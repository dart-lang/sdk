// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Never never() => throw "Never";

class A<X extends Object, Y extends Object?> {
  X foo() => never();
  X? bar() => null;
  Y baz() => never();
}

class B<X extends List<Y>, Y extends Object?> {
  foo(X x, Y y) {}
}

class C<X extends List<Y>?, Y extends List<X>?> {
  foo(X x, Y y) {}
}

class D<X extends Y, Y extends Z, Z> {
  foo(X x, Y y, Z z) {}
}

main() {
  X fun1<X extends Object, Y extends Object?>() => never();
  Y fun2<X extends Object, Y extends Object?>() => never();
  X fun3<X extends List<Y>, Y extends Object?>() => never();
  Y fun4<X extends List<Y>, Y extends Object?>() => never();
  X fun5<X extends List<Y>?, Y extends List<X>?>() => never();
  Y fun6<X extends List<Y>?, Y extends List<X>?>() => never();
  X fun7<X extends Y, Y extends Z, Z>() => never();
  Y fun8<X extends Y, Y extends Z, Z>() => never();
  Z fun9<X extends Y, Y extends Z, Z>() => never();
}
