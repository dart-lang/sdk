// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

//------------------------------------------------------------------------------

class A {
  dynamic operator +(covariant int a) => null;
}

class B {
  dynamic operator +(dynamic b) => null;
}

abstract class C implements A, B {}

//------------------------------------------------------------------------------

class D {
  dynamic operator +(dynamic d) => null;
}

class E extends D {
  dynamic operator +(covariant int e);
}

//------------------------------------------------------------------------------

main() {}
