require 'json'

class WelcomeController < ApplicationController
  def index
    @title = 'Register User'
  end



  def send_data
    api = '6d39d72823d3392fb5e1cc0321f6b5e2269f7dc4c432eb2ba12ee7f7d81a32dba353e0e93d29365a'
    bitex_url = "https://sandbox.bitex.la/#{api}/natural_docket_seeds"
    data = {}
    body = {
      data: {
        type: 'natural_docket_seeds',
        attributes: {
          first_name: data['first_name'],
          last_name: data['last_name'],
          nationality: "AR",
          gender_code: data['gender_code'],
          marital_status_code: data['marital_status_code'],
          politically_exposed: data['politically_exposed'],
          birth_date: data['birth_date']
        }
      }
    }
      begin
          Rails.logger.info ""
          uri = URI(bitex_url)
          http = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Post.new(uri)
          request.body = body.to_json
          # TLS v1.2
          ctx = OpenSSL::SSL::SSLContext.new
          ctx.ssl_version = :TLSv1_2
          if uri.scheme = "https"
              http.use_ssl = true
          end
          res = http.request(request)
          res.code
        rescue => e
          Rails.logger.error "Error:::#{e.message}"
      end
  end

end
