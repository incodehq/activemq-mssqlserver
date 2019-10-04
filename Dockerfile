#
# This Dockerfile expects that `spring.properties` is mounted as a secret in `/run/secrets`
#
# If none is provided, then it will fallback to using an in-memory HSQLDB database
#
FROM openjdk:8-jre-alpine

ENV ACTIVEMQ_VERSION 5.15.9
ENV MSSQL_JDBC_VERSION 6.4.0.jre8
ENV HSQLDB_JDBC_VERSION 2.5.0

ENV ACTIVEMQ apache-activemq-$ACTIVEMQ_VERSION
ENV ACTIVEMQ_TCP=61616
#ENV ACTIVEMQ_AMQP=5672
#ENV ACTIVEMQ_STOMP=61613
#ENV ACTIVEMQ_MQTT=1883
#ENV ACTIVEMQ_WS=61614
ENV ACTIVEMQ_UI=8161
ENV ACTIVEMQ_SHA512=35cae4258e38e47f9f81e785f547afc457fc331d2177bfc2391277ce24123be1196f10c670b61e30b43b7ab0db0628f3ff33f08660f235b7796d59ba922d444f
ENV MSSQL_JDBC_SHA512=dc443263901360c061df7220e4ef87eb6044ae4da6213572131ef6866b8620bf9ffbd50edc1973ec08687ec09fbd2994b6c8db2aa2ea22d3d219f1aaa55d7090
ENV HSQLDB_JDBC_SHA512=4209b37bc6dcd24ca9b599f9aa491e5b36758e13ef557611f257a480cc50df993eb31a9573dda6cc637874927a2db8d6f584b00d16310361fd055b8c70c5f7a0

ENV ACTIVEMQ_HOME /opt/activemq

RUN set -x && \
    mkdir -p /opt && \
    apk --update add --virtual build-dependencies curl && \
    curl https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/$MSSQL_JDBC_VERSION/mssql-jdbc-$MSSQL_JDBC_VERSION.jar -o mssql-jdbc-$MSSQL_JDBC_VERSION.jar && \
    curl https://repo1.maven.org/maven2/org/hsqldb/hsqldb/$HSQLDB_JDBC_VERSION/hsqldb-$HSQLDB_JDBC_VERSION.jar -o hsqldb-$HSQLDB_JDBC_VERSION.jar && \
    curl https://archive.apache.org/dist/activemq/$ACTIVEMQ_VERSION/$ACTIVEMQ-bin.tar.gz -o $ACTIVEMQ-bin.tar.gz

# Validate checksums
RUN if [ "$ACTIVEMQ_SHA512" != "$(sha512sum $ACTIVEMQ-bin.tar.gz | awk '{print($1)}')" ];\
    then \
        echo "sha512 value for ActiveMQ doesn't match! exiting."  && \
        exit 1; \
    fi;

RUN if [ "$MSSQL_JDBC_SHA512" != "$(sha512sum mssql-jdbc-$MSSQL_JDBC_VERSION.jar | awk '{print($1)}')" ];\
    then \
        echo "sha512 values for MSSQL JDBC driver doesn't match! exiting."  && \
        exit 1; \
    fi;

RUN if [ "$HSQLDB_JDBC_SHA512" != "$(sha512sum hsqldb-$HSQLDB_JDBC_VERSION.jar | awk '{print($1)}')" ];\
    then \
        echo "sha512 values for HSQLDB JDBC driver doesn't match! exiting."  && \
        exit 1; \
    fi;

RUN tar xzf $ACTIVEMQ-bin.tar.gz -C  /opt && \
    ln -s /opt/$ACTIVEMQ $ACTIVEMQ_HOME && \
    addgroup -S activemq && adduser -S -H -G activemq -h $ACTIVEMQ_HOME activemq && \
    chown -R activemq:activemq /opt/$ACTIVEMQ && \
    chown -h activemq:activemq $ACTIVEMQ_HOME && \
    apk del build-dependencies && \
    rm -rf /var/cache/apk/*

RUN cp mssql-jdbc-$MSSQL_JDBC_VERSION.jar /opt/$ACTIVEMQ/lib/optional/mssql-jdbc-$MSSQL_JDBC_VERSION.jar
RUN cp hsqldb-$HSQLDB_JDBC_VERSION.jar /opt/$ACTIVEMQ/lib/optional/hsqldb-$HSQLDB_JDBC_VERSION.jar

RUN mv /opt/$ACTIVEMQ/conf/activemq.xml /opt/$ACTIVEMQ/conf/activemq.xml.ORIG
COPY src/conf/activemq.xml /opt/$ACTIVEMQ/conf/activemq.xml
COPY src/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# although it would be preferable to run as non-root, the entrypoint.sh needs to read from /run/secrets
# USER activemq

WORKDIR $ACTIVEMQ_HOME
EXPOSE $ACTIVEMQ_TCP
#EXPOSE $ACTIVEMQ_AMQP
#EXPOSE $ACTIVEMQ_STOMP
#EXPOSE $ACTIVEMQ_MQTT
#EXPOSE $ACTIVEMQ_WS
EXPOSE $ACTIVEMQ_UI

CMD /entrypoint.sh
