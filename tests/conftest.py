# SPDX-FileCopyrightText: 2023 Nextcloud GmbH and Nextcloud contributors
# SPDX-License-Identifier: AGPL-3.0-or-later

import pytest
import misc


@pytest.fixture(scope="session", autouse=True)
def execute_before_any_test():
    misc.initialize_container()
