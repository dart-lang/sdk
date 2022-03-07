// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X extends int> {}

foo(A<num> x) {
  bar(A<num> y) {
    barbar(A<num> yy) => null;
  }
  var baz = (A<num> z) {
    var bazbaz = (A<num> zz) => null;
  };
}

main() {}
