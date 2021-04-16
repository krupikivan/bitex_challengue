require 'json'

class WelcomeController < ApplicationController
  def index
    @title = 'Registro de Usuario'
  end

  def send_data
    year = params[:user]["date(1i)"]
    month = params[:user]["date(2i)"]
    day = params[:user]["date(3i)"]
    dob = "#{year}-#{month}-#{day}"
    continue = true
    if not params[:"Nombre"].present?
      continue = false
    end
    if not params[:"Apellido"].present?
      continue = false
    end
    if not params[:"Documento Nacional de Identidad"].present?
      continue = false
    end
    
    if params[:image].present?
      image = params[:image] 
      encode = File.open(image.path, "rb") do |file|
        Base64.strict_encode64(file.read)
      end
    else
      continue = false
    end
    
    if continue
      data = {
        first_name:  params[:"Nombre"],
        last_name:  params[:"Apellido"],
        national_id:  params[:"Documento Nacional de Identidad"],
        birth_date:  dob,
        nationality:  "AR",
        document_file_name:  image.original_filename,
        document_content_type:  image.content_type,
        document_size:  image.size,
        document:  "data:#{image.content_type};base64,#{encode}"
      }
      @loading = true
      # 1) Create User
      user_id = create_user
      
      # 2) Create Issue
      issue_id = create_issue(user_id)
      
      # 3) Create Seed
      seed_id = create_seed(issue_id, data)
      
      # 4) Send Attachment
      attach_id = send_attach(seed_id, data)
      
      # 5) Send Natural docket seed
      code = natural_seed(issue_id, data)
  
      Rails.logger.info ":::::::::Final code: #{code}"
  
      if code.to_s == "201"
        redirect_to :action => "index"
      end
    end


  end




  def natural_seed(id, data)
    api = '6d39d72823d3392fb5e1cc0321f6b5e2269f7dc4c432eb2ba12ee7f7d81a32dba353e0e93d29365a'
    bitex_url = "https://sandbox.bitex.la/api/natural_docket_seeds"
    body = {
      data: {
        type: 'natural_docket_seeds',
        attributes: {
          first_name: data[:first_name],
          last_name: data[:last_name],
          nationality: data[:nationality],
          birth_date: data[:birth_date]
        },
        relationships: {
          issue: {
            data: {
              type: "issues",
              id: id
            }
          }
        }
      }
    }
      begin
        Rails.logger.info ":::::::Begin 5_natural_seed"
        uri = URI(bitex_url)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(uri)
        # TLS v1.2
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.ssl_version = :TLSv1_2
        if uri.scheme = "https"
          http.use_ssl = true
        end
        request["Authorization"] = api
        request["Content-Type"] = "application/json"
        request.body = body.to_json
        res = http.request(request)
        json_data = JSON.parse(res.body)
        Rails.logger.info ":::::::DATA 5_natural_seed #{json_data['data']['id']}"
        res.code
        rescue => e
          Rails.logger.error "Error 5_natural_seed:::#{e.message}"
      end
  end
  
  def send_attach(id, data)
    api = '6d39d72823d3392fb5e1cc0321f6b5e2269f7dc4c432eb2ba12ee7f7d81a32dba353e0e93d29365a'
    bitex_url = "https://sandbox.bitex.la/api/attachments"
    body = {
      data: {
        type: 'attachments',
        attributes: {
          document: data[:document],
          document_file_name: data[:document_file_name],
          document_content_type: data[:document_content_type],
          document_size: data[:document_size]
        },
        relationships: {
          attached_to_seed: {
            data: {
              id: id,
              type: "identification_seeds"
            }
          }
        }
      }
    }
      begin
        Rails.logger.info ":::::::Begin 4_send_attach"
        uri = URI(bitex_url)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(uri)
        # TLS v1.2
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.ssl_version = :TLSv1_2
        if uri.scheme = "https"
          http.use_ssl = true
        end
        request["Authorization"] = api
        request["Content-Type"] = "application/json"
        request.body = body.to_json
        res = http.request(request)
        json_data = JSON.parse(res.body)
        Rails.logger.info ":::::::DATA 4_send_attach #{json_data['data']['id']}"
        json_data['data']['id']
        rescue => e
          Rails.logger.error "Error 4_send_attach:::#{e.message}"
      end
  end

  def create_seed(id, data)
    api = '6d39d72823d3392fb5e1cc0321f6b5e2269f7dc4c432eb2ba12ee7f7d81a32dba353e0e93d29365a'
    bitex_url = "https://sandbox.bitex.la/api/identification_seeds"
    body = {
      data: {
        type: 'identification_seeds',
        attributes: {
          identification_kind_code: "national_id",
          issuer: "AR",
          number: data[:national_id]
        },
        relationships: {
          issue: {
            data: {
              type: "issues",
              id: id
            }
          }
        }
      }
    }
      begin
        Rails.logger.info ":::::::Begin 3_create_seed"
        uri = URI(bitex_url)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(uri)
        # TLS v1.2
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.ssl_version = :TLSv1_2
        if uri.scheme = "https"
          http.use_ssl = true
        end
        request["Authorization"] = api
        request["Content-Type"] = "application/json"
        request.body = body.to_json
        res = http.request(request)
        json_data = JSON.parse(res.body)
        Rails.logger.info ":::::::DATA 3_create_seed #{json_data['data']['id']}"
        json_data['data']['id']
        rescue => e
          Rails.logger.error "Error 3_create_seed:::#{e.message}"
      end
  end

  def create_issue(id)
    api = '6d39d72823d3392fb5e1cc0321f6b5e2269f7dc4c432eb2ba12ee7f7d81a32dba353e0e93d29365a'
    bitex_url = "https://sandbox.bitex.la/api/issues"
    body = {
      data: {
        type: 'issues',
        attributes: {
          reason_code: "new_client"
        },
        relationships: {
          issue: {
            data: {
              type: "users",
              id: id
            }
          }
        }
      }
    }
      begin
        Rails.logger.info ":::::::Begin 2_create_issue"
        uri = URI(bitex_url)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(uri)
        # TLS v1.2
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.ssl_version = :TLSv1_2
        if uri.scheme = "https"
          http.use_ssl = true
        end
        request["Authorization"] = api
        request["Content-Type"] = "application/json"
        request.body = body.to_json
        res = http.request(request)
        json_data = JSON.parse(res.body)
        Rails.logger.info ":::::::DATA 2_create_issue #{json_data['data']['id']}"
        json_data['data']['id']
        rescue => e
          Rails.logger.error "Error 2_create_issue:::#{e.message}"
      end
  end

  def create_user
    api = '6d39d72823d3392fb5e1cc0321f6b5e2269f7dc4c432eb2ba12ee7f7d81a32dba353e0e93d29365a'
    bitex_url = "https://sandbox.bitex.la/api/users"
    body = {
      data: {
        type: 'users'
      }
    }
      begin
        Rails.logger.info ":::::::Begin 1_create_user"
        uri = URI(bitex_url)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(uri)
        # TLS v1.2
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.ssl_version = :TLSv1_2
        if uri.scheme = "https"
          http.use_ssl = true
        end
        request["Authorization"] = api
        request["Content-Type"] = "application/json"
        request.body = body.to_json
        res = http.request(request)
        json_data = JSON.parse(res.body)
        Rails.logger.info ":::::::DATA 1_create_user #{json_data['data']['id']}"
        json_data['data']['id']
        rescue => e
          Rails.logger.error "Error 1_create_user:::#{e.message}"
      end
  end
end
