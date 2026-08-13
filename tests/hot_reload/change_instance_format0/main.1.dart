// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/1a486499bf73ee5b007abbe522b94869a1f36d02/runtime/vm/isolate_reload_test.cc#L3806

// Tests reload succeeds when instance format changes.
// Change: Foo {a, b, c:42}  -> Foo {c:42}
// Validate: c keeps the value in the retained Foo object.

class Foo {
  var c;
}

var f;

Future<void> main() async {
  f = Foo();
  f.c = 42;
  Expect.equals(42, f.c);
  await hotReload();

  Expect.equals(42, f.c);
}

/** DIFF **/
/*
 // Validate: c keeps the value in the retained Foo object.
 
 class Foo {
-  var a;
-  var b;
   var c;
 }
 
*/
