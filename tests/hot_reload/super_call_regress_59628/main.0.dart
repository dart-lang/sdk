// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Regression test for https://github.com/dart-lang/sdk/issues/59628.

class A {
  method() {
    return 'A.method';
  }
}

class B extends A {
  method() {
    return '${super.method()} - B.method';
  }
}

String unrelatedChange() => 'before';

Future<void> main() async {
  Expect.equals('before', unrelatedChange());
  var b = B();
  Expect.equals('A.method - B.method', b.method());
  await hotReload();
  Expect.equals('after', unrelatedChange());
  Expect.equals('A.method - B.method', b.method());
}
