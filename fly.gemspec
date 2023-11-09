# frozen_string_literal: true

require_relative 'lib/fly/version'

Gem::Specification.new do |spec|
  spec.name = 'Fly'
  spec.version = Fly::VERSION
  spec.authors = ['Tanna McClure', 'Kayla Reopelle', 'James Bunch', 'Hannah Ramadan']
  spec.email = 'support@newrelic.com'
  spec.licenses = %w[Apache-2.0]
  spec.summary = 'Fly - a cool, minimalistic, on-the-wall observability agent'
  spec.homepage = 'https://github.com/fallwith/fly'
  spec.required_ruby_version = '>= 2.7.5'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/CHANGELOG.md"
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test)/|\.|Gemfile|Rakefile)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
