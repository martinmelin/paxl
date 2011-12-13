#!/usr/bin/env ruby
module Paxl
  module Nodes
    
    class Node
    end
    
    class PStatementList < Node
      
      def initialize(statement)
        if statement.kind_of? Array
          @statement_list = statement
        else
          @statement_list = [statement]
        end
      end
      
      def +(statement_list)
        self.class.new @statement_list + statement_list.list
      end
      
      def list
        @statement_list
      end
      
      def eval(scope)
        result = nil
        @statement_list.each do |statement|
          result = statement.eval(scope)
        end        
        return result
      end
      
    end
    
    class PForLoop < Node
      
      def initialize(control, statements)
        @control, @statements = control, statements
      end
      
      def eval(scope)
        my_scope = Paxl::Scope.new(scope)
        init_stmt, test_stmt, iter_stmt = @control.list
        init_stmt.eval(my_scope)
        return_value = nil
        while test_stmt.eval(my_scope) do
          return_value = @statements.eval(my_scope)
          iter_stmt.eval(my_scope)
        end
        return_value
      end
      
    end
    
    class PIfStatement < Node
      
      def initialize(test, if_true, if_false)
        @test, @if_true, @if_false = test, if_true, if_false
      end
      
      def eval(scope)
        test_result = @test.eval(scope)
        if test_result
          @if_true.eval(scope)
        else
          if @if_false
            @if_false.eval(scope)
          else
            nil
          end
        end
      end
      
    end
    
    class PBlockDefinition < Node
      
      attr_reader :parameters, :statement_list, :block_scope
      
      def initialize(parameters, statements)
        @parameters, @statement_list = parameters, PStatementList.new(statements)
      end
      
      def eval(scope)
        @block_scope = scope.clone
        @block_scope["this"] = self
        self
      end
      
    end
    
    class PBlockCall < Node
      
      def initialize(identifier, arguments)
        @identifier, @arguments = identifier, arguments
      end
      
      def eval(scope)
        block_def = scope[@identifier]
        if not block_def.kind_of? Paxl::Nodes::PBlockDefinition
          return "Error! Attempting to use a non-block as a block."
        end
        my_scope = block_def.block_scope.clone
        if @arguments.kind_of? Paxl::Nodes::PStatementList
          arguments = Array.new(@arguments.list)
        end
        block_def.parameters.each do |param|
          my_scope[param] = arguments.pop().eval(scope)
        end
        block_def.statement_list.eval(my_scope)
      end
      
    end
    
    class PVariableAssignment < Node
      
      def initialize(identifier, value)
        @identifier, @value = identifier, value
      end
      
      def eval(scope)
        scope[@identifier] = @value.eval(scope)
      end
      
    end
    
    class PVariableReference < Node
      
      def initialize(identifier)
        @identifier = identifier
      end
      
      def eval(scope)
        scope[@identifier]
      end
      
    end
    
    class PLogicalExpression < Node
      
      def initialize(a, op, b)
        @a, @op, @b = a, op, b
      end
      
      def eval(scope)
        a, b = @a.eval(scope), @b.eval(scope)
        case @op
        when "and"
          return PBoolean.new( (a and b) ).eval(scope)
        when "or"
          return PBoolean.new( (a or b) ).eval(scope)
        when "not"
          return PBoolean.new( (not a) ).eval(scope)
        end
      end
      
    end
    
    class PComparison < Node
      
      def initialize(a, op, b)
        @a, @op, @b = a, op, b
      end
      
      def eval(scope)
        a, b = @a.eval(scope), @b.eval(scope)
        case @op
        when "=="
          return PBoolean.new( (a == b) ).eval(scope)
        when "!="
          return PBoolean.new( (a != b) ).eval(scope)
        when "<="
          return PBoolean.new( (a <= b) ).eval(scope)
        when ">="
          return PBoolean.new( (a >= b) ).eval(scope)
        when "<"
          return PBoolean.new( (a < b) ).eval(scope)
        when ">"
          return PBoolean.new( (a > b) ).eval(scope)
        end
      end
      
    end
    
    class PMultiplication < Node
      
      def initialize(a, b)
        @a, @b = a, b
      end
      
      def eval(scope)
        @a.eval(scope) * @b.eval(scope)
      end
      
    end
    
    class PDivision < Node
      
      def initialize(a, b)
        @a, @b = a, b
      end
      
      def eval(scope)
        @a.eval(scope) / @b.eval(scope)
      end
      
    end
    
    class PAddition < Node
      
      def initialize(a, b)
        @a, @b = a, b
      end
      
      def eval(scope)
        @a.eval(scope) + @b.eval(scope)
      end
      
    end
    
    class PSubtraction < Node
      
      def initialize(a, b)
        @a, @b = a, b
      end
      
      def eval(scope)
        @a.eval(scope) - @b.eval(scope)
      end
      
    end
   
    class PInteger < Node
      
      def initialize(value)
        @value = value.to_i
      end
      
      def eval(scope)
        @value
      end
      
    end
    
    class PFloat < Node
      
      def initialize(value)
        @value = value.to_f
      end
      
      def eval(scope)
        @value
      end
      
    end
    
    class PBoolean < Node
      
      def initialize(value)
        if value == true or value == false
          @value = value
        else
          @value = (value != 0) # false if value == 0, true otherwise
        end
      end
      
      def eval(scope)
        @value
      end
      
    end
    
  end
    
  class Scope < Hash
    def initialize(parent)
      super
      @parent = parent
    end
    
    def [](key)
      if self.has_key? key
        return super(key)
      else
        if @parent.nil?
          return nil
        else
          return @parent[key]
        end
      end
    end
    
    def []=(key, value)
      current_value = self[key]
      if self.has_key? key or current_value.nil?
        super(key, value)
      else
        @parent[key] = value
      end
    end
    
  end
end