FROM ubuntu:18.04 AS builder
ARG DEBIAN_FRONTEND=noninteractive
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

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get install -y nodejs

COPY ./ui /tmp/ui
RUN cd /tmp/ui \
  && node -v \
  && npm -v \
  && npm install \
  && npm run build

# # final image
FROM tensorflow/tensorflow:2.4.2-gpu
ENV SHELL=/bin/bash \
    TERM=xterm \
    TZ=UTC \
    DEBIAN_FRONTEND=noninteractive \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8
COPY ./app /app
COPY --from=builder /tmp/ui/dist /app/static
COPY requirements.txt /tmp
RUN pip install -r /tmp/requirements.txt
WORKDIR /app
CMD [ "python" , "main.py"]
