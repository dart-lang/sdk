// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

/// Test the invalid uses of a base mixin defined in a different library.

import "shared_library_definitions.dart" show SimpleClass, BaseMixin;

mixin _MixinOnObject {}

/// It is an error if BaseMixin is implemented by something which is not base,
/// final or sealed.

// Simple implementation.

class SimpleImplement implements BaseMixin {}
//    ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.
//                               ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

base class BaseImplement implements BaseMixin {}
//                                  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

interface class InterfaceImplement implements BaseMixin {}
//              ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.
//                                            ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

final class FinalImplement implements BaseMixin {}
//                                    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

sealed class SealedImplement implements BaseMixin {}
//                                      ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

// Implementing with a mixin class.

mixin class SimpleMixinClassImplement implements BaseMixin {}
//          ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinClassImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.
//                                               ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

base mixin class BaseMixinClassImplement implements BaseMixin {}
//                                                  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

// Implementing with a mixin application class.

class SimpleImplementApplication = Object
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleImplementApplication' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.
    with
        _MixinOnObject
    implements
        BaseMixin;
//      ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

base class BaseImplementApplication = Object
    with _MixinOnObject
    implements BaseMixin;
//             ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

interface class InterfaceImplementApplication = Object
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceImplementApplication' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.
    with
        _MixinOnObject
    implements
        BaseMixin;
//      ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

final class FinalImplementApplication = Object
    with _MixinOnObject
    implements BaseMixin;
//             ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

sealed class SealedImplementApplication = Object
    with _MixinOnObject
    implements BaseMixin;
//             ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

// Implementing with a mixin.

mixin SimpleMixinImplement implements BaseMixin {}
//    ^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.
//                                    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

base mixin BaseMixinImplement implements BaseMixin {}
//                                       ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

/// It is an error if BaseMixin is the `on` type of something which is not base.

mixin SimpleMixinOn on BaseMixin {}
//    ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinOn' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.

mixin SimpleMixinOnSimpleBase on SimpleClass, BaseMixin {}
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinOnSimpleBase' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.

mixin SimpleMixinOnBaseSimple on BaseMixin, SimpleClass {}
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinOnBaseSimple' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.

/// It is an error to use BaseMixin as a mixin, if the result is not base,
/// final or sealed.

class SimpleMixinClassApply extends Object with BaseMixin {}
//    ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinClassApply' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.

class SimpleMixinClassApplySimpleBase extends Object
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinClassApplySimpleBase' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.
    with
        _MixinOnObject,
        BaseMixin {}

class SimpleMixinClassApplyBaseSimple extends Object
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinClassApplyBaseSimple' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.
    with
        BaseMixin,
        _MixinOnObject {}

interface class InterfaceMixinClassApply extends Object with BaseMixin {}
//              ^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceMixinClassApply' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.

interface class InterfaceMixinClassApplySimpleBase extends Object
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceMixinClassApplySimpleBase' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.
    with
        _MixinOnObject,
        BaseMixin {}

interface class InterfaceMixinClassApplyBaseSimple extends Object
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceMixinClassApplyBaseSimple' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.
    with
        BaseMixin,
        _MixinOnObject {}

// Base class produced from a base mixin (valid, used for tests below).

base class BaseMixinApply extends Object with BaseMixin {}

// Implementing through a base class.

