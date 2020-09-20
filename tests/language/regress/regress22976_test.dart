// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 22976.

class A<T> {}

class B<T> implements A<T> {}

class C<S, T> implements B<S>, A<T> {}
// [error line 11, column 1, length 38]
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_GENERIC_INTERFACES
//    ^
// [cfe] 'C' can't implement both 'A<S>' and 'A<T>'

main() {
  C<int, String> c1 = new C<int, String>();
  C<String, int> c2 = new C<String, int>();
  A<int> a0 = c1;
  A<int> a1 = c2;
  //          ^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //          ^
  // [cfe] A value of type 'C<String, int>' can't be assigned to a variable of type 'A<int>'.
}
