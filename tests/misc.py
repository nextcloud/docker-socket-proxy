# SPDX-FileCopyrightText: 2023 Nextcloud GmbH and Nextcloud contributors
# SPDX-License-Identifier: AGPL-3.0-only

from subprocess import run, DEVNULL
import time
from os import environ


def remove_haproxy():
    run("docker container rm nextcloud-appapi-dsp --force".split(), stderr=DEVNULL, stdout=DEVNULL, check=False)


def start_haproxy(port: int = 2375):
    tag = environ.get("TAG_SUFFIX", "latest")
    run(
        [
            "docker", "run", "-e", "NC_HAPROXY_PASSWORD=some secure password", "-e",
            f"HAPROXY_PORT={port}", "-v", "/var/run/docker.sock:/var/run/docker.sock",
            "--name", "nextcloud-appapi-dsp", "-h", "nextcloud-appapi-dsp", "-p", f"{port}:{port}",
            "--rm", "--privileged", "-d", f"nextcloud-appapi-dsp:{tag}"
        ],
        stdout=DEVNULL,
        check=True,
    )


def wait_heartbeat():
    for i in range(60):
        r = run(
            ["docker", "inspect", "--format='{{json .State.Health.Status}}'", "nextcloud-appapi-dsp"],
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
