// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/63622f03eeaf72983b2f4957fa84da8062693f00/runtime/vm/isolate_reload_test.cc#L5448

class C {
  static var x = 42;
}

Future<void> main() async {
  Expect.equals(42, C.x);
  Expect.equals(0, hotReloadGeneration);

  await hotReload();

  // Newly loaded field maintained old static value
  Expect.equals(42, C.x);
  Expect.equals(1, hotReloadGeneration);

  await hotReload();

  // Newly loaded field maintained old static value
  Expect.equals(42, C.x);
  Expect.equals(2, hotReloadGeneration);
}
