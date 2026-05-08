// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is a compile-time error if an extension type does not contain a declaring
// constructor that has exactly one declaring parameter which is final.
// With primary constructors, the extension type representation type/value name
// declaration must still have exactly one parameter, which must be declaring.
// The `final` can be omitted, but a `var` cannot be used.

// SharedOptions=--enable-experiment=primary-constructors

// -----------------
// No `var` allowed.

extension type ET1(var int i);
//                 ^
// [analyzer] unspecified
// [cfe] unspecified

extension type ET2(var i);
//                 ^
// [analyzer] unspecified
// [cfe] unspecified

// --------------------------------
// Must have exactly one parameter.

extension type ET3(final i, final x);
//                          ^
// [analyzer] unspecified
// [cfe] unspecified

extension type ET4(int i, int x);
//                        ^
// [analyzer] unspecified
// [cfe] unspecified

extension type ET5(int i, final x);
//                        ^
// [analyzer] unspecified
// [cfe] unspecified

// --------------------
// The extension type representation parameter cannot be covariant.
// (Declaring parameters of a class can.)
// Neither can have any other modifier that could otherwise apply to
// a parameter or instance variable.

extension type ET6(covariant int i);
//                 ^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.INVALID_COVARIANT_MODIFIER_IN_PRIMARY_CONSTRUCTOR
// [cfe] The 'covariant' modifier can only be used on non-final declaring parameters.

extension type ET7(late int i);
//                 ^^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'late' here.

extension type ET8(static int i);
//                 ^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'static' here.

extension type ET9(external final int i);
//                 ^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'external' here.

extension type ET10(abstract final int i);
//                  ^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'abstract' here.

extension type ET11(const int i);
//                  ^^^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'const' here.

// --------------------------------------------------------------
// Still cannot declare member with same name as `Object` instance members,
// which includes the representation variable.

extension type ET12({required final int hashCode});
//                                      ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
// [cfe] This extension member conflicts with Object member 'hashCode'.

extension type ET13({required final dynamic Function(Invocation) noSuchMethod});
//                                                               ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
// [cfe] This extension member conflicts with Object member 'noSuchMethod'.

extension type ET14({required final Type runtimeType});
//                                       ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
// [cfe] This extension member conflicts with Object member 'runtimeType'.

extension type ET15({required final String Function() toString});
//                                                    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
// [cfe] This extension member conflicts with Object member 'toString'.

// Doesn't matter how the parameter list is written.

extension type ET16(final int hashCode);
//                            ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
// [cfe] This extension member conflicts with Object member 'hashCode'.

extension type ET17({final int hashCode = 0});
//                             ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
// [cfe] This extension member conflicts with Object member 'hashCode'.

extension type ET18([final int hashCode = 0]);
//                             ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
// [cfe] This extension member conflicts with Object member 'hashCode'.
