# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'daidan'
  spec.version = '0.2.0'
  spec.authors = ['Bernard Cesarz']
  spec.email = ['cesarzb@protonmail.com']

  spec.summary = 'Lightweight GraphQL web framework.'
  spec.description = 'A lightweight Ruby framework for building GraphQL-based web applications.'
  spec.homepage = 'https://github.com/cesarzb/daidan'
  spec.licenses = ['MIT']

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = 'https://github.com/cesarzb/daidan/blob/main/CHANGELOG.md'
  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['license_uri'] = 'https://opensource.org/licenses/MIT'

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |file|
      file.start_with?('test/', 'spec/', 'features/', '.git/') || file.end_with?('.gem')
    end
  end

  spec.bindir = 'bin'
  spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'bcrypt', '~> 3.1'
  spec.add_dependency 'dotenv', '~> 3.1'
  spec.add_dependency 'graphql', '~> 2.4'
  spec.add_dependency 'jwt', '~> 2.9'
  spec.add_dependency 'sequel', '~> 5.0'

  spec.add_development_dependency 'rake', '~> 13.0'
end
