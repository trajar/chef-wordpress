maintainer       'trajar'
maintainer_email 'https://github.com/trajar'
license          'Apache 2.0'
description      'Installs/Configures wordpress'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

recipe 'wordpress', 'Installs and configures wordpress site(s) on a single system.'

%w{ php php-fpm openssl }.each do |cb|
  depends cb
end

depends 'mysql', '>= 1.0.5'

recommends 'apache2', '>= 0.99.4'
recommends 'nginx', '>= 1.7.0'
