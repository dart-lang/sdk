// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/be2aabd91c67f7f331c49cb74e18fe5e469f04db/runtime/vm/isolate_reload_test.cc#L2371

enum Fruit { Apple, Banana }

var retained;

Future<void> main() async {
  retained = Fruit.Banana;
  await hotReload();
  Expect.equals('Fruit.Deleted enum value from Fruit', retained.toString());
}
