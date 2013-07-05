require 'irc-socket'

class OnetimeIRCNotifier
  class IRCConnectError < StandardError; end
  class IRCNickNameAlreadyUse < StandardError; end
  class IRCError < StandardError; end

  attr_accessor :server
  attr_accessor :port

  def initialize(server, port = 6667)
    @server = server
    @port ||= port
  end

  def connect(name, channel, &block)
    @irc = IRCSocket.new(@server, @port)
    @irc.connect
    @channel = channel
    raise IRCConnectError.new("can't connect #{@server}:#{@port}") unless @irc.connected?

    @irc.nick name
    @irc.user name, 0, "*", "OnetimeIRCNotifier"

    while line = @irc.read do
      case line.split[1]
      when '376'
        @irc.join @channel
        block.call(self)
        @irc.part @channel
        break
      when '433'
        raise IRCNickNameAlreadyUse.new(line)
      when /^[4,5]\d{2}/
        raise IRCError.new(line)
      end
    end

  ensure
    @irc = nil
    @channel = nil
  end

  def connect_with_changename(name, channel, &block)
    change_name = name
    begin
      connect(change_name, channel) do |irc|
        block.call(irc)
      end
    rescue IRCNickNameAlreadyUse => e
      if change_name.size < 9
        change_name = "#{change_name}_"
        retry
      end
      raise e
    end
  end

  def send_messages(messages)
    messages.each_line do |line|
      @irc.privmsg @channel, line.chomp
    end
    
  end
end

