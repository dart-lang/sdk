// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

/// Test the valid uses of an interface class defined in a different library

import "shared_library_definitions.dart" show InterfaceClass;

mixin _MixinOnObject {}

/// Interface classes can be implemented.
/// Implementations of interface classes can be implemented or extended.

// Implementing with a simple class.

class SimpleImplement implements InterfaceClass {}

// Extending through a simple class.

class SimpleSimpleImplementExtend extends SimpleImplement {}

base class BaseSimpleImplementExtend extends SimpleImplement {}

interface class InterfaceSimpleImplementExtend extends SimpleImplement {}

final class FinalSimpleImplementExtend extends SimpleImplement {}

sealed class SealedSimpleImplementExtend extends SimpleImplement {}

// Implementing through a simple class.

class SimpleSimpleImplementImplement implements SimpleImplement {}

base class BaseSimpleImplementImplement implements SimpleImplement {}

interface class InterfaceSimpleImplementImplement implements SimpleImplement {}

final class FinalSimpleImplementImplement implements SimpleImplement {}

sealed class SealedSimpleImplementImplement implements SimpleImplement {}

mixin class MixinClassSimpleImplementImplement implements SimpleImplement {}

base mixin class BaseMixinClassSimpleImplementImplement
    implements SimpleImplement {}

mixin MixinSimpleImplementImplement implements SimpleImplement {}

base mixin BaseMixinSimpleImplementImplement implements SimpleImplement {}

mixin MixinSimpleImplementOn on SimpleImplement {}

base mixin BaseMixinSimpleImplementOn on SimpleImplement {}

// Implementing with a base class.

base class BaseImplement implements InterfaceClass {}

// Extending through a base class.

base class BaseBaseImplementExtend extends BaseImplement {}

final class FinalBaseImplementExtend extends BaseImplement {}

sealed class SealedBaseImplementExtend extends BaseImplement {}

// Implementing through a base class.

base class BaseBaseImplementImplement implements BaseImplement {}

final class FinalBaseImplementImplement implements BaseImplement {}

sealed class SealedBaseImplementImplement implements BaseImplement {}

base mixin class BaseMixinClassBaseImplementImplement
    implements BaseImplement {}

base mixin BaseMixinBaseImplementImplement implements BaseImplement {}

base mixin BaseMixinBaseImplementOn on BaseImplement {}

// Implementing with an interface class.

interface class InterfaceImplement implements InterfaceClass {}

// Extending through an interface class.

class SimpleInterfaceImplementExtend extends InterfaceImplement {}

base class BaseInterfaceImplementExtend extends InterfaceImplement {}

interface class InterfaceInterfaceImplementExtend extends InterfaceImplement {}

final class FinalInterfaceImplementExtend extends InterfaceImplement {}

sealed class SealedInterfaceImplementExtend extends InterfaceImplement {}

// Implementing through an interface class.

class SimpleInterfaceImplementImplement implements InterfaceImplement {}

base class BaseInterfaceImplementImplement implements InterfaceImplement {}

interface class InterfaceInterfaceImplementImplement
    implements InterfaceImplement {}

final class FinalInterfaceImplementImplement implements InterfaceImplement {}

sealed class SealedInterfaceImplementImplement implements InterfaceImplement {}

mixin class MixinClassInterfaceImplementImplement
    implements InterfaceImplement {}

base mixin class BaseMixinClassInterfaceImplementImplement
    implements InterfaceImplement {}

mixin MixinInterfaceImplementImplement implements InterfaceImplement {}

base mixin BaseMixinInterfaceImplementImplement implements InterfaceImplement {}

mixin MixinInterfaceImplementOn on InterfaceImplement {}

base mixin BaseMixinInterfaceImplementOn on InterfaceImplement {}

// Implementing with a final class

final class FinalImplement implements InterfaceClass {}

// Extending through a final class.

