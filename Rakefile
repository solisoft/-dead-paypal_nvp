require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('paypal_nvp', '0.1.3') do |p|
  p.description    = "Paypal NVP API Class."
  p.url            = "http://github.com/solisoft/paypal_nvp"
  p.author         = "Olivier BONNAURE - Direct Interactive LLC"
  p.email          = "o.bonnaure@directinteractive.com"
  p.ignore_pattern = ["tmp/*", "script/*"]
  p.development_dependencies = []
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }
