#!/bin/bash

# Script para instalar Apache e PHP no Arch Linux com extensões específicas
# Execute como root ou com sudo

set -e

# Atualizar o sistema
echo "Atualizando o sistema..."
yay -Syu --noconfirm

# Instalar Apache
echo "Instalando Apache..."
yay -S --noconfirm apache

# Instalar PHP e extensões principais
echo "Instalando PHP e extensões principais..."
yay -S --noconfirm php84 php84-apache

# Instalar extensões obrigatórias
echo "Instalando extensões obrigatórias..."
yay -S --noconfirm \
    php84-mbstring \
    php84-zlib \
    php84-json \
    php84-xml \
    php84-dom

# Instalar extensões opcionais
echo "Instalando extensões opcionais..."
yay -S --noconfirm \
    php84-curl \
    php84-exif \
    php84-gd \
    php84-intl \
    php84-ldap \
    php84-pdo \
    php-pgsql \
    php-sqlite \
    php-redis \
    php84-sodium \
    php84-tidy \
    php84-zip

# Instalar ImageMagick (alternativa ao GD)
echo "Instalando ImageMagick..."
yay -S --noconfirm imagemagick php-imagick

# Instalar UUID (PECL)
echo "Instalando UUID PECL..."
yay -S --noconfirm php-uuid

# Instalar XXTEA (PECL)
echo "Instalando XXTEA PECL..."
# Nota: XXTEA pode não estar disponível nos repositórios oficiais
# Pode ser necessário instalar via pecl
yay -S --noconfirm php-pear
pecl install xxtea || echo "XXTEA pode não estar disponível via PECL"

# Configurar Apache para usar PHP
echo "Configurando Apache..."
sudo sed -i 's/#LoadModule mpm_event_module/LoadModule mpm_event_module/' /etc/httpd/conf/httpd.conf
sudo sed -i 's/#LoadModule mpm_prefork_module/LoadModule mpm_prefork_module/' /etc/httpd/conf/httpd.conf

# Adicionar handler do PHP no Apache
echo "Adicionando configuração do PHP no Apache..."
sudo tee /etc/httpd/conf/extra/php.conf > /dev/null << 'EOL'
LoadModule php_module modules/libphp.so
AddHandler php-script .php

# Configurações do PHP
<FilesMatch \.php$>
    SetHandler application/x-httpd-php
</FilesMatch>

<IfModule dir_module>
    DirectoryIndex index.php index.html
</IfModule>
EOL

# Incluir configuração do PHP no httpd.conf
echo "Include conf/extra/php.conf" | sudo tee -a /etc/httpd/conf/httpd.conf > /dev/null

# Habilitar e iniciar serviços
echo "Habilitando e iniciando serviços..."
sudo systemctl enable httpd
sudo systemctl start httpd

# Configurar PHP
echo "Configurando PHP..."
# Habilitar extensões necessárias
sudo sed -i 's/;extension=mbstring/extension=mbstring/' /etc/php/php.ini
sudo sed -i 's/;extension=curl/extension=curl/' /etc/php/php.ini
sudo sed -i 's/;extension=gd/extension=gd/' /etc/php/php.ini
sudo sed -i 's/;extension=exif/extension=exif/' /etc/php/php.ini
sudo sed -i 's/;extension=intl/extension=intl/' /etc/php/php.ini
sudo sed -i 's/;extension=ldap/extension=ldap/' /etc/php/php.ini
sudo sed -i 's/;extension=pdo_mysql/extension=pdo_mysql/' /etc/php/php.ini
sudo sed -i 's/;extension=pdo_pgsql/extension=pdo_pgsql/' /etc/php/php.ini
sudo sed -i 's/;extension=pdo_sqlite/extension=pdo_sqlite/' /etc/php/php.ini
sudo sed -i 's/;extension=redis/extension=redis/' /etc/php/php.ini
sudo sed -i 's/;extension=sodium/extension=sodium/' /etc/php/php.ini
sudo sed -i 's/;extension=tidy/extension=tidy/' /etc/php/php.ini
sudo sed -i 's/;extension=zip/extension=zip/' /etc/php/php.ini

