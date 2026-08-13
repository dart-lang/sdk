// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class BadExtends extends Null {}
//    ^
// [cfe] 'Null' is restricted and can't be extended or implemented.
// [cfe] Subtypes of deeply immutable classes must be deeply immutable.
// [cfe] The superclass, 'Null', has no unnamed constructor that takes no arguments.
//                       ^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE
// [cfe] 'Null' is restricted and can't be extended or implemented.
// [cfe] The class 'Null' can't be extended outside of its library because it's a final class.

class BadImplements implements Null {}
//    ^
// [cfe] 'Null' is restricted and can't be extended or implemented.
// [cfe] Subtypes of deeply immutable classes must be deeply immutable.
//                             ^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE
// [cfe] 'Null' is restricted and can't be extended or implemented.
// [cfe] The class 'Null' can't be implemented outside of its library because it's a final class.

class BadMixin extends Object with Null {}
//    ^
// [cfe] 'Null' is restricted and can't be extended or implemented.
// [cfe] Subtypes of deeply immutable classes must be deeply immutable.
// [cfe] The type 'BadMixin' must be 'base', 'final' or 'sealed' because the supertype 'Null' is 'final'.
//                                 ^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE
// [cfe] 'Null' is restricted and can't be extended or implemented.
// [cfe] The class 'Null' can't be used as a mixin because it isn't a mixin class nor a mixin.

class BadMixin2 = Object with Null;
//    ^
// [cfe] 'Null' is restricted and can't be extended or implemented.
// [cfe] Subtypes of deeply immutable classes must be deeply immutable.
//                            ^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE
// [cfe] 'Null' is restricted and can't be extended or implemented.
// [cfe] The class 'Null' can't be used as a mixin because it isn't a mixin class nor a mixin.
