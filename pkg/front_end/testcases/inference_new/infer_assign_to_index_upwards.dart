// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

abstract class Test<T, U> {
  T operator [](String s);
  void operator []=(String s, U v);
}

void test1(Test<int, int> t) {
  var /*@type=int*/ v1 = t /*@target=Test::[]=*/ ['x'] = getInt();
  var /*@type=num*/ v2 = t /*@target=Test::[]=*/ ['x'] = getNum();
  var /*@type=int*/ v4 = t /*@target=Test::[]=*/ ['x'] ??= getInt();
  var /*@type=num*/ v5 = t /*@target=Test::[]=*/ ['x'] ??= getNum();
  var /*@type=int*/ v7 = t /*@target=Test::[]=*/ ['x'] += getInt();
  var /*@type=num*/ v8 = t /*@target=Test::[]=*/ ['x'] += getNum();
  var /*@type=int*/ v10 = ++t /*@target=Test::[]=*/ ['x'];
  var /*@type=int*/ v11 = t /*@target=Test::[]=*/ ['x']++;
}

void test2(Test<int, num> t) {
  var /*@type=int*/ v1 = t /*@target=Test::[]=*/ ['x'] = getInt();
  var /*@type=num*/ v2 = t /*@target=Test::[]=*/ ['x'] = getNum();
  var /*@type=double*/ v3 = t /*@target=Test::[]=*/ ['x'] = getDouble();
  var /*@type=int*/ v4 = t /*@target=Test::[]=*/ ['x'] ??= getInt();
  var /*@type=num*/ v5 = t /*@target=Test::[]=*/ ['x'] ??= getNum();
  var /*@type=num*/ v6 = t /*@target=Test::[]=*/ ['x'] ??= getDouble();
  var /*@type=int*/ v7 = t /*@target=Test::[]=*/ ['x'] += getInt();
  var /*@type=num*/ v8 = t /*@target=Test::[]=*/ ['x'] += getNum();
  var /*@type=double*/ v9 = t /*@target=Test::[]=*/ ['x'] += getDouble();
  var /*@type=int*/ v10 = ++t /*@target=Test::[]=*/ ['x'];
  var /*@type=int*/ v11 = t /*@target=Test::[]=*/ ['x']++;
}

void test3(Test<int, double> t) {
  var /*@type=num*/ v2 = t /*@target=Test::[]=*/ ['x'] = getNum();
  var /*@type=double*/ v3 = t /*@target=Test::[]=*/ ['x'] = getDouble();
  var /*@type=num*/ v5 = t /*@target=Test::[]=*/ ['x'] ??= getNum();
  var /*@type=num*/ v6 = t /*@target=Test::[]=*/ ['x'] ??= getDouble();
  var /*@type=int*/ v7 = t /*@target=Test::[]=*/ ['x'] += getInt();
  var /*@type=num*/ v8 = t /*@target=Test::[]=*/ ['x'] += getNum();
  var /*@type=double*/ v9 = t /*@target=Test::[]=*/ ['x'] += getDouble();
  var /*@type=int*/ v10 = ++t /*@target=Test::[]=*/ ['x'];
  var /*@type=int*/ v11 = t /*@target=Test::[]=*/ ['x']++;
}

void test4(Test<num, int> t) {
  var /*@type=int*/ v1 = t /*@target=Test::[]=*/ ['x'] = getInt();
  var /*@type=num*/ v2 = t /*@target=Test::[]=*/ ['x'] = getNum();
  var /*@type=num*/ v4 = t /*@target=Test::[]=*/ ['x'] ??= getInt();
  var /*@type=num*/ v5 = t /*@target=Test::[]=*/ ['x'] ??= getNum();
  var /*@type=num*/ v7 = t /*@target=Test::[]=*/ ['x'] += getInt();
  var /*@type=num*/ v8 = t /*@target=Test::[]=*/ ['x'] += getNum();
  var /*@type=num*/ v10 = ++t /*@target=Test::[]=*/ ['x'];
  var /*@type=num*/ v11 = t /*@target=Test::[]=*/ ['x']++;
}

