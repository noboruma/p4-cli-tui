Gem::Specification.new do |s|
  s.name = %q{p4vtt}
  s.version = "0.0.1"
  s.date = %q{2019-01-30}
  s.summary = %q{p4vtt: Perforce/Helix Visual Terminal Tools}
  s.authors = "Thomas Legris"
  s.homepage = "https://github.com/noboruma/p4vtt"
  s.licenses = "MIT"
  s.files = [
    "Gemfile",
    "LICENSE",
    "README.md",
    "lib/p4vtt.rb",
    "lib/p4vsub.rb",
    "lib/p4vpen.rb",
    "lib/p4desc.rb"
  ]
  s.require_paths = ["lib"]
  s.executables << 'p4vtt'

  s.add_runtime_dependency 'tty-prompt', '~>0'
  s.add_runtime_dependency 'tty-spinner', '~>0'
  s.add_runtime_dependency 'tty-progressbar', '~>0'
  s.add_runtime_dependency 'colorize', '~>0'
end
