// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for F-Bounded Quantification.

class FBound1<F1 extends FBound1<F1, F2>, F2 extends FBound2<F1, F2>> {
  Test() {
    new FBound1<F1, F2>();
    new FBound2<F1, F2>();
  }
}

class FBound2<F1 extends FBound1<F1, F2>, F2 extends FBound2<F1, F2>> {
  Test() {
    new FBound1<F1, F2>();
    new FBound2<F1, F2>();
  }
}

class Bar extends FBound1<Bar, Baz> {}

class Baz extends FBound2<Bar, Baz> {}

main() {
  new FBound1<Bar, Baz>().Test();
  new FBound2<Bar, Baz>().Test();
}
