module Submitted

def self.open_description(changenum, prompt, root)
    p4desc(changenum, prompt, root)
end

def self.getWorkspaces(user)
    workspacesRoots={}
    raw=`p4 workspaces -u #{user}`
    workspaces=raw.scan(/Client ([^ ]*) /)
    roots=raw.scan(/root ([^ ]*) /)
    workspaces.zip(roots).each do |key, val|
        workspacesRoots[key[0]] = val[0]
    end
    return workspacesRoots
end

def self.clearScreen()
    puts "\e[H\e[2J"
end

def self.getChangeList(user)
    raw=`p4 changes -u #{user} -s submitted`
    colour=raw.gsub(/by #{user}@#{user}\.([^ ]*)/) {|match| tmp = "[#{match}]".red}
    colour=colour.gsub(/by #{user}@#{user}\./, "at ")
    colour=colour.gsub(/ [0-9]* /) {|match| match.cyan}
    colour=colour.gsub(/'.*'/) {|match| match.yellow}
    colour=`echo "#{colour}" | column -ts"'"`
    return colour, raw
end

def self.main (prompt, user)
pursue = true
while pursue
    catch :ctrl_c do begin
        clearScreen
        unless $lastAction.empty?
            puts $lastAction
        end
        spinner = TTY::Spinner.new("[:spinner] Getting list...", format: :pulse_2)
        spinner.auto_spin
        workRoots=getWorkspaces user
        coloutput, output=getChangeList user
        changes=output.scan(/Change ([0-9]+) /)
        spinner.stop("#{changes.length} changes")

        choice = prompt.select("Changelist #", per_page: 30, filter: true) do |menu|
            menu.default 1
            changes.zip(coloutput.scan(/^.*$/)).each do |value, name|
                menu.choice name: name, value: value[0]
            end
        end

          workspace = output.scan(/Change #{choice}.*@([^ ]*) /)
          root = workRoots[workspace.join('')]
          open_description choice, prompt, root
    rescue TTY::Reader::InputInterrupt
        pursue = false
    rescue Exception => e
        $lastAction=e.inspect
    end
    end
end
end

end
