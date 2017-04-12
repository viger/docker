#!/bin/bash
#
# subversion本地分支管理脚本
# 自动根据用户输入的分支号切换不同的版本文件目录，无缝切换nginx映射目录
# 到达能够简化在不同版本间切换开发的时间成本。
# 如果用户输入的分支在本地不存在，则自动从远程版本库拉取指定的分支，并将配置文件复制到新分支目录中。
# 自动在目录内生成标明当前目录分支所属版本号。
#
# @command:
#   branch.sh [version_number]
# @example:
#   branch.sh 5.1.x
# 输入命令后会从远程版本服务器上拉取5.1.x版本的文件，并在/home/vhosts/bugfix_devp/svn_branches/目录下建立本地仓库
# 请在/home/vhosts/bugfix_devp/svn_branches/下创建configures目录，并将bugfix_devp对应的配置文件按目录方式复制一份到此。
# nginx配置需将虚拟目录的主目录指向/home/vhosts/bugfix_devp/public
# 添加自定义命令:
# bash: echo "alias bch=~/branch.sh " >> ~/.bashrc && source ~/.bashrc
# zsh: echo "alias bch=~/branch.sh " >> ~/.zshrc && source ~/.zshrc
#
# 本脚本只适应linux,unix系统。
# 新机器，请按需配置目录及Subversion相关信息。
#
# @issuses:
#
#
# @bugs:
#
#
# @author: tom.chen <viger@mchen.info>
# @version: 0.1.12 <2017-01-15 19:05:21>
# @create time: 2016-11-17 10:39:10
# @modify time: 2017-01-15 19:05:21
####

ROOT_PATH='/data/vhosts/bugfix_devp/'
PUBLIC_PATH="${ROOT_PATH}public"
SVN_PATH="${ROOT_PATH}svn_branches/"
SVN_URL='https://svn.jetlive.net:8443/svn/%E6%A0%87%E5%87%86%E4%BA%A7%E5%93%81_cms%E4%BA%A7%E5%93%81%E5%8F%91%E5%B8%83/{{SVN_BRANCH}}/bugfix_devp'
SVN_USERNAME=''
SVN_PASSWORD=''
SVN_BIN=`which svn`
MSG_BRANCH_NOT_EXISTS="Can not found the branch: {{BRANCH_NAME}}"
MSG_CHECKOUT_NOTICE="ar u want to checkout this branch from subversion server?[Y/n] "
DONT_CHANGE=0
TMP_CHECKOUT_LOG=""
SHOW_CHECKOUT_POINT_NUM=100

check_directories() {
    echo_info "check directoirs..."
    [[ ! -d "$ROOT_PATH" ]] && echo_error "We can not found the path of webroot: $ROOT_PATH, exit." && exit 1
    [[ ! -d "$SVN_PATH" ]] && echo_error "We can not found the path of subversion resprioty : $SVN_PATH, exit." \
    && exit 1
    [[ ! -d "$SVN_PATH/configures" ]] \
    && echo_error "We can not found the path of configures : $SVN_PATH/configures, exit." && exit 1
    echo_ok "check directoirs ok."
}

remove_public() {
    [[ $DONT_CHANGE -eq 0 ]] && [[ -d "$PUBLIC_PATH" ]] && rm -f "$PUBLIC_PATH" && echo_ok "deleted $PUBLIC_PATH."
}

create_public() {
    local branch_name=$1
    echo_info "create the tmp link of $branch_name..."
    [[ -d "${PUBLIC_PATH}_tmp" ]] && rm -f "${PUBLIC_PATH}_tmp"
    [[ -d "${SVN_PATH}${branch_name}" ]] && ln -s "${SVN_PATH}${branch_name}" "${PUBLIC_PATH}_tmp" \
    && echo_ok "create sysmbol link from ${SVN_PATH}${branch_name} to ${PUBLIC_PATH}_tmp " \
    && rm -f "${SVN_PATH}${branch_name}/${branch_name}.svn_branch" && echo "" > "${SVN_PATH}${branch_name}/${branch_name}.svn_branch" \
    && return

    [[ "$2" == "checkout" ]] && echo_error "can not checkout $branch_name." && DONT_CHANGE=1 && return
    local branch_info="$(echo $MSG_BRANCH_NOT_EXISTS | sed "s/{{BRANCH_NAME}}/${branch_name}/")" \
    && read -p "$(echo_info "${branch_info}, ${MSG_CHECKOUT_NOTICE}")" checkout_status \
    && [[ -z "$checkout_status" ]] && checkout_status="Y"
    [[ "$checkout_status" == "Y" || "$checkout_status" == "y" ]] && checkout_branch $branch_name \
    && create_public $branch_name "checkout"
}

