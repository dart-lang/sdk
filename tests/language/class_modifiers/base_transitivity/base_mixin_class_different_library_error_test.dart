// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

/// Test the invalid uses of a base mixin class defined in a different library.

import "shared_library_definitions.dart" show SimpleClass, BaseMixinClass;

mixin _MixinOnObject {}

/// It is an error if BaseMixinClass is extended by something which is not base,
/// final or sealed.

// Simple extension.
class SimpleExtend extends BaseMixinClass {}
//    ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleExtend' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

interface class InterfaceExtend extends BaseMixinClass {}
//              ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceExtend' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

// Extending with a sealed class (valid, used to check the errors below).
sealed class SealedExtend extends BaseMixinClass {}

// Extending through a sealed class.
class SimpleSealedExtendExtend extends SealedExtend {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleSealedExtendExtend' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

interface class InterfaceSealedExtendExtend extends SealedExtend {}
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceSealedExtendExtend' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

// Implementing through a sealed class.
class SimpleSealedExtendImplement implements SealedExtend {}
//                                           ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

base class BaseSealedExtendImplement implements SealedExtend {}
//                                              ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

interface class InterfaceSealedExtendImplement implements SealedExtend {}
//                                                        ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

final class FinalSealedExtendImplement implements SealedExtend {}
//                                                ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

sealed class SealedSealedExtendImplement implements SealedExtend {}
//                                                  ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

mixin class MixinClassSealedExtendImplement implements SealedExtend {}
//                                                     ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

base mixin class BaseMixinClassSealedExtendImplement implements SealedExtend {}
//                                                              ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

mixin MixinSealedExtendImplement implements SealedExtend {}
//                                          ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

base mixin BaseMixinSealedExtendImplement implements SealedExtend {}
//                                                   ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

// Using a sealed class as an `on` type

mixin MixinSealedExtendOn on SealedExtend {}
//    ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixinSealedExtendOn' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

// Extending via an anonymous mixin class.
class SimpleExtendWith extends BaseMixinClass with _MixinOnObject {}
//    ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleExtendWith' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

interface class InterfaceExtendWith extends BaseMixinClass
//              ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceExtendWith' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.
    with
        _MixinOnObject {}

// Extending via an anonymous mixin application class.
class SimpleExtendApplication = BaseMixinClass with _MixinOnObject;
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleExtendApplication' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

interface class InterfaceExtendApplication = BaseMixinClass with _MixinOnObject;
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceExtendApplication' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

/// It is an error if BaseMixinClass is implemented by something which is not base,
/// final or sealed.

// Simple implementation.
class SimpleImplement implements BaseMixinClass {}
//    ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.
//                               ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

base class BaseImplement implements BaseMixinClass {}
//                                  ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

interface class InterfaceImplement implements BaseMixinClass {}
//              ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.
//                                            ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

final class FinalImplement implements BaseMixinClass {}
//                                    ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

sealed class SealedImplement implements BaseMixinClass {}
//                                      ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

// Implementing with a mixin class.
mixin class SimpleMixinClassImplement implements BaseMixinClass {}
//          ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinClassImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.
//                                               ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

base mixin class BaseMixinClassImplement implements BaseMixinClass {}
//                                                  ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

// Implementing with a mixin application class.
class SimpleImplementApplication = Object
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleImplementApplication' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.
    with
        _MixinOnObject
    implements
        BaseMixinClass;
//      ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

base class BaseImplementApplication = Object
    with _MixinOnObject
    implements BaseMixinClass;
//             ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

interface class InterfaceImplementApplication = Object
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceImplementApplication' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.
    with
        _MixinOnObject
    implements
        BaseMixinClass;
//      ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

final class FinalImplementApplication = Object
    with _MixinOnObject
    implements BaseMixinClass;
//             ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

sealed class SealedImplementApplication = Object
    with _MixinOnObject
    implements BaseMixinClass;
//             ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

// Implementing with a mixin.
mixin SimpleMixinImplement implements BaseMixinClass {}
//    ^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.
//                                    ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

base mixin BaseMixinImplement implements BaseMixinClass {}
//                                       ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

/// It is an error if BaseMixinClass is the `on` type of something which is not base.

mixin SimpleMixinOn on BaseMixinClass {}
//    ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinOn' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

mixin SimpleMixinOnSimpleBase on SimpleClass, BaseMixinClass {}
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinOnSimpleBase' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

mixin SimpleMixinOnBaseSimple on BaseMixinClass, SimpleClass {}
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinOnBaseSimple' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

/// It is an error to use BaseMixinClass as a mixin, if the result is not base,
/// final or sealed.

class SimpleMixinClassApply extends Object with BaseMixinClass {}
//    ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinClassApply' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

class SimpleMixinClassApplySimpleBase extends Object
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinClassApplySimpleBase' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.
    with
        _MixinOnObject,
        BaseMixinClass {}

class SimpleMixinClassApplyBaseSimple extends Object
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinClassApplyBaseSimple' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.
    with
        BaseMixinClass,
        _MixinOnObject {}

interface class InterfaceMixinClassApply extends Object with BaseMixinClass {}
//              ^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceMixinClassApply' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

interface class InterfaceMixinClassApplySimpleBase extends Object
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceMixinClassApplySimpleBase' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.
    with
        _MixinOnObject,
        BaseMixinClass {}

interface class InterfaceMixinClassApplyBaseSimple extends Object
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceMixinClassApplyBaseSimple' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.
    with
        BaseMixinClass,
        _MixinOnObject {}

// Sealed class from mixing in a base mixin class.  (valid, used for tests
// below)
sealed class SealedMixinClassApply extends Object with BaseMixinClass {}

// Implementing through a sealed class.
class SimpleSealedMixinClassApplyImplement implements SealedMixinClassApply {}
//                                                    ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

base class BaseSealedMixinClassApplyImplement
    implements SealedMixinClassApply {}
//             ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

interface class InterfaceSealedMixinClassApplyImplement
    implements SealedMixinClassApply {}
//             ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

final class FinalSealedMixinClassApplyImplement
    implements SealedMixinClassApply {}
//             ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

sealed class SealedSealedMixinClassApplyImplement
    implements SealedMixinClassApply {}
//             ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

base mixin class BaseMixinClassSealedMixinClassApplyImplement
    implements SealedMixinClassApply {}
//             ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

base mixin BaseMixinSealedMixinClassApplyImplement
    implements SealedMixinClassApply {}
//             ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

/// It is an error to use BaseMixinClass as a mixin application, if the result
/// is not base, final or sealed.

class SimpleMixinClassApplication extends Object with BaseMixinClass {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinClassApplication' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

class SimpleMixinClassApplicationSimpleBase extends Object
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinClassApplicationSimpleBase' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.
    with
        _MixinOnObject,
        BaseMixinClass {}

class SimpleMixinClassApplicationBaseSimple extends Object
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinClassApplicationBaseSimple' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.
    with
        BaseMixinClass,
        _MixinOnObject {}

interface class InterfaceMixinClassApplication extends Object
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceMixinClassApplication' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.
    with
        BaseMixinClass {}

interface class InterfaceMixinClassApplicationSimpleBase extends Object
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceMixinClassApplicationSimpleBase' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.
    with
        _MixinOnObject,
        BaseMixinClass {}

interface class InterfaceMixinClassApplicationBaseSimple extends Object
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceMixinClassApplicationBaseSimple' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.
    with
        BaseMixinClass,
        _MixinOnObject {}

// Sealed class from mixing in a base mixin class.  (valid, used for tests
// below)
sealed class SealedMixinApplication = Object with BaseMixinClass;

// Implementing through a sealed class.
class SimpleSealedMixinApplicationImplement implements SealedMixinApplication {}
//                                                     ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

base class BaseSealedMixinApplicationImplement
    implements SealedMixinApplication {}
//             ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

interface class InterfaceSealedMixinApplicationImplement
    implements SealedMixinApplication {}
//             ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

final class FinalSealedMixinApplicationImplement
    implements SealedMixinApplication {}
//             ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

sealed class SealedSealedMixinApplicationImplement
    implements SealedMixinApplication {}
//             ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

base mixin class BaseMixinClassSealedMixinApplicationImplement
    implements SealedMixinApplication {}
//             ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.

base mixin BaseMixinSealedMixinApplicationImplement
    implements SealedMixinApplication {}
//             ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseMixinClass' can't be implemented outside of its library because it's a base class.
