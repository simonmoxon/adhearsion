module Adhearsion
  module DSL
    # In Ruby, a number with a leading zero such as 023.45 or 023 does not evaluate as expected.
    # In the case of the float 023.45, you get a syntax error. In the case of 023 the number is
    # parsed as being in octal form and the number 19 is returned.
    #
    # In Adhearsion, various strings that are entirely numeric might start with zero and that zero
    # should be preserved when converting that string of numbers into a number. The numerical string
    # retains the zero while still allowing it to be compared to other numbers.
    #
    # [[I think this leading zero thing is only part of the reason that NumericalString exists. I'm
    # currently writing tests for this leading zero stuff so I thought I'd dump some of my assumptions
    # about it here in the documentation.]]
    class NumericalString
      class << self
        def starts_with_leading_zero?(string)
          string.to_s[/^0\d+/]
        end
      end

      (instance_methods.map{|m| m.to_sym} - [:instance_eval, :object_id, :class]).each { |m| undef_method m unless m.to_s =~ /^__/ }

      attr_reader :__real_num, :__real_string

      def initialize(str)
        @__real_string = str.to_s
        @__real_num = str.to_i if @__real_string =~ /^\d+$/
      end

      def method_missing(name, *args, &block)
        @__real_string.__send__ name, *args, &block
      end

      def respond_to?(m)
        @__real_string.respond_to?(m) || m == :__real_num || m == :__real_string
      end

      def ==(x)
        return x.is_a?(Fixnum) ? x == @__real_num : x == @__real_string
      end
      alias :=== :==

      def is_a?(obj)
        case obj.to_s
        when "Fixnum" then true
        when "String" then true
        end
      end
      alias :kind_of? :is_a?

    end

  end
end

# These monkey patches are necessary for the NumericalString to work, unfortunately.
class Class
  def alias_method_once(new_name, old_name)
    unless instance_methods.map{|m| m.to_sym}.include?(new_name.to_sym)
      alias_method(new_name, old_name)
    end
  end
end

[Object, Range, class << String; self; end].each do |klass|
  klass.alias_method_once(:pre_modified_threequal, :===)
end

class Object
  def ===(arg)
    if arg.respond_to? :__real_string
      arg = arg.__real_num if kind_of?(Numeric) || kind_of?(Range)
      pre_modified_threequal arg
    else
      pre_modified_threequal arg
    end
  end
end

class Range
  alias_method_once(:original_threequal, :===)
  def ===(arg)
    if (arg.respond_to? :__real_string) &&  !arg.__real_num.nil?
      arg = arg.__real_num
      original_threequal arg
    else
      original_threequal arg
    end
  end
end

class << String
  alias_method_once(:original_threequal, :===)
  def ===(arg)
    arg.respond_to?(:__real_string) || original_threequal(arg)
  end
end
