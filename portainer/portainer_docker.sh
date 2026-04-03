#!/bin/bash

CONTAINER_NAME="portainer"

# Check if container already exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Portainer container already exists."
    STATE=$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME")
    if [ "$STATE" = "true" ]; then
        echo "Portainer is already running at https://localhost:9443"
    else
        echo "Starting existing Portainer container..."
        docker start "$CONTAINER_NAME"
        echo "Portainer started at https://localhost:9443"
    fi
else
    echo "Creating and starting Portainer..."
    docker volume create portainer_data
    docker run -d \
        -p 8000:8000 \
        -p 9443:9443 \
        --name "$CONTAINER_NAME" \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:latest
    echo "Portainer is running at https://localhost:9443"
fi
