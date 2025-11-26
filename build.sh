#!/bin/bash
set -e

# ========================
# 配置
# ========================
NGINX_VERSION=1.18.0
OPENSSL_VERSION=1.1.1n   # 1.1.x 是 nginx 1.18 最佳搭配
ZLIB_VERSION=1.3.1
PCRE_VERSION=8.44

PREFIX_DIR=$(pwd)/nginx-arm64
BUILD_DIR=$(pwd)/build

TOOLCHAIN_PATH=/opt/gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu/bin
CROSS=aarch64-none-linux-gnu
CC=${TOOLCHAIN_PATH}/${CROSS}-gcc
CXX=${TOOLCHAIN_PATH}/${CROSS}-g++

export PATH=${TOOLCHAIN_PATH}:$PATH

# ========================
# 准备构建目录
# ========================
prepare_build_dir() {
    rm -rf $PREFIX_DIR $BUILD_DIR
    mkdir -p $PREFIX_DIR $BUILD_DIR
}


# ========================
# 下载依赖
# ========================
prepare_source() {
    cd $BUILD_DIR
    wget -c http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
    wget -c https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
    wget -c https://ftp.exim.org/pub/pcre/pcre-${PCRE_VERSION}.tar.gz
    wget -c https://zlib.net/fossils/zlib-${ZLIB_VERSION}.tar.gz

    tar xzf nginx-${NGINX_VERSION}.tar.gz
    tar xzf openssl-${OPENSSL_VERSION}.tar.gz
    tar xzf pcre-${PCRE_VERSION}.tar.gz
    tar xzf zlib-${ZLIB_VERSION}.tar.gz
}


# ========================
# 配置 nginx
# ========================
configure_nginx() {
    echo "进入 nginx 源码目录并配置..."
    cd $BUILD_DIR/nginx-${NGINX_VERSION}

    # auto/cc/name
    sed -r -i "/ngx_feature_run=yes/ s/.*/\tngx_feature_run=no/g" auto/cc/name
    sed -r -i "/exit 1/ s/.*//1" auto/cc/name

    # auto/types/sizeof
    sed -r -i "/ngx_size=`$NGX_AUTOTEST`/ s/.*/\tngx_size=8/g" auto/types/sizeof
    
    # auto/options
    sed -r -i "/PCRE_CONF_OPT=/ s/.*/PCRE_CONF_OPT=--host=${CROSS}/g" auto/options

    # auto/lib/openssl/make
    printf "%s\n" " && sed -i 's/-m64/ /g' Makefile \\\\" | sed -i '54r /dev/stdin' auto/lib/openssl/make

    ./configure \
        --prefix=${PREFIX_DIR} \
        --with-cc=${CC} \
        --with-cpp=${CXX} \
        --with-cc-opt='-fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2 -O2 -g0' \
        --with-ld-opt='-pie -Wl,-z,relro,-z,now -Wl,-s' \
        --with-http_ssl_module \
        --with-openssl=../openssl-${OPENSSL_VERSION} \
        --with-pcre=../pcre-${PCRE_VERSION} \
        --with-zlib=../zlib-${ZLIB_VERSION} \
        --with-openssl-opt="no-shared no-asm --cross-compile-prefix=${CROSS}-" \
        --without-http_fastcgi_module \
        --without-http_uwsgi_module \
        --without-http_scgi_module \
        --without-http_grpc_module \
        --without-http_empty_gif_module \
        --without-http_memcached_module \
        --without-http_upstream_zone_module

    # objs/ngx_auto_config.h
    HEAD_FILE=`find . -name "ngx_auto_config.h"`

    echo "#ifndef NGX_SYS_NERR" >> ${HEAD_FILE}
    echo "#define NGX_SYS_NERR 132" >> ${HEAD_FILE}
    echo "#endif" >> ${HEAD_FILE}

    echo "#ifndef NGX_HAVE_SYSVSHM" >> ${HEAD_FILE}
    echo "#define NGX_HAVE_SYSVSHM 1" >> ${HEAD_FILE}
    echo "#endif" >> ${HEAD_FILE}
}

# ========================
# 编译 nginx
# ========================
make_nginx() {
    make
    make install
}

prepare_build_dir
prepare_source
configure_nginx
make_nginx
