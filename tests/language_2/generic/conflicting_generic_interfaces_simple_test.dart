// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test arithmetic operations.

class I<T> {}

class A implements I<int> {}

class B implements I<String> {}

/*@compile-error=unspecified*/ class C extends A implements B {}

main() {
  new C();
}
