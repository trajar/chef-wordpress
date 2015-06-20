maintainer       'trajar'
maintainer_email 'https://github.com/trajar'
license          'Apache 2.0'
description      'Installs/Configures wordpress'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

recipe 'wordpress', 'Installs and configures wordpress site(s) on a single system.'

depends 'openssl'
depends 'mysql', '>= 1.0.5'

recomments 'php'
recomments 'php-fpm'

recommends 'apache2'
recommends 'nginx'
