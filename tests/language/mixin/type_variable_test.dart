// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for generic mixin fields.

mixin class A<T> {
  T? field;
}

class B<T> = Object with A<T>;

class C<T> extends B<T> {}
class D extends B<int> {}

class E = Object with A<int>;

class F extends E {}

class G<T> extends Object with A<T> {}
class H extends Object with A<int> {}

void main() {
  new A<num>();
  new B<num>();
  new C<num>();
  new D();
  new E();
  new F();
  new G<num>();
  new H();
}
