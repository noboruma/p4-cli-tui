require 'tty-progressbar'

def p4getdiffs(changeListNum, desc)
  tuple = Struct.new(:_1, :_2)
  spinner = TTY::Spinner.new("[:spinner] Getting diffs...", format: :pulse_2)
  spinner.auto_spin()
  filenames=desc.scan(/\.\.\. (.*#[0-9]+) .*/).flatten
                               downloaded_filenames = Hash.new
  filenames.each do |filename|
    escape_filename=filename.gsub(/\//,
                                  '')
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
  diffAll = prompt.yes?("Diff all? (#{downloaded_filenames.length} files)")
  chosen_paths = []
  if diffAll
    downloaded_filenames.each do |key, value|
        chosen_paths.push value
    end
  else
    choices = prompt.multi_select("Choose between:") do |menu|
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
    system("vimdiff #{value._1} #{value._2}")
    bar.advance(1)
  end
end

def getChangeDesc(changenum)
    raw=`p4 describe #{changenum}`
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

def p4desc(changenum, prompt, reader)
  #catch :ctrl_c do begin
  while true
    spinner = TTY::Spinner.new("[:spinner] Getting desc...", format: :pulse_2)
    spinner.auto_spin()
    raise 'Empty string passed' if changenum.empty?
    raise 'Change # not a number' if changenum =~ /\D/
    `mkdir -p #{@tmpdir}/#{changenum}`
    coloutput, output = getChangeDesc(changenum)
    spinner.stop("done!")
    puts "#{coloutput}"

    choices = [
      { key: 'd', name: 'show diffs', value: :diff },
      { key: 'S', name: 'submit changelist', value: :submit },
      { key: 'e', name: 'edit changelist', value: :edit },
      { key: 'q', name: 'quit', value: :quit }
    ]

    action = prompt.expand('Action?', choices)
    case action
    when :submit
      `p4 submit #{changenum}`
    when :edit
      `p4 edit #{changenum}`
    when :diff
      p4diff (p4getdiffs changenum, output), prompt
    when :quit
      puts "Leave #{changenum}"
      break
    else
      puts "Leave #{changenum}"
      break
    end
  end
#rescue Exception
#  puts "Leave #{changeListNum}"
#end
#end
end
