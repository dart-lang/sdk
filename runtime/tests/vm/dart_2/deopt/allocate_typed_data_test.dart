// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// VMOptions=--disable-dart-dev --no-inline-alloc --use-slow-path --deoptimize-on-runtime-call-every=1 --deterministic --optimization-counter-threshold=1 --deoptimize-on-runtime-call-name-filter=AllocateTypedData

import 'dart:typed_data';

main() {
  for (int i = 0; i < 20; ++i) {
    final foo = bar(1);
    if (foo[0] != 42) throw 'a';
  }
}

@pragma('vm:never-inline')
Uint32List bar(int a) {
  return Uint32List(1)..[0] = 42;
}
