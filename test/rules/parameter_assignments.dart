// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N parameter_assignments`

void badFunction(int parameter) { // LINT
  parameter = 4;
}

void ok(String parameter) {
  print(parameter);
}

String get topLevelGetter => '';

class A {
  int get x => 0;

  set x(int value) { // LINT
    value = 5;
  }

  void badFunction(int parameter) { // LINT
    parameter = 4;
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

void otherBad(int parameter) { // LINT
  print(parameter++);
}

void otherBad1(int parameter) { // LINT
  parameter += 3;
  print(parameter);
}
