#!/usr/bin/env ruby

require "erb"

def promscale_url
  return "https://#{ENV["PROMSCALE_HOSTNAME"]}"
end

def target_praefect
  # gitaly-1-0
  return "ip-10-0-0-171.osc-st-fr1.st-sc.fr:10101"
end

def target_gitaly
  # gitaly-1-0
  return "ip-10-0-0-171.osc-st-fr1.st-sc.fr:9236"
end

content = File.read "/app/prometheus.yml.erb"
erb_postgresql_conf = ERB.new(content)
erb_postgresql_conf.run
