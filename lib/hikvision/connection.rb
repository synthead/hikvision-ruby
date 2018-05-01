class Hikvision
  class Connection
    class BadCredentials < Faraday::ClientError; end

    def initialize(base_url:, user: nil, password: nil)
      @base_uri = URI(base_url)
      @user = user
      @password = password
      @cookies = ''

      @faraday = Faraday.new do |faraday|
        faraday.response :xml, content_type: /\bxml$/
        faraday.response :raise_error

        faraday.adapter :excon

        faraday.headers['Cookie'] = @cookies
      end
    end

    def get(path, query: nil, login: true)
      send(
        submit_method(login),
        :get, path, query: query
      )
    end

    def put(path, data: nil, xml: nil, xml_root: nil, query: nil, login: true)
      send(
        submit_method(login),
        :put, path, data: data, xml: xml, xml_root: xml_root, query: query
      )
    end

    def post(path, data: nil, xml: nil, xml_root: nil, query: nil, login: true)
      send(
        submit_method(login),
        :post, path, data: data, xml: xml, xml_root: xml_root, query: query
      )
    end

    private

    def submit_method(login)
      login ? :submit_with_login : :submit_without_login
    end

    def url_builder(path, query: nil)
      uri = @base_uri.dup
      path_uri = URI(path)
      uri.path = File.join(uri.path, 'ISAPI', path_uri.path)
      uri.query = URI.encode_www_form(query) if query

      uri.to_s
    end

    def clear_cookies!
      @cookies.replace('')
    end

    def submit_without_login(
      http_method, path, data: nil, xml: nil, xml_root: nil, query: nil
    )
      url = url_builder(path, query: query)
      data = xml.to_xml(root: xml_root) if xml
      response = @faraday.send(http_method, url, data)

      response.body
    rescue Faraday::ClientError
      clear_cookies!
      raise($!)
    end

    def logged_in?
      @cookies != ''
    end

    def submit_with_login(
      http_method, path, data: nil, xml: nil, xml_root: nil, query: nil
    )
      login unless logged_in?

      retried = false

      begin
        submit_without_login(
          http_method, path, data: data, xml: xml, xml_root: xml_root, query: query
        )
      rescue Faraday::ClientError
        raise($!) if retried == true
        retried = true

        login
        retry
      end
    end

    def set_session_id(response)
      session_id = response['SessionLogin']['sessionID']
      @cookies.replace("WebSession=#{session_id}")
    end

    def login
      session_login_capabilities = get_session_login_capabilities
      digest = generate_digest(session_login_capabilities)

      login_response = post_session_login(session_login_capabilities, digest)
      set_session_id(login_response)
    end

    def get_session_login_capabilities
      login_cap = get(
        'Security/sessionLogin/capabilities',
        query: { username: @user },
        login: false
      )

      raise(
        BadCredentials, 'No salt returned'
      ) if login_cap['SessionLoginCap']['salt'].nil?

      login_cap['SessionLoginCap']
    end

    def raise_if_no_credentials
      raise(BadCredentials, 'No user provided') unless @user
      raise(BadCredentials, 'No password provided') unless @password
    end

    def sha256(to_encode)
      Digest::SHA256.digest(to_encode).unpack('H*').first
    end

    def generate_digest(login_session_capabilities)
      raise_if_no_credentials

      digest = sha256(@user + login_session_capabilities['salt'] + @password)
      digest = sha256(digest + login_session_capabilities['challenge'])

      iterations = login_session_capabilities['iterations'].to_i - 2
      iterations.times { digest = sha256(digest) }

      digest
    end

    def now_epoch_ms
      DateTime.now.strftime('%Q')
    end

    def post_session_login(login_session_capabilities, digest)
      xml = {
        userName: @user,
        password: digest,
        sessionID: login_session_capabilities['sessionID']
      }

      post(
        'Security/sessionLogin',
        xml_root: 'SessionLogin',
        xml: xml,
        query: { timeStamp: now_epoch_ms },
        login: false
      )
    rescue Faraday::ClientError
      raise(BadCredentials, $!)
    end
  end
end
