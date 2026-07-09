// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main(List<String> arguments) {}

void test(int positional, {int named1 = 0, int named2 = 0}) {}

class Sueta {
  static void test(int positional, {int named1 = 0, int named2 = 0}) {}
}

extension SuetaExtension on Sueta {
  static void test(int pos, {int named1 = 0, int named2 = 0}) {}
}

void test1() {
  test(named1: 0, 1, named2: 0);
}

void test2() {
  Sueta.test(named1: 0, 1, named2: 0);
}

/// couldn't compile
void test3() {
  SuetaExtension.test(named1: 0, 1, named2: 0);
}
