require_relative 'onetime-irc-notifier'
require_relative 'env-changer'

class NotifierPublisher < Jenkins::Tasks::Publisher
    def self.message(instance, options = {})
      return nil if instance.nil? || instance.messages.nil?

      @index ||= 0
      idx = @index
      @index += 1 if options[:with_next]
      @index = 0 if @index >= instance.messages.size

      return instance.messages[idx] ? instance.messages[idx][options[:key]] : nil
    end

    attr_reader :server, :port, :user, :channel, :messages

    display_name "IRC Onetime Notifier"

    # Invoked with the form parameters when this extension point
    # is created from a configuration screen.
    def initialize(attrs = {})
      attrs.each { |k, v| instance_variable_set "@#{k}", v }
      @messages = [@messages] if @messages.class == Hash
    end

    ##
    # Runs before the build begins
    #
    # @param [Jenkins::Model::Build] build the build which will begin
    # @param [Jenkins::Model::Listener] listener the listener for this build.
    def prebuild(build, listener)
      # do any setup that needs to be done before this build runs.
    end

    ##
    # Runs the step over the given build and reports the progress to the listener.
    #
    # @param [Jenkins::Model::Build] build on which to run this step
    # @param [Jenkins::Launcher] launcher the launcher that can run code on the node running this build
    # @param [Jenkins::Model::Listener] listener the listener for this build.
    def perform(build, launcher, listener)
      # actually perform the build step
      env = EnvChanger.new(build.native.getEnvironment())
      irc = OnetimeIRCNotifier.new(env.change(@server), env.change(@port).to_i)
      irc.connect_with_changename(env.change(@user), env.change(@channel)) do |connector|
        @messages.each do |message|
          next unless match_trigger?(build, message["trigger"])
          connector.send_messages(env.change(message["message"]))
        end
      end
    end

    private

    def match_trigger?(build, trigger)
      return true if trigger == "complete"

      case build.native.getResult.to_s
      when "SUCCESS"
        return trigger == "stable" || trigger == "stable_or_unstable"
      when "FAILURE"
        return trigger == "failed" || trigger == "unstable_or_failed"
      when "UNSTABLE"
        return trigger == "unstable" || trigger == "unstable_or_failed"
      end
      return false
    end
end
