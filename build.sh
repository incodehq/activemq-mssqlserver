#!/bin/bash

IMAGE="incodehq/activemq-sqlserver"

if [ -f "tag.properties" ]
then
  NOW=$(cat tag.properties)
else
  NOW="$(date +'%Y%m%d.%H%M').$(git branch | cut -c3-).$(git rev-parse HEAD | cut -c1-8)"
fi

echo ""
echo "building:"
echo "  $IMAGE:$NOW"
echo ""

docker build -t $IMAGE:$NOW ./
#docker push $IMAGE:$NOW

