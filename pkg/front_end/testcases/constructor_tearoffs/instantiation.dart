// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X extends num> {
  A.foo(X x) {}
  A(X x) {}
}

A<num> Function(num) test1() => A.foo; // Ok.
A<int> Function(int) test2() => A.foo; // Ok.
A<num> Function(num) test3() => A.new; // Ok.
A<int> Function(int) test4() => A.new; // Ok.

A<dynamic> Function(String) test5() => A.foo; // Error.
A<dynamic> Function(String) test6() => A.new; // Error.
A<dynamic> Function(num) test7() => A<num>.foo; // Error.
A<dynamic> Function(num) test8() => A<num>.new; // Error.

main() {}
