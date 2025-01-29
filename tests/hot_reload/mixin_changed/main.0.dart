// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/1a486499bf73ee5b007abbe522b94869a1f36d02/runtime/vm/isolate_reload_test.cc#L917

mixin Mixin1 {
  var field = 'mixin1';
  func() => 'mixin1';
}

class B extends Object with Mixin1 {}

Future<void> main() async {
  var saved = B();
  Expect.equals('mixin1', saved.field);
  Expect.equals('mixin1', saved.func());
  await hotReload();

  // The saved instance of B retains its old field value from mixin1,
  // but it gets the new implementation of func from mixin2.
  var newer = B();
  Expect.equals('mixin1', saved.field);
  Expect.equals('mixin2', saved.func());
  Expect.equals('mixin2', newer.field);
  Expect.equals('mixin2', newer.func());
}
