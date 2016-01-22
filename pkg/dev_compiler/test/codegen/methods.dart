// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library methods;

class A {
  int x() => 42;

  int y(int a) {
    return a;
  }

  int z([num b]) => b;

  int zz([int b = 0]) => b;

  int w(int a, {num b}) {
    return a + b;
  }

  int ww(int a, {int b: 0}) {
    return a + b;
  }

  clashWithObjectProperty({constructor}) => constructor;
  clashWithJsReservedName({function}) => function;

  int get a => x();

  void set b(int b) {}

  int _c = 3;

  int get c => _c;

  void set c(int c) {
    _c = c;
  }
}

class Bar {
  call(x) => print('hello from $x');
}
class Foo {
  final Bar bar = new Bar();
}

test() {
  // looks like a method but is actually f.bar.call(...)
  var f = new Foo();
  f.bar("Bar's call method!");

  // Tear-off
  A a = new A();
  var g = a.x;

  // Dynamic Tear-off
  dynamic aa = new A();
  var h = aa.x;

  // Tear-off of object methods
  var ts = a.toString;
  var nsm = a.noSuchMethod;

  // Tear-off extension methods
  var c = "".padLeft;
  var r = (3.0).floor;
}
