#!/usr/bin/ruby
require 'tty-prompt'
prompt = TTY::Prompt.new

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

        output=`p4 describe #{changeListNum}`
        puts "#{output}"

        filenames=output.scan(/\.\.\. (.*#[0-9]+) .*/).flatten
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
