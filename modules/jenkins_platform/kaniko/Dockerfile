
FROM gcr.io/kaniko-project/executor:debug AS kaniko

FROM jenkins/inbound-agent:latest-alpine
USER root

RUN apk --update add \
  bash \
  curl \
  git \
  jq \
  unzip \
  npm

#
# Add kaniko to this image by re-using binaries and steps from official image
#
COPY --from=kaniko /kaniko/ /kaniko/

ENV SSL_CERT_DIR /kaniko/ssl/certs
ENV PATH $PATH:/usr/local/bin:/kaniko
ENV DOCKER_CONFIG /kaniko/.docker/
ENV DOCKER_CREDENTIAL_GCR_CONFIG /kaniko/.config/gcloud/docker_credential_gcr_config.json

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && ./aws/install

COPY files/Dockerfile.example /home/Dockerfile
COPY files/scripts/execute.sh /home/execute.sh
COPY files/config.json /root/.docker/config.json
RUN chmod 755 /home/execute.sh /home/Dockerfile /root/.docker/config.json

USER root

