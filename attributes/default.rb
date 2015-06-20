
default['wordpress']['url'] = 'http://wordpress.org/latest.tar.gz'
default['wordpress']['db']['user'] = nil
default['wordpress']['db']['password'] = nil
default['wordpress']['db']['character_set'] = 'utf8'
default['wordpress']['server_aliases'] = [node['fqdn']]
default['wordpress']['webserver'] = 'apache2'
default['wordpress']['php_fpm']['listen'] = '/var/run/php5-fpm.sock'

default['mysql']['conf_dir'] = '/etc/mysql'
default['mysql']['server_root_password'] = nil
