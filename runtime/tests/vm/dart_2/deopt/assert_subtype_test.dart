// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// VMOptions=--disable-dart-dev --deoptimize-on-runtime-call-every=1 --deterministic --optimization-counter-threshold=1 --deoptimize-on-runtime-call-name-filter=SubtypeCheck

main() {
  for (int i = 0; i < 20; ++i) {
    if (foo()<int>() != 42) throw 'a';
    if (foo()<double>() != 42) throw 'a';
  }
}

@pragma('vm:never-inline')
dynamic foo() {
  int bar<T extends num>() => 42;
  return bar;
}
