// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool inConstructor = false;

class A {
  A._() {
    inConstructor = true;
  }
}

class B extends A {
  B() : super._();
}

main() {
  new B();
  if (!inConstructor) throw 'Test failed';
}
