
Gem::Specification.new do |spec|
  spec.name          = "embulk-input-prometheus"
  spec.version       = "0.3.0"
  spec.authors       = ["pyama86"]
  spec.summary       = "Prometheus input plugin for Embulk"
  spec.description   = "Loads records from Prometheus."
  spec.email         = ["pyama@pepabo.com"]
  spec.licenses      = ["MIT"]
  spec.homepage      = "https://github.com/pyama86/embulk-input-prometheus"
  spec.files         = `git ls-files`.split("\n") + Dir["classpath/*.jar"]
  spec.test_files    = spec.files.grep(%r{^(test|spec)/})
  spec.require_paths = ["lib"]
  spec.add_dependency 'prometheus-api-client'
  spec.add_dependency 'faraday',  ['~> 0.9']
  spec.add_development_dependency 'embulk', ['>= 0.8.39']
  spec.add_development_dependency 'bundler', ['>= 1.10.6']
  spec.add_development_dependency 'rake', ['>= 10.0']
end
