// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when subtyping a base class where the subtype is not base, final or
// sealed.

base class BaseClass {}

base mixin BaseMixin {}

final class FinalClass extends BaseClass {}

sealed class SubtypeOfBase extends BaseClass {}

class RegularClass {}

base mixin BaseMixin2 {}

class Extends extends BaseClass {}
//    ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'Extends' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

class Implements implements BaseClass {}
//    ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'Implements' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

mixin MixinImplements implements BaseMixin {}
//    ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The mixin 'MixinImplements' must be 'base' because the supertype 'BaseMixin' is 'base'.

mixin MixinImplementsIndirect implements SubtypeOfBase {}
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The mixin 'MixinImplementsIndirect' must be 'base' because the supertype 'BaseClass' is 'base'.

class With with BaseMixin {}
//    ^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'With' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.

class With2 with BaseMixin, BaseMixin2 {}
//    ^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'With2' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.

mixin On on BaseClass {}
//    ^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The mixin 'On' must be 'base' because the supertype 'BaseClass' is 'base'.

class ExtendsExtends extends Extends {}

class Multiple extends FinalClass implements BaseMixin {}
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'Multiple' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

class Multiple2 extends RegularClass implements BaseClass {}
//    ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'Multiple2' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

class IndirectSubtype extends SubtypeOfBase {}
//    ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'IndirectSubtype' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.
