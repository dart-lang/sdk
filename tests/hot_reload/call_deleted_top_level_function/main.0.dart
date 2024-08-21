// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/bf2fba78e006ce4feac43e514c0b8f3ea9e9fbb8/runtime/vm/isolate_reload_test.cc#L2597

deleted() {
  return 'hello';
}

var retained;

helper() {
  retained = () => deleted();
  return retained();
}

Future<void> main() async {
  Expect.equals('hello', helper());
  Expect.equals(0, hotReloadGeneration);

  await hotReload();

  Expect.contains('NoSuchMethodError', helper());
  Expect.contains('deleted', helper());
  Expect.equals(1, hotReloadGeneration);
}
