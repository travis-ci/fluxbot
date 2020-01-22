FROM node:13.6.0-alpine3.10

RUN adduser -S fluxbot
RUN wget https://github.com/fluxcd/flux/releases/download/1.17.1/fluxctl_linux_amd64 -O /usr/local/bin/fluxctl
RUN chmod +x /usr/local/bin/fluxctl
RUN npm install -g yo generator-hubot

RUN apk add --update \
			python \
			curl \
			which \
			bash

USER fluxbot
WORKDIR /home/fluxbot 

RUN curl -sSL https://sdk.cloud.google.com | bash
ENV PATH $PATH:/home/fluxbot/google-cloud-sdk/bin

ADD client-secret.json /home/fluxbot/google-cloud-sdk/client-secret.json
RUN gcloud -q auth activate-service-account --key-file /home/fluxbot/google-cloud-sdk/client-secret.json && \
  	gcloud -q config set project travis-ci-staging-services-1 && \
  	gcloud -q config set compute/zone us-central1 && \
  	gcloud container clusters get-credentials travis-ci-services && \
  	gcloud auth configure-docker

RUN yo hubot \
			--owner="Arek <arek@travis-ci.org>" \
			--name="Fluxbot" \
			--description="Flux deployment bot" \
			--adapter=slack \
			--defaults

ADD scripts/fluxctl.coffee /home/fluxbot/scripts/fluxctl.coffee
CMD bin/hubot --adapter slack

