$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "rake/testtask"

desc "Run a script"
task :run, [:path] do |t, args|
  if args[:path]
    require "compiler"
    input = File.read(args[:path])
    $stdout.puts Kaleidoscope.compile_run(input)
  else
    $stderr.puts "No script path specified"
  end
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => :test
