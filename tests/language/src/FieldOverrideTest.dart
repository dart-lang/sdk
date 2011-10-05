// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test overriding of fields.

interface A {}
interface B1 extends A {}
interface B2 extends A {}

class Super {
  Super() : super();

  B1 field;
}

class Sub extends Super {
  Sub() : super();

  A field;
}

class SubSub extends Super {
  SubSub() : super();

  B2 field; /// 01: static type error
}

main() {
  new SubSub();
}
