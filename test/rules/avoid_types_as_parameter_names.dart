// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_types_as_parameter_names`

typedef void f1(); // OK
typedef void f2(int a); // OK
typedef void f3(int); // LINT
typedef void f4(
  num a, // OK
  {
  int, // LINT
});
typedef void f5(
  double a, // OK
  [
  bool, // LINT
]);

m1(f()) => null; // OK
m2(f(int a)) => null; // OK
m3(f(int)) => null; // LINT
m4(f(num a, {int})) => null; // LINT
m5(f(double a, [bool])) => null; // LINT
