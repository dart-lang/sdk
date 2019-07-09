// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the bug reported at http://dartbug.com/37381 is fixed.

class A<X> {
  R f<R>(R Function<X>(A<X>) f) => f<X>(this);
}

main() {
  A<num> a = A<int>();
  a.f(<X>(_) => 42);
}
