name             'wordpress'
maintainer       'trajar'
maintainer_email 'https://github.com/trajar'
license          'Apache 2.0'
description      'Installs/Configures wordpress'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.2.0'
recipe           'wordpress', 'Installs and configures wordpress site(s) on a single system.'

depends 'openssl'
depends 'mysql'

recommends 'php'
recommends 'php-fpm'

recommends 'apache2'
recommends 'nginx'
