FROM ubuntu:xenial
MAINTAINER Ahmed Bodiwala <ahmedbodi@crypto-expert.com>

ARG USER_ID
ARG GROUP_ID

ENV HOME /node

# add user with specified (or default) user/group ids
ENV USER_ID ${USER_ID:-1000}
ENV GROUP_ID ${GROUP_ID:-1000}

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -g ${GROUP_ID} node && useradd -u ${USER_ID} -g node -s /bin/bash -m -d /node node

RUN set -ex \
	&& apt-get update \
        && apt-get install software-properties-common build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils python3 git libboost-all-dev gosu -y \
        && add-apt-repository ppa:bitcoin/bitcoin \
        && apt-get update \
        && apt-get install libdb4.8-dev libdb4.8++-dev -y \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /node
COPY . /node/src

RUN echo PATH=\"\$HOME/bin:\$PATH\" >> .bash_profile

WORKDIR /node/src
RUN ./autogen.sh && ./configure --with-incompatible-bdb
RUN make -j $(nproc) install

ADD ./bin /usr/local/bin

VOLUME ["/node"]

WORKDIR /node

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["oneshot"]
