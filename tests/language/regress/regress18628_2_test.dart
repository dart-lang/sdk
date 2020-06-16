// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks for a regression found in Dart Editor: the
// analyzer was treating [Type] as more specific than any type
// variable (generic parameter).
//
// https://code.google.com/p/dart/issues/detail?id=18628

class X<T extends Type> {}

// This line is supposed to cause the warning; the other lines are
// marked because they don't make sense when [Y] is not defined.
class Y<U> extends X<U> {}
//    ^
// [cfe] Type argument 'U' doesn't conform to the bound 'Type' of the type variable 'T' on 'X' in the supertype 'X' of class 'Y'.
//                   ^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

main() {
  X<Type> x = new X<Type>();
  Y<Type> y = new Y<Type>();
}
