// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(https://github.com/dart-lang/sdk/issues/51557): Decide if the mixins
// being applied in this test should be "mixin", "mixin class" or the test
// should be left at 2.19.
// @dart=2.19

class BadExtends extends Null {}
//                       ^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE
//    ^
// [cfe] 'Null' is restricted and can't be extended or implemented.
// [cfe] The superclass, 'Null', has no unnamed constructor that takes no arguments.
// [cfe] Subtypes of deeply immutable classes must be deeply immutable.
//                       ^
// [cfe] 'Null' is restricted and can't be extended or implemented.

class BadImplements implements Null {}
//                             ^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE
//    ^
// [cfe] 'Null' is restricted and can't be extended or implemented.
// [cfe] Subtypes of deeply immutable classes must be deeply immutable.
//                             ^
// [cfe] 'Null' is restricted and can't be extended or implemented.

class BadMixin extends Object with Null {}
//                                 ^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE
//    ^
// [cfe] 'Null' is restricted and can't be extended or implemented.
// [cfe] Subtypes of deeply immutable classes must be deeply immutable.
//                                 ^
// [cfe] 'Null' is restricted and can't be extended or implemented.

class BadMixin2 = Object with Null;
//                            ^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE
//    ^
// [cfe] 'Null' is restricted and can't be extended or implemented.
// [cfe] Subtypes of deeply immutable classes must be deeply immutable.
//                            ^
// [cfe] 'Null' is restricted and can't be extended or implemented.
