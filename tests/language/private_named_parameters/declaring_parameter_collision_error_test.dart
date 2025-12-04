// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// It's an error if a private named declaring parameter collides with an
/// explicit instance variable with the same name. (This is just the normal
/// error for a duplicate field, but we test it explicitly to make sure
/// implementations are checking that for private named parameters.)

// SharedOptions=--enable-experiment=private-named-parameters,primary-constructors

import 'package:expect/expect.dart';

/// Collide with explicitly declared field.
class C1({required final String _foo}) {
  final String _foo;
  //           ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified
}

/// Collide with previous private declaring parameter.
class C2({required final String _foo, required final String _foo}) {}
//                                                          ^^^^
// [analyzer] unspecified
// [cfe] unspecified

/// Collide with previous public declaring parameter.
class C3({required final String foo, required final String _foo}) {}
//                                                         ^^^^
// [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_DUPLICATE_PUBLIC_NAME
// [cfe] unspecified

/// Collide with previous private named parameter.
class C4({String? _foo, required final String _foo}) {}
//                ^^^^
// [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_NON_FIELD_PARAMETER
// [cfe] unspecified
//                                            ^^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [cfe] unspecified

/// Collide with previous public named parameter.
class C5({String? foo, required final String _foo}) {}
//                                           ^^^^
// [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_DUPLICATE_PUBLIC_NAME
// [cfe] unspecified

/// Collide with previous private positional parameter.
class C6(String _foo, {required final String _foo}) {}
//                                           ^^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [cfe] unspecified

/// Collide with previous public positional parameter.
class C7(String? foo, {required final String _foo}) {}
//                                           ^^^^
// [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_DUPLICATE_PUBLIC_NAME
// [cfe] unspecified

/// Collide with previous private initializing formal.
class C8(this._foo, {required final String _foo}) {
  //                                       ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] unspecified
  final String _foo;
  //           ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] unspecified
}

/// Collide with previous public initializing formal.
class C9(this.foo, {required final String _foo}) {
  //                                      ^^^^
  // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_DUPLICATE_PUBLIC_NAME
  // [cfe] unspecified
  final String foo;
}

/// Collide with later private named parameter.
class C10({required final String _foo, String? _foo}) {}
//                                             ^^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [cfe] unspecified

/// Collide with later public named parameter.
class C11({required final String _foo, String? foo}) {}
//                               ^^^^
// [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_DUPLICATE_PUBLIC_NAME
// [cfe] unspecified

/// Collide with later private initializing formal.
class C12({required final String _foo, required this._foo}) {
  //                                                 ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] unspecified
  final String _foo;
  //           ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] unspecified
}

/// Collide with later public initializing formal.
class C13({required final String _foo, required this.foo}) {
  //                             ^^^^
  // [analyzer] COMPILE_TIME_ERROR.PRIVATE_NAMED_PARAMETER_DUPLICATE_PUBLIC_NAME
  // [cfe] unspecified
  final String foo;
}

void main() {}
