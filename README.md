# Prometheus Buildpack for Scalingo

Ce buildpack déploie une instance Prometheus sur la plateforme [Scalingo](https://scalingo.com/) avec les fonctionnalités suivantes :

- Découverte automatique des applications Node.js exposant des métriques Prometheus
- Exportation des métriques vers InfluxDB via remote write
- Authentification de base pour sécuriser l'accès à l'interface web
- Configuration personnalisable via des variables d'environnement

## Configuration requise

Les variables d'environnement suivantes doivent être définies :

- `CANONICAL_HOST` - L'URL de base de votre application (ex: `mon-app.osc-fr1.scalingo.io`)
- `BASIC_AUTH_USERNAME` - Nom d'utilisateur pour l'authentification de base
- `BASIC_AUTH_PASSWORD` - Mot de passe pour l'authentification de base
- `SCALINGO_INFLUX_URL` - URL de connexion à InfluxDB (fournie par l'addon InfluxDB de Scalingo)

## Variables d'environnement optionnelles

- `PROMETHEUS_GLOBAL_SCRAPE_INTERVAL` - Intervalle de rafraîchissement des métriques (par défaut: 30s)
- `PROMETHEUS_GLOBAL_EVALUATION_INTERVAL` - Intervalle d'évaluation des règles (par défaut: 30s)
- `PROMETHEUS_SCRAPE_TIMEOUT` - Délai d'attente pour le rafraîchissement des métriques (par défaut: 10s)
- `SCALINGO_APP_NAME` - Nom de l'application cible pour la découverte de service (par défaut: utilise le nom de l'application courante)
- `SCALINGO_REGION` - Région Scalingo (par défaut: osc-fr1)
- `ENVIRONMENT` - Environnement de déploiement (par défaut: development)

## Configuration des cibles

Les cibles sont configurées via le fichier `/app/config/scalingo_targets.json` qui est généré automatiquement au démarrage. Le fichier est mis à jour dynamiquement pour inclure les applications Scalingo déployées.

## Règles d'alerte

Les règles d'alerte sont définies dans le fichier `alert.rules` et sont chargées automatiquement au démarrage. Vous pouvez personnaliser ces règles selon vos besoins.

## Remote Write vers InfluxDB

Le remote write vers InfluxDB est configuré automatiquement si la variable d'environnement `SCALINGO_INFLUX_URL` est définie. Les métriques sont envoyées à la base de données spécifiée dans l'URL.

## Développement local

Pour tester en local, vous pouvez définir les variables d'environnement requises dans un fichier `.env` et utiliser Docker :

```bash
docker build -t prometheus-scalingo .
docker run -p 9090:9090 --env-file .env prometheus-scalingo
```

## Déploiement

Ce buildpack est conçu pour être utilisé directement avec Scalingo. Assurez-vous que votre application est configurée pour utiliser ce buildpack et que toutes les variables d'environnement requises sont définies.

### Configuration des applications Node.js

Pour que vos applications Node.js soient découvertes automatiquement, assurez-vous qu'elles exposent un endpoint `/metrics` compatible avec le client Prometheus. Par exemple :

```javascript
const express = require('express');
const client = require('prom-client');

const app = express();
const port = process.env.PORT || 3000;

// Enable collection of default metrics
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics({ timeout: 5000 });

// Expose metrics endpoint
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', client.register.contentType);
    res.end(await client.register.metrics());
  } catch (err) {
    res.status(500).end(err);
  }
});

app.listen(port, () => {
  console.log(`App listening at http://localhost:${port}`);
});
```

## Définition de la version

By default we're installing the version of Promscale declared in the [`bin/compile`](https://github.com/Scalingo/prometheus-buildpack/blob/master/bin/compile#L16) file. But if you want to use a specific version, you can define the environment variable `PROMETHEUS_VERSION`.

```shell
scalingo env-set PROMETHEUS_VERSION=2.26.0
```
