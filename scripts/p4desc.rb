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
      chosen_paths.append value
    end
  else
    choices = prompt.multi_select("Choose between:") do |menu|
      downloaded_filenames.each do |key, value|
        menu.choice key
      end
    end
    choices.each do |choice|
      chosen_paths.append downloaded_filenames[choice]
    end
  end

  bar = TTY::ProgressBar.new('Diffs [:bar] :percent', total:chosen_paths.length)
  chosen_paths.each do |value|
    system("vimdiff #{value._1} #{value._2}")
    bar.advance(1)
  end
end

def getChangeDesc(changenum)
    RAW=`p4 describe #{changeListNum}`
    HEADER=`echo "#{RAW}" | head -n 1`
    BODY=`echo "#{RAW}" | tail -n +2`
    BODY=`echo "#{BODY}"  | sed 's/\(#[0-9]\+\)/ \1/g' | sed 's/move\//move|/g' | GREP_COLOR='01;36' grep --color=always 'move\|$' | GREP_COLOR='01;32' grep --color=always 'add\|$' | GREP_COLOR='01;32' grep --color=always 'edit\|$' | GREP_COLOR='01;31' grep --color=always '^.*delete.*$\|$' | GREP_COLOR='01;31' grep --color=always 'delete.*\|$' | column -ts\#`
    HEADER=`echo #{HEADER} | GREP_COLOR='01;33' grep --color=always "[a-zA-Z]*@" | GREP_COLOR='01;32' grep --color=always " [0-9]* " | GREP_COLOR='01;34' grep --color=always "\*.*\*"`
    OUTPUT="#{HEADER}\n#{BODY}"
    # TODO: resolve coloring
    return OUTPUT
end

def p4desc(changenum, prompt, reader)

  #catch :ctrl_c do begin
  while true

    puts changenum
    changeListNum = changenum
    raise 'Empty string passed' if changeListNum.empty?
    raise 'Change # not a number' if changeListNum =~ /\D/

      spinner = TTY::Spinner.new("[:spinner] Getting desc...", format: :pulse_2)
    spinner.auto_spin()
    `mkdir -p #{@tmpdir}/#{changeListNum}`
    output = getChangeList(changeListNum)
    puts "#{output}"

    spinner.stop("done!")

    choices = [
      { key: 'd', name: 'show diffs', value: :diff },
      { key: 'S', name: 'submit changelist', value: :submit },
      { key: 'e', name: 'edit changelist', value: :edit },
      { key: 'q', name: 'quit; do not overwrite this file ', value: :quit }
    ]

    action = prompt.expand('Action?', choices)
    case action
    when :submit
      `p4 submit #{changeListNum}`
    when :edit
      `p4 edit #{changeListNum}`
    when :diff
      p4diff (p4getdiffs changeListNum, output), prompt
    when :quit
      puts "Leave #{changeListNum}"
      break
    else
      puts "Leave #{changeListNum}"
      break
    end
  end
#rescue Exception
#  puts "Leave #{changeListNum}"
#end
#end
end
