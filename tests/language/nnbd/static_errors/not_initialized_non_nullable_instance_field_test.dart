// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Test that it is an error if an instance field with potentially non-nullable
// type has no initializer expression and is not initialized in a constructor
// via an initializing formal or an initializer list entry, unless the field is
// marked with the `late` modifier.
void main() {}

class A {
  int v = 0; //# 01: ok
  int? v; //# 02: ok
  int? v = 0; //# 03: ok
  dynamic v; //# 04: ok
  var v; //# 05: ok
  void v; //# 06: ok

  int v; A(this.v); //# 07: ok

  int v; A() : v = 0; //# 08: ok

  int v; //# 09: compile-time error

  Never v; //# 10: compile-time error

  int v; A(); //# 11: compile-time error

  int v; A(this.v); A.second(); //# 12: compile-time error
}

class B<T> {
  T v; //# 13: compile-time error

  T? v; //# 14: ok

  T v; B(this.v); //# 15: ok
}
