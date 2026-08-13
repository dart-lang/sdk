// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

abstract class Test<T, U> {
  T operator [](String s);
  void operator []=(String s, U v);
}

abstract class Test2<T, U> {
  T? operator [](String s);
  void operator []=(String s, U? v);
}

void test1(Test<int, int> t, Test2<int, int> t2) {
  var v1 = t['x'] = getInt();

  var v4 = t2['x'] ??= getInt();

  var v7 = t['x'] += getInt();

  var v10 = ++t['x'];

  var v11 = t['x']++;
}

void test2(Test<int, num> t, Test2<int, num> t2) {
  var v1 = t['x'] = getInt();

  var v2 = t['x'] = getNum();

  var v3 = t['x'] = getDouble();

  var v4 = t2['x'] ??= getInt();

  var v5 = t2['x'] ??= getNum();

  var v6 = t2['x'] ??= getDouble();

  var v7 = t['x'] += getInt();

  var v8 = t['x'] += getNum();

  var v9 = t['x'] += getDouble();

  var v10 = ++t['x'];

  var v11 = t['x']++;
}

void test3(Test<int, double> t, Test2<int, double> t2) {
  var v3 = t['x'] = getDouble();

  var v6 = t2['x'] ??= getDouble();

  var v9 = t['x'] += getDouble();

  var v10 = ++t['x'];

  var v11 = t['x']++;
}

void test4(Test<num, int> t, Test2<num, int> t2) {
  var v1 = t['x'] = getInt();

  var v4 = t2['x'] ??= getInt();
}

void test5(Test<num, num> t, Test2<num, num> t2) {
  var v1 = t['x'] = getInt();

  var v2 = t['x'] = getNum();

  var v3 = t['x'] = getDouble();

  var v4 = t2['x'] ??= getInt();

  var v5 = t2['x'] ??= getNum();

  var v6 = t2['x'] ??= getDouble();

  var v7 = t['x'] += getInt();

  var v8 = t['x'] += getNum();

  var v9 = t['x'] += getDouble();

  var v10 = ++t['x'];

  var v11 = t['x']++;
}

void test6(Test<num, double> t, Test2<num, double> t2) {
  var v3 = t['x'] = getDouble();

  var v6 = t2['x'] ??= getDouble();

  var v9 = t['x'] += getDouble();

  var v10 = ++t['x'];

  var v11 = t['x']++;
}

void test7(Test<double, int> t, Test2<double, int> t2) {
  var v1 = t['x'] = getInt();

  var v4 = t2['x'] ??= getInt();
}

void test8(Test<double, num> t, Test2<double, num> t2) {
  var v1 = t['x'] = getInt();

  var v2 = t['x'] = getNum();

  var v3 = t['x'] = getDouble();

  var v4 = t2['x'] ??= getInt();

  var v5 = t2['x'] ??= getNum();

  var v6 = t2['x'] ??= getDouble();

  var v7 = t['x'] += getInt();

  var v8 = t['x'] += getNum();

  var v9 = t['x'] += getDouble();

  var v10 = ++t['x'];

  var v11 = t['x']++;
}

void test9(Test<double, double> t, Test2<double, double> t2) {
  var v3 = t['x'] = getDouble();

  var v6 = t2['x'] ??= getDouble();

  var v7 = t['x'] += getInt();

  var v8 = t['x'] += getNum();

  var v9 = t['x'] += getDouble();

  var v10 = ++t['x'];

  var v11 = t['x']++;
}

main() {}
