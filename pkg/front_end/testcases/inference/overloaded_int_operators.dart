// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

main() {
  num n = 1;
  int i = 1;
  double d = 1.0;

  // (double, double) -> double
  var ddPlus = d + d;
  var ddMinus = d - d;
  var ddTimes = d * d;
  var ddMod = d % d;

  // (double, int) -> double
  var diPlus = d + i;
  var diMinus = d - i;
  var diTimes = d * i;
  var diMod = d % i;

  // (double, num) -> double
  var dnPlus = d + n;
  var dnMinus = d - n;
  var dnTimes = d * n;
  var dnMod = d % n;

  // (int, double) -> double
  var idPlus = i + d;
  var idMinus = i - d;
  var idTimes = i * d;
  var idMod = i % d;

  // (int, int) -> int
  var iiPlus = i + i;
  var iiMinus = i - i;
  var iiTimes = i * i;
  var iiMod = i % i;

  // (int, num) -> num
  var inPlus = i + n;
  var inMinus = i - n;
  var inTimes = i * n;
  var inMod = i % n;

  // (num, double) -> num
  var ndPlus = n + d;
  var ndMinus = n - d;
  var ndTimes = n * d;
  var ndMod = n % d;

  // (num, int) -> num
  var niPlus = n + i;
  var niMinus = n - i;
  var niTimes = n * i;
  var niMod = n % i;

  // (num, num) -> num
  var nnPlus = n + n;
  var nnMinus = n - n;
  var nnTimes = n * n;
  var nnMod = n % n;
}
