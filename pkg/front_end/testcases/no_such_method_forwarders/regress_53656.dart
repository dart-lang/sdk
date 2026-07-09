// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String log = "";

class C {
  int m1(int v, [String s = "s1"]);

  int m2(int v, {String s = "s2"});

  dynamic noSuchMethod(Invocation inv) {
    for (int i = 0; i < inv.positionalArguments.length; i++) {
      log += "${inv.positionalArguments[i]};";
    }
    for (int i = 0; i < inv.namedArguments.length; i++) {
      log += "s=${inv.namedArguments[Symbol("s")]};";
    }
    return 42;
  }
}

mixin M {
  int m1(int v, [String s = "s1"]);

  int m2(int v, {String s = "s2"});

  dynamic noSuchMethod(Invocation inv) {
    for (int i = 0; i < inv.positionalArguments.length; i++) {
      log += "${inv.positionalArguments[i]};";
    }
    for (int i = 0; i < inv.namedArguments.length; i++) {
      log += "s=${inv.namedArguments[Symbol("s")]};";
    }
    return 42;
  }
}

class MA = Object with M;

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

main() {
  C().m1(1);
  expect('1;s1;', log);
  log = "";
  C().m2(2);
  expect('2;s=s2;', log);
  log = "";

  MA().m1(1);
  expect('1;s1;', log);
  log = "";
  MA().m2(2);
  expect('2;s=s2;', log);
}
