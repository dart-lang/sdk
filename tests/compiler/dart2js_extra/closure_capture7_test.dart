// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {
  List<List> xs;

  void foo() {
    // the inner closure only needs to capture 'this' if
    // `A` needs runtime type information.
    xs.map((x) => x.map((a) => a as T));
  }
}

main() {
  var a = new A<int>();
  a.xs = [
    [1, 2, 3],
    [4, 5, 6]
  ];
  // just check that this doesn't crash
  a.foo();
}
