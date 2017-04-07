FROM archlinux
MAINTAINER tom chen <viger@mchen.info>

RUN echo -e "Server = http://mirrors.163.com/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist \
    && echo -e "\n[archlinuxcn]\nSigLevel = Optional TrustedOnly\nServer = http://mirrors.163.com/archlinux-cn/\$arch" >> /etc/pacman.conf \
    && pacman -Syyu --noconfirm \
    && pacman-db-upgrade \
    && pacman -S --noconfirm \
            archlinuxcn/yaourt \
            extra/nginx \
            extra/mariadb \
            extra/samba \
            core/openssh \
            extra/vim \
            core/sudo \
            extra/zsh \
            extra/php \
            extra/php-cgi \
            extra/php-dblib \
            extra/php-embed \
            extra/php-enchant \
            extra/php-fpm \
            extra/php-gd \
            extra/php-imap \
            extra/php-intl \
            extra/php-ldap \
            extra/php-mcrypt \
            community/php-memcache \
            community/php-mongodb \
            extra/php-odbc \
            extra/php-pgsql \
            extra/php-phpdbg \
            extra/php-pspell \
            extra/php-snmp \
            extra/php-sqlite \
            extra/php-tidy \
            community/xdebug \
            extra/php-xsl \
            extra/memcached \
            community/redis \
    && pacman --noconfirm -Sc \
    && useradd -G users -m -p "$6$MUMyGSiy$7F1sknUTZ6hQFzuPxLMV2YhrvYPdxiAXfliqwqhjbM.UeCu8MuYez0mGc0Phk3rLSJkUApxrhpPIpUbTc8G631" tom \
    && echo "tom ALL=(ALL:ALL) ALL" >> /etc/sudoers

VOLUME /home/vhosts

RUN mkdir -p /home/vhosts \
    && ln -s /home/vhosts /home/tom/vhosts

ADD confs/start    /etc/init.d/start
RUN chmod a+x /etc/init.d/start
ADD confs/smb.conf /etc/samba/smb.conf
ADD confs/nginx/*  /etc/nginx/
ADD confs/php56/php.ini /etc/php/php.ini
ADD confs/php56/php-fpm.conf /etc/php/php-fpm.conf
ADD confs/php56/conf.d/*  /etc/php/conf.d/
ADD confs/branch.sh /home/tom/branch.sh
ADD confs/sync_database.sh /home/tom/sync_database.sh

EXPOSE 22 80 137 455

CMD /etc/init.d/start

ENTRYPOINT ["/bin/bash"]
