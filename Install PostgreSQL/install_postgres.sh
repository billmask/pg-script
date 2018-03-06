su - root

cd /usr/locar/src/

wget "https://ftp.postgresql.org/pub/source/v9.6.8/postgresql-9.6.8.tar.gz"

tar zxf postgresql-9.6.8.tar.gz

cd postgresql-9.6.8

./configure --prefix=/usr/local/pgsql-9.6.8

make -j2; make install

cd contrib/

make -j2; make install

cd /usr/local/

ln -s pgsql-9.6.8 pgsql

mkdir -p /dados/pgdata

chown -R postgres.postgres /dados/pgdata

su - postgres

/usr/local/pgsql/bin/initdb -D /dados/pgdata/ -E UTF8 --lc-collate="pt_BR.UTF-8" --lc-ctype="pt_BR.UTF-8" 

/usr/local/pgsql/bin/pg_ctl -D /dados/pgdata/ -l logfile start
