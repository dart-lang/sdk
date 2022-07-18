// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  testUninitializedNonFinalInstanceField();
  testUninitializedFinalInstanceField();
  testInitializedNonFinalInstanceField();
  testInitializedFinalInstanceField();
}

class C {
  @pragma('dart2js:late:trust')
  late int a;

  @pragma('dart2js:late:check')
  late final int b;

  @pragma('dart2js:late:trust')
  @pragma('dart2js:tryInline')
  late int c = -1;

  @pragma('dart2js:late:check')
  @pragma('dart2js:noInline')
  late final int d = -1;
}

var c = C();

void testUninitializedNonFinalInstanceField() {
  print(c.a);
  c.a = 42;
  print(c.a);
}

void testUninitializedFinalInstanceField() {
  print(c.b);
  c.b = 42;
  print(c.b);
}

void testInitializedNonFinalInstanceField() {
  print(c.c);
  c.c = 42;
  print(c.c);
}

void testInitializedFinalInstanceField() {
  print(c.d);
}
