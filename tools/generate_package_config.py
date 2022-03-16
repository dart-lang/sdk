#!/usr/bin/env python3
# Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Invoke the `tools/generate_package_config.dart` script.

# NOTE(devoncarew): This script is currently a no-op in order to facilitate us
# landing the package_config generation changes through flutter/engine. Once
# generate_package_config.py exists in flutter/engine, we'll update that repo's
# DEPS file to call this script, and then land the full package_config changes
# in dart-lang/sdk.

USE_PYTHON3 = True


def Main():
    print('generate_package_config.py called')


if __name__ == '__main__':
    Main()
