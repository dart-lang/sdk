// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that function type parameter S can be resolved in bar's result type.
// Verify that generic function types are not allowed as type arguments.

import "package:expect/expect.dart";

int foo

          (int i, int j) => i + j;

List<int Function

                    (S, int)> bar<S extends int>() {
  return <int Function

                         (S, int)>[foo, foo];
}

void main() {
  var list = bar<int>();
  print(list[0].runtimeType);
  Expect.equals(123, list[1](100, 23));
}
