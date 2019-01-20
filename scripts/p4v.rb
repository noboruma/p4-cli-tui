require 'tty-prompt'
prompt = TTY::Prompt.new
require 'tty-reader'
reader = TTY::Reader.new
require 'tty-spinner'
require 'colorize'

@user   = ""
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
    raw=`p4 changes -u #{user} -s pending | sort -`
    colour=raw.gsub(/by #{user}@#{user}\./,"at [")
    colour=colour.gsub(/ \*pending\* /,"] ")
    colour=colour.gsub(/\[.*\]/) {|match| match.red}
    colour=colour.gsub(/ [0-9]* /) {|match| match.cyan}
    colour=colour.gsub(/'.*'/) {|match| match.yellow}
    #colour=`echo "#{colour}" | column -ts\'`
    return colour, raw
end

trap("SIGINT") { throw :ctrl_c }

#catch :ctrl_c do begin
while true
    spinner = TTY::Spinner.new("[:spinner] Getting list...", format: :pulse_2)
    spinner.auto_spin
    coloutput, output=getChangeList @user
    changes=output.scan(/Change ([0-9]+) /)
    spinner.stop("#{changes.length} changes")
    puts coloutput

    choice = prompt.select("Changelist #") do |menu|
        changes.each do |value|
            menu.choice name: value[0], value: value
        end
    end
    open_description choice[0], prompt, reader
end
#rescue Exception
#   puts "Stop"
#end
#end
