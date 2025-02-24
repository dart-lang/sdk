// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/13f5fc6b168d8b6e5843d17fb9ba77f1343a7dfe/runtime/vm/isolate_reload_test.cc#L3041

var retained;

first(flag) {
  if (flag) throw 'first!';
}

class C {
  static deleted(_) {
    return 'hello';
  }
}

helper() {
  retained = (bool flag) => C.deleted(first(flag));
  return retained(false);
}

Future<void> main() async {
  helper();
  await hotReload();
  Expect.throws(helper, (error) => '$error'.contains('first!'));
}
