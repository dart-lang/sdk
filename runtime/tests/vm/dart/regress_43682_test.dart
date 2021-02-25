// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic --optimization_counter_threshold=20

// Verifies that SSA construction doesn't crash when handling a Phi
// corresponding to an expression temp in case of OSR with non-empty
// expression stack.
// Regression test for https://github.com/dart-lang/sdk/issues/43682.

import 'package:expect/expect.dart';

class Foo {
  List<Object> data;
  Foo(this.data);
}

Map<String, Foo> foo(List<Object> objects) {
  Map<String, Foo> map = {};
  // OSR happens during '...objects' spread, and Foo instance is already
  // allocated and remains on the stack during OSR.
  // OSR Phi corresponding to that value is stored into 'foo' local and
  // then loaded from it, but it doesn't correspond to 'foo' environment slot.
  final foo = new Foo([...objects]);
  map['hi'] = foo;
  return map;
}

main() {
  Expect.equals(30, foo(List.filled(30, Object()))['hi']!.data.length);
}
