// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class B<T> extends C<T> {
  B();
  factory B.foo() = B<T>;
  factory B.foo() = B<T>;
//        ^^^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_CONSTRUCTOR
//        ^
// [cfe] 'B.foo' is already declared in this scope.
}

class C<K> {
  C();
  factory C.bar() = B<K>.foo;
  //                ^
  // [cfe] Can't use 'B.foo' because it is declared more than once.
}

main() {
  new C.bar();
}
