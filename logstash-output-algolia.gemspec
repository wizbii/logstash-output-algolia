Gem::Specification.new do |s|
  s.name          = 'logstash-output-algolia'
  s.version       = '0.1.0'
  s.licenses      = ['Apache-2.0']
  s.summary       = 'Output events in Algolia indices'
  s.description   = 'Output events in Algolia indices'
  s.homepage      = 'https://github.com/wizbii/logstash-output-algolia'
  s.authors       = ['Florent Baldino', 'Frédéric Palluel Lafleur']
  s.email         = 'florent.baldino@wizbii.com'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "output" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core-plugin-api", "~> 2.0"
  s.add_runtime_dependency "logstash-codec-plain"
  s.add_runtime_dependency "algoliasearch"
  s.add_development_dependency "logstash-devutils"
  s.add_development_dependency "webmock"
end
