// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'tester/tester.dart';

void main() {
  testMacroBuild([
    r'$DART pub get',
    r'$DART '
        r'$DART_SDK_OUT/gen/dartanalyzer.dart.snapshot '
        '-Dtest_runner.configuration=analyzer-asserts-linux '
        '--enable-experiment=macros '
        '--ignore-unrecognized-flags '
        '--packages=.dart_tool/package_config.json '
        '--format=json test/main.dart ',
    // Analysis passed; there isn't any other output to verify.
  ]);
}
