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

  def send(name, channel, messages)
    irc = IRCSocket.new(@server, @port)
    irc.connect
    raise IRCConnectError.new("can't connect #{@server}:#{@port}") unless irc.connected?

    irc.nick name
    irc.user name, 0, "*", "OnetimeIRCNotifier"

    while line = irc.read do
      case line.split[1]
      when '376'
        irc.join channel
        messages.each_line do |line|
          irc.privmsg channel, line.chomp
        end
        irc.part channel
        break
      when '433'
        raise IRCNickNameAlreadyUse.new(line)
      when /^[4,5]\d{2}/
        raise IRCError.new(line)
      end
    end
  end

  def send_with_changename(name, channel, messages)
    change_name = name
    begin
      send(change_name, channel, messages)
    rescue IRCNickNameAlreadyUse => e
      if change_name.size < 9
        change_name = "#{change_name}_"
        retry
      end
      raise e
    end
  end
end

