// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B {}

class C extends A implements B {}

class Base<T> {}

class Sub implements Base<C> {}

void main() {
  Expect.subtype<Sub, Base<A>>();
  Expect.subtype<Sub, Base<B>>();
}
