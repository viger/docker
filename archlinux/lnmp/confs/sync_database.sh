#!/bin/bash
#
#
[[ ! -z "$(which mysql | grep "not found")" ]] && \
    echo "This server has not mysql or $(whoami) has not enough power." && exit

[[ ! -z "$(which mysqldump | grep "not found")" ]] && \
    echo "This server has not mysqldump or $(whoami) has not enough power." && exit

MAX_TABLE_SIZE=20.00 # 20M
MAX_TABLE_NUM=10000 # 10000 lines
BACKUP_LOCAL_PATH='./backup_sql/'

MYSQL_BIN=`which mysql`
MYSQLDUMP_BIN=`which mysqldump`
GZIP_BIN=`which gzip`
ZCAT_BIN=`which zcat`

MYSQL_SOURCE_HOST='192.168.95.55'
MYSQL_SOURCE_PORT='3306'
MYSQL_SOURCE_USERNAME='nn_cms'
MYSQL_SOURCE_PASSWD='nn_cms1234'
MYSQL_SOURCE_DBNAMES=(nn_aaa nn_pay nn_cms_new)

MYSQL_TARGET_HOST='127.0.0.1'
MYSQL_TARGET_PORT='3306'
MYSQL_TARGET_USERNAME='nn_cms'
MYSQL_TARGET_PASSWD='starc0r'
MYSQL_TARGET_DBNAMES=(nn_aaa nn_pay nn_cms)

now() {
    echo "[$(date +"%Y-%m-%d %T")] "
}

echo_ok() {
    echo -e "$(now)[\e[32m\e[1m SUCCESSED \e[21m\e[0m] $1"
}

echo_error() {
    echo -e "$(now)[\e[31m\e[1m   FAILD   \e[21m\e[0m] $1"
}

echo_info() {
    echo -e "$(now)[\e[34m\e[1m   INFO    \e[21m\e[0m] $1"
}

execute_sql_on_source() {
    local res=$(echo "$1" | $MYSQL_BIN \
                        -h$MYSQL_SOURCE_HOST \
                        -u$MYSQL_SOURCE_USERNAME \
                        -p$MYSQL_SOURCE_PASSWD \
                        --port=$MYSQL_SOURCE_PORT);
    echo $res;
}

execute_sql_on_target() {
    local res=$(echo "$1" | $MYSQL_BIN \
                        -h$MYSQL_TARGET_HOST \
                        -u$MYSQL_TARGET_USERNAME \
                        -p$MYSQL_TARGET_PASSWD \
                        --port=$MYSQL_TARGET_PORT);
    echo $res;
}

get_table_size() {
    local table=$1 && local db_name=$2;
    [[ -z "$table" || -z "$db_name" ]] && echo 0 && exit;

    local count_sql="SELECT round(((data_length + index_length) / 1024 / 1024), 2) \`table_size\`
                    FROM information_schema.TABLES WHERE table_schema = '$db_name'
                    AND table_name = '$table';";
    local count_res=$(execute_sql_on_source "$count_sql");
    [ -z "$count_res" ] && echo 0 && exit;
    echo $count_res | awk '{print $2}';
}

get_table_names_for_source() {
    local db_name=$1;
    [[ -z "$db_name" ]] && echo "" && exit;

    local tables_sql="SHOW TABLES FROM $db_name;"
    local table_res=$(execute_sql_on_source "$tables_sql");
    echo $table_res;
}

