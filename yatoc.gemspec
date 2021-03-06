Gem::Specification.new do |s|
  s.name = 'yatoc'
  s.version = '0.3.5'
  s.summary = 'Yet Another Table Of Contents HTML generator.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/yatoc.rb']
  s.add_runtime_dependency('pxindex', '~> 0.2', '>=0.2.2')  
  s.add_runtime_dependency('line-tree', '~> 0.7', '>=0.7.2')
  #s.add_runtime_dependency('kramdown', '~> 2.1', '>=2.1.0')   
  s.signing_key = '../privatekeys/yatoc.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/yatoc'
end
