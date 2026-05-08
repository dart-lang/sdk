// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for a compile-time crash in dart2wasm.
//
// The code is standard Dart, so the test is added to language/ instead of
// web/wasm.

main() {
  Foo? f;
  if (int.parse('1') == 0) {
    f = foo;
  }
  final fun = f?.getClosure();
  if (fun != null) {
    // After TFA this becomes a direct closure call to `Foo.getClosure.inner`,
    // but `Foo.getClosure` is unreachable as `Foo` can't be instantiated.
    fun();
  }
}

late final Foo foo = Foo(foo);

class Foo {
  final Foo next;

  Foo(this.next);

  void Function() getClosure() {
    void inner() async {
      print('inner');
      print(this);
      print(next);
    }

    return inner;
  }
}
