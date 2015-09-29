sudo apt-get update
sudo apt-get install -y git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev

sudo -u vagrant git clone git://github.com/sstephenson/rbenv.git /home/vagrant/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> /home/vagrant/.bashrc
echo 'eval "$(rbenv init -)"' >> /home/vagrant/.bashrc
source /home/vagrant/.bashrc

sudo -u vagrant git clone git://github.com/sstephenson/ruby-build.git /home/vagrant/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> /home/vagrant/.bashrc
source /home/vagrant/.bashrc

sudo -u vagrant git clone https://github.com/sstephenson/rbenv-gem-rehash.git /home/vagrant/.rbenv/plugins/rbenv-gem-rehash

debconf-set-selections <<< 'mysql-server mysql-server/root_password password yourpasswd'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password yourpasswd'

sudo apt-get install -y mysql-server mysql-client libmysqld-dev nodejs imagemagick
