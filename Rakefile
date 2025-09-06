# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'minitest/test_task'

Minitest::TestTask.create

require 'rubocop/rake_task'

RuboCop::RakeTask.new

# C++ extension build task
begin
  require 'rake/extensiontask'

  Rake::ExtensionTask.new('pseudo_random_native') do |ext|
    ext.lib_dir = 'lib'
    ext.source_pattern = '*.{c,cpp}'
  end

  task test: :compile
  task default: %i[compile test rubocop]
rescue LoadError
  # Use normal tasks only when rake-compiler-dock is not available
  task default: %i[test rubocop]

  # Manual build task
  task :compile do
    Dir.chdir('ext/pseudo_random_native') do
      sh 'ruby extconf.rb'
      sh 'make'
    end
  end

  task :clean do
    Dir.chdir('ext/pseudo_random_native') do
      sh 'make clean' if File.exist?('Makefile')
      FileUtils.rm_f(['Makefile', 'mkmf.log'])
    end
  end
end
