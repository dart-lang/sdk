// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/63621.

// VMOptions=--deterministic

import 'dart:typed_data';

const int n = 8;

// Index of the largest of `v`, via a running-max Float32x4 select; read from lane x.
int simdArgmax(List<double> v) {
  var bestVal = Float32x4.splat(-1e30);
  var bestIdx = Float32x4.zero();
  for (int i = 0; i < n; i++) {
    final cur = Float32x4.splat(v[i]);
    final mask = cur.greaterThan(bestVal); // Int32x4 mask
    bestVal = mask.select(cur, bestVal); // running max: correct
    bestIdx = mask.select(
      Float32x4.splat(i.toDouble()),
      bestIdx,
    ); // index: miscompiled
  }
  return bestIdx.x.toInt();
}

int scalarArgmax(List<double> v) {
  var b = 0;
  for (int i = 1; i < n; i++) if (v[i] > v[b]) b = i;
  return b;
}

void main() {
  var seed = 12345;
  double next() {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed / 0x7fffffff * 100.0;
  }

  final v = List<double>.filled(n, 0);
  for (int iter = 0; iter < 5000; iter++) {
    for (int i = 0; i < n; i++) v[i] = next();
    final got = simdArgmax(v), want = scalarArgmax(v);
    if (got != want) {
      throw 'DIVERGED at iter $iter: simd=$got scalar=$want  v=$v';
    }
  }
}
