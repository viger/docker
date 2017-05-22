FROM daocloud.io/library/ubuntu:zesty-20170411
MAINTAINER Tom Chan <viger@mchen.info>

# install base applications
RUN echo "nameserver 61.139.2.69\nnameserver 114.114.114.114" > /etc/resolv.conf \
    && sed -i "s/archive\.ubuntu/mirrors\.163/g" /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y openssh-server \
                       gcc \
                       g++ \
                       cmake \
                       make \
                       autoconf \
                       nginx \
                       tzdata \
                       ntp \
                       cron \
                       sudo \
                       locales \
                       mariadb-server \
                       memcached \
                       redis-server \
                       subversion \
                       vim \
                       htop \
                       libxml2-dev \
                       libcurl4-openssl-dev \
                       libssl-dev \
                       libsslcommon2-dev \
                       libpcre3-dev \
                       libsqlite3-dev \
                       libbz2-dev \
                       #libcurl4-gnutls-dev \
                       libgdbm-dev \
                       libenchant-dev \
                       libjpeg-dev \
                       libpng-dev \
                       libxpm-dev \
                       libfreetype6-dev \
                       libgd-dev \
                       libgmp-dev \
                       libc-client-dev \
                       libkrb5-dev \
                       libldap2-dev \
                       libsasl2-dev \
                       libmcrypt-dev \
                       freetds-dev \
                       unixodbc-dev \
                       postgresql-server-dev-9.6 \
                       libpspell-dev \
                       libsnmp-dev \
                       libtidy-dev \
                       libxslt1-dev \
                       libzip-dev \
    && ln -s /usr/lib/x86_64-linux-gnu/libssl.so  /usr/lib \
    && ln -s /usr/lib/x86_64-linux-gnu/libpcre.a /usr/lib/. \
    && ln -s /usr/lib/x86_64-linux-gnu/libpcre.so /usr/lib/. \
    && ln -s /usr/include/x86_64-linux-gnu/curl /usr/include/. \
    && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/. \
    && ln -s /usr/lib/x86_64-linux-gnu/libldap.a /usr/lib/. \
    && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/. \
    && ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/. \
    && ln -s /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/. \
    # && /usr/bin/mysql_install_db \
    && mkdir /var/run/mysql \
    && chown mysql:mysql -R /var/run/mysql \
    && apt-get clean

# complie php56
RUN cd /root \
    && wget http://cn2.php.net/distributions/php-5.6.30.tar.gz \
    && tar xvfz php-5.6.30.tar.gz \
    && cd php-5.6.30 \
    && './configure' '--srcdir=../php-5.6.30' '--config-cache' '--prefix=/usr' '--sysconfdir=/etc/php56' '--localstatedir=/var' '--libdir=/usr/lib/php56' '--datarootdir=/usr/share/php56' '--datadir=/usr/share/php56' '--program-suffix=56' '--with-layout=GNU' '--with-config-file-path=/etc/php56' '--with-config-file-scan-dir=/etc/php56/conf.d' '--disable-rpath' '--without-pear' '--enable-fpm' '--with-fpm-user=www-data' '--with-fpm-group=www-data' '--enable-bcmath=shared' '--enable-calendar=shared' '--enable-dba=shared' '--enable-exif=shared' '--enable-ftp=shared' '--enable-gd-native-ttf' '--enable-intl=shared' '--enable-mbstring' '--enable-opcache' '--enable-phar=shared' '--enable-posix=shared' '--enable-shmop=shared' '--enable-soap=shared' '--enable-sockets=shared' '--enable-sysvmsg=shared' '--enable-sysvsem=shared' '--enable-sysvshm=shared' '--enable-zip=shared' '--with-bz2=shared' '--with-curl=shared' '--with-db5=/usr' '--with-enchant=shared,/usr' '--with-freetype-dir=/usr' '--with-xpm-dir=/usr' '--with-gd=shared,/usr' '--with-gdbm' '--with-gettext=shared' '--with-gmp=shared' '--with-iconv=shared' '--with-icu-dir=/usr' '--with-imap-ssl' '--with-imap=shared' '--with-kerberos=/usr' '--with-jpeg-dir=/usr' '--with-vpx-dir=no' '--with-ldap=shared' '--with-ldap-sasl' '--with-libzip' '--with-mcrypt=shared' '--with-mhash' '--with-mssql=shared' '--with-mysql-sock=/run/mysqld/mysqld.sock' '--with-mysql=shared,mysqlnd' '--with-mysqli=shared,mysqlnd' '--with-openssl=shared' '--with-pcre-regex=/usr' '--with-pdo-dblib=shared,/usr' '--with-pdo-mysql=shared,mysqlnd' '--with-pdo-odbc=shared,unixODBC,/usr' '--with-pdo-pgsql=shared' '--with-pdo-sqlite=shared,/usr' '--with-pgsql=shared' '--with-png-dir=/usr' '--with-pspell=shared' '--with-snmp=shared' '--with-sqlite3=shared,/usr' '--with-tidy=shared' '--with-unixODBC=shared,/usr' '--with-xmlrpc=shared' '--with-xsl=shared' '--with-zlib' 'CFLAGS=-march=x86-64 '-mtune=generic' '-O2' '-pipe' '-fstack-protector-strong'' 'LDFLAGS=-Wl,-O1,--sort-common,--as-needed,-z,relro' 'CPPFLAGS=-D_FORTIFY_SOURCE=2' 'CXXFLAGS=-march=x86-64 '-mtune=generic' '-O2' '-pipe' '-fstack-protector-strong'' \
    && make \
    && make install \
    # && cp php.ini-development /etc/php56/php.ini \
    # && cp /etc/php56/php-fpm.conf.default /etc/php56/php-fpm.conf \
    && mkdir /etc/php56/conf.d \
    && mkdir /etc/php56/fpm.d \
    && rm -rf /root/php-5.6.30*
    # && sed -i 's/http/www-data/g' /etc/php56/php-fpm.conf

