// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A implements B {
  final x = 4;
  const A(this.x);
}

interface B default A {
  const B(x);
}

final b1 = const B(499);

main() {
  Expect.equals(499, b1.x);
}
