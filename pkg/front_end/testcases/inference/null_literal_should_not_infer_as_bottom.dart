// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

var /*@topType=dynamic*/ h = null;
void foo(int f(Object _)) {}

main() {
  var /*@type=(Object) -> dynamic*/ f = /*@returnType=dynamic*/ (Object x) =>
      null;
  String y = /*info:DYNAMIC_CAST*/ f(42);

  f = /*@returnType=String*/ (/*@type=Object*/ x) => 'hello';

  var /*@type=dynamic*/ g = null;
  g = 'hello';
  (/*info:DYNAMIC_INVOKE*/ g.foo());

  h = 'hello';
  (/*info:DYNAMIC_INVOKE*/ h.foo());

  foo(/*@returnType=int*/ (/*@type=Object*/ x) => null);
  foo(/*@returnType=<BottomType>*/ (/*@type=Object*/ x) =>
      throw "not implemented");
}
