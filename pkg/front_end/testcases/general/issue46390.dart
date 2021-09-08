// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  num foo(num n) {
    print(n.runtimeType);
    return 1.1;
  }
}

abstract class B<X> {
  X foo(X x);
}

class C extends A with B<num> {}

void main() {
  B<Object> b = C();
  try {
    b.foo(true);
  } catch (e) {
    print(e);
    return;
  }
  throw 'Missing type error';
}
