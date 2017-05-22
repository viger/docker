# docker 镜像

欢迎使用我的Docker镜像,这些都是开箱即用的一些基础镜像。

## 目前支持系统:
|序号|系统|文件|版本|创建日期|
|-|-|-|-|-|
|1|archlinux|archlinux/archlinux.2017.04.07.7z||2017-04-07|
|2|ubuntu|daocloud.io/library/ubuntu:zesty-20170411||2017-05-15|
|3|alpine:proxy|alpine:latest||2017-05-15|

## 能通过脚本生成的镜像
|序号|脚本|系统|版本|功能|创建日期|
|-|-|-|-|-|-|
|1|archlinux/mkimage-arch.sh|archlinux||生成一个archlinux的基础镜像。|2017-04-07|
|2|archlinux/lnmp/docker_build.sh|archlinux||使用脚本生成一个nginx + php(可选php5.6.30版本或最新7.x.x) + mysql + samba[可选]的镜像。|2017-04-14|
|3|ubuntu/docker_build.sh|ubuntu||使用脚本生成一个nginx + php(可选php5.6.30版本) + mysql 的镜像。|2017-05-15|

如果在使用中有问题，请[联系我](mailto:viger@mchen.info).