base class BaseFinalImplementExtend extends FinalImplement {}

final class FinalFinalImplementExtend extends FinalImplement {}

sealed class SealedFinalImplementExtend extends FinalImplement {}

// Implementing through a final class.

base class BaseFinalImplementImplement implements FinalImplement {}

final class FinalFinalImplementImplement implements FinalImplement {}

sealed class SealedFinalImplementImplement implements FinalImplement {}

base mixin class BaseMixinClassFinalImplementImplement
    implements FinalImplement {}

base mixin BaseMixinFinalImplementImplement implements FinalImplement {}

base mixin BaseMixinFinalImplementOn on FinalImplement {}

// Implementing with a sealed class.

sealed class SealedImplement implements InterfaceClass {}

// Extending through a sealed class.

class SimpleSealedImplementExtend extends SealedImplement {}

base class BaseSealedImplementExtend extends SealedImplement {}

interface class InterfaceSealedImplementExtend extends SealedImplement {}

final class FinalSealedImplementExtend extends SealedImplement {}

sealed class SealedSealedImplementExtend extends SealedImplement {}

// Implementing through a sealed class.

class SimpleSealedImplementImplement implements SealedImplement {}

base class BaseSealedImplementImplement implements SealedImplement {}

interface class InterfaceSealedImplementImplement implements SealedImplement {}

final class FinalSealedImplementImplement implements SealedImplement {}

sealed class SealedSealedImplementImplement implements SealedImplement {}

base mixin class BaseMixinClassSealedImplementImplement
    implements SealedImplement {}

base mixin BaseMixinSealedImplementImplement implements SealedImplement {}

base mixin BaseMixinSealedImplementOn on SealedImplement {}

// Implementing with a mixin class.

mixin class SimpleMixinClassImplement implements InterfaceClass {}

// Extending through a mixin class.

class SimpleSimpleMixinClassImplementExtend extends SimpleMixinClassImplement {}

base class BaseSimpleMixinClassImplementExtend
    extends SimpleMixinClassImplement {}

interface class InterfaceSimpleMixinClassImplementExtend
    extends SimpleMixinClassImplement {}

final class FinalSimpleMixinClassImplementExtend
    extends SimpleMixinClassImplement {}

sealed class SealedSimpleMixinClassImplementExtend
    extends SimpleMixinClassImplement {}

// Implementing through a mixin class.

class SimpleSimpleMixinClassImplementImplement
    implements SimpleMixinClassImplement {}

base class BaseSimpleMixinClassImplementImplement
    implements SimpleMixinClassImplement {}

interface class InterfaceSimpleMixinClassImplementImplement
    implements SimpleMixinClassImplement {}

final class FinalSimpleMixinClassImplementImplement
    implements SimpleMixinClassImplement {}

sealed class SealedSimpleMixinClassImplementImplement
    implements SimpleMixinClassImplement {}

base mixin class BaseMixinClassSimpleMixinClassImplementImplement
    implements SimpleMixinClassImplement {}

base mixin BaseMixinSimpleMixinClassImplementImplement
    implements SimpleMixinClassImplement {}

base mixin BaseMixinSimpleMixinClassImplementOn on SimpleMixinClassImplement {}

// Implementing with a base mixin class.

base mixin class BaseMixinClassImplement implements InterfaceClass {}

// Extending through a base mixin class.

base class BaseBaseMixinClassImplementExtend extends BaseMixinClassImplement {}

final class FinalBaseMixinClassImplementExtend
    extends BaseMixinClassImplement {}

sealed class SealedBaseMixinClassImplementExtend
    extends BaseMixinClassImplement {}

// Implementing through a base mixin class.

base class BaseBaseMixinClassImplementImplement
    implements BaseMixinClassImplement {}

final class FinalBaseMixinClassImplementImplement
    implements BaseMixinClassImplement {}

sealed class SealedBaseMixinClassImplementImplement
    implements BaseMixinClassImplement {}

