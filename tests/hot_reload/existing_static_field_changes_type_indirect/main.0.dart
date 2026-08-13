// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/bf2fba78e006ce4feac43e514c0b8f3ea9e9fbb8/runtime/vm/isolate_reload_test.cc#L5757

class A {}

class B extends A {}

init() => new B();

A value = init();

helper() {
  try {
    return value.toString();
  } catch (e) {
    return e.toString();
  }
}

Future<void> main() async {
  Expect.equals("Instance of 'B'", helper());
  Expect.equals(0, hotReloadGeneration);

  await hotReload();

  Expect.contains("type 'B' is not a subtype of type 'A'", helper());
  Expect.equals(1, hotReloadGeneration);
}
