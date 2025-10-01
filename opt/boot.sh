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

# Définition des chemins
PROMETHEUS_DATA_DIR="/app/data/prometheus"
PROMETHEUS_CONFIG_DIR="/app/config"

# Création des répertoires nécessaires avec les bonnes permissions
mkdir -p "${PROMETHEUS_DATA_DIR}"
chmod -R 755 "${PROMETHEUS_DATA_DIR}"

mkdir -p "${PROMETHEUS_CONFIG_DIR}"
chmod -R 755 "${PROMETHEUS_CONFIG_DIR}"

# Génération de la configuration
echo "[INFO] Génération de la configuration Prometheus..."
if ! ruby /app/opt/gen_prometheus_conf.rb; then
  echo "[ERREUR] Échec de la génération de la configuration"
  exit 1
fi

# Vérification de la configuration
echo "[INFO] Vérification de la configuration..."
if ! /app/prometheus/promtool check config "${PROMETHEUS_CONFIG_DIR}/prometheus.yml"; then
  echo "[ERREUR] Configuration Prometheus invalide"
  exit 1
fi

# Création du fichier d'authentification pour l'interface web
echo "[INFO] Configuration de l'authentification..."
if [[ -n "$BASIC_AUTH_USERNAME" && -n "$BASIC_AUTH_PASSWORD" ]]; then
  # Créer un fichier de configuration web avec authentification basique
  web_config_content = <<~YAML
    basic_auth_users:
      "#{ENV["BASIC_AUTH_USERNAME"]}": "#{ENV["BASIC_AUTH_PASSWORD"]}"
  YAML
  
  echo "$web_config_content" > "${PROMETHEUS_CONFIG_DIR}/web.yml"
  chmod 644 "${PROMETHEUS_CONFIG_DIR}/web.yml"

  echo "[SUCCÈS] Authentification configurée pour l'utilisateur: $BASIC_AUTH_USERNAME"  
else
  echo "[ERREUR] Les variables BASIC_AUTH_USERNAME et BASIC_AUTH_PASSWORD doivent être définies"
  exit 1
fi

# Démarrage de Prometheus
echo "[INFO] Démarrage de Prometheus..."
echo "[INFO] Répertoire des données: ${PROMETHEUS_DATA_DIR}"
echo "[INFO] Répertoire de configuration: ${PROMETHEUS_CONFIG_DIR}"
echo "[INFO] Fichier de configuration: ${PROMETHEUS_CONFIG_DIR}/prometheus.yml"

exec /app/prometheus/prometheus \
  --config.file="${PROMETHEUS_CONFIG_DIR}/prometheus.yml" \
  --storage.tsdb.path="${PROMETHEUS_DATA_DIR}" \
  --web.console.libraries=/app/prometheus/console_libraries \
  --web.console.templates=/app/prometheus/consoles \
  --web.listen-address=:${PORT:-9090} \
  --web.external-url=https://${CANONICAL_HOST} \
  --web.route-prefix="/" \
  --web.enable-lifecycle \
  --storage.tsdb.retention.time=30d \
  --log.level=${PROMETHEUS_LOG_LEVEL:-info}