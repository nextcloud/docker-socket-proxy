# Nextcloud AppAPI Docker Socket Proxy

This is a **Security-Enhanced** proxy for the Docker Socket *specifically* for AppAPI.

It comes with built-in authentication and strict bruteforce protection.

The rules specifying which docker APIs are allowed for AppAPI are the same as in [Nextcloud AIO](https://github.com/nextcloud/all-in-one/tree/main/Containers/docker-socket-proxy).

## When to use

We highly recommend to use it **in all cases**, except for **Nextcloud AIO**, in that case use the standard Nextcloud AIO Docker Socket proxy.

> [!IMPORTANT]
> It is very important to understand that if you install ExApps on a remote daemon on an untrusted network,
> you should always use this docker socket proxy with TLS.

## How to use

### Docker in trusted network

```shell
docker run -e NC_HAPROXY_PASSWORD="some_secure_password" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --name aa-docker-socket-proxy -h aa-docker-socket-proxy \
  --restart unless-stopped --privileged -d ghcr.io/cloud-py-api/aa-docker-socket-proxy:release
```

Instead of `some_secure_password` you put your password that later you should provide to AppAPI during Daemon creation.

### Docker with TLS

```shell
docker run -e NC_HAPROXY_PASSWORD="some_secure_password" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v `pwd`/certs/cert.pem:/certs/cert.pem \
  --name aa-docker-socket-proxy -h aa-docker-socket-proxy --net host \
  --restart unless-stopped --privileged -d ghcr.io/cloud-py-api/aa-docker-socket-proxy:release
```

Here in addition we map certificate file from host with SSL certificate that will be used by HaProxy and specify `host` network.

*In this case ExApps will only map host's loopback adapter, and will be avalaible to Nextcloud only throw HaProxy.*

> [!WARNING]
> If the certificates are self-signed, your job is to add them to the Nextcloud instance so that AppAPI can recognize them.

### AppAPI

1. Create a daemon from the `Docker Socket Proxy` template in AppAPI.
2. Fill the password you used during container creation.

### Additionally supported variables

`HAPROXY_PORT`: using of custom port instead of **2375** which is the default one.

`EX_APPS_NET_FOR_HTTPS`: only for custom remote ExApp installs with TLS, determines destination of requests to ExApps for HaProxy.

## Development

### HTTP(local)

To build image locally use:

```shell
docker build -f ./Dockerfile -t aa-docker-socket-proxy:latest ./
```

Deploy image(for `nextcloud-docker-dev`):

```shell
docker run -e NC_HAPROXY_PASSWORD="some_secure_password" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --name aa-docker-socket-proxy -h aa-docker-socket-proxy --net master_default \
  --privileged -d aa-docker-socket-proxy:latest
```

After that create daemon in AppAPI from the Docker Socket Proxy template, specifying:
1. Host: `aa-docker-socket-proxy:2375`
2. Network in Deploy Config equal to `master_default`
3. Deploy Config: HaProxy password: `some_secure_password`

### HTTPS(remote)

We will emulate remote deployment still with `nextcloud-docker-dev` setup.
For this we deploy `aa-docker-socket-proxy` to host network and reach it using `host.docker.internal`.

> [!NOTE]
> Due to current Docker limitations, this setup type is not working on macOS.
> Ref issue: [Support Host Network for macOS](https://github.com/docker/roadmap/issues/238)

First create Self-Signed cert for tests:

```shell
openssl req -nodes -new -x509 -subj '/CN=host.docker.internal' -sha256 -keyout certs/privkey.pem -out certs/fullchain.pem -days 365000 > /dev/null 2>&1
```

```shell
cat certs/fullchain.pem certs/privkey.pem | tee certs/cert.pem > /dev/null 2>&1
```

Place `cert.pem` into `data/shared` folder of `nextcloud-docker-dev` and execute inside Nextcloud container:

```shell
sudo -u www-data php occ security:certificates:import /shared/cert.pem
```

Create HaProxy container:

```shell
docker run -e NC_HAPROXY_PASSWORD="some_secure_password" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v `pwd`/certs/cert.pem:/certs/cert.pem \
  --name aa-docker-socket-proxy -h aa-docker-socket-proxy --net host \
  --privileged -d aa-docker-socket-proxy:latest
```

After that create daemon in AppAPI from the Docker Socket Proxy template, with next parameters:
1. Host: `host.docker.internal:2375`
2. Tick `https` checkbox.
3. Deploy Config: HaProxy password: `some_secure_password`
