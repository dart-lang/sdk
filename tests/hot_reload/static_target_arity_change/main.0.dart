// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/a70adce28e53ff8bb3445fe96f3f1be951d8a417/runtime/vm/isolate_reload_test.cc#L6070

class A {
  final x;
  final y;
  const A(this.x, this.y);
}

dynamic closure;

helper() {
  closure = () => A(1, 2);
  return 'okay';
}

Future<void> main() async {
  Expect.equals('okay', helper());
  Expect.equals(0, hotReloadGeneration);

  await hotReload();

  // Call the old closure, which will try to call A(1, 2).
  Expect.throws<NoSuchMethodError>(closure);
  Expect.equals(1, hotReloadGeneration);
}
