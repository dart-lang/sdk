// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers,sealed-class

// Error when subtyping a final class where the subtype is not base, final or
// sealed.

final class FinalClass {}

final mixin FinalMixin {}

base class BaseClass extends FinalClass {}

sealed class SubtypeOfFinal extends FinalClass {}

class RegularClass {}

final mixin FinalMixin2 {}

class Extends extends FinalClass {}
//    ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'Extends' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

class Implements implements FinalClass {}
//    ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'Implements' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

mixin MixinImplements implements FinalMixin {}
//    ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixinImplements' must be 'base', 'final' or 'sealed' because the supertype 'FinalMixin' is 'final'.

class With with FinalMixin {}
//    ^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'With' must be 'base', 'final' or 'sealed' because the supertype 'FinalMixin' is 'final'.

class With2 with FinalMixin, FinalMixin2 {}
//    ^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'With2' must be 'base', 'final' or 'sealed' because the supertype 'FinalMixin' is 'final'.

mixin On on FinalClass {}
//    ^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'On' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

class ExtendsExtends extends Extends {}
//    ^
// [cfe] The type 'ExtendsExtends' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

class Multiple extends BaseClass implements FinalMixin {}
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'Multiple' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

class Multiple2 extends RegularClass implements FinalClass {}
//    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'Multiple2' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

class IndirectSubtype extends SubtypeOfFinal {}
//    ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'IndirectSubtype' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.
