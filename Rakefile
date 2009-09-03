require 'rake'

require 'spec/rake/spectask'

desc "Run all examples"
Spec::Rake::SpecTask.new('default') do |t|
  t.spec_files = FileList['examples/fast']
end

Spec::Rake::SpecTask.new('slow') do |t|
  t.spec_files = FileList['examples/slow']
end