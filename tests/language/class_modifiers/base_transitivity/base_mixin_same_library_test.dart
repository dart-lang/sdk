// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

/// Test the valid uses of a base mixin within the same library

base mixin BaseMixin {}

mixin _MixinOnObject {}

/// BaseMixin can be implemented, so long as the subtype is base, final, or
/// sealed

// Simple implementation.

base class BaseImplement implements BaseMixin {}

final class FinalImplement implements BaseMixin {}

// Implementing with a sealed class.

sealed class SealedImplement implements BaseMixin {}

// Extending through a sealed class.

base class BaseSealedImplementExtend extends SealedImplement {}

final class FinalSealedImplementExtend extends SealedImplement {}

sealed class SealedSealedImplementExtend extends SealedImplement {}

// Implementing through a sealed class.

base class BaseSealedImplementImplement implements SealedImplement {}

final class FinalSealedImplementImplement implements SealedImplement {}

sealed class SealedSealedImplementImplement implements SealedImplement {}

// Implementing with a mixin class.

base mixin class BaseMixinClassImplement implements BaseMixin {}

// Implementing by applying a mixin class.

base class BaseMixinClassImplementApplied extends Object
    with BaseMixinClassImplement {}

final class FinalMixinClassImplementApplied extends Object
    with BaseMixinClassImplement {}

sealed class SealedMixinClassImplementApplied extends Object
    with BaseMixinClassImplement {}

// Implementing with a mixin application class.

base class BaseImplementApplication = Object
    with _MixinOnObject
    implements BaseMixin;
final class FinalImplementApplication = Object
    with _MixinOnObject
    implements BaseMixin;
sealed class SealedImplementApplication = Object
    with _MixinOnObject
    implements BaseMixin;

// Implementing with a mixin.

base mixin BaseMixinImplement implements BaseMixin {}

// Implementing by applying a mixin.

base class BaseMixinImplementApplied extends Object with BaseMixinImplement {}

final class FinalMixinImplementApplied extends Object with BaseMixinImplement {}

sealed class SealedMixinImplementApplied extends Object
    with BaseMixinImplement {}

/// BaseMixin can be an `on` type, so long as the subtype is base.

base mixin BaseMixinOn on BaseMixin {}

/// BaseMixin can be used as a mixin, so long as the result is base, final,
/// or sealed.

base class BaseMixinApply extends Object with BaseMixin {}

final class FinalMixinClassApply extends Object with BaseMixin {}

sealed class SealedMixinClassApply extends Object with BaseMixin {}

// Extending through a sealed class.

base class BaseSealedMixinClassApplyExtend extends SealedMixinClassApply {}

final class FinalSealedMixinClassApplyExtend extends SealedMixinClassApply {}

sealed class SealedSealedMixinClassApplyExtend extends SealedMixinClassApply {}

// Implementing through a sealed class.

base class BaseSealedMixinClassApplyImplement
    implements SealedMixinClassApply {}

final class FinalSealedMixinClassApplyImplement
    implements SealedMixinClassApply {}

sealed class SealedSealedMixinClassApplyImplement
    implements SealedMixinClassApply {}

base mixin class BaseMixinSealedMixinClassApplyImplement
    implements SealedMixinClassApply {}

base mixin BaseMixinSealedMixinApplyImplement
    implements SealedMixinClassApply {}

// Using a sealed class as an `on` type

base mixin BaseMixinSealedMixinApplyOn on SealedMixinClassApply {}

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

// Implementing through a sealed class.

base class BaseSealedMixinApplicationImplement
    implements SealedMixinApplication {}

final class FinalSealedMixinApplicationImplement
    implements SealedMixinApplication {}

sealed class SealedSealedMixinApplicationImplement
    implements SealedMixinApplication {}

base mixin class BaseMixinClassSealedMixinApplicationImplement
    implements SealedMixinApplication {}

base mixin BaseMixinSealedMixinApplicationImplement
    implements SealedMixinApplication {}

// Using a sealed class as an `on` type

base mixin BaseMixinSealedMixinApplicationOn on SealedMixinApplication {}

// This test is intended just to check that certain combinations of modifiers
// are statically allowed.  Make this a static error test so that backends don't
// try to run it.
int x = "This is a static error test";
//      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
// [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
