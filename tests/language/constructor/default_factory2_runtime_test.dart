// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check type bounds when invoking a redirecting factory method

abstract class Foo {}

abstract class IA<T> {

}

class A<T extends Foo> implements IA<T> {
  factory A() { return A._(); }

  A._();
}

main() {

}
