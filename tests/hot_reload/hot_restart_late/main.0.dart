// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

late String noInitializer;
late int withInitializer = 1;

class Lates {
  static late String noInitializer;
  static late int withInitializer = 2;
}

class LatesGeneric<T> {
  static late String noInitializer;
  static late int withInitializer = 3;
}

Future<void> main() async {
  // Set uninitialized static late fields. Avoid calling getters for these
  // statics to ensure they are reset even if they are never accessed.
  noInitializer = 'set via setter';
  Lates.noInitializer = 'Lates set via setter';
  LatesGeneric.noInitializer = 'LatesGeneric set via setter';

  // Initialized statics should contain their values.
  Expect.equals(1, withInitializer);
  Expect.equals(2, Lates.withInitializer);
  Expect.equals(3, LatesGeneric.withInitializer);

  await hotRestart();
}
