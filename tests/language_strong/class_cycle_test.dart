// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check fail because of cycles in super class relationship.

import "package:expect/expect.dart";

class Foo implements Bar {}

class C {}

class Bar
    extends Foo // //# 00: compile-time error
    implements Foo // //# 01: compile-time error
{}

class ImplementsC implements C
, C // //# 02: compile-time error
{}

// Spec says: It is a compile-time error if the superclass
// of a class C appears in the implements clause of C.
class ExtendsC extends C
implements C // //# 03: compile-time error
{}

main() {
  Expect.isTrue(new Foo() is Foo);
  Expect.isTrue(new ImplementsC() is C);
  Expect.isTrue(new ExtendsC() is C);
}
