role :app, "75.101.132.186"
role :web, "75.101.132.186"
role :db, "75.101.132.186", :primary => true
set :user,          "cyrille"
set :runner,        "cyrille"
set :password,  "mavslr55"
set :deploy_to, "/var/rails/be_amazing"
set :rails_env, :production
set :db_user, "postgres"
set :db_name, "be_amazing_production"
set :db_password, "test0user"