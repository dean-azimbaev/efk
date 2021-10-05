FROM fluentd:v1.9.1-debian-1.0

USER root

RUN apt-get update \
  && apt-get install -y vim \
  && apt-get install -y iputils-ping

RUN ["gem", "install", "fluent-plugin-elasticsearch", "--no-document", "--version", "5.1.0"]

USER fluent
