// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Benchmarks for int.trailingZeroBitCount, int.oneBitCount and int.bitLength,
// exercised through a small bit-array implementation.

import 'dart:math';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';

// 32-bit storage words so the benchmark runs on both native (64-bit int)
// and web (32-bit bitwise) without platform-specific word arithmetic.
const int _wordBits = 32;
const int _wordMask = _wordBits - 1;
const int _wordShift = 5;

class BitArray32 {
  final Uint32List _words;
  final int length;

  BitArray32(this.length)
    : _words = Uint32List((length + _wordBits - 1) >> _wordShift);

  Uint32List get words => _words;

  void setBit(int i) {
    _words[i >> _wordShift] |= 1 << (i & _wordMask);
  }

  int cardinality() {
    var total = 0;
    for (var i = 0; i < _words.length; i++) {
      total += _words[i].oneBitCount;
    }
    return total;
  }

  void forEachSetBit(void Function(int) action) {
    for (var wordIdx = 0; wordIdx < _words.length; wordIdx++) {
      var w = _words[wordIdx];
      final base = wordIdx << _wordShift;
      while (w != 0) {
        final bit = w.trailingZeroBitCount;
        final pos = base + bit;
        if (pos >= length) return;
        action(pos);
        // https://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetKernighan
        w &= w - 1;
      }
    }
  }

  int select(int k) {
    var remaining = k;
    for (var wordIdx = 0; wordIdx < _words.length; wordIdx++) {
      final w = _words[wordIdx];
      final pop = w.oneBitCount;
      if (remaining < pop) {
        var v = w;
        while (remaining > 0) {
          // https://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetKernighan
          v &= v - 1;
          remaining--;
        }
        return (wordIdx << _wordShift) + v.trailingZeroBitCount;
      }
      remaining -= pop;
    }
    return -1;
  }

  // A synthetic operation that exercises int.bitLength once per word, the
  // way cardinality exercises int.oneBitCount once per word.
  int totalBitLength() {
    var total = 0;
    for (var i = 0; i < _words.length; i++) {
      total += _words[i].bitLength;
    }
    return total;
  }

  // Exercises int.~ once per word, immediately followed by oneBitCount.
  int complementCardinality() {
    var total = 0;
    for (var i = 0; i < _words.length; i++) {
      // Mask back to 32 bits because ~uint32 sign-extends in Dart's int.
      total += (~_words[i] & 0xFFFFFFFF).oneBitCount;
    }
    return total;
  }

  static void intersection(BitArray32 a, BitArray32 b, BitArray32 out) {
    final wa = a._words;
    final wb = b._words;
    final wo = out._words;
    if (wa.length != wb.length || wa.length != wo.length) {
      throw ArgumentError('a, b, and out must have the same length');
    }
    final n = wa.length;
    for (var i = 0; i < n; i++) {
      wo[i] = wa[i] & wb[i];
    }
  }

  static void intersectionAccelerated(
    BitArray32 a,
    BitArray32 b,
    BitArray32 out,
  ) {
    final wa = a._words;
    final wb = b._words;
    final wo = out._words;
    if (wa.length != wb.length || wa.length != wo.length) {
      throw ArgumentError('a, b, and out must have the same length');
    }
    final n = wa.length;
    final simdWords = n >> 2;
    final va = Int32x4List.view(wa.buffer, wa.offsetInBytes, simdWords);
    final vb = Int32x4List.view(wb.buffer, wb.offsetInBytes, simdWords);
    final vo = Int32x4List.view(wo.buffer, wo.offsetInBytes, simdWords);
    for (var i = 0; i < simdWords; i++) {
      vo[i] = va[i] & vb[i];
    }
    for (var i = simdWords << 2; i < n; i++) {
      wo[i] = wa[i] & wb[i];
    }
  }

  static void union(BitArray32 a, BitArray32 b, BitArray32 out) {
    final wa = a._words;
    final wb = b._words;
    final wo = out._words;
    if (wa.length != wb.length || wa.length != wo.length) {
      throw ArgumentError('a, b, and out must have the same length');
    }
    final n = wa.length;
    for (var i = 0; i < n; i++) {
      wo[i] = wa[i] | wb[i];
    }
  }