class SimpleBaseMixinApplyImplement implements BaseMixinApply {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleBaseMixinApplyImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinApply' is 'base'.
//                                             ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

base class BaseBaseMixinApplyImplement implements BaseMixinApply {}
//                                                ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

interface class InterfaceBaseMixinApplyImplement
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceBaseMixinApplyImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinApply' is 'base'.
    implements
        BaseMixinApply {}
//      ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

final class FinalBaseMixinApplyImplement implements BaseMixinApply {}
//                                                  ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

sealed class SealedBaseMixinApplyImplement implements BaseMixinApply {}
//                                                    ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

base mixin class BaseMixinClassBaseMixinApplyImplement
    implements BaseMixinApply {}
//             ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

base mixin BaseMixinBaseMixinApplyImplement implements BaseMixinApply {}
//                                                     ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

// final class produced from a base mixin (valid, used for tests below)

final class FinalMixinApply extends Object with BaseMixin {}

// Implementing through a base class.

class SimpleFinalMixinApplyImplement implements FinalMixinApply {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleFinalMixinApplyImplement' must be 'base', 'final' or 'sealed' because the supertype 'FinalMixinApply' is 'final'.
//                                              ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

base class BaseFinalMixinApplyImplement implements FinalMixinApply {}
//                                                 ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

interface class InterfaceFinalMixinApplyImplement
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceFinalMixinApplyImplement' must be 'base', 'final' or 'sealed' because the supertype 'FinalMixinApply' is 'final'.
    implements
        FinalMixinApply {}
//      ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

final class FinalFinalMixinApplyImplement implements FinalMixinApply {}
//                                                   ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

sealed class SealedFinalMixinApplyImplement implements FinalMixinApply {}
//                                                     ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

base mixin class BaseMixinClassFinalMixinApplyImplement
    implements FinalMixinApply {}
//             ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

base mixin BaseMixinFinalMixinApplyImplement implements FinalMixinApply {}
//                                                      ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

// Sealed class produced from a base mixin (valid, used for tests below)

sealed class SealedMixinApply extends Object with BaseMixin {}

// Implementing through a sealed class.

class SimpleSealedMixinApplyImplement implements SealedMixinApply {}
//                                               ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

base class BaseSealedMixinApplyImplement implements SealedMixinApply {}
//                                                  ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

interface class InterfaceSealedMixinApplyImplement
    implements SealedMixinApply {}
//             ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

final class FinalSealedMixinApplyImplement implements SealedMixinApply {}
//                                                    ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

sealed class SealedSealedMixinApplyImplement implements SealedMixinApply {}
//                                                      ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

base mixin class BaseMixinClassSealedMixinApplyImplement
    implements SealedMixinApply {}
//             ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

base mixin BaseMixinSealedMixinApplyImplement implements SealedMixinApply {}
//                                                       ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

/// It is an error to use BaseMixin as a mixin application, if the result
/// is not base, final or sealed.

class SimpleMixinClassApplication extends Object with BaseMixin {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinClassApplication' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.

class SimpleMixinClassApplicationSimpleBase extends Object
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinClassApplicationSimpleBase' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.
    with
        _MixinOnObject,
        BaseMixin {}

class SimpleMixinClassApplicationBaseSimple extends Object
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinClassApplicationBaseSimple' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.
    with
        BaseMixin,
        _MixinOnObject {}

interface class InterfaceMixinClassApplication extends Object with BaseMixin {}
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceMixinClassApplication' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.

interface class InterfaceMixinClassApplicationSimpleBase extends Object
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceMixinClassApplicationSimpleBase' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.
    with
        _MixinOnObject,
        BaseMixin {}

interface class InterfaceMixinClassApplicationBaseSimple extends Object
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceMixinClassApplicationBaseSimple' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.
    with
        BaseMixin,
        _MixinOnObject {}

// Sealed class produced from a base mixin (valid, used for tests below).

sealed class SealedMixinApplication = Object with BaseMixin;

// Implementing through a sealed class.

class SimpleSealedMixinApplicationImplement implements SealedMixinApplication {}
//                                                     ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

base class BaseSealedMixinApplicationImplement
    implements SealedMixinApplication {}
//             ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

interface class InterfaceSealedMixinApplicationImplement
    implements SealedMixinApplication {}
//             ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

final class FinalSealedMixinApplicationImplement
    implements SealedMixinApplication {}
//             ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

sealed class SealedSealedMixinApplicationImplement
    implements SealedMixinApplication {}
//             ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

base mixin class BaseMixinClassSealedMixinApplicationImplement
    implements SealedMixinApplication {}
//             ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.

base mixin BaseMixinSealedMixinApplicationImplement
    implements SealedMixinApplication {}
//             ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'BaseMixin' can't be implemented outside of its library because it's a base mixin.
