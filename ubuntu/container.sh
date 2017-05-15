#!/bin/bash

CONTAINER_NAME='tom'
CONTAINER_USER='tom'
CONTAINER_IMG_NAME='ubuntu:lnmp'
CONTAINER_PORTS=''
CONTAINER_VOLUMN_IDX=0
CONTAINER_VOLUMN_PATH='/data/docker/volumes/'
CONTAINER_VOLUMN_CURRENT_PATH=''
CONTAINER_VOLUMN_IDX_PATH="${CONTAINER_VOLUMN_PATH}.idx"

echo_info() {
	[ ! -z "$1" ] && echo "[$(date +"%Y-%m-%d %T")] $1"
}

echo_split() {
	echo_info "------------------------------------------------------------------------------------"
	[ "1" == "$1" ] && echo 1
}

exec_set_config() {
    local c_name=''
    local c_user=''
    local c_img_name=''
    local entried='1'
    read -p "[$(date +"%Y-%m-%d %T")] please entry a name of container[$CONTAINER_NAME]:" c_name
    [ ! -z "$c_name" ] && CONTAINER_NAME=$c_name

    read -p "[$(date +"%Y-%m-%d %T")] please entry a user name of container[$CONTAINER_USER]:" c_user
    [ ! -z "$c_user" ] && CONTAINER_USER=$c_user

    read -p "[$(date +"%Y-%m-%d %T")] please entry a img name which used by container[$CONTAINER_IMG_NAME]:" c_img_name
    [ ! -z "$c_img_name" ] && CONTAINER_IMG_NAME=$c_img_name

    while [[ ! -z "$entried" ]]; do
        read -p "[$(date +"%Y-%m-%d %T")] please entry a port realtion[13306:3306]:" entried
        [ ! -z "$entried" ] && CONTAINER_PORTS="${CONTAINER_PORTS} $entried"
    done

    [ ! -z "$CONTAINER_PORTS" ] && CONTAINER_PORTS=($CONTAINER_PORTS)
}

exist_container() {
    local status=0

    [ ! -z "$(docker ps | grep $CONTAINER_NAME | grep -v grep)" ] && status=1
    [ 0 -eq $status ] && [ ! -z "$(docker ps -a -q | grep $CONTAINER_NAME | grep -v grep)" ] && status=2

    echo $status
}

exec_create() {
    exec_set_config
    local st=$(exist_container)
    [[ 1 == $st ]] && echo_info "The container is exists and running." && return
    [[ 2 == $st ]] && {
        local cc='n'
        read -p  "[$(date +"%Y-%m-%d %T")] The container exists, ar u want run it[y/N]?" cc
        [ "n" == cc ] && return

        echo_info "The container $CONTAINER_NAME starting."
        docker start $(get_container_id_by_name)
        echo_info "The container $CONTAINER_NAME started."
    } && return

    echo_info "creating the container which named $CONTAINER_NAME.."
    local run_cmd="docker run -d -i --restart=on-failure"
    for port in "${CONTAINER_PORTS[@]}"; do
        run_cmd="$run_cmd -p $port"
    done

    CONTAINER_VOLUMN_IDX=$(get_container_volumn_path_idx)
    CONTAINER_VOLUMN_CURRENT_PATH=$(get_container_volumn_path $CONTAINER_VOLUMN_IDX)
    run_cmd="$run_cmd -v $CONTAINER_VOLUMN_CURRENT_PATH:/data/"
    [ ! -z "$CONTAINER_NAME" ] && run_cmd="$run_cmd --name=$CONTAINER_NAME"
    [ ! -z "$CONTAINER_IMG_NAME" ] && run_cmd="$run_cmd $CONTAINER_IMG_NAME"
    run_cmd="$run_cmd /bin/bash"

    local run_result=`$run_cmd`
    echo_info $run_result
    echo_info "created the container which named $CONTAINER_NAME."

    change_user

    add_smb
}

add_smb() {
    local user_info=$(cat /etc/passwd | grep $CONTAINER_USER)
    local volume_idx=$(get_container_volumn_path_idx)
    local uid=$(expr $volume_idx + 600)

    if [ -z "$user_info" ]; then
        useradd -M -N -u $uid -g 100 -s /sbin/nologin  $CONTAINER_USER
        chown -R $uid:100 $CONTAINER_VOLUMN_CURRENT_PATH
    fi

    smbpasswd -a $CONTAINER_USER

    local smb_conf=$(cat <<EOF
\n[${CONTAINER_USER}]
\n\tcomment = ${CONTAINER_USER} directory
\n   path = ${CONTAINER_VOLUMN_CURRENT_PATH}/vhosts/
\n   valid users = ${CONTAINER_USER}
\n   public = no
\n   writable = yes
\n   browseable = yes
\n   create mask = 0755
\n   printable = no

EOF
)

    echo -e $smb_conf >> /etc/samba/smb.conf;

    /etc/init.d/nmb restart
    /etc/init.d/smb restart
}

