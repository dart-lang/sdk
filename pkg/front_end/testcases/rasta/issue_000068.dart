// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import "package:expect/expect.dart";

class G<T> {}

class A {}

class B extends A {}

class C extends B {}

main() {
  Expect.isFalse(new G<B>() is G<C>);
  Expect.isFalse(new G<A>() is G<B>);
  Expect.isFalse(new G<A>() is G<C>);
  Expect.isFalse(new G<Object>() is G<B>);
  Expect.isFalse(new G<int>() is G<B>);
  Expect.isFalse(new G<int>() is G<double>);
  Expect.isFalse(new G<int>() is G<String>);
}
