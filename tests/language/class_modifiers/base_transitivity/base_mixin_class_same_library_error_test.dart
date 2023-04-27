// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

/// Test the invalid uses of a base mixin class within the same library

class SimpleClass {}

base mixin class BaseMixinClass {}

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
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleSealedExtendImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

interface class InterfaceSealedExtendImplement implements SealedExtend {}
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceSealedExtendImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

mixin class MixinClassSealedExtendImplement implements SealedExtend {}
//          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixinClassSealedExtendImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

mixin MixinSealedExtendImplement implements SealedExtend {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixinSealedExtendImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

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

interface class InterfaceImplement implements BaseMixinClass {}
//              ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

// Implementing with a sealed class (valid, used for tests below).

sealed class SealedImplement implements BaseMixinClass {}

// Extending through a sealed class.

class SimpleSealedImplementExtend extends SealedImplement {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleSealedImplementExtend' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

interface class InterfaceSealedImplementExtend extends SealedImplement {}
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceSealedImplementExtend' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

// Implementing through a sealed class.

class SimpleSealedImplementImplement implements SealedImplement {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleSealedImplementImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

interface class InterfaceSealedImplementImplement implements SealedImplement {}
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceSealedImplementImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

// Implementing with a mixin class.

mixin class SimpleMixinClassImplement implements BaseMixinClass {}
//          ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinClassImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

// Implementing with a base mixin class (valid, used for tests below)

base mixin class BaseMixinClassImplement implements BaseMixinClass {}

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
// [cfe] The type 'InterfaceImplementApplication' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.
    with
        _MixinOnObject
    implements
        BaseMixinClass;

class SimpleImplementApplication = Object
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleImplementApplication' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.
    with
        _MixinOnObject
    implements
        BaseMixinClass;

// Implementing with a mixin.

mixin SimpleMixinImplement implements BaseMixinClass {}
//    ^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinImplement' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

// Implementing with a base mixin (valid, used for tests below)

base mixin BaseMixinImplement implements BaseMixinClass {}

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

/// It is an error if BaseMixinClass is the `on` type of something which is not base.

mixin SimpleMixinOn on BaseMixinClass {}
//    ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinOn' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

mixin SimpleMixinOnBaseSimple on BaseMixinClass, SimpleClass {}
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinOnBaseSimple' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

mixin SimpleMixinOnSimpleBase on SimpleClass, BaseMixinClass {}
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinOnSimpleBase' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixinClass' is 'base'.

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
