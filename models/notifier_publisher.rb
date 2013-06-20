require_relative 'onetime-irc-notifier'

class NotifierPublisher < Jenkins::Tasks::Publisher

    attr_reader :server, :port, :user, :channel, :message

    display_name "IRC Onetime Notifier"

    # Invoked with the form parameters when this extension point
    # is created from a configuration screen.
    def initialize(attrs = {})
      attrs.each { |k, v| instance_variable_set "@#{k}", v }
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
      irc = OnetimeIRCNotifier.new(@server, @port.to_i)
      irc.send_with_changename(@user, @channel, @message.split("\n"))
    end

end