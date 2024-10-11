FROM alpine:3.20

RUN apk add --no-cache curl jq  bash

COPY --chmod=755 scripts/* /scripts/
