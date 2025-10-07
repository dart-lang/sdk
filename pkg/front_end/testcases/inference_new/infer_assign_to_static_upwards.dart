// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

int topLevelInt = 0;
int? topLevelInt2;
num topLevelNum = 0;
num? topLevelNum2;
double topLevelDouble = 0;
double? topLevelDouble2;

void test1() {
  var v1 = topLevelInt = getInt();

  var v4 = topLevelInt2 ??= getInt();

  var v7 = topLevelInt += getInt();

  var v10 = ++topLevelInt;

  var v11 = topLevelInt++;
}

void test2() {
  var v1 = topLevelNum = getInt();

  var v2 = topLevelNum = getNum();

  var v3 = topLevelNum = getDouble();

  var v4 = topLevelNum2 ??= getInt();

  var v5 = topLevelNum2 ??= getNum();

  var v6 = topLevelNum2 ??= getDouble();

  var v7 = topLevelNum += getInt();

  var v8 = topLevelNum += getNum();

  var v9 = topLevelNum += getDouble();

  var v10 = ++topLevelNum;

  var v11 = topLevelNum++;
}

void test3() {
  var v3 = topLevelDouble = getDouble();

  var v6 = topLevelDouble2 ??= getDouble();

  var v7 = topLevelDouble += getInt();

  var v8 = topLevelDouble += getNum();

  var v9 = topLevelDouble += getDouble();

  var v10 = ++topLevelDouble;

  var v11 = topLevelDouble++;
}

main() {}
