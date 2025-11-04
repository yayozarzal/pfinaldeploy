#cloud-config
package_update: true
runcmd:
  - |
    set -e
    # Docker + Compose
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg lsb-release
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable docker
    systemctl restart docker

    mkdir -p /opt/app
    cat >/opt/app/docker-compose.yml <<'COMPOSE'
    version: '3.8'
    services:
      backend:
        image: groverdz/task-api-backend:latest
        container_name: task-api-backend
        environment:
          - PORT=3000
        ports:
          - "3000:3000"
        restart: unless-stopped

      frontend:
        image: groverdz/office-supply-frontend:latest
        container_name: office-supply-frontend
        ports:
          - "80:3000"
        environment:
          - NEXT_PUBLIC_API_URL=http://localhost:3000
        depends_on:
          - backend
        restart: unless-stopped
    COMPOSE

    cd /opt/app
    docker compose pull
    docker compose up -d
