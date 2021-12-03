// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super1 {
  void call() {}
}

class Class1 extends Super1 {
  void method() {
    super();
    super.call();
  }
}

class Super2 {
  int call(int a, [int? b]) => a;
}

class Class2 extends Super2 {
  void method() {
    super(0);
    super(0, 1);
    super.call(0);
    super.call(0, 1);
  }
}

class Super3 {
  int call(int a, {int? b, int? c}) => a;
}

class Class3 extends Super3 {
  void method() {
    super(0);
    super(0, b: 1);
    super(0, c: 1);
    super(0, b: 1, c: 2);
    super(0, c: 1, b: 2);
    super.call(0);
    super.call(0, b: 1);
    super.call(0, c: 1);
    super.call(0, b: 1, c: 2);
    super.call(0, c: 1, b: 2);
  }
}

class Super4 {
  T call<T>(T a) => a;
}

class Class4 extends Super4 {
  void method() {
    super(0);
    super<int>(0);
    super.call(0);
    super.call<int>(0);
  }
}

class Super5 {
  int Function(int) get call => (int a) => a;
}

class Class5 extends Super5 {
  void test() {
    super(0); // error
  }

  void method() {
    super.call(0); // ok
  }
}

class Super6 {
  int Function(int) call = (int a) => a;
}

class Class6 extends Super6 {
  void test() {
    super(0); // error
  }

  void method() {
    super.call(0); // ok
  }
}

class Super7 {
  void set call(int Function(int) value) {}
}

class Class7 extends Super7 {
  void test() {
    super(0); // error
    super.call(0); // error
  }
}

class Super8 {}

class Class8 extends Super8 {
  void test() {
    super(); // error
    super.call(); // error
  }
}

main() {
  new Class1().method();
  new Class2().method();
  new Class3().method();
  new Class4().method();
  new Class5().method();
  new Class6().method();
}
