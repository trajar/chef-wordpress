
actions :create, :delete

attribute :dir,                 :kind_of => String, :default => nil
attribute :site_name,           :kind_of => String, :default => nil
attribute :server_aliases,      :kind_of => Array, :default => []
attribute :db_name,             :kind_of => String, :default => nil
attribute :db_user,             :kind_of => String
attribute :db_password,         :kind_of => String
attribute :db_character_set,    :kind_of => String