# complie the extends (redis, memcache) for php56
RUN cd /root \
    && wget http://pecl.php.net/get/redis-3.1.2.tgz \
    && tar xvfz redis-3.1.2.tgz \
    && cd redis-3.1.2 \
    && /usr/bin/phpize56 \
    && ./configure --with-php-config=/usr/bin/php-config56 \
    && make \
    && make install \
    && echo "extension = redis.so" > /etc/php56/conf.d/redis.ini \
    && cd .. \
    && wget http://pecl.php.net/get/memcache-3.0.8.tgz \
    && tar xvfz memcache-3.0.8.tgz \
    && cd memcache-3.0.8 \
    && /usr/bin/phpize56 \
    && ./configure --with-php-config=/usr/bin/php-config56 \
    && make \
    && make install \
    && echo "extension = memcache.so" > /etc/php56/conf.d/memcache.ini \
    && cd .. \
    && rm -rf memcache-3.0.8* redis-3.1.2*

# add user & set timezone & language && alias for user
RUN useradd -G users -m -p "\$6\$BLzY/AKcZQbH3m0H\$ZWZVwfjwxMHGC4PwI9SMlqritnq6TcPiaPI13CKjc7CKPhXkiGBINCKvr1V41DVZW0LpRwbs/qW4RZci1fV5H0" -s /bin/bash __DEFAULT_USER__ \
    && echo "__DEFAULT_USER__ ALL=(ALL:ALL) ALL" >> /etc/sudoers \
    && rm -f /etc/localtime \
    && ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "zh_CN.GB18030 GB18030\nzh_CN.GBK GBK\nzh_CN.UTF-8 UTF-8\nzh_CN GB2312" >> /etc/locale.gen \
    && locale-gen \
    && echo LANG="en_US.UTF-8" > /etc/locale.conf \
    && echo "alias ll='ls -las --color=auto' \nalias rm='rm -i' \nalias cp='cp -i'\n alias mv='mv -i'" >> /home/__DEFAULT_USER__/.bashrc \
    && sed -ri 's/^session\s+required\s+pam_loginuid.so$/session optional pam_loginuid.so/' /etc/pam.d/sshd

# add files of configures & startup & ssh info
ADD php56/. /etc/php56/.
ADD nginx/. /etc/nginx/.
ADD mysql/. /etc/mysql/.
ADD ssh/. /etc/ssh/.
ADD start   /etc/init.d/start
RUN chmod a+x /etc/init.d/start \
    && echo "__SSH_LOGIN_INFO__" > /etc/motd

EXPOSE 22 80 3306

ENTRYPOINT /etc/init.d/start
