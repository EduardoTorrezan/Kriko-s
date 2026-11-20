#!/bin/bash
set -e

echo "--- Configurando MariaDB para conexões externas ---"
sudo sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

sudo mysql << 'SQL'
CREATE USER IF NOT EXISTS 'krikos_user'@'%' IDENTIFIED BY 'KrikosAdmin@2026';
GRANT ALL PRIVILEGES ON krikos_db.* TO 'krikos_user'@'%';
FLUSH PRIVILEGES;
SQL

sudo iptables -I INPUT 5 -p tcp -m state --state NEW --dport 3306 -j ACCEPT || true
sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null

sudo systemctl restart mariadb
echo "MariaDB configurado e reiniciado com sucesso!"
