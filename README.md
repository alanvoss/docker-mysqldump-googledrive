# docker-mysqldump-googledrive
Automate frequent backups to google drive from mysqldump, using a combination of env variables and docker volumes.

## Installation

- Follow the directions here (Step 1) to get an OAuth key in the format specified.

https://developers.google.com/drive/v3/web/quickstart/ruby

- Put the resulting json file download in the root directory of this project, and rename to `client_secret.json`.

- Run

`bundle install`
`bundle exec ruby setup.rb`

- The first time the app runs, you'll be requested to go to a URL to "Open the following URL in the browser and enter the resulting code after authorization":

- After going to that url, and authorizing the correct Google Drive account, copy the resulting code into your terminal and hit enter.

- If everything went right, you'll see a list of the files currently in the Google Drive authorized.

# Usage

This is intended to be run inside of docker, whether it be in a compose setup or individually.  It is also intended to entirely be configured through ENV vars and volume mounts (for credentials).

You'll need to set the following required `ENV` vars:

- `LOCAL_CREDENTIALS_FOLDER` - the volume folder mounted inside this container containing the `.client_secret.json` (from Google) and `credentials.yaml` (created after running `setup.rb`)
- `MYSQL_DATABASE` - the database name
- `MYSQL_USER` - the database user

And then also some optional ones:

- `GOOGLE_DRIVE_BACKUPS_FOLDER` - the name of the folder that the credentialed user has access to, e.g. `database_backups`
- `MYSQL_HOST` -  the hostname of the mysql instance (in `docker-compose.yml`, use the name of the mysql service)
- `BACKUP_FILE_PREFIX` - a prefix to come before a timestamp for all uploaded db files
- `MYSQL_PASSWORD` - the db password for `MYSQL_USER`, if set

### Sample docker-compose file
