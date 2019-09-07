// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_int_literals`

import 'dart:math';

const double okDouble = 7.3; // OK
const double shouldBeInt1 = 8.0; // LINT
const double shouldBeInt2 = -8.0; // LINT
const double shouldBeInt3 = 88.00; // LINT

// TODO(danrubel): Consider linting these as well
const double shouldBeInt4 = 8.0 + 7.0; // OK

const inferredAsDouble = 8.0; // OK
Object inferredAsDouble2 = 8.0; // OK
dynamic inferredAsDouble3 = 8.0; // OK
final inferredAsDouble4 = 8.0 + 7.0; // OK

class A {
  var w = 7.0e2; // OK
  double x = 7.0e2; // LINT
  double y = 7.1e2; // LINT
  double z = 7.576e2; // OK
  A(this.x);
  namedDouble(String s, {double d}) {}
  namedDynamic(String s, {d}) {}
}

class B extends A {
  B.one() : super(1.0); // LINT
  B.two() : super(2.3); // OK
  B.three() : super(3);

  namedParam1() {
    namedDouble('should be int', d: 1.0); // LINT
  }

  namedParam2() {
    namedDynamic('should stay double', d: 1.0); // OK
  }

  double typedMethodReturn1() => 6.0; // LINT
  double typedMethodReturn2() {
    typedMethodReturn1();
    return 6.0; // LINT
  }

  untypedMethodReturn1() => 6.0; // OK
  untypedMethodReturn2() {
    untypedMethodReturn1();
    return 6.0; // OK
  }
}

void takesDouble(double value) {}

void typedVar() {
  takesDouble(3.0); // LINT
  takesDouble(-3.0); // LINT
  takesDouble(33.00); // LINT

  double myDouble1 = 5.0; // LINT

  myDouble1 = myDouble1 + 3.7; // OK
  myDouble1 = 5.7 * myDouble1 / myDouble1; // OK

  // TODO(danrubel): Consider if these can be converted to an int literal
  myDouble1 = 4.0 + myDouble1; // OK
  myDouble1 = myDouble1 + 4.0; // OK
  myDouble1 = myDouble1 - 4.0; // OK
  myDouble1 = myDouble1 * 4.0; // OK
  myDouble1 = myDouble1 / 4.0; // OK
}

void untypedVar() {
  var inferredAsInt = 3;

  var inferredAsDouble1 = inferredAsInt + 3.0; // OK
  var inferredAsDouble2 = inferredAsDouble1 + 3.7; // OK
  inferredAsDouble1 = inferredAsInt + 3.0; // OK
  inferredAsDouble2 = inferredAsDouble1 + 3.7; // OK

  // No static type info is not available for these
  var inferredAsDouble3 = inferredAsDouble2 + 3.0; // OK
  var inferredAsDouble4 = inferredAsDouble3 - 3.0; // OK
  inferredAsDouble3 = inferredAsDouble2 + 3.0; // OK
  inferredAsDouble4 = inferredAsDouble3 - 3.0; // OK

  int largeInt = 1 << 61 + 1;
  double largeDouble1 = largeInt * 360.0; // OK
  var largeDouble2 = largeInt * 360.0; // OK

  largeDouble1 = largeDouble1 + largeDouble2 + inferredAsDouble4;
}

double typedFunctReturn1() => 6.0; // LINT
double typedFunctReturn2(List<bool> b) {
  if (b[0]) return 6.0; // LINT
  if (b[1]) {
    return 6.0; // LINT
  }
  typedFunctReturn1();
  return 6.0; // LINT
}

untypedFunctReturn1() => 6.0; // OK
untypedFunctReturn2(List<bool> b) {
  if (b[0]) return 6.0; // OK
  if (b[1]) {
    return 6.0; // OK
  }

  double typedInnerReturn1() => 6.0; // LINT
  double typedInnerReturn2() {
    typedInnerReturn1();
    return 6.0; // LINT
  }

  typedInnerReturn2();

  untypedInnerReturn1() => 6.0; // OK
  untypedInnerReturn2() {
    untypedInnerReturn1();
    return 6.0; // OK
  }

  untypedInnerReturn2();

  untypedFunctReturn1();
  return 6.0; // OK
}

double typedExpressionReturn() {
  double myDouble = 6;

  // TODO(danrubel): Consider if this can be converted to an int literal
  return 6.0 + myDouble; // OK
}

linter_issue_1227() {
  int i = 1 << 61 + 1;
  var value1 = 360.0 * i; // OK
  return value1;
}

linter_issue_1231() {
  double myDouble = 3;
  max(3.0, 4); // OK
  max(myDouble, 5.0); // LINT
  var value1 = max(myDouble, 6.0); // LINT
  double value2 = max(myDouble, 7.0); // LINT
  return value1 + value2;
}

class LinterIssue1230 {
  static const List<double> list1 = <double>[50.0]; // LINT
  static const list2 = <double>[50.0]; // LINT
  static const list3 = [50.0]; // OK
}
