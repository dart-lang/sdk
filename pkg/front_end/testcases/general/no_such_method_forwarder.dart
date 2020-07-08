// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class X {
  void _foo() async {
    await null;
    print("hello");
  }

  void foo() => _foo();
}

class Y implements X {
  void noSuchMethod(Invocation _) {
    print("Hello from noSuchMethod");
  }
}

main() {
  Y y = new Y();
  y.foo();
}