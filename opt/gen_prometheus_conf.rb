#!/usr/bin/env ruby

require "erb"
require "yaml"

# Chemin vers le template
TEMPLATE_PATH = "/app/opt/prometheus.yml.erb"

begin
  # Lire le template
  template = File.read(TEMPLATE_PATH)
  
  # Rendre le template avec les variables d'environnement
  config = ERB.new(template).result(binding)
  
  # Écrire la configuration générée
  puts config
rescue => e
  # En cas d'erreur, écrire un message d'erreur clair
  STDERR.puts "Erreur lors de la génération de la configuration : #{e.message}"
  STDERR.puts e.backtrace.join("\n")
  exit 1
end