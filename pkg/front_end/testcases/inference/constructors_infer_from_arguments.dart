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
  var /*@type=C<int>*/ x = new /*@typeArgs=int*/ C(42);

  num y;
  C<int> c_int = new /*@typeArgs=int*/ C(
      /*info:DOWN_CAST_IMPLICIT*/ y);

  // These hints are not reported because we resolve with a null error listener.
  C<num> c_num = new /*@typeArgs=num*/ C(123);
  C<num> c_num2 = (new /*@typeArgs=num*/ C(456)).. /*@target=C::t*/ t = 1.0;

  // Down't infer from explicit dynamic.
  var /*@type=C<dynamic>*/ c_dynamic = new C<dynamic>(42);
  x. /*@target=C::t*/ t = /*error:INVALID_ASSIGNMENT*/ 'hello';
}