void test5(Test<num, num> t) {
  var /*@type=int*/ v1 = t /*@target=Test::[]=*/ ['x'] = getInt();
  var /*@type=num*/ v2 = t /*@target=Test::[]=*/ ['x'] = getNum();
  var /*@type=double*/ v3 = t /*@target=Test::[]=*/ ['x'] = getDouble();
  var /*@type=num*/ v4 = t /*@target=Test::[]=*/ ['x'] ??= getInt();
  var /*@type=num*/ v5 = t /*@target=Test::[]=*/ ['x'] ??= getNum();
  var /*@type=num*/ v6 = t /*@target=Test::[]=*/ ['x'] ??= getDouble();
  var /*@type=num*/ v7 = t /*@target=Test::[]=*/ ['x'] += getInt();
  var /*@type=num*/ v8 = t /*@target=Test::[]=*/ ['x'] += getNum();
  var /*@type=num*/ v9 = t /*@target=Test::[]=*/ ['x'] += getDouble();
  var /*@type=num*/ v10 = ++t /*@target=Test::[]=*/ ['x'];
  var /*@type=num*/ v11 = t /*@target=Test::[]=*/ ['x']++;
}

void test6(Test<num, double> t) {
  var /*@type=num*/ v2 = t /*@target=Test::[]=*/ ['x'] = getNum();
  var /*@type=double*/ v3 = t /*@target=Test::[]=*/ ['x'] = getDouble();
  var /*@type=num*/ v5 = t /*@target=Test::[]=*/ ['x'] ??= getNum();
  var /*@type=num*/ v6 = t /*@target=Test::[]=*/ ['x'] ??= getDouble();
  var /*@type=num*/ v7 = t /*@target=Test::[]=*/ ['x'] += getInt();
  var /*@type=num*/ v8 = t /*@target=Test::[]=*/ ['x'] += getNum();
  var /*@type=num*/ v9 = t /*@target=Test::[]=*/ ['x'] += getDouble();
  var /*@type=num*/ v10 = ++t /*@target=Test::[]=*/ ['x'];
  var /*@type=num*/ v11 = t /*@target=Test::[]=*/ ['x']++;
}

void test7(Test<double, int> t) {
  var /*@type=int*/ v1 = t /*@target=Test::[]=*/ ['x'] = getInt();
  var /*@type=num*/ v2 = t /*@target=Test::[]=*/ ['x'] = getNum();
  var /*@type=num*/ v4 = t /*@target=Test::[]=*/ ['x'] ??= getInt();
  var /*@type=num*/ v5 = t /*@target=Test::[]=*/ ['x'] ??= getNum();
  var /*@type=double*/ v7 = t /*@target=Test::[]=*/ ['x'] += getInt();
  var /*@type=double*/ v8 = t /*@target=Test::[]=*/ ['x'] += getNum();
  var /*@type=double*/ v10 = ++t /*@target=Test::[]=*/ ['x'];
  var /*@type=double*/ v11 = t /*@target=Test::[]=*/ ['x']++;
}

void test8(Test<double, num> t) {
  var /*@type=int*/ v1 = t /*@target=Test::[]=*/ ['x'] = getInt();
  var /*@type=num*/ v2 = t /*@target=Test::[]=*/ ['x'] = getNum();
  var /*@type=double*/ v3 = t /*@target=Test::[]=*/ ['x'] = getDouble();
  var /*@type=num*/ v4 = t /*@target=Test::[]=*/ ['x'] ??= getInt();
  var /*@type=num*/ v5 = t /*@target=Test::[]=*/ ['x'] ??= getNum();
  var /*@type=double*/ v6 = t /*@target=Test::[]=*/ ['x'] ??= getDouble();
  var /*@type=double*/ v7 = t /*@target=Test::[]=*/ ['x'] += getInt();
  var /*@type=double*/ v8 = t /*@target=Test::[]=*/ ['x'] += getNum();
  var /*@type=double*/ v9 = t /*@target=Test::[]=*/ ['x'] += getDouble();
  var /*@type=double*/ v10 = ++t /*@target=Test::[]=*/ ['x'];
  var /*@type=double*/ v11 = t /*@target=Test::[]=*/ ['x']++;
}

void test9(Test<double, double> t) {
  var /*@type=num*/ v2 = t /*@target=Test::[]=*/ ['x'] = getNum();
  var /*@type=double*/ v3 = t /*@target=Test::[]=*/ ['x'] = getDouble();
  var /*@type=num*/ v5 = t /*@target=Test::[]=*/ ['x'] ??= getNum();
  var /*@type=double*/ v6 = t /*@target=Test::[]=*/ ['x'] ??= getDouble();
  var /*@type=double*/ v7 = t /*@target=Test::[]=*/ ['x'] += getInt();
  var /*@type=double*/ v8 = t /*@target=Test::[]=*/ ['x'] += getNum();
  var /*@type=double*/ v9 = t /*@target=Test::[]=*/ ['x'] += getDouble();
  var /*@type=double*/ v10 = ++t /*@target=Test::[]=*/ ['x'];
  var /*@type=double*/ v11 = t /*@target=Test::[]=*/ ['x']++;
}

main() {}
