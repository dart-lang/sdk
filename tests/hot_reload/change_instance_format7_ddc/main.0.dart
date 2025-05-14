// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/1a486499bf73ee5b007abbe522b94869a1f36d02/runtime/vm/isolate_reload_test.cc#L4051

// Tests reload succeeds when type parameters are changed for allocated class.
// Change: Foo<A,B> {a, b} -> Foo<A> {a}
// Validate: return value from main is correct.
// This test is rejected at compile-time in DDC (vs at runtime for the VM).

class Foo<A, B> {
  var a;
  var b;
}

Future<void> main() async {
  await hotReload(expectRejection: true);
}
