// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A<T> {
  factory A.factory() {
    return new B<T>();
  }

  A();

  build() {
    return new A<T>();
  }
}

class B<T> extends A<T> {
  B();

  build() {
    return new B<T>();
  }
}

main() {
  Expect.isTrue(new A<List>() is A<List>);
  Expect.isTrue(new A<List>.factory() is B<List>);

  // Check that we don't always return true for is checks with
  // generics.
  Expect.isFalse(new A<List>() is A<Set>);
  Expect.isFalse(new A<List>.factory() is B<Set>);

  Expect.isTrue(new A<List>().build() is A<List>);
  Expect.isFalse(new A<List>().build() is A<Set>);

  Expect.isTrue(new A<List>.factory().build() is B<List>);
  Expect.isFalse(new A<List>.factory().build() is B<Set>);

  Expect.isTrue(new B<List>().build() is B<List>);
  Expect.isFalse(new B<List>().build() is B<Set>);
}
