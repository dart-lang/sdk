// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C1<T> extends Object with Malformed {}
//    ^
// [cfe] The type 'Malformed' can't be mixed in.
//                              ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_OF_NON_CLASS
// [cfe] Type 'Malformed' not found.

class C2<T> extends Object with T {}
//    ^
// [cfe] The type 'T' can't be mixed in.
//                              ^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_OF_NON_CLASS
// [cfe] The type variable 'T' can't be used as supertype.

class C3<T> extends Object with T<int> {}
//    ^
// [cfe] The type 'T<int>' can't be mixed in.
//                              ^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_OF_NON_CLASS
//                              ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
// [cfe] Can't use type arguments with type variable 'T'.

void main() {}