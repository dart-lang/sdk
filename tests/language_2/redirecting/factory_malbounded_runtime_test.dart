// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo<T> {
  factory Foo() = Bar<T>;
  Foo.create() {}
}

class Bar<
    T

    > extends Foo<T> {
  factory Bar() {
    return new Bar<T>.create();
  }

  Bar.create() : super.create() {}
}

main() {
  new Foo<String>();
}
