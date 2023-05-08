// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

/// Test the valid uses of a sealed class within the same library

sealed class SealedClass {}

mixin _MixinOnObject {}

/// SealedClass can be extended.

// Simple extension.

class SimpleExtend extends SealedClass {}

base class BaseExtend extends SealedClass {}

interface class InterfaceExtend extends SealedClass {}

final class FinalExtend extends SealedClass {}

// Extending with a sealed class.

sealed class SealedExtend extends SealedClass {}

// Extending through a sealed class.

class SimpleSealedExtendExtend extends SealedExtend {}

base class BaseSealedExtendExtend extends SealedExtend {}

interface class InterfaceSealedExtendExtend extends SealedExtend {}

final class FinalSealedExtendExtend extends SealedExtend {}

sealed class SealedSealedExtendExtend extends SealedExtend {}

// Implementing through a sealed class.

class SimpleSealedExtendImplement implements SealedExtend {}

base class BaseSealedExtendImplement implements SealedExtend {}

interface class InterfaceSealedExtendImplement implements SealedExtend {}

final class FinalSealedExtendImplement implements SealedExtend {}

sealed class SealedSealedExtendImplement implements SealedExtend {}

mixin class MixinClassSealedExtendImplement implements SealedExtend {}

base mixin class BaseMixinClassSealedExtendImplement implements SealedExtend {}

mixin MixinSealedExtendImplement implements SealedExtend {}

base mixin BaseMixinSealedExtendImplement implements SealedExtend {}

// Using a sealed class as an `on` type

mixin MixinSealedExtendOn on SealedExtend {}

base mixin BaseMixinSealedExtendOn on SealedExtend {}

// Extending via an anonymous mixin class.

class SimpleExtendWith extends SealedClass with _MixinOnObject {}

base class BaseExtendWith extends SealedClass with _MixinOnObject {}

interface class InterfaceExtendWith extends SealedClass with _MixinOnObject {}

final class FinalExtendWith extends SealedClass with _MixinOnObject {}

sealed class SealedExtendWith extends SealedClass with _MixinOnObject {}

// Extending via an anonymous mixin application class.

class SimpleExtendApplication = SealedClass with _MixinOnObject;

interface class InterfaceExtendApplication = SealedClass with _MixinOnObject;

final class FinalExtendApplication = SealedClass with _MixinOnObject;

base class BaseExtendApplication = SealedClass with _MixinOnObject;

sealed class SealedExtendApplication = SealedClass with _MixinOnObject;

/// SealedClass can be implemented.

// Simple implementation.

class SimpleImplement implements SealedClass {}

base class BaseImplement implements SealedClass {}

interface class InterfaceImplement implements SealedClass {}

final class FinalImplement implements SealedClass {}

// Implementing with a sealed class.

sealed class SealedImplement implements SealedClass {}

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

// Implementing with a mixin class.
mixin class SimpleMixinClassImplement implements SealedClass {}

base mixin class BaseMixinClassImplement implements SealedClass {}

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
    implements SealedClass;

base class BaseImplementApplication = Object
    with _MixinOnObject
    implements SealedClass;

interface class InterfaceImplementApplication = Object
    with _MixinOnObject
    implements SealedClass;

final class FinalImplementApplication = Object
    with _MixinOnObject
    implements SealedClass;

sealed class SealedImplementApplication = Object
    with _MixinOnObject
    implements SealedClass;

// Implementing with a mixin.

mixin SimpleMixinImplement implements SealedClass {}

base mixin BaseMixinImplement implements SealedClass {}

// Implementing by applying a mixin.

class SimpleMixinImplementApplied extends Object with SimpleMixinImplement {}

base class BaseMixinImplementApplied extends Object with SimpleMixinImplement {}

interface class InterfaceMixinImplementApplied extends Object
    with SimpleMixinImplement {}

final class FinalMixinImplementApplied extends Object
    with SimpleMixinImplement {}

sealed class SealedMixinImplementApplied extends Object
    with SimpleMixinImplement {}

/// SealedClass can be an `on` type.

mixin SimpleMixinOn on SealedClass {}

base mixin BaseMixinOn on SealedClass {}

// This test is intended just to check that certain combinations of modifiers
// are statically allowed.  Make this a static error test so that backends don't
// try to run it.
int x = "This is a static error test";
//      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
// [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
