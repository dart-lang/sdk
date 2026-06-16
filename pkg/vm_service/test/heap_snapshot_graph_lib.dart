// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

class Foo {
  @pragma('vm:entry-point')
  dynamic left;
  @pragma('vm:entry-point')
  dynamic right;
}

late Foo r;

late List lst;

void script() {
  // Create 3 instances of Foo, with out-degrees
  // 0 (for b), 1 (for a), and 2 (for staticFoo).
  r = Foo();
  final a = Foo();
  final b = Foo();
  r.left = a;
  r.right = b;
  a.left = b;

  lst = List.filled(2, null);
  lst[0] = lst; // Self-loop.
  // Larger than any other fixed-size list in a fresh heap.
  lst[1] = List.filled(1234569, null);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: script);
}
