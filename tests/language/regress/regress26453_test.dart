// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The program crashed with segfault because we when we first compile foo
// and bar we allocate all four variables (a, b, c and d) to the context.
// When we compile foo the second time (with optimizations) we allocate
// only c and d to the context. This happened because parser folds away
// "${a}" and "${b}" as constant expressions when parsing bar on its own,
// i.e. the expressions were not parsed again and thus a and b were not
// marked as captured.
// This caused a mismatch between a context that bar expects and that
// the optimized version of foo produces.

foo() {
  const a = 1;
  const b = 2;
  var c = 3;
  var d = 4;

  bar() {
    if ("${a}" != "1") throw "failed";
    if ("${b}" != "2") throw "failed";
    if ("${c}" != "3") throw "failed";
    if ("${d}" != "4") throw "failed";
  }

  bar();
}

main() {
  for (var i = 0; i < 50000; i++) foo();
}
