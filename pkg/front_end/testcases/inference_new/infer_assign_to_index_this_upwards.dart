// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

abstract class Test1a {
  int operator [](String s);
  void operator []=(String s, int v);

  void test() {
    var v1 = this['x'] = getInt();

    var v7 = this['x'] += getInt();

    var v10 = ++this['x'];

    var v11 = this['x']++;
  }
}

abstract class Test1b {
  int? operator [](String s);
  void operator []=(String s, int? v);

  void test() {
    var v4 = this['x'] ??= getInt();
  }
}

abstract class Test2a {
  int operator [](String s);
  void operator []=(String s, num v);

  void test() {
    var v1 = this['x'] = getInt();

    var v2 = this['x'] = getNum();

    var v3 = this['x'] = getDouble();

    var v7 = this['x'] += getInt();

    var v8 = this['x'] += getNum();

    var v9 = this['x'] += getDouble();

    var v10 = ++this['x'];

    var v11 = this['x']++;
  }
}

abstract class Test2b {
  int? operator [](String s);
  void operator []=(String s, num? v);

  void test() {
    var v4 = this['x'] ??= getInt();

    var v5 = this['x'] ??= getNum();

    var v6 = this['x'] ??= getDouble();
  }
}

abstract class Test3a {
  int operator [](String s);
  void operator []=(String s, double v);

  void test() {
    var v3 = this['x'] = getDouble();

    var v9 = this['x'] += getDouble();

    var v10 = ++this['x'];

    var v11 = this['x']++;
  }
}

abstract class Test3b {
  int? operator [](String s);
  void operator []=(String s, double? v);

  void test() {
    var v6 = this['x'] ??= getDouble();
  }
}

abstract class Test4a {
  num operator [](String s);
  void operator []=(String s, int v);

  void test() {
    var v1 = this['x'] = getInt();
  }
}

abstract class Test4b {
  num? operator [](String s);
  void operator []=(String s, int? v);

  void test() {
    var v4 = this['x'] ??= getInt();
  }
}

abstract class Test5a {
  num operator [](String s);
  void operator []=(String s, num v);

  void test() {
    var v1 = this['x'] = getInt();

    var v2 = this['x'] = getNum();

    var v3 = this['x'] = getDouble();

    var v7 = this['x'] += getInt();

    var v8 = this['x'] += getNum();

    var v9 = this['x'] += getDouble();

    var v10 = ++this['x'];

    var v11 = this['x']++;
  }
}

abstract class Test5b {
  num? operator [](String s);
  void operator []=(String s, num? v);

  void test() {
    var v4 = this['x'] ??= getInt();

    var v5 = this['x'] ??= getNum();

    var v6 = this['x'] ??= getDouble();
  }
}

abstract class Test6a {
  num operator [](String s);
  void operator []=(String s, double v);

  void test() {
    var v3 = this['x'] = getDouble();

    var v9 = this['x'] += getDouble();

    var v10 = ++this['x'];

    var v11 = this['x']++;
  }
}

abstract class Test6b {
  num? operator [](String s);
  void operator []=(String s, double? v);

  void test() {
    var v6 = this['x'] ??= getDouble();
  }
}

abstract class Test7a {
  double operator [](String s);
  void operator []=(String s, int v);

  void test() {
    var v1 = this['x'] = getInt();
  }
}

abstract class Test7b {
  double? operator [](String s);
  void operator []=(String s, int? v);

  void test() {
    var v4 = this['x'] ??= getInt();
  }
}

abstract class Test8a {
  double operator [](String s);
  void operator []=(String s, num v);

  void test() {
    var v1 = this['x'] = getInt();

    var v2 = this['x'] = getNum();

    var v3 = this['x'] = getDouble();

    var v7 = this['x'] += getInt();

    var v8 = this['x'] += getNum();

    var v9 = this['x'] += getDouble();

    var v10 = ++this['x'];

    var v11 = this['x']++;
  }
}

abstract class Test8b {
  double? operator [](String s);
  void operator []=(String s, num? v);

  void test() {
    var v4 = this['x'] ??= getInt();

    var v5 = this['x'] ??= getNum();

    var v6 = this['x'] ??= getDouble();
  }
}

abstract class Test9a {
  double operator [](String s);
  void operator []=(String s, double v);

  void test() {
    var v3 = this['x'] = getDouble();

    var v7 = this['x'] += getInt();

    var v8 = this['x'] += getNum();

    var v9 = this['x'] += getDouble();

    var v10 = ++this['x'];

    var v11 = this['x']++;
  }
}

abstract class Test9b {
  double? operator [](String s);
  void operator []=(String s, double? v);

  void test() {
    var v6 = this['x'] ??= getDouble();
  }
}

main() {}
