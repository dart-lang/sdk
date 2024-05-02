// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/36c0788137d55c6c77f4b9a8be12e557bc764b1c/runtime/vm/isolate_reload_test.cc#L395

init() => 'old value';
var value = init();

Future<void> main() async {
  Expect.equals('old value', init());
  Expect.equals('old value', value);

  await hotReload();

  Expect.equals('new value', init());
  Expect.equals('old value', value);
}
