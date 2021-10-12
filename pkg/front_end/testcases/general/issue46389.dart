// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  num foo(int n) {
    print(n.runtimeType); // 'double'
    return 1.1;
  }

  num bar({required int x}) {
    print(x.runtimeType); // 'double'
    return 1.1;
  }

  void set baz(int x) {
    print(x.runtimeType); // 'double'
  }

  int boz = 0;
}

abstract class B<X> {
  X foo(X x);
  X bar({required X x});
  void set baz(X x);
  void set boz(X x);
}

class C extends A with B<num> {}

void main() {
  C a = C();
  a.foo(1);
  throws(() => a.foo(1.2));
  a.bar(x: 1);
  throws(() => a.bar(x: 1.2));
  a.baz = 1;
  throws(() => a.baz = 1.2);
  a.boz = 1;
  throws(() => a.boz = 1.2);
}

throws(void Function() f) {
  try {
    f();
  } catch (e) {
    print(e);
    return;
  }
  throw 'Exception expected';
}
