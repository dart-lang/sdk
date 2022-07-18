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

abstract class Test2<T, U> {
  T? operator [](String s);
  void operator []=(String s, U? v);
}

void test1(Test<int, int> t, Test2<int, int> t2) {
  var /*@type=int*/ v1 = t /*@target=Test.[]=*/ ['x'] = getInt();

  var /*@type=int*/ v4 =
      t2 /*@target=Test2.[]*/ /*@target=Test2.[]=*/ ['x'] ??= getInt();

  var /*@type=int*/ v7 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=num.+*/ +=
          getInt();

  var /*@type=int*/ v10 =
      /*@target=num.+*/ ++t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'];

  var /*@type=int*/ v11 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=num.+*/ ++;
}

void test2(Test<int, num> t, Test2<int, num> t2) {
  var /*@type=int*/ v1 = t /*@target=Test.[]=*/ ['x'] = getInt();

  var /*@type=num*/ v2 = t /*@target=Test.[]=*/ ['x'] = getNum();

  var /*@type=double*/ v3 = t /*@target=Test.[]=*/ ['x'] = getDouble();

  var /*@type=int*/ v4 =
      t2 /*@target=Test2.[]*/ /*@target=Test2.[]=*/ ['x'] ??= getInt();

  var /*@type=num*/ v5 =
      t2 /*@target=Test2.[]*/ /*@target=Test2.[]=*/ ['x'] ??= getNum();

  var /*@type=num*/ v6 =
      t2 /*@target=Test2.[]*/ /*@target=Test2.[]=*/ ['x'] ??= getDouble();

  var /*@type=int*/ v7 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=num.+*/ +=
          getInt();

  var /*@type=num*/ v8 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=num.+*/ +=
          getNum();

  var /*@type=double*/ v9 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=num.+*/ +=
          getDouble();

  var /*@type=int*/ v10 =
      /*@target=num.+*/ ++t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'];

  var /*@type=int*/ v11 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=num.+*/ ++;
}

void test3(Test<int, double> t, Test2<int, double> t2) {
  var /*@type=double*/ v3 = t /*@target=Test.[]=*/ ['x'] = getDouble();

  var /*@type=num*/ v6 =
      t2 /*@target=Test2.[]*/ /*@target=Test2.[]=*/ ['x'] ??= getDouble();

  var /*@type=double*/ v9 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=num.+*/ +=
          getDouble();

  var /*@type=double*/ v10 =
      /*@target=num.+*/ ++t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'];

  var /*@type=int*/ v11 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=num.+*/ ++;
}

void test4(Test<num, int> t, Test2<num, int> t2) {
  var /*@type=int*/ v1 = t /*@target=Test.[]=*/ ['x'] = getInt();

  var /*@type=num*/ v4 =
      t2 /*@target=Test2.[]*/ /*@target=Test2.[]=*/ ['x'] ??= getInt();
}

void test5(Test<num, num> t, Test2<num, num> t2) {
  var /*@type=int*/ v1 = t /*@target=Test.[]=*/ ['x'] = getInt();

  var /*@type=num*/ v2 = t /*@target=Test.[]=*/ ['x'] = getNum();

  var /*@type=double*/ v3 = t /*@target=Test.[]=*/ ['x'] = getDouble();

  var /*@type=num*/ v4 =
      t2 /*@target=Test2.[]*/ /*@target=Test2.[]=*/ ['x'] ??= getInt();

  var /*@type=num*/ v5 =
      t2 /*@target=Test2.[]*/ /*@target=Test2.[]=*/ ['x'] ??= getNum();

  var /*@type=num*/ v6 =
      t2 /*@target=Test2.[]*/ /*@target=Test2.[]=*/ ['x'] ??= getDouble();

  var /*@type=num*/ v7 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=num.+*/ +=
          getInt();

  var /*@type=num*/ v8 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=num.+*/ +=
          getNum();

  var /*@type=double*/ v9 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=num.+*/ +=
          getDouble();

  var /*@type=num*/ v10 =
      /*@target=num.+*/ ++t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'];

  var /*@type=num*/ v11 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=num.+*/ ++;
}

void test6(Test<num, double> t, Test2<num, double> t2) {
  var /*@type=double*/ v3 = t /*@target=Test.[]=*/ ['x'] = getDouble();

  var /*@type=num*/ v6 =
      t2 /*@target=Test2.[]*/ /*@target=Test2.[]=*/ ['x'] ??= getDouble();

  var /*@type=double*/ v9 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=num.+*/ +=
          getDouble();

  var /*@type=double*/ v10 =
      /*@target=num.+*/ ++t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'];

  var /*@type=num*/ v11 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=num.+*/ ++;
}

void test7(Test<double, int> t, Test2<double, int> t2) {
  var /*@type=int*/ v1 = t /*@target=Test.[]=*/ ['x'] = getInt();

 st  var /*@type=num*/ v4 =
      t2 /*@target=Test2.[]*/ /*@target=Test2.[]=*/ ['x'] ??= getInt();
}

void test8(Test<double, num> t, Test2<double, num> t2) {
  var /*@type=int*/ v1 = t /*@target=Test.[]=*/ ['x'] = getInt();

  var /*@type=num*/ v2 = t /*@target=Test.[]=*/ ['x'] = getNum();

  var /*@type=double*/ v3 = t /*@target=Test.[]=*/ ['x'] = getDouble();

  var /*@type=num*/ v4 =
      t2 /*@target=Test2.[]*/ /*@target=Test2.[]=*/ ['x'] ??= getInt();

  var /*@type=num*/ v5 =
      t2 /*@target=Test2.[]*/ /*@target=Test2.[]=*/ ['x'] ??= getNum();

  var /*@type=double*/ v6 =
      t2 /*@target=Test2.[]*/ /*@target=Test2.[]=*/ ['x'] ??= getDouble();

  var /*@type=double*/ v7 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=double.+*/ +=
          getInt();

  var /*@type=double*/ v8 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=double.+*/ +=
          getNum();

  var /*@type=double*/ v9 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=double.+*/ +=
          getDouble();

  var /*@type=double*/ v10 =
      /*@target=double.+*/ ++t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'];

  var /*@type=double*/ v11 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=double.+*/ ++;
}

void test9(Test<double, double> t, Test2<double, double> t2) {
  var /*@type=double*/ v3 = t /*@target=Test.[]=*/ ['x'] = getDouble();

  var /*@type=double*/ v6 =
      t2 /*@target=Test2.[]*/ /*@target=Test2.[]=*/ ['x'] ??= getDouble();

  var /*@type=double*/ v7 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=double.+*/ +=
          getInt();

  var /*@type=double*/ v8 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=double.+*/ +=
          getNum();

  var /*@type=double*/ v9 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=double.+*/ +=
          getDouble();

  var /*@type=double*/ v10 =
      /*@target=double.+*/ ++t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'];

  var /*@type=double*/ v11 =
      t /*@target=Test.[]*/ /*@target=Test.[]=*/ ['x'] /*@target=double.+*/ ++;
}

main() {}
