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

# Création du fichier d'authentification
echo "[INFO] Configuration de l'authentification..."
if [[ -n "$BASIC_AUTH_USERNAME" && -n "$BASIC_AUTH_PASSWORD" ]]; then
  # Installation de htpasswd si nécessaire
  if ! command -v htpasswd &> /dev/null; then
    echo "[INFO] Installation de apache2-utils pour htpasswd..."
    apt-get update && apt-get install -y apache2-utils
  fi
  
  # Création du fichier d'authentification
  echo "[INFO] Création du fichier d'authentification..."
  htpasswd -b -c /etc/prometheus/web_auth.yml "$BASIC_AUTH_USERNAME" "$BASIC_AUTH_PASSWORD"
  chmod 644 /etc/prometheus/web_auth.yml
  
  # Vérification que le fichier a été créé
  if [ ! -f "/etc/prometheus/web_auth.yml" ]; then
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
