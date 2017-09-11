// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:expect/expect.dart';

class C {
  dynamic f(int x) => x + 1;
  dynamic g(int x) => x + 2;
}

class D extends C {
  f(int x) => x + 41;
  get superF => super.f;
  get superG => super.g;
}

tearoffEquals(f1, f2) {
  Expect.equals(f1, f2);
  Expect.equals(f1.hashCode, f2.hashCode);
}

tearoffNotEquals(f1, f2) {
  Expect.notEquals(f1, f2);
  Expect.notEquals(f1.hashCode, f2.hashCode);
}

testDynamic() {
  C c = new C();

  dynamic f1 = c.f;
  Expect.throws(() => f1(2.5));
  Expect.equals(f1(41), 42);

  dynamic f2 = (c as dynamic).f;
  Expect.throws(() => f2(2.5));
  Expect.equals(f2(41), 42);

  tearoffEquals(f1, f1);
  tearoffEquals(f1, f2);
  tearoffEquals(f1, c.f);
  tearoffEquals(c.g, (c as dynamic).g);

  tearoffNotEquals(f1, new C().f);
  tearoffNotEquals(f1, (new C() as dynamic).f);
  tearoffNotEquals(f1, c.g);
  tearoffNotEquals(f1, (c as dynamic).g);
  tearoffNotEquals(null, f1);
  tearoffNotEquals(f1, null);
}

testSuper() {
  D d = new D();
  dynamic superF1 = d.superF;
  dynamic superF2 = (d as dynamic).superF;

  Expect.throws(() => superF1(2.5));
  Expect.throws(() => superF2(2.5));
  Expect.equals(superF1(41), 42);
  Expect.equals(superF2(41), 42);

  tearoffEquals(superF1, superF1);
  tearoffEquals(superF1, superF2);
  tearoffEquals(superF1, d.superF);
  tearoffEquals(d.f, (d as dynamic).f);

  tearoffNotEquals(superF1, d.f);
  tearoffNotEquals(superF1, (d as dynamic).f);
  tearoffNotEquals(superF1, new D().superF);
  tearoffNotEquals(superF1, (new D() as dynamic).superF);
  tearoffNotEquals(superF1, d.superG);
  tearoffNotEquals(superF1, (d as dynamic).superG);

  tearoffEquals(d.superG, (d as dynamic).superG);
  tearoffEquals(d.g, d.superG);
}

class S {
  final int id;
  S(this.id);
  toString() => 'S#$id';
}

testToString() {
  testType<T>(T c) {
    dynamic d = c;
    Object o = c;
    tearoffEquals(c.toString, d.toString);
    tearoffEquals(c.toString, o.toString);

    var expected = c.toString();
    dynamic f = d.toString;
    tearoffEquals(f(), expected);
    f = o.toString;
    tearoffEquals(f(), expected);
    var g = c.toString;
    tearoffEquals(g(), expected);
  }

  testType(new C());
  testType(new D());
  testType(new S(1));
  testType(new S(2));
  testType(new Object());
  testType(null);
  testType(Object); // Type
  testType(C); // Type
  testType(42);
  testType('hi');
  testType(true);
  testType([1, 2, 3]);
  testType({'a': 'b'});
  testType((x) => x + 1);
  testType(testType);
}

class N {
  noSuchMethod(i) => i;
}

testNoSuchMethod() {
  // Create an invocation.
  Invocation i = (new N() as dynamic).foo(1, bar: 2);
  tearoffEquals(i.memberName, #foo);

  testType<T>(T c) {
    dynamic d = c;
    Object o = c;
    tearoffEquals(c.noSuchMethod, d.noSuchMethod);
    tearoffEquals(c.noSuchMethod, o.noSuchMethod);

    var expected;
    try {
      c.noSuchMethod(i);
    } on NoSuchMethodError catch (error) {
      var nsm = '$error';
      Expect.isTrue(nsm.startsWith("NoSuchMethodError: "));
      Expect.isTrue(nsm.contains("'foo'"));
      expected = (e) => e is NoSuchMethodError && '$e' == nsm;
    }
    dynamic f = d.noSuchMethod;
    Expect.throws(() => f(i), expected);
    f = o.noSuchMethod;
    Expect.throws(() => f(i), expected);
    var g = c.noSuchMethod;
    Expect.throws(() => g(i), expected);
  }

  testType(new C());
  testType(new D());
  testType(new S(1));
  testType(new S(2));
  testType(new Object());
  testType(null);
  testType(Object); // Type
  testType(C); // Type
  testType(42);
  testType('hi');
  testType(true);
  testType([1, 2, 3]);
  testType({'a': 'b'});
  testType((x) => x + 1);
  testType(testType);
}

main() {
  testDynamic();
  testSuper();
  testToString();
  testNoSuchMethod();
}
