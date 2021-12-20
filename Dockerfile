FROM ryde11/c7-systemd
LABEL maintainer="ryde <masakio@post.kek.jp>"

# file copy
ADD ./mongodb-org-5.0.repo /etc/yum.repos.d/
ADD ./disable-transparent-hugepages /etc/init.d/

# yum update & install
RUN yum -y update && \
    yum install -y git2u gcc make zlib-devel libffi-devel bzip2-devel openssl-devel ncurses-devel \
    sqlite-devel readline-devel tk-devel gdbm-devel libuuid-devel xz-devel

# python install
RUN curl -O https://www.python.org/ftp/python/3.9.5/Python-3.9.5.tgz && \
    tar xvzf Python-3.9.5.tgz && \
    cd Python-3.9.5 && \
    ./configure --with-ensurepip --enable-shared  --prefix=/usr/local/python3.9
RUN cd /Python-3.9.5 && make && make altinstall

# configure python path
RUN ln -sf /usr/local/python3.9/bin/python3.9 /usr/bin/python3 && ln -sf /usr/local/python3.9/bin/pip3.9 /usr/bin/pip3 && ln /usr/local/python3.9/lib/libpython3.9.so.1.0 /usr/lib64/

# pip install
# RUN pip3 install -U pip

# mongodb install
RUN yum install -y mongodb-org && \
    yum clean all

# configure mongodb
RUN chmod 755 /etc/init.d/disable-transparent-hugepages && \
    chkconfig --add disable-transparent-hugepages && \
    mkdir -p /usr/local/mongodb/conf && \
    openssl rand -base64 741 > /usr/local/mongodb/conf/mongodb-keyfile && \
    chmod 600 /usr/local/mongodb/conf/mongodb-keyfile && \
    chown -R mongod.mongod /usr/local/mongodb/conf/mongodb-keyfile

# rewrite mongodb config file
RUN sed -i -e "/^#security:/c\security:" /etc/mongod.conf && \
    sed -i -e "/^security/a \  authorization: enabled" /etc/mongod.conf && \
    sed -i -e "/^security/a \  keyFile: /usr/local/mongodb/conf/mongodb-keyfile" /etc/mongod.conf

# start mongodb
RUN systemctl enable mongod.service

EXPOSE 27017

CMD ["/usr/sbin/init"]
