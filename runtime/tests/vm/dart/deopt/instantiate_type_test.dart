// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--disable-dart-dev --deoptimize-on-runtime-call-every=1 --deterministic --optimization-counter-threshold=1 --deoptimize-on-runtime-call-name-filter=InstantiateType

main() {
  final a = A<int>();
  for (int i = 0; i < 20; ++i) {
    final l = a.foo<double>();
    if (l[0] != int) throw 'a';
    if (l[1] != double) throw 'a';
  }
}

class A<T> {
  @pragma('vm:never-inline')
  List<Type> foo<H>() {
    final l = <Type>[];
    for (int i = 0; i < 10; ++i) {
      l.add(T);
      l.add(H);
    }
    return l;
  }
}
