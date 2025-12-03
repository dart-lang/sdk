// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// It's an error if a private named parameter collides with another parameter
/// with the same public or private name.

// SharedOptions=--enable-experiment=private-named-parameters

class C {
  String? foo;
  final String? _foo;

  // Colliding initializing formals.
  C.a({required this._foo, required this._foo}) {}
  //                                     ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_FIELD_FORMAL_PARAMETER
  // [cfe] unspecified

  // Collide with previous public initializing formal.
  C.b({required this.foo, required this._foo}) {}
  //                                    ^^^^
  // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_DUPLICATE_PUBLIC_NAME
  // [cfe] unspecified

  // Collide with later private named.
  C.c({required this._foo, String? _foo}) {}
  //                               ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] unspecified
  //                               ^^^^
  // [analyzer] SYNTACTIC_ERROR.PRIVATE_NAMED_NON_FIELD_PARAMETER
  // [cfe] unspecified

  // Collide with later public named.
  C.d({required this._foo, String? foo}) {}
  //                 ^^^^
  // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_DUPLICATE_PUBLIC_NAME
  // [cfe] unspecified

  // Collide with previous private named.
  C.e({String? _foo, required this._foo}) {}
  //           ^^^^
  // [analyzer] SYNTACTIC_ERROR.PRIVATE_NAMED_NON_FIELD_PARAMETER
  // [cfe] unspecified
  //                               ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] unspecified

  // Collide with previous public named.
  C.f({String? foo, required this._foo}) {}
  //                              ^^^^
  // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_DUPLICATE_PUBLIC_NAME
  // [cfe] unspecified

  // Collide with previous private positional.
  C.g(String _foo, {required this._foo}) {}
  //                              ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] unspecified

  // Collide with previous public positional.
  C.h(String? foo, {required this._foo}) {}
  //                              ^^^^
  // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_DUPLICATE_PUBLIC_NAME
  // [cfe] unspecified
}

void main() {}
