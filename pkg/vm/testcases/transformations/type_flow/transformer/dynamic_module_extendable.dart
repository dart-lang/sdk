// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for @pragma('dyn-module:extendable').

abstract class A1 {
  Object foo(); // Unboxed.
}

class B1 implements A1 {
  int foo() => 42;
}

abstract class C1 implements A1 {} // Unused, eliminated.

abstract class A2 {
  @pragma('dyn-module:can-be-overridden')
  Object foo(); // Not unboxed.
}

class B2 implements A2 {
  int foo() => 42;
}

@pragma('dyn-module:extendable')
abstract class C2 implements A2 {} // Not eliminated.

void call1(A1 obj) {
  print(obj.foo()); // Devirtualized, constant result.
}

void call2(A2 obj) {
  print(obj.foo()); // Not devirtualized, no constant result.
}

void cast1(A1 obj) {
  print(obj is B1); // Eliminated.
  print(obj as B1); // Eliminated.
}

void cast2(A2 obj) {
  print(obj is B2); // Not eliminated.
  print(obj as B2); // Not eliminated.
}

List opaque = []
  ..add(B1())
  ..add(B2());

main() {
  call1(opaque[0]);
  call2(opaque[1]);
  cast1(opaque[0]);
  cast2(opaque[1]);
}
