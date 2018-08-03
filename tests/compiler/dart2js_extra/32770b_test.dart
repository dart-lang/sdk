// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--strong

// Regression test for issue 32770.

import 'package:expect/expect.dart';

dynamic f;
dynamic g;

class A {}

class B extends A {}

class C extends A {}

class Class<T> {
  void Function(E) method<E, F extends E>(bool Function(bool) callback) {
    return (E event) {
      g = () => callback(event is F);
    };
  }
}

main() {
  f = new Class<String>().method<A, B>((o) => o);
  f(new B());
  Expect.isTrue(g());
  f(new C());
  Expect.isFalse(g());
}
