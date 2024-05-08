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

abstract class Base2<T, U> {
  T? operator [](String s) => /*@target=Base2.getValue*/ getValue(s);
  void operator []=(
      String s, U? v) => /*@target=Base2.setValue*/ setValue(s, v);

  T? getValue(String s);
  void setValue(String s, U? v);
}

abstract class Test1a extends Base<int, int> {
  void test() {
    var /*@type=int*/ v1 = super /*@target=Base.[]=*/ ['x'] = getInt();

    var /*@type=int*/ v7 = super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'] /*@target=num.+*/ += getInt();

    var /*@type=int*/ v10 = /*@target=num.+*/ ++super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'];

    var /*@type=int*/ v11 = super /*@target=Base.[]*/ /*@target=Base.[]=*/
        ['x'] /*@target=num.+*/ ++;
  }
}

abstract class Test1b extends Base2<int, int> {
  void test() {
    var /*@type=int*/ v4 =
        super /*@target=Base2.[]*/ /*@target=Base2.[]=*/ ['x'] ??= getInt();
  }
}

abstract class Test2a extends Base<int, num> {
  void test() {
    var /*@type=int*/ v1 = super /*@target=Base.[]=*/ ['x'] = getInt();

    var /*@type=num*/ v2 = super /*@target=Base.[]=*/ ['x'] = getNum();

    var /*@type=double*/ v3 = super /*@target=Base.[]=*/ ['x'] = getDouble();

    var /*@type=int*/ v7 = super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'] /*@target=num.+*/ += getInt();

    var /*@type=num*/ v8 = super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'] /*@target=num.+*/ += getNum();

    var /*@type=double*/ v9 = super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'] /*@target=num.+*/ += getDouble();

    var /*@type=int*/ v10 = /*@target=num.+*/ ++super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'];

    var /*@type=int*/ v11 = super /*@target=Base.[]*/ /*@target=Base.[]=*/
        ['x'] /*@target=num.+*/ ++;
  }
}

abstract class Test2b extends Base2<int, num> {
  void test() {
    var /*@type=int*/ v4 =
        super /*@target=Base2.[]*/ /*@target=Base2.[]=*/ ['x'] ??= getInt();

    var /*@type=num*/ v5 =
        super /*@target=Base2.[]*/ /*@target=Base2.[]=*/ ['x'] ??= getNum();

    var /*@type=num*/ v6 =
        super /*@target=Base2.[]*/ /*@target=Base2.[]=*/ ['x'] ??= getDouble();
  }
}

abstract class Test3a extends Base<int, double> {
  void test() {
    var /*@type=double*/ v3 = super /*@target=Base.[]=*/ ['x'] = getDouble();

    var /*@type=double*/ v9 = super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'] /*@target=num.+*/ += getDouble();

    var /*@type=double*/ v10 = /*@target=num.+*/ ++super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'];

    var /*@type=int*/ v11 = super /*@target=Base.[]*/ /*@target=Base.[]=*/
        ['x'] /*@target=num.+*/ ++;
  }
}

abstract class Test3b extends Base2<int, double> {
  void test() {
    var /*@type=num*/ v6 =
        super /*@target=Base2.[]*/ /*@target=Base2.[]=*/ ['x'] ??= getDouble();
  }
}

abstract class Test4a extends Base<num, int> {
  void test() {
    var /*@type=int*/ v1 = super /*@target=Base.[]=*/ ['x'] = getInt();
  }
}

abstract class Test4b extends Base2<num, int> {
  void test() {
    var /*@type=num*/ v4 =
        super /*@target=Base2.[]*/ /*@target=Base2.[]=*/ ['x'] ??= getInt();
  }
}

abstract class Test5a extends Base<num, num> {
  void test() {
    var /*@type=int*/ v1 = super /*@target=Base.[]=*/ ['x'] = getInt();

    var /*@type=num*/ v2 = super /*@target=Base.[]=*/ ['x'] = getNum();

    var /*@type=double*/ v3 = super /*@target=Base.[]=*/ ['x'] = getDouble();

    var /*@type=num*/ v7 = super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'] /*@target=num.+*/ += getInt();

    var /*@type=num*/ v8 = super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'] /*@target=num.+*/ += getNum();

    var /*@type=double*/ v9 = super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'] /*@target=num.+*/ += getDouble();

    var /*@type=num*/ v10 = /*@target=num.+*/ ++super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'];

    var /*@type=num*/ v11 = super /*@target=Base.[]*/ /*@target=Base.[]=*/
        ['x'] /*@target=num.+*/ ++;
  }
}

