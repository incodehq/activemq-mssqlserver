#!/bin/sh

mkdir -p /run/secrets
if [ -d /run/secrets ]
then
  cd /run/secrets || exit 1
  # strip off any prefix
  mv *.spring.properties spring.properties
fi


if [ ! -f "/run/secrets/spring.properties" ]; then

  cat > /run/secrets/spring.properties <<EOF
activemq.data=activemq-data

activemq.db.driverClassName=org.hsqldb.jdbcDriver
activemq.db.url=jdbc:hsqldb:mem:activemq
activemq.db.username=sa
activemq.db.password=
activemq.db.jdbcAdapter=org.apache.activemq.store.jdbc.adapter.HsqldbJDBCAdapter
activemq.db.databaseLocker=org.apache.activemq.store.jdbc.DefaultDatabaseLocker
EOF

fi

echo "Starting ActiveMQ:"

/opt/activemq/bin/activemq console -Dspring.config.file=file:/run/secrets/spring.properties