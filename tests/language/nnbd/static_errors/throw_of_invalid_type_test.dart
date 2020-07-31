// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Test that it is an error if the static type of `e` in the expression
// `throw e` is not assignable to `Object`.
import 'package:expect/expect.dart';

main() {
  f1(0);
  f2(0);
  f3();
}

void f1(int a) {
  try {
    throw a;
  } catch (e) {}
}

void f2(int? a) {
  try {
    throw a; //# 01: compile-time error
  } catch (e) {}
}

void f3() {
  try {
    throw null; //# 02: compile-time error
  } catch (e) {}
}
