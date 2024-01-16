import httpx
import pytest
import misc


def test_ping_spam():
    client = httpx.Client(base_url="http://localhost:2375", auth=("app_api_haproxy_user", "some_secure_password"))
    for i in range(60):
        r = client.get("_ping")
        assert r.status_code == 200


def test_volume_creation_removal():
    volume_name = "nc_app_test_data"
    httpx.post("http://localhost:2375/volumes/create",
               auth=("app_api_haproxy_user", "some_secure_password"),
               json={"name": volume_name})
    httpx.delete(
        f"http://localhost:2375/volumes/{volume_name}",
        auth=("app_api_haproxy_user", "some_secure_password"),
    )


def test_volume_creation_removal_invalid():
    volume_name = "app_test_data"
    with pytest.raises(httpx.ReadTimeout):
        for i in range(9):
            r = httpx.post(
                "http://localhost:2375/volumes/create",
                auth=("app_api_haproxy_user", "some_secure_password"),
                json={"name": volume_name},
            )
            assert r.status_code == 403
            r = httpx.delete(f"http://localhost:2375/volumes/{volume_name}",
                             auth=("app_api_haproxy_user", "some_secure_password"))
            assert r.status_code == 403
    print("Autoban, invalid volume name:", i + 1)
    misc.initialize_container()


def test_invalid_auth():
    r = httpx.get("http://localhost:2375/_ping", auth=("app_api_haproxy_user1", "some_secure_password"))
    assert r.status_code == 401
    r = httpx.get("http://localhost:2375/_ping", auth=("app_api_haproxy_user", "some_secure_password1"))
    assert r.status_code == 401
    misc.initialize_container()


def test_autoban():
    client = httpx.Client(base_url="http://localhost:2375", auth=("app_api_haproxy_user", "some_secure_password1"))
    with pytest.raises(httpx.ReadTimeout):
        for i in range(7):
            client.get("_ping")
    print("Autoban, invalid auth:", i + 1)
    misc.initialize_container()


def test_autoban_invalid_url():
    client = httpx.Client(base_url="http://localhost:2375", auth=("app_api_haproxy_user", "some_secure_password"))
    with pytest.raises((httpx.ReadTimeout, httpx.RemoteProtocolError)):
        for i in range(11):
            client.get("_unknown")
    print("Autoban, invalid url:", i + 1)
    misc.initialize_container()
