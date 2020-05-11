// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This library defines a set of test functions 'xxxAsBoolean" and a check
// combinator called `check` which test the runtime behavior of conversions
// of values in boolean condional positions (e.g. the condition of a conditional
// statement).
//
// For example: calling `check(dynamicAsBoolean, value, expectation)` tests that
// using `value` as the condition in a number of different syntactic constructs
// with static type `dynamic` behaves as expected by `expectation`, where
// `expectation` should be one of:
// Expect.throwsAssertionError if a null conversion error is expected
// Expect.throwsTypeError if an implicit cast error is expected
// expectOk if no runtime error is expected.

void expectOk(void Function() f) {
  f();
}

final int constructsTested = 11;

void check<T>(void Function(T, int) test, T value,
    void Function(void Function()) expectation) {
  for (int i = 0; i < constructsTested; i++) {
    expectation(() => test(value, i));
  }
}

void neverAsBoolean(Never value, int index) {
  // Check that values of type `Never` are boolean converted appropriately
  // In strong checking mode, this code is unreachable.  In weak checking mode,
  // we may get passed `null` for `value`, and so we check that the `null` value
  // causes an assertion error to be thrown appropriately.
  switch (index) {
    case 0:
      if (value) {}
      break;
    case 1:
      [if (value) 3];
      break;
    case 2:
      value ? 3 : 4;
      break;
    case 3:
      while (value) {
        break;
      }
      break;
    case 4:
      var done = false;
      do {
        if (done) break;
        done = true;
      } while (value);
      break;
    case 5:
      value || true;
      break;
    case 6:
      value && true;
      break;
    case 7:
      false || value;
      break;
    case 8:
      true && value;
      break;
    case 9:
      for (int i = 0; value; i++) {
        break;
      }
      break;
    case 10:
      [for (int i = 0; value; i++) 3];
      break;
    default:
      throw "Invalid index";
  }
}

void booleanAsBoolean(bool value, int index) {
  // Check that values of type `boolean` are boolean converted appropriately
  switch (index) {
    case 0:
      if (value) {}
      break;
    case 1:
      [if (value) 3];
      break;
    case 2:
      value ? 3 : 4;
      break;
    case 3:
      while (value) {
        break;
      }
      break;
    case 4:
      var done = false;
      do {
        if (done) break;
        done = true;
      } while (value);
      break;
    case 5:
      value || true;
      break;
    case 6:
      value && true;
      break;
    case 7:
      false || value;
      break;
    case 8:
      true && value;
      break;
    case 9:
      for (int i = 0; value; i++) {
        break;
      }
      break;
    case 10:
      [for (int i = 0; value; value = false) 3];
      break;
    default:
      throw "Invalid index";
  }
}

void dynamicAsBoolean(dynamic value, int index) {
  // Check that values of type `dynamic` are boolean converted appropriately
  switch (index) {
    case 0:
      if (value) {}
      break;
    case 1:
      [if (value) 3];
      break;
    case 2:
      value ? 3 : 4;
      break;
    case 3:
      while (value) {
        break;
      }
      break;
    case 4:
      var done = false;
      do {
        if (done) break;
        done = true;
      } while (value);
      break;
    case 5:
      value || true;
      break;
    case 6:
      value && true;
      break;
    case 7:
      false || value;
      break;
    case 8:
      true && value;
      break;
    case 9:
      for (int i = 0; value; i++) {
        break;
      }
      break;
    case 10:
      [for (int i = 0; value; value = false) 3];
      break;
    default:
      throw "Invalid index";
  }
}
