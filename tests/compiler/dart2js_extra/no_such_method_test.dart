// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class NoSuchMethodInfo {
  Object receiver;
  String name;
  List args;
  NoSuchMethodInfo(Object r, String m, List a)
    : receiver = r, name = m, args = a;
}

class A {
  noSuchMethod(String name, List args) {
    topLevelInfo = new NoSuchMethodInfo(this, name, args);
    return topLevelInfo;
  }

  foo(a, b, c) {
    Expect.fail('Should never enter here');
  }
}

// Used for the setter case.
NoSuchMethodInfo topLevelInfo;

main() {
  A a = new A();
  var info = a.foo();
  Expect.equals('foo', info.name);
  Expect.isTrue(info.args.isEmpty);
  Expect.isTrue(info.receiver === a);

  info = a.foo(2);
  Expect.equals('foo', info.name);
  Expect.isTrue(info.args.length == 1);
  Expect.isTrue(info.args[0] === 2);
  Expect.isTrue(info.receiver === a);

  info = a.bar;
  Expect.equals('get:bar', info.name);
  Expect.isTrue(info.args.length == 0);
  Expect.isTrue(info.receiver === a);

  a.bar = 2;
  info = topLevelInfo;
  Expect.equals('set:bar', info.name);
  Expect.isTrue(info.args.length == 1);
  Expect.isTrue(info.args[0] === 2);
  Expect.isTrue(info.receiver === a);
}
