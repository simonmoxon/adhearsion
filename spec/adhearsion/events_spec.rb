require 'spec_helper'

module Adhearsion
  describe Events do

    EventClass = Class.new
    ExceptionClass = Class.new StandardError

    it "should have a GirlFriday::Queue to handle events" do
      Events.queue.should be_a GirlFriday::WorkQueue
    end

    it "should allow adding events to the queue and handle them appropriately" do
      t = nil
      o = nil
      latch = CountDownLatch.new 1

      flexmock(Events).should_receive(:handle_message).and_return do |message|
        t = message.type
        o = message.object
        latch.countdown!
      end

      Events.trigger :event, :foo

      latch.wait(10).should be_true
      t.should == :event
      o.should == :foo
    end

    it "should allow executing events immediately" do
      t = nil
      o = nil

      flexmock(Events).should_receive(:handle_message).and_return do |message|
        sleep 0.25
        t = message.type
        o = message.object
      end

      Events.trigger_immediately :event, :foo

      t.should == :event
      o.should == :foo
    end

    it "should handle events using registered guarded handlers" do
      result = nil

      Events.register_handler :event, EventClass do |event|
        result = :foo
      end

      Events.trigger_immediately :event, EventClass.new

      result.should == :foo

      Events.clear_handlers :event, EventClass
    end

    it "should handle exceptions in event processing by raising the exception as an event" do
      flexmock(Events).should_receive(:trigger).with(:exception, ExceptionClass).once

      Events.register_handler :event, EventClass do |event|
        raise ExceptionClass
      end

      Events.trigger_immediately :event, EventClass.new
    end

    describe '#draw' do
      it "should allow registering handlers by type" do
        result = nil
        Events.draw do
          event do
            result = :foo
          end
        end

        Events.trigger_immediately :event

        result.should == :foo

        Events.clear_handlers :event
      end
    end

  end
end
