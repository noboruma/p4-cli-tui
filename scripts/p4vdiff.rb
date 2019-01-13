require 'tty-prompt'
prompt = TTY::Prompt.new

output=`ls`

output_arr=[]
output.each_line do |var|
    sym = var.delete!("\n").to_sym
    output_arr.push(sym)
end

diffAll = prompt.yes?("Diff all?")

chosen_paths = []
if diffAll
    output_arr.each do |choice|
        chosen_paths.append choice
    end
else
    choices = prompt.multi_select("Choose between:") do |menu|
        output_arr.each do |var|
            menu.choice var
        end
    end
    choices.each do |choice|
        chosen_paths.append choice.to_sym
    end
end

puts "#{chosen_paths}"
