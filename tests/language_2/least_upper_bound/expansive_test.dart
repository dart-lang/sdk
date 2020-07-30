// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test least upper bound through type checking of conditionals.

class N<T> {
  T get n => null;
}

class C1<T> extends N<N<C1<T>>> {
  T get c1 => null;
}

class C2<T> extends N<N<C2<N<C2<T>>>>> {
  T get c2 => null;
}

/**
 * Test that we don't try to find the least upper bound by applying the
 * algorithm for finding the most specific common declaration recursively on
 * type arguments.
 *
 * For C1<int> and N<C1<String>> this would result in this infinite chain of
 * computations:
 *
 * lub(C1<int>, N<C1<String>>) = lub(N<N<C1<int>>>, N<C1<String>>)
 * =>
 * lub(N<C1<int>>, C1<String>) = lub(N<C1<int>>, N<N<C1<String>>>)
 * =>
 * lub(C1<int>, N<C1<String>>) = lub(N<N<C1<int>>>, N<C1<String>>>)
 * => ...
 */
void testC1(bool z, C1<int> a, N<C1<String>> b) {
  if (z) {
    // The least upper bound of C1<int> and N<C1<String>> is Object since the
    // supertypes are
    //     {C1<int>, N<N<C1<int>>>, Object} for C1<int> and
    //     {N<C1<String>>, Object} for N<C1<String>> and
    // Object is the most specific type in the intersection of the supertypes.

    // Is least upper bound dynamic?
    (z ? a : b).z;
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'z' isn't defined for the class 'Object'.

    // Is least upper bound N<...> ?
    (z ? a : b).n;
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'n' isn't defined for the class 'Object'.

    // Is least upper bound C1<...> ?
    (z ? a : b).c1;
    //          ^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'c1' isn't defined for the class 'Object'.

    // Is least upper bound N<dynamic> ?
    (z ? a : b).n.z;
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'n' isn't defined for the class 'Object'.

    // Is least upper bound N<N<...>> ?
    (z ? a : b).n.n;
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'n' isn't defined for the class 'Object'.

    // Is least upper bound N<C1<...>> ?
    (z ? a : b).n.c1;
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'n' isn't defined for the class 'Object'.
  }
}

/**
 * Test that we don't try to find the least upper bound by applying the
 * algorithm for finding the most specific common declaration recursively on
 * type arguments.
 *
 * For C1<int> and N<C1<String>> this would result in this infinite and
 * expanding chain of computations:
 *
 * lub(C2<int>, N<C2<String>>) = lub(N<N<C2<N<C2<int>>>>>, N<C2<String>>)
 * =>
 * lub(N<C2<N<C2<int>>>>, C2<String>) =
 *                               lub(N<C2<N<C2<int>>>>, N<N<C2<N<C2<String>>>>>)
 * =>
 * lub(C2<N<C2<int>>>, N<C2<N<C2<String>>>>) =
 *                              lub(N<N<C2<N<C2<int>>>>>, N<C2<N<C2<String>>>>>)
 * => ...
 */

void testC2(bool z, C2<int> a, N<C2<String>> b) {
  if (z) {
    // The least upper bound of C2<int> and N<C2<String>> is Object since the
    // supertypes are
    //     {C2<int>, N<N<C2<N<C2<int>>>>>, Object} for C1<int> and
    //     {N<C2<String>>, Object} for N<C1<String>> and
    // Object is the most specific type in the intersection of the supertypes.

    // Is least upper bound dynamic?
    (z ? a : b).z;
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'z' isn't defined for the class 'Object'.

    // Is least upper bound N<...> ?
    (z ? a : b).n;
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'n' isn't defined for the class 'Object'.

    // Is least upper bound C2<...> ?
    (z ? a : b).c2;
    //          ^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'c2' isn't defined for the class 'Object'.

    // Is least upper bound N<dynamic> ?
    (z ? a : b).n.z;
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'n' isn't defined for the class 'Object'.

    // Is least upper bound N<N<...>> ?
    (z ? a : b).n.n;
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'n' isn't defined for the class 'Object'.

    // Is least upper bound N<C2<...>> ?
    (z ? a : b).n.c2;
    //          ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'n' isn't defined for the class 'Object'.
  }
}

void main() {
  testC1(false, null, null);
  testC2(false, null, null);
}
