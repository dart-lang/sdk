// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test arithmetic operations.

// @dart = 2.9

class I<T> {}

class A implements I<int> {}

class B implements I<String> {}

class C extends A implements B {}
//    ^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_GENERIC_INTERFACES
// [cfe] 'C' can't implement both 'I<int>' and 'I<String>'

main() {
  new C();
}
