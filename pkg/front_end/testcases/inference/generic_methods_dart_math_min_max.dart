// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:math';

void printInt(int x) => print(x);
void printDouble(double x) => print(x);

num myMax(num x, num y) => max(x, y);

main() {
  // Okay if static types match.
  printInt(max(1, 2));
  printInt(min(1, 2));
  printDouble(max(1.0, 2.0));
  printDouble(min(1.0, 2.0));

  // No help for user-defined functions from num->num->num.
  printInt(/*info:DOWN_CAST_IMPLICIT*/ myMax(1, 2));
  printInt(myMax(1, 2) as int);

  // Mixing int and double means return type is num.
  printInt(max(1, /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 2.0));
  printInt(min(1, /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 2.0));
  printDouble(max(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 1, 2.0));
  printDouble(min(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ 1, 2.0));

  // Types other than int and double are not accepted.
  printInt(min(
      /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ "hi",
      /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ "there"));
}
