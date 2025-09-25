// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

class Test1 {
  int prop = 1;
  int? prop2;

  static void test(Test1? t) {
    var v1 = t?.prop = getInt();

    var v4 = t?.prop2 ??= getInt();

    var v7 = t?.prop += getInt();

    var v10 = ++t?.prop;

    var v11 = t?.prop++;
  }
}

class Test2 {
  num prop = 0;
  num? prop2;

  static void test(Test2? t) {
    var v1 = t?.prop = getInt();

    var v2 = t?.prop = getNum();

    var v3 = t?.prop = getDouble();

    var v4 = t?.prop2 ??= getInt();

    var v5 = t?.prop ??= getNum();

    var v6 = t?.prop ??= getDouble();

    var v7 = t?.prop += getInt();

    var v8 = t?.prop += getNum();

    var v9 = t?.prop += getDouble();

    var v10 = ++t?.prop;

    var v11 = t?.prop++;
  }
}

class Test3 {
  double prop = 0;
  double? prop2;

  static void test3(Test3? t) {
    var v3 = t?.prop = getDouble();

    var v6 = t?.prop2 ??= getDouble();

    var v7 = t?.prop += getInt();

    var v8 = t?.prop += getNum();

    var v9 = t?.prop += getDouble();

    var v10 = ++t?.prop;

    var v11 = t?.prop++;
  }
}

main() {}
