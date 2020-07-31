// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that you cannot instantiate a type variable.

class Foo<T> {
  Foo() {}
  dynamic make() {

  }
}

main() {
  new Foo<Object>().make();
}
