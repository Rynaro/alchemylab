####################################################
##               Shell Provisioning               ##
##                      for                       ##
##                Vagrant w. BrERP                ##
####################################################

## r-0.0.5-dev

##  Variáveis de controle
##  CODENAME: Captura o -c do lsb_release e isola o valor
##  do codenome da versão.
##  PGVERSION: Recebe valor, que pode ser alterado
##  para a versão desejada do PostgreSQL.

## Versões LTS marcadas pela PostgreSQL Global Group Dev.
## 8.4 / 9.0 / 9.1 / 9.2 / 9.4
## 9.3 está como stable pelo repositório universe do Ubuntu 14.04.

CODENAME=$(lsb_release -c | sed 's/['Codename:'| /( \t)]//g')
PGVERSION=9.3

echo '---------------------------------------------'
echo '|            BrERP Provisioning             |'
echo '|              version: 0.0.5               |'
echo '---------------------------------------------'
echo 'Updating Ubuntu repositories !'
sudo apt-get -qq update
echo 'Installing PostgreSQL packages and dependencies !'
echo "--> Searching PostgreSQL $PGVERSION ..."

## Verifica se pacote postgresql-client-(versão) está
## incluso nos repositórios oficiais do Ubuntu.
## Caso não, um repositório da PG é incluso, e a chave
## adicionada e autenticada.

if [ "$(apt-cache policy postgresql-client-$PGVERSION | grep -c postgresql-client | head -n 1)" = "0" ];
then
  echo 'Writing PostgreSQL repository in your sources.list'
  sudo echo "deb http://apt.postgresql.org/pub/repos/apt/ $CODENAME-pgdg main" >> /etc/apt/sources.list
  echo 'We need some keys to unlock the doors'
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  echo 'Updating Ubuntu repositories (again) !'
  sudo apt-get -qq update
fi

sudo apt-get install -y postgresql-$PGVERSION postgresql-client-$PGVERSION postgresql-contrib-$PGVERSION

## Inicia processos de configuração via psql
## utilizando o usuário postgres para evitar
## confilto de permissões.

echo 'Work in tasks inside psql'
sudo -u postgres psql -c "CREATE ROLE brerp SUPERUSER LOGIN PASSWORD 'senhabrerp';"
sudo -u postgres psql -c "ALTER USER postgres WITH password 'senhapostgres';"

echo 'Creating database brERP'
sudo -u postgres psql -c "CREATE DATABASE brerp ENCODING 'UNICODE' OWNER brerp;"

echo 'Look at the role! Change it!'
sudo -u postgres psql -c "ALTER ROLE brerp SET search_path TO adempiere, pg_catalog;"
echo 'UUID-OSSP extension will be created !'
sudo -u postgres psql -c 'CREATE EXTENSION "uuid-ossp";'

## Verifica se existe o arquivo Adempiere_pg.jar
## na pasta compartilhada entre o host e o guest.
## Caso tenha, será baixado o pacote unzip e em
## seguida descompactando o dump na home da vm
## Feito isso, o psql vai migrar a estrutura pro BD.
 
sudo -u postgres psql brerp < /vagrant/ExpDat_devcoffee.dmp

## Processo de alteração nas configurações do
## pg_hba.conf, utilizando a substituição de
## sentenças com stream de palavras.

echo 'PostgreSQL will be refined after this work !'
echo 'seed to md5'
sudo sed -i -- 's/seed/md5/g' /etc/postgresql/$PGVERSION/main/pg_hba.conf
echo 'peer to md5'
sudo sed -i -- 's/peer/md5/g' /etc/postgresql/$PGVERSION/main/pg_hba.conf
echo 'We dont like # in listen_address'
sudo sed -i "s/$(grep listen_addresses /etc/postgresql/$PGVERSION/main/postgresql.conf)/$(grep listen_addresses /etc/postgresql/$PGVERSION/main/postgresql.conf | cut -c 2-20) '*'/g" /etc/postgresql/$PGVERSION/main/postgresql.conf

sudo echo '# IPv4 local connections:' >> /etc/postgresql/$PGVERSION/main/pg_hba.conf
sudo echo 'host    all             all             127.0.0.1/32            md5' >> /etc/postgresql/$PGVERSION/main/pg_hba.conf
sudo echo 'host    all             all             0.0.0.0/0               md5' >> /etc/postgresql/$PGVERSION/main/pg_hba.conf

## Reinicialização do servidor PostgreSQL.

echo 'Take a rest Postgresql'
sudo /etc/init.d/postgresql restart
echo 'Wake up, Postgresql !'
