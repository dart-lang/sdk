// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'tester/tester.dart';

void main() {
  testMacroBuild([
    r'$DART pub get',
    r'$DART compile jit-snapshot '
        '--enable-experiment=macros '
        '-o out.jit '
        'test/main.dart',
    r'$DART run out.jit',
  ]);
}
