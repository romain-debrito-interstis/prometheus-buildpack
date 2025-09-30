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

# Copie des fichiers de configuration
echo "[INFO] Génération de la configuration Prometheus..."
ruby /app/opt/gen_prometheus_conf.rb > "${PROMETHEUS_CONFIG_DIR}/prometheus.yml"

# Vérification de la configuration
echo "[INFO] Vérification de la configuration..."
/app/prometheus/promtool check config "${PROMETHEUS_CONFIG_DIR}/prometheus.yml"

# Création du fichier d'authentification
echo "[INFO] Configuration de l'authentification..."
if [[ -n "$BASIC_AUTH_USERNAME" && -n "$BASIC_AUTH_PASSWORD" ]]; then
  # Création du fichier d'authentification
  echo "[INFO] Création du fichier d'authentification..."
  # Utilisation de openssl si htpasswd n'est pas disponible
  if command -v htpasswd &> /dev/null; then
    htpasswd -b -c "${PROMETHEUS_CONFIG_DIR}/web_auth.yml" "$BASIC_AUTH_USERNAME" "$BASIC_AUTH_PASSWORD"
  else
    # Alternative avec openssl si htpasswd n'est pas disponible
    echo "$BASIC_AUTH_USERNAME:$(openssl passwd -apr1 "$BASIC_AUTH_PASSWORD")" > "${PROMETHEUS_CONFIG_DIR}/web_auth.yml"
  fi
  
  chmod 644 "${PROMETHEUS_CONFIG_DIR}/web_auth.yml"
  
  # Vérification que le fichier a été créé
  if [ ! -f "${PROMETHEUS_CONFIG_DIR}/web_auth.yml" ]; then
    echo "[ERREUR] Impossible de créer le fichier d'authentification"
    exit 1
  fi
  
  echo "[SUCCÈS] Authentification configurée pour l'utilisateur: $BASIC_AUTH_USERNAME"
else
  echo "[ERREUR] Les variables BASIC_AUTH_USERNAME et BASIC_AUTH_PASSWORD doivent être définies"
  exit 1
fi

# Démarrage de Prometheus
echo "[INFO] Démarrage de Prometheus..."
echo "[INFO] Répertoire des données: ${PROMETHEUS_DATA_DIR}"
echo "[INFO] Répertoire de configuration: ${PROMETHEUS_CONFIG_DIR}"

# Vérification des permissions
touch "${PROMETHEUS_DATA_DIR}/test_write" && rm "${PROMETHEUS_DATA_DIR}/test_write"
if [ $? -ne 0 ]; then
  echo "[ERREUR] Impossible d'écrire dans le répertoire de données: ${PROMETHEUS_DATA_DIR}"
  exit 1
fi

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