abstract class Test5b extends Base2<num, num> {
  void test() {
    var /*@type=num*/ v4 =
        super /*@target=Base2.[]*/ /*@target=Base2.[]=*/ ['x'] ??= getInt();

    var /*@type=num*/ v5 =
        super /*@target=Base2.[]*/ /*@target=Base2.[]=*/ ['x'] ??= getNum();

    var /*@type=num*/ v6 =
        super /*@target=Base2.[]*/ /*@target=Base2.[]=*/ ['x'] ??= getDouble();
  }
}

abstract class Test6a extends Base<num, double> {
  void test() {
    var /*@type=double*/ v3 = super /*@target=Base.[]=*/ ['x'] = getDouble();

    var /*@type=double*/ v9 = super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'] /*@target=num.+*/ += getDouble();

    var /*@type=double*/ v10 = /*@target=num.+*/ ++super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'];

    var /*@type=num*/ v11 = super /*@target=Base.[]*/ /*@target=Base.[]=*/
        ['x'] /*@target=num.+*/ ++;
  }
}

abstract class Test6b extends Base2<num, double> {
  void test() {
    var /*@type=num*/ v6 =
        super /*@target=Base2.[]*/ /*@target=Base2.[]=*/ ['x'] ??= getDouble();
  }
}

abstract class Test7a extends Base<double, int> {
  void test() {
    var /*@type=int*/ v1 = super /*@target=Base.[]=*/ ['x'] = getInt();
  }
}

abstract class Test7b extends Base2<double, int> {
  void test() {
    var /*@type=num*/ v4 =
        super /*@target=Base2.[]*/ /*@target=Base2.[]=*/ ['x'] ??= getInt();
  }
}

abstract class Test8a extends Base<double, num> {
  void test() {
    var /*@type=int*/ v1 = super /*@target=Base.[]=*/ ['x'] = getInt();

    var /*@type=num*/ v2 = super /*@target=Base.[]=*/ ['x'] = getNum();

    var /*@type=double*/ v3 = super /*@target=Base.[]=*/ ['x'] = getDouble();

    var /*@type=double*/ v7 = super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'] /*@target=double.+*/ += getInt();

    var /*@type=double*/ v8 = super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'] /*@target=double.+*/ += getNum();

    var /*@type=double*/ v9 = super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'] /*@target=double.+*/ += getDouble();

    var /*@type=double*/ v10 = /*@target=double.+*/ ++super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'];

    var /*@type=double*/ v11 = super /*@target=Base.[]*/ /*@target=Base.[]=*/
        ['x'] /*@target=double.+*/ ++;
  }
}

abstract class Test8b extends Base2<double, num> {
  void test() {
    var /*@type=num*/ v4 =
        super /*@target=Base2.[]*/ /*@target=Base2.[]=*/ ['x'] ??= getInt();

    var /*@type=num*/ v5 =
        super /*@target=Base2.[]*/ /*@target=Base2.[]=*/ ['x'] ??= getNum();

    var /*@type=double*/ v6 =
        super /*@target=Base2.[]*/ /*@target=Base2.[]=*/ ['x'] ??= getDouble();
  }
}

abstract class Test9a extends Base<double, double> {
  void test() {
    var /*@type=double*/ v3 = super /*@target=Base.[]=*/ ['x'] = getDouble();

    var /*@type=double*/ v8 = super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'] /*@target=double.+*/ += getNum();

    var /*@type=double*/ v9 = super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'] /*@target=double.+*/ += getDouble();

    var /*@type=double*/ v10 = /*@target=double.+*/ ++super /*@target=Base.[]*/ /*@target=Base.[]=*/ [
        'x'];

    var /*@type=double*/ v11 = super /*@target=Base.[]*/ /*@target=Base.[]=*/
        ['x'] /*@target=double.+*/ ++;
  }
}

abstract class Test9b extends Base2<double, double> {
  void test() {
    var /*@type=double*/ v6 =
        super /*@target=Base2.[]*/ /*@target=Base2.[]=*/ ['x'] ??= getDouble();
  }
}

main() {}
