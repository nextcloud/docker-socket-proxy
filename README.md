# Nextcloud AppAPI Docker Socket Proxy

This is a **Security-Enhanced** proxy for the Docker Socket *specifically* for AppAPI.

It comes with built-in authentication and strict bruteforce protection.

The rules specifying which docker APIs are allowed for AppAPI are the same as in [Nextcloud AIO](https://github.com/nextcloud/all-in-one/tree/main/Containers/docker-socket-proxy).

For the optimal use of AppAPI in conjunction with Docker, the following approach is highly recommended for all scenarios.

For those utilizing **Nextcloud AIO**, it's advised to employ the standard Nextcloud AIO Docker Socket proxy.

## How to use

### Docker in trusted network

```shell
docker run -e NC_HAPROXY_PASSWORD="some_secure_password" -v /var/run/docker.sock:/var/run/docker.sock \
  --name aa-docker-socket-proxy -h aa-docker-socket-proxy --rm --privileged -d ghcr.io/cloud-py-api/aa-docker-socket-proxy:release
```

Instead of `some_secure_password` you put your password that later you should provide to AppAPI during Daemon creation.

### Docker with SSL

```shell
docker run -e NC_HAPROXY_PASSWORD="some_secure_password" -v /var/run/docker.sock:/var/run/docker.sock \
  -v `pwd`/certs/cert.pem:/certs/cert.pem \
  --name aa-docker-socket-proxy -h aa-docker-socket-proxy --rm --privileged -d ghcr.io/cloud-py-api/aa-docker-socket-proxy:release
```

Here in addition to `some_secure_password` you should map certificate file from host with SSL certificates that will be used by HaProxy and ExApps.

> [!WARNING]
> If the certificates are self-signed, your job is to add them to the Nextcloud instance so that AppAPI can recognize them.

### AppAPI

1. Create a Docker Deploy Daemon in AppAPI with the button: `Docker Socket Proxy`
2. Fill the password you used during container creation.
3. In cases when DockerSocketProxy is on a remote server, you also will be asked for the IP/DNS of the created HaProxy.

### Additionally supported variables

You can specify `HAPROXY_PORT` during container creation to use custom port instead of 2735 which is the default one.

## Development

To build image locally use:

```shell
docker build -f ./Dockerfile -t aa-docker-socket-proxy:latest ./
```

Deploy image(for `nextcloud-docker-dev`):

```shell
docker run -e NC_HAPROXY_PASSWORD="some_secure_password" -v /var/run/docker.sock:/var/run/docker.sock \
--name aa-docker-socket-proxy -h aa-docker-socket-proxy --rm --net master_default --privileged -d aa-docker-socket-proxy:latest
```

If you need create Self-Signed cert for tests:

```shell
openssl req -nodes -new -x509 -subj '/CN=*' -sha256 -keyout certs/privkey.pem -out certs/fullchain.pem -days 365000 > /dev/null 2>&1
```

```shell
cat certs/fullchain.pem certs/privkey.pem | tee certs/cert.pem > /dev/null 2>&1
```
