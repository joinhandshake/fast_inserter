# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fast_inserter/version'

Gem::Specification.new do |spec|
  spec.name          = "fast_inserter"
  spec.version       = FastInserter::VERSION
  spec.authors       = ["Scott Ringwelski", "Brandon Gafford", "Jordon Dornbos"]
  spec.email         = ["scott@joinhandshake.com", "brandon@joinhandshake.com", "jordon@joinhandshake.com"]

  spec.summary       = %q{Quickly insert database records in bulk}
  spec.description   = %q{Use raw SQL to insert database records in bulk. Supports uniqueness constraints, timestamps, and checking for existing records.}
  spec.homepage      = "https://github.com/strydercorp/fast_inserter"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'activerecord', '>= 4.1.0'

  spec.required_ruby_version = ">= 2.2.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "database_cleaner"

  case ENV['DB']
  when "mysql"; spec.add_development_dependency "mysql2"
  when "sqlite"; spec.add_development_dependency "sqlite3"
  when "pg"; spec.add_development_dependency "pg"
  else spec.add_development_dependency "sqlite3" # Default
  end
end
