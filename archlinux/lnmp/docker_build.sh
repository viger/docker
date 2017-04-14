#!/bin/bash
SELF_NAME=$(basename $0)
DEFAULT_USER='tom'
DOCKER_TAG="docker:$(date +"%s%N")"

UNKOWN_TPL=$(cat <<EOF
Unkown argument: __ARG__, script exit.\n
\n
$0 is support args like this:\n
$0 [php|php56] nosmb
EOF
)

PHP_INSTALL_TPL=$(cat -s <<EOF
\n            extra/php \\\\
\\n            extra/php-cgi \\\\
\\n            extra/php-dblib \\\\
\\n            extra/php-embed \\\\
\\n            extra/php-enchant \\\\
\\n            extra/php-fpm \\\\
\\n            extra/php-gd \\\\
\\n            extra/php-imap \\\\
\\n            extra/php-intl \\\\
\\n            extra/php-ldap \\\\
\\n            extra/php-mcrypt \\\\
\\n            community/php-memcache \\\\
\\n            community/php-mongodb \\\\
\\n            extra/php-odbc \\\\
\\n            extra/php-pgsql \\\\
\\n            extra/php-phpdbg \\\\
\\n            extra/php-pspell \\\\
\\n            extra/php-snmp \\\\
\\n            extra/php-sqlite \\\\
\\n            extra/php-tidy \\\\
\\n            community/xdebug \\\\
\\n            extra/php-xsl \\\\ \t
EOF
)

PHP56_INSTALL_TPL=$(cat -s <<EOF
RUN su - __DEFAULT_USER__ -c \'gpg --recv-key C2BF0BC433CFC8B3 \&\& yaourt -Sy --noconfirm php56 php56-imagick php56-memcache php56-xdebug\' \\\\
\\n    \&\& git clone https://github.com/phpredis/phpredis.git \\\\
\\n    \&\& cd phpredis \\\\
\\n    \&\& /usr/bin/phpize56 \\\\
\\n    \&\& ./configure \\\\
\\n    \&\& make \\\\
\\n    \&\& make install \\\\
\\n    \&\& cd .. \\\\
\\n    \&\& rm -rf phpredis
EOF
)

SAMABA_INSTALL_TPL=$(cat -s <<EOF
\n            extra/samba \\\\ \t
EOF
)
SAMABA_CONF_TPL='ADD confs/smb.conf /etc/samba/smb.conf'


exec_php() {
    # exec_replace_tpl '__PHP_VERSION__' 'php'
    grep '__PHP_VERSION__' --exclude=$SELF_NAME -rl ./* | xargs sed -i 's/__PHP_VERSION__/php/g'
    exec_replace_tpl '__PHP56_INSTALL__' ''
    exec_replace_tpl '__NO_PASSWD__' ''
    exec_replace_tpl '__PHP_INSTALL__' "$PHP_INSTALL_TPL"
    echo ';extension = redis.so' > confs/php/conf.d/redis.ini
}

exec_php56() {
    # exec_replace_tpl '__PHP_VERSION__' 'php56'
    grep '__PHP_VERSION__' --exclude=$SELF_NAME -rl ./* | xargs sed -i 's/__PHP_VERSION__/php56/g'
    exec_replace_tpl '__NO_PASSWD__' 'NOPASSWD:'
    exec_replace_tpl '__PHP56_INSTALL__' "$PHP56_INSTALL_TPL"
    exec_replace_tpl '__PHP_INSTALL__' ''
    echo 'extension = redis.so' > confs/php/conf.d/redis.ini
}

exec_smb() {
    local si=$SAMABA_INSTALL_TPL
    local sc=$SAMABA_CONF_TPL
    local sca=' nmbd smbd'
    local scc=" ' ' ' '"
    [ "nosmb" == "$1" ] && si='' && sc='' && sca='' && scc=''

    exec_replace_tpl '__SAMBA_INSTALL__' "$si"
    exec_replace_tpl '__SAMABA_CONF__' "$sc"
    exec_replace_tpl '__START_SCRIPT_SMB_APPS__' "$sca" "confs/start"
    exec_replace_tpl '__START_SCRIPT_SMB_CONFS__' "$scc" "confs/start"
}

exec_replace_tpl() {
    local f=$3
    [ -z "$f" ] && f='Dockerfile'
    sed -i "s|$1|$2|g" $f
}

exec_set_user() {
    local user=$(echo "$1" | sed 's/-u//' )
    [ ! -z "$user" ] && DEFAULT_USER=$user
}

exec_set_tag() {
    local tag=$(echo "$1" | sed 's/-t//')
    [ ! -z "$tag" ] && DOCKER_TAG=$tag
}

exec_build() {
    grep '__DEFAULT_USER__' --exclude=$SELF_NAME -rl ./* | xargs sed -i "s/__DEFAULT_USER__/$DEFAULT_USER/g"
    docker build -t "$DOCKER_TAG" --rm=true .
}

for arg in "$@"; do
    case $arg in
        "php") exec_php $arg;;
        "php56") exec_php56 $arg;;
        "nosmb") exec_smb $arg;;
        -u*) exec_set_user $arg;;
        -t*) exec_set_tag $arg;;
        *) echo -e $UNKOWN_TPL | sed  's/__ARG__/'$arg'/';;
    esac
done

exec_smb
exec_build
