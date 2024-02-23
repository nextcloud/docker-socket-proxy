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
  --name nextcloud-appapi-dsp -h nextcloud-appapi-dsp \
  --restart unless-stopped --privileged -d ghcr.io/cloud-py-api/nextcloud-appapi-dsp:release
```

Instead of `some_secure_password` you put your password that later you should provide to AppAPI during Daemon creation.

> [!NOTE]
> Usually the **bridge** networks types in Docker are trusted networks.

### Docker with TLS

In this case ExApps will only map host's loopback adapter, and will be avalaible to Nextcloud only throw HaProxy.

```shell
docker run -e NC_HAPROXY_PASSWORD="some_secure_password" \
  -e BIND_ADDRESS="x.y.z.z"
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v `pwd`/certs/cert.pem:/certs/cert.pem \
  --name nextcloud-appapi-dsp -h nextcloud-appapi-dsp --net host \
  --restart unless-stopped --privileged -d ghcr.io/cloud-py-api/nextcloud-appapi-dsp:release
```

Here in addition we map certificate file from host with SSL certificate that will be used by HaProxy and specify to use the `host` network.

You should set `BIND_ADDRESS` to the IP on which server with ExApps can accept requests coming from the Nextcloud instance.

*This is necessary when using the “host” network so as not to occupy all interfaces, because ExApp will use loopback adapter.*

> [!WARNING]
> If the certificates are self-signed, your job is to add them to the Nextcloud instance so that AppAPI can recognize them.

### AppAPI

1. Create a daemon from the `Docker Socket Proxy` template in AppAPI.
2. Fill the password you used during container creation.

### Additionally supported variables

`HAPROXY_PORT`: using of custom port instead of **2375** which is the default one.

`BIND_ADDRESS`: the address to use for port binding. (Usually needed only for remote installs, **must be accessible from the Nextcloud**)

`EX_APPS_NET_FOR_HTTPS`: only for custom remote ExApp installs with TLS, determines destination of requests to ExApps for HaProxy.
    Default:`localhost`

`EX_APPS_COUNT`: only for remote ExApp installs with TLS, determines amount of  ports HaProxy will open to proxy requests to ExApps.
    Default:`50`

## Development

### HTTP(local)

To build image locally use:

```shell
docker build -f ./Dockerfile -t nextcloud-appapi-dsp:latest ./
```

Deploy image(for `nextcloud-docker-dev`):

```shell
docker run -e NC_HAPROXY_PASSWORD="some_secure_password" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --name nextcloud-appapi-dsp -h nextcloud-appapi-dsp --net master_default \
  --privileged -d nextcloud-appapi-dsp:latest
```

After that create daemon in AppAPI from the Docker Socket Proxy template, specifying:
1. Host: `nextcloud-appapi-dsp:2375`
2. Network in Deploy Config equal to `master_default`
3. Deploy Config: HaProxy password: `some_secure_password`

### HTTPS(remote)

We will emulate remote deployment still with `nextcloud-docker-dev` setup.
For this we deploy `nextcloud-appapi-dsp` to host network and reach it using `host.docker.internal`.

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
  -e BIND_ADDRESS="172.17.0.1" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v `pwd`/certs/cert.pem:/certs/cert.pem \
  --name nextcloud-appapi-dsp -h nextcloud-appapi-dsp --net host \
  --privileged -d nextcloud-appapi-dsp:latest
```

After that create daemon in AppAPI from the Docker Socket Proxy template, with next parameters:
1. Host: `host.docker.internal:2375`
2. Tick `https` checkbox.
3. Deploy Config: HaProxy password: `some_secure_password`

## Known issues

### IPv6 support

> [!NOTE]
> You need this only if IPv6 protocol is default on the remote machine with ExApps

_Currently_, not all external applications support the IPv6 protocol, and most often they listen only on IPv4, 
so in the case of using HTTPS when HaProxy forwards incoming connections, you should additionally 
specify the EX_APPS_NET_FOR_HTTPS variable when creating the container:

```shell
  -e EX_APPS_NET_FOR_HTTPS="ipv4@localhost"
```
