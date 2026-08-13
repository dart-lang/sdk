// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--disable-dart-dev --no-inline-alloc --use-slow-path --deoptimize-on-runtime-call-every=1 --deterministic --optimization-counter-threshold=1 --deoptimize-on-runtime-call-name-filter=CloneContext

main() {
  for (int i = 0; i < 20; ++i) {
    if (foo(1)[1]() != 2) throw 'a';
  }
}

@pragma('vm:never-inline')
List foo(int a) {
  final l = <int Function()>[];
  for (int i = 0; i < 10; ++i) {
    l.add(() => a + i);
  }
  return l;
}
