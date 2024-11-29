<!--
 - SPDX-FileCopyrightText: 2023 Nextcloud GmbH and Nextcloud contributors
 - SPDX-License-Identifier: AGPL-3.0-or-later
-->

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
  --restart unless-stopped --privileged -d ghcr.io/nextcloud/nextcloud-appapi-dsp:release
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
  --restart unless-stopped --privileged -d ghcr.io/nextcloud/nextcloud-appapi-dsp:release
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

`TIMEOUT_CONNECT`: timeout for connecting to ExApp, default: **30s**

`TIMEOUT_CLIENT`: timeout for NC to start sending request data to the ExApp, default: **30s**

`TIMEOUT_SERVER`: timeout for ExApp to start responding to NC request, default: **1800s**

`NC_HAPROXY_PASSWORD_FILE`: Specifies path to a file containing the password for HAProxy. 

> [!NOTE]
> This file should be mounted into the container, and the password will be read from this file.
> If both NC_HAPROXY_PASSWORD and NC_HAPROXY_PASSWORD_FILE are specified, the container will exit with an error.

#### Only for ExApp installs with TLS:

* `EX_APPS_NET`: determines destination of requests to ExApps for HaProxy. Default:`localhost`

* `EX_APPS_COUNT`: determines amount of ports HaProxy will open to proxy requests to ExApps. Default:`30`

### Example when operated on a different host

when the docker-socket-proxy is installed on a different host than Nextcloud, the following settings can be used with the TLS configuration.
Ensure that the firewall is opened for the ports 2375, 23000-230xx (see `EX_APPS_COUNT`)

`-e BIND_ADDRESS="xxx.xxx.xxx.xx"` this needs to be the public ip of the host

`-e EX_APPS_NET="ipv4@127.0.0.1"` required for the HaProxy to reach the sub containers

`--net: host`

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
specify the EX_APPS_NET variable when creating the container:

```shell
  -e EX_APPS_NET="ipv4@localhost"
```

### Slow responding ExApps

Some AI applications may respond **longer** than the standard 30 seconds timeout defined in the `HaProxy` config.

An example of such an application: `context_chat`

For the successful operation of such applications, 
you can set custom config values through the environment variable during the creation of the DSP container with:

```shell
  -e TIMEOUT_SERVER="1800s"
```
