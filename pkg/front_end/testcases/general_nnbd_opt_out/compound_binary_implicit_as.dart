// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

class A {}

class B extends A {
  A operator +(B b) => new C();
}

class C extends A {}

main() {
  Map<int, B> map = {0: new B()};
  try {
    map[0] += new B();
    throw 'Expected type error';
  } catch (_) {}
}