backup_table() {
    local table_name=$1 && local source_db_name=$2 && local table_size=$(get_table_size $1 $2) && local backup_path="${3}${table_name}.sql.tar";
    echo_info "backuping $table_name(${table_size}M)...";
    local cpr=$(awk 'BEGIN{print '$MAX_TABLE_SIZE' < '$table_size'}');
    if [[ "$cpr" -eq 1 ]]; then
        echo_info "backup $table_name limit $MAX_TABLE_NUM...";
        $MYSQLDUMP_BIN --single-transaction -h$MYSQL_SOURCE_HOST \
            -u$MYSQL_SOURCE_USERNAME \
            -p$MYSQL_SOURCE_PASSWD \
            --port=$MYSQL_SOURCE_PORT \
            $source_db_name $table_name --where="1 limit $MAX_TABLE_NUM" | $GZIP_BIN -9 > $backup_path;
    else
         $MYSQLDUMP_BIN --single-transaction -h$MYSQL_SOURCE_HOST \
            -u$MYSQL_SOURCE_USERNAME \
            -p$MYSQL_SOURCE_PASSWD \
            --port=$MYSQL_SOURCE_PORT \
            $source_db_name $table_name | $GZIP_BIN -9 > $backup_path;
    fi
    echo_ok "backuped $table_name into $backup_path.";
}

restore_table() {
    local table_name=$1 && local target_db_name=$2 && local backup_path="${3}${table_name}.sql.tar";
    echo_info "restoreing $table_name...";
    echo "DROP TABLE IF EXISTS \`$table_name\`;" | $MYSQL_BIN -h$MYSQL_TARGET_HOST\
          -u$MYSQL_TARGET_USERNAME\
          -p$MYSQL_TARGET_PASSWD\
          --port=$MYSQL_TARGET_PORT\
          $target_db_name ;

    $ZCAT_BIN $backup_path | $MYSQL_BIN -h$MYSQL_TARGET_HOST\
          -u$MYSQL_TARGET_USERNAME\
          -p$MYSQL_TARGET_PASSWD\
          --port=$MYSQL_TARGET_PORT\
          $target_db_name ;
    echo_ok "restored $table_name.";
}

backup_database() {
    [ ! -d "$BACKUP_LOCAL_PATH" ] && mkdir "$BACKUP_LOCAL_PATH";
    local db_name=$1 && local backup_path="${BACKUP_LOCAL_PATH}${db_name}_$(date +"%Y_%m_%d").sql.tar";
    echo_info "backuping the whole database: $db_name...";
    $MYSQLDUMP_BIN --single-transaction -h$MYSQL_TARGET_HOST \
        -u$MYSQL_TARGET_USERNAME \
        -p$MYSQL_TARGET_PASSWD \
        --port=$MYSQL_TARGET_PORT \
        $db_name | $GZIP_BIN -9 > $backup_path;
    echo_ok "backuped $db_name into $backup_path.";
}

reset_backup_path() {
    path="/tmp/$1/"
    [ -d "$path" ] && rm -rf "$path";
    mkdir -p "$path";
    echo $path;
}

sync_database() {
    local source_db_name=$1 && local target_db_name=$2 && local table_size=0 && local backup_path=$(reset_backup_path $source_db_name);

    execute_sql_on_target "CREATE DATABASE IF NOT EXISTS $target_db_name;"
    backup_database $target_db_name;

    local table_names=($(get_table_names_for_source $source_db_name));
    for table_name in "${table_names[@]:1}"; do
        # [ "$table_name" != "nns_user_partner_relation" ] && continue;
        backup_table $table_name $source_db_name $backup_path;
        restore_table $table_name $target_db_name $backup_path;
    done
}

run() {
    local idx=0 && local db_name='' && local target_db_name='';
    echo "============================================== start ==============================================";
    echo_info "will be syncing the database: ${MYSQL_SOURCE_DBNAMES[*]}.";
    sleep 5;
    for db_name in "${MYSQL_SOURCE_DBNAMES[@]}"; do
        target_db_name="${MYSQL_TARGET_DBNAMES[$idx]}" && [ -z "$target_db_name" ] && target_db_name=$db_name;
        echo_info "begining sync $db_name($MYSQL_SOURCE_HOST) into $target_db_name($MYSQL_TARGET_HOST)...";
        sleep 5;
        sync_database $db_name $target_db_name;
        idx=$(expr $idx + 1);
        echo_ok "begined sync $db_name.";
    done
    echo_ok "all done.";
    echo_info "Thanks, plz tell me or send a mail to \e[5mviger[at]mchen.info\e[0m if u have any question.";
    echo "==============================================  end  ==============================================";
}

run
