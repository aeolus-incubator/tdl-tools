# -*- encoding: utf-8 -*-

GEM_NAME    = 'tdl'
PKG_VERSION = '0.0.1'

PKG_FILES =
  Dir.glob('{lib,specs}/**/*.rb') + ['LICENSE', 'Rakefile', 'README.md']

Gem::Specification.new do |s|
    s.name    = GEM_NAME
    s.version = PKG_VERSION
    s.files   = PKG_FILES
    s.executables   = Dir.glob('bin/*.rb').collect { |e| e.gsub(/bin\//, '') }
    s.require_paths = ['lib']

    s.required_ruby_version = '>= 1.8.1'
    s.required_rubygems_version = Gem::Requirement.new(">= 1.3.3")
    s.add_development_dependency('rspec', '~> 2.11.0')
    #s.add_dependency('', '')

    s.requirements = ['deltacloud is required to launch etdls against cloud instances',
                      'imagefactory is required to build images from tdls']

    s.author = "Mo Morsi"
    s.email = "mmorsi@redhat.com"
    s.date = %q{2013-02-26}
    s.description = %q{Aeolus Template Description Language Tools}
    s.summary = %q{Aeolus tdl-tools}
    s.homepage = %q{http://aeolusproject.org/}
end
