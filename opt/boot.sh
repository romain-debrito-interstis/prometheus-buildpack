#!/bin/bash

if [ -n "$DEBUG" ]; then
  set -x
fi

if [[ -z "$CANONICAL_HOST" ]]; then
  echo >&2 "The environment variable CANONICAL_HOST must be set"
  exit -1
fi

if [[ -z "$BASIC_AUTH_USERNAME" ]] || [[ -z "$BASIC_AUTH_PASSWORD" ]]; then
  echo >&2 "The environment variables BASIC_AUTH_USERNAME and BASIC_AUTH_PASSWORD are mandatory to configure the Prometheus Basic Auth"
  exit -1
fi

if [[ -z "$PROMSCALE_HOSTNAME" ]]; then
  echo >&2 "The environment variable PROMSCALE_HOSTNAME must be set"
  exit -1
fi

echo "Using Promscale as Prometheus storage backend"

if [[ -z "$PROMSCALE_AUTH_USERNAME" ]] || [[ -z "$PROMSCALE_AUTH_PASSWORD" ]]; then
  echo >&2 "The environment variables PROMSCALE_AUTH_USERNAME and PROMSCALE_AUTH_PASSWORD are mandatory to connect to Promscale"
  exit -1
fi

echo "Generating the Prometheus configuration file"
ruby /app/gen_prometheus_conf.rb > /app/prometheus.yml

/app/prometheus/prometheus --web.listen-address=127.0.0.1:9090 \
  --web.external-url=https://${CANONICAL_HOST} \
  --web.route-prefix="/"
