// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X extends num> {
  A.foo(X x) {}
}

A<num> Function(num) bar1() => A.foo; // Ok.
A<int> Function(int) bar2() => A.foo; // Ok.
A<dynamic> Function(String) bar3() => A.foo; // Error.

main() {}
