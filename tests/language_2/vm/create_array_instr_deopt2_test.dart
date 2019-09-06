// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

foo(n) {
  return new List(n);
}

@pragma('vm:never-inline')
bar(n) {
  try {
    return foo(n);
  } catch (e) {}
}

main() {
  for (var i = 0; i < 20; i++) {
    bar(5);
  }
  bar("");
}
