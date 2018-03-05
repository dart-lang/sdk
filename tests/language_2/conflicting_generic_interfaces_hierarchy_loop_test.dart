// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test arithmetic operations.

// There is no interface conflict here, but there is a loop in the class
// hierarchy leading to a finite set of implemented types; this loop
// shouldn't cause non-termination.
/*@compile-error=unspecified*/ class A<T> implements B<T> {}

/*@compile-error=unspecified*/ class B<T> implements A<T> {}

main() {
  new A();
  new B();
}
