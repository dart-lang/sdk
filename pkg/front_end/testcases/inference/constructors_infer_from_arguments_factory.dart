// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class C<T> {
  T? t;

  C._();

  factory C(T t) {
    var x = new C<T>._();
    x.t = t;
    return x;
  }
}

test() {
  var x = new C(42);
  x.t = /*error:INVALID_ASSIGNMENT*/ 'hello';
}

main() {}
