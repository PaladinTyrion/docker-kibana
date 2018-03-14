# Dockerfile for Kibana 5.6.3

# Build with:
# docker build -t <repo-user>/kibana .

# Run with:
# docker run -p 5601:5601 -it --name kibana <repo-user>/kibana

FROM phusion/baseimage
MAINTAINER paladintyrion <paladintyrion@gmail.com>

###############################################################################
#                               GROUP && USER
###############################################################################

ENV KIBANA_HOME /opt/kibana
# ensure kibana user exists
ENV KIBANA_GID 443
ENV KIBANA_UID 443
RUN groupadd -r kibana -g ${KIBANA_GID} \
    && useradd -r -s /usr/sbin/nologin -d ${KIBANA_HOME} -c "Kibana service user" -u ${KIBANA_UID} -g kibana kibana

###############################################################################
#                            GOSU && TIMEZONE && JDK8
###############################################################################

ENV GOSU_VERSION 1.10

ENV DEBIAN_FRONTEND noninteractive
RUN set -x \
		&& apt-get update -qq \
		&& apt-get install -yq --no-install-recommends tzdata cron \
		&& dpkg-reconfigure -f noninteractive tzdata \
		&& apt-get install -qqy --no-install-recommends ca-certificates wget curl \
		&& rm -rf /var/lib/apt/lists/* \
		&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
		&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture | awk -F- '{ print $NF }').asc" \
		&& export GNUPGHOME="$(mktemp -d)" \
		&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
		&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
		&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
		&& chmod +x /usr/local/bin/gosu \
		&& gosu nobody true \
		&& ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
		&& apt-get clean \
    && rm -fr /tmp/* \
		&& set +x

###############################################################################
#                               INSTALL KIBANA
###############################################################################

### install Kibana

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANGUAGE en_US:en
ENV KIBANA_PATH $KIBANA_HOME/bin
ENV PATH $KIBANA_PATH:$PATH

RUN mkdir -p ${KIBANA_HOME} \
    && mkdir -p /var/log/kibana /tmp/kibana \
    && chown -R kibana:kibana ${KIBANA_HOME} /var/log/kibana /tmp/kibana \
    && mkdir -p /etc/logrotate.d

ENV KIBANA_VERSION 5.6.3
ENV KIBANA_PACKAGE kibana-${KIBANA_VERSION}-linux-x86_64.tar.gz

RUN curl -O https://artifacts.elastic.co/downloads/kibana/${KIBANA_PACKAGE} \
    && tar -xzf ${KIBANA_PACKAGE} -C ${KIBANA_HOME} --strip-components=1 \
    && rm -f ${KIBANA_PACKAGE} \
    && apt-get autoremove \
		&& apt-get autoclean \
    && chown -R kibana:kibana ${KIBANA_HOME}

COPY ./kibana-init /etc/init.d/kibana
RUN sed -i -e 's#^KIBANA_HOME=$#KIBANA_HOME='$KIBANA_HOME'#' /etc/init.d/kibana \
    && chmod +x /etc/init.d/kibana

###############################################################################
#                           INSTALL KIBANA-ELASTALERT
###############################################################################

ENV KIBANA_ELASTALERT_PACKAGE elastalert-${KIBANA_VERSION}-latest.zip

RUN set -x \
    && ${KIBANA_HOME}/bin/kibana-plugin install https://git.bitsensor.io/front-end/elastalert-kibana-plugin/builds/artifacts/kibana5/raw/artifact/${KIBANA_ELASTALERT_PACKAGE}?job=build \
    && ${KIBANA_HOME}/bin/kibana-plugin list \
    && set +x

###############################################################################
#                               CONFIGURATION
###############################################################################

### configure Kibana

COPY ./kibana.yml ${KIBANA_HOME}/config/kibana.yml
RUN chmod -R +r ${KIBANA_HOME}/config

### configure logrotate

COPY ./kibana-logrotate /etc/logrotate.d/kibana
RUN chmod 644 /etc/logrotate.d/kibana

###############################################################################
#                               PREPARE START
###############################################################################

COPY ./replace_ips.sh /usr/local/bin/replace_ips.sh
COPY ./start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/replace_ips.sh \
    && chmod +x /usr/local/bin/start.sh

###############################################################################
#                                XPACK INSTALLATION
###############################################################################

# ENV XPACK_VERSION 5.6.3
# ENV XPACK_PACKAGE x-pack-${XPACK_VERSION}.zip
#
# WORKDIR /tmp
# RUN gosu kibana ${KIBANA_HOME}/bin/kibana-plugin install \
#       file:///tmp/${XPACK_PACKAGE} \
#  && rm -f ${XPACK_PACKAGE}
#
# RUN sed -i -e 's/curl localhost:9200/curl -u elastic:changeme localhost:9200/' \
#       -e 's/curl localhost:5601/curl -u kibana:paladin localhost:5601/' \
#       /usr/local/bin/start.sh

###############################################################################
#                                   START
###############################################################################

EXPOSE 5601

CMD [ "/usr/local/bin/start.sh" ]
