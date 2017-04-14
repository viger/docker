# 创建LNMP环境镜像

使用脚本生成一个nginx + php(可选php5.6.30版本或最新7.x.x) + mysql + samba[可选]的镜像。

--

请使用以下命令行来创建docker镜像
```
chmod a+x ./docker_build.sh && ./docker_build.sh php56 nosmb -tusername -tarch:lnmp
```

创建完镜像后请按此启动一个容器
```
docker run --restart=on-failure -d -i -p 1022:22 -v /root_system/path/:/data/ --name archlnmp arch:lnmp /bin/bash
```
**/root_system/path/**为宿主机上指定的数据目录，容器在启动时会自动在此目录下创建mysdl目录，并在初次创建目录时生成mysql初始数据。

其次还会创建一个vhosts目录，nginx默认目录指向这里。

创建的镜像默认信息
  + 账户：viger（如果在./docker_build.sh后使用参数-uxxx,那么你的账户是xxx）
  + 密码：123qwe!

如果选择了samba作为默认服务，那么请登陆到docker环境后新增一个用户
```
smbpasswd -a 创建镜像时输入的账户
```

请勿结束容器内进程**tail -f /var/log/startup.log**,会导致**容器重启**.

祝你使用愉快
