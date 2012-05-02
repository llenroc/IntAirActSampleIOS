require 'rubygems'

desc "Initialize and update all submodules"
task :init do
  system("git submodule update --init --recursive")
  system("git submodule foreach --recursive git checkout master")
end

desc "Pull all submodules"
task :pull => :init do
  system("git submodule foreach --recursive git pull origin master")
end
