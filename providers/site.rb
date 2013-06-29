
action :create do

  dir = nil
  site_name = nil
  if @new_resource.dir
    dir = @new_resource.dir
  end
  if @new_resource.site_name
    site_name = @new_resource.site_name
  end
  if site_name.nil? && dir.nil?
    raise 'Must specify either wordpress installation directory or site name.'
  end
  if site_name.nil? && dir
    site_name = File.basename(dir)
  if dir.nil? && site_name
    dir = "/var/www/#{site_name}"
  end

  server_aliases = @new_resource.server_aliases || ['wordpress']['server_aliases']
  db_name = @new_resource.db_name || site_name
  db_user = @new_resource.db_user || ['wordpress']['db']['user']
  db_password = @new_resource.db_password || ['wordpress']['db']['password']
  db_character_set = @new_resource.db_character_set || ['wordpress']['db']['character_set']

  if node.has_key?('ec2')
    server_fqdn = node['ec2']['public_hostname']
  else
    server_fqdn = node['fqdn']
  end

  db_password = secure_password if db_password.nil?
  keys_auth = secure_password
  keys_secure_auth = secure_password
  keys_logged_in = secure_password
  keys_nonce = secure_password

  tarball = "#{Chef::Config[:file_cache_path]}/wordpress-download.tar.gz"

  remote_file tarball do
    checksum node['wordpress']['checksum']
    source node['wordpress']['url']
    mode '0644'
  end

  directory dir do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
    recursive true
  end

  execute "#{dir}-untar" do
    cwd dir
    command "tar --strip-components 1 -xzf #{tarball}"
    creates "#{dir}/wp-settings.php"
  end

  execute "#{db_name}-privileges" do
    command "/usr/bin/mysql -u root -p\"#{node['mysql']['server_root_password']}\" < #{node['mysql']['conf_dir']}/wp-grants.sql"
    action :nothing
  end

  template "#{node['mysql']['conf_dir']}/#{db_name}-wp-grants.sql" do
    source 'grants.sql.erb'
    owner 'root'
    group 'root'
    mode '0600'
    variables(
        :user     => db_user,
        :password => db_password,
        :database => db_name
    )
    notifies :run, "#{db_name}-privileges", :immediately
  end

  execute "#{db_name}-create" do
    command "/usr/bin/mysqladmin -u root -p\"#{node['mysql']['server_root_password']}\" create #{db_name} --default-character-set=#{db_character_set}"
    not_if do
      require 'mysql'
      m = Mysql.new('localhost', 'root', node['mysql']['server_root_password'])
      m.list_dbs.include?(db_name)
    end
    notifies :create, 'ruby_block[save node data]', :immediately unless Chef::Config[:solo]
  end

  unless Chef::Config[:solo]
    ruby_block 'save node data' do
      block do
        node.save
      end
      action :create
    end
  end

  template "#{dir}/wp-config.php" do
    source "wp-config.php.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
        :database        => db_name,
        :user            => db_user,
        :password        => db_password,
        :character_set   => db_character_set,
        :auth_key        => keys_auth,
        :secure_auth_key => keys_secure_auth,
        :logged_in_key   => keys_logged_in,
        :nonce_key       => keys_nonce
    )
  end

  if 'apache2'.eql?(node['wordpress']['webserver']) || :apache2.eql?(node['wordpress']['webserver'])

    apache_site '000-default' do
      enable false
    end

    web_app site_name do
      template 'wordpress-apache2.conf.erb'
      docroot dir
      server_name server_fqdn
      server_aliases server_aliases
    end

  elsif 'nginx'.eql?(node['wordpress']['webserver']) || :nginx.eql?(node['wordpress']['webserver'])

    template "#{node['nginx']['dir']}/wordpress.conf" do
      source 'wordpress-nginx-common.conf.erb'
      owner 'root'
      group 'root'
      mode 00644
      notifies :reload, 'service[nginx]'
      variables({
        :php_fpm_socket => node['php-fpm']['pool']['www']['listen']
      })
    end

    template "#{node['nginx']['dir']}/sites-available/#{site_name}" do
      source 'wordpress-nginx.conf.erb'
      owner 'root'
      group 'root'
      mode 00644
      notifies :reload, 'service[nginx]'
      variables({
        :docroot => db_name,
        :server_aliases => server_aliases,
        :log_dir => node['nginx']['log_dir'],
        :log_name => "wordpress-#{site_name}"
      })
    end

    nginx_site 'default' do
      enable false
    end

    nginx_site 'wordpress' do
      enable true
    end

  end

end