require 'rubygems'
require 'xcoder'

# The name of the project (also used for the Xcode project and loading the schemes)
$name='IntAirActImageIOS'

# The configuration to build: 'Debug' or 'Release'
$configuration='Release'

desc 'Clean, Build, Test and Archive for iOS'
task :default => [:ios]

desc 'Cleans for iOS'
task :clean => [:remove_build_dir, 'ios:clean']

desc 'Builds for iOS'
task :build => ['ios:build']

desc 'Test for iOS'
task :test => ['ios:test']

desc 'Archives for iOS'
task :archive => ['ios:archive']

desc 'Remove build folder'
task :remove_build_dir do
  rm_rf 'Build'
end

$project
$ios

task :load_project do
  $project = Xcode.project($name)
  $ios = $project.target($name).config($configuration).builder
end

desc 'Clean, Build, Test and Archive for iOS'
task :ios => ['ios:clean', 'ios:build', 'ios:test', 'ios:archive']

namespace :ios do

  desc 'Clean for iOS'
  task :clean => [:init, :remove_build_dir, :load_project] do
    $ios.clean
  end
  
  desc 'Build for iOS'
  task :build => [:init, :load_project] do
    $ios.build
  end
  
  desc 'Test for iOS'
  task :test => [:init] do
    puts('Tests for iOS are not implemented - hopefully (!) - yet.')
  end

  desc 'Archive for iOS'
  task :archive => [:load_project, 'ios:clean', 'ios:build', 'ios:test'] do
    $ios.package
    cd 'build/' + $configuration + '-iphoneos' do
      system('tar cvzf "../' + $name + '.tar.gz" *.ipa')
    end
  end

end

desc 'Initialize and update all submodules recursively'
task :init do
  system('git submodule update --init --recursive')
  system('git submodule foreach --recursive "git checkout master"')
end

desc 'Pull all submodules recursively'
task :pull => :init do
  system('git submodule foreach --recursive git pull')
end

desc 'Increment version'
task :publish, :version do |t, args|
  if !args[:version]
    puts('Usage: rake publish[version]');
    exit(1)
  end
  version = args[:version]
  # check that version is newer than current_version
  current_version = open('Version').gets.strip
  if Gem::Version.new(version) < Gem::Version.new(current_version)
    puts('New version (' + version + ') is smaller than current version (' + current_version + ')')
    exit(1)
  end
  # write version into versionfile
  File.open('Version', 'w') {|f| f.write(version) }

  Rake::Task['archive'].invoke
  
  # build was successful, increment version and push changes
  system('git add Version')
  system('git commit -m "Bump version to ' + version + '"')
  system('git push')
end
