// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

main() {
  num n = 1;
  int i = 1;
  double d = 1.0;

  // (double, double) -> double
  var /*@type=double*/ ddPlus = d /*@target=double::+*/ + d;
  var /*@type=double*/ ddMinus = d /*@target=double::-*/ - d;
  var /*@type=double*/ ddTimes = d /*@target=double::**/ * d;
  var /*@type=double*/ ddMod = d /*@target=double::%*/ % d;

  // (double, int) -> double
  var /*@type=double*/ diPlus = d /*@target=double::+*/ + i;
  var /*@type=double*/ diMinus = d /*@target=double::-*/ - i;
  var /*@type=double*/ diTimes = d /*@target=double::**/ * i;
  var /*@type=double*/ diMod = d /*@target=double::%*/ % i;

  // (double, num) -> double
  var /*@type=double*/ dnPlus = d /*@target=double::+*/ + n;
  var /*@type=double*/ dnMinus = d /*@target=double::-*/ - n;
  var /*@type=double*/ dnTimes = d /*@target=double::**/ * n;
  var /*@type=double*/ dnMod = d /*@target=double::%*/ % n;

  // (int, double) -> double
  var /*@type=double*/ idPlus = i /*@target=num::+*/ + d;
  var /*@type=double*/ idMinus = i /*@target=num::-*/ - d;
  var /*@type=double*/ idTimes = i /*@target=num::**/ * d;
  var /*@type=double*/ idMod = i /*@target=num::%*/ % d;

  // (int, int) -> int
  var /*@type=int*/ iiPlus = i /*@target=num::+*/ + i;
  var /*@type=int*/ iiMinus = i /*@target=num::-*/ - i;
  var /*@type=int*/ iiTimes = i /*@target=num::**/ * i;
  var /*@type=int*/ iiMod = i /*@target=num::%*/ % i;

  // (int, num) -> num
  var /*@type=num*/ inPlus = i /*@target=num::+*/ + n;
  var /*@type=num*/ inMinus = i /*@target=num::-*/ - n;
  var /*@type=num*/ inTimes = i /*@target=num::**/ * n;
  var /*@type=num*/ inMod = i /*@target=num::%*/ % n;

  // (num, double) -> num
  var /*@type=num*/ ndPlus = n /*@target=num::+*/ + d;
  var /*@type=num*/ ndMinus = n /*@target=num::-*/ - d;
  var /*@type=num*/ ndTimes = n /*@target=num::**/ * d;
  var /*@type=num*/ ndMod = n /*@target=num::%*/ % d;

  // (num, int) -> num
  var /*@type=num*/ niPlus = n /*@target=num::+*/ + i;
  var /*@type=num*/ niMinus = n /*@target=num::-*/ - i;
  var /*@type=num*/ niTimes = n /*@target=num::**/ * i;
  var /*@type=num*/ niMod = n /*@target=num::%*/ % i;

  // (num, num) -> num
  var /*@type=num*/ nnPlus = n /*@target=num::+*/ + n;
  var /*@type=num*/ nnMinus = n /*@target=num::-*/ - n;
  var /*@type=num*/ nnTimes = n /*@target=num::**/ * n;
  var /*@type=num*/ nnMod = n /*@target=num::%*/ % n;
}
