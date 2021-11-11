// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the support for type parameters as potentially constant expressions
// and potentially constant type expressions. The cast to dynamic is included
// in order to avoid a diagnostic message about an unnecessary cast.

class A<X> {
  final Type t1, t2;
  final Object x1, x2;

  const A()
      : t1 = X,
        t2 = List<X>,
        x1 = 1 is X,
        x2 = (const <Never>[] as dynamic) as List<X>;
}

void main() {
  const A<int>();
}