base mixin class BaseMixinClassBaseMixinClassImplementImplement
    implements BaseMixinClassImplement {}

base mixin BaseMixinBaseMixinClassImplementImplement
    implements BaseMixinClassImplement {}

base mixin BaseMixinBaseMixinClassImplementOn on BaseMixinClassImplement {}

// Implementing by applying a mixin class.

class SimpleMixinClassImplementApplied extends Object
    with SimpleMixinClassImplement {}

base class BaseMixinClassImplementApplied extends Object
    with SimpleMixinClassImplement {}

interface class InterfaceMixinClassImplementApplied extends Object
    with SimpleMixinClassImplement {}

final class FinalMixinClassImplementApplied extends Object
    with SimpleMixinClassImplement {}

sealed class SealedMixinClassImplementApplied extends Object
    with SimpleMixinClassImplement {}

// Implementing with a mixin application class.

class SimpleImplementApplication = Object
    with _MixinOnObject
    implements InterfaceClass;

base class BaseImplementApplication = Object
    with _MixinOnObject
    implements InterfaceClass;

interface class InterfaceImplementApplication = Object
    with _MixinOnObject
    implements InterfaceClass;

final class FinalImplementApplication = Object
    with _MixinOnObject
    implements InterfaceClass;

sealed class SealedImplementApplication = Object
    with _MixinOnObject
    implements InterfaceClass;

// Implementing with a mixin.

mixin SimpleMixinImplement implements InterfaceClass {}

// Implementing through a mixin.

class SimpleSimpleMixinImplementImplement implements SimpleMixinImplement {}

base class BaseSimpleMixinImplementImplement implements SimpleMixinImplement {}

interface class InterfaceSimpleMixinImplementImplement
    implements SimpleMixinImplement {}

final class FinalSimpleMixinImplementImplement
    implements SimpleMixinImplement {}

sealed class SealedSimpleMixinImplementImplement
    implements SimpleMixinImplement {}

// Implementing with a base mixin.

base mixin BaseMixinImplement implements InterfaceClass {}

// Implementing through a base mixin.

base class BaseBaseMixinImplementImplement implements BaseMixinImplement {}

final class FinalBaseMixinImplementImplement implements BaseMixinImplement {}

sealed class SealedBaseMixinImplementImplement implements BaseMixinImplement {}

// Implementing by applying a mixin.

class SimpleMixinImplementApplied extends Object with SimpleMixinImplement {}

base class BaseMixinImplementApplied extends Object with SimpleMixinImplement {}

interface class InterfaceMixinImplementApplied extends Object
    with SimpleMixinImplement {}

final class FinalMixinImplementApplied extends Object
    with SimpleMixinImplement {}

sealed class SealedMixinImplementApplied extends Object
    with SimpleMixinImplement {}

// Implementing with a mixin on type.

mixin SimpleMixinOn on InterfaceClass {}

// Implementing through a mixin on type.

class SimpleSimpleMixinOnImplement implements SimpleMixinOn {}

base class BaseSimpleMixinOnImplement implements SimpleMixinOn {}

interface class InterfaceSimpleMixinOnImplement implements SimpleMixinOn {}

final class FinalSimpleMixinOnImplement implements SimpleMixinOn {}

sealed class SealedSimpleMixinOnImplement implements SimpleMixinOn {}

// Implementing with a base mixin on type.

base mixin BaseMixinOn on InterfaceClass {}

// Implementing through a base mixin on type.

base class BaseBaseMixinOnImplement implements BaseMixinOn {}

final class FinalBaseMixinOnImplement implements BaseMixinOn {}

sealed class SealedBaseMixinOnImplement implements BaseMixinOn {}

// This test is intended just to check that certain combinations of modifiers
// are statically allowed.  Make this a static error test so that backends don't
// try to run it.
int x = "This is a static error test";
//      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
// [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
