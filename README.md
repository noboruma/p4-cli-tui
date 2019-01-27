# p4vtt: Perforce/Helix Visual Terminal Tools

**p4vtt** is a small set of CLI (Command Line Interface) tools that mimics graphical **p4v**, but in terminal.

## Are p4 &amp; p4v not enough already?

**p4v** is very convenient when working with **perforce**. Sometimes GUI &amp; mouse are not an option! **p4** alone is very useful, but it does not provide facilities for diff'ing nor opening changelists' files quickly. This is why **p4vtt** was developed. Under the hood, **p4vtt** is using **p4**, but presents results and asks for input in a convenient way.

The tools/scripts are written in ruby, they mostly fit my workflow but if you want/need to extend them, please feel free to reach me out.

## How does it work?

The workflow shown below is:
- Get a list of pending changes
- Create a new pending change (because it uses vim, the recoding outputs garbage when writing the change's description)
- Access the newly created pending change
- List the possible actions for the selected change

![img](https://github.com/noboruma/p4-cli-tui/blob/master/wiki/screenshots/ttyrecord.gif)

Here are all the possible actions for a selected changelist:
![img](https://github.com/noboruma/p4-cli-tui/blob/master/wiki/screenshots/Screenshot_20190124_105032.png)

## Installation &amp; external tools

The scripts work great with tmux &amp; vim.

You will need all the gems listed in the Gemfile. (work in progress to make that process automatic)
