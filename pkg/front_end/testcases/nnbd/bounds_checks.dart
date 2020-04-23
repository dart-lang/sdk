// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X extends num> {}

foo(A<num?> a) {} // Error

A<num?>? bar() {} // Error

baz<T extends A<num?>>() {} // Error

class B extends A<num?> {} // Error

class C<T extends A<num?>> {} // Error

void hest<T extends num>() {}

class Hest {
  void hest<T extends num>() {}
}

fisk(Hest h) {
  hest<num?>();
  h.hest<num?>();
}

main() {}
