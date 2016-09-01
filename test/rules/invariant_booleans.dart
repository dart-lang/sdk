// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test/util/solo_test.dart invariant_booleans`

int bar = 1;

int baz = 2;

int foo = 0;
bool setting = null;

A a = new A();
B b = new B();

void bad() {
  if ((foo == bar && someComputation()) || (foo != bar && otherComputation())) {} // OK
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
}
void nestedBad1() {
  if (foo == bar) {
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
  if (foo < bar) {
  } else {
   if (foo < bar) {} // LINT
  }
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

void nestedOk4() {
  if (foo <= bar) {
    return;
  }

  if (foo == bar) {} // LINT
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
  if (foo < bar) {
  } else if (foo > bar) {} // OK
}

void nestedOk7() {
  if (foo < bar) {
  } else {
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

class A {
  bool foo;
  int fooNumber;
}

class B {
  bool bar;
  int barNumber;
}
