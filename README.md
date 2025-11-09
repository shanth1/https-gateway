# 🚀 Universal HTTPS Gateway with Docker and Nginx

[Russian version](README.ru.md)

This project provides a ready-to-use, universal reverse-proxy gateway. It is designed for maximum simplicity and reliability, allowing you to effortlessly publish any number of web applications under HTTPS, whether they are Docker containers or regular binaries.

## 🌟 Key Features

- **Full SSL Automation**: Automatically obtains and renews SSL certificates from Let's Encrypt for any domains and subdomains.
- **Subdomain Support**: Easily configure `app.example.com`, `api.example.com`, and even `staging.api.example.com`.
- **Flexible Proxying**:
  - Proxy to other **Docker containers** in the same network.
  - Proxy to services running **on the host machine** (by port) or on **another server** in a private network.
- **Local Development Mode**: Work with `localhost` and custom domains (`.local`, `.test`) using self-signed certificates for offline development.
- **Centralized Management**: A single `gateway.sh` script for all operations: from initial setup to certificate monitoring.
- **Security by Default**: Uses recommended Certbot TLS parameters and automatically adds important security headers (HSTS).

---

## 📖 Table of Contents

1.  [Core Concepts](#-core-concepts)
2.  [Quick Start: Initial Setup](#-quick-start-initial-setup)
3.  [Primary Use Case: Deploying a Project with Frontend and Backend](#-primary-use-case-deploying-a-project-with-frontend-and-backend)
4.  [Advanced Use Case: Proxying to a Non-Docker Service](#-advanced-use-case-proxying-to-a-non-docker-service)
5.  [Local Development Mode](#-local-development-mode)
6.  [Management and Monitoring](#-management-and-monitoring)
7.  [`gateway.sh` Command Reference](#-gatewaysh-command-reference)
8.  [Frequently Asked Questions (FAQ)](#-frequently-asked-questions-faq)

---

## 🧠 Core Concepts

To use the gateway effectively, it's important to understand three key elements:

1.  **Nginx + Certbot**: `Nginx` acts as a reverse-proxy, accepting all traffic on ports 80 and 443 and distributing it to your applications. `Certbot` works in tandem with Nginx to automatically obtain and renew SSL certificates via the ACME protocol.

2.  **Shared Docker Network**: The gateway and all your containerized applications must be in the same shared Docker network (by default, `web-gateway`). This allows containers to "see" each other by their service names, which is a secure and standard approach in Docker. Applications don't need to expose ports to the outside world (`ports`); they just need to declare them within the network (`expose`).

3.  **The `gateway.sh` script**: This is your single control center. Instead of memorizing long `docker-compose` commands, you use simple and clear commands like `./gateway.sh add` or `./gateway.sh check-expiry`.

---

## ⚙️ Quick Start: Initial Setup

These steps need to be performed **once** on your server.

1.  **Clone the repository:**

    ```sh
    git clone <your-repo-url>
    cd <repo-folder>
    ```

2.  **(Optional) Configure `.env`:**
    You can change the Docker network name in the `.env` file. If you do, remember to use the same name in the `docker-compose.yaml` files of your applications.

3.  **Run the setup script:**
    The script will create the Docker network and download recommended TLS parameters for Nginx into a Docker volume.

    ```sh
    chmod +x gateway.sh ./scripts/*.sh
    ./gateway.sh setup
    ```

    Expected output:

    ```
    Creating Docker network 'web-gateway'...
    Downloading recommended TLS parameters...
    Copying parameters to Docker volume...
    ✅ Initial setup complete!
    ```

4.  **Start the gateway:**
    This command will run the Nginx and Certbot containers in the background.
    ```sh
    ./gateway.sh up
    ```
    Your gateway is now running and ready for domain configuration.

---

## 🚀 Primary Use Case: Deploying a Project with Frontend and Backend

Let's imagine we have a standard web project consisting of two Docker services:

- `frontend` (e.g., a React/Vue application)
- `backend` (e.g., a Node.js/Python API)

We want to make them accessible at:

- `app.example.com` -> `frontend`
- `api.example.com` -> `backend`

### Step 1: Prepare your applications

Ensure that the `docker-compose.yaml` files for your applications are configured to use the gateway's external network.

**Example `docker-compose.yaml` for `frontend`:**

```yaml
# my-frontend-app/docker-compose.yaml
version: '3.8'

services:
  frontend-app: # <-- Service name: frontend-app
    image: my-frontend-image
    restart: unless-stopped
    expose:
      - '80' # <-- Internal port
    networks:
      - web-gateway-net

networks:
  web-gateway-net:
    external: true
    name: web-gateway # Network name from the gateway's .env file
```

_The `backend-api` is configured similarly._

### Step 2: Start the applications

Start both services from their respective folders:

```sh
# In the frontend folder
docker-compose up -d

# In the backend folder
docker-compose up -d
```

### Step 3: Configure DNS

In your domain's control panel, create two A-records pointing to your server's IP address:

- `app.example.com` -> `SERVER_IP`
- `api.example.com` -> `SERVER_IP`

> **💡 Important:** Before proceeding, make sure the DNS records have propagated. You can check this with the command `ping app.example.com`.

### Step 4: Add domains to the gateway

Return to the gateway folder and add each domain using the interactive script.

**Adding the Frontend:**

```sh
./gateway.sh add
```

Answer the script's questions:

- `Enter domain`: `app.example.com`
- `Enter your email`: `admin@example.com`
- `Where to proxy traffic? [1-3]`: `1` (To a Docker container)
- `Enter Docker service name`: `frontend-app` (from the frontend's `docker-compose.yaml`)
- `Enter the service's internal port`: `80`
- `Use staging server? (y/n)`: `n` (for a real certificate)

The script will automatically create the config, request a certificate, and reload Nginx.

**Adding the Backend:**
Run the same script again:

```sh
./gateway.sh add
```

And answer the questions for the backend:

- `Enter domain`: `api.example.com`
- `Enter your email`: `admin@example.com`
- `Where to proxy traffic? [1-2]`: `1`
- `Enter Docker service name`: `backend-api` (from the backend's `docker-compose.yaml`)
- `Enter the service's internal port`: `8000`
- `Use staging server? (y/n)`: `n`

**Done!** Your services are now accessible via HTTPS:

- `https://app.example.com`
- `https://api.example.com`

> **What about `api.backend.example.com`?**
> The process is identical! Just specify `api.backend.example.com` as the domain. The gateway will handle it without any issues.

---

## 🛠️ Advanced Use Case: Proxying to a Non-Docker Service

### Scenario 1: Proxying to a service running on the same host machine

Suppose you have a binary (e.g., a Go application) running directly on the host machine and listening on port `8080`.

1.  **Configure DNS:** Create an A-record (e.g., `legacy.example.com`) pointing to your server's IP.
2.  **Run the `add` script:**
    ```sh
    ./gateway.sh add
    ```
    Answer the questions:
    - `Enter domain`: `legacy.example.com`
    - `Where to proxy traffic? [1-3]`: `2` (To a port on the host machine)
    - `Enter the port on the host machine`: `8080`

### 🚨 Important Note on Security and Firewalls (for Scenario 1)

**The Problem:** After setup, you might see a `504 Gateway Timeout` error. This happens because the Nginx container cannot reach port `8080` on your server. The most common cause is the **host machine's firewall** (e.g., `ufw`), which blocks connections from Docker's internal network.

**The Solution:** You need to allow traffic from Docker containers to your server. This is safe because the ports are not being opened to the outside world.

**How to do it (recommended way):**

1.  **Find your Docker network's subnet:**

    ```sh
    # 'web-gateway' is the network name from your .env file
    docker network inspect web-gateway | grep "Subnet"
    ```

    You will see something like `"Subnet": "172.19.0.0/16"`.

2.  **Add a general allow rule to `ufw`:**
    This command will allow all containers from this network to access any port on the host machine.
    ```sh
    # Replace 172.19.0.0/16 with your subnet
    sudo ufw allow from 172.19.0.0/16
    ```
    This is the most convenient method, as it won't require you to add new rules for each new service.

**When is this necessary?**
This rule is **only required if you are proxying traffic to host machine ports (option 2)**. For proxying between Docker containers (option 1), this is not necessary, as they communicate within an isolated network.

### Scenario 2: Proxying to another server in a private network

This is useful if you have services on other machines (e.g., `192.168.0.10:3000`) in the same local network.

1.  **Configure DNS:** Create an A-record (e.g., `internal.example.com`) pointing to the **public IP of the server with the gateway**.
2.  **Run the `add` script:**
    - `Where to proxy traffic? [1-3]`: `3` (To another server by IP address)
    - `Enter the target server's IP address`: `192.168.0.10`
    - `Enter the port on the target server`: `3000`

Done! The gateway will terminate HTTPS and forward the traffic to your internal server.

---

## 💻 Local Development Mode

This mode is ideal for testing HTTPS connections on your local machine without needing an internet connection.

1.  **Generate a local certificate:**
    You can do this for `localhost` or any custom domain.

    ```sh
    # For localhost
    ./scripts/generate-local-cert.sh localhost

    # For a custom domain
    ./scripts/generate-local-cert.sh my-app.local
    ```

2.  **(For custom domains) Configure `/etc/hosts`:**
    If you use a domain like `my-app.local`, add the following line to your `/etc/hosts` file (`C:\Windows\System32\drivers\etc\hosts` on Windows):

    ```
    127.0.0.1   my-app.local
    ```

3.  **Create an Nginx configuration:**
    Copy the template and replace the placeholders.

    ```sh
    cp nginx/templates/local.conf.template nginx/conf.d/my-app.local.conf
    ```

    Edit `nginx/conf.d/my-app.local.conf`, specifying `<DOMAIN>`, `<SERVICE_NAME>` (the container name of your local application), and `<SERVICE_PORT>`.

4.  **Start the local gateway:**

    ```sh
    ./gateway.sh up-local
    ```

    Open `https://my-app.local` in your browser. You will need to accept a security exception once, as the browser does not trust your self-signed certificate.

5.  **Stop the local gateway:**
    ```sh
    ./gateway.sh down-local
    ```

---

## 📈 Management and Monitoring

Let's Encrypt certificates are valid for 90 days. The gateway is configured for **automatic renewal** every 12 hours. You don't need to do anything. However, special commands exist for full control.

- **Check certificate expiry dates:**
  This is the most important monitoring command. Run it once a month to ensure everything is in order.

  ```sh
  ./gateway.sh check-expiry
  ```

The output will show how many days are left until each certificate expires.

- **Force renewal:**
  This command will attempt to renew all certificates. Use it if you receive a notification from Let's Encrypt about an impending expiration or for debugging purposes.

  ```sh
  ./gateway.sh renew
  ```

  _Note: Certbot will not renew a certificate if it has more than 30 days until expiration._

- **View logs:**
  If something goes wrong, the Nginx logs are the first place to look.
  ```sh
  ./gateway.sh logs
  ```

---

## 🗂️ `gateway.sh` Command Reference

#### Lifecycle

- `setup`: **(Run once)** Prepares the system for operation.
- `up`: Starts the production gateway (Nginx + Certbot).
- `down`: Stops the production gateway.
- `reload`: Reloads the Nginx configuration without dropping connections.
- `status`: Shows the status of the gateway containers.
- `logs`: Shows Nginx logs in real-time.

#### Domain Management

- `add`: Starts an interactive wizard to add a new domain/subdomain.
- `remove`: Starts an interactive wizard to remove a domain and its certificate.
- `list`: Shows a list of all configured domains.

#### Certificate Management

- `renew`: Forcibly runs the renewal process for all certificates.
- `check-expiry`: Checks and displays the expiry dates for all certificates.

#### Local Development

- `up-local`: Starts the gateway in local development mode.
- `down-local`: Stops the local gateway.

---

## ❓ Frequently Asked Questions (FAQ)

**Q: I'm getting an error from Certbot when adding a domain. What should I do?**
**A:** The most common reasons are: 1. **The DNS record has not propagated.** Make sure your domain points to the correct IP. 2. **Port 80 is blocked.** Ensure your firewall (on the server or with your hosting provider) allows incoming traffic on port 80. Let's Encrypt uses it to verify domain ownership. 3. **You have exceeded Let's Encrypt rate limits.** If you have failed to obtain a certificate many times, use the "staging server" option to avoid blocking your domain.

**Q: I'm seeing a `502 Bad Gateway` error. How do I fix it?**
**A:** This means Nginx cannot communicate with your application. Check that: 1. Your application's container is running (`docker ps`). 2. The service name (`<SERVICE_NAME>`) in the Nginx config (`nginx/conf.d/your-domain.conf`) exactly matches the service name in your application's `docker-compose.yaml`. 3. The application and the gateway are in the same Docker network.

**Q: How can I add custom headers or other Nginx rules?**
**A:** Simply edit the corresponding configuration file in `nginx/conf.d/`. For example, `nginx/conf.d/app.example.com.conf`. After saving your changes, run `./gateway.sh reload` to apply them.
