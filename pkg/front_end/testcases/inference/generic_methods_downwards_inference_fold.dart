// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void main() {
  List<int> o;
  int y = /*@promotedType=none*/ o.fold(
      0,
      /*@returnType=int*/ (/*@type=int*/ x,
          /*@type=int*/ y) => /*@promotedType=none*/ x + /*@promotedType=none*/ y);
  var /*@type=dynamic*/ z = /*@promotedType=none*/ o.fold(
      0,
      /*@returnType=dynamic*/ (/*@type=dynamic*/ x,
          /*@type=int*/ y) => /*info:DYNAMIC_INVOKE*/ /*@promotedType=none*/ x + /*@promotedType=none*/ y);
  y = /*info:DYNAMIC_CAST*/ /*@promotedType=none*/ z;
}

void functionExpressionInvocation() {
  List<int> o;
  int y = (/*@promotedType=none*/ o.fold)(
      0,
      /*@returnType=int*/ (/*@type=int*/ x,
          /*@type=int*/ y) => /*@promotedType=none*/ x + /*@promotedType=none*/ y);
  var /*@type=dynamic*/ z = (/*@promotedType=none*/ o.fold)(
      0,
      /*@returnType=dynamic*/ (/*@type=dynamic*/ x,
          /*@type=int*/ y) => /*info:DYNAMIC_INVOKE*/ /*@promotedType=none*/ x + /*@promotedType=none*/ y);
  y = /*info:DYNAMIC_CAST*/ /*@promotedType=none*/ z;
}
