lib_files = Dir.glob('{lib,bin}/**/{.irbrc,*.{rb,feature,yml}}')

Gem::Specification.new do |s|
  s.name        = 'ruby-graph-walker'
  s.version     = '0.0.1'
  s.date        = '2017-10-09'
  s.summary     = "Ruby Graph Walker"
  s.description = ""
  s.authors     = ["astro"]
  s.email       = 'astro2linus@gmail.com'
  s.files       = lib_files
  s.homepage    = ''
  s.license       = 'MIT'
end