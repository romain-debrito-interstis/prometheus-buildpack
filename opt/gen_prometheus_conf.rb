#!/usr/bin/env ruby

require "erb"
require "json"
require "yaml"

def scrape_configs
  prometheus_scrape_configs = ENV["PROMETHEUS_SCRAPE_CONFIGS"] || "[]"
  return JSON.parse(prometheus_scrape_configs)
end

content = File.read "/app/prometheus.yml.erb"
erb_result = ERB.new(content).result
puts erb_result
File.write("/app/opt/prometheus.yml", erb_result)
puts "[INFO] Fichier de configuration généré : /app/opt/prometheus.yml"