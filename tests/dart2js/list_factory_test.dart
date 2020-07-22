// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  var a = List.filled(4, 0);
  Expect.equals(4, a.length);
  a[0] = 42;
  a[1] = 43;
  a[2] = 44;
  a[3] = 45;
  for (int i = 0; i < a.length; i++) {
    Expect.equals(42 + i, a[i]);
  }

  a = List.empty(growable: true);
  a.add(42);
  a.add(43);
  a.add(44);
  a.add(45);
  Expect.equals(4, a.length);
  for (int i = 0; i < a.length; i++) {
    Expect.equals(42 + i, a[i]);
  }
}
