// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for F-Bounded Quantification.

import "package:expect/expect.dart";

class A<T extends B<T>> {}

class B<T extends B<T>> extends A<T> {}

class Foo<T extends B<T>> extends B<Foo<T>> {}

main() {
  Expect.equals("Foo<Foo<B<dynamic>>>", new Foo<Foo>().runtimeType.toString());
}
