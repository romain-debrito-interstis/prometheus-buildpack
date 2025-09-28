#!/bin/bash

set -euo pipefail

# Activation du mode debug si demandé
[ -n "${DEBUG:-}" ] && set -x

# Vérification des variables d'environnement requises
required_vars=(
  "CANONICAL_HOST"
  "BASIC_AUTH_USERNAME"
  "BASIC_AUTH_PASSWORD"
  "SCALINGO_INFLUX_URL"
  "PROMETHEUS_GLOBAL_SCRAPE_INTERVAL"
  "PROMETHEUS_GLOBAL_EVALUATION_INTERVAL"
  "PROMETHEUS_SCRAPE_TIMEOUT"
)

for var in "${required_vars[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo >&2 "[ERREUR] La variable d'environnement $var doit être définie"
    exit 1
  fi
done

# Configuration des répertoires
CONFIG_DIR="/app/config"
mkdir -p "$CONFIG_DIR"

# Copie de la configuration
cp /app/opt/prometheus.yml /app/

# Création du fichier de cibles vide (sera géré par la configuration Prometheus)
mkdir -p "$CONFIG_DIR"
echo '[]' > "$CONFIG_DIR/scalingo_targets.json"

# Extraction des informations de connexion InfluxDB
export INFLUX_USER=$(echo "$SCALINGO_INFLUX_URL" | sed -n 's|.*//\([^:]*\):\([^@]*\)@.*|\1|p')
export INFLUX_PASSWORD=$(echo "$SCALINGO_INFLUX_URL" | sed -n 's|.*//[^:]*:\([^@]*\)@.*|\1|p')
export INFLUX_HOST_PORT=$(echo "$SCALINGO_INFLUX_URL" | sed -n 's|.*@\([^/]*\).*|\1|p')
export INFLUX_DB=$(echo "$SCALINGO_INFLUX_URL" | sed -n 's|.*/\([^/]*\)$|\1|p')

echo "=== Configuration de Prometheus ==="
echo "URL: https://${CANONICAL_HOST}"
echo "Authentification: ${BASIC_AUTH_USERNAME}/*******"
echo "InfluxDB: ${INFLUX_HOST_PORT}/${INFLUX_DB}"
echo "Scrape interval: ${PROMETHEUS_GLOBAL_SCRAPE_INTERVAL}"
echo "Evaluation interval: ${PROMETHEUS_GLOBAL_EVALUATION_INTERVAL}"
echo "Scrape timeout: ${PROMETHEUS_SCRAPE_TIMEOUT}"
echo "================================="

# Démarrage de Prometheus
exec /app/prometheus/prometheus \
  --config.file=/app/prometheus.yml \
  --web.listen-address=:${PORT:-9090} \
  --web.external-url=https://${CANONICAL_HOST} \
  --web.route-prefix="/" \
  --storage.tsdb.retention.time=30d \
  --storage.tsdb.path=/app/prometheus/data
