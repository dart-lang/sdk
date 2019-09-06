// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/

class A {
  dynamic field1;
  int field2;
}

class I {
  int field1;
  dynamic field2;
}

class B extends A implements I {
  get field1 => null;
  get field2 => null;
  set field1(value) {}
  set field2(value) {}
}

main() {}
