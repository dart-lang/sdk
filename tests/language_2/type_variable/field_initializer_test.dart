// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that an inlined field initializer has access to the enclosing
// type variables.

import "package:expect/expect.dart";

class A<T> {
  var c = new List<T>();
}

class B<T> extends A<T> {}

main() {
  Expect.isTrue(new B<int>().c is List<int>);
  Expect.isFalse(new B<String>().c is List<int>);
}
