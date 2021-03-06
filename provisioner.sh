CODENAME=$(lsb_release -c | sed 's/['Codename:'| /( \t)]//g')
PGVERSION=9.5
RBVERSION=2.5.0
NDVERSION=10.15.0
EXVERSION=1.8.0

sudo -H -u vagrant bash -i -c "wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && sudo dpkg -i erlang-solutions_1.0_all.deb"

echo 'Updating repositories...'
sudo apt-get update
echo 'Installing dependencies...'
sudo apt-get install -y \
git-core \
curl \
zlib1g-dev \
build-essential \
libssl-dev \
libreadline-dev \
libyaml-dev \
libxml2-dev \
libxslt1-dev \
libcurl4-openssl-dev \
python-software-properties \
libffi-dev \
ghostscript \
redis-server \
imagemagick \
esl-erlang

echo 'Installing Rbenv...'
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

echo 'Installing Postgres...'
if [ "$(apt-cache policy postgresql-client-$PGVERSION | grep -c postgresql-client | head -n 1)" = "0" ];
then
  sudo sh -c "sudo echo "deb http://apt.postgresql.org/pub/repos/apt/ $CODENAME-pgdg main" >> /etc/apt/sources.list"
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt-get update
fi

sudo apt-get install -y postgresql-$PGVERSION postgresql-client-$PGVERSION postgresql-contrib-$PGVERSION libpq-dev

echo 'Ensure postgres credentials...'
sudo -u postgres psql -c "CREATE ROLE henrique SUPERUSER LOGIN PASSWORD 'linuxhenrique';"
sudo -u postgres psql -c "ALTER USER postgres WITH password 'postgres';"

echo 'Exposing postgres to vagrant host...'
sudo sh -c "sed -i -- 's/seed/md5/g' /etc/postgresql/$PGVERSION/main/pg_hba.conf"
sudo sh -c "sudo sed -i -- 's/peer/md5/g' /etc/postgresql/$PGVERSION/main/pg_hba.conf"
sudo sh -c "sudo sed -i \"s/$(grep listen_addresses /etc/postgresql/$PGVERSION/main/postgresql.conf)/$(grep listen_addresses /etc/postgresql/$PGVERSION/main/postgresql.conf | cut -c 2-20) '*'/g\" /etc/postgresql/$PGVERSION/main/postgresql.conf"

sudo sh -c "sudo echo '# IPv4 local connections:' >> /etc/postgresql/$PGVERSION/main/pg_hba.conf"
sudo sh -c "sudo echo 'host    all             all             127.0.0.1/32            md5' >> /etc/postgresql/$PGVERSION/main/pg_hba.conf"
sudo sh -c "sudo echo 'host    all             all             0.0.0.0/0               md5' >> /etc/postgresql/$PGVERSION/main/pg_hba.conf"

sudo /etc/init.d/postgresql restart

sudo -H -u vagrant bash -i -c "rbenv install $RBVERSION"
sudo -H -u vagrant bash -i -c "rbenv global $RBVERSION"

echo 'gem: --no-rdoc --no-ri' >> ~/.gemrc
sudo -H -u vagrant bash -i -c "gem install bundler"

sudo -H -u vagrant bash -i -c "wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.6/install.sh | bash"
sudo -H -u vagrant bash -i -c "nvm install $NDVERSION"

sudo -H -u vagrant bash -i -c "curl -sSL https://raw.githubusercontent.com/taylor/kiex/master/install | bash -s"
echo '[[ -s "$HOME/.kiex/scripts/kiex" ]] && source "$HOME/.kiex/scripts/kiex"' >> ~/.bashrc
source ~/.bashrc
sudo -H -u vagrant bash -i -c "kiex install $EXVERSION"

sudo -H -u vagrant bash -i -c "sudo locale-gen pt_BR.UTF-8"
