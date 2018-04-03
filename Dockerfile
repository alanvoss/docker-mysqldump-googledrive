FROM ruby:2.4.1

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV APP=/mysqldump-backup LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8
WORKDIR $APP

RUN apt-get install -y mysql-client libmysqlclient-dev --no-install-recommends \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && addgroup ruby \
  && adduser --ingroup ruby --shell /bin/bash --disabled-password ruby

COPY --chown=ruby:ruby . $APP

USER ruby
RUN bundle install
ENTRYPOINT bundle exec ruby backup.rb
