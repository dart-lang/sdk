// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

var /*@topType=dynamic*/ h = null;
void foo(int f(Object _)) {}

main() {
  var /*@type=(Object) -> Null*/ f = /*@returnType=Null*/ (Object x) {
    return null;
  };
  String y = f(42);

  f = /*error:INVALID_CAST_FUNCTION_EXPR*/ /*@returnType=String*/ (/*@type=Object*/ x) =>
      'hello';

  foo(/*@returnType=Null*/ (/*@type=Object*/ x) {
    return null;
  });
  foo(/*@returnType=Null*/ (/*@type=Object*/ x) {
    throw "not implemented";
  });
}
