// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {
  const A();
}

class B<S, T> {
  const B();
}

class C<T extends num> {
  const C();
}

class D<S extends num, T extends S> {
  const D();
}

@A<int, num>() // error
@B<int>() // error
@C<String>() // error
@D<int, num>() // error
test() {}

@A() // ok
@A<int>() // ok
@B() // ok
@B<int, String>() // ok
@C() // ok
@C<num>() // ok
@C<int>() // ok
@D() // ok
@D<num, num>() // ok
@D<num, int>() // ok
main() {}