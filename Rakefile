require 'rubygems'
require 'xcoder'
require 'github_api'

if File.exist?('Rakefile.config')
  load 'Rakefile.config'
end

$name="IntAirActImageIOS"

$github_user='ase-lab'
$github_repo='IntAirActSampleIOS'

$configuration="Release"

project=Xcode.project($name)
$ios=project.target($name).config($configuration).builder
$ios.sdk = :iphoneos

desc "Clean, Build, Test and Archive for iOS"
task :default => [:ios]

desc "Cleans for iOS"
task :clean => [:removebuild, "ios:clean"]

desc "Builds for iOS"
task :build => ["ios:build"]

desc "Test for iOS"
task :test => ["ios:test"]

desc "Archives for iOS"
task :archive => [ "ios:archive"]

desc "Remove build folder"
task :removebuild do
  rm_rf "build"
end

desc "Clean, Build, Test and Archive for iOS"
task :ios => ["ios:clean", "ios:build", "ios:test", "ios:archive"]

namespace :ios do

  desc "Clean for iOS"
  task :clean => [:init, :removebuild] do
    $ios.clean
  end

  desc "Build for iOS"
  task :build => :init do
    $ios.build
  end
  
  desc "Test for iOS"
  task :test => :init do
    puts("Tests for iOS are not implemented - hopefully (!) - yet.")
  end

  desc "Archive for iOS"
  task :archive => ["ios:clean", "ios:build", "ios:test"] do
    cd "build/" + $configuration + "-iphoneos" do
      sh "tar cvzf ../" + $name + ".tar.gz " + $name + ".app"
    end
  end

end

desc "Initialize and update all submodules recursively"
task :init do
  system("git submodule update --init --recursive")
  system("git submodule foreach --recursive git checkout master")
end

desc "Pull all submodules recursively"
task :pull => :init do
  system("git submodule foreach --recursive git pull")
end

def publish(version)
  github = Github.new :user => $github_user, :repo => $github_repo, :login => $github_login, :password => $github_password
  file = 'build/' + $name + ".tar.gz"
  name = $name + '-' + version + '.tar.gz'
  size = File.size(file)
  description = "Version " + version
  res = github.repos.downloads.create $github_user, $github_repo,
    "name" => name,
    "size" => size,
    "description" => description,
    "content_type" => "application/x-gzip"
  github.repos.downloads.upload res, file
end

desc "Publish a new version of the framework to github"
task :publish, :version do |t, args|
  if !args[:version]
    puts("Usage: rake publish[version]");
    exit(1)
  end
  if !defined? $github_login
    puts("$github_login is not set");
    exit(1)
  end
  if !defined? $github_password
    puts("$github_password is not set");
    exit(1)
  end
  version = args[:version]
  #check that version is newer than current_version
  current_version = open("Version").gets.strip
  if Gem::Version.new(version) < Gem::Version.new(current_version)
    puts("New version (" + version + ") is smaller than current version ("+current_version+")")
    exit(1)
  end
  #write version into versionfile
  File.open("Version", 'w') {|f| f.write(version) }
  Rake::Task["archive"].invoke
  system("git add Version")
  system('git commit -m "Bump version to ' + version + '"')
  system('git tag -a v' + version + ' -m "Framework version ' + version + '."')
  system('git push')
  system('git push --tags')
  publish(version)
end
