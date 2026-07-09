// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when subtyping a final class where the subtype is not base, final or
// sealed.

final class FinalClass {}
//          ^^^^^^^^^^
// [context 1] The type 'SubtypeOfFinal' is a subtype of 'FinalClass', and 'FinalClass' is defined here.
// [context 2] The type 'SubtypeOfFinal' is a subtype of 'FinalClass', and 'FinalClass' is defined here.

base class BaseClass extends FinalClass {}

sealed class SubtypeOfFinal extends FinalClass {}

class RegularClass {}

class Extends extends FinalClass {}
//    ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'Extends' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

class Implements implements FinalClass {}
//    ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'Implements' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

mixin MixinImplements implements FinalClass {}
//    ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The mixin 'MixinImplements' must be 'base' because the supertype 'FinalClass' is 'final'.

mixin MixinImplementsIndirect implements SubtypeOfFinal {}
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer 1] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The mixin 'MixinImplementsIndirect' must be 'base' because the supertype 'FinalClass' is 'final'.

mixin On on FinalClass {}
//    ^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The mixin 'On' must be 'base' because the supertype 'FinalClass' is 'final'.

class ExtendsExtends extends Extends {}

class Multiple extends RegularClass implements FinalClass {}
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'Multiple' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.

class IndirectSubtype extends SubtypeOfFinal {}
//    ^^^^^^^^^^^^^^^
// [analyzer 2] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'IndirectSubtype' must be 'base', 'final' or 'sealed' because the supertype 'FinalClass' is 'final'.
