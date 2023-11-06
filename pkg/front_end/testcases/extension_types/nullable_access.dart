// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

extension E on ET? {
  void foo(int i) {}
}

extension type ET(int? i) {
  void foo() {}
}

method<X extends ET, Y extends ET?>(ET et1, ET? et2, X x1, X? x2, Y y1, Y? y2) {
  et1.foo();
  et2.foo(0);
  x1.foo();
  x2.foo(0);
  y1.foo(0);
  y2.foo(0);
}