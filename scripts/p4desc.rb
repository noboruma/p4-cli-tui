require 'tty-progressbar'

def p4getdiffs(changeListNum, desc)
  pendingChange = false
  if desc =~ /.*\*pending\*.*/
    pendingChange = true
  end

  tuple = Struct.new(:_1, :_2)
  spinner = TTY::Spinner.new("[:spinner] Getting diffs...", format: :pulse_2)
  spinner.auto_spin()
  filenames=desc.scan(/\.\.\. (.*#[0-9]+) .*/).flatten
  downloaded_filenames = Hash.new
  filenames.each do |filename|
    escape_filename=filename.gsub(/\//,
                                  '')
    if !pendingChange
    filename=filename.gsub(/#[0-9]+/) {|match| match.gsub(/[0-9]+/) {|rev| (rev.to_i - 1).to_s}}
    end

    escape_filename=escape_filename.gsub(/(\..*)#([0-9]+)/,
                                         '__\2\1')
    `p4 print -q #{filename} > "#{@tmpdir}/#{changeListNum}/.#{escape_filename}"`
    crev_filename=filename.gsub(/#[0-9]+/,
                                "@=#{changeListNum}")
    `p4 print -q #{crev_filename} >  #{@tmpdir}/#{changeListNum}/#{escape_filename}`
    downloaded_filenames[filename] = tuple.new("#{@tmpdir}/#{changeListNum}/#{escape_filename}",
                                               "#{@tmpdir}/#{changeListNum}/.#{escape_filename}")
  end
  spinner.stop("done!")
  return downloaded_filenames
end

def p4diff(downloaded_filenames, prompt)
  return -1 unless downloaded_filenames.length != 0
  diffAll = prompt.yes?("Diff all? (#{downloaded_filenames.length} files)")
  chosen_paths = []
  if diffAll
    downloaded_filenames.each do |key, value|
        chosen_paths.push value
    end
  else
    choices = prompt.multi_select("Choose between:", filter: true) do |menu|
      if downloaded_filenames.length == 1
        menu.default 1
      end
      downloaded_filenames.each do |key, value|
        menu.choice key
      end
    end
    choices.each do |choice|
        chosen_paths.push downloaded_filenames[choice]
    end
  end
  bar = TTY::ProgressBar.new('Diffs [:bar] :percent', total:chosen_paths.length)
  chosen_paths.each do |value|
    system("gvimdiff #{value._1} #{value._2} 1>/dev/null")
    bar.advance(1)
  end
  return chosen_paths.length
end

def p4open(filenames, prompt)
  return -1 unless downloaded_filenames.length != 0
  openAll = prompt.yes?("Open all? (#{filenames.length} files)")
  chosen_paths = []
  if openAll
    filenames.each do |value|
        chosen_paths.push value
    end
  else
    choices = prompt.multi_select("Choose between:", filter: true) do |menu|
      if filenames.length == 1
        menu.default 1
      end
      filenames.each do |value|
        menu.choice value
      end
    end
    choices.each do |choice|
        chosen_paths.push choice
    end
  end
  system("gvim #{chosen_paths.join(' ')} 1>/dev/null &")
  return chosen_paths.length
end

def getChangeDesc(changenum)
    raw=`p4 describe -s #{changenum}`
    colour = raw.gsub(/ [0-9]+ /) {|match| match.cyan}
    colour = colour.gsub(/delete/) {|match| match.red}
    colour = colour.gsub(/edit/) {|match| match.green}
    colour = colour.gsub(/add/) {|match| match.blue}
    colour = colour.gsub(/integrate/) {|match| match.yellow}
    colour = colour.sub(/Affected files \.\.\./, "***")
    colour = colour.sub(/\n\n.*\n\n\*\*\*/m) {|match| match.yellow}
    colour = colour.sub(/\*\*\*/) {|match| match.green}
    ## TODO: resolve coloring
    return colour, raw
end

def addFileChangelist(changenum, root, prompt)
  raw=`cd #{root} && p4 opened`
  rawlines=raw.scan(/^.*$/)
  lines = []
  rawlines.each do |line|
    if line =~ /^((?!#{changenum}).)*$/
       lines.push line
    end
  end
  return -1 unless lines.length != 0

  choices = prompt.multi_select("Files to take:", per_page: 15) do |menu|
    if lines.length == 1
      menu.default 1
    end
    lines.each do |line|
      filename=line.scan(/(.*)#[0-9]+ -/)
      menu.choice name:line, value:filename[0]
    end
  end
  choices.each do |file|
    `cd #{root} && p4 reopen -c #{changenum} #{file[0]}`
  end
  return choices.length
end

def removeFileChangelist(changenum, root, prompt)
  raw=`cd #{root} && p4 opened`
  rawlines=raw.scan(/^.*$/)
  lines = []
  rawlines.each do |line|
    if line !~ /^((?!#{changenum}).)*$/
       lines.push line
    end
  end
  return -1 unless lines.length != 0
  choices = prompt.multi_select("Files to remove:", per_page: 15) do |menu|
    if lines.length == 1
      menu.default 1
    end
    lines.each do |line|
      filename=line.scan(/(.*)#[0-9]+ -/)
      menu.choice name:line, value:filename[0]
    end
  end
  choices.each do |file|
    `cd #{root} && p4 reopen -c default #{file[0]}`
  end
  return choices.length
end

def workspaceActions(changenum, root, prompt, desc)
    choices = [
        { key: 'e', name: 'edit files', value: :edit },
        { key: 'a', name: 'add files', value: :add},
        { key: 'r', name: 'remove files', value: :remove},
        { key: 's', name: 'shelve files', value: :shelve},
        { key: 'd', name: 'show diffs', value: :diff },
        { key: 'R', name: 'delete shelved files', value: :deleteshelved},
        { key: 'E', name: 'edit changelist', value: :editchange },
        { key: 'S', name: 'submit changelist', value: :submit },
        { key: 'D', name: 'delete changelist', value: :delete },
        { key: '!', name: 'execute', value: :shebang},
        { key: 'q', name: 'quit', value: :quit }
    ]

    action = prompt.expand('Action?', choices)
    case action
    when :edit
        raw=`cd #{root} && p4 opened -c #{changenum}`
        filenames=raw.scan(/(.*)#[0-9]+ -/)
        resolvedFilenames = []
        filenames.each do |filename|
            out = `cd #{root} && p4 where #{filename[0]} | cut -f3 -d' '`
            resolvedFilenames.push(out.gsub(/\n/, ''))
        end
        openedNum   = p4open(resolvedFilenames, prompt)
        @lastAction = "opened #{openedNum} files" unless openedNum == -1
        @lastAction = "Nothing to open" unless openedNum != -1
    when :add
      addedfileNum=addFileChangelist changenum, root, prompt
      @lastAction = "added #{addedfileNum} files" unless addedfileNum == -1
      @lastAction = "No files to add" unless addedfileNum != -1
    when :remove
      removedfileNum = removeFileChangelist changenum, root, prompt
      @lastAction    = "removed #{removedfileNum} files" unless removedfileNum == -1
      @lastAction    = "No files to remove" unless addedfileNum != -1
    when :diff
      err         = p4diff (p4getdiffs changenum, desc), prompt
      @lastAction = 'diff\'ed' unless err == -1
      @lastAction = 'Nothing to diff' unless err != -1
    when :submit
      @lastAction=`cd #{root} && p4 submit -c #{changenum}`
      return false
    when :editchange
      @lastAction=`p4 change #{changenum}`
    when :shelve
      @lastAction=`p4 shelve -c #{changenum}`
    when :deleteshelve
      @lastAction=`p4 shelve -d -c #{changenum}`
    when :delete
      @lastAction=`cd #{root} && p4 change -d #{changenum}`
    when :shebang
      cmd=prompt.ask("!")
      @lastAction=`#{cmd}`
    when :quit
      @lastAction=''
      return false
    else
    end
    return true
end

def clearScreen()
    puts "\e[H\e[2J"
end

def p4desc(changenum, prompt, root)
  while true
    catch :ctrl_c do begin
        clearScreen
        unless @lastAction.empty?
            puts @lastAction
        end
        spinner = TTY::Spinner.new("[:spinner] Getting desc...", format: :pulse_2)
        spinner.auto_spin()
        raise 'Empty string passed' if changenum.empty?
        raise 'Change # not a number' if changenum =~ /\D/
        `mkdir -p #{@tmpdir}/#{changenum}`
        coloutput, desc = getChangeDesc(changenum)
        spinner.stop("done!")
        puts "#{coloutput}"

        continue = true
        Dir.chdir(root) do # Useful with tmux splitting
            continue = workspaceActions(changenum, root, prompt, desc)
        end
        unless continue
            puts "Leave #{changenum}"
            return
        end
    rescue TTY::Reader::InputInterrupt
    rescue Exception => e
        @lastAction=e.inspect
        puts "Leave #{changenum}"
        return
    end
end
end
end
