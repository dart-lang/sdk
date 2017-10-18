// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// When an instantiation of an abstract class has the wrong arguments, an
// AbstractClassInstantiationError is thrown, not a NoSuchMethodError.

abstract class A {
  A() {}
}

class B {
  B() {}
}

bool isAbstractClassInstantiationError(e) =>
    e is AbstractClassInstantiationError;

bool isNoSuchMethodError(e) => e is NoSuchMethodError;

void main() {
  Expect.throws(() => new A(), isAbstractClassInstantiationError);

  Expect.throws(() => new B(1), isNoSuchMethodError);
  Expect.throws(() => new A(1), isAbstractClassInstantiationError);
}
