require 'rake/testtask'
require 'rake/clean'
CLEAN.include 'lib/jvyaml_internal.jar'

task :default => [:java_compile, :test]

task :filelist do
  puts FileList['pkg/**/*'].inspect
end
