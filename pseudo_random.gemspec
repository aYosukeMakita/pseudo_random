# frozen_string_literal: true

require_relative 'lib/pseudo_random/version'

Gem::Specification.new do |spec|
  spec.name = 'pseudo_random'
  spec.version = PseudoRandom::VERSION
  spec.authors = ['aYosukeMakita']
  spec.email = ['yosuke.makita@access-company.com']

  spec.summary = 'Deterministic pseudo-random generator for numbers and strings.'
  spec.description = 'Generates reproducible (deterministic) pseudo-random numbers and strings (hex/alphabetic/alphanumeric) from arbitrary Ruby object seeds. Not cryptographically secure.'
  spec.homepage = 'https://github.com/aYosukeMakita/pseudo_random'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0', '< 4.0'

  # spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['issue_tracker_uri'] = "#{spec.homepage}/issues"
  spec.metadata['documentation_uri'] = "https://www.rubydoc.info/gems/#{spec.name}"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  # No CLI executables are packaged at the moment; remove bindir/executables.
  # Add an `exe/` directory and set spec.bindir/spec.executables if a CLI is introduced.
  spec.require_paths = ['lib']

  # Add runtime dependencies with: spec.add_dependency 'gem_name', '~> x.y'
end
