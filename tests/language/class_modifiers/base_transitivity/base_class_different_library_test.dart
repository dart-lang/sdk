// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

/// Test the valid uses of a base class defined in a different library

import "shared_library_definitions.dart" show BaseClass;

mixin _MixinOnObject {}

/// Base classes from a different library can be extended, so long as the
/// subtype is base, final or sealed.

/// Subclasses of base classes from a different library can be extended, so long
/// as the subtype is base, final, or sealed.

// Extending with a base class.

base class BaseExtend extends BaseClass {}

// Extending through a base class.

base class BaseBaseExtendExtend extends BaseExtend {}

final class FinalBaseExtendExtend extends BaseExtend {}

sealed class SealedBaseExtendExtend extends BaseExtend {}

// Implementing through a base class

base mixin BaseMixinBaseExtendOn on BaseExtend {}

// Extending with a final class

final class FinalExtend extends BaseClass {}

// Extending through a final class.

base class BaseFinalExtendExtend extends FinalExtend {}

final class FinalFinalExtendExtend extends FinalExtend {}

sealed class SealedFinalExtendExtend extends FinalExtend {}

// Implementing through a final class

base mixin BaseMixinFinalExtendOn on FinalExtend {}

// Extending with a sealed class.

sealed class SealedExtend extends BaseClass {}

// Extending through a sealed class.
base class BaseSealedExtendExtend extends SealedExtend {}

final class FinalSealedExtendExtend extends SealedExtend {}

sealed class SealedSealedExtendExtend extends SealedExtend {}

// Using a sealed class as an `on` type

base mixin BaseMixinSealedExtendOn on SealedExtend {}

// Extending via an anonymous mixin class.

base class BaseExtendWith extends BaseClass with _MixinOnObject {}

final class FinalExtendWith extends BaseClass with _MixinOnObject {}

sealed class SealedExtendWith extends BaseClass with _MixinOnObject {}

// Extending via an anonymous mixin application class.

final class FinalExtendApplication = BaseClass with _MixinOnObject;

base class BaseExtendApplication = BaseClass with _MixinOnObject;

sealed class SealedExtendApplication = BaseClass with _MixinOnObject;

/// BaseClass can be an `on` type, so long as the subtype is base.

base mixin BaseMixinOn on BaseClass {}

base mixin BaseMixinBaseMixinOnOn on BaseMixinOn {}

// This test is intended just to check that certain combinations of modifiers
// are statically allowed.  Make this a static error test so that backends don't
// try to run it.
int x = "This is a static error test";
//      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
// [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
