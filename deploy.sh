#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <new-tag>"
  exit 1
fi

NEW_TAG=$1
IMAGE=<your-dockerhub-username>/yolo-stream

echo "Pulling $IMAGE:$NEW_TAG..."
docker pull $IMAGE:$NEW_TAG

echo "Tagging $IMAGE:$NEW_TAG as latest..."
docker tag $IMAGE:$NEW_TAG $IMAGE:latest

echo "Starting v2 service..."
docker-compose up -d --no-deps --scale app-v2=1 app-v2

echo "Waiting for v2 to pass healthcheck..."
until [ "$(docker inspect --format='{{.State.Health.Status}}' yolo-app-v2)" == "healthy" ]; do
  sleep 2
done

echo "Switching traffic to v2..."
docker stop yolo-app-v1
docker rename yolo-app-v2 yolo-app-v1

echo "Deployment complete. v2 is now serving on port 5000."
