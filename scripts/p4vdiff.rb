require 'tty-prompt'
prompt = TTY::Prompt.new
require 'tty-spinner'
spinner = TTY::Spinner.new
require 'tty-progressbar'

trap("SIGINT") { throw :ctrl_c }

tuple = Struct.new(:_1, :_2)
@tmpdir = "/tmp/p4v"
`mkdir -p #{@tmpdir}/#{changeListNum}`

catch :ctrl_c do
    begin
        print "Diff changelist#: "
        changeListNum = gets.chomp;
        raise 'Empty string passed' if changeListNum.empty?
        raise 'Change # not a number' if changeListNum =~ /\D/

        spinner.auto_spin
        output=`p4 describe #{changeListNum}`
        puts "#{output}"
        spinner.stop("Done")

        filenames=output.scan(/\.\.\. (.*#[0-9]+) .*/).flatten
        downloaded_filenames = Hash.new
        spinner.auto_spin
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
        spinner.stop("Done")

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
            system("vimdiff value._1 value._2")
            bar.advance(1)
        end

    rescue Exception
        puts "Stop"
    end
end
