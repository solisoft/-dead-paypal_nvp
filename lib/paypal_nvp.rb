module PaypalNVP
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    
    def initialize(sandbox = false)
      config = YAML.load_file("#{RAILS_ROOT}/config/paypal.yml")
      type = sandbox ? "sandbox" : "live"
      @url  = config[type]["url"]
      @user = config[type]["user"]
      @pass = config[type]["pass"]
      @cert = config[type]["cert"]
      reset
    end

    def add_value(key, value)
      @values[key] = value
    end

    def reset
      @values = { "USER" => @user, "PWD" => @pass, "SIGNATURE" => @cert, "VERSION" => "50.0" }
    end

    def call_paypal
      qs = []
      @values.each do |key, value|
        qs << "#{key}=#{url_encode(value)}"
      end
      qs = "?#{qs * "&"}"    

      uri = URI.parse(@url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      response = http.start {
        http.request_get(uri.path) {|res|
          res
        }
      }
      data = {}
      if response.kind_of? Net::HTTPSuccess
        response.body.split("&").each do |element|
          a = element.split("=")
          data[a[0]] = a[1] if a.size == 2
        end
      end 
      data
    end
    
  end
end

