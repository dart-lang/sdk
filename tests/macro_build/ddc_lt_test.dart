// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'tester/tester.dart';

void main() {
  testMacroBuild([
    r'$DART pub get',
    r'$DART '
        r'$DART_SDK_OUT/dart-sdk/bin/snapshots/dartdevc.dart.snapshot '
        '-Dtest_runner.configuration=ddc-linux-chrome '
        '--enable-experiment=macros '
        '--sound-null-safety '
        '-Dtest_runner.configuration=ddc-linux-chrome '
        '--ignore-unrecognized-flags '
        '--no-summarize '
        '-o out.js '
        'test/main.dart '
        r'-s $DART_SDK_OUT/gen/utils/ddc/expect_outline.dill=expect '
        r'-s $DART_SDK_OUT/gen/utils/ddc/js_outline.dill=js '
        r'-s $DART_SDK_OUT/gen/utils/ddc/meta_outline.dill=meta',
    // Running out.js is nontrivial, just check if it contains the getter
    // that the macro is supposed to add.
    r'grep -q return$SPACE"OK" out.js',
  ]);
}
