// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for a compile-time crash in dart2wasm.
//
// The code is standard Dart, so the test is added to language/ instead of
// web/wasm.

class Foo {
  final Foo next;
  Foo(this.next);
}

final Foo global = Foo(global);

bool get runtimeFalse => int.parse('1') == 0;

void test() {
  Foo foo;
  if (runtimeFalse) {
    foo = global;
  } else {
    throw 'error';
  }
  print(foo);
  print(foo.next);
}

void main() {
  try {
    test();
  } catch (e) {}
}
