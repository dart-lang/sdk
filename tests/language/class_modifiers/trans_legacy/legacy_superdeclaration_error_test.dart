// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

import "legacy_lib.dart";

// Not allowed to implement a class (from anywhere) which has a base/final
// superclass in any other library.

abstract base class ImplementsLegacyImplementsFinal
    implements LegacyImplementsFinal {
//             ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] unspecified
}

abstract base class ImplementsLegacyExtendsFinal implements LegacyExtendsFinal {
//                                                          ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] unspecified
}

abstract class ImplementsLegacyMixesInFinal implements LegacyMixesInFinal {
//                                                     ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] unspecified
}

abstract base class ImplementsLegacyImplementsBase
    implements LegacyImplementsBase {
//             ^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] unspecified
}

abstract base class ImplementsLegacyMixinOnFinal implements LegacyMixinOnFinal {
//                                                          ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] unspecified
}

// Not allowed to omit base on classes with base/final superclasses.

abstract class ExtendsLegacyImplementsFinal extends LegacyImplementsFinal {
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified
}

abstract class ExtendsLegacyImplementsFinal2 = LegacyImplementsFinal
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified
    with
        _AnyMixin;

abstract class ExtendsLegacyExtendsFinal extends LegacyExtendsFinal {}
//             ^^^^^^^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified

abstract class ExtendsLegacyExtendsFinal2 = LegacyExtendsFinal2 with _AnyMixin;
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified

abstract class ExtendsLegacyMixesInFinal extends LegacyMixesInFinal {}
//             ^^^^^^^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified

abstract class ExtendsLegacyMixesInFinal2 = LegacyMixesInFinal2 with _AnyMixin;
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified

abstract class ExtendsLegacyImplementsBase extends LegacyImplementsBase {}
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified

abstract class ExtendsLegacyImplementsBase2 = LegacyImplementsBase
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified
    with
        _AnyMixin;

abstract class MixesInLegacyImplementsFinal with LegacyImplementsFinal {}
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified

abstract class MixesInLegacyImplementsFinal2 = Object
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified
    with
        LegacyImplementsFinal;

abstract class MixesInLegacyMixesInFinal with LegacyMixesInFinal2 {}
//             ^^^^^^^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified

abstract class MixesInLegacyMixesInFinal2 = Object with LegacyMixesInFinal2;
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified

abstract class MixesInLegacyImplementsBase with LegacyImplementsBase {}
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified

abstract class MixesInLegacyImplementsBase2 = Object with LegacyImplementsBase;
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified

abstract class MixesInMixinOnFinal extends LegacyImplementsFinal
//             ^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified
    with
        LegacyMixinOnFinal {}

abstract class MixesInMixinOnFinal2 = LegacyImplementsFinal
//             ^^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified
    with
        LegacyMixinOnFinal;

abstract class MixesInMixinOnBase extends LegacyMixinOnBaseSuper
//             ^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified
    with
        LegacyMixinOnBase {}

abstract class MixesInMixinOnBase2 = LegacyMixinOnBaseSuper
//             ^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified
    with
        LegacyMixinOnBase;

abstract class MixesInMixinImplementsFinal with LegacyMixinImplementsFinal {}
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified

abstract class MixesInMixinImplementsFinal2 = Object
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified
    with
        LegacyMixinImplementsFinal;

abstract class MixesInMixinImplementsBase with LegacyMixinImplementsBase {}
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified

abstract class MixesInMixinImplementsBase2 = Object
//             ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [cfe] unspecified
// [analyzer] unspecified
    with
        LegacyMixinImplementsBase;

// Helpers.
mixin _AnyMixin {}

void main() {}
