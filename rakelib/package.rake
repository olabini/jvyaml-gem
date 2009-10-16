MANIFEST = FileList["Manifest.txt", "Rakefile", "lib/**/*.rb", "lib/jvyamlb.jar", "lib/jvyaml_internal.jar", "test/**/*.rb", "lib/**/*.rake", "src/**/*.java", "rakelib/*.rake"]

file "Manifest.txt" => :manifest
task :manifest do
  File.open("Manifest.txt", "w") {|f| MANIFEST.each {|n| f << "#{n}\n"} }
end
Rake::Task['manifest'].invoke # Always regen manifest, so Hoe has up-to-date list of files

begin
  require 'hoe'
  hoe = Hoe.spec("jvyaml") do |p|
    p.version = "0.0.1"
    p.url = "http://github.com/olabini/jvyaml-gem"
    p.author = "Ola Bini"
    p.email = "ola.bini@gmail.com"
    p.summary = "Alternative YAML engine for JRuby"
  end
  hoe.spec.files = MANIFEST
  hoe.spec.dependencies.delete_if { |dep| dep.name == "hoe" }
rescue LoadError => le
  puts le.to_s, *le.backtrace
  puts "Problem loading Hoe; please check the error above to ensure that Hoe is installed correctly"
end

def rake(*args)
  ruby "-S", "rake", *args
end
