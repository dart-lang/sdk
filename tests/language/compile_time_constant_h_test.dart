// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A implements B {
  final x;
  const A(this.x);
}

abstract class B {
  const factory B(x) = A;
}

const b1 = const B(499);

main() {
  Expect.equals(499, b1.x);
}
