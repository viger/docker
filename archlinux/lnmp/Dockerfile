FROM archlinux
MAINTAINER tom chen <viger@mchen.info>

RUN echo -e "Server = http://mirrors.aliyun.com/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist \
    && echo -e "\n[archlinuxcn]\nSigLevel = Optional TrustedOnly\nServer = http://mirrors.163.com/archlinux-cn/\$arch\n\n[archlinuxfr]\nServer = http://repo.archlinux.fr/\$arch" >> /etc/pacman.conf \
    && echo 'AURURL="https://aur.tuna.tsinghua.edu.cn"' >> /etc/yaourtrc \
    && pacman -Syyu --noconfirm \
    && pacman-db-upgrade \
    && pacman -S --noconfirm \
            archlinuxcn/yaourt \
            base-devel \
            core/iptables \
            core/libpcap \
            core/patch \
            extra/nginx \
            extra/mariadb \
            extra/samba \
            core/openssh \
            extra/vim \
            core/sudo \
            extra/zsh \
#            extra/php \
#            extra/php-cgi \
#            extra/php-dblib \
#            extra/php-embed \
#            extra/php-enchant \
#            extra/php-fpm \
#            extra/php-gd \
#            extra/php-imap \
#            extra/php-intl \
#            extra/php-ldap \
#            extra/php-mcrypt \
#            community/php-memcache \
#            community/php-mongodb \
#            extra/php-odbc \
#            extra/php-pgsql \
#            extra/php-phpdbg \
#            extra/php-pspell \
#            extra/php-snmp \
#            extra/php-sqlite \
#            extra/php-tidy \
#            community/xdebug \
#            extra/php-xsl \
            extra/memcached \
            community/redis \
            htop \
            subversion \
            binutils \
            git \
    && pacman --noconfirm -Sc \
    && useradd -G users -m -p "\$6\$BLzY/AKcZQbH3m0H\$ZWZVwfjwxMHGC4PwI9SMlqritnq6TcPiaPI13CKjc7CKPhXkiGBINCKvr1V41DVZW0LpRwbs/qW4RZci1fV5H0" tom \
    && echo "tom ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && rm -f /etc/localtime \
    && ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && /usr/bin/ssh-keygen -A \
    && echo -e "zh_CN.GB18030 GB18030\nzh_CN.GBK GBK\nzh_CN.UTF-8 UTF-8\nzh_CN GB2312" >> /etc/locale.gen \
    && locale-gen \
    && echo LANG="en_US.UTF-8" > /etc/locale.conf
RUN su - tom -c 'gpg --recv-key C2BF0BC433CFC8B3 && yaourt -Sy --noconfirm php56 php56-imagick php56-memcache php56-xdebug' \
    && git clone https://github.com/phpredis/phpredis.git \
    && cd phpredis \
    && /usr/bin/phpize56 \
    && ./configure \
    && make \
    && make install \
    && cd .. \
    && rm -rf phpredis

VOLUME /data

RUN mkdir -p /data/vhosts \
    && ln -s /data/vhosts /home/tom/vhosts \
    && mkdir -p /etc/nginx/vhost \
    && mkdir -p /var/run/nginx \
    && mkdir -p /var/run/php-fpm \
#    && mkdir -p /var/log/php \
    && mkdir -p /var/log/php56 \
    && mkdir -p /var/log/nginx  \
#    && chown -R tom:users /var/log/php \
    && chown -R tom:users /var/log/php56

ADD confs/start    /etc/init.d/start
RUN chmod a+x /etc/init.d/start
ADD confs/smb.conf /etc/samba/smb.conf
ADD confs/my.cnf /etc/mysql/my.cnf
ADD confs/nginx/*.conf  /etc/nginx/
ADD confs/nginx/vhost/*.conf  /etc/nginx/vhost/
ADD confs/php56/php.ini /etc/php56/php.ini
ADD confs/php56/php-fpm.conf /etc/php56/php-fpm.conf
ADD confs/php56/conf.d/*  /etc/php56/conf.d/
# ADD confs/php/php.ini /etc/php/php.ini
# ADD confs/php/php-fpm.conf /etc/php/php-fpm.conf
# ADD confs/php/conf.d/*  /etc/php/conf.d/

EXPOSE 22 80 137 139 445 3306

# CMD /etc/init.d/start

ENTRYPOINT /etc/init.d/start
