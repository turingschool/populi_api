require_relative 'lib/populi_api/version'

Gem::Specification.new do |spec|
  spec.name          = "populi_api"
  spec.version       = PopuliAPI::VERSION
  spec.authors       = ["Tanner Welsh"]
  spec.email         = ["tanner@turing.edu"]

  spec.summary       = %q{API wrapper for the Populi API}
  # spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "https://github.com/turingschool/populi_api/"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "faraday", "<= 2.0", ">= 1.0"
  spec.add_runtime_dependency "faraday_middleware", "~> 1.0"
  spec.add_runtime_dependency "multi_xml", "~> 0.6"
  spec.add_runtime_dependency "activesupport", "< 8.0", ">= 5.2"
end
