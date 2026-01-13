// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for a compile-time crash in dart2wasm.
//
// The code is standard Dart, so the test is added to language/sync_star
// instead of web/wasm.

class C {
  final int value;

  final C next;

  C(this.value, this.next);

  Iterable<String> foo() sync* {
    yield value.toString();
    yield* next.foo();
  }
}

C cs = C(1, cs);

void main() {
  if (int.parse('1') == 0) {
    print(cs.foo().toList());
  }
}
