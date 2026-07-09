// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/13f5fc6b168d8b6e5843d17fb9ba77f1343a7dfe/runtime/vm/isolate_reload_test.cc#L5209

// When an initializer expression has a syntax error, we detect it at reload
// time.

class Foo {
  int x = 4;
}

late Foo value;
helper() {
  value = Foo();
  return value.x;
}

Future<void> main() async {
  Expect.equals(4, helper());
  // Add the field y with a syntax error in the initializing expression.
  // The reload fails because the initializing expression is parsed at
  // class finalization time.
  await hotReload(expectRejection: true);
}
