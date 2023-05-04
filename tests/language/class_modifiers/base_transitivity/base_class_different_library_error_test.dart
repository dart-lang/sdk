// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

/// Test the invalid uses of a base class defined in a different library

import 'dart:collection';
import "shared_library_definitions.dart" show SimpleClass, BaseClass;
import 'shared_library_definitions_legacy.dart' show LegacyImplementBaseCore;

mixin _MixinOnObject {}

/// It is an error if a base class from a different library is extended by
/// something which is not base, final or sealed.

/// It is an error if a subclass of a base class from a different library is
/// extended by something which is not base, final or sealed.

/// It is an error if a subclass of a base class from a different library is
/// implemented.

// Extending with a simple class.

class SimpleExtend extends BaseClass {}
//    ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleExtend' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

// Extending with a base class (valid).

base class BaseExtend extends BaseClass {}

// Extending through a base class.

class SimpleBaseExtendExtend extends BaseExtend {}
//    ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleBaseExtendExtend' must be 'base', 'final' or 'sealed' because the supertype 'BaseExtend' is 'base'.

interface class InterfaceBaseExtendExtend extends BaseExtend {}
//              ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceBaseExtendExtend' must be 'base', 'final' or 'sealed' because the supertype 'BaseExtend' is 'base'.

// Implementing through a base class.

