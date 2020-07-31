// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

abstract class Base<T, U> {
  T operator [](String s) => /*@target=Base.getValue*/ getValue(s);
  void operator []=(String s, U v) => /*@target=Base.setValue*/ setValue(s, v);

  T getValue(String s);
  void setValue(String s, U v);
}

abstract class Test1 extends Base<int, int> {
  void test() {
    var /*@ type=int* */ v1 = super /*@target=Base.[]=*/ ['x'] = getInt();

    var /*@ type=num* */ v2 = super /*@target=Base.[]=*/ ['x'] = getNum();

    var /*@ type=int* */ v4 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getInt();

    var /*@ type=num* */ v5 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getNum();

    var /*@ type=int* */ v7 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.+*/ += getInt();

    var /*@ type=num* */ v8 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.+*/ += getNum();

    var /*@ type=int* */ v10 = /*@target=num.+*/ ++super
        /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x'];

    var /*@ type=int* */ v11 = super /*@target=Base.[]*/ /*@target=Base.[]=*/
        ['x'] /*@target=num.+*/ ++;
  }
}

abstract class Test2 extends Base<int, num> {
  void test() {
    var /*@ type=int* */ v1 = super /*@target=Base.[]=*/ ['x'] = getInt();

    var /*@ type=num* */ v2 = super /*@target=Base.[]=*/ ['x'] = getNum();

    var /*@ type=double* */ v3 = super /*@target=Base.[]=*/ ['x'] = getDouble();

    var /*@ type=int* */ v4 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getInt();

    var /*@ type=num* */ v5 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getNum();

    var /*@ type=num* */ v6 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getDouble();

    var /*@ type=int* */ v7 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.+*/ += getInt();

    var /*@ type=num* */ v8 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.+*/ += getNum();

    var /*@ type=double* */ v9 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.+*/ += getDouble();

    var /*@ type=int* */ v10 = /*@target=num.+*/ ++super
        /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x'];

    var /*@ type=int* */ v11 = super /*@target=Base.[]*/ /*@target=Base.[]=*/
        ['x'] /*@target=num.+*/ ++;
  }
}

abstract class Test3 extends Base<int, double> {
  void test() {
    var /*@ type=num* */ v2 = super /*@target=Base.[]=*/ ['x'] = getNum();

    var /*@ type=double* */ v3 = super /*@target=Base.[]=*/ ['x'] = getDouble();

    var /*@ type=num* */ v5 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getNum();

    var /*@ type=num* */ v6 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getDouble();

    var /*@ type=int* */ v7 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.+*/ += getInt();

    var /*@ type=num* */ v8 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.+*/ += getNum();

    var /*@ type=double* */ v9 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.+*/ += getDouble();

    var /*@ type=int* */ v10 = /*@target=num.+*/ ++super
        /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x'];

    var /*@ type=int* */ v11 = super /*@target=Base.[]*/ /*@target=Base.[]=*/
        ['x'] /*@target=num.+*/ ++;
  }
}

abstract class Test4 extends Base<num, int> {
  void test() {
    var /*@ type=int* */ v1 = super /*@target=Base.[]=*/ ['x'] = getInt();

    var /*@ type=num* */ v2 = super /*@target=Base.[]=*/ ['x'] = getNum();

    var /*@ type=num* */ v4 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getInt();

    var /*@ type=num* */ v5 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getNum();

    var /*@ type=num* */ v7 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.+*/ += getInt();

    var /*@ type=num* */ v8 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.+*/ += getNum();

    var /*@ type=num* */ v10 = /*@target=num.+*/ ++super
        /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x'];

    var /*@ type=num* */ v11 = super /*@target=Base.[]*/ /*@target=Base.[]=*/
        ['x'] /*@target=num.+*/ ++;
  }
}

