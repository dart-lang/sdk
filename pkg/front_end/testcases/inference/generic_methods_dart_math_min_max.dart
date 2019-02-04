// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference,error*/
library test;

import 'dart:math';

void printInt(int x) => print(x);
void printDouble(double x) => print(x);

num myMax(num x, num y) =>
    /*@typeArgs=num*/ max(x, y);

f() {
  // Okay if static types match.
  printInt(/*@typeArgs=int*/ max(1, 2));
  printInt(/*@typeArgs=int*/ min(1, 2));
  printDouble(/*@typeArgs=double*/ max(1.0, 2.0));
  printDouble(/*@typeArgs=double*/ min(1.0, 2.0));

  // No help for user-defined functions from num->num->num.
  printInt(myMax(1, 2));
  printInt(myMax(1, 2) as int);

  printInt(
      /*@typeArgs=int*/ max(1, /*@error=ArgumentTypeNotAssignable*/ 2.0));
  printInt(
      /*@typeArgs=int*/ min(1, /*@error=ArgumentTypeNotAssignable*/ 2.0));
  printDouble(
      /*@typeArgs=double*/ max(1, 2.0));
  printDouble(
      /*@typeArgs=double*/ min(1, 2.0));

  // Types other than int and double are not accepted.
  printInt(/*@typeArgs=int*/ min(
      /*@error=ArgumentTypeNotAssignable*/ "hi",
      /*@error=ArgumentTypeNotAssignable*/ "there"));
}

main() {}
