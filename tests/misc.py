from subprocess import run, DEVNULL
import time


def restart_haproxy():
    run("docker container rm aa-docker-socket-proxy --force".split(), stderr=DEVNULL, stdout=DEVNULL, check=False)
    run("docker run -e NC_HAPROXY_PASSWORD='some_secure_password' "
        "-v /var/run/docker.sock:/var/run/docker.sock "
        "--name aa-docker-socket-proxy -h aa-docker-socket-proxy -p 2375:2375 "
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
    restart_haproxy()
    wait_heartbeat()
