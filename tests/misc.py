from subprocess import run, DEVNULL
import time


def remove_haproxy():
    run("docker container rm aa-docker-socket-proxy --force".split(), stderr=DEVNULL, stdout=DEVNULL, check=False)


def start_haproxy(port: int = 2375):
    run(f"docker run -e NC_HAPROXY_PASSWORD='some_secure_password' -e HAPROXY_PORT={port} "
        "-v /var/run/docker.sock:/var/run/docker.sock "
        f"--name aa-docker-socket-proxy -h aa-docker-socket-proxy -p {port}:{port} "
        "--rm --privileged -d ghcr.io/cloud-py-api/aa-docker-socket-proxy:latest".split(),
        stdout=DEVNULL,
        check=True)


def wait_heartbeat():
    for i in range(60):
        r = run(
            ["docker", "inspect", "--format='{{json .State.Health.Status}}'", "aa-docker-socket-proxy"],
            capture_output=True, check=True, )
        r = r.stdout.decode("UTF-8")
        if r.find("healthy") != -1:
            return
        time.sleep(1)
    raise Exception("Container HEALTHCHECK fails.")


def initialize_container():
    remove_haproxy()
    start_haproxy()
    wait_heartbeat()
