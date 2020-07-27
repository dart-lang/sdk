// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Simple test of the subtype relationship on generic function types.

typedef F1 = void Function<X1 extends num>();
typedef F2 = void Function<X2 extends String>();

void f1<Y1 extends num>() {}
void f2<Y2 extends String>() {}

void foo() {
  F1 f11 = f1;
  F1 f12 = f2;
  //       ^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'void Function<Y2 extends String>()' can't be assigned to a variable of type 'void Function<X1 extends num>()'.

  F2 f21 = f1;
  //       ^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'void Function<Y1 extends num>()' can't be assigned to a variable of type 'void Function<X2 extends String>()'.
  F2 f22 = f2;
}

main() {}
