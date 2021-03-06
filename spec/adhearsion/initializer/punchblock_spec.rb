require 'spec_helper'

describe Adhearsion::Initializer::Punchblock do
  def initialize_punchblock_with_defaults
    initialize_punchblock_with_options Hash.new
  end

  def initialize_punchblock_with_options(options)
    flexmock(Adhearsion::Initializer::Punchblock).should_receive(:connect)
    Adhearsion::Configuration.configure { |config| config.enable_punchblock options }
    Adhearsion::Initializer::Punchblock.start
  end

  it "starts the client" do
    initialize_punchblock_with_defaults
  end

  it "starts the client with any overridden settings" do
    overrides = {:username => 'userb@127.0.0.1', :password => '123', :wire_logger => ahn_log.pb.wire, :transport_logger => ahn_log.pb, :auto_reconnect => false}
    flexmock(::Punchblock::Connection).should_receive(:new).once.with(overrides).and_return do
      flexmock 'Client', :event_queue => Queue.new
    end
    initialize_punchblock_with_options overrides
  end

  it "starts up a dispatcher"
end