  static void unionAccelerated(BitArray32 a, BitArray32 b, BitArray32 out) {
    final wa = a._words;
    final wb = b._words;
    final wo = out._words;
    if (wa.length != wb.length || wa.length != wo.length) {
      throw ArgumentError('a, b, and out must have the same length');
    }
    final n = wa.length;
    final simdWords = n >> 2;
    final va = Int32x4List.view(wa.buffer, wa.offsetInBytes, simdWords);
    final vb = Int32x4List.view(wb.buffer, wb.offsetInBytes, simdWords);
    final vo = Int32x4List.view(wo.buffer, wo.offsetInBytes, simdWords);
    for (var i = 0; i < simdWords; i++) {
      vo[i] = va[i] | vb[i];
    }
    for (var i = simdWords << 2; i < n; i++) {
      wo[i] = wa[i] | wb[i];
    }
  }

  static void xor(BitArray32 a, BitArray32 b, BitArray32 out) {
    final wa = a._words;
    final wb = b._words;
    final wo = out._words;
    if (wa.length != wb.length || wa.length != wo.length) {
      throw ArgumentError('a, b, and out must have the same length');
    }
    final n = wa.length;
    for (var i = 0; i < n; i++) {
      wo[i] = wa[i] ^ wb[i];
    }
  }

  static void xorAccelerated(BitArray32 a, BitArray32 b, BitArray32 out) {
    final wa = a._words;
    final wb = b._words;
    final wo = out._words;
    if (wa.length != wb.length || wa.length != wo.length) {
      throw ArgumentError('a, b, and out must have the same length');
    }
    final n = wa.length;
    final simdWords = n >> 2;
    final va = Int32x4List.view(wa.buffer, wa.offsetInBytes, simdWords);
    final vb = Int32x4List.view(wb.buffer, wb.offsetInBytes, simdWords);
    final vo = Int32x4List.view(wo.buffer, wo.offsetInBytes, simdWords);
    for (var i = 0; i < simdWords; i++) {
      vo[i] = va[i] ^ vb[i];
    }
    for (var i = simdWords << 2; i < n; i++) {
      wo[i] = wa[i] ^ wb[i];
    }
  }

  static void difference(BitArray32 a, BitArray32 b, BitArray32 out) {
    final wa = a._words;
    final wb = b._words;
    final wo = out._words;
    if (wa.length != wb.length || wa.length != wo.length) {
      throw ArgumentError('a, b, and out must have the same length');
    }
    final n = wa.length;
    for (var i = 0; i < n; i++) {
      wo[i] = wa[i] & (~wb[i] & 0xFFFFFFFF);
    }
  }

  static void differenceAccelerated(
    BitArray32 a,
    BitArray32 b,
    BitArray32 out,
  ) {
    final wa = a._words;
    final wb = b._words;
    final wo = out._words;
    if (wa.length != wb.length || wa.length != wo.length) {
      throw ArgumentError('a, b, and out must have the same length');
    }
    final n = wa.length;
    final simdWords = n >> 2;
    final va = Int32x4List.view(wa.buffer, wa.offsetInBytes, simdWords);
    final vb = Int32x4List.view(wb.buffer, wb.offsetInBytes, simdWords);
    final vo = Int32x4List.view(wo.buffer, wo.offsetInBytes, simdWords);
    final ones = Int32x4(-1, -1, -1, -1);
    for (var i = 0; i < simdWords; i++) {
      vo[i] = va[i] & (vb[i] ^ ones);
    }
    for (var i = simdWords << 2; i < n; i++) {
      wo[i] = wa[i] & (~wb[i] & 0xFFFFFFFF);
    }
  }

  static void complement(BitArray32 a, BitArray32 out) {
    final wa = a._words;
    final wo = out._words;
    if (wa.length != wo.length) {
      throw ArgumentError('a and out must have the same length');
    }
    final n = wa.length;
    for (var i = 0; i < n; i++) {
      wo[i] = ~wa[i] & 0xFFFFFFFF;
    }
  }

  static void complementAccelerated(BitArray32 a, BitArray32 out) {
    final wa = a._words;
    final wo = out._words;
    if (wa.length != wo.length) {
      throw ArgumentError('a and out must have the same length');
    }
    final n = wa.length;
    final simdWords = n >> 2;
    final va = Int32x4List.view(wa.buffer, wa.offsetInBytes, simdWords);
    final vo = Int32x4List.view(wo.buffer, wo.offsetInBytes, simdWords);
    final ones = Int32x4(-1, -1, -1, -1);
    for (var i = 0; i < simdWords; i++) {
      vo[i] = va[i] ^ ones;
    }
    for (var i = simdWords << 2; i < n; i++) {
      wo[i] = ~wa[i] & 0xFFFFFFFF;
    }
  }

