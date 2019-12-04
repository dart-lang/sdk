// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that an attempt to assign to a class, enum, typedef, or type
// parameter produces a compile error.

class C<T> {
  f() {

  }
}

class D {}

enum E { e0 }

typedef void F();

main() {
  new C<D>().f();



}