# Configurações recomendadas
sudo sed -i 's/;date.timezone =/date.timezone = America\/Sao_Paulo/' /etc/php/php.ini
sudo sed -i 's/memory_limit = 128M/memory_limit = 256M/' /etc/php/php.ini
sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 64M/' /etc/php/php.ini
sudo sed -i 's/post_max_size = 8M/post_max_size = 64M/' /etc/php/php.ini

# Criar arquivo de teste PHP
echo "Criando arquivo de teste..."
sudo tee /srv/http/info.php > /dev/null << 'EOL'
<?php
phpinfo();
?>
EOL

# Ajustar permissões
sudo chown -R http:http /srv/http/

# Reiniciar Apache
echo "Reiniciando Apache..."
sudo systemctl restart httpd

echo "Instalação concluída!"
echo "Acesse http://localhost/info.php para verificar a instalação"
echo ""
echo "Extensões instaladas:"
php -m | grep -E '(mbstring|zlib|json|xml|dom|curl|exif|gd|gnupg|intl|ldap|openssl|pdo|redis|sodium|tidy|zip)'

echo ""
echo "Notas:"
echo "- XXTEA pode precisar ser instalado manualmente se não estiver disponível"
echo "- Ajuste o timezone no php.ini conforme sua localização"
echo "- Verifique as configurações de segurança do Apache e PHP"

# Baixar e instalar SnappyMail
echo "Instalando SnappyMail..."

# Verificar se wget está instalado
if ! command -v wget &> /dev/null; then
    echo "Instalando wget..."
    sudo pacman -S --noconfirm wget
fi

# Criar diretório se não existir
if [ ! -d "/srv/http" ]; then
    echo "Criando diretório /srv/http..."
    sudo mkdir -p /srv/http
fi

# Baixar o SnappyMail
echo "Baixando SnappyMail..."
cd /tmp
if wget https://snappymail.eu/repository/latest.tar.gz; then
    echo "Download concluído com sucesso!"
else
    echo "Erro ao baixar o SnappyMail!"
    echo "Tentando método alternativo com curl..."
    if command -v curl &> /dev/null; then
        curl -O https://snappymail.eu/repository/latest.tar.gz
    else
        sudo pacman -S --noconfirm curl
        curl -O https://snappymail.eu/repository/latest.tar.gz
    fi
    
    if [ ! -f latest.tar.gz ]; then
        echo "Falha ao baixar SnappyMail. Verifique sua conexão com a internet."
        exit 1
    fi
fi

# Mover para /srv/http
echo "Movendo arquivo para /srv/http..."
sudo mv latest.tar.gz /srv/http/

# Descompactar
echo "Descompactando SnappyMail..."
cd /srv/http
sudo tar -xzf latest.tar.gz

# Verificar se descompactou corretamente
if [ ! -d "/srv/http/index.php" ] && [ ! -d "/srv/http/snappymail" ]; then
    # Provavelmente criou um diretório com a versão
    snappy_dir=$(find /srv/http -maxdepth 1 -type d -name "snappymail-*" | head -1)
    if [ -n "$snappy_dir" ]; then
        echo "Movendo arquivos do diretório da versão..."
        sudo mv "$snappy_dir"/* /srv/http/
        sudo mv "$snappy_dir"/.* /srv/http/ 2>/dev/null || true
        sudo rmdir "$snappy_dir"
    fi
fi

# Ajustar permissões
echo "Ajustando permissões para usuário http e grupo http..."
sudo chown -R http:http /srv/http/
sudo chmod -R 755 /srv/http/
sudo find /srv/http/ -type f -exec chmod 644 {} \;

# Configurar permissões específicas para diretórios de escrita
if [ -d "/srv/http/data" ]; then
    sudo chmod -R 775 /srv/http/data/
fi

if [ -d "/srv/http/_logs_" ]; then
    sudo chmod -R 775 /srv/http/_logs_/
fi

# Limpar arquivo tar.gz
sudo rm -f /srv/http/latest.tar.gz

# Verificar instalação
if [ -f "/srv/http/index.php" ]; then
    echo "SnappyMail instalado com sucesso em /srv/http/"
    echo "Acesse http://localhost/ para configurar"
else
    echo "Aviso: index.php não encontrado. Verifique se a extração foi bem sucedida."
    echo "Conteúdo do diretório /srv/http/:"
    ls -la /srv/http/
fi
