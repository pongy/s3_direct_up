# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 's3_direct_up/version'

Gem::Specification.new do |gem|
  gem.name          = "s3_direct_up"
  gem.version       = S3DirectUp::VERSION
  gem.authors       = ["William Yeung"]
  gem.email         = ["william@tofugear.com"]
  gem.description   = %q{Amazon S3 direct uploader}
  gem.summary       = %q{An independent S3 direct uploader base on CarrierWave and fog.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "carrierwave"
  gem.add_dependency "fog"
end
