// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class B {}

class A {
  B get _typeArguments => B();
}

void main() {
  print(A()._typeArguments);
}
