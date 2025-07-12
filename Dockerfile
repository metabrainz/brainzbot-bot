FROM golang:1.24.5 as base
WORKDIR /app

RUN apt-get update && apt-get install -y git

COPY go.mod go.sum ./
RUN go mod download

FROM base as builder

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -v -o botbot-bot .

FROM metabrainz/consul-template-base:noble-1.0.0-v0.1-1 as prod
WORKDIR /app

RUN groupadd -r app && useradd -r -g app app
USER app

COPY --from=builder --chown=app:app /app/botbot-bot .
RUN chmod +x /app/botbot-bot

COPY ./environment.ctmpl /app/environment.ctmpl
COPY ./docker/services/consul-template-bot.conf /etc/consul-template-bot.conf
COPY ./docker/services/brainzbot-bot.service /etc/service/brainzbot-bot/run

ENV PATH="/app:${PATH}"

USER root

ARG GIT_COMMIT_SHA
LABEL org.label-schema.vcs-url="https://github.com/metabrainz/brainzbot-bot.git" \
      org.label-schema.vcs-ref="" \
      org.label-schema.schema-version="1.0.0-rc1" \
      org.label-schema.vendor="MetaBrainz Foundation" \
      org.label-schema.name="MetaBrainz" \
      org.label-schema.vcs-ref=$GIT_COMMIT_SHA
ENV GIT_SHA ${GIT_COMMIT_SHA}

FROM base as dev

COPY . .

RUN go install github.com/air-verse/air@latest

ENTRYPOINT ["air"]
CMD ["./botbot-bot", "--logtostderr=1", "--stderrthreshold=0", "--v=2"]