change_user() {
    if [[ "$CONTAINER_USER" != "tom" ]]; then
        echo_info "change the container's user name to $CONTAINER_USER which named $CONTAINER_NAME."
        local volume_idx=$(get_container_volumn_path_idx)
        local uid=$(expr $volume_idx + 600)
        local change_user_cmd="mv /home/tom /home/$CONTAINER_USER"
        change_user_cmd="$change_user_cmd && sed -i 's/tom/$CONTAINER_USER/g' /etc/sudoers"
        if [ $uid -gt 600 ]; then
            change_user_cmd="$change_user_cmd && sed -i 's/1000/$uid/' /etc/passwd"
            change_user_cmd="$change_user_cmd && sed -i 's/1000/100/' /etc/passwd"
            change_user_cmd="$change_user_cmd && chown -R $uid:100 /home/$CONTAINER_USER"
            change_user_cmd="$change_user_cmd && chown -R $uid:100 /data/vhosts"
        fi

        change_user_cmd="$change_user_cmd && usermod -l $CONTAINER_USER -d /home/$CONTAINER_USER -m tom"
        local new_container_id=$(get_container_id_by_name)
        if [ -z "$new_container_id" ]; then
            echo_info "the container which named $CONTAINER_NAME not runing."
            exit;
        fi

        docker exec -it $(get_container_id_by_name) bash -c "$change_user_cmd"
        echo_info "changed."
    fi
}

exec_change_user() {
    [[ -z "$1" || -z "$2" ]] && help_info && return

    CONTAINER_NAME=$1
    CONTAINER_USER=$2

    change_user
}

get_container_volumn_path_idx() {
    if [ -f "$CONTAINER_VOLUMN_IDX_PATH" ]; then
        local idx=$(cat "$CONTAINER_VOLUMN_IDX_PATH")
        [ -z "$idx" ] && idx=0
        echo $(expr $idx + 0)
    else
        echo 0
    fi
}

get_container_volumn_path() {
    local except_idx=$1
    [ -z "$except_idx" ] && except_idx = 0
    local path_idx=$(expr $except_idx + 1)
    local volumn_path="${CONTAINER_VOLUMN_PATH}volume${path_idx}"
    if [ ! -d "$volumn_path" ]; then
        mkdir -p $volumn_path
        echo $path_idx > "$CONTAINER_VOLUMN_IDX_PATH"
        echo $volumn_path
    else
        echo $(get_container_volumn_path ${path_idx})
    fi
}

get_container_id_by_name() {
    docker ps -a | grep $CONTAINER_NAME | grep -v grep | awk '{print $1}'
}

exec_run() {
    [ -z "$1" ] && help_info && return

    CONTAINER_NAME=$1
    case $(exist_container) in
        0)
            local cc='n'
            read -p  "[$(date +"%Y-%m-%d %T")] The container not exists, ar u want create it[y/N]?" cc
            [ "n" == cc ] && return
        ;;
        1)
            echo_info "The container $CONTAINER_NAME was runing."
            return
        ;;
        2)
            echo_info "The container $CONTAINER_NAME starting."
            docker start $(get_container_id_by_name)
            echo_info "The container $CONTAINER_NAME started."
        ;;
    esac
}

exec_delete() {
    [ -z "$1" ] && help_info && return
    CONTAINER_NAME=$1
    local delete_all=$2

    local container_id=$(get_container_id_by_name)
    [ -z "$container_id" ] && echo_info "can not find container which named $CONTAINER_NAME" && return
    [ ! -z "$delete_all" ] && local volume=$(docker inspect -f '{{index .Volumes "/data"}}' $CONTAINER_NAME)
    echo_info "stoping container which named $CONTAINER_NAME."
    docker stop $container_id
    echo_info "stoped container which named $CONTAINER_NAME."
    echo_info "deleting container which named $CONTAINER_NAME."
    docker rm $container_id

    [ ! -z "$delete_all" ] && [ ! -z "$volume" ] && rm -rf $volume
    echo_info "deleted container which named $CONTAINER_NAME."
}

help_info() {
    cat <<EOF
$0 command [args]

commands:
create|c                                        create a new container.
delete                                          delete a exists container.
delete_all                                      delete a exists container & volume.
changeuser|cu container_name new_user_name      change user name for container.
run|r [container_name]                          run a container.

EOF
}

case $1 in
    create|c) exec_create ;;
    run|r) exec_run $2;;
    changeuser|cu) exec_change_user $2 $3;;
    delete) exec_delete $2;;
    delete_all) exec_delete $2 1;;
    *) help_info ;;
esac
