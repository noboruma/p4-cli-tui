require 'tty-prompt'
prompt = TTY::Prompt.new
require 'tty-reader'
reader = TTY::Reader.new
require 'tty-spinner'

@tmpdir = "/tmp/p4v"

require './p4desc.rb'

# Modes:
# :changelist_viewer -> changelists viewer
# :description_viewer -> changelist description

mode = :changelist_viewer

def exit_mode()
    mode = :changelist_viewer
end

def open_description(changenum, prompt, reader)
    mode = :description_viewer
    puts changenum
    p4desc(changenum, prompt, reader)
end

def getChangeList(user)
    RAW=`p4 changes -u #{user} -s pending`
    OUTPUT=`echo #{RAW} | sort - | sed 's/by #{user}@#{user}\./at [/g' | sed 's/ \*pending\* /] /g' | GREP_COLOR='01;33' grep --color=always "\[.*\]" | GREP_COLOR='01;32' grep --color=always " [0-9]* " | GREP_COLOR='01;31' grep --color=always "'.*'$" | column -ts\'`
    COLOR_LINES=`echo #{OUTPUT} | wc -l`
    RAW_LINES=`echo #{RAW} | wc -l`

    if COLOR_LINES != RAW_LINES
        raise "poised coloring"
    end
    return OUTPUT
end

trap("SIGINT") { throw :ctrl_c }

#catch :ctrl_c do begin
while true
    spinner = TTY::Spinner.new("[:spinner] Getting list...", format: :pulse_2)
    spinner.auto_spin
    output=getChangeList("")
    puts output
    changes=output.scan(/Change ([0-9]+) /)
    spinner.stop("#{changes.length} changes")

    choice = prompt.select("Changelist #") do |menu|
        changes.each do |value|
            menu.choice name: value[0], value: value
        end
    end

    open_description choice, prompt, reader
end
#rescue Exception
#   puts "Stop"
#end
#end
