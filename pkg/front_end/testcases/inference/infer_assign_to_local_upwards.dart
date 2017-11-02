// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

void test1(int t) {
  var /*@type=int*/ v1 = t = getInt();
  var /*@type=int*/ v4 = t ??= getInt();
  var /*@type=int*/ v7 = t += getInt();
  var /*@type=num*/ v8 = t += getNum();
  var /*@type=int*/ v10 = ++t;
  var /*@type=int*/ v11 = t++;
}

void test2(num t) {
  var /*@type=int*/ v1 = t = getInt();
  var /*@type=num*/ v2 = t = getNum();
  var /*@type=double*/ v3 = t = getDouble();
  var /*@type=num*/ v4 = t ??= getInt();
  var /*@type=num*/ v5 = t ??= getNum();
  var /*@type=num*/ v6 = t ??= getDouble();
  var /*@type=num*/ v7 = t += getInt();
  var /*@type=num*/ v8 = t += getNum();
  var /*@type=num*/ v9 = t += getDouble();
  var /*@type=num*/ v10 = ++t;
  var /*@type=num*/ v11 = t++;
}

void test3(double t) {
  var /*@type=double*/ v3 = t = getDouble();
  var /*@type=double*/ v6 = t ??= getDouble();
  var /*@type=double*/ v7 = t += getInt();
  var /*@type=double*/ v8 = t += getNum();
  var /*@type=double*/ v9 = t += getDouble();
  var /*@type=double*/ v10 = ++t;
  var /*@type=double*/ v11 = t++;
}

main() {}
