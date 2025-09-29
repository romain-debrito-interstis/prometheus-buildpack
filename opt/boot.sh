#!/bin/bash

set -e

if [ -n "$DEBUG" ]; then
  set -x
fi

# Vérification des variables d'environnement requises
if [[ -z "$CANONICAL_HOST" ]]; then
  echo >&2 "[ERREUR] La variable d'environnement CANONICAL_HOST doit être définie"
  exit 1
fi

if [[ -z "$BASIC_AUTH_USERNAME" ]] || [[ -z "$BASIC_AUTH_PASSWORD" ]]; then
  echo >&2 "[ERREUR] Les variables BASIC_AUTH_USERNAME et BASIC_AUTH_PASSWORD sont obligatoires"
  exit 1
fi

# Création des répertoires nécessaires
mkdir -p /etc/prometheus/rules
chmod -R 755 /etc/prometheus

# Copie des fichiers de configuration
echo "[INFO] Génération de la configuration Prometheus..."
ruby /app/opt/gen_prometheus_conf.rb > /app/prometheus.yml

# Vérification de la configuration
echo "[INFO] Vérification de la configuration..."
/app/prometheus/promtool check config /app/prometheus.yml

# Démarrage de Prometheus
echo "[INFO] Démarrage de Prometheus..."
exec /app/prometheus/prometheus \
  --config.file=/app/prometheus.yml \
  --storage.tsdb.path=/prometheus \
  --web.console.libraries=/app/prometheus/console_libraries \
  --web.console.templates=/app/prometheus/consoles \
  --web.listen-address=:${PORT:-9090} \
  --web.external-url=https://${CANONICAL_HOST} \
  --web.route-prefix="/" \
  --web.enable-lifecycle \
  --storage.tsdb.retention.time=30d
