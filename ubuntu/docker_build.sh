#!/bin/bash
SELF_NAME=$(basename $0)
DEFAULT_USER='tom'
DOCKER_TAG="docker:$(date +"%s%N")"

UNKOWN_TPL=$(cat <<EOF
Unkown argument: __ARG__, script exit.\n
\n
$0 is support args like this:\n
$0 -uuser -ttest
EOF
)

SSH_LOGIN_INFO=$(cat -s <<EOF
# ================================================================ #\\
\\n#                      Welcome to LDNMP                            #\\
\\n#             Created by Tom Chan <viger@mchen.info>               #\\
\\n#                      ---------------                             #\\
\\n# We was installed the software which are: nginx, php, mysql when  #\\
\\n# this image which build, so u don not need install it again.      #\\
\\n# but u must to do somethings at first time.                       #\\
\\n# 1, change ur domain for virtual configures of nginx which in     #\\
\\n# /etc/nginx/sites-available/*.conf                                #\\
\\n# 2, change ur password by this command:                           #\\
\\n# passwd someone                                                   #\\
\\n# 3, clone ur code from server of subversion by the script which   #\\
\\n# named branch.sh on ur home directory, like this:                 #\\
\\n# ./branch.sh <version>                                            #\\
\\n# ./branch.sh 5.5.x                                                #\\
\\n# 4, sync the database from the platform which ip's' 192.168.95.53 #\\
\\n# ./sync_database.sh                                               #\\
\\n# 5, clear this information by this command as root:               #\\
\\n# echo \'\' > /etc/motd                                              #\\
\\n# 6, set password for mysql by this command at first login:        #\\
\\n# mysqladmin -u root -p password PASSWORD                          #\\
\\n# and then u must restart it.                                      #\\
\\n#                                                                  #\\
\\n# default information:                                             #\\
\\n# password for root of mysql: 123qwe!                              #\\
\\n# virtual directories of nginx: /data/vhosts/                      #\\
\\n# data directory of mysql: /data/mysql                             #\\
\\n#                                                                  #\\
\\n# !!!NOTICE!!!                                                     #\\
\\n# don\'t kill process which is tail -f /var/log/starup.log          #\\
\\n#                                                                  #\\
\\n# ================================================================ #
EOF
)

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
    exec_replace_tpl '__SSH_LOGIN_INFO__' "$SSH_LOGIN_INFO"
    grep '__DEFAULT_USER__' --exclude=$SELF_NAME -rl ./* | xargs sed -i "s/__DEFAULT_USER__/$DEFAULT_USER/g"
    docker build -t "$DOCKER_TAG" --rm=true .
}

for arg in "$@"; do
    case $arg in
        -u*) exec_set_user $arg;;
        -t*) exec_set_tag $arg;;
        *) echo -e $UNKOWN_TPL | sed  's/__ARG__/'$arg'/';;
    esac
done

exec_build