  bool wordsEqual(BitArray32 other) {
    if (_words.length != other._words.length) return false;
    for (var i = 0; i < _words.length; i++) {
      if (_words[i] != other._words[i]) return false;
    }
    return true;
  }
}

class BitArray32x4 {
  final Int32x4List _words;
  final int length;

  BitArray32x4(this.length) : _words = Int32x4List((length + 127) >> 7);

  void setBit(int i) {
    final wordIdx = i >> 7;
    final laneIdx = (i >> _wordShift) & 3;
    final bit = 1 << (i & _wordMask);
    final v = _words[wordIdx];
    switch (laneIdx) {
      case 0:
        _words[wordIdx] = Int32x4(v.x | bit, v.y, v.z, v.w);
      case 1:
        _words[wordIdx] = Int32x4(v.x, v.y | bit, v.z, v.w);
      case 2:
        _words[wordIdx] = Int32x4(v.x, v.y, v.z | bit, v.w);
      case 3:
        _words[wordIdx] = Int32x4(v.x, v.y, v.z, v.w | bit);
    }
  }

  // Used by the cross-implementation correctness check to enumerate bits.
  void forEachSetBit(void Function(int) action) {
    for (var i = 0; i < _words.length; i++) {
      final v = _words[i];
      final base = i << 7;
      var w = v.x & 0xFFFFFFFF;
      while (w != 0) {
        final bit = w.trailingZeroBitCount;
        final pos = base + bit;
        if (pos >= length) return;
        action(pos);
        w &= w - 1;
      }
      w = v.y & 0xFFFFFFFF;
      final b1 = base + 32;
      while (w != 0) {
        final bit = w.trailingZeroBitCount;
        final pos = b1 + bit;
        if (pos >= length) return;
        action(pos);
        w &= w - 1;
      }
      w = v.z & 0xFFFFFFFF;
      final b2 = base + 64;
      while (w != 0) {
        final bit = w.trailingZeroBitCount;
        final pos = b2 + bit;
        if (pos >= length) return;
        action(pos);
        w &= w - 1;
      }
      w = v.w & 0xFFFFFFFF;
      final b3 = base + 96;
      while (w != 0) {
        final bit = w.trailingZeroBitCount;
        final pos = b3 + bit;
        if (pos >= length) return;
        action(pos);
        w &= w - 1;
      }
    }
  }

  static void intersection(BitArray32x4 a, BitArray32x4 b, BitArray32x4 out) {
    final wa = a._words;
    final wb = b._words;
    final wo = out._words;
    if (wa.length != wb.length || wa.length != wo.length) {
      throw ArgumentError('a, b, and out must have the same length');
    }
    final n = wa.length;
    for (var i = 0; i < n; i++) {
      wo[i] = wa[i] & wb[i];
    }
  }

  static void union(BitArray32x4 a, BitArray32x4 b, BitArray32x4 out) {
    final wa = a._words;
    final wb = b._words;
    final wo = out._words;
    if (wa.length != wb.length || wa.length != wo.length) {
      throw ArgumentError('a, b, and out must have the same length');
    }
    final n = wa.length;
    for (var i = 0; i < n; i++) {
      wo[i] = wa[i] | wb[i];
    }
  }

  static void xor(BitArray32x4 a, BitArray32x4 b, BitArray32x4 out) {
    final wa = a._words;
    final wb = b._words;
    final wo = out._words;
    if (wa.length != wb.length || wa.length != wo.length) {
      throw ArgumentError('a, b, and out must have the same length');
    }
    final n = wa.length;
    for (var i = 0; i < n; i++) {
      wo[i] = wa[i] ^ wb[i];
    }
  }

  static void difference(BitArray32x4 a, BitArray32x4 b, BitArray32x4 out) {
    final wa = a._words;
    final wb = b._words;
    final wo = out._words;
    if (wa.length != wb.length || wa.length != wo.length) {
      throw ArgumentError('a, b, and out must have the same length');
    }
    final n = wa.length;
    final ones = Int32x4(-1, -1, -1, -1);
    for (var i = 0; i < n; i++) {
      wo[i] = wa[i] & (wb[i] ^ ones);
    }
  }

  static void complement(BitArray32x4 a, BitArray32x4 out) {
    final wa = a._words;
    final wo = out._words;
    if (wa.length != wo.length) {
      throw ArgumentError('a and out must have the same length');
    }
    final n = wa.length;
    final ones = Int32x4(-1, -1, -1, -1);
    for (var i = 0; i < n; i++) {
      wo[i] = wa[i] ^ ones;
    }
  }
}

