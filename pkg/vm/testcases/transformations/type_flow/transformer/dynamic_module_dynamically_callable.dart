// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for @pragma('dyn-module:dynamically-callable').

abstract class A {
  @pragma('dyn-module:dynamically-callable')
  Object method1(); // Not eliminated

  @pragma('dyn-module:dynamically-callable')
  Object method2() => 42; // Not eliminated

  Object method3() => 1; // Eliminated
}

class B extends A {
  @pragma('dyn-module:implicitly-dynamically-callable')
  int method1() => 42; // Not eliminated

  Object method4() => 1; // Eliminated
}

class C implements A {
  @pragma('dyn-module:implicitly-dynamically-callable')
  int method1() => 42; // Not eliminated

  @pragma('dyn-module:implicitly-dynamically-callable')
  int method2() => 42; // Not eliminated

  Object method3() => 2; // Eliminated

  @pragma('dyn-module:dynamically-callable')
  Object method5() => 42; // Not eliminated

  Object method6() => 1; // Eliminated
}

abstract class D {
  Object method7(); // Eliminated
}

class E implements D {
  @pragma('dyn-module:dynamically-callable')
  int get field1 => 0;

  int method7() => 3; // Eliminated
}

abstract class F {
  Object method8(); // Eliminated
}

class G implements F {
  @pragma('dyn-module:implicitly-dynamically-callable')
  int field1 = 0; // Not eliminated

  int field2 = 0; // Eliminated

  int method8() => 4; // Eliminated

  @pragma('dyn-module:dynamically-callable')
  int method9() => 42; // Eliminated

  @pragma('dyn-module:dynamically-callable')
  int get getter2 => 0; // Not eliminated

  @pragma('dyn-module:dynamically-callable')
  void set setter2(int v) {} // Not eliminated

  int field3 = 0; // Eliminated

  int get getter4 => 0; // Eliminated

  void set setter4(int v) {} // Eliminated
}

main() {}
