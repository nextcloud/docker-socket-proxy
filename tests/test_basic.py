# SPDX-FileCopyrightText: 2023 Nextcloud GmbH and Nextcloud contributors
# SPDX-License-Identifier: AGPL-3.0-only

import httpx
import pytest
import misc


def test_ping_spam():
    client = httpx.Client(base_url="http://localhost:2375", auth=("app_api_haproxy_user", "some secure password"))
    for i in range(100):
        r = client.get("_ping")
        assert r.status_code == 200


def test_volume_creation_removal():
    volume_name = "nc_app_test_data"
    httpx.post("http://localhost:2375/volumes/create",
               auth=("app_api_haproxy_user", "some secure password"),
               json={"name": volume_name})
    httpx.delete(
        f"http://localhost:2375/volumes/{volume_name}",
        auth=("app_api_haproxy_user", "some_secure_password"),
    )


def test_volume_creation_removal_invalid():
    volume_name = "app_test_data"
    for i in range(30):
        r = httpx.post(
            "http://localhost:2375/volumes/create",
            auth=("app_api_haproxy_user", "some secure password"),
            json={"name": volume_name},
        )
        assert r.status_code == 403
        r = httpx.delete(f"http://localhost:2375/volumes/{volume_name}",
                         auth=("app_api_haproxy_user", "some secure password"))
        assert r.status_code == 403


def test_invalid_url():
    client = httpx.Client(base_url="http://localhost:2375", auth=("app_api_haproxy_user", "some secure password"))
    for i in range(50):
        client.get("_unknown")


def test_autoban():
    client = httpx.Client(base_url="http://localhost:2375", auth=("app_api_haproxy_user", "some secure password1"))
    with pytest.raises(httpx.ReadTimeout):
        for i in range(10):
            client.get("_ping")
    print("Autoban, invalid auth:", i + 1)
    misc.initialize_container()


# test should be run last
def test_non_standard_port():
    misc.remove_haproxy()
    try:
        misc.start_haproxy(port=12375)
        misc.wait_heartbeat()
        r = httpx.get("http://localhost:12375/_ping", auth=("app_api_haproxy_user", "some secure password"))
        assert r.status_code == 200
    finally:
        misc.remove_haproxy()