void _setRandomBits(
  void Function(int) setBit,
  int size,
  Random rng,
  int densityPercent,
) {
  for (var i = 0; i < size; i++) {
    if (rng.nextInt(100) < densityPercent) setBit(i);
  }
}

BitArray32 _randomArray32(int size, Random rng, int densityPercent) {
  final bits = BitArray32(size);
  _setRandomBits(bits.setBit, size, rng, densityPercent);
  return bits;
}

void _assertEq(Object? actual, Object? expected, String label) {
  if (actual != expected) {
    throw StateError('FAIL $label: expected $expected, got $actual');
  }
}

const int _benchSize = 1 << 20; // 1,048,576 bits = 32,768 words.

const int _seedA = 0xBEEF;
const int _seedB = 0xC0DE;

class _BitArray32Benchmark extends BenchmarkBase {
  final int densityPercent;
  final void Function(BitArray32) operation;
  late BitArray32 bits;

  _BitArray32Benchmark(String name, this.densityPercent, this.operation)
    : super('BitArray32.$name');

  @override
  void setup() {
    bits = _randomArray32(_benchSize, Random(_seedA), densityPercent);
  }

  @override
  void run() {
    operation(bits);
  }
}

class _BitArray32PairBenchmark extends BenchmarkBase {
  final int densityPercent;
  final void Function(BitArray32, BitArray32, BitArray32) operation;
  late BitArray32 a;
  late BitArray32 b;
  late BitArray32 out;

  _BitArray32PairBenchmark(String name, this.densityPercent, this.operation)
    : super('BitArray32.$name');

  @override
  void setup() {
    a = _randomArray32(_benchSize, Random(_seedA), densityPercent);
    b = _randomArray32(_benchSize, Random(_seedB), densityPercent);
    out = BitArray32(_benchSize);
  }

  @override
  void run() {
    operation(a, b, out);
  }
}

List<BenchmarkBase> _benchmarks32() {
  // Sinks the optimizer cannot fold away.
  var sink = 0;
  void accumulate(int x) {
    sink ^= x;
  }

  return [
    _BitArray32Benchmark(
      'cardinality',
      25,
      (bits) => sink ^= bits.cardinality(),
    ),
    _BitArray32Benchmark(
      'forEachSetBit',
      25,
      (bits) => bits.forEachSetBit(accumulate),
    ),
    _BitArray32Benchmark(
      'select',
      25,
      (bits) => sink ^= bits.select(_benchSize >> 3),
    ),
    _BitArray32Benchmark(
      'complementCardinality',
      25,
      (bits) => sink ^= bits.complementCardinality(),
    ),
    _BitArray32Benchmark(
      'totalBitLength',
      25,
      (bits) => sink ^= bits.totalBitLength(),
    ),

    _BitArray32PairBenchmark('intersection', 25, BitArray32.intersection),
    _BitArray32PairBenchmark(
      'intersection.accelerated',
      25,
      BitArray32.intersectionAccelerated,
    ),
    _BitArray32PairBenchmark('union', 25, BitArray32.union),
    _BitArray32PairBenchmark(
      'union.accelerated',
      25,
      BitArray32.unionAccelerated,
    ),
    _BitArray32PairBenchmark('xor', 25, BitArray32.xor),
    _BitArray32PairBenchmark('xor.accelerated', 25, BitArray32.xorAccelerated),
    _BitArray32PairBenchmark('difference', 25, BitArray32.difference),
    _BitArray32PairBenchmark(
      'difference.accelerated',
      25,
      BitArray32.differenceAccelerated,
    ),
    _BitArray32PairBenchmark(
      'complement',
      25,
      (a, _, out) => BitArray32.complement(a, out),
    ),
    _BitArray32PairBenchmark(
      'complement.accelerated',
      25,
      (a, _, out) => BitArray32.complementAccelerated(a, out),
    ),
  ];
}

BitArray32x4 _randomArray32x4(int size, Random rng, int densityPercent) {
  final bits = BitArray32x4(size);
  _setRandomBits(bits.setBit, size, rng, densityPercent);
  return bits;
}

