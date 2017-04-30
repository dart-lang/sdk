// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C<T> {
  T t;
  C(this.t);
}

main() {
  var /*@type=C<int>*/ x = /*@typeArgs=int*/ new C(42);

  num y;
  C<int> c_int = /*@typeArgs=int*/ new C(
      /*info:DOWN_CAST_IMPLICIT*/ /*@promotedType=none*/ y);

  // These hints are not reported because we resolve with a null error listener.
  C<num> c_num = /*@typeArgs=num*/ new C(123);
  C<num> c_num2 = (/*@typeArgs=num*/ new C(456))..t = 1.0;

  // Down't infer from explicit dynamic.
  var /*@type=C<dynamic>*/ c_dynamic = new C<dynamic>(42);
  /*@promotedType=none*/ x.t = /*error:INVALID_ASSIGNMENT*/ 'hello';
}
