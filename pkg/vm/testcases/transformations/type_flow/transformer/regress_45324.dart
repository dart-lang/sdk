// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  final int targetPlatform;
  const A(this.targetPlatform);

  static const BAR = A(1);
}

class X implements A {
  int get targetPlatform => 2;
}

A a = X();

void main() {
  print(a.targetPlatform);
  print(A.BAR);
}
