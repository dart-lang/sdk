// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

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

  C<num> c_num = /*@typeArgs=num*/ new C(123);

  // Don't infer from explicit dynamic.
  var /*@type=C<dynamic>*/ c_dynamic = new C<dynamic>(42);
}
