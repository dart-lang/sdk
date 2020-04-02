// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Bad {
  int foo = 0;
  final int bar =

      -1;
  static const int toto =

      -3;
}

void use(x) {}

main() {
  use(new Bad().bar);
  use(Bad.toto);
}
