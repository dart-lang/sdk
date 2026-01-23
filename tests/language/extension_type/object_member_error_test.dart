// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// From feature-specification:
//
// > A compile-time error occurs if an extension type declares a member
// > whose basename is the basename of an instance member declared by `Object`
// > as well.
//
// The instance members declared by `Object` are:
// `hashCode`, `noSuchMethod`, `runtimeType`, `toString` and `==`.
//
// This applies to both static members and instance members,
// but not constructors. (The concept of "base name" is not extended
// to constructors by the language specification.)
// For static members and constructors, the restrictions for
// extension types are the same as for classes and class-like declarations.

import 'package:expect/static_type_helper.dart';

// -------------------------------
// Instance extension-type members
extension type E0(Object? _) {
  // Cannot declare instance member with same name as member of [Object].

  String get hashCode => "";
  //         ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member 'hashCode'.

  String get noSuchMethod => "";
  //         ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member 'noSuchMethod'.

  String get runtimeType => "";
  //         ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member 'runtimeType'.

  String get toString => "";
  //         ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member 'toString'.

  String operator ==(Object _) => "";
  //              ^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member '=='.

  set hashCode(String _) {}
  //  ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT

  set noSuchMethod(String _) {}
  //  ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT

  set runtimeType(String _) {}
  //  ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT

  set toString(String _) {}
  //  ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
}

// Also cannot declare instance setter with such a name as base-name.
extension type E0SetOnly(Object? _) {
  // Also separate from getters because CFE only reports one error for the
  // getter/setter pair, analyzer reports two.

  set hashCode(String _) {}
  //  ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member 'hashCode'.

  set noSuchMethod(String _) {}
  //  ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member 'noSuchMethod'.

  set runtimeType(String _) {}
  //  ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member 'runtimeType'.

  set toString(String _) {}
  //  ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member 'toString'.
}

// Even if exact same signature as `Object`-member, it's not a type/kind error.
extension type E1(Object? _) {
  // Cannot declare instance member with same name as member of [Object].

  int get hashCode => _.hashCode;
  //      ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member 'hashCode'.

  dynamic noSuchMethod(Invocation i) => _.noSuchMethod(i);
  //      ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member 'noSuchMethod'.

  Type get runtimeType => _.runtimeType;
  //       ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member 'runtimeType'.

  String toString() => _.toString();
  //     ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member 'toString'.

  bool operator ==(Object other) => _ == other;
  //            ^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member '=='.
}

// Same for the representation type getter, which is an extension type
// member, even if it's declared outside of the body.

extension type E2(int hashCode) {}
//                    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
// [cfe] This extension member conflicts with Object member 'hashCode'.

extension type E3(Object? Function(Invocation) noSuchMethod) {}
//                                             ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
// [cfe] This extension member conflicts with Object member 'noSuchMethod'.

extension type E4(Type runtimeType) {}
//                     ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
// [cfe] This extension member conflicts with Object member 'runtimeType'.

extension type E5(String Function() toString) {}
//                                  ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
// [cfe] This extension member conflicts with Object member 'toString'.

// ---------------
// Static members.

extension type ES(Object? _) {
  // Cannot declare instance member with same name as member of [Object].

  static String get hashCode => "";
  //                ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member 'hashCode'.

  static String get noSuchMethod => "";
  //                ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member 'noSuchMethod'.

  static String get runtimeType => "";
  //                ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member 'runtimeType'.

  static String get toString => "";
  //                ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member 'toString'.

  // Also cannot declare instance setter with such a name as base-name.
  // (CFE only reports once for a getter/setter pair.)

  static set hashCode(String _) {}
  //         ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT

  static set noSuchMethod(String _) {}
  //         ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT

  static set runtimeType(String _) {}
  //         ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT

  static set toString(String _) {}
  //         ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
}

extension type ESSetOnly(Object? _) {
  // Setters by themselves.

  static set hashCode(String _) {}
  //         ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member 'hashCode'.

  static set noSuchMethod(String _) {}
  //         ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member 'noSuchMethod'.

  static set runtimeType(String _) {}
  //         ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member 'runtimeType'.

  static set toString(String _) {}
  //         ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT
  // [cfe] This extension member conflicts with Object member 'toString'.
}

// ---------------
// Constructors are allowed. (Same as in classes.)

extension type EC(Object? _) {
  factory EC.hashCode() => throw "unreachable";
  factory EC.noSuchMethod() => throw "unreachable";
  factory EC.runtimeType() => throw "unreachable";
  factory EC.toString() => throw "unreachable";
}

void main() {
  // Constructors exist and have expected types.
  EC.hashCode.expectStaticType<Exactly<EC Function()>>();
  EC.noSuchMethod.expectStaticType<Exactly<EC Function()>>();
  EC.runtimeType.expectStaticType<Exactly<EC Function()>>();
  EC.toString.expectStaticType<Exactly<EC Function()>>();

  // Instance members exist and have expected types.
  EC(0).hashCode.expectStaticType<Exactly<int>>();
  EC(0).noSuchMethod.expectStaticType<Exactly<dynamic Function(Invocation)>>();
  EC(0).runtimeType.expectStaticType<Exactly<Type>>();
  EC(0).toString.expectStaticType<Exactly<String Function()>>();
}
