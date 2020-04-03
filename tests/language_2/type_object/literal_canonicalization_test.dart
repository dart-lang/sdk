// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Foo {}

class Box<T> {
  Type get typeArg => T;
}

/// A typedef that defines a non-generic function type.
typedef int Func1(bool b);

/// Semantically identical to [Func], but using the Dart 2 syntax.
typedef Func2 = int Function(bool);

main() {
  // Literals are canonicalized.
  Expect.identical(Foo, Foo);
  Expect.identical(Box, Box);
  Expect.identical(new Box<Foo>().typeArg, new Box<Foo>().typeArg);
  Expect.identical(Func1, Func1);
  Expect.identical(Func2, Func2);
}
