// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class C<T> {
  T t;
  C(this.t);
}

test(num y) {
  var x = new C(42);

  C<int> c_int = new C(/*info:DOWN_CAST_IMPLICIT*/ y);

  // These hints are not reported because we resolve with a null error listener.
  C<num> c_num = new C(123);
  C<num> c_num2 = (new C(456))..t = 1.0;

  // Don't infer from explicit dynamic.
  var c_dynamic = new C<dynamic>(42);
  x.t = /*error:INVALID_ASSIGNMENT*/ 'hello';
}

main() {}
