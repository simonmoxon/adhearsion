module Adhearsion
  module DSL
    class DialingDSL
      class RouteRule

        attr_reader :patterns, :providers

        def initialize(hash={})
          @patterns  = Array hash[:patterns]
          @providers = Array hash[:providers]
        end

        def merge!(other)
          providers.concat other.providers
          patterns.concat  other.patterns
          self
        end

        def >>(other)
          case other
            when RouteRule then merge! other
            when ProviderDefinition then providers << other
            else raise RouteException, "Unrecognized object in route definition: #{other.inspect}"
          end
          self
        end

        def |(other)
          case other
            when RouteRule then merge! other
            when Regexp
              patterns << other
              self
            else raise other.inspect
          end
        end

        def ===(other)
          patterns.each { |pattern| return true if pattern === other }
          false
        end

        def unshift_pattern(pattern)
          patterns.unshift pattern
        end

        class RouteException < StandardError; end

      end
    end
  end
end
