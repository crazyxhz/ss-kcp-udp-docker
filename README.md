# shadowsocks kcptun udp2raw 一键运行docker镜像

## 思路
[kcptun](https://github.com/xtaci/kcptun)用于加速[ss](https://github.com/shadowsocks/shadowsocks-libev)流量，[udp2raw](https://github.com/wangyu-/udp2raw-tunnel)用于伪装kcptun的大量udp包，防止udp流量过大被运营商QoS。即三层嵌套，ss的tcp流量由kcp客户端转为kcp加速的udp流，再经过udp2raw伪装为tcp包，绕过运营商udp QoS防火墙，到达vps，然后服务器端反向udp2raw->kcptun->ss-server，参考下图：
![](https://github.com/wangyu-/udp2raw-tunnel/raw/master/doc/kcptun_step_by_step/Capture00.PNG)

## 具体实现
在[Docker Alphine Linux](https://hub.docker.com/_/alpine/)环境下把 shadowsocks-libev，kcptun，udp2raw及其相关运行时依赖打包在了一个镜像中：[crazyxhz/ss](https://hub.docker.com/r/crazyxhz/ss/)，通过配置环境变量，可以实现容器运行在客户端模式，还是服务器端模式，ss、kcptun、udp2raw的所有参数也通过环境变量暴露出来可以自己配置调优。如果嫌麻烦的话也可以使用默认参数，只需要设置一下VPS IP就可以一键运行了。

客户端模式内置了一个pac server，可以把crazyxhz/ss暴露出来的socks5代理封装为可以动态添加host的[pac代理](https://en.wikipedia.org/wiki/Proxy_auto-config)。直接修改本地的pac文件或者通过网页版的管理后台，都可以实现动态添加host

## 使用说明
### 安装环境
首先VPS和客户端都需要安装Docker：

各个平台的安装参考[官方文档](https://docs.docker.com/install/linux/docker-ce/centos/)

Linux环境下，docker-compose需要单独安装，[参考文档](https://docs.docker.com/compose/install/#install-compose)
### 拉取镜像
在服务器环境拉取镜像 `docker pull crazyxhz/ss`

在客户端拉取ss镜像和pac server镜像：`docker pull crazyxhz/ss && docker pull crazyxhz/pac`
### 配置
#### 服务器端
把`docker-compose.server.yml`拷贝到VPS，重命名为`docker-compose.yml`，建议修改一下里面的`PASSWORD`环境变量。保存之后，运行**docker-compose up -d** 即可
#### 客户端
把`docker-compose.client.yml`拷贝到本机或者局域网内机器，重命名为`docker-compose.yml`，修改里面的`PASSWORD`,`SERVER_IP`环境变量，保证和VPS端同步，其他参数保持默认即可。

和`docker-compose.yml`同级，把`pac`文件夹拷贝过来，里面的paclist文件即是要走代理的域名，可以手动修改该文件（一个域名一行），pac server 会自动监听文件的变化更新。或者也通过默认的 `http://<客户端ip>:1986/`访问Web版的管理后台，添加域名

做完以上操作后，在docker-compose.yml所在文件夹执行**docker-compose up -d**
这样我们就得到了一个可以自动配置上网的地址：
> #**http://<客户端ip>:1986/pac**

把该地址填入浏览器或者Wi-Fi的自动代理配置即可

### pac host 管理

管理web地址![](https://wx4.sinaimg.cn/large/9b7f515dly1fpdk8ni0jrj21cc0nujva.jpg)
> http://<客户端ip>:1986/

可以添加删除host，pac地址自动刷新，浏览器可能有更新延迟

## 限制
由于docker for Mac 不支持rawsocket，占不支持Mac客户端，建议客户端部署在Linux内网环境，或者Linux虚拟机内