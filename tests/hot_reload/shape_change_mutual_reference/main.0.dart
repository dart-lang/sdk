// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/13f5fc6b168d8b6e5843d17fb9ba77f1343a7dfe/runtime/vm/isolate_reload_test.cc#L4140

class A {
  var x;
  get yourself => this;
}

var retained1;
var retained2;

Future<void> main() async {
  retained1 = new A();
  retained2 = new A();
  retained1.x = retained2;
  retained2.x = retained1;
  Expect.identical(retained1.x.yourself, retained2);
  Expect.identical(retained2.x.yourself, retained1);

  await hotReload();
}
