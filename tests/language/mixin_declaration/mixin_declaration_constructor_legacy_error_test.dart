// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test behavior when using a class as a mixin.
// @dart=2.19

// A class declaration cannot declare any non-factory constructors
// and be used as a mixin.
// A mixin declaration cannot declare any constructors.

class A {}

class B implements M, C1, C2, C3 {
  const B();
}

mixin M on A {
  factory M.foo() => throw "uncalled";
  // [error column 3, length 7]
  // [analyzer] SYNTACTIC_ERROR.MIXIN_DECLARES_CONSTRUCTOR
  // [cfe] Mixins can't declare constructors.
  const factory M.bar() = B;
  //    ^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.MIXIN_DECLARES_CONSTRUCTOR
  // [cfe] Mixins can't declare constructors.
  M.baz();
  // [error column 3, length 1]
  // [analyzer] SYNTACTIC_ERROR.MIXIN_DECLARES_CONSTRUCTOR
  // [cfe] Mixins can't declare constructors.
  M.qux() : this.baz();
  // [error column 3, length 1]
  // [analyzer] SYNTACTIC_ERROR.MIXIN_DECLARES_CONSTRUCTOR
  // [cfe] Mixins can't declare constructors.
}

// In Dart 3.0, it's OK for a mixin class to have factory constructors
// and trivial non-redirecting generative constructors.
// (Trivial means: No initializer list, no body, no parameters.
// That is, anything which does anything, and can't be ignored.)
// Not so for classes used as mixins in <3.0.

// (Cannot test a class with *only* a redirecting generative constructor,
// it also needs a constructor to redirect to.)
class C1 {
  factory C1.foo() => const B(); // Factory constructor is OK.
}

class C2 {
  const factory C2.bar() = B; // Redirecting factory constructor is OK.
}

// Generative constructor means cannot be used as mixin.
class C3 {
  const C3.baz(); // Trivial generative constructor is not OK.
}

class AC1 = A with C1;
class AC2 = A with C2;
class AC3 = A with C3;
//    ^
// [cfe] Can't use 'C3' as a mixin because it has constructors.
//                 ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR

main() {}
