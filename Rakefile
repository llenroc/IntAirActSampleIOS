require 'rubygems'

desc "Initialize and update all submodules"
task :init do
  system("git submodule update --init --recursive")
end

desc "Pull all submodules"
task :pull => :init do
  system("git submodule foreach --recursive git pull origin master")
end
