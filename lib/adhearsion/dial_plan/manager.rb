module Adhearsion
  class DialPlan
    class Manager

      NoContextError = Class.new StandardError

      class << self
        def handle(call)
          new.handle call
        end
      end

      attr_accessor :dial_plan, :context

      def initialize
        @dial_plan = DialPlan.new
      end

      def handle(call)
        Events.trigger_immediately [:before_call], call
        ahn_log.dial_plan.notice "Handling call with ID #{call.id}"

        starting_entry_point = entry_point_for call
        raise NoContextError, "No dialplan entry point for call context '#{call.context}' -- Ignoring call!" unless starting_entry_point
        @context = ExecutionEnvironment.create call, starting_entry_point
        inject_context_names_into_environment @context
        @context.run
      rescue Hangup
        call.ahn_log "Hangup event for call with id #{call.id}"
        Events.trigger_immediately [:after_call], call
      rescue NoContextError => e
        call.ahn_log e.message
        raise e
      rescue SyntaxError, StandardError => e
        Events.trigger ['exception'], e
      ensure
        call.hangup!
      end

      # Find the dialplan by the context name from the call or from the
      # first path entry in the AGI URL
      def entry_point_for(call)
        # Try the request URI for an entry point first
        if call.respond_to?(:request) && m = call.request.path.match(%r{/([^/]+)})
          if entry_point = dial_plan.lookup(m[1].to_sym)
            return entry_point
          else
            ahn_log.warn "AGI URI requested context \"#{m[1]}\" but matching Adhearsion context not found! Falling back to Asterisk context."
          end
        end

        # Fall back to the matching Asterisk context name
        dial_plan.lookup call.context.to_sym
      end

      protected

      def inject_context_names_into_environment(environment)
        return unless dial_plan.entry_points
        dial_plan.entry_points.each do |name, context|
          environment.meta_def(name) { context }
        end
      end

    end
  end
end
