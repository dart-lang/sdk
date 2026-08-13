// Copyright (c) 2020, the Dart Team. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in
// the LICENSE file.

// Regression test for: https://github.com/dart-lang/sdk/issues/42234

Iterable<Object> f() sync* {
  yield* g();
}

Iterable<int> g() sync* {
  yield 1;
  yield 2;
}

main() {
  for (var i in f()) {
    print(i);
  }
}
