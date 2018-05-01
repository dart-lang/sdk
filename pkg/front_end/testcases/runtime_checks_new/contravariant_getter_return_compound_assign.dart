// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef void F<T>(T x);

class B<T> {
  B<T> operator +(B<T> /*@covariance=genericInterface, genericImpl*/ other) =>
      null;
}

class C<T> {
  B<F<T>> get x => null;
  void set x(B<F<T>> value) {}
}

void test(C<num> c) {
  c. /*@checkReturn=B<(num) -> void>*/ x += new B<num>();
  var y = c. /*@checkReturn=B<(num) -> void>*/ x += new B<num>();
  c. /*@checkReturn=B<(num) -> void>*/ x ??= new B<num>();
  var z = c. /*@checkReturn=B<(num) -> void>*/ x ??= new B<num>();
}

main() {}
