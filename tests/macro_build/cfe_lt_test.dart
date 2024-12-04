// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'tester/tester.dart';

void main() {
  testMacroBuild([
    r'$DART pub get',
    r'$DART '
        r'$DART_SDK/pkg/front_end/tool/compile.dart '
        '--verify '
        '--skip-platform-verification -o out.dill '
        '--platform '
        r'$DART_SDK_OUT/vm_platform_strong.dill '
        '-Dtest_runner.configuration=cfe-strong-linux '
        '--enable-experiment=macros '
        '--nnbd-strong '
        '--packages=.dart_tool/package_config.json '
        'test/main.dart',
    r'$DART out.dill',
  ]);
}
