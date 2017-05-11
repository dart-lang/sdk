// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void main() {
  List<int> o;
  int y = o. /*@typeArgs=int*/ /*@target=List::fold*/ fold(
      0,
      /*@returnType=int*/ (/*@type=int*/ x,
              /*@type=int*/ y) =>
          x /*@target=num::+*/ + y);
  var /*@type=dynamic*/ z =
      o. /*@typeArgs=dynamic*/ /*@target=List::fold*/ fold(
          0,
          /*@returnType=dynamic*/ (/*@type=dynamic*/ x,
              /*@type=int*/ y) => /*info:DYNAMIC_INVOKE*/ x + y);
  y = /*info:DYNAMIC_CAST*/ z;
}

void functionExpressionInvocation() {
  List<int> o;
  int y = (o.fold)(
      0,
      /*@returnType=int*/ (/*@type=int*/ x,
              /*@type=int*/ y) =>
          x /*@target=num::+*/ + y);
  var /*@type=dynamic*/ z = (o.fold)(
      0,
      /*@returnType=dynamic*/ (/*@type=dynamic*/ x,
          /*@type=int*/ y) => /*info:DYNAMIC_INVOKE*/ x + y);
  y = /*info:DYNAMIC_CAST*/ z;
}
