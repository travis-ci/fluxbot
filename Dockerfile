FROM node:alpine3.16

RUN adduser -S fluxbot

RUN npm install -g yo generator-hubot

RUN apk add --update \
			python3 \
			curl \
			which \
			bash 

USER fluxbot
WORKDIR /home/fluxbot 

RUN yo hubot \
			--owner="Arek <arek@travis-ci.org>" \
			--name="Fluxbot" \
			--description="Flux deployment bot" \
			--adapter=slack \
			--defaults

ADD scripts/fluxctl.coffee /home/fluxbot/scripts/fluxctl.coffee
ADD external-scripts.json /home/fluxbot/external-scripts.json

CMD bin/hubot --adapter slack
