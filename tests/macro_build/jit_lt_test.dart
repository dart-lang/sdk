// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'tester/tester.dart';

void main() {
  testMacroBuild([
    r'$DART pub get',
    r'$DART '
        '--sound-null-safety '
        '-Dtest_runner.configuration=vm-linux-release-x64 '
        '--enable-experiment=macros '
        '--ignore-unrecognized-flags '
        '--packages=.dart_tool/package_config.json '
        'test/main.dart',
  ]);
}
