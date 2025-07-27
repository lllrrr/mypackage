# luci-app-vnt
<p align="center">
	<img alt="GitHub Created At" src="https://img.shields.io/github/created-at/lmq8267/luci-app-vnt?logo=github&label=%E5%88%9B%E5%BB%BA%E6%97%A5%E6%9C%9F">
<a href="https://hits.seeyoufarm.com"><img src="https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Flmq8267%2Fluci-app-vnt&count_bg=%2395C10D&title_bg=%23555555&icon=github.svg&icon_color=%238DC409&title=%E8%AE%BF%E9%97%AE%E6%95%B0&edge_flat=false"/></a>
<a href="https://github.com/lmq8267/luci-app-vnt/releases"><img src="https://img.shields.io/github/downloads/lmq8267/luci-app-vnt/total?logo=github&label=%E4%B8%8B%E8%BD%BD%E9%87%8F"/></a>
<a href="https://github.com/lmq8267/luci-app-vnt/graphs/contributors"><img src="https://img.shields.io/github/contributors-anon/lmq8267/luci-app-vnt?logo=github&label=%E8%B4%A1%E7%8C%AE%E8%80%85"/></a>
<a href="https://github.com/lmq8267/luci-app-vnt/releases/"><img src="https://img.shields.io/github/release/lmq8267/luci-app-vnt?logo=github&label=%E6%9C%80%E6%96%B0%E7%89%88%E6%9C%AC"/></a>
<a href="https://github.com/lmq8267/luci-app-vnt/issues"><img src="https://img.shields.io/github/issues-raw/lmq8267/luci-app-vnt?logo=github&label=%E9%97%AE%E9%A2%98"/></a>
<a href="https://github.com/lmq8267/luci-app-vnt/discussions"><img src="https://img.shields.io/github/discussions/lmq8267/luci-app-vnt?logo=github&label=%E8%AE%A8%E8%AE%BA"/></a>
<a href="GitHub repo size"><img src="https://img.shields.io/github/repo-size/lmq8267/luci-app-vnt?logo=github&label=%E4%BB%93%E5%BA%93%E5%A4%A7%E5%B0%8F"/></a>
<a href="https://github.com/lmq8267/luci-app-vnt/actions?query=workflow%3ABuild"><img src="https://img.shields.io/github/actions/workflow/status/lmq8267/luci-app-vnt/CI.yml?branch=main&logo=github&label=%E6%9E%84%E5%BB%BA%E7%8A%B6%E6%80%81" alt="Build status"/></a>
</p>

项目地址：https://github.com/vnt-dev/vnt

非专业，编写自用，有大佬完善一下也好，自1.2.9版本起可以多开了，要是有大佬重写一个可以支持多开、多配置快速切换 就好啦，多配置快速切换

需要依赖komd-tun 手动去系统自带的软件包里先安装好吧

新版OpenWrt的APK包管理器安装后编译的APK包，由于签名证书不一致了，可能需要使用跳过证书验证的命令才能安装
```
apk add --allow-untrusted luci-app-vnt.apk
```

## 使用方法

- 只编译IPK或APK安装包的话，参考.github/workflows里的[CI.yml](.github/workflows/CI.yml) 可以直接在GitHub云编译。
- 将luci-app-lucky添加至 LEDE/OpenWRT 源码的方法。

### 下载源码方法:

 ```Brach
 
    # 下载源码
	
    git clone https://github.com/lmq8267/luci-app-vnt.git package/vnt
    make menuconfig
	
 ``` 
### 配置菜单

 ```Brach
    make menuconfig
	# 找到 LuCI -> Applications, 选择 luci-app-vnt, 保存后退出。
 ``` 
 
### 编译

 ```Brach 
    # 编译固件
    make package/vnt/luci-app-vnt/compile V=s
    #客户端程序
    make package/vnt/vnt/compile V=s
    #服务端程序
    make package/vnt/vnts/compile V=s
 ```

##

> 如果 状态-系统日志里 出现下图日志内容可以使用以下命令解决

<p><img width="500" alt="" src="./Image/xml.png"></p>

```
sed -i 's/util/xml/g' /usr/lib/lua/luci/model/cbi/vnt.lua
```

##

### UI预览 ###
![](./Image/主界面23-11-07.png)
![](./Image/服务端23-11-07.png)
![](./Image/高级设置23-11-07.png)
![](./Image/上传程序23-11-07.png)
![](./Image/服务端私钥.png)
![](./Image/客户端日志.png)
![](./Image/服务客户端日志.png)
