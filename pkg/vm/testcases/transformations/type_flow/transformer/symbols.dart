// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies constant propagation and parameter elimination for symbols.

void test0(Symbol arg) {
  print(arg);
}

void test1([Symbol arg = #defaultSymbol]) {
  print(arg);
}

void test2({Symbol arg = #namedDefaultSymbol}) {
  print(arg);
}

Symbol getSymbol() => #getterSymbol;

void testSymbol(Symbol arg) {
  print(arg);
  print(getSymbol());
}

void main() {
  test0(#foo);
  test1();
  test2();
  testSymbol(#bar);
}
