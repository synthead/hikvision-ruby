class Hikvision
  class Camera
    def initialize(base_url:, user: nil, password: nil)
      @connection = Connection.new(
        base_url: base_url,
        user:     user,
        password: password
      )
    end

    def reboot!
      @connection.put('System/reboot')
    end

    def day!
      @connection.put(
        'Image/channels/1/ircutFilter',
        xml_root: 'IrcutFilter',
        xml: { IrcutFilterType: 'day' }
      )
    end

    def night!
      @connection.put(
        'Image/channels/1/ircutFilter',
        xml_root: 'IrcutFilter',
        xml: { IrcutFilterType: 'night' }
      )
    end
  end
end
