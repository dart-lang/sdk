// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

expressionBranching() {
  null ?? 1 + 1; // LINT
  null ?? foo; // LINT
  null ?? new MyClass().foo; // LINT
  false || 1 + 1 == 2; // LINT
  false || foo == true; // LINT
  false || new MyClass() as bool; // OK
  false || new MyClass().foo == true; // LINT
  true && 1 + 1 == 2; // LINT
  true && foo == true; // LINT
  true && new MyClass() as bool; // OK
  true && new MyClass().foo == true; // LINT

  // ternaries can detect either/both sides
  someBool // OK
      ? 1 + 1 // LINT
      : foo(); // OK
  someBool // OK
      ? foo() // OK
      : foo; // LINT
  someBool // OK
      ? new MyClass() // OK
      : foo(); // OK
  someBool // OK
      ? foo() // OK
      : new MyClass().foo; // LINT
  someBool // OK
      ? [] //LINT
      : {}; // LINT

  // not unnecessary condition, but unnecessary branching
  foo() ?? 1 + 1; // LINT
  foo() || new MyClass() as bool; // OK
  foo() && foo == true; // LINT
  foo() ? 1 + 1 : foo(); // LINT
  foo() ? foo() : foo; // LINT
  foo() ? foo() : new MyClass().foo; // LINT

  null ?? new MyClass(); // OK
  null ?? foo(); // OK
  null ?? new MyClass().foo(); // OK
  false || foo(); // OK
  false || new MyClass().foo(); // OK
  true && foo(); // OK
  true && new MyClass().foo(); // OK
  someBool ? foo() : new MyClass().foo(); // OK
  foo() ? foo() : new MyClass().foo(); // OK
  foo() ? new MyClass() : foo(); // OK
}

inOtherStatements() {
  if (foo()) {
    1; // LINT
  }
  while (someBool) {
    1 + 1; // LINT
  }
  for (foo; foo();) {} // LINT
  for (; foo(); 1 + 1) {} // LINT
  for (;
      foo();
      foo(), // OK
      1 + 1, // LINT
      new MyClass().foo) {} // LINT
  do {
    new MyClass().foo; // LINT
  } while (foo());

  switch (foo()) {
    case true:
      []; // LINT
      break; // OK
    case false:
      <dynamic, dynamic>{}; // LINT
      break; // OK
    default:
      "blah"; // LINT
  }

  for (var i in [1, 2, 3]) {
    ~1; // LINT
  }
}

bool someBool = true;
bool foo() => true;

class MyClass {
  bool foo() => true;
}
