// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N invariant_booleans`

void deadCodeWithIfAndElseExit() {
  int localFoo = 3, localBar = 4;
  if (localFoo < localBar) {
    return;
  }
  else {
    return;
  }
  // ignore: dead_code
  if (localFoo < localBar) { // OK

  }
}

void returnMustUndefineAll() {
  int localFoo = 3, localBar = 4;
  if (localFoo < localBar) {
    return;
    // ignore: dead_code
    if (localFoo < localBar) { // OK

    }
  }
}

void throwMustUndefineAll() {
  int localFoo = 3, localBar = 4;
  if (localFoo < localBar) {
    throw new Exception();
    // ignore: dead_code
    if (localFoo < localBar) { // OK

    }
  }
}

void rethrowMustUndefineAll() {
  int localFoo = 3, localBar = 4;
  try {
  } catch(exception) {
    if (localFoo < localBar) {
      rethrow;
      // ignore: dead_code
      if (localFoo < localBar) { // OK

      }
    }
  }

}

void forStatementWithLabels() {
  int localFoo = 3, localBar = 4;
  label: for (;localFoo < 3;) {
    for (;localBar>4;) {
      break label;
    }
  }
  if (localFoo < 3) {} // OK
}

void whileStatementWithLabels() {
  int localFoo = 3, localBar = 4;
  label: while (localFoo < 3) {
    while (localBar>4) {
      break label;
    }
  }
  if (localFoo < 3) {} // OK
}

void forStatementTest1() {
  int localFoo = 3, localBar = 4;
  for (;localFoo < localBar;) {
    print('hola mundo');
  }
  if (localFoo < localBar) { // LINT
    print('should not see this');
  }
}

void forStatementTest2() {
  int localFoo = 3, localBar = 4, localBaz = 5;
  for (;localFoo < localBar;) {
    for (;localFoo < localBaz;) {
      break;
    }
  }
  if (localFoo < localBar) { // LINT
    print('should not see this');
  }
}

void forStatementTest3() {
  int localFoo = 3, localBar = 4;
  for (;localFoo < localBar ;) {
    break;
  }
  if (localFoo < localBar) { // OK
    print('should not see this');
  }
}

void whileStatementTest1() {
  int localFoo = 3, localBar = 4;
  while (localFoo < localBar) {
    print('hola mundo');
  }
  if (localFoo < localBar) { // LINT
    print('should not see this');
  }
}

void whileStatementTest2() {
  int localFoo = 3, localBar = 4, localBaz = 5;
  while (localFoo < localBar) {
    while (localFoo < localBaz) {
      break;
    }
  }
  if (localFoo < localBar) { // LINT
    print('should not see this');
  }
}

void whileStatementTest3() {
  int localFoo = 3, localBar = 4;
  while (localFoo < localBar) {
    break;
  }
  if (localFoo < localBar) { // OK
    print('should not see this');
  }
}

void forStatementWithLabeledBreak() {
  int localFoo = 3, localBar = 4;
  outer:
  for (;localFoo < localBar;) {
    if (localFoo < localBar - 1) {
      break outer;
    }
  }
  if (localFoo < localBar) { // OK
    print('should not see this');
  }
}

void whileStatementWithLabeledBreak() {
  int localFoo = 3, localBar = 4;
  outer:
  while (localFoo < localBar) {
    if (localFoo < localBar - 1) {
      break outer;
    }
  }
  if (localFoo < localBar) { // OK
    print('should not see this');
  }
}

int bar = 1;

int baz = 2;

int foo = 0;
bool setting;

class A {
  bool foo;
  int fooNumber;
}

class B {
  bool bar;
  int barNumber;
}

A a = new A();
B b = new B();

void bad() {
  if ((foo == bar && someComputation()) ||
      (foo != bar && otherComputation())) {} // OK
  if (foo > bar || foo == bar) {} // OK
  if (a.fooNumber > b.barNumber || a.fooNumber == b.barNumber) {} // OK
  if (foo > bar && someComputation() || foo == bar) {} // OK
  if (foo > bar || foo == bar && someComputation()) {} // OK
  if (foo < bar - baz || foo > bar) {} // OK
  if (setting == true) {} // OK
  if (setting != true) {} // OK
  if (a.foo == b.bar || a.foo != b.bar) {} // LINT
  if (foo == bar || foo != bar) {} // LINT
  if (foo == bar || bar != foo) {} // LINT
  if (foo == bar && foo != bar) {} // LINT
  if (foo == bar && someComputation() && foo != bar) {} // LINT
  if (foo > bar && someComputation() && foo <= bar) {} // LINT
  if (foo > bar && someComputation() && foo < bar) {} // LINT
  if (foo < bar && someComputation() && foo > bar) {} // LINT
  if (foo < bar && foo > bar) {} // LINT
  if (true || foo == bar) {} // LINT
  if (false || foo == bar) {} // LINT
  if (false && foo == bar) {} // LINT
  if (true && foo == bar) {} // LINT
  if (foo > bar && foo == bar) {} // LINT
  if (foo < bar && foo == bar) {} // LINT
  if (foo > bar && someComputation() && foo == bar) {} // LINT
  if (foo > bar && someComputation() || foo == bar && foo != bar) {} // LINT
  if (foo > bar && foo > bar) {} // LINT
  if (foo > bar && bar < foo) {} // LINT
  if (foo == bar && bar == foo) {} // LINT
  while (foo == bar && bar == foo) {} // LINT
  for (; foo == bar && bar == foo;) {} // LINT
  do {} while (foo == bar && bar == foo); // LINT
}

