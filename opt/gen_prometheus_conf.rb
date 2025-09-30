#!/usr/bin/env ruby

require "erb"
require "json"
require "yaml"
require "fileutils"

# Configuration des chemins - utiliser /app/config au lieu de /etc/prometheus
RULES_DIR = "/app/opt/rules"
CONFIG_DIR = "/app/config"

# Création des répertoires si nécessaire
FileUtils.mkdir_p(RULES_DIR) unless Dir.exist?(RULES_DIR)
FileUtils.mkdir_p(CONFIG_DIR) unless Dir.exist?(CONFIG_DIR)

def scrape_configs
  prometheus_scrape_configs = ENV["PROMETHEUS_SCRAPE_CONFIGS"]
  if prometheus_scrape_configs && !prometheus_scrape_configs.empty?
    begin
      return JSON.parse(prometheus_scrape_configs)
    rescue JSON::ParserError => e
      puts "Warning: Invalid JSON in PROMETHEUS_SCRAPE_CONFIGS: #{e.message}"
      return []
    end
  else
    return []
  end
end

def load_rules
  rules_files = Dir.glob(File.join(RULES_DIR, "*.{yaml,yml}"))

  # Si aucun fichier de règle n'existe, on crée un exemple
  if rules_files.empty?
    example_rules = {
      'groups' => [
        {
          'name' => 'example-rules',
          'interval' => '30s',
          'rules' => [
            {
              'alert' => 'HighErrorRate',
              'expr' => 'job:up == 0',
              'for' => '5m',
              'labels' => {
                'severity' => 'critical'
              },
              'annotations' => {
                'summary' => 'Instance {{ $labels.instance }} down',
                'description' => '{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 5 minutes.'
              }
            }
          ]
        }
      ]
    }

    rules_file_path = File.join(RULES_DIR, 'example_rules.yml')
    File.write(rules_file_path, example_rules.to_yaml)
    rules_files = [rules_file_path]
  end

  # Copie des fichiers de règles vers le répertoire de configuration
  rules_files.each do |source|
    filename = File.basename(source)
    destination = File.join(CONFIG_DIR, filename)
    FileUtils.cp(source, destination) unless File.exist?(destination)
  end

  # Retourne la liste des fichiers de règles pour la configuration
  rules_files.map { |f| File.basename(f) }
end

# Génération de la configuration
begin
  rules_files = load_rules
  template_content = File.read("/app/opt/prometheus.yml.erb")
  
  # Rendu du template avec les variables nécessaires
  erb_template = ERB.new(template_content)
  puts erb_template.result(binding)
rescue => e
  STDERR.puts "Error generating Prometheus configuration: #{e.message}"
  STDERR.puts e.backtrace
  exit 1
end