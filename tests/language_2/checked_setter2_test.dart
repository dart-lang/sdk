// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that implicit setters do a type check generic types.

class A {
  C<int> c;
}

class B extends A {}

class C<T> {}

var array = [new B()];

main() {
  array[0].c = new C();
  array[0].c = /*@compile-error=unspecified*/new C<bool>();
}
