Pod::Spec.new do |s|
  s.name = 'LimeConfig'
  s.version = '0.9.99'
  # Metadata
  s.license = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.summary = 'Shared configuration for swift libraries'
  s.homepage = 'https://github.com/lime-company/swift-lime-config'
  s.social_media_url = 'https://twitter.com/lime_company'
  s.author = { 'Lime - HighTech Solution s.r.o.' => 'support@lime-company.eu' }
  s.source = { :git => 'https://github.com/lime-company/swift-lime-config.git', :tag => s.version }
  # Deployment targets
  s.swift_version = '4.0'
  s.ios.deployment_target = '8.0'
  s.watchos.deployment_target = '2.0'
  # Sources
  s.source_files = 'Source/*.swift'
  
  # LimeCore >= 0.9.4 also contains LimeCore/Config, so this deprecated pod must target older version
  s.dependency 'LimeCore', '< 0.9.4'
  
  s.deprecated = true
  s.deprecated_in_favor_of = 'LimeCore/Config'
end
