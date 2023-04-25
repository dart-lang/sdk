// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

/// Test the valid uses of a base mixin defined in a different library

import "shared_library_definitions.dart" show BaseMixin;

/// BaseMixin can be an `on` type, so long as the subtype is base.

base mixin BaseMixinOn on BaseMixin {}

/// BaseMixin can be used as a mixin, so long as the result is base, final,
/// or sealed.

// Mixin to produce a base class.

base class BaseMixinApply extends Object with BaseMixin {}

// Extending through a base class.

base class BaseBaseMixinApplyExtend extends BaseMixinApply {}

final class FinalBaseMixinApplyExtend extends BaseMixinApply {}

sealed class SealedBaseMixinApplyExtend extends BaseMixinApply {}

// Mixin to produce a final class.

final class FinalMixinApply extends Object with BaseMixin {}

// Extending through a final class.

base class BaseFinalMixinApplyExtend extends FinalMixinApply {}

final class FinalFinalMixinApplyExtend extends FinalMixinApply {}

sealed class SealedFinalMixinApplyExtend extends FinalMixinApply {}

// Mixin to produce a sealed class.

sealed class SealedMixinApply extends Object with BaseMixin {}

// Extending through a sealed class.

base class BaseSealedMixinApplyExtend extends SealedMixinApply {}

final class FinalSealedMixinApplyExtend extends SealedMixinApply {}

sealed class SealedSealedMixinApplyExtend extends SealedMixinApply {}

// Using a sealed class as an `on` type

base mixin BaseMixinSealedMixinApplyOn on SealedMixinApply {}

/// BaseMixin can be used as a mixin application, so long as the result is
/// base, final, or sealed.

base class BaseMixinApplication = Object with BaseMixin;

final class FinalMixinApplication = Object with BaseMixin;

sealed class SealedMixinApplication = Object with BaseMixin;

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
