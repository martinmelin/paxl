#!/usr/bin/env ruby

require 'lib/rdparse'
require 'nodes'

module Paxl
  
  class Parser
    
    include Paxl::Nodes
    
    def initialize(log = false)
      
      @parser = Rdparse::Parser.new('paxl', log) do
        
        @scope = Hash.new
        
        token(/\s+/)
        token(/and|or|==|!=|<=|>=|\w+|./) { |m| m }
        
        start :stmt_list do
          match(:stmt, :stmt_term, :stmt_list) { |a, _, b| b = a + b }
          match(:stmt, :stmt_term)
          match(:stmt)
        end
        
        rule :stmt_term do
          match("\n")
          match(";")
        end
        
        rule :stmt do
          match(:if_stmt) { |a| PStatementList.new a }
          match(:for_loop) { |a| PStatementList.new a }
          match(:expr) { |a| PStatementList.new a }
        end
        
        rule :for_loop do
          match('for', '(', :stmt_list, ')', '{', :stmt_list, '}') do
            |_, _, a, _, _, b, _| PForLoop.new(a, b)
          end
        end
        
        rule :if_stmt do
          match('if', '(', :stmt_list, ')', '{', :stmt_list, '}',
          	'else', '{', :stmt_list, '}') do
            |_, _, a, _, _, b, _, _, _, c, _| PIfStatement.new(a, b, c)
          end
          match('if', '(', :stmt_list, ')', '{', :stmt_list, '}') do
            |_, _, a, _, _, b, _| PIfStatement.new(a, b, nil)
          end
        end
        
        rule :expr do
          match('{', '|', :param_list, '|', :stmt_list, '}') do
          	|_, _, a, _, b, _| PBlockDefinition.new(a, b)
          end
          match('{', :stmt_list, '}') { |_, a, _| PBlockDefinition.new([], a) }
          match(:identifier, '(', ')') { |a, _, _| PBlockCall.new(a, []) }
          match(:identifier, '(', :stmt_list, ')') { |a, _, b, _| PBlockCall.new(a, b) }
          match(:expr, '+', :term) { |a, _, b| PAddition.new(a, b) }
          match(:expr, '-', :term) { |a, _, b| PSubtraction.new(a, b) }
          match(:expr, :logical_operator, :term) { |a, op, b| PLogicalExpression.new(a, op, b) }
          match('not', :expr) { |op, a| PLogicalExpression.new(a, op, PBoolean.new(1)) }
          match(:expr, :comparison_operator, :term) do 
          	|a, op, b| PComparison.new(a, op, b)
          end
          match(:term)
        end
        
        rule :term do
          match(:term, '*', :atom) { |a, _, b| PMultiplication.new(a, b) }
          match(:term, '/', :atom) { |a, _, b| PDivision.new(a, b) }
          match(:atom)
        end
        
        rule :var do
          match(:identifier, '=', :expr) { |a, _, b| PVariableAssignment.new(a, b) }
          match(:identifier) { |a| PVariableReference.new(a) }
        end
        
        rule :param_list do
          match(:identifier, ',', :param_list) { |a, _, b| b + [a] }
          match(:identifier) { |a| [a] }
        end
        
        rule :identifier do
          match(/[a-zA-Z][A-Za-z0-9_]*/)
        end
        
        rule :comparison_operator do
          match('==')
          match('!=')
          match('<=')
          match('>=')
          match('<')
          match('>')
        end
        
        rule :logical_operator do
          match('and')
          match('or')
        end
        
        rule :atom do 
          match(:boolean)
          match(:number)
          match(:var)
          match('(', :expr, ')') { |_, a, _| a }
        end
        
        rule :boolean do
          match('true') { PBoolean.new(1) }
          match('false') { PBoolean.new(0) }
        end
        
        rule :number do
          match(:float)
          match(:integer)
        end
        
        rule :float do
          match(:digits, '.', :digits) { |a, _, b| PFloat.new("#{a}.#{b}") }
          match('.', :digits) { |_, a| PFloat.new("0.#{a}") }
        end
        
        rule :integer do
          match(:digits) { |a| PInteger.new(a) }
        end
        
        rule :digits do
          match(:digits, :digit) { |a, b| a += b }
          match(:digit)
        end
        
        rule :digit do
          match(/[0-9]/)
        end
        
      end
      
    end
    
    def parse(code)
      @parser.parse(code)      
    end
    
    def interactive
      puts "Welcome to the Paxl interactive parser (type 'exit' to quit)"
      code = ""
      global_scope = Paxl::Scope.new(nil)
      while true
        print "Paxl: "
        line = gets
        break if line.chomp == "exit"
        
        code += line
        
        result = parse(code).eval(global_scope)
        print "=> "
        puts result
        code = ""
      end
      puts "Goodbye!"
    end
    
  end
  
end