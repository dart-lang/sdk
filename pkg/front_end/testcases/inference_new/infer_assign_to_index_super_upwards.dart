// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

abstract class Base<T, U> {
  T operator [](String s) => /*@target=Base::getValue*/ getValue(s);
  void operator []=(String s, U v) => /*@target=Base::setValue*/ setValue(s, v);

  T getValue(String s);
  void setValue(String s, U v);
}

abstract class Test1 extends Base<int, int> {
  void test() {
    var /*@type=int*/ v1 = super /*@target=Base::[]=*/ ['x'] = getInt();
    var /*@type=int*/ v2 = super /*@target=Base::[]=*/ ['x'] = getNum();
    var /*@type=int*/ v4 = super /*@target=Base::[]=*/ ['x'] ??= getInt();
    var /*@type=int*/ v5 = super /*@target=Base::[]=*/ ['x'] ??= getNum();
    var /*@type=int*/ v7 = super /*@target=Base::[]=*/ ['x'] += getInt();
    var /*@type=int*/ v8 = super /*@target=Base::[]=*/ ['x'] += getNum();
    var /*@type=int*/ v10 = ++super /*@target=Base::[]=*/ ['x'];
    var /*@type=int*/ v11 = super /*@target=Base::[]=*/ ['x']++;
  }
}

abstract class Test2 extends Base<int, num> {
  void test() {
    var /*@type=int*/ v1 = super /*@target=Base::[]=*/ ['x'] = getInt();
    var /*@type=num*/ v2 = super /*@target=Base::[]=*/ ['x'] = getNum();
    var /*@type=double*/ v3 = super /*@target=Base::[]=*/ ['x'] = getDouble();
    var /*@type=int*/ v4 = super /*@target=Base::[]=*/ ['x'] ??= getInt();
    var /*@type=num*/ v5 = super /*@target=Base::[]=*/ ['x'] ??= getNum();
    var /*@type=num*/ v6 = super /*@target=Base::[]=*/ ['x'] ??= getDouble();
    var /*@type=int*/ v7 = super /*@target=Base::[]=*/ ['x'] += getInt();
    var /*@type=num*/ v8 = super /*@target=Base::[]=*/ ['x'] += getNum();
    var /*@type=double*/ v9 = super /*@target=Base::[]=*/ ['x'] += getDouble();
    var /*@type=int*/ v10 = ++super /*@target=Base::[]=*/ ['x'];
    var /*@type=int*/ v11 = super /*@target=Base::[]=*/ ['x']++;
  }
}

abstract class Test3 extends Base<int, double> {
  void test() {
    var /*@type=double*/ v2 = super /*@target=Base::[]=*/ ['x'] = getNum();
    var /*@type=double*/ v3 = super /*@target=Base::[]=*/ ['x'] = getDouble();
    var /*@type=num*/ v5 = super /*@target=Base::[]=*/ ['x'] ??= getNum();
    var /*@type=num*/ v6 = super /*@target=Base::[]=*/ ['x'] ??= getDouble();
    var /*@type=double*/ v7 = super /*@target=Base::[]=*/ ['x'] += getInt();
    var /*@type=double*/ v8 = super /*@target=Base::[]=*/ ['x'] += getNum();
    var /*@type=double*/ v9 = super /*@target=Base::[]=*/ ['x'] += getDouble();
    var /*@type=double*/ v10 = ++super /*@target=Base::[]=*/ ['x'];
    var /*@type=int*/ v11 = super /*@target=Base::[]=*/ ['x']++;
  }
}

abstract class Test4 extends Base<num, int> {
  void test() {
    var /*@type=int*/ v1 = super /*@target=Base::[]=*/ ['x'] = getInt();
    var /*@type=int*/ v2 = super /*@target=Base::[]=*/ ['x'] = getNum();
    var /*@type=num*/ v4 = super /*@target=Base::[]=*/ ['x'] ??= getInt();
    var /*@type=num*/ v5 = super /*@target=Base::[]=*/ ['x'] ??= getNum();
    var /*@type=int*/ v7 = super /*@target=Base::[]=*/ ['x'] += getInt();
    var /*@type=int*/ v8 = super /*@target=Base::[]=*/ ['x'] += getNum();
    var /*@type=int*/ v10 = ++super /*@target=Base::[]=*/ ['x'];
    var /*@type=num*/ v11 = super /*@target=Base::[]=*/ ['x']++;
  }
}