void nestedBad1_1() {
  if (foo == bar) {
    if (foo != bar) {} // LINT
  }
}

void nestedBad1_2() {
  if (foo == bar) {
    while (foo != bar) {} // LINT
  }
}

void nestedBad1_3() {
  while (foo == bar) {
    if (foo != bar) {} // LINT
  }
}

void nestedBad2() {
  if (foo == bar) {
    return;
  }

  if (foo == bar) {} // LINT
}

void nestedBad7() {
  if (foo < bar) {} else {
    if (foo < bar) {} // LINT
  }
}

void nestedBad8() {
  if (foo <= bar) {
    return;
  }

  if (foo == bar) {} // LINT
}

void nestedOK1() {
  if (foo == bar) {
    foo = baz;
    if (foo != bar) {} // OK
  }
}

void nestedOk2() {
  if (foo == bar) {
    return;
  }

  foo = baz;
  if (foo == bar) {} // OK
}

void nestedOk3() {
  if (foo < bar) {
    return;
  }

  if (foo == bar) {} // OK
}

void nestedOk5() {
  if (foo != null) {
    if (bar != null) {
      return;
    }
  }

  if (bar != null) {} // OK
}

void nestedOk5_1() {
  if (foo != null) {
    if (bar != null) {
      return;
    }
  }

  if (foo != null) {} // OK
}

void nestedOk6() {
  if (foo < bar) {} else if (foo > bar) {} // OK
}

void nestedOk7() {
  if (foo < bar) {} else {
    if (foo > bar) {} // OK
  }
}

void nestedOk8() {
  if (foo == bar) {
    foo = baz;
    if (foo == bar) {} // OK
  }
}

bool otherComputation() {
  // Ignore return value, assume more complex logic.
  return false;
}

bool someComputation() {
  // Ignore return value, assume more complex logic.
  return false;
}

String sixDigits(int n) {
  if (n >= 100000) return "$n";
  if (n >= 10000) return "0$n";
  if (n >= 1000) return "00$n";
  if (n >= 100) return "000$n";
  if (n >= 10) return "0000$n";
  return "00000$n";
}

someFunction() {
  int a = new DateTime.now().millisecondsSinceEpoch;

  innerFunction() {
    if (a > 0) {
      return false;
    }
  }

  otherInnerFunction() => a > 0 ? false : null;

  if (a > 0) {
    // OK
    print('bla');
  }
}

class Foo {
  bool bar;
  void sayHello() {
    if (bar ?? false) print('hello');
  }
}

Iterable bug368(Iterable values) {
  if (values?.isEmpty ?? true) return [];
  return values.toList();
}

bool bug371(dynamic other, dynamic productTypes) {
  if (productTypes == null && other.productTypes == null) return true;
  if (productTypes == null || other.productTypes == null) return false;
  return true;
}

/// https://github.com/dart-lang/linter/issues/373
void bug373(int foo) {
  bool bar = true;
  if (foo == 4 && bar && foo > 4) {} // LINT
  if (foo == 4 && bar) {
    // doSomething();
    if (foo > 4) { // LINT
      // ...
    }
    // ...
  }
}

void bug372(bool foo) {
  if (foo) {
    return;
  }
  // doSomething();

  if (foo) { // LINT
    // doSomethingElse();
  }
}

void bug337_1(int offset, int length) {
  if (offset >= length) {
    return;
  }

  offset++;
  if (offset >= length) { // OK
  }
}

void bug337_2(int offset, int length) {
  if (offset >= length) {
    return;
  }

  offset--;
  if (offset >= length) { // OK
  }
}

void bug337_3(int offset, int length) {
  if (offset >= length) {
    return;
  }

  ++offset;
  if (offset >= length) { // OK
  }
}

void bug337_4(int offset, int length) {
  if (offset >= length) {
    return;
  }

  --offset;
  if (offset >= length) { // OK
  }
}

void test337_5() {
  int b = 2;
  if (b > 0) {
    b--;
    if (b == 0) {
      return;
    }
    if (b > 0) {
      return;
    }
  }
}

void bug658() {
  String text;
  if ((text?.length ?? 0) != 0) {}
}

void bug811_1() {
  final bar = 0;
  final foo = 10;

  for (var i = 0; i < foo; ++i) {}

  for (var i = 0; i < foo; i++) {} // OK

  if (bar == 10) {}
}

void bug811_2() {
  var bar = 0;
  final foo = 10;

  for (bar = 0; bar < foo; ++bar) {}

  for (bar = 0; bar < foo; bar++) {}

  if (bar < foo) {} // LINT
}
