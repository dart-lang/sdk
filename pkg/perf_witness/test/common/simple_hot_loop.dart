// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int hotLoop({Duration duration = const Duration(seconds: 30)}) {
  int sum = 0;
  final sw = Stopwatch()..start();
  while (sw.elapsed < duration) {
    final l = <int>[];
    for (var i = 0; i < 10000; i++) {
      l.add(i * i);
    }
    sum += l[50];
  }
  return sum;
}

void main() {
  print(hotLoop());
}
