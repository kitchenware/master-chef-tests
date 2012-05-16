set :application, "conf4"

set :scm, :none
set :deploy_via, :copy
set :repository, File.join(File.dirname(__FILE__), "..")
set :deploy_to, "/toto"
set :user, "user1"

use_http_proxy = ENV["PROXY"] ? "export http_proxy=http://#{ENV["PROXY"]} && " : ""

server ENV["TARGET"], :app, :db

ssh_options[:keys] = [File.join(File.dirname(__FILE__), "..", "..", "ssh", "id_rsa")]

namespace :deploy do

  task :bundler, :roles => :app do
    run "#{use_http_proxy} cd #{release_path} && . $HOME/.warp/common/ruby/include && rbenv warp install-ruby && gem list | grep bundle || gem install bundler"
  end

  task :bundle, :roles => :app do
    run "#{use_http_proxy} cd #{release_path} && . $HOME/.warp/common/ruby/include && bundle --without development"
  end

  task :symlinks, :roles => :app do
    run "cd #{release_path} && rm -rf log config/database.yml && ln -s #{shared_path}/database.yml config/database.yml && ln -s #{shared_path}/log ."
  end

  task :init_rails, :roles => :app do
    run "cd #{release_path} && . $HOME/.warp/common/ruby/include && RAILS_ENV=production rake db:migrate assets:precompile"
  end

  task :restart, :roles => :app do
    run "/etc/init.d/app_test restart"
  end

end

after 'deploy:finalize_update', 'deploy:symlinks', 'deploy:bundler', 'deploy:bundle', 'deploy:init_rails'