FROM alpine:3.14

WORKDIR /app

RUN apk update && apk add --no-cache coreutils \
    jq \
    bash \
    curl

COPY . .

CMD ./wait-for-it.sh zap:8090 -- bash scan-auth.sh
