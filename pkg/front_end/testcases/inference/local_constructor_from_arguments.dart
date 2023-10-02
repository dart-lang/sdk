// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C<T> {
  T t;
  C(this.t);
}

test(dynamic y) {
  var /*@type=C<int>*/ x = new /*@typeArgs=int*/ C(42);

  C<int> c_int = new /*@typeArgs=int*/ C(/*info:DOWN_CAST_IMPLICIT*/ y);

  C<num> c_num = new /*@typeArgs=num*/ C(123);

  // Don't infer from explicit dynamic.
  var /*@type=C<dynamic>*/ c_dynamic = new C<dynamic>(42);
}
