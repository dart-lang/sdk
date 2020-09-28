// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of the subtype relationship that includes parametrized typedefs and
// invariant occurrences of types.

typedef H<X> = void Function<Y extends X>();

class A {}

class B extends A {}

class C extends B {}

void foo(H<A> ha, H<B> hb, H<C> hc) {
  H<A> haa = ha;
  H<A> hab = hb;
  //         ^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'void Function<Y extends B>()' can't be assigned to a variable of type 'void Function<Y extends A>()'.
  H<A> hac = hc;
  //         ^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'void Function<Y extends C>()' can't be assigned to a variable of type 'void Function<Y extends A>()'.

  H<B> hba = ha;
  //         ^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'void Function<Y extends A>()' can't be assigned to a variable of type 'void Function<Y extends B>()'.
  H<B> hbb = hb;
  H<B> hbc = hc;
  //         ^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'void Function<Y extends C>()' can't be assigned to a variable of type 'void Function<Y extends B>()'.

  H<C> hca = ha;
  //         ^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'void Function<Y extends A>()' can't be assigned to a variable of type 'void Function<Y extends C>()'.
  H<C> hcb = hb;
  //         ^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'void Function<Y extends B>()' can't be assigned to a variable of type 'void Function<Y extends C>()'.
  H<C> hcc = hc;
}

main() {}