// Cross-implementation check: for the same seeded bit pattern, the SIMD
// `BitArray32x4` ops and `BitArray32`'s accelerated (Int32x4-view) ops must
// both agree with the scalar `BitArray32` ops.
void checkCrossImpl() {
  final rng = Random(0xC0DE);

  void compareSets(String op, BitArray32 u, BitArray32x4 s) {
    final uBits = <int>[];
    final sBits = <int>[];
    u.forEachSetBit(uBits.add);
    s.forEachSetBit(sBits.add);
    _assertEq(sBits.length, uBits.length, '$op count');
    for (var i = 0; i < uBits.length; i++) {
      _assertEq(sBits[i], uBits[i], '$op [$i]');
    }
  }

  for (final size in const [0, 1, 31, 32, 33, 63, 64, 65, 127, 1000, 50000]) {
    for (final density in const [0, 3, 50, 97, 100]) {
      final u = _randomArray32(size, rng, density);
      final uOther = _randomArray32(size, rng, density);
      // Mirror both `u` operands into `BitArray32x4` via forEachSetBit.
      final s = BitArray32x4(size);
      u.forEachSetBit(s.setBit);
      final sOther = BitArray32x4(size);
      uOther.forEachSetBit(sOther.setBit);

      final label = 'cross(size=$size, density=$density)';

      final uInt = BitArray32(size);
      final sInt = BitArray32x4(size);
      BitArray32.intersection(u, uOther, uInt);
      BitArray32x4.intersection(s, sOther, sInt);
      compareSets('$label intersection', uInt, sInt);

      final uUni = BitArray32(size);
      final sUni = BitArray32x4(size);
      BitArray32.union(u, uOther, uUni);
      BitArray32x4.union(s, sOther, sUni);
      compareSets('$label union', uUni, sUni);

      final uXor = BitArray32(size);
      final sXor = BitArray32x4(size);
      BitArray32.xor(u, uOther, uXor);
      BitArray32x4.xor(s, sOther, sXor);
      compareSets('$label xor', uXor, sXor);

      final uDif = BitArray32(size);
      final sDif = BitArray32x4(size);
      BitArray32.difference(u, uOther, uDif);
      BitArray32x4.difference(s, sOther, sDif);
      compareSets('$label difference', uDif, sDif);

      final aInt = BitArray32(size);
      BitArray32.intersectionAccelerated(u, uOther, aInt);
      _assertEq(uInt.wordsEqual(aInt), true, '$label intersection.accelerated');

      final aUni = BitArray32(size);
      BitArray32.unionAccelerated(u, uOther, aUni);
      _assertEq(uUni.wordsEqual(aUni), true, '$label union.accelerated');

      final aXor = BitArray32(size);
      BitArray32.xorAccelerated(u, uOther, aXor);
      _assertEq(uXor.wordsEqual(aXor), true, '$label xor.accelerated');

      final aDif = BitArray32(size);
      BitArray32.differenceAccelerated(u, uOther, aDif);
      _assertEq(uDif.wordsEqual(aDif), true, '$label difference.accelerated');

      final uCmp = BitArray32(size);
      final aCmp = BitArray32(size);
      BitArray32.complement(u, uCmp);
      BitArray32.complementAccelerated(u, aCmp);
      _assertEq(uCmp.wordsEqual(aCmp), true, '$label complement.accelerated');
    }
  }
}

class _BitArray32x4PairBenchmark extends BenchmarkBase {
  final int densityPercent;
  final void Function(BitArray32x4, BitArray32x4, BitArray32x4) operation;
  late BitArray32x4 a;
  late BitArray32x4 b;
  late BitArray32x4 out;

  _BitArray32x4PairBenchmark(String name, this.densityPercent, this.operation)
    : super('BitArray32x4.$name');

  @override
  void setup() {
    a = _randomArray32x4(_benchSize, Random(_seedA), densityPercent);
    b = _randomArray32x4(_benchSize, Random(_seedB), densityPercent);
    out = BitArray32x4(_benchSize);
  }

  @override
  void run() {
    operation(a, b, out);
  }
}

List<BenchmarkBase> _benchmarks32x4() {
  return [
    _BitArray32x4PairBenchmark('intersection', 25, BitArray32x4.intersection),
    _BitArray32x4PairBenchmark('union', 25, BitArray32x4.union),
    _BitArray32x4PairBenchmark('xor', 25, BitArray32x4.xor),
    _BitArray32x4PairBenchmark('difference', 25, BitArray32x4.difference),
    _BitArray32x4PairBenchmark(
      'complement',
      25,
      (a, _, out) => BitArray32x4.complement(a, out),
    ),
  ];
}

void main() {
  checkCrossImpl();
  for (final benchmark in _benchmarks32()) {
    benchmark.report();
  }
  for (final benchmark in _benchmarks32x4()) {
    benchmark.report();
  }
}
