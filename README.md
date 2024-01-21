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
  --name aa-docker-socket-proxy -h aa-docker-socket-proxy \
  --restart unless-stopped --privileged -d ghcr.io/cloud-py-api/aa-docker-socket-proxy:release
```

Here in addition we map certificate file from host with SSL certificate that will be used by HaProxy.

> [!WARNING]
> If the certificates are self-signed, your job is to add them to the Nextcloud instance so that AppAPI can recognize them.

### AppAPI

1. Create a daemon from the `Docker Socket Proxy` or `Docker Socket Proxy Remote` template in AppAPI.
2. Fill the password you used during container creation.
3. If `Docker Socket Proxy Remote` is used you need to specify the IP/DNS of the created HaProxy.

### Additionally supported variables

`HAPROXY_PORT`: using of custom port instead of **2375** which is the default one.

`EX_APPS_NET`: only for custom remote ExApp installs with TLS, determines destination of requests to ExApps for HaProxy.

## Development

To build image locally use:

```shell
docker build -f ./Dockerfile -t aa-docker-socket-proxy:latest ./
```

Deploy image(for `nextcloud-docker-dev`):

```shell
docker run -e NC_HAPROXY_PASSWORD="some_secure_password" -v /var/run/docker.sock:/var/run/docker.sock \
--name aa-docker-socket-proxy -h aa-docker-socket-proxy --net master_default --privileged -d aa-docker-socket-proxy:latest
```

If you need create Self-Signed cert for tests:

```shell
openssl req -nodes -new -x509 -subj '/CN=*' -sha256 -keyout certs/privkey.pem -out certs/fullchain.pem -days 365000 > /dev/null 2>&1
```

```shell
cat certs/fullchain.pem certs/privkey.pem | tee certs/cert.pem > /dev/null 2>&1
```