abstract class Test5 extends Base<num, num> {
  void test() {
    var /*@type=int*/ v1 = super /*@target=Base::[]=*/ ['x'] = getInt();
    var /*@type=num*/ v2 = super /*@target=Base::[]=*/ ['x'] = getNum();
    var /*@type=double*/ v3 = super /*@target=Base::[]=*/ ['x'] = getDouble();
    var /*@type=num*/ v4 = super /*@target=Base::[]=*/ ['x'] ??= getInt();
    var /*@type=num*/ v5 = super /*@target=Base::[]=*/ ['x'] ??= getNum();
    var /*@type=num*/ v6 = super /*@target=Base::[]=*/ ['x'] ??= getDouble();
    var /*@type=num*/ v7 = super /*@target=Base::[]=*/ ['x'] += getInt();
    var /*@type=num*/ v8 = super /*@target=Base::[]=*/ ['x'] += getNum();
    var /*@type=num*/ v9 = super /*@target=Base::[]=*/ ['x'] += getDouble();
    var /*@type=num*/ v10 = ++super /*@target=Base::[]=*/ ['x'];
    var /*@type=num*/ v11 = super /*@target=Base::[]=*/ ['x']++;
  }
}

abstract class Test6 extends Base<num, double> {
  void test() {
    var /*@type=double*/ v2 = super /*@target=Base::[]=*/ ['x'] = getNum();
    var /*@type=double*/ v3 = super /*@target=Base::[]=*/ ['x'] = getDouble();
    var /*@type=num*/ v5 = super /*@target=Base::[]=*/ ['x'] ??= getNum();
    var /*@type=num*/ v6 = super /*@target=Base::[]=*/ ['x'] ??= getDouble();
    var /*@type=double*/ v7 = super /*@target=Base::[]=*/ ['x'] += getInt();
    var /*@type=double*/ v8 = super /*@target=Base::[]=*/ ['x'] += getNum();
    var /*@type=double*/ v9 = super /*@target=Base::[]=*/ ['x'] += getDouble();
    var /*@type=double*/ v10 = ++super /*@target=Base::[]=*/ ['x'];
    var /*@type=num*/ v11 = super /*@target=Base::[]=*/ ['x']++;
  }
}

abstract class Test7 extends Base<double, int> {
  void test() {
    var /*@type=int*/ v1 = super /*@target=Base::[]=*/ ['x'] = getInt();
    var /*@type=int*/ v2 = super /*@target=Base::[]=*/ ['x'] = getNum();
    var /*@type=num*/ v4 = super /*@target=Base::[]=*/ ['x'] ??= getInt();
    var /*@type=num*/ v5 = super /*@target=Base::[]=*/ ['x'] ??= getNum();
    var /*@type=int*/ v7 = super /*@target=Base::[]=*/ ['x'] += getInt();
    var /*@type=int*/ v8 = super /*@target=Base::[]=*/ ['x'] += getNum();
    var /*@type=int*/ v10 = ++super /*@target=Base::[]=*/ ['x'];
    var /*@type=double*/ v11 = super /*@target=Base::[]=*/ ['x']++;
  }
}

abstract class Test8 extends Base<double, num> {
  void test() {
    var /*@type=int*/ v1 = super /*@target=Base::[]=*/ ['x'] = getInt();
    var /*@type=num*/ v2 = super /*@target=Base::[]=*/ ['x'] = getNum();
    var /*@type=double*/ v3 = super /*@target=Base::[]=*/ ['x'] = getDouble();
    var /*@type=num*/ v4 = super /*@target=Base::[]=*/ ['x'] ??= getInt();
    var /*@type=num*/ v5 = super /*@target=Base::[]=*/ ['x'] ??= getNum();
    var /*@type=double*/ v6 = super /*@target=Base::[]=*/ ['x'] ??= getDouble();
    var /*@type=double*/ v7 = super /*@target=Base::[]=*/ ['x'] += getInt();
    var /*@type=double*/ v8 = super /*@target=Base::[]=*/ ['x'] += getNum();
    var /*@type=double*/ v9 = super /*@target=Base::[]=*/ ['x'] += getDouble();
    var /*@type=double*/ v10 = ++super /*@target=Base::[]=*/ ['x'];
    var /*@type=double*/ v11 = super /*@target=Base::[]=*/ ['x']++;
  }
}

abstract class Test9 extends Base<double, double> {
  void test() {
    var /*@type=double*/ v2 = super /*@target=Base::[]=*/ ['x'] = getNum();
    var /*@type=double*/ v3 = super /*@target=Base::[]=*/ ['x'] = getDouble();
    var /*@type=double*/ v5 = super /*@target=Base::[]=*/ ['x'] ??= getNum();
    var /*@type=double*/ v6 = super /*@target=Base::[]=*/ ['x'] ??= getDouble();
    var /*@type=double*/ v7 = super /*@target=Base::[]=*/ ['x'] += getInt();
    var /*@type=double*/ v8 = super /*@target=Base::[]=*/ ['x'] += getNum();
    var /*@type=double*/ v9 = super /*@target=Base::[]=*/ ['x'] += getDouble();
    var /*@type=double*/ v10 = ++super /*@target=Base::[]=*/ ['x'];
    var /*@type=double*/ v11 = super /*@target=Base::[]=*/ ['x']++;
  }
}

main() {}
