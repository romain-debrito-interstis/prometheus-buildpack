# Scalingo Prometheus Buildpack

This buildpack aims at deploying a Prometheus instance on the [Scalingo](https://scalingo.com/) PaaS platform.

## Configuration

### Basic Authentication

This buildpack makes it mandatory to enable a Basic Auth protection. The application must define the `BASIC_AUTH_USERNAME` and `BASIC_AUTH_PASSWORD` environment variables with the credentials.

### Promscale Information

You may want to connect Prometheus to a Promscale instance. In this case, one need to provide the hostname (`PROMSCALE_HOSTNAME`), and the Promscale Basic Auth credentials (`PROMSCALE_AUTH_USERNAME` and `PROMSCALE_AUTH_PASSWORD`).

Promscale is currently the only available backend. Feel free to open an issue and a pull request to support various backends.

## Defining the Version

By default we're installing the version of Promscale declared in the [`bin/compile`](https://github.com/Scalingo/prometheus-buildpack/blob/master/bin/compile#L16) file. But if you want to use a specific version, you can define the environment variable `PROMETHEUS_VERSION`.

```shell
$ scalingo env-set PROMETHEUS_VERSION=2.26.0
```
