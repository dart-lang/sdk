// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {
  T field;
}

class B<T> {
  T field = 42; //# 01: compile-time error
}

class C<T> {
  T field = 42; //# 02: compile-time error
}

main() {
  var a = new A<String>();
  var c = new C<int>();
  var i = 42;
  var s = 'foo';
  a.field = i; //# 03: compile-time error
}
