require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

CREDENTIALS_FOLDER = ENV['LOCAL_CREDENTIALS_FOLDER'] ||
  raise("no LOCAL_CREDENTIALS_FOLDER env var declared")
GOOGLE_DRIVE_BACKUPS_FOLDER = ENV['GOOGLE_DRIVE_BACKUPS_FOLDER'] ||
  warn("no GOOGLE_DRIVE_BACKUPS_FOLDER declared -- using root folder")
BACKUP_FILE_PREFIX = ENV['BACKUP_FILE_PREFIX'] || "db_dump_"
MYSQL_HOST = ENV['MYSQL_HOST'] || "localhost"
MYSQL_DATABASE = ENV['MYSQL_DATABASE'] ||
  raise("no MYSQL_DATABASE env var declared")
MYSQL_USER = ENV['MYSQL_USER'] ||
  raise("no MYSQL_USER env var declared")
MYSQL_PASSWORD = ENV['MYSQL_PASSWORD'] ||
  warn("no MYSQL_PASSWORD env var declared")

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
APPLICATION_NAME = 'Drive API Ruby Quickstart'
BACKUPS_FOLDER = 'backups'
CLIENT_SECRETS_PATH = "#{CREDENTIALS_FOLDER}/client_secret.json"
CREDENTIALS_PATH = "#{CREDENTIALS_FOLDER}/credentials.yaml"
DRIVE = Google::Apis::DriveV3
SCOPE = DRIVE::AUTH_DRIVE

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

  client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(
    client_id, SCOPE, token_store)
  user_id = 'default'
  authorizer.get_credentials(user_id)
end

# Initialize the API
service = DRIVE::DriveService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

backup_path = "#{BACKUPS_FOLDER}/dump.sql"
gzipped_backup_path = "#{backup_path}.gz"
timestamp = DateTime.now.strftime("%Y%m%dT%H%M%S")

dump_command = "mysqldump --databases #{MYSQL_DATABASE} -h#{MYSQL_HOST} -u#{MYSQL_USER} "
if MYSQL_PASSWORD
  dump_command += "-p#{MYSQL_PASSWORD} "
end
dump_command += ">#{backup_path}"

%x(#{dump_command})
open("temp.txt", "w") do |output| 
  open(backup_path).each_line do |line|
    unless line =~ /Dump completed on/
      output.write(line)
    end
  end
end

FileUtils.mv("temp.txt", backup_path)
%x(gzip -f -n --best #{backup_path})

hex_digest = Digest::MD5.hexdigest(File.read(gzipped_backup_path))
previous_upload = service.list_files(
  q: "name contains '#{BACKUP_FILE_PREFIX}'",
  order_by: 'createdTime desc',
  fields: 'files(id, name, md5Checksum)'
).files.first

if previous_upload && hex_digest == previous_upload.md5_checksum
  warn "backup identical - not uploading again"
else
  file =
    if GOOGLE_DRIVE_BACKUPS_FOLDER
      folder_id = service.list_files(q: "name = '#{GOOGLE_DRIVE_BACKUPS_FOLDER}'").files.first.id
      DRIVE::File.new(
        name: "#{BACKUP_FILE_PREFIX}#{timestamp}",
        description: 'Today DB Upload',
        parents: [folder_id]
      )
    else
      DRIVE::File.new(
        name: "#{BACKUP_FILE_PREFIX}#{timestamp}",
        description: 'Today DB Upload'
      )
    end
  
  service.create_file(
    file,
    upload_source: gzipped_backup_path,
    content_type: 'text/plain'
  )
end
