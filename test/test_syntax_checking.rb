require 'helper'
describe Pry do

  [
    ["puts '", "'"],
    ["def", "a", "(); end"],
    ["pp <<FOO", "lots", "and", "lots of", "foo", "FOO"],
    ["[", ":lets,", "'list',", "[/nested/", "], things ]"],
    ["abc =~ /hello", "/"],
    ["puts(<<HI, 'foo", "bar", "HI", "baz')"],
  ].each do |foo|
    it "should not raise an error on broken lines: #{foo.join("\\n")}" do
      output = StringIO.new
      redirect_pry_io(InputTester.new(*foo), output) do
        Pry.start
      end

      output.string.should.not =~ /SyntaxError/
    end
  end

  [
    ["end"],
    ["puts )("],
    ["1 1"],
    ["puts", ":"],
    ["def", "method(1"]
  ].each do |foo|
    it "should raise an error on invalid syntax like #{foo.inspect}" do
      output = StringIO.new
      redirect_pry_io(InputTester.new(*foo), output) do
        Pry.start
      end
      output.string.should =~ /SyntaxError/
    end
  end

  it "should re-raise syntax errors from nested evals" do
    output = StringIO.new
    redirect_pry_io(InputTester.new(%q{ eval('puts "') }), output) do
      Pry.start
    end
    output.string.should =~ /SyntaxError/
  end

  it "should re-raise syntax errors from nested bindings" do
    output = StringIO.new
    redirect_pry_io(InputTester.new(%q{ binding.eval('puts "', Pry.eval_path, Pry.current_line) }), output) do
      Pry.start
    end
    output.string.should =~ /SyntaxError/
  end

  # TODO: It would be nice to find a way to make this pass in ruby-1.8.7,
  # unfortunately, the backtrace and message of the exception are identical
  # to that of a real syntax error.
  # One possibility might be to instead temporarily monkey-patch Kernel#eval,
  # and not raise an error if that gets called.
  if RUBY_VERSION == '1.8' && RUBY_PLATFORM != "java"
    it "should re-raise syntax errors from very-nested evals" do
      output = StringIO.new
      redirect_pry_io(InputTester.new(%q{ eval(%q{ binding.eval('puts "', Pry.eval_path, Pry.current_line) }) }), output) do
        Pry.start
      end
      output.string.should =~ /SyntaxError/
    end
  end

  it "should re-raise syntax errors explicitly raised" do
    output = StringIO.new
    redirect_pry_io(InputTester.new(%q{raise SyntaxError, "unexpected $end"}), output) do
      Pry.start
    end
    output.string.should =~ /SyntaxError/
  end
end
