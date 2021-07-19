FROM ubuntu:18.04 AS builder

ARG BUILDENV
ENV BUILDENV ${BUILDENV:-dev}
ENV SHELL=/bin/bash \
    TERM=xterm \
    TZ=UTC \
    DEBIAN_FRONTEND=noninteractive \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8

RUN sed -i 's/archive.ubuntu.com/tw.archive.ubuntu.com/g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    make \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-distutils \
    zip \
    unzip \
    wget \
    gpg-agent \
  && apt-get clean && rm -rf /var/lib/apt/lists/* && \
  ln -s /usr/bin/python3 /usr/local/bin/python

# upgrade pip and prepare build
RUN pip3 install --no-cache --upgrade pip && \
    pip3 install --no-cache wheel jellyfish

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs


COPY mlsteam /build/mlsteam
COPY mlsteam_agent /build/mlsteam_agent

RUN cd /build/mlsteam_agent && make script && \
    cd /build/mlsteam && make front && \
    if [ "$BUILDENV" != "dev" ] ; then cd /build/mlsteam && \
       python3 -m compileall mlsteam -b -f ; \
       find mlsteam \
         -not -path "mlsteam/migrations/*" \
         -not -path "mlsteam/migrate.py" \
         -not -path "mlsteam/upgrade.py" \
         -not -path "mlsteam/templates/*" \
         -name "*.py" -exec rm -f {} \; ; fi && \
    cd /build/mlsteam && python3 setup.py bdist_wheel && python3 setup.py clean --all && \
    tar zxvf config/docker-*.tgz -C ./config && \
    rm -rf config/docker-*.tgz
    
# # final image
FROM ubuntu:18.04
ENV SHELL=/bin/bash \
    TERM=xterm \
    TZ=UTC \
    DEBIAN_FRONTEND=noninteractive \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8

RUN sed -i 's/archive.ubuntu.com/tw.archive.ubuntu.com/g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    btrfs-tools \
    certbot \
    curl \
    cron \
    dmidecode \
    gcc \
    gnupg \
    libsasl2-dev \
    libldap2-dev \
    libssl-dev \
    openssl \
    python3-dev \
    python3-setuptools \
    python3-pip \
    sqlite3 \
    sysstat \
    unzip \
    vim \
    wget \
    zip && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/bin/python3 /usr/local/bin/python && \
    ln -s /usr/bin/pip3 /usr/local/bin/pip && \
    pip3 install --no-cache --upgrade pip && \
    pip3 install --no-cache wheel jellyfish

# install latest nginx
RUN wget -q https://nginx.org/keys/nginx_signing.key -O- | apt-key add - && \
    echo "deb https://nginx.org/packages/mainline/ubuntu/ bionic nginx" >> /etc/apt/sources.list && \
    echo "deb-src https://nginx.org/packages/mainline/ubuntu/ bionic nginx" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install --upgrade -y nginx && \
    apt-get install -y python3-certbot-nginx && \
    rm -rf /etc/nginx/conf.d/default.conf && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/mlsteam/dist/ /build/mlsteam_agent/dist/ /opt/
COPY --from=builder /build/mlsteam/config /opt/mlsteam

RUN cd /opt && pip3 install mlsteam-*.whl && cd /opt/mlsteam && \
    # docker19.03.4
    mv docker/docker /usr/bin/docker && mv docker-compose /usr/local/bin/docker-compose && \
    # nginx 1.19.4
    mv nginx.conf /etc/nginx/nginx.conf && \
    mkdir -p /etc/nginx/sites-enabled && \
    mv nginx-default.conf /etc/nginx/sites-enabled/default && \
    mv 50x.html /usr/share/nginx/html/50x.html && \
    mv mc /usr/local/bin/mc && \
    # supervisord.conf
    mv supervisord.conf /etc/supervisord.conf && mkdir -p /var/log/supervisor && \
    # mlsteam
    mkdir -p /etc/mlsteam && mv mlsteam.ini mlsteam_reset.sh /etc/mlsteam && \
    # env
    mv environment login.defs /etc/ && \
    # download default template config
    wget -q https://raw.githubusercontent.com/myelintek/templates/main/default_templates.yml -O /opt/mlsteam/default_templates.yml

EXPOSE 80

VOLUME ["/data"]

CMD mkdir -p /data/log ; exec /usr/local/bin/supervisord -c /etc/supervisord.conf
