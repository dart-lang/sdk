// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that an inlined field closure has access to the enclosing
// type variables.

import "package:expect/expect.dart";

class A<T> {
  var c = (() => new X<T>())();
}

class B<T> extends A<T> {}

class X<T> {}

main() {
  Expect.isTrue(new B<int>().c is X<int>);
  Expect.isFalse(new B<String>().c is X<int>);
}
