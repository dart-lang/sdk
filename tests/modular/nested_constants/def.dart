// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class B {
  const B();
}

class A {
  final B b;
  const A(this.b);
}

const ab = A(B());
const b = B();
