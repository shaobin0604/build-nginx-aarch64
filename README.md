# Nginx ARM64 编译脚本

本项目提供了一个自动化脚本，用于在x86_64平台上交叉编译Nginx 1.18.0，目标平台为ARM64架构。

## 项目特点

- 自动化下载所需依赖源码    
- 配置交叉编译环境
- 应用必要的补丁和修改以确保ARM64平台兼容性
- 优化编译选项，提高安全性和性能
- 简化的编译流程，一键完成从源码到安装的全过程

## 支持的版本

- **Nginx**: 1.18.0
- **OpenSSL**: 1.1.1n (nginx 1.18 最佳搭配版本)
- **ZLIB**: 1.3.1
- **PCRE**: 8.44

## 环境要求

### 硬件要求
- x86_64架构的Linux系统
- 至少1GB内存
- 足够的磁盘空间（建议4GB以上）

### 软件要求
- **交叉编译工具链**: `/opt/gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu/bin`
- **bash**: 用于执行脚本
- **wget**: 用于下载源码包
- **tar**: 用于解压源码包
- **sed**: 用于修改配置文件
- **gcc/g++**: 基础编译环境

## 使用方法

### 1. 准备环境

确保已安装交叉编译工具链并位于指定路径。如果路径不同，可以修改脚本中的`TOOLCHAIN_PATH`变量。

### 2. 执行编译脚本

```bash
cd /home/oem/workspace/build-nginx-1.18
chmod +x build.sh
./build.sh
```

### 3. 查看编译结果

编译完成后，Nginx将安装在以下目录：

```
/home/oem/workspace/build-nginx-1.18/nginx-arm64/
```

主要文件位置：
- **配置文件**: `nginx-arm64/conf/nginx.conf`
- **可执行文件**: `nginx-arm64/sbin/nginx`
- **网页文件**: `nginx-arm64/html/`

## 编译过程详解

脚本执行以下主要步骤：

1. **准备构建目录**
   - 清理旧的构建目录
   - 创建新的构建和安装目录

2. **下载依赖源码**
   - 下载Nginx、OpenSSL、PCRE和ZLIB的源码包
   - 解压所有源码包

3. **配置Nginx**
   - 修改`auto/cc/name`以跳过编译检测
   - 设置`auto/types/sizeof`中的大小为64位
   - 配置PCRE的交叉编译选项
   - 移除OpenSSL编译中的`-m64`选项（ARM64不支持）
   - 配置Nginx，启用SSL模块，禁用不需要的模块
   - 添加必要的头文件定义

4. **编译和安装**
   - 执行编译
   - 安装到指定目录

## 配置说明

### 主要配置变量

在`build.sh`脚本中，您可以修改以下主要配置变量：

- `NGINX_VERSION`: Nginx版本
- `OPENSSL_VERSION`: OpenSSL版本
- `ZLIB_VERSION`: ZLIB版本
- `PCRE_VERSION`: PCRE版本
- `PREFIX_DIR`: 安装目录
- `BUILD_DIR`: 构建目录
- `TOOLCHAIN_PATH`: 交叉编译工具链路径

### Nginx模块配置

脚本默认禁用了以下模块：
- http_fastcgi_module
- http_uwsgi_module
- http_scgi_module
- http_grpc_module
- http_empty_gif_module
- http_memcached_module
- http_upstream_zone_module

如果需要启用某些模块，可以修改`configure_nginx`函数中的`--without-*`选项。

## 注意事项

1. 确保交叉编译工具链已正确安装
2. 编译过程需要网络连接以下载源码包
3. 如果源码包已下载，可以注释掉`prepare_source`函数中的下载部分
4. 编译成功后，生成的二进制文件只能在ARM64平台上运行

## 故障排除

### 常见问题

1. **交叉编译工具链问题**
   - 错误信息: `找不到 aarch64-none-linux-gnu-gcc`
   - 解决方案: 检查`TOOLCHAIN_PATH`变量设置是否正确，确保工具链已安装

2. **网络问题**
   - 错误信息: 下载源码包失败
   - 解决方案: 检查网络连接，或手动下载源码包到`build`目录

3. **编译错误**
   - 错误信息: 与`-m64`选项相关的错误
   - 解决方案: 确保脚本中的修复已正确应用

## 许可证

本项目采用MIT许可证。

## 贡献

欢迎提交问题报告和改进建议。

## 联系方式

如有任何问题，请通过项目托管平台提交issue。