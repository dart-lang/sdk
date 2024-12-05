// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  void bar(int x) => print(x);
}

class B extends A {
  Future<void> foo() async {
    // Ensure the async lowering does not try to assign "super" to a temp.
    super.bar(await 3);
  }
}

Future<void> main() async {
  await B().foo();
}
