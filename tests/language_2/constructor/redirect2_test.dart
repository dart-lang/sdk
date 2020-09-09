// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Redirection constructors must not have a function body.

class A {
  var x;
  A(this.x) {}

  // Redirecting constructor must not have a function body.
  A.illegalBody(x) : this(3) {}
  //                         ^
  // [analyzer] SYNTACTIC_ERROR.REDIRECTING_CONSTRUCTOR_WITH_BODY
  // [cfe] Redirecting constructors can't have a body.

  // Redirecting constructor must not initialize any fields.
  A.illegalInit() : this(3), x = 5;
  //                         ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR
  //                           ^
  // [cfe] A redirecting constructor can't have other initializers.

  // Redirecting constructor must not have initializing formal parameters.
  A.illegalFormal(this.x) : this(3);
  //              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR
  //                   ^
  // [cfe] A redirecting constructor can't have other initializers.

  // Redirection constructors must not call super constructor.
  A.illegalSuper() : this(3), super(3);
  //                          ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.SUPER_IN_REDIRECTING_CONSTRUCTOR
  // [cfe] A redirecting constructor can't have other initializers.
  //                               ^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_POSITIONAL_ARGUMENTS
  // [cfe] Too many positional arguments: 0 allowed, but 1 found.
}

main() {
  new A(3);
  new A.illegalBody(10);
  new A.illegalInit();
  new A.illegalFormal(10);
  new A.illegalSuper();
}
