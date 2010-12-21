direc = File.dirname(__FILE__)

require 'bacon'
require "#{direc}/../lib/pry"
require "#{direc}/test_helper"

describe Pry do
  describe "open a Pry session on an object" do
    describe "rep" do
      it 'should set an ivar on an object' do
        input_string = "@x = 10"
        input = InputTester.new(input_string)
        output = OutputTester.new
        o = Object.new

        pry_tester = Pry.new(input, output)
        pry_tester.rep(o)
        o.instance_variable_get(:@x).should == 10
      end

      it 'should make self evaluate to the receiver of the rep session' do
        output = OutputTester.new
        o = Object.new
        
        pry_tester = Pry.new(InputTester.new("self"), output)
        pry_tester.rep(o)
        output.output_buffer.should == o
      end
    end

    describe "repl" do
      describe "commands" do

        before do
          Pry.input = InputTester.new("exit")
          Pry.output = OutputTester.new
        end

        after do
          Pry.reset_defaults
        end
        
        { "!" => "refresh",
          "help" => "show_help",
          "nesting" => "show_nesting",
          "status" => "show_status",
          "cat dummy" => "cat",
          "cd 3" => "cd",
          "ls" => "ls",
          "show_method test_method" => "show_method",
          "show_imethod test_method" => "show_method",
          "show_doc test_method" => "show_doc",
          "show_idoc test_method" => "show_doc",
          "jump_to 0" => "jump_to"
        }.each do |command, meth|

          eval %{
            it "should invoke output##{meth}  when #{command} command entered" do
              input_strings = ["#{command}", "exit"]
              input = InputTester.new(input_strings)
              output = OutputTester.new
              o = Class.new
          
              pry_tester = Pry.new(input, output)
              pry_tester.repl(o)

              output.#{meth}_invoked.should == true
              output.session_end_invoked.should == true
            end
          }


          # it "should invoke output#help when help command entered" do
          #   input_strings = ["help", "exit"]
          #   input = InputTester.new(input_strings)
          #   output = OutputTester.new
          #   o = Object.new
          
          #   pry_tester = Pry.new(input, output)
          #   pry_tester.repl(o)

          #   output.show_help_invoked.should == true
          #   output.session_end_invoked.should == true
          # end

          # it 'should set an ivar on an object and exit the repl' do
          #   input_strings = ["@x = 10", "exit"]
          #   input = InputTester.new(input_strings)
          #   output = OutputTester.new

          #   o = Object.new

          #   pry_tester = Pry.new(input, output)
          #   pry_tester.repl(o)

          #   o.instance_variable_get(:@x).should == 10
          #   output.session_end_invoked.should == true
          # end
        end
      end
    end
  end
end