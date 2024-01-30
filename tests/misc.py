from subprocess import run, DEVNULL
import time
from os import environ


def remove_haproxy():
    run("docker container rm nextcloud_appapi_dsp --force".split(), stderr=DEVNULL, stdout=DEVNULL, check=False)


def start_haproxy(port: int = 2375):
    tag = environ.get("TAG_SUFFIX", "latest")
    run(f"docker run -e NC_HAPROXY_PASSWORD='some_secure_password' -e HAPROXY_PORT={port} "
        "-v /var/run/docker.sock:/var/run/docker.sock "
        f"--name nextcloud_appapi_dsp -h nextcloud_appapi_dsp -p {port}:{port} "
        f"--rm --privileged -d nextcloud_appapi_dsp:{tag}".split(),
        stdout=DEVNULL,
        check=True)


def wait_heartbeat():
    for i in range(60):
        r = run(
            ["docker", "inspect", "--format='{{json .State.Health.Status}}'", "nextcloud_appapi_dsp"],
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
