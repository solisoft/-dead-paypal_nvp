require "net/https"
require "cgi"
require "logger"

class PaypalNVP
  def self.included(base)
    base.extend ClassMethods
  end

  def initialize(sandbox = false, extras = {})
    type = sandbox ? "sandbox" : "live"
    config = YAML.load_file("#{Rails.root}/config/paypal.yml") rescue nil
    @logger = defined?(Rails.logger) && Rails.logger || Logger.new(STDOUT)

    # By default we use the 50.0 API version.
    # At 30 Apr 2012, version 87.0 and provides additional shipping information.
    extras[:version] ||= "50.0"

    if config
      @url  = config[type]["url"] 
      @user = config[type]["user"]
      @pass = config[type]["pass"]
      @cert = config[type]["cert"]
      @rootCA = config[type]["rootca"]
    else
      @url  = extras[:url]
      @user = extras[:user]
      @pass = extras[:pass]
      @cert = extras[:cert]
      @rootCA = extras[:rootca]
    end
    @extras = extras
    @rootCA = @rootCA || '/etc/ssl/certs'
  end

  def call_paypal(data)
    data.merge!({ "USER" => @user, "PWD" => @pass, "SIGNATURE" => @cert })
    data.merge!(@extras)
    qs = []
    data.each do |key, value|
      qs << "#{key.to_s.upcase}=#{URI.escape(value.to_s)}"
    end
    qs = "#{qs * "&"}"

    uri = URI.parse(@url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    if File.directory? @rootCA
      http.ca_path = @rootCA
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.verify_depth = 5
    elsif File.exists?(@rootCA)
      http.ca_file = @rootCA
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.verify_depth = 5
    else
      @logger.warn "[PaypalNVP] No ssl certs found. Paypal communication will be insecure. DO NOT DEPLOY"
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    response = http.start {
      http.request_post(uri.path, qs) {|res|
        res
      }
    }
    data = { :response => response }
    if response.kind_of? Net::HTTPSuccess
      response.body.split("&").each do |element|
        a = element.split("=")
        data[a[0]] = CGI.unescape(a[1]) if a.size == 2
      end
    end
    data
  end
end
