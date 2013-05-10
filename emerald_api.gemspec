Gem::Specification.new do |s|
  s.name        = 'emerald_api'
  s.version     = '3.7.4'
  s.date        = '2013-04-29'
  s.summary     = "Emerald API"
  s.description = "Interfaces with Emerald"
  s.authors     = ["Victor Lin","Jeremy J. Barth","Chris Williams"]
  s.email       = ['victor@wellnessfx.com','jeremy@wellnessfx.com','chris@wellnessfx.com']
  s.files       = ["lib/emerald_api.rb"]
  s.homepage    =
    'http://rubygems.org/gems/emerald_api'

  s.add_runtime_dependency "faraday"
  s.add_runtime_dependency "faraday_middleware"
  s.add_runtime_dependency "hashie"
  s.add_runtime_dependency 'factory_girl'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'activesupport'
end
