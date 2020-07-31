// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing that `noSuchMethod` forwarding properly handles optional, named and
// type parameters, and result type checking.

import 'package:expect/expect.dart';

class A {
  dynamic noSuchMethod(Invocation invoke) {
    if (invoke.memberName == #test0) {
      Expect.equals(invoke.positionalArguments[0], 1);
      Expect.equals(invoke.positionalArguments[1], 2);
      return null;
    } else if (invoke.memberName == #test1) {
      Expect.isTrue(invoke.namedArguments.length == 1);
      Expect.equals(null, invoke.namedArguments[#x]);
      return null;
    } else if (invoke.memberName == #test2) {
      Expect.isTrue(invoke.namedArguments.length == 1);
      Expect.equals("w/e", invoke.namedArguments[#x]);
      return null;
    } else if (invoke.memberName == #test3) {
      Expect.equals(invoke.namedArguments[#x], "ok");
      return null;
    } else if (invoke.memberName == #test4) {
      Expect.equals(invoke.positionalArguments[0], "ok");
      return null;
    } else if (invoke.memberName == #test5) {
      Expect.equals(invoke.typeArguments[0].toString(), "int");
      return null;
    } else if (invoke.memberName == #test6) {
      return 1;
    } else if (invoke.memberName == #test7) {
      return "hi";
    } else if (invoke.memberName == #allTogetherNow) {
      Expect.equals(invoke.typeArguments.length, 2);
      Expect.equals(invoke.typeArguments[0].toString(), "num");
      Expect.equals(invoke.typeArguments[1].toString(), "double");

      Expect.equals(invoke.positionalArguments.length, 1);
      Expect.equals(invoke.positionalArguments[0], 2.0);

      Expect.equals(invoke.namedArguments.length, 1);
      Expect.equals(invoke.namedArguments[#foo], const <num>[3, 4]);
      return 1;
    } else if (invoke.memberName == #test8) {
      Expect.equals(1, invoke.positionalArguments.length);
      Expect.equals(null, invoke.positionalArguments[0]);
    }
  }

  void test0(int x, int y);
  void test1({String? x});
  void test2({String x: "w/e"});
  void test3({String x: "w/e"});
  void test4([String? x]);
  void test5<T extends num>(T x);
  String test6();

  int get test7;
  void set test7(int x);

  void test8([String? x]);

  T allTogetherNow<T, S extends T>(S x1, {List<T> foo: const <Never>[]});
}

main() {
  var a = new A();

  a.test0(1, 2);
  (a.test0 as dynamic)(1, 2);

  a.test1();
  (a.test1 as dynamic)();

  a.test2();
  (a.test2 as dynamic)();

  a.test3(x: "ok");
  (a.test3 as dynamic)(x: "ok");

  a.test4("ok");
  (a.test4 as dynamic)("ok");

  a.test5<int>(1);
  (a.test5 as dynamic)<int>(1);
  Expect.throwsTypeError(() => (a.test5 as dynamic)<String>("foo"));
  Expect.throwsTypeError(() => (a.test5 as dynamic)<int>(3.1));

  Expect.throwsTypeError(() => a.test6());
  Expect.throwsTypeError(() => (a.test6 as dynamic)());

  Expect.throwsTypeError(() => a.test7);
  Expect.throwsTypeError(() => (a as dynamic).test7 = "hi");

  a.allTogetherNow<num, double>(2.0, foo: const <num>[3, 4]);

  a.test8();
}
