set :application, "one_to_one_mailer"
set :repository,  "git@github.com:digitalscientists/one_to_one_mailer.git"

set :scm, :git
set :ssh_options, { :forward_agent => true }
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`
set :user, 'ubuntu'

set :deploy_to, "~/#{application}"
set :port, '30306'
role :app, "ec2-54-234-209-191.compute-1.amazonaws.com"                          # This may be the same as your `Web` server
set :branch, 'master'

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end
