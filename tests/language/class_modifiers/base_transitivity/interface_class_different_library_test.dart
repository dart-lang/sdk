// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

/// Test the valid uses of an interface class defined in a different library

import "shared_library_definitions.dart" show InterfaceClass;

mixin _MixinOnObject {}

/// InterfaceClass can be implemented.

// Simple implementation.
class SimpleImplement implements InterfaceClass {}

base class BaseImplement implements InterfaceClass {}

interface class InterfaceImplement implements InterfaceClass {}

final class FinalImplement implements InterfaceClass {}

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

// Implementing with a mixin class.
mixin class SimpleMixinClassImplement implements InterfaceClass {}

base mixin class BaseMixinClassImplement implements InterfaceClass {}

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

base mixin BaseMixinImplement implements InterfaceClass {}

// Implementing by applying a mixin.
class SimpleMixinImplementApplied extends Object with SimpleMixinImplement {}

base class BaseMixinImplementApplied extends Object with SimpleMixinImplement {}

interface class InterfaceMixinImplementApplied extends Object
    with SimpleMixinImplement {}

final class FinalMixinImplementApplied extends Object
    with SimpleMixinImplement {}

sealed class SealedMixinImplementApplied extends Object
    with SimpleMixinImplement {}

/// InterfaceClass can be an `on` type.

mixin SimpleMixinOn on InterfaceClass {}

base mixin BaseMixinOn on InterfaceClass {}

main() {}
