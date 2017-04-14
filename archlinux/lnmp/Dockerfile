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
            extra/mariadb \__SAMBA_INSTALL__
            core/openssh \
            extra/vim \
            core/sudo \
            extra/zsh \__PHP_INSTALL__
            extra/memcached \
            community/redis \
            htop \
            subversion \
            binutils \
            git \
    && pacman --noconfirm -Sc \
    && useradd -G users -m -p "\$6\$BLzY/AKcZQbH3m0H\$ZWZVwfjwxMHGC4PwI9SMlqritnq6TcPiaPI13CKjc7CKPhXkiGBINCKvr1V41DVZW0LpRwbs/qW4RZci1fV5H0" __DEFAULT_USER__ \
    && echo "__DEFAULT_USER__ ALL=(ALL:ALL) __NO_PASSWD__ALL" >> /etc/sudoers \
    && rm -f /etc/localtime \
    && ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && /usr/bin/ssh-keygen -A \
    && echo -e "zh_CN.GB18030 GB18030\nzh_CN.GBK GBK\nzh_CN.UTF-8 UTF-8\nzh_CN GB2312" >> /etc/locale.gen \
    && locale-gen \
    && echo LANG="en_US.UTF-8" > /etc/locale.conf \
    && echo -e "alias ll='ls -las --color=auto' \nalias rm='rm -i' \nalias cp='cp -i'\n alias mv='mv -i'" >> /home/__DEFAULT_USER__/.bashrc
__PHP56_INSTALL__

VOLUME /data

RUN mkdir -p /data/vhosts \
    && ln -s /data/vhosts /home/__DEFAULT_USER__/vhosts \
    && mkdir -p /etc/nginx/vhost \
    && mkdir -p /var/run/nginx \
    && mkdir -p /var/log/nginx \
    && mkdir -p /var/log/__PHP_VERSION__ \
    && mkdir -p /var/run/__PHP_VERSION__-fpm \
    && chown -R __DEFAULT_USER__:users /var/log/__PHP_VERSION__


ADD confs/start    /etc/init.d/start
RUN chmod a+x /etc/init.d/start
__SAMABA_CONF__
ADD confs/my.cnf /etc/mysql/my.cnf
ADD confs/nginx/*.conf  /etc/nginx/
ADD confs/nginx/vhost/*.conf  /etc/nginx/vhost/
ADD confs/php/php.ini /etc/__PHP_VERSION__/php.ini
ADD confs/php/php-fpm.conf /etc/__PHP_VERSION__/php-fpm.conf
ADD confs/php/conf.d/*  /etc/__PHP_VERSION__/conf.d/
ADD confs/branch.sh /home/__DEFAULT_USER__/branch.sh
ADD confs/sync_database.sh /home/__DEFAULT_USER__/sync_database.sh

EXPOSE 22 80 __SMB_PORT__3306

# CMD /etc/init.d/start

ENTRYPOINT /etc/init.d/start
