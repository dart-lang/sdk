// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/c0819ff165a2557e6537700363594f2ddaf2a96e/runtime/vm/isolate_reload_test.cc#L3226

var retained;

class C {
  C.deleted();
}

helper() {
  retained = () => C.deleted().toString();
  return retained();
}

Future<void> main() async {
  helper();
  await hotReload();
  Expect.throws<NoSuchMethodError>(
    helper,
    (error) => '$error'.contains('deleted'),
  );
}
