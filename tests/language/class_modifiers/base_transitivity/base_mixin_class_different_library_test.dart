// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

/// Test the valid uses of a base mixin class defined in a different library

import "shared_library_definitions.dart" show BaseMixinClass;

mixin _MixinOnObject {}

/// Base mixin classes from a different library can be extended, so long as the
/// subtype is base, final or sealed.

/// Subclasses of base mixin classes from a different library can be extended,
/// so long as the subtype is base, final, or sealed.

// Extending with a base class.

base class BaseExtend extends BaseMixinClass {}

// Extending through a base class.

base class BaseBaseExtendExtend extends BaseExtend {}

final class FinalBaseExtendExtend extends BaseExtend {}

sealed class SealedBaseExtendExtend extends BaseExtend {}

// Implementing through a base class

base mixin BaseMixinBaseExtendOn on BaseExtend {}

// Extending with a final class

final class FinalExtend extends BaseMixinClass {}

// Extending through a final class.

base class BaseFinalExtendExtend extends FinalExtend {}

final class FinalFinalExtendExtend extends FinalExtend {}

sealed class SealedFinalExtendExtend extends FinalExtend {}

// Implementing through a final class

base mixin BaseMixinFinalExtendOn on FinalExtend {}

// Extending with a sealed class.

sealed class SealedExtend extends BaseMixinClass {}

// Extending through a sealed class.

base class BaseSealedExtendExtend extends SealedExtend {}

final class FinalSealedExtendExtend extends SealedExtend {}

sealed class SealedSealedExtendExtend extends SealedExtend {}

// Using a sealed class as an `on` type

base mixin BaseMixinSealedExtendOn on SealedExtend {}

// Extending via an anonymous mixin class.

base class BaseExtendWith extends BaseMixinClass with _MixinOnObject {}

final class FinalExtendWith extends BaseMixinClass with _MixinOnObject {}

sealed class SealedExtendWith extends BaseMixinClass with _MixinOnObject {}

// Extending via an anonymous mixin application class.

final class FinalExtendApplication = BaseMixinClass with _MixinOnObject;

base class BaseExtendApplication = BaseMixinClass with _MixinOnObject;

sealed class SealedExtendApplication = BaseMixinClass with _MixinOnObject;

/// BaseMixinClass can be an `on` type, so long as the subtype is base.

base mixin BaseMixinOn on BaseMixinClass {}

base mixin BaseMixinBaseMixinOnOn on BaseMixinOn {}

/// BaseMixinClass can be used as a mixin, so long as the result is base, final,
/// or sealed.

base class BaseMixinClassApply extends Object with BaseMixinClass {}

final class FinalMixinClassApply extends Object with BaseMixinClass {}

sealed class SealedMixinClassApply extends Object with BaseMixinClass {}

// Extending through a sealed class.

base class BaseSealedMixinClassApplyExtend extends SealedMixinClassApply {}

final class FinalSealedMixinClassApplyExtend extends SealedMixinClassApply {}

sealed class SealedSealedMixinClassApplyExtend extends SealedMixinClassApply {}

// Using a sealed class as an `on` type

base mixin BaseMixinSealedMixinApplyOn on SealedMixinClassApply {}

/// BaseMixinClass can be used as a mixin application, so long as the result is
/// base, final, or sealed.

base class BaseMixinApplication = Object with BaseMixinClass;

// Extending through a base class.

base class BaseBaseMixinApplicationExtend extends BaseMixinApplication {}

final class FinalBaseMixinApplicationExtend extends BaseMixinApplication {}

sealed class SealedBaseMixinApplicationExtend extends BaseMixinApplication {}

final class FinalMixinApplication = Object with BaseMixinClass;

// Extending through a final class.

base class BaseFinalMixinApplicationExtend extends FinalMixinApplication {}

final class FinalFinalMixinApplicationExtend extends FinalMixinApplication {}

sealed class SealedFinalMixinApplicationExtend extends FinalMixinApplication {}

sealed class SealedMixinApplication = Object with BaseMixinClass;

// Extending through a sealed class.

base class BaseSealedMixinApplicationExtend extends SealedMixinApplication {}

final class FinalSealedMixinApplicationExtend extends SealedMixinApplication {}

sealed class SealedSealedMixinApplicationExtend
    extends SealedMixinApplication {}

// Using a sealed class as an `on` type

base mixin BaseMixinSealedMixinApplicationOn on SealedMixinApplication {}

// This test is intended just to check that certain combinations of modifiers
// are statically allowed.  Make this a static error test so that backends don't
// try to run it.
int x = "This is a static error test";
//      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
// [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
