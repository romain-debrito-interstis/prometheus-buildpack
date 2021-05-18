#!/usr/bin/env ruby

require "erb"
require "json"
require "yaml"

def promscale_url
  return "https://#{ENV["PROMSCALE_HOSTNAME"]}"
end

def scrape_configs
  prometheus_scrape_configs = ENV["PROMETHEUS_SCRAPE_CONFIGS"] || []
  return JSON.parse(prometheus_scrape_configs)
end

content = File.read "/app/prometheus.yml.erb"
erb_postgresql_conf = ERB.new(content)
erb_postgresql_conf.run
