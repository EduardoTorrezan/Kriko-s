#!/bin/bash
set -e

exec > >(tee -a /var/log/krikos-install.log) 2>&1
echo "=== INICIANDO DEPLOY KRIKO'S NA ORACLE CLOUD ==="
date

# 1. Liberar Firewall interno da Oracle (iptables)
echo "--- [1/10] Liberando firewall interno (iptables) para porta 80 e 443 ---"
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT || true
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT || true
sudo netfilter-persistent save 2>/dev/null || true

# 2. Configurar 2GB de Swap
if [ ! -f /swapfile ]; then
    echo "--- [2/10] Configurando 2GB de Swap ---"
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

# 3. Pacotes essenciais e repositório PHP
echo "--- [3/10] Instalando dependências e adicionando repositório PHP 8.4 ---"
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y software-properties-common curl git unzip apache2 mariadb-server
sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get update

# 4. Instalar PHP 8.4 e módulos
echo "--- [4/10] Instalando PHP 8.4 e módulos necessários ---"
sudo apt-get install -y php8.4 php8.4-cli php8.4-mysql php8.4-xml php8.4-mbstring php8.4-curl libapache2-mod-php8.4 composer

# 5. Configurar MariaDB / MySQL
echo "--- [5/10] Configurando Banco de Dados MariaDB ---"
sudo systemctl start mariadb
sudo systemctl enable mariadb

sudo mysql -e "CREATE DATABASE IF NOT EXISTS krikos_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -e "CREATE USER IF NOT EXISTS 'krikos_user'@'localhost' IDENTIFIED BY 'KrikosAdmin@2026';"
sudo mysql -e "CREATE USER IF NOT EXISTS 'krikos_user'@'127.0.0.1' IDENTIFIED BY 'KrikosAdmin@2026';"
sudo mysql -e "GRANT ALL PRIVILEGES ON krikos_db.* TO 'krikos_user'@'localhost';"
sudo mysql -e "GRANT ALL PRIVILEGES ON krikos_db.* TO 'krikos_user'@'127.0.0.1';"
sudo mysql -e "FLUSH PRIVILEGES;"

# 6. Baixar código do repositório
echo "--- [6/10] Clonando o repositório Kriko's ---"
sudo rm -rf /var/www/krikos
sudo git clone https://github.com/joaodamasio22/Kriko-s.git /var/www/krikos
cd /var/www/krikos

# 7. Composer install
echo "--- [7/10] Instalando dependências do Composer ---"
export COMPOSER_ALLOW_SUPERUSER=1
sudo composer install --no-interaction --prefer-dist --optimize-autoloader

# 8. Importar banco de dados e usuário admin
echo "--- [8/10] Importando Schema do Banco de Dados ---"
if [ -f /var/www/krikos/src/Repository/Schema/SchemaDb.sql ]; then
    sudo mysql krikos_db < /var/www/krikos/src/Repository/Schema/SchemaDb.sql
fi
sudo mysql krikos_db -e "INSERT IGNORE INTO administradores (id, nome, email, senha, perfil, ativo) VALUES (1, 'Administrador', 'admin@krikos.com', 'admin123', 'MASTER', 'S');"

# 9. Permissões de arquivos e proxies Doctrine
echo "--- [9/10] Ajustando permissões ---"
sudo mkdir -p /var/www/krikos/proxies
sudo chown -R www-data:www-data /var/www/krikos
sudo chmod -R 775 /var/www/krikos
sudo chmod -R 777 /var/www/krikos/proxies

# 10. Configurar Apache e VirtualHost
echo "--- [10/10] Configurando Apache ---"
echo 'export KRIKOS_DB_HOST="127.0.0.1"' | sudo tee -a /etc/apache2/envvars
echo 'export KRIKOS_DB_PORT="3306"' | sudo tee -a /etc/apache2/envvars
echo 'export KRIKOS_DB_NAME="krikos_db"' | sudo tee -a /etc/apache2/envvars
echo 'export KRIKOS_DB_USER="krikos_user"' | sudo tee -a /etc/apache2/envvars
echo 'export KRIKOS_DB_PASSWORD="KrikosAdmin@2026"' | sudo tee -a /etc/apache2/envvars
echo 'export KRIKOS_WHATSAPP="5511999999999"' | sudo tee -a /etc/apache2/envvars
echo 'export KRIKOS_INSTAGRAM="krikos.oficial"' | sudo tee -a /etc/apache2/envvars

sudo tee /etc/apache2/sites-available/krikos.conf > /dev/null << 'AVHOST'
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/krikos/public

    SetEnv KRIKOS_DB_HOST "127.0.0.1"
    SetEnv KRIKOS_DB_PORT "3306"
    SetEnv KRIKOS_DB_NAME "krikos_db"
    SetEnv KRIKOS_DB_USER "krikos_user"
    SetEnv KRIKOS_DB_PASSWORD "KrikosAdmin@2026"
    SetEnv KRIKOS_WHATSAPP "5511999999999"
    SetEnv KRIKOS_INSTAGRAM "krikos.oficial"

    <Directory /var/www/krikos/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/krikos_error.log
    CustomLog ${APACHE_LOG_DIR}/krikos_access.log combined
</VirtualHost>
AVHOST

sudo a2dissite 000-default.conf || true
sudo a2ensite krikos.conf
sudo a2enmod rewrite
sudo systemctl restart apache2

echo "=== DEPLOY CONCLUÍDO COM SUCESSO! ==="
date
