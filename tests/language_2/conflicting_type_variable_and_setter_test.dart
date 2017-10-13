// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class C<D> {
  void set D(int value) {
    field = value;
  }

  int field;
}

main() {
  C<int> c = new C<int>();
  c.D = 1;
  Expect.equals(c.field, 1);
}
