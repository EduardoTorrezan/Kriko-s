#!/bin/bash
set -e

# Log de execução
exec > >(tee -a /var/log/krikos-startup.log) 2>&1
echo "=== INICIANDO SETUP KRIKO'S ==="
date

# 1. Configurar Swap de 2GB (essencial para VM e2-miclsro de 1GB não sofrer OOM)
if [ ! -f /swapfile ]; then
    echo "--- Configurando Swap de 2GB ---"
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# 2. Atualizar repositórios e instalar dependências essenciais
echo "--- Instalando pacotes básicos ---"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y software-properties-common curl git unzip apache2 mariadb-server

# 3. Adicionar repositório PPA do PHP e instalar PHP 8.4
echo "--- Instalando PHP 8.4 ---"
add-apt-repository -y ppa:ondrej/php
apt-get update
apt-get install -y php8.4 php8.4-cli php8.4-mysql php8.4-xml php8.4-mbstring php8.4-curl libapache2-mod-php8.4 composer

# 4. Configurar MariaDB / MySQL (localhost e 127.0.0.1)
echo "--- Configurando Banco de Dados ---"
systemctl start mariadb
systemctl enable mariadb

mysql -e "CREATE DATABASE IF NOT EXISTS krikos_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS 'krikos_user'@'localhost' IDENTIFIED BY 'KrikosAdmin@2026';"
mysql -e "CREATE USER IF NOT EXISTS 'krikos_user'@'127.0.0.1' IDENTIFIED BY 'KrikosAdmin@2026';"
mysql -e "GRANT ALL PRIVILEGES ON krikos_db.* TO 'krikos_user'@'localhost';"
mysql -e "GRANT ALL PRIVILEGES ON krikos_db.* TO 'krikos_user'@'127.0.0.1';"
mysql -e "FLUSH PRIVILEGES;"

# 5. Baixar código do repositório
echo "--- Baixando repositório Kriko's ---"
rm -rf /var/www/krikos
git clone https://github.com/joaodamasio22/Kriko-s.git /var/www/krikos
cd /var/www/krikos

# 6. Rodar Composer
echo "--- Instalando dependências do Composer ---"
export COMPOSER_ALLOW_SUPERUSER=1
if [ -f /var/www/krikos/composer.json ]; then
    composer install --no-interaction --prefer-dist --optimize-autoloader
fi

# 7. Importar schema do banco de dados
echo "--- Importando Schema MySQL ---"
if [ -f /var/www/krikos/src/Repository/Schema/SchemaDb.sql ]; then
    mysql krikos_db < /var/www/krikos/src/Repository/Schema/SchemaDb.sql
fi

# Criar administrador inicial se não existir
mysql krikos_db -e "INSERT IGNORE INTO administradores (id, nome, email, senha, perfil, ativo) VALUES (1, 'Administrador', 'admin@krikos.com', 'admin123', 'MASTER', 'S');"

# 8. Permissões de arquivos
echo "--- Ajustando permissões ---"
mkdir -p /var/www/krikos/proxies
chown -R www-data:www-data /var/www/krikos
chmod -R 775 /var/www/krikos
chmod -R 777 /var/www/krikos/proxies

# 9. Configurar variáveis de ambiente do Apache
echo 'export KRIKOS_DB_HOST="127.0.0.1"' >> /etc/apache2/envvars
echo 'export KRIKOS_DB_PORT="3306"' >> /etc/apache2/envvars
echo 'export KRIKOS_DB_NAME="krikos_db"' >> /etc/apache2/envvars
echo 'export KRIKOS_DB_USER="krikos_user"' >> /etc/apache2/envvars
echo 'export KRIKOS_DB_PASSWORD="KrikosAdmin@2026"' >> /etc/apache2/envvars
echo 'export KRIKOS_WHATSAPP="5511999999999"' >> /etc/apache2/envvars
echo 'export KRIKOS_INSTAGRAM="krikos.oficial"' >> /etc/apache2/envvars

# 10. Configurar VirtualHost no Apache
echo "--- Configurando VirtualHost ---"
cat << 'EOF' > /etc/apache2/sites-available/krikos.conf
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
EOF

# 11. Ativar site e módulos no Apache
a2dissite 000-default.conf || true
a2ensite krikos.conf
a2enmod rewrite
systemctl restart apache2

echo "=== SETUP KRIKO'S CONCLUÍDO COM SUCESSO ==="
date
