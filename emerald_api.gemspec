Gem::Specification.new do |s|
  s.name        = 'emerald_api'
  s.version     = '3.5.1'
  s.date        = '2012-05-01'
  s.summary     = "Emerald API"
  s.description = "Interfaces with Emerald"
  s.authors     = ["Victor Lin"]
  s.email       = 'victor@wellnessfx.com'
  s.files       = ["lib/emerald_api.rb"]
  s.homepage    =
    'http://rubygems.org/gems/emerald_api'

  s.add_runtime_dependency "faraday"
  s.add_runtime_dependency "faraday_middleware"
  s.add_runtime_dependency "hashie"

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'activesupport'
end
