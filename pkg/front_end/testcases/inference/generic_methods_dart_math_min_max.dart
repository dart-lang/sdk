// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:math';

void printInt(int x) => print(x);
void printDouble(double x) => print(x);

num myMax(num x, num y) => max(x, y);

f() {
  // Okay if static types match.
  printInt(max(1, 2));
  printInt(min(1, 2));
  printDouble(max(1.0, 2.0));
  printDouble(min(1.0, 2.0));

  // No help for user-defined functions from num->num->num.
  printInt(myMax(1, 2));
  printInt(myMax(1, 2) as int);

  printInt(max(1, 2.0));
  printInt(min(1, 2.0));
  printDouble(max(1, 2.0));
  printDouble(min(1, 2.0));

  // Types other than int and double are not accepted.
  printInt(min("hi", "there"));
}

main() {}
