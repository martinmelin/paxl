#!/usr/bin/env ruby
require 'rubygems'
require 'spreadsheet'
require 'paxl'

filename = ARGV.shift
if not filename
  abort "I expect a .xls filename as an argument"
end
book = Spreadsheet.open filename
sheet = book.worksheet 0
number_of_threads = 4
threads = []

sheet.each_slice(number_of_threads) do |rows|
  threads << Thread.new(rows) do |rows|
    p = Paxl::Parser.new
    rows.each do |row|
      row_scope = Paxl::Scope.new(nil)
      column_labels = ('A'..'Z').to_a
      values = []
      row.each do |cell|
        code = "#{cell}"
        lbl = column_labels.shift
        result = p.parse(code).eval(row_scope)
        row_scope[lbl] = result
        values << result
      end
      puts "#{row.idx}," + values.join(",")
    end
  end
end

threads.each { |t| t.join }