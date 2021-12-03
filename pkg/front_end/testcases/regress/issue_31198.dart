// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart=2.9
abstract class A {}

class B extends A {
  B(): super().foo() {}
  B.named1(): super().super() {}
  B.named2(): super().() {}
}

bad() {
  new B();
}

main() {}
