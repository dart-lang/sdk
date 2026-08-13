// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for a compile-time crash in dart2wasm.
//
// The code is standard Dart, so the test is added to language/async instead of
// web/wasm.

class C {
  final int value;

  final C next;

  C(this.value, this.next);

  @override
  String toString() {
    return "$value -> $next";
  }

  void foo() async {
    await Future.delayed(Duration(seconds: 1));
    int.parse('1') == 1 ? await Future.delayed(Duration(seconds: 1)) : ();
    print(this);
  }
}

C cs = C(1, cs);

void main() {
  if (int.parse('1') == 0) {
    cs.foo();
  }
}
