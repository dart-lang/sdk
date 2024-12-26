// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/f34a2ed99fc1b34cedbd974a5801f8d922121126/runtime/vm/isolate_reload_test.cc#L1804

class C {
  foo() => 'old';
}

List list = List<dynamic>.filled(2, null);
Set set = Set();

Future<void> main() async {
  var c = C();
  list[0] = c.foo;
  list[1] = c.foo;
  set.add(c.foo);
  set.add(c.foo);
  int countBefore = set.length;
  await hotReload();

  list[1] = c.foo;
  set.add(c.foo);
  set.add(c.foo);
  int countAfter = set.length;

  Expect.equals('new', list[0]());
  Expect.equals('new', list[1]());
  Expect.equals(list[0], list[1]);
  Expect.notIdentical(list[0], list[1]);
  Expect.equals(1, countBefore);
  Expect.equals(1, countAfter);
  Expect.equals('new', (set.first)());
  Expect.equals(set.first, c.foo);
  Expect.equals(set.first, c.foo);
  Expect.notIdentical(set.first, c.foo);
  set.remove(c.foo);
  Expect.isEmpty(set);
}
