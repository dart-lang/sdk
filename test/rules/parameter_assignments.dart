// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N parameter_assignments`

void badFunction(int parameter) {
  parameter = 4; // LINT
}

void ok(String parameter) {
  print(parameter);
}

String get topLevelGetter => '';

class A {
  int get x => 0;

  set x(int value) {
    value = 5;  // LINT
  }

  void badFunction(int parameter) {
    parameter = 4; // LINT
  }

  void ok(String parameter) {
    print(parameter);
  }
}

void ok2(String parameter) {
  if (parameter == null) {
    int parameter = 2;
    parameter = 3;
  }
}

void otherBadNamed(int a, {int parameter: 5}) {
  print(parameter++); // LINT
}

void otherBad(int parameter) {
  print(parameter++); // LINT
}

void otherBad1(int parameter) {
  parameter += 3; // LINT
  print(parameter);
}

void actuallyGood(int required, {int optional}) { // OK
  optional ??= 8;
}

void actuallyGoodPositional(int required, [int optional]) { // OK
  optional ??= 8;
}

void butNotTwice(int required, [int optional]) {
  optional ??= 8;
  optional ??= 16; // LINT
}

void onceAgainBad01(int required, {int optional}) {
  optional ??= 8;
  optional = 42; // LINT
}

void onceAgainBad01Positional(int required, [int optional]) {
  optional ??= 8;
  optional = 42; // LINT
}

void onceAgainBad02(int required, {int optional: 42}) {
  optional ??= 8; // LINT
}

void onceAgainBad02Positional(int required, [int optional = 42]) {
  optional ??= 8; // LINT
}
