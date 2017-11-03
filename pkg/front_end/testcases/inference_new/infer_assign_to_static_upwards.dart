// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

int topLevelInt;
num topLevelNum;
double topLevelDouble;

void test1() {
  var /*@type=int*/ v1 = topLevelInt = getInt();
  var /*@type=int*/ v2 = topLevelInt = getNum();
  var /*@type=int*/ v4 = topLevelInt ??= getInt();
  var /*@type=int*/ v5 = topLevelInt ??= getNum();
  var /*@type=int*/ v7 = topLevelInt += getInt();
  var /*@type=int*/ v8 = topLevelInt += getNum();
  var /*@type=int*/ v10 = ++topLevelInt;
  var /*@type=int*/ v11 = topLevelInt++;
}

void test2() {
  var /*@type=int*/ v1 = topLevelNum = getInt();
  var /*@type=num*/ v2 = topLevelNum = getNum();
  var /*@type=double*/ v3 = topLevelNum = getDouble();
  var /*@type=num*/ v4 = topLevelNum ??= getInt();
  var /*@type=num*/ v5 = topLevelNum ??= getNum();
  var /*@type=num*/ v6 = topLevelNum ??= getDouble();
  var /*@type=num*/ v7 = topLevelNum += getInt();
  var /*@type=num*/ v8 = topLevelNum += getNum();
  var /*@type=num*/ v9 = topLevelNum += getDouble();
  var /*@type=num*/ v10 = ++topLevelNum;
  var /*@type=num*/ v11 = topLevelNum++;
}

void test3() {
  var /*@type=double*/ v2 = topLevelDouble = getNum();
  var /*@type=double*/ v3 = topLevelDouble = getDouble();
  var /*@type=double*/ v5 = topLevelDouble ??= getNum();
  var /*@type=double*/ v6 = topLevelDouble ??= getDouble();
  var /*@type=double*/ v7 = topLevelDouble += getInt();
  var /*@type=double*/ v8 = topLevelDouble += getNum();
  var /*@type=double*/ v9 = topLevelDouble += getDouble();
  var /*@type=double*/ v10 = ++topLevelDouble;
  var /*@type=double*/ v11 = topLevelDouble++;
}

main() {}
