# Portainer Setup

## Launch

```bash
./portainer_docker.sh
```

The script will:
- Create a `portainer_data` Docker volume for persistent data
- Start Portainer CE as a container with restart policy `always`
- Reuse the existing container if it already exists

## Access

Open your browser and go to:

```
https://localhost:9443
```

> The certificate is self-signed, so your browser will show a security warning. Click **Advanced** and proceed.

On first access you will be prompted to create an admin user and password.

## Ports

| Port | Purpose               |
|------|-----------------------|
| 9443 | Web UI (HTTPS)        |
| 8000 | Edge Agent tunnel     |

## Manage

```bash
# Stop Portainer
docker stop portainer

# Start Portainer
docker start portainer

# Remove Portainer (keeps data volume)
docker rm -f portainer

# Remove everything including data
docker rm -f portainer && docker volume rm portainer_data
```
