require "pry/default_commands/ls"

class Pry
  module DefaultCommands

    Context = Pry::CommandSet.new do
      import Ls

      command 'cd', 'Start a Pry session on VAR (use `cd ..` to go back and `cd /` to return to Pry top-level)',  
      :argument_required => true do |argument|
        case argument
        when ".."
          _pry_.binding_stack.size == 1 ? output.puts('At root of stack.') : _pry_.binding_stack.pop
        when "/"
          _pry_.binding_stack.slice! 1..-1  
        when "::"
          _pry_.binding_stack = [ TOPLEVEL_BINDING ]
        else
          obj = target.eval arg_string
          _pry_.binding_stack.push Pry.binding_for(obj)
        end
      end

      command "show-stack", "Show binding stack information." do
        _pry_.binding_stack.each.with_index do |bind, index|
          output.puts "#{index+1}. #{Pry.view_clip(bind.eval("self"))}"
        end
      end

      command "jump-to", 
              "Jump to a Pry session further up the stack, exiting all sessions below.",
              :argument_required => true do |index|
        
        index = index.to_i
        if (1.._pry_.binding_stack.size).include? index 
          _pry_.binding_stack.slice! index..-1
        else
          output.puts "Stack isn't that big! Choose between 1..#{_pry_.binding_stack.size}"
        end
      end

      command "exit", "End the current Pry session. Accepts optional return value." do
        throw :breakout, target.eval(opts[:arg_string])
      end

      command "exit-program", "End the current program. Aliases: quit-program, !!!" do
        Pry.active_instance.save_history if Pry.config.history.should_save
        exit
      end

      alias_command "quit-program", "exit-program", ""
      alias_command "!!!", "exit-program", ""

      command "!pry", "Start a Pry session on current self; this even works mid-expression." do
        target.pry
      end

      command "whereami", "Show the code context for the session. (whereami <n> shows <n> extra lines of code around the invocation line. Default: 5)" do |num|
        file = target.eval('__FILE__')
        line_num = target.eval('__LINE__')
        klass = target.eval('self.class')

        if num
          i_num = num.to_i
        else
          i_num = 5
        end

        meth_name = meth_name_from_binding(target)
        meth_name = "N/A" if !meth_name

        if file =~ /(\(.*\))|<.*>/ || file == "" || file == "-e"
          output.puts "Cannot find local context. Did you use `binding.pry` ?"
          next
        end

        set_file_and_dir_locals(file)
        output.puts "\n#{text.bold('From:')} #{file} @ line #{line_num} in #{klass}##{meth_name}:\n\n"

        # This method inspired by http://rubygems.org/gems/ir_b
        File.open(file).each_with_index do |line, index|
          line_n = index + 1
          next unless line_n > (line_num - i_num - 1)
          break if line_n > (line_num + i_num)
          if line_n == line_num
            code =" =>#{line_n.to_s.rjust(3)}: #{line.chomp}"
            if Pry.color
              code = CodeRay.scan(code, :ruby).term
            end
            output.puts code
            code
          else
            code = "#{line_n.to_s.rjust(6)}: #{line.chomp}"
            if Pry.color
              code = CodeRay.scan(code, :ruby).term
            end
            output.puts code
            code
          end
        end
      end

    end
  end
end
