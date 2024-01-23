// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  foo1(null);
  foo2(null);
  foo3(null);
}

foo1(x) {
  /*dynamic*/ x as double;
  return (/*double*/ x as dynamic). /*invoke: [dynamic]->dynamic*/ asInt();
}

foo2(x) {
  for (var i in [1, 2, 3]) {
    /*dynamic*/ x as double;
    return (/*double*/ x as dynamic). /*invoke: [dynamic]->dynamic*/ asInt();
  }
  return /*dynamic*/ x;
}

foo3(x) {
  1 /*invoke: [int]->bool*/ >= /*dynamic*/ x;
  return /*dynamic*/ x /*invoke: [dynamic]->dynamic*/ - 2;
}
