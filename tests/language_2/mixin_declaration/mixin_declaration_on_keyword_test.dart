// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// The `on` word is not a reserved word or built-in identifier.
// It's a purely contextual keyword.
// A type can have the name `on`, and even a mixin.

class A {}

mixin on on A {}

mixin M on on {}

mixin M2 implements on {}

class B = A with on;
class C = B with M;
class D = Object with M2;

main() {
  Expect.type<on>(B());
  Expect.type<on>(C());
  Expect.type<on>(D());
}