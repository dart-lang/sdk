// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

typedef void F<T>(T x);

class B<T> {
  B<T> operator +(B<T> other) => throw '';
}

class C<T> {
  B<F<T>> get x => throw '';
  void set x(B<F<T>> value) {}
  B<F<T>>? get x2 => null;
  void set x2(B<F<T>>? value) {}
}

void test(C<num> c) {
  c.x += new B<num>();
  var y = c.x += new B<num>();
  c.x2 ??= new B<num>();
  var z = c.x2 ??= new B<num>();
}

main() {}
