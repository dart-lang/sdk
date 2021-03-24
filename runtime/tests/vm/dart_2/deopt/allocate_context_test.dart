// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--disable-dart-dev --no-inline-alloc --use-slow-path --deoptimize-on-runtime-call-every=1 --deterministic --optimization-counter-threshold=1 --deoptimize-on-runtime-call-name-filter=AllocateContext

main() {
  for (int i = 0; i < 20; ++i) {
    final fun = foo(1);
    if (fun(1) != 3) throw 'a';
    if (fun(2) != 6) throw 'b';
  }
}

@pragma('vm:never-inline')
int Function(int) foo(int a) {
  int b = 1;
  return (int c) {
    return a++ + b++ + c;
  };
}
