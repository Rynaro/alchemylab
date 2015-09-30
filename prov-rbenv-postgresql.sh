CODENAME=$(lsb_release -c | sed 's/['Codename:'| /( \t)]//g')
PGVERSION=9.3

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

if [ "$(apt-cache policy postgresql-client-$PGVERSION | grep -c postgresql-client | head -n 1)" = "0" ];
then
  sudo echo "deb http://apt.postgresql.org/pub/repos/apt/ $CODENAME-pgdg main" >> /etc/apt/sources.list
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt-get update
fi

sudo apt-get install -y postgresql-$PGVERSION postgresql-client-$PGVERSION postgresql-contrib-$PGVERSION libpq-dev

sudo -u postgres psql -c "CREATE ROLE yourrole SUPERUSER LOGIN PASSWORD 'yourpasswd';"
sudo -u postgres psql -c "ALTER USER postgres WITH password 'yourpasswd';"

sudo sed -i -- 's/seed/md5/g' /etc/postgresql/$PGVERSION/main/pg_hba.conf
sudo sed -i -- 's/peer/md5/g' /etc/postgresql/$PGVERSION/main/pg_hba.conf
sudo sed -i "s/$(grep listen_addresses /etc/postgresql/$PGVERSION/main/postgresql.conf)/$(grep listen_addresses /etc/postgresql/$PGVERSION/main/postgresql.conf | cut -c 2-20) '*'/g" /etc/postgresql/$PGVERSION/main/postgresql.conf

sudo echo '# IPv4 local connections:' >> /etc/postgresql/$PGVERSION/main/pg_hba.conf
sudo echo 'host    all             all             127.0.0.1/32            md5' >> /etc/postgresql/$PGVERSION/main/pg_hba.conf
sudo echo 'host    all             all             0.0.0.0/0               md5' >> /etc/postgresql/$PGVERSION/main/pg_hba.conf

sudo /etc/init.d/postgresql restart

