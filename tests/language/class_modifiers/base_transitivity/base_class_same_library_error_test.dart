// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

/// Test the invalid uses of a base class within the same library

class SimpleClass {}

base class BaseClass {}

mixin _MixinOnObject {}

/// It is an error if BaseClass is extended by something which is not base,
/// final or sealed.

// Simple extension.

class SimpleExtend extends BaseClass {}
//    ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleExtend' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

interface class InterfaceExtend extends BaseClass {}
//              ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceExtend' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

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
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleSealedExtendImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

interface class InterfaceSealedExtendImplement implements SealedExtend {}
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceSealedExtendImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

mixin class MixinClassSealedExtendImplement implements SealedExtend {}
//          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixinClassSealedExtendImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

mixin MixinSealedExtendImplement implements SealedExtend {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixinSealedExtendImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

// Using a sealed class as an `on` type

mixin MixinSealedExtendOn on SealedExtend {}
//    ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixinSealedExtendOn' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

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

interface class InterfaceImplement implements BaseClass {}
//              ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

// Implementing with a sealed class (valid, used for tests below).

sealed class SealedImplement implements BaseClass {}

// Extending through a sealed class.

class SimpleSealedImplementExtend extends SealedImplement {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleSealedImplementExtend' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

interface class InterfaceSealedImplementExtend extends SealedImplement {}
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceSealedImplementExtend' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

// Implementing through a sealed class.

class SimpleSealedImplementImplement implements SealedImplement {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleSealedImplementImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

interface class InterfaceSealedImplementImplement implements SealedImplement {}
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceSealedImplementImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

// Implementing with a mixin class.

mixin class SimpleMixinClassImplement implements BaseClass {}
//          ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinClassImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

// Implementing with a base mixin class (valid, used for tests below)

base mixin class BaseMixinClassImplement implements BaseClass {}

// Implementing by applying a mixin class.

class SimpleMixinClassImplementApplied extends Object
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinClassImplementApplied' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClassImplement' is 'base'.
    with
        BaseMixinClassImplement {}

interface class InterfaceMixinClassImplementApplied extends Object
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceMixinClassImplementApplied' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClassImplement' is 'base'.
    with
        BaseMixinClassImplement {}

// Implementing with a mixin application class.

interface class InterfaceImplementApplication = Object
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceImplementApplication' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.
    with
        _MixinOnObject
    implements
        BaseClass;
class SimpleImplementApplication = Object
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleImplementApplication' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.
    with
        _MixinOnObject
    implements
        BaseClass;

// Implementing with a mixin.

mixin SimpleMixinImplement implements BaseClass {}
//    ^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

// Implementing with a base mixin (valid, used for tests below)

base mixin BaseMixinImplement implements BaseClass {}

// Implementing by applying a mixin.

class SimpleMixinImplementApplied extends Object with BaseMixinImplement {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinImplementApplied' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinImplement' is 'base'.

interface class InterfaceMixinImplementApplied extends Object
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceMixinImplementApplied' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinImplement' is 'base'.
    with
        BaseMixinImplement {}

/// It is an error if BaseClass is the `on` type of something which is not base.

mixin SimpleMixinOn on BaseClass {}
//    ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinOn' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

mixin SimpleMixinOnBaseSimple on BaseClass, SimpleClass {}
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinOnBaseSimple' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

mixin SimpleMixinOnSimpleBase on SimpleClass, BaseClass {}
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinOnSimpleBase' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

main() {}