mv_public() {
     [[ $DONT_CHANGE -eq 0 ]] && [[ -d "${PUBLIC_PATH}_tmp" ]] && mv "${PUBLIC_PATH}_tmp" "$PUBLIC_PATH" \
     && echo_ok "mv ${PUBLIC_PATH}_tmp to $PUBLIC_PATH."
}

checkout_branch() {
    local branch_name=$1
    local show_log_status="N"
    TMP_CHECKOUT_LOG="/tmp/checkout_${branch_name}_$(date +"%Y%m%d%H%M%S").log"
    [[ -d "${SVN_PATH}${branch_name}" ]] && [[ -d "${SVN_PATH}${branch_name}/.svn" ]] \
    && echo_error "The branch has exists." && return

    echo_info "checkout $branch_name form subversion server."
    local svn_url=`echo $SVN_URL | sed "s/{{SVN_BRANCH}}/$(echo $branch_name | tr '[:lower:]' '[:upper:]')/"` \
    && $SVN_BIN checkout $(ganrate_svn_auth_info) $svn_url "${SVN_PATH}${branch_name}" >$TMP_CHECKOUT_LOG 2>&1 &

    show_checkout_info

    local checkout_result=$(grep -E "^Checked out revision [0-9]+\.$" $TMP_CHECKOUT_LOG)
    [[ -z $checkout_result ]] && echo_error "Checked faild, show log: " && cat $TMP_CHECKOUT_LOG && exit
    read -p "$(echo_info "$checkout_result Ar u want to show log [y/N] ")" show_log_status \
        && [[ "$show_log_status" = "y" || "$show_log_status" = "Y" ]] && cat $TMP_CHECKOUT_LOG

    [[ -d "${SVN_PATH}${branch_name}" ]] && [[ -d "${SVN_PATH}${branch_name}/.svn" ]] && copy_configure $branch_name
    echo "" > "${SVN_PATH}${branch_name}/${branch_name}.svn_branch"
    # cd "${SVN_PATH}${branch_name}" && $SVN_BIN propset svn:ignore "${branch_name}.svn_branch" . \
    # && svn ci -m "ignore ${branch_name}.svn_branch"
    echo_ok "checkout $branch_name is end."
}

show_checkout_info()
{
    sleep 1
    local checkout_num=0
    local checkout_count=0
    tail -f $TMP_CHECKOUT_LOG 2>&1 | while read line; do
        local status=$(echo $line | grep -E "^A.")
        [[ -z "$status" ]] && echo "" && echo_info "checkouted $checkout_count files or directoirs." \
        && pkill -9 -P $$ tail 2>&1 > /dev/null && return
        checkout_num=$( expr $checkout_num + 1 )
        checkout_count=$( expr $checkout_count + 1 )
        [[ $checkout_num -eq $SHOW_CHECKOUT_POINT_NUM ]] && echo -n -e "\e[34m\e[1m.\e[21m\e[0m" && checkout_num=0
    done
}

copy_configure() {
    local branch_name=$1
    [[ ! -d "${SVN_PATH}${branch_name}" ]] || [[ ! -d "${SVN_PATH}${branch_name}/.svn" ]] \
    && echo_error "The branch has not exists." && DONT_CHANGE=1 && return

    [[ ! -d "${SVN_PATH}configures" ]] || [[ $(ls -lR|grep "^-"|wc -l) -eq 0 ]] \
    && echo_error "The configures has not exists." && return

    echo_info "copy configures to ${SVN_PATH}${branch_name}..."
    cp -Rn ${SVN_PATH}configures/* ${SVN_PATH}${branch_name}/.
    echo_ok "copy configures to ${SVN_PATH}${branch_name}, ok."
}

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

ganrate_svn_auth_info() {
    auth_info=''
    [[ ! -z "$SVN_USERNAME" ]] && auth_info=" --username $SVN_USERNAME"
    [[ ! -z "$SVN_PASSWORD" ]] && auth_info="$auth_info --password $SVN_PASSWORD"
    echo "$auth_info --no-auth-cache --non-interactive --trust-server-cert "
}

echo "============================================== start =============================================="
check_directories
create_public $1
remove_public
mv_public
echo_info "Thanks, plz tell me or send a mail to \e[5mviger[at]mchen.info\e[0m if u have any question."
echo "==============================================  end  =============================================="
