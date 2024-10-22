# Initialize keycloak according to https://vermaden.wordpress.com/2024/03/10/keycloak-on-freebsd/
# Usage:
#   pot_init.sh <hostname> <postgres-password>

set -x

cat << EOF > /etc/rc.conf
hostname="$1"
ifconfig_DEFAULT="inet 10.1.1.211/24"
defaultrouter="10.1.1.1"
growfs_enable="YES"
zfs_enable="YES"
keycloak_enable="YES"
keycloak_env="KEYCLOAK_ADMIN=admin KEYCLOAK_ADMIN_PASSWORD=password"
EOF

echo 10.1.1.211 $1 keycloak >> /etc/hosts

mkdir -p /usr/local/etc/pkg/repos

sed -e s/quarterly/latest/g /etc/pkg/FreeBSD.conf \
                   > /usr/local/etc/pkg/repos/FreeBSD.conf

echo nameserver 1.1.1.1 > /etc/resolv.conf

drill freebsd.org | grep '^[^;]'

service netif restart
service routing restart
service hostname restart

set -e

pkg install -y keycloak \
     postgresql16-client

# TODO: move postgres to separate pot
# service postgresql enable
# service postgresql initdb
# service postgresql start
# 
# sockstat -l4

# Add postgres user to access database
pw user add \
	-n postgres \
	- d /home/postgres \
	-m

tail -1 /etc/passwd

mkdir -p /home/postgres

# su - postgres -c "psql -c \"ALTER USER postgres WITH PASSWORD '$2'\";"
su - postgres -c "psql -h localhost -p 5432 -c \"CREATE DATABASE keycloak with encoding 'UTF8';\""
# psql -U postgres -c "CREATE DATABASE keycloak with encoding 'UTF8';"
su - postgres -c "psql -h localhost -p 5432 -c \"GRANT ALL ON DATABASE keycloak TO postgres;\""
# psql -U postgres -c "GRANT ALL ON DATABASE keycloak TO postgres;"

cd /usr/local/share/java/keycloak/conf

openssl req -x509 -newkey rsa:2048 -keyout server.key.pem -out server.crt.pem -days 36500 -nodes -subj "/C=BE/CN=auth.jomy.dev"
chmod 600 server.crt.pem server.key.pem
chown keycloak:keycloak server.crt.pem server.key.pem

cat << EOF > /usr/local/share/java/keycloak/conf/keycloak.conf               
db=postgres
db-username=postgres
db-password=$2
db-url=jdbc:postgresql://localhost:5432/keycloak
hostname-strict-https=true
hostname-url=$1
hostname=$1
hostname-admin-url=$1
hostname-admin=$1
https-certificate-file=/usr/local/share/java/keycloak/conf/server.crt.pem
https-certificate-key-file=/usr/local/share/java/keycloak/conf/server.key.pem
proxy=edge
EOF

echo quarkus.transaction-manager.enable-recovery=true > /usr/local/share/java/keycloak/conf/quarkus.properties

chown keycloak:keycloak /usr/local/share/java/keycloak/conf/quarkus.properties
service keycloak enable
service keycloak build
/usr/local/share/java/keycloak/bin/kc.sh show-config

# Patch file
pkg install -y ruby
# TODO!
ruby -e 'f=File.read("/usr/local/etc/rc.d/keycloak");a=f.lines;a.insert(a.index { |i| i.strip == ": ${keycloak_flags=\"start\"}" } + 1, ": ${keycloak_env=\"\"}");a.insert(a.index { |i| !(i =~ /\$\{command\} \$\{command_args\} \\/).nil? } + 1, "env ${keycloak_env}");File.write("/usr/local/etc/rc.d/keycloak", a.join(""))'
pkg delete -y ruby

pkg clean -y

