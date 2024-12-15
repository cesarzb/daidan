# frozen_string_literal: true

require_relative 'lib/daidan/version'

Gem::Specification.new do |spec|
  spec.name = 'daidan'
  spec.version = Daidan::VERSION
  spec.authors = ['Bernard Cesarz']
  spec.email = ['cesarzb@protonmail.com']

  spec.summary = 'Lightweight GraphQL web framework.'
  spec.homepage = 'https://github.com/cesarzb/daidan'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'bcrypt', '~> 3.1'
  spec.add_dependency 'dotenv', '~> 3.1'
  spec.add_dependency 'graphql', '~> 2.4'
  spec.add_dependency 'jwt', '~> 2.9'
  spec.add_dependency 'sequel', '~> 5.0'
end