abstract class Test5 extends Base<num, num> {
  void test() {
    var /*@ type=int* */ v1 = super /*@target=Base.[]=*/ ['x'] = getInt();

    var /*@ type=num* */ v2 = super /*@target=Base.[]=*/ ['x'] = getNum();

    var /*@ type=double* */ v3 = super /*@target=Base.[]=*/ ['x'] = getDouble();

    var /*@ type=num* */ v4 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getInt();

    var /*@ type=num* */ v5 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getNum();

    var /*@ type=num* */ v6 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getDouble();

    var /*@ type=num* */ v7 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.+*/ += getInt();

    var /*@ type=num* */ v8 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.+*/ += getNum();

    var /*@ type=num* */ v9 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.+*/ += getDouble();

    var /*@ type=num* */ v10 = /*@target=num.+*/ ++super
        /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x'];

    var /*@ type=num* */ v11 = super /*@target=Base.[]*/ /*@target=Base.[]=*/
        ['x'] /*@target=num.+*/ ++;
  }
}

abstract class Test6 extends Base<num, double> {
  void test() {
    var /*@ type=num* */ v2 = super /*@target=Base.[]=*/ ['x'] = getNum();

    var /*@ type=double* */ v3 = super /*@target=Base.[]=*/ ['x'] = getDouble();

    var /*@ type=num* */ v5 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getNum();

    var /*@ type=num* */ v6 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getDouble();

    var /*@ type=num* */ v7 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.+*/ += getInt();

    var /*@ type=num* */ v8 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.+*/ += getNum();

    var /*@ type=num* */ v9 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.+*/ += getDouble();

    var /*@ type=num* */ v10 = /*@target=num.+*/ ++super
        /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x'];

    var /*@ type=num* */ v11 = super /*@target=Base.[]*/ /*@target=Base.[]=*/
        ['x'] /*@target=num.+*/ ++;
  }
}

abstract class Test7 extends Base<double, int> {
  void test() {
    var /*@ type=int* */ v1 = super /*@target=Base.[]=*/ ['x'] = getInt();

    var /*@ type=num* */ v2 = super /*@target=Base.[]=*/ ['x'] = getNum();

    var /*@ type=num* */ v4 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getInt();

    var /*@ type=num* */ v5 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getNum();

    var /*@ type=double* */ v7 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=double.+*/ += getInt();

    var /*@ type=double* */ v8 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=double.+*/ += getNum();

    var /*@ type=double* */ v10 = /*@target=double.+*/ ++super
        /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x'];

    var /*@ type=double* */ v11 = super /*@target=Base.[]*/ /*@target=Base.[]=*/
        ['x'] /*@target=double.+*/ ++;
  }
}

abstract class Test8 extends Base<double, num> {
  void test() {
    var /*@ type=int* */ v1 = super /*@target=Base.[]=*/ ['x'] = getInt();

    var /*@ type=num* */ v2 = super /*@target=Base.[]=*/ ['x'] = getNum();

    var /*@ type=double* */ v3 = super /*@target=Base.[]=*/ ['x'] = getDouble();

    var /*@ type=num* */ v4 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getInt();

    var /*@ type=num* */ v5 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getNum();

    var /*@ type=double* */ v6 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getDouble();

    var /*@ type=double* */ v7 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=double.+*/ += getInt();

    var /*@ type=double* */ v8 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=double.+*/ += getNum();

    var /*@ type=double* */ v9 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=double.+*/ += getDouble();

    var /*@ type=double* */ v10 = /*@target=double.+*/ ++super
        /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x'];

    var /*@ type=double* */ v11 = super /*@target=Base.[]*/ /*@target=Base.[]=*/
        ['x'] /*@target=double.+*/ ++;
  }
}

abstract class Test9 extends Base<double, double> {
  void test() {
    var /*@ type=num* */ v2 = super /*@target=Base.[]=*/ ['x'] = getNum();

    var /*@ type=double* */ v3 = super /*@target=Base.[]=*/ ['x'] = getDouble();

    var /*@ type=num* */ v5 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getNum();

    var /*@ type=double* */ v6 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=num.==*/ ??= getDouble();

    var /*@ type=double* */ v7 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=double.+*/ += getInt();

    var /*@ type=double* */ v8 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=double.+*/ += getNum();

    var /*@ type=double* */ v9 =
        super /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x']
            /*@target=double.+*/ += getDouble();

    var /*@ type=double* */ v10 = /*@target=double.+*/ ++super
        /*@target=Base.[]*/ /*@target=Base.[]=*/ ['x'];

    var /*@ type=double* */ v11 = super /*@target=Base.[]*/ /*@target=Base.[]=*/
        ['x'] /*@target=double.+*/ ++;
  }
}

main() {}
