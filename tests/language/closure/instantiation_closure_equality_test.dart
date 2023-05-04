// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  int x = 0;
  List<void Function<D>()> f = [];
  for (int i = 0; i < 2; i++) {
    f.add(<E>() {
      x++;
    });
  }
  // We may allocate a new function in each iteration, or move the function to
  // the outside of the loop. In any case, equality of the instantiations
  // should agree with the equality of the instantiated functions.
  Expect.equals(f[0] == f[1], f[0]<int> == f[1]<int>);
}
