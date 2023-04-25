// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

/// Test the invalid uses of a final class within the same library

class SimpleClass {}

final class FinalClass {}

mixin _MixinOnObject {}

/// It is an error if FinalClass is extended by something which is not base,
/// final or sealed.

// Simple extension.

class SimpleExtend extends FinalClass {}
//    ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleExtend' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

interface class InterfaceExtend extends FinalClass {}
//              ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceExtend' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

// Extending with a sealed class (valid, used to check the errors below).

sealed class SealedExtend extends FinalClass {}

// Extending through a sealed class.

class SimpleSealedExtendExtend extends SealedExtend {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleSealedExtendExtend' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

interface class InterfaceSealedExtendExtend extends SealedExtend {}
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceSealedExtendExtend' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

// Implementing through a sealed class.

class SimpleSealedExtendImplement implements SealedExtend {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleSealedExtendImplement' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

interface class InterfaceSealedExtendImplement implements SealedExtend {}
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceSealedExtendImplement' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

mixin class MixinClassSealedExtendImplement implements SealedExtend {}
//          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixinClassSealedExtendImplement' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

mixin MixinSealedExtendImplement implements SealedExtend {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixinSealedExtendImplement' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

// Using a sealed class as an `on` type

mixin MixinSealedExtendOn on SealedExtend {}
//    ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixinSealedExtendOn' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

// Extending via an anonymous mixin class.

class SimpleExtendWith extends FinalClass with _MixinOnObject {}
//    ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleExtendWith' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

interface class InterfaceExtendWith extends FinalClass with _MixinOnObject {}
//              ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceExtendWith' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

// Extending via an anonymous mixin application class.

class SimpleExtendApplication = FinalClass with _MixinOnObject;
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleExtendApplication' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

interface class InterfaceExtendApplication = FinalClass with _MixinOnObject;
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceExtendApplication' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

/// It is an error if FinalClass is implemented by something which is not base,
/// final or sealed.

// Simple implementation.

class SimpleImplement implements FinalClass {}
//    ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleImplement' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

interface class InterfaceImplement implements FinalClass {}
//              ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceImplement' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

// Implementing with a sealed class (valid, used for tests below).

sealed class SealedImplement implements FinalClass {}

// Extending through a sealed class.

class SimpleSealedImplementExtend extends SealedImplement {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleSealedImplementExtend' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

interface class InterfaceSealedImplementExtend extends SealedImplement {}
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceSealedImplementExtend' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

// Implementing through a sealed class.

class SimpleSealedImplementImplement implements SealedImplement {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleSealedImplementImplement' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

interface class InterfaceSealedImplementImplement implements SealedImplement {}
//              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'InterfaceSealedImplementImplement' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

// Implementing with a mixin class.

mixin class SimpleMixinClassImplement implements FinalClass {}
//          ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinClassImplement' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

// Implementing with a base mixin class (valid, used for tests below)

base mixin class BaseMixinClassImplement implements FinalClass {}

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
// [cfe] The type 'InterfaceImplementApplication' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.
    with
        _MixinOnObject
    implements
        FinalClass;
class SimpleImplementApplication = Object
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleImplementApplication' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.
    with
        _MixinOnObject
    implements
        FinalClass;

// Implementing with a mixin.

mixin SimpleMixinImplement implements FinalClass {}
//    ^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinImplement' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

// Implementing with a base mixin (valid, used for tests below)

base mixin BaseMixinImplement implements FinalClass {}

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

/// It is an error if FinalClass is the `on` type of something which is not
/// base.

mixin SimpleMixinOn on FinalClass {}
//    ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinOn' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

mixin SimpleMixinOnFinalSimple on FinalClass, SimpleClass {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinOnFinalSimple' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

mixin SimpleMixinOnSimpleFinal on SimpleClass, FinalClass {}
//    ^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'SimpleMixinOnSimpleFinal' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

main() {}
