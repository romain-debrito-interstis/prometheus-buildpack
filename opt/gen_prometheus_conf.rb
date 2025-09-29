#!/usr/bin/env ruby

require "erb"
require "json"
require "yaml"
require "fileutils"

# Configuration des chemins
RULES_DIR = "/app/opt/rules"
CONFIG_DIR = "/etc/prometheus"

# Création des répertoires si nécessaire
FileUtils.mkdir_p(RULES_DIR) unless Dir.exist?(RULES_DIR)
FileUtils.mkdir_p(CONFIG_DIR) unless Dir.exist?(CONFIG_DIR)

def scrape_configs
  prometheus_scrape_configs = ENV["PROMETHEUS_SCRAPE_CONFIGS"] || []
  return JSON.parse(prometheus_scrape_configs)
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
              'expr' => 'rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.1',
              'for' => '10m',
              'labels' => {
                'severity' => 'critical',
                'team' => 'devops'
              },
              'annotations' => {
                'summary' => 'High error rate on {{ $labels.instance }}',
                'description' => 'Error rate is {{ $value }}% for {{ $labels.job }}'
              }
            }
          ]
        }
      ]
    }
    
    File.write(File.join(RULES_DIR, 'example_rules.yml'), example_rules.to_yaml)
    rules_files = [File.join(RULES_DIR, 'example_rules.yml')]
  end
  
  # Copie des fichiers de règles vers le répertoire de configuration
  rules_files.each do |source|
    filename = File.basename(source)
    FileUtils.cp(source, File.join(CONFIG_DIR, filename))
  end
  
  # Retourne la liste des fichiers de règles pour la configuration
  rules_files.map { |f| File.basename(f) }
end

# Génération de la configuration
rules_files = load_rules
content = File.read "/app/opt/prometheus.yml.erb"

# Rendu du template avec les variables nécessaires
puts ERB.new(content).result(binding)