class SimpleBaseExtendImplement implements BaseExtend {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleBaseExtendImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseExtend' is 'base'.
//                                         ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

base class BaseBaseExtendImplement implements BaseExtend {}
//                                            ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

interface class InterfaceBaseExtendImplement implements BaseExtend {}
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceBaseExtendImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseExtend' is 'base'.
//                                                      ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

final class FinalBaseExtendImplement implements BaseExtend {}
//                                              ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

sealed class SealedBaseExtendImplement implements BaseExtend {}
//                                                ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

mixin class MixinClassBaseExtendImplement implements BaseExtend {}
//          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixinClassBaseExtendImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseExtend' is 'base'.
//                                                   ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

base mixin class BaseMixinClassBaseExtendImplement implements BaseExtend {}
//                                                            ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

mixin MixinBaseExtendImplement implements BaseExtend {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixinBaseExtendImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseExtend' is 'base'.
//                                        ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

base mixin BaseMixinBaseExtendImplement implements BaseExtend {}
//                                                 ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

mixin MixinBaseExtendOn on BaseExtend {}
//    ^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixinBaseExtendOn' must be 'base', 'final' or 'sealed' because the supertype 'BaseExtend' is 'base'.

// Extending with an interface class.

interface class InterfaceExtend extends BaseClass {}
//              ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceExtend' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

// Extending with a final class (valid).

final class FinalExtend extends BaseClass {}

// Extending through a final class.

class SimpleFinalExtendExtend extends FinalExtend {}
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleFinalExtendExtend' must be 'base', 'final' or 'sealed' because the supertype 'FinalExtend' is 'final'.

interface class InterfaceFinalExtendExtend extends FinalExtend {}
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceFinalExtendExtend' must be 'base', 'final' or 'sealed' because the supertype 'FinalExtend' is 'final'.

// Implementing through a final class.

class SimpleFinalExtendImplement implements FinalExtend {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleFinalExtendImplement' must be 'base', 'final' or 'sealed' because the supertype 'FinalExtend' is 'final'.
//                                          ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

base class BaseFinalExtendImplement implements FinalExtend {}
//                                             ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

interface class InterfaceFinalExtendImplement implements FinalExtend {}
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceFinalExtendImplement' must be 'base', 'final' or 'sealed' because the supertype 'FinalExtend' is 'final'.
//                                                       ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

final class FinalFinalExtendImplement implements FinalExtend {}
//                                               ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

sealed class SealedFinalExtendImplement implements FinalExtend {}
//                                                 ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

mixin class MixinClassFinalExtendImplement implements FinalExtend {}
//          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixinClassFinalExtendImplement' must be 'base', 'final' or 'sealed' because the supertype 'FinalExtend' is 'final'.
//                                                    ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

base mixin class BaseMixinClassFinalExtendImplement implements FinalExtend {}
//                                                             ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

mixin MixinFinalExtendImplement implements FinalExtend {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixinFinalExtendImplement' must be 'base', 'final' or 'sealed' because the supertype 'FinalExtend' is 'final'.
//                                         ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

base mixin BaseMixinFinalExtendImplement implements FinalExtend {}
//                                                  ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

mixin MixinFinalExtendOn on FinalExtend {}
//    ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixinFinalExtendOn' must be 'base', 'final' or 'sealed' because the supertype 'FinalExtend' is 'final'.

// Extending with a sealed class (valid, used to check the errors below).

sealed class SealedExtend extends BaseClass {}

// Extending through a sealed class.

class SimpleSealedExtendExtend extends SealedExtend {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleSealedExtendExtend' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

interface class InterfaceSealedExtendExtend extends SealedExtend {}
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceSealedExtendExtend' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

// Implementing through a sealed class.

class SimpleSealedExtendImplement implements SealedExtend {}
//                                           ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

base class BaseSealedExtendImplement implements SealedExtend {}
//                                              ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

interface class InterfaceSealedExtendImplement implements SealedExtend {}
//                                                        ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

final class FinalSealedExtendImplement implements SealedExtend {}
//                                                ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

sealed class SealedSealedExtendImplement implements SealedExtend {}
//                                                  ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

mixin class MixinClassSealedExtendImplement implements SealedExtend {}
//                                                     ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

base mixin class BaseMixinClassSealedExtendImplement implements SealedExtend {}
//                                                              ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

mixin MixinSealedExtendImplement implements SealedExtend {}
//                                          ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

base mixin BaseMixinSealedExtendImplement implements SealedExtend {}
//                                                   ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

// Using a sealed class as an `on` type

mixin MixinSealedExtendOn on SealedExtend {}
//    ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixinSealedExtendOn' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

// Implementing via an on type (valid).
base mixin BaseMixinOn on BaseClass {}

// Implementing through a base mixin.

class SimpleBaseMixinOnImplement implements BaseMixinOn {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleBaseMixinOnImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinOn' is 'base'.
//                                          ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

base class BaseBaseMixinOnImplement implements BaseMixinOn {}
//                                             ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

interface class InterfaceBaseMixinOnImplement implements BaseMixinOn {}
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceBaseMixinOnImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinOn' is 'base'.
//                                                       ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

final class FinalBaseMixinOnImplement implements BaseMixinOn {}
//                                               ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

sealed class SealedBaseMixinOnImplement implements BaseMixinOn {}
//                                                 ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

mixin class MixinClassBaseMixinOnImplement implements BaseMixinOn {}
//          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixinClassBaseMixinOnImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinOn' is 'base'.
//                                                    ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

base mixin class BaseMixinClassBaseMixinOnImplement implements BaseMixinOn {}
//                                                             ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

mixin MixinBaseMixinOnImplement implements BaseMixinOn {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixinBaseMixinOnImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinOn' is 'base'.
//                                         ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

base mixin BaseMixinBaseMixinOnImplement implements BaseMixinOn {}
//                                                  ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

mixin MixinBaseMixinOnOn on BaseMixinOn {}
//    ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixinBaseMixinOnOn' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinOn' is 'base'.

// Extending via an anonymous mixin class.

class SimpleExtendWith extends BaseClass with _MixinOnObject {}
//    ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleExtendWith' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

interface class InterfaceExtendWith extends BaseClass with _MixinOnObject {}
//              ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceExtendWith' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

// Extending via an anonymous mixin application class.

class SimpleExtendApplication = BaseClass with _MixinOnObject;
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleExtendApplication' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

interface class InterfaceExtendApplication = BaseClass with _MixinOnObject;
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceExtendApplication' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

/// It is an error if BaseClass is implemented by something which is not base,
/// final or sealed.

// Simple implementation.

class SimpleImplement implements BaseClass {}
//    ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.
//                               ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

base class BaseImplement implements BaseClass {}
//                                  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

interface class InterfaceImplement implements BaseClass {}
//              ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.
//                                            ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

final class FinalImplement implements BaseClass {}
//                                    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

sealed class SealedImplement implements BaseClass {}
//                                      ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

// Implementing with a mixin class.

mixin class SimpleMixinClassImplement implements BaseClass {}
//          ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinClassImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.
//                                               ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

base mixin class BaseMixinClassImplement implements BaseClass {}
//                                                  ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

// Implementing with a mixin application class.

class SimpleImplementApplication = Object
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleImplementApplication' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.
    with
        _MixinOnObject
    implements
        BaseClass;
//      ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

base class BaseImplementApplication = Object
    with _MixinOnObject
    implements BaseClass;
//             ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

interface class InterfaceImplementApplication = Object
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceImplementApplication' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.
    with
        _MixinOnObject
    implements
        BaseClass;
//      ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

final class FinalImplementApplication = Object
    with _MixinOnObject
    implements BaseClass;
//             ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

sealed class SealedImplementApplication = Object
    with _MixinOnObject
    implements BaseClass;
//             ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

// Implementing with a mixin.

mixin SimpleMixinImplement implements BaseClass {}
//    ^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.
//                                    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

base mixin BaseMixinImplement implements BaseClass {}
//                                       ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.

// Implementing a legacy class that implements a core library base class.

abstract class LegacyImplement<E extends LinkedListEntry<E>>
    implements LegacyImplementBaseCore<E> {}
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] unspecified

/// It is an error if BaseClass is the `on` type of something which is not base.

mixin SimpleMixinOn on BaseClass {}
//    ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinOn' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

mixin SimpleMixinOnSimpleBase on SimpleClass, BaseClass {}
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinOnSimpleBase' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

mixin SimpleMixinOnBaseSimple on BaseClass, SimpleClass {}
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinOnBaseSimple' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

main() {}
