FROM ruby:2.4.1

RUN apt-get update \
  && apt-get install -y mysql-client libmysqlclient-dev --no-install-recommends \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /mysqldump-backup
COPY . $WORKDIR

RUN bundle install

ENTRYPOINT bundle exec $WORKDIR/backup.rb
