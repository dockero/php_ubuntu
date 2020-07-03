FROM ubuntu:18.04

LABEL maintainer="codinghuang"

RUN  sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list
RUN apt-get update

# install dev libraries
RUN apt-get -y install \
        libcurl4-openssl-dev \
        libxml2-dev \
        libsqlite3-dev \
        libssl-dev

# install pressure test tools
RUN apt-get -y install \
        apache2-utils

# install build tools
RUN apt-get -y install \
        build-essential

# install other tools
RUN apt-get -y install \
        wget \
        vim \
        help2man \
        nmap \
        net-tools \
        valgrind \
        gettext \
        git \
        curl \
        openssl

RUN apt-get -y install \
        cmake

# install test tools
RUN wget https://github.com/google/googletest/archive/release-1.10.0.tar.gz \
        && tar xf release-1.10.0.tar.gz \
        && cd googletest-release-1.10.0 \
        && cmake -DBUILD_SHARED_LIBS=ON . \
        && make > /dev/null \
        && make install > /dev/null

# install git 2
RUN apt-get -y remove git*
RUN cd /tmp \
        && wget https://www.kernel.org/pub/software/scm/git/git-2.22.2.tar.gz \
        && tar xzf git-2.22.2.tar.gz \
        && cd git-2.22.2 \
        && ./configure --with-openssl=/usr/local/openssl \
        && make > /dev/null \
        && make install > /dev/null

# install debug tools
RUN apt-get -y install libncurses5-dev texinfo libreadline6-dev  automake flex
RUN apt-get -y install gdb
RUN cd /root \
        && wget https://github.com/cgdb/cgdb/archive/v0.7.1.tar.gz -O cgdb-0.7.1.tar.gz \
        && tar xvfz cgdb-0.7.1.tar.gz \
        && cd cgdb-0.7.1 \
        && ./autogen.sh \
        && ./configure \
        && make > /dev/null \
        && make install > /dev/null \
        && cd /root \
        && rm -r cgdb-0.7.1.tar.gz cgdb-0.7.1


# install ssh
RUN apt-get -y install \
        openssh-server

# modify the password
# ARG PASSWORD
# RUN sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config \
#         && ssh-keygen -t rsa -P "" -f /etc/ssh/ssh_host_rsa_key \
#         && ssh-keygen -t ecdsa -P "" -f /etc/ssh/ssh_host_ecdsa_key \
#         && ssh-keygen -t ed25519 -P "" -f /etc/ssh/ssh_host_ed25519_key \
#         && echo "root:${PASSWORD}" | chpasswd

# add id_rsa.pub in authorized_keys
ARG SSH_PUB_KEY
RUN mkdir -p ~/.ssh \
        && echo $SSH_PUB_KEY > ~/.ssh/authorized_keys

# install php
# download php src
# http://cn2.php.net/
# curl -L http://cn2.php.net/distributions/php-${PHP_VERSION}.tar.xz -o php-${PHP_VERSION}.tar.gz
RUN apt-get -y install re2c

ARG PHP_VERSION
ENV PATH $PATH:/usr/bin:/usr/sbin
RUN cd /root \
        && git clone https://gitee.com/codinghuang/php-repo.git \
        && cp php-repo/php-${PHP_VERSION}.tar.gz .
# unpace php package
RUN cd /root                           \
        && tar xf php-${PHP_VERSION}.tar.gz    \
        && mv php-${PHP_VERSION} php-src
# build php
RUN cd /root \
        && cd php-src \
        && ./configure --prefix=/usr \
                --with-config-file-path=/etc \
                --with-config-file-scan-dir=/etc/php.d \
                --enable-fpm \
                --enable-debug \
                --with-mysqli=mysqlnd \
                --with-pdo-mysql=mysqlnd \
                --with-mysqli \
                --with-pdo_mysql \
        && make > /dev/null \
        && make install > /dev/null \
        && cp php.ini-development /etc/php.ini \
        && cd /root \
        && rm -r php-${PHP_VERSION}.tar.gz                \
        && php -v

# install php extension
# install openssl

RUN cd /root/php-src/ext \
        && cd openssl \
        && cp config0.m4 config.m4 \
        && phpize \
        && ./configure \
        && make > /dev/null \
        && make install > /dev/null

# install zlib
RUN cd /root/php-src/ext \
        && cd zlib \
        && cp config0.m4 config.m4 \
        && phpize \
        && ./configure \
        && make > /dev/null \
        && make install > /dev/null

# install curl
RUN cd /root/php-src/ext \
        && cd curl \
        && phpize \
        && ./configure \
        && make > /dev/null \
        && make install > /dev/null

# install zip extension
RUN apt-get install -y libzip-dev
RUN cd /root/php-src/ext \
        && cd zip \
        && phpize \
        && ./configure \
        && make > /dev/null \
        && make install > /dev/null

# install sockets extension
RUN cd /root/php-src/ext \
        && cd sockets \
        && phpize \
        && ./configure \
        && make > /dev/null \
        && make install > /dev/null

# install swoole
# download swoole
ARG SWOOLE_VERSION
RUN cd /root \
        && curl -L https://github.com/swoole/swoole-src/archive/v${SWOOLE_VERSION}.tar.gz -o swoole-src.tar.gz
# build swoole
RUN cd /root \
        && tar -xzf swoole-src.tar.gz \
        && cd swoole-src* \
        && phpize \
        && ./configure --enable-openssl --with-openssl-dir=/usr/local/openssl/ \
                --enable-sockets \
                --enable-mysqlnd \
                --enable-http2 \
        && make > /dev/null \
        && make install > /dev/null \
        && cd /root \
        && rm swoole-src.tar.gz

COPY etc/php.d /etc/php.d

# install composer
RUN curl -sS https://getcomposer.org/installer | php \
        && mv composer.phar /usr/local/bin/composer
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ \
        && composer global require hirak/prestissimo \
        && composer global require "squizlabs/php_codesniffer=*"

# set the path for ssh
ARG LD_LIBRARY_PATH
# set the LD_LIBRARY_PATH to the compiler's search library
RUN echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> /etc/profile
RUN echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib" >> /etc/profile
# set the PATH
RUN echo "export PATH=$PATH:~/.composer/vendor/bin" >> /etc/profile

# set the http proxy for ssh
ARG HTTP_PROXY
ARG HTTPS_PROXY
RUN echo "export http_proxy=${HTTP_PROXY}" >> /etc/profile
RUN echo "export http_proxys=${HTTPS_PROXY}" >> /etc/profile

WORKDIR /root/codeDir

RUN mkdir -p /var/run/sshd

CMD ["/etc/init.d/ssh", "start"]
