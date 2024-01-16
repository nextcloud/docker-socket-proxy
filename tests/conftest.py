import pytest
import misc


@pytest.fixture(scope="session", autouse=True)
def execute_before_any_test():
    misc.initialize_container()
