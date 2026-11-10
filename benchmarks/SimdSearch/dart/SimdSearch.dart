// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Search benchmarks over Int32x4 lanes, across data sizes. Compares three
// approaches:
//   scalar - a plain linear scan of an Int32List.
//   view   - a SIMD scan that views the Int32List as an Int32x4List per call.
//   direct - a SIMD scan of a list that is already an Int32x4List.
// The `view` variant allocates an Int32x4List view on every call, which is
// invisible on large arrays but dominates on tiny ones; `direct` avoids it.
//
// TODO: `direct` is a workaround to measure SIMD search throughput without the
// per-call `Int32x4List.view` allocation overhead. Remove it once the `view`
// variant is as fast as `direct`.

import 'dart:math';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';

const _sizes = <String, int>{
  '32B': 1 << 3,
  '64B': 1 << 4,
  '256B': 1 << 6,
  '1KiB': 1 << 8,
  '4KiB': 1 << 10,
  '64KiB': 1 << 14,
  '1MiB': 1 << 18,
  '16MiB': 1 << 22,
};

const int _seed = 0x5f3759df;

Int32List _randomData(int size) {
  final rng = Random(_seed);
  final data = Int32List(size);
  for (var i = 0; i < size; i++) {
    data[i] = rng.nextInt(size);
  }
  return data;
}

abstract class _SearchBenchmark extends BenchmarkBase {
  final int size;
  int sink = 0;

  _SearchBenchmark(String variant, this.size)
    : super('SimdSearch.Int32x4.$variant');
}

class _ScalarSearch extends _SearchBenchmark {
  late Int32List data;

  _ScalarSearch(String name, int size) : super(name, size);

  @override
  void setup() {
    data = _randomData(size);
  }

  @override
  void run() {
    // Values are in [0, size), so `size` is absent: every run is a full scan.
    sink ^= _indexOf(data, size);
  }

  static int _indexOf(Int32List data, int needle) {
    for (var i = 0; i < data.length; i++) {
      if (data[i] == needle) return i;
    }
    return -1;
  }
}

class _ViewSearch extends _SearchBenchmark {
  late Int32List data;

  _ViewSearch(String name, int size) : super(name, size);

  @override
  void setup() {
    data = _randomData(size);
  }

  @override
  void run() {
    sink ^= _indexOf(data, size);
  }

  // Views the Int32List as an Int32x4List on every call (per-call allocation).
  static int _indexOf(Int32List data, int needle) {
    // The SIMD scan covers whole lanes only, so a tail shorter than a lane is
    // rejected rather than silently skipped.
    if (data.length % 4 != 0) {
      throw ArgumentError('data.length must be a multiple of 4');
    }
    final view = Int32x4List.view(
      data.buffer,
      data.offsetInBytes,
      data.length >> 2,
    );
    final needles = Int32x4(needle, needle, needle, needle);
    for (var i = 0; i < view.length; i++) {
      final mask = view[i].equal(needles);
      if (mask.anyTrue) {
        final base = i << 2;
        if (mask.flagX) return base;
        if (mask.flagY) return base + 1;
        if (mask.flagZ) return base + 2;
        return base + 3;
      }
    }
    return -1;
  }
}

class _DirectSearch extends _SearchBenchmark {
  late Int32x4List data;

  _DirectSearch(String name, int size) : super(name, size);

  @override
  void setup() {
    final i32 = _randomData(size);
    // Built once, so `direct` pays no per-call allocation.
    data = Int32x4List.view(i32.buffer, 0, size >> 2);
  }

  @override
  void run() {
    sink ^= _indexOf(data, size);
  }

  // Searches a list that is already an Int32x4List (no per-call view).
  static int _indexOf(Int32x4List data, int needle) {
    final needles = Int32x4(needle, needle, needle, needle);
    for (var i = 0; i < data.length; i++) {
      final mask = data[i].equal(needles);
      if (mask.anyTrue) {
        final base = i << 2;
        if (mask.flagX) return base;
        if (mask.flagY) return base + 1;
        if (mask.flagZ) return base + 2;
        return base + 3;
      }
    }
    return -1;
  }
}

void main() {
  for (final entry in _sizes.entries) {
    final size = entry.value;
    _ScalarSearch('${entry.key}.scalar', size).report();
    _ViewSearch('${entry.key}.view', size).report();
    _DirectSearch('${entry.key}.direct', size).report();
  }
}
