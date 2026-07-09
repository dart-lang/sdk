// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/1a486499bf73ee5b007abbe522b94869a1f36d02/runtime/vm/isolate_reload_test.cc#L3948

// Tests reload succeeds when instance format changes.
// Change: Bar {c:42}, Foo : Bar {d, e} -> Foo {c:42}
// In the VM: c keeps the value in the retained Foo object.
// For DDC: c adopts the value in the newly declared field in Bar.

class Bar {
  var c;
}

class Foo extends Bar {
  var d;
  var e;
}

var f;

Future<void> main() async {
  f = Foo();
  f.c = 42;
  Expect.equals(42, f.c);
  await hotReload();

  if (isVmRuntime) {
    Expect.equals(42, f.c);
  } else if (isDdcRuntime) {
    Expect.isNull(f.c);
  }
}
