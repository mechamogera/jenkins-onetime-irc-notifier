require 'irc-socket'


class OnetimeIRCNotifier
  class IRCConnectError < StandardError; end
  class IRCNickNameError < StandardError; end
  class IRCError < StandardError; end

  attr_accessor :server
  attr_accessor :port
  attr_accessor :name

  def initialize(opts)
    [:server, :port, :name].each { |opt| instance_variable_set "@#{opt}", opts[opt] }
    @port ||= 6667
  end

  def send(channel, message)
    irc = IRCSocket.new(@server, @port)
    irc.connect
    raise IRCConnectError.new("can't connect #{@server}:#{@port}") unless irc.connected?

    irc.nick @name
    irc.user @name, 0, "*", "OnetimeIRCNotifier"

    while line = irc.read do
p line
      case line.split[1]
      when '376'
        irc.join channel
        message.each_line do |line|
          irc.privmsg channel, line.chomp
        end
        irc.part channel
        break
      when '433'
        raise IRCNickNameError.new(line)
      when /^[4,5]\d{2}/
        raise IRCError.new(line)
      end
    end
  end
end

if __FILE__ == $0
  irc = OnetimeIRCNotifier.new(:server => "localhost", :name => "uge")
  irc.send("#hoge", "hemo")
end
