// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for testing access to private fields.

part of PrivateTest.dart;

main() {
  testPrivateTopLevel();
  testPrivateClasses();
}

void expectCatch(f) {
  bool threw = false;
  try {
    f();
  } catch (e) {
    threw = true;
  }
  Expect.equals(true, threw);
}

String _private1() => "private1";
const String _private1Field = "private1Field";

void testPrivateTopLevel() {
  Expect.equals("private1", _private1());
  Expect.equals("private2", _private2());
  Expect.equals("private1Field", _private1Field);
  Expect.equals("private2Field", _private2Field);
}

class _A {
  _A() : fieldA = 499;

  int fieldA;
}

class AExposed extends _A {
  AExposed() : super();
}

class B {
  int _fieldB;
  B() : _fieldB = 42;
}

class C1 {
  int _field1;
  C1() : _field1 = 499;

  field1a() => _field1;
}

class C3 extends C2 {
  int _field2;
  C3()
      : _field2 = 42,
        super();

  field2a() => _field2;
  field1c() => _field1;
}

int c_field1a(c) => c._field1;
int c_field2a(c) => c._field2;

int _field1FromNewC4() => new C4()._field1;
int _field2FromNewC4() => new C4()._field2;

void testPrivateClasses() {
  _A a = new _A();
  Expect.equals(499, a.fieldA);
  Expect.equals(499, accessFieldA2(a));
  Expect.equals(499, LibOther3.accessFieldA3(a));

  var a2 = new AImported();
  Expect.equals(499, a2.getFieldA());

  B b = new B();
  Expect.equals(42, b._fieldB);
  Expect.equals(42, accessFieldB2(b));
  expectCatch(() => LibOther3.accessFieldB3(b));

  C4 c = new C4();
  Expect.equals(499, c._field1);
  Expect.equals(499, c_field1a(c));
  Expect.equals(499, c.field1a());
  Expect.equals(42, c._field2);
  Expect.equals(42, c_field2a(c));
  Expect.equals(42, c.field2a());
  Expect.equals(99, LibOther3.c_field1b(c));
  Expect.equals(99, c.field1b());
  Expect.equals(1024, LibOther3.c_field2b(c));
  Expect.equals(1024, c.field2b());
  Expect.equals(499, c.field1c());
  Expect.equals(99, c.field1d());
  Expect.equals(499, _field1FromNewC4());
  Expect.equals(42, _field2FromNewC4());
}
