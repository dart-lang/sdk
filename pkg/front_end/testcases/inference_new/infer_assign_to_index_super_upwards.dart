// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

abstract class Base<T, U> {
  T operator [](String s) => getValue(s);
  void operator []=(String s, U v) => setValue(s, v);

  T getValue(String s);
  void setValue(String s, U v);
}

abstract class Base2<T, U> {
  T? operator [](String s) => getValue(s);
  void operator []=(String s, U? v) => setValue(s, v);

  T? getValue(String s);
  void setValue(String s, U? v);
}

abstract class Test1a extends Base<int, int> {
  void test() {
    var v1 = super['x'] = getInt();

    var v7 = super['x'] += getInt();

    var v10 = ++super['x'];

    var v11 = super['x']++;
  }
}

abstract class Test1b extends Base2<int, int> {
  void test() {
    var v4 = super['x'] ??= getInt();
  }
}

abstract class Test2a extends Base<int, num> {
  void test() {
    var v1 = super['x'] = getInt();

    var v2 = super['x'] = getNum();

    var v3 = super['x'] = getDouble();

    var v7 = super['x'] += getInt();

    var v8 = super['x'] += getNum();

    var v9 = super['x'] += getDouble();

    var v10 = ++super['x'];

    var v11 = super['x']++;
  }
}

abstract class Test2b extends Base2<int, num> {
  void test() {
    var v4 = super['x'] ??= getInt();

    var v5 = super['x'] ??= getNum();

    var v6 = super['x'] ??= getDouble();
  }
}

abstract class Test3a extends Base<int, double> {
  void test() {
    var v3 = super['x'] = getDouble();

    var v9 = super['x'] += getDouble();

    var v10 = ++super['x'];

    var v11 = super['x']++;
  }
}

abstract class Test3b extends Base2<int, double> {
  void test() {
    var v6 = super['x'] ??= getDouble();
  }
}

abstract class Test4a extends Base<num, int> {
  void test() {
    var v1 = super['x'] = getInt();
  }
}

abstract class Test4b extends Base2<num, int> {
  void test() {
    var v4 = super['x'] ??= getInt();
  }
}

abstract class Test5a extends Base<num, num> {
  void test() {
    var v1 = super['x'] = getInt();

    var v2 = super['x'] = getNum();

    var v3 = super['x'] = getDouble();

    var v7 = super['x'] += getInt();

    var v8 = super['x'] += getNum();

    var v9 = super['x'] += getDouble();

    var v10 = ++super['x'];

    var v11 = super['x']++;
  }
}

abstract class Test5b extends Base2<num, num> {
  void test() {
    var v4 = super['x'] ??= getInt();

    var v5 = super['x'] ??= getNum();

    var v6 = super['x'] ??= getDouble();
  }
}

abstract class Test6a extends Base<num, double> {
  void test() {
    var v3 = super['x'] = getDouble();

    var v9 = super['x'] += getDouble();

    var v10 = ++super['x'];

    var v11 = super['x']++;
  }
}

abstract class Test6b extends Base2<num, double> {
  void test() {
    var v6 = super['x'] ??= getDouble();
  }
}

abstract class Test7a extends Base<double, int> {
  void test() {
    var v1 = super['x'] = getInt();
  }
}

abstract class Test7b extends Base2<double, int> {
  void test() {
    var v4 = super['x'] ??= getInt();
  }
}

abstract class Test8a extends Base<double, num> {
  void test() {
    var v1 = super['x'] = getInt();

    var v2 = super['x'] = getNum();

    var v3 = super['x'] = getDouble();

    var v7 = super['x'] += getInt();

    var v8 = super['x'] += getNum();

    var v9 = super['x'] += getDouble();

    var v10 = ++super['x'];

    var v11 = super['x']++;
  }
}

abstract class Test8b extends Base2<double, num> {
  void test() {
    var v4 = super['x'] ??= getInt();

    var v5 = super['x'] ??= getNum();

    var v6 = super['x'] ??= getDouble();
  }
}

abstract class Test9a extends Base<double, double> {
  void test() {
    var v3 = super['x'] = getDouble();

    var v8 = super['x'] += getNum();

    var v9 = super['x'] += getDouble();

    var v10 = ++super['x'];

    var v11 = super['x']++;
  }
}

abstract class Test9b extends Base2<double, double> {
  void test() {
    var v6 = super['x'] ??= getDouble();
  }
}

main() {}
