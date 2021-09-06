// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic --deoptimize-on-runtime-call-every=3 --optimization-counter-threshold=10

main() {
  final l = <int>[1, 2, 3, 4, 5];
  for (int i = 0; i < 1000; ++i) {
    if (sumIt(l) != 15) throw 'failed';
  }
}

@pragma('vm:never-inline')
int sumIt(dynamic arg) {
  int sum = 0;
  for (int i = 0; i < 5; ++i) {
    final l = arg as List<int>;
    sum += l[i];
  }
  return sum;
}
