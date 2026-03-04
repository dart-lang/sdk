// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A compile-time error occurs if a class, enum, or extension type has a
// primary constructor whose name is also the name of a constructor declared
// in the body.

// SharedOptions=--enable-experiment=primary-constructors

class C1(final int x) {
  C1(this.x);
  // [error column 3, length 2]
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_CONSTRUCTOR
  // [analyzer] COMPILE_TIME_ERROR.NON_REDIRECTING_GENERATIVE_CONSTRUCTOR_WITH_PRIMARY
  // [cfe] 'C1' is already declared in this scope.
}

class C2.named(final int x) {
  C2.named(this.x);
  // [error column 3, length 8]
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_CONSTRUCTOR
  // [analyzer] COMPILE_TIME_ERROR.NON_REDIRECTING_GENERATIVE_CONSTRUCTOR_WITH_PRIMARY
  // [cfe] 'C2.named' is already declared in this scope.
}

enum E1(final int x) {
  e(1);
  const E1(this.x);
  //    ^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_CONSTRUCTOR
  // [analyzer] COMPILE_TIME_ERROR.NON_REDIRECTING_GENERATIVE_CONSTRUCTOR_WITH_PRIMARY
  // [cfe] 'E1' is already declared in this scope.
}

enum E2.named(final int x) {
  e(1);
  // [error column 3, length 1]
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_ENUM_CONSTRUCTOR
  // [cfe] Couldn't find constructor 'E2'.
  const E2.named(this.x);
  //    ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_CONSTRUCTOR
  // [analyzer] COMPILE_TIME_ERROR.NON_REDIRECTING_GENERATIVE_CONSTRUCTOR_WITH_PRIMARY
  // [cfe] 'E2.named' is already declared in this scope.
}

extension type ET1(int x) {
  ET1(this.x);
  // [error column 3, length 3]
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_CONSTRUCTOR
  // [cfe] 'ET1' is already declared in this scope.
}

extension type ET2.named(int x) {
  ET2.named(this.x);
  // [error column 3, length 9]
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_CONSTRUCTOR
  // [cfe] 'ET2.named' is already declared in this scope.
}

class C3(int x) {
  C3.other(int x) : this(x);
  // [error column 3]
  // [cfe] Classes with primary constructors can't have non-redirecting generative constructors.
  //                ^
  // [cfe] Couldn't find constructor 'C3'.
  factory C3(int x) => C3.other(x);
  //      ^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_CONSTRUCTOR
  // [cfe] 'C3' is already declared in this scope.
}

class C4.named(int x) {
  C4.other(int x) : this.named(x);
  // [error column 3]
  // [cfe] Classes with primary constructors can't have non-redirecting generative constructors.
  //                     ^
  // [cfe] Couldn't find constructor 'C4.named'.
  factory C4.named(int x) => C4.other(x);
  //      ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_CONSTRUCTOR
  // [cfe] 'C4.named' is already declared in this scope.
}
