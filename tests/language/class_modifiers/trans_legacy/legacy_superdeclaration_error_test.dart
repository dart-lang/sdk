// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "legacy_lib.dart";

// Not allowed to implement a class (from anywhere) which has a base/final
// superclass in any other library.

abstract base class ImplementsLegacyImplementsFinal
    implements LegacyImplementsFinal {
//             ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'MapEntry' can't be implemented outside of its library because it's a final class.
}

abstract base class ImplementsLegacyExtendsFinal implements LegacyExtendsFinal {
//                                                          ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'ListQueue' can't be implemented outside of its library because it's a final class.
}

abstract base class ImplementsLegacyMixesInFinal implements LegacyMixesInFinal {
//                                                          ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'BigInt' can't be implemented outside of its library because it's a final class.
}

abstract base class ImplementsLegacyImplementsBase
    implements LegacyImplementsBase {
//             ^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'LinkedList' can't be implemented outside of its library because it's a base class.
}

abstract base class ImplementsLegacyMixinOnFinal implements LegacyMixinOnFinal {
//                                                          ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'MapEntry' can't be implemented outside of its library because it's a final class.
}

// Not allowed to omit base on classes with base/final superclasses.

abstract class ExtendsLegacyImplementsFinal extends LegacyImplementsFinal {
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'ExtendsLegacyImplementsFinal' must be 'base', 'final' or 'sealed' because the supertype 'MapEntry' is 'final'.
}

abstract class ExtendsLegacyImplementsFinal2 = LegacyImplementsFinal
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'ExtendsLegacyImplementsFinal2' must be 'base', 'final' or 'sealed' because the supertype 'MapEntry' is 'final'.
    with
        _AnyMixin;

abstract class ExtendsLegacyExtendsFinal extends LegacyExtendsFinal {}
//             ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'ExtendsLegacyExtendsFinal' must be 'base', 'final' or 'sealed' because the supertype 'ListQueue' is 'final'.

abstract class ExtendsLegacyExtendsFinal2 = LegacyExtendsFinal2 with _AnyMixin;
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'ExtendsLegacyExtendsFinal2' must be 'base', 'final' or 'sealed' because the supertype 'ListQueue' is 'final'.

abstract class ExtendsLegacyMixesInFinal extends LegacyMixesInFinal {}
//             ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'ExtendsLegacyMixesInFinal' must be 'base', 'final' or 'sealed' because the supertype 'BigInt' is 'final'.

abstract class ExtendsLegacyMixesInFinal2 = LegacyMixesInFinal2 with _AnyMixin;
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'ExtendsLegacyMixesInFinal2' must be 'base', 'final' or 'sealed' because the supertype 'BigInt' is 'final'.

abstract class ExtendsLegacyImplementsBase extends LegacyImplementsBase {}
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'ExtendsLegacyImplementsBase' must be 'base', 'final' or 'sealed' because the supertype 'LinkedList' is 'base'.

abstract class ExtendsLegacyImplementsBase2 = LegacyImplementsBase
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'ExtendsLegacyImplementsBase2' must be 'base', 'final' or 'sealed' because the supertype 'LinkedList' is 'base'.
    with
        _AnyMixin;

abstract class MixesInLegacyImplementsFinal with LegacyImplementsFinal {}
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixesInLegacyImplementsFinal' must be 'base', 'final' or 'sealed' because the supertype 'MapEntry' is 'final'.

abstract class MixesInLegacyImplementsFinal2 = Object
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixesInLegacyImplementsFinal2' must be 'base', 'final' or 'sealed' because the supertype 'MapEntry' is 'final'.
    with
        LegacyImplementsFinal;

abstract class MixesInLegacyMixesInFinal with LegacyMixesInFinal2 {}
//             ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixesInLegacyMixesInFinal' must be 'base', 'final' or 'sealed' because the supertype 'BigInt' is 'final'.

abstract class MixesInLegacyMixesInFinal2 = Object with LegacyMixesInFinal2;
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixesInLegacyMixesInFinal2' must be 'base', 'final' or 'sealed' because the supertype 'BigInt' is 'final'.

abstract class MixesInLegacyImplementsBase with LegacyImplementsBase {}
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixesInLegacyImplementsBase' must be 'base', 'final' or 'sealed' because the supertype 'LinkedList' is 'base'.

abstract class MixesInLegacyImplementsBase2 = Object with LegacyImplementsBase;
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixesInLegacyImplementsBase2' must be 'base', 'final' or 'sealed' because the supertype 'LinkedList' is 'base'.

abstract class MixesInMixinOnFinal extends LegacyImplementsFinal
//             ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixesInMixinOnFinal' must be 'base', 'final' or 'sealed' because the supertype 'MapEntry' is 'final'.
    with
        LegacyMixinOnFinal {}

abstract class MixesInMixinOnFinal2 = LegacyImplementsFinal
//             ^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixesInMixinOnFinal2' must be 'base', 'final' or 'sealed' because the supertype 'MapEntry' is 'final'.
    with
        LegacyMixinOnFinal;

abstract class MixesInMixinOnBase extends LegacyMixinOnBaseSuper
//             ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixesInMixinOnBase' must be 'base', 'final' or 'sealed' because the supertype 'LinkedListEntry' is 'base'.
    with
        LegacyMixinOnBase {}

abstract class MixesInMixinOnBase2 = LegacyMixinOnBaseSuper
//             ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixesInMixinOnBase2' must be 'base', 'final' or 'sealed' because the supertype 'LinkedListEntry' is 'base'.
    with
        LegacyMixinOnBase;

abstract class MixesInMixinImplementsFinal with LegacyMixinImplementsFinal {}
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixesInMixinImplementsFinal' must be 'base', 'final' or 'sealed' because the supertype 'MapEntry' is 'final'.

abstract class MixesInMixinImplementsFinal2 = Object
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixesInMixinImplementsFinal2' must be 'base', 'final' or 'sealed' because the supertype 'MapEntry' is 'final'.
    with
        LegacyMixinImplementsFinal;

abstract class MixesInMixinImplementsBase with LegacyMixinImplementsBase {}
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixesInMixinImplementsBase' must be 'base', 'final' or 'sealed' because the supertype 'LinkedList' is 'base'.

abstract class MixesInMixinImplementsBase2 = Object
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'MixesInMixinImplementsBase2' must be 'base', 'final' or 'sealed' because the supertype 'LinkedList' is 'base'.
    with
        LegacyMixinImplementsBase;

// Helpers.
mixin _AnyMixin {}

void main() {}
