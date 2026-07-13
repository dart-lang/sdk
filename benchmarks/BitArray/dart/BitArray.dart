// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Benchmarks for int.trailingZeroBitCount and int.oneBitCount, exercised
// through a small bit-array implementation. Each operation has an
// `Accelerated` variant (HW intrinsic for counting operations, Int32x4 SIMD
// for word-level bitwise operations) and a `Swar` baseline that does the
// same work without HW acceleration, so the speedup attributable to the
// hardware path is visible directly.
//
// `main()` first runs a correctness check that asserts both
// implementations agree across a range of sizes and densities, then
// reports benchmark timings via the standard BenchmarkBase harness.

import 'dart:math';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';

// 32-bit storage words so the benchmark runs on both native (64-bit int)
// and web (32-bit bitwise) without platform-specific word arithmetic.
const int _wordBits = 32;
const int _wordMask = _wordBits - 1;
const int _wordShift = 5;

class BitArray {
  final Uint32List _words;
  final int length;

  BitArray(this.length)
    : _words = Uint32List((length + _wordBits - 1) >> _wordShift);

  Uint32List get words => _words;

  void setBit(int i) {
    _words[i >> _wordShift] |= 1 << (i & _wordMask);
  }

  // ----- cardinality (popcount across all words) ---------------------------

  // Accelerated: hardware popcount via int.oneBitCount.
  int cardinalityAccelerated() {
    var total = 0;
    for (var i = 0; i < _words.length; i++) {
      total += _words[i].oneBitCount;
    }
    return total;
  }

  int cardinalitySwar() {
    var total = 0;
    for (var i = 0; i < _words.length; i++) {
      total += _popcountWord(_words[i]);
    }
    return total;
  }

  // ----- forEachSetBit (iterate set bits via ctz + clear-lowest) -----------

  // Accelerated: int.trailingZeroBitCount per surviving bit.
  void forEachSetBitAccelerated(void Function(int) action) {
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

  void forEachSetBitSwar(void Function(int) action) {
    for (var wordIdx = 0; wordIdx < _words.length; wordIdx++) {
      var w = _words[wordIdx];
      final base = wordIdx << _wordShift;
      while (w != 0) {
        final bit = _ctzWord(w);
        final pos = base + bit;
        if (pos >= length) return;
        action(pos);
        // https://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetKernighan
        w &= w - 1;
      }
    }
  }

  // ----- select(k) (position of the k-th set bit, k >= 0) -----------------

  // Accelerated: int.oneBitCount to skip whole words, then walk the
  // target word with int.trailingZeroBitCount.
  int selectAccelerated(int k) {
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

  // Fair non-accelerated baseline: SWAR popcount to skip whole words,
  // SWAR ctz inside the target word.
  int selectSwar(int k) {
    var remaining = k;
    for (var wordIdx = 0; wordIdx < _words.length; wordIdx++) {
      final w = _words[wordIdx];
      final pop = _popcountWord(w);
      if (remaining < pop) {
        var v = w;
        while (remaining > 0) {
          // https://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetKernighan
          v &= v - 1;
          remaining--;
        }
        return (wordIdx << _wordShift) + _ctzWord(v);
      }
      remaining -= pop;
    }
    return -1;
  }

  // ----- totalBitLength (sum of int.bitLength across every word) ----------
  //
  // A synthetic operation that exercises int.bitLength once per word, the
  // way cardinality exercises int.oneBitCount once per word.

  // Accelerated: int.bitLength (asm-intrinsic CLZ today).
  int totalBitLengthAccelerated() {
    var total = 0;
    for (var i = 0; i < _words.length; i++) {
      total += _words[i].bitLength;
    }
    return total;
  }

  // Software bit-trick equivalent of bitLength on a 32-bit word.
  int totalBitLengthSwar() {
    var total = 0;
    for (var i = 0; i < _words.length; i++) {
      final v = _words[i];
      if (v != 0) total += _highBitInWord(v) + 1;
    }
    return total;
  }

  // ----- complementCardinality (popcount of bitwise NOT each word) -------
  //
  // Exercises int.~ once per word, immediately followed by oneBitCount.

  // Accelerated: int.oneBitCount on each complemented word.
  int complementCardinalityAccelerated() {
    var total = 0;
    for (var i = 0; i < _words.length; i++) {
      // Mask back to 32 bits because ~uint32 sign-extends in Dart's int.
      total += (~_words[i] & 0xFFFFFFFF).oneBitCount;
    }
    return total;
  }

  // Fair non-accelerated baseline: SWAR popcount on each complemented word.
  int complementCardinalitySwar() {
    var total = 0;
    for (var i = 0; i < _words.length; i++) {
      total += _popcountWord(~_words[i] & 0xFFFFFFFF);
    }
    return total;
  }

  // ----- intersection (out = a AND b, materialized as a new BitArray) -----

  // Word-level scalar AND.
  static void intersectionSwar(BitArray a, BitArray b, BitArray out) {
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

  // Accelerated: 4 words per Int32x4 vector op. Tail uses scalar.
  static void intersectionAccelerated(BitArray a, BitArray b, BitArray out) {
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

  // ----- union (out = a OR b) -------------------------------------------

  static void unionSwar(BitArray a, BitArray b, BitArray out) {
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

  static void unionAccelerated(BitArray a, BitArray b, BitArray out) {
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

  // ----- xor (out = a XOR b, symmetric difference) -----------------------

  static void xorSwar(BitArray a, BitArray b, BitArray out) {
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

  static void xorAccelerated(BitArray a, BitArray b, BitArray out) {
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

  // ----- difference (out = a AND NOT b) ----------------------------------
  //
  // Set difference: bits set in `a` and not in `b`. Implemented as
  // a & ~b at the word / SIMD level.

  static void differenceSwar(BitArray a, BitArray b, BitArray out) {
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

  static void differenceAccelerated(BitArray a, BitArray b, BitArray out) {
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
    // Int32x4 has no andNot; build via a & ~b (bitwise negate is a single
    // NEON EOR-with-all-ones on ARM64).
    final ones = Int32x4(-1, -1, -1, -1);
    for (var i = 0; i < simdWords; i++) {
      vo[i] = va[i] & (vb[i] ^ ones);
    }
    for (var i = simdWords << 2; i < n; i++) {
      wo[i] = wa[i] & (~wb[i] & 0xFFFFFFFF);
    }
  }

  // ----- complement (out = NOT a) ----------------------------------------

  static void complementSwar(BitArray a, BitArray out) {
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

  static void complementAccelerated(BitArray a, BitArray out) {
    final wa = a._words;
    final wo = out._words;
    if (wa.length != wo.length) {
      throw ArgumentError('a and out must have the same length');
    }
    final n = wa.length;
    final simdWords = n >> 2;
    final va = Int32x4List.view(wa.buffer, wa.offsetInBytes, simdWords);
    final vo = Int32x4List.view(wo.buffer, wo.offsetInBytes, simdWords);
    // No SIMD NOT; emit XOR-with-all-ones, which the VM lowers to a single
    // NEON EOR on ARM64.
    final ones = Int32x4(-1, -1, -1, -1);
    for (var i = 0; i < simdWords; i++) {
      vo[i] = va[i] ^ ones;
    }
    for (var i = simdWords << 2; i < n; i++) {
      wo[i] = ~wa[i] & 0xFFFFFFFF;
    }
  }

  bool wordsEqual(BitArray other) {
    if (_words.length != other._words.length) return false;
    for (var i = 0; i < _words.length; i++) {
      if (_words[i] != other._words[i]) return false;
    }
    return true;
  }

  // ----- helpers ----------------------------------------------------------

  // SWAR popcount on a 32-bit word; non-accelerated equivalent of
  // int.oneBitCount.
  static int _popcountWord(int v) {
    v = v - ((v >> 1) & 0x55555555);
    v = (v & 0x33333333) + ((v >> 2) & 0x33333333);
    v = (v + (v >> 4)) & 0x0F0F0F0F;
    return ((v * 0x01010101) >> 24) & 0xFF;
  }

  // SWAR count-trailing-zeros on a 32-bit word; non-accelerated equivalent
  // of int.trailingZeroBitCount. Returns 32 for zero.
  static int _ctzWord(int v) {
    if (v == 0) return _wordBits;
    var n = 0;
    if ((v & 0xFFFF) == 0) {
      n += 16;
      v >>= 16;
    }
    if ((v & 0xFF) == 0) {
      n += 8;
      v >>= 8;
    }
    if ((v & 0xF) == 0) {
      n += 4;
      v >>= 4;
    }
    if ((v & 0x3) == 0) {
      n += 2;
      v >>= 2;
    }
    if ((v & 0x1) == 0) {
      n += 1;
    }
    return n;
  }

  // SWAR log2 on a 32-bit word; non-accelerated equivalent of
  // int.bitLength minus one (for nonzero v).
  static int _highBitInWord(int v) {
    var r = 0;
    if (v >= 0x10000) {
      v >>= 16;
      r += 16;
    }
    if (v >= 0x100) {
      v >>= 8;
      r += 8;
    }
    if (v >= 0x10) {
      v >>= 4;
      r += 4;
    }
    if (v >= 0x4) {
      v >>= 2;
      r += 2;
    }
    if (v >= 0x2) {
      r += 1;
    }
    return r;
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

// ----- Correctness check ----------------------------------------------------

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

BitArray _randomArray(int size, Random rng, int densityPercent) {
  final bits = BitArray(size);
  _setRandomBits(bits.setBit, size, rng, densityPercent);
  return bits;
}

void _assertEq(Object? actual, Object? expected, String label) {
  if (actual != expected) {
    throw StateError('FAIL $label: expected $expected, got $actual');
  }
}

void checkCorrectness() {
  final rng = Random(0xDA27);
  for (final size in const [0, 1, 31, 32, 33, 63, 64, 65, 127, 1000, 50000]) {
    for (final density in const [0, 3, 50, 97, 100]) {
      final bits = _randomArray(size, rng, density);

      // Cardinality operations must agree. SWAR is the oracle.
      final card = bits.cardinalitySwar();
      _assertEq(
        bits.cardinalityAccelerated(),
        card,
        'cardinality.accelerated(size=$size, density=$density)',
      );

      // forEachSetBit: accelerated and swar must enumerate the same
      // bits in the same order.
      final acc = <int>[];
      final swar = <int>[];
      bits.forEachSetBitAccelerated(acc.add);
      bits.forEachSetBitSwar(swar.add);
      _assertEq(
        acc.length,
        swar.length,
        'forEach count (size=$size, density=$density)',
      );
      for (var i = 0; i < acc.length; i++) {
        _assertEq(
          acc[i],
          swar[i],
          'forEach[$i] (size=$size, density=$density)',
        );
      }

      // select(k): accelerated and swar must agree.
      for (final k in [0, 1, card >> 1, card - 1]) {
        if (k < 0 || k >= card) continue;
        _assertEq(
          bits.selectAccelerated(k),
          bits.selectSwar(k),
          'select(size=$size, density=$density, k=$k)',
        );
      }

      _assertEq(
        bits.complementCardinalityAccelerated(),
        bits.complementCardinalitySwar(),
        'complementCardinality(size=$size, density=$density)',
      );

      _assertEq(
        bits.totalBitLengthAccelerated(),
        bits.totalBitLengthSwar(),
        'totalBitLength(size=$size, density=$density)',
      );

      // Bitwise pair ops: scalar and SIMD must produce identical results.
      final other = _randomArray(size, rng, density);
      final label = 'size=$size, density=$density';

      final iSwar = BitArray(size);
      final iAcc = BitArray(size);
      BitArray.intersectionSwar(bits, other, iSwar);
      BitArray.intersectionAccelerated(bits, other, iAcc);
      _assertEq(iAcc.wordsEqual(iSwar), true, 'intersection($label)');

      final uSwar = BitArray(size);
      final uAcc = BitArray(size);
      BitArray.unionSwar(bits, other, uSwar);
      BitArray.unionAccelerated(bits, other, uAcc);
      _assertEq(uAcc.wordsEqual(uSwar), true, 'union($label)');

      final xSwar = BitArray(size);
      final xAcc = BitArray(size);
      BitArray.xorSwar(bits, other, xSwar);
      BitArray.xorAccelerated(bits, other, xAcc);
      _assertEq(xAcc.wordsEqual(xSwar), true, 'xor($label)');

      final dSwar = BitArray(size);
      final dAcc = BitArray(size);
      BitArray.differenceSwar(bits, other, dSwar);
      BitArray.differenceAccelerated(bits, other, dAcc);
      _assertEq(dAcc.wordsEqual(dSwar), true, 'difference($label)');

      // Complement: scalar and SIMD must produce the same bit-flipped array.
      final cSwar = BitArray(size);
      final cAcc = BitArray(size);
      BitArray.complementSwar(bits, cSwar);
      BitArray.complementAccelerated(bits, cAcc);
      _assertEq(cAcc.wordsEqual(cSwar), true, 'complement($label)');
    }
  }
}

// ----- Benchmarks -----------------------------------------------------------

const int _benchSize = 1 << 20; // 1,048,576 bits = 32,768 words.

const int _seedA = 0xBEEF;
const int _seedB = 0xC0DE;

class _BitArrayBenchmark extends BenchmarkBase {
  final int densityPercent;
  final void Function(BitArray) operation;
  late BitArray bits;

  _BitArrayBenchmark(String name, this.densityPercent, this.operation)
    : super('BitArray.$name');

  @override
  void setup() {
    bits = _randomArray(_benchSize, Random(_seedA), densityPercent);
  }

  @override
  void run() {
    operation(bits);
  }
}

class _BitArrayPairBenchmark extends BenchmarkBase {
  final int densityPercent;
  final void Function(BitArray, BitArray, BitArray) operation;
  late BitArray a;
  late BitArray b;
  late BitArray out;

  _BitArrayPairBenchmark(String name, this.densityPercent, this.operation)
    : super('BitArray.$name');

  @override
  void setup() {
    a = _randomArray(_benchSize, Random(_seedA), densityPercent);
    b = _randomArray(_benchSize, Random(_seedB), densityPercent);
    out = BitArray(_benchSize);
  }

  @override
  void run() {
    operation(a, b, out);
  }
}

List<BenchmarkBase> _benchmarks() {
  // Sinks the optimizer cannot fold away.
  var sink = 0;
  void accumulate(int x) {
    sink ^= x;
  }

  return [
    // Cardinality: SWAR popcount vs int.oneBitCount.
    _BitArrayBenchmark(
      'cardinality.swar',
      25,
      (bits) => sink ^= bits.cardinalitySwar(),
    ),
    _BitArrayBenchmark(
      'cardinality.accelerated',
      25,
      (bits) => sink ^= bits.cardinalityAccelerated(),
    ),

    // forEachSetBit: Brian-Kernighan loop with SWAR ctz vs int.trailingZeroBitCount.
    _BitArrayBenchmark(
      'forEachSetBit.swar',
      25,
      (bits) => bits.forEachSetBitSwar(accumulate),
    ),
    _BitArrayBenchmark(
      'forEachSetBit.accelerated',
      25,
      (bits) => bits.forEachSetBitAccelerated(accumulate),
    ),

    // select(k) for k near the middle of a quarter-full array.
    _BitArrayBenchmark(
      'select.swar',
      25,
      (bits) => sink ^= bits.selectSwar(_benchSize >> 3),
    ),
    _BitArrayBenchmark(
      'select.accelerated',
      25,
      (bits) => sink ^= bits.selectAccelerated(_benchSize >> 3),
    ),

    // complementCardinality: popcount of (~w & 0xFFFFFFFF) per word.
    _BitArrayBenchmark(
      'complementCardinality.swar',
      25,
      (bits) => sink ^= bits.complementCardinalitySwar(),
    ),
    _BitArrayBenchmark(
      'complementCardinality.accelerated',
      25,
      (bits) => sink ^= bits.complementCardinalityAccelerated(),
    ),

    // totalBitLength: sum int.bitLength across every word.
    _BitArrayBenchmark(
      'totalBitLength.swar',
      25,
      (bits) => sink ^= bits.totalBitLengthSwar(),
    ),
    _BitArrayBenchmark(
      'totalBitLength.accelerated',
      25,
      (bits) => sink ^= bits.totalBitLengthAccelerated(),
    ),

    // Bitwise pair ops: scalar word-level vs Int32x4 SIMD.
    _BitArrayPairBenchmark('intersection.swar', 25, BitArray.intersectionSwar),
    _BitArrayPairBenchmark(
      'intersection.accelerated',
      25,
      BitArray.intersectionAccelerated,
    ),
    _BitArrayPairBenchmark('union.swar', 25, BitArray.unionSwar),
    _BitArrayPairBenchmark('union.accelerated', 25, BitArray.unionAccelerated),
    _BitArrayPairBenchmark('xor.swar', 25, BitArray.xorSwar),
    _BitArrayPairBenchmark('xor.accelerated', 25, BitArray.xorAccelerated),
    _BitArrayPairBenchmark('difference.swar', 25, BitArray.differenceSwar),
    _BitArrayPairBenchmark(
      'difference.accelerated',
      25,
      BitArray.differenceAccelerated,
    ),

    // Complement: scalar ~ vs Int32x4 XOR-with-all-ones. Ignores the
    // second input of the pair-benchmark harness.
    _BitArrayPairBenchmark(
      'complement.swar',
      25,
      (a, _, out) => BitArray.complementSwar(a, out),
    ),
    _BitArrayPairBenchmark(
      'complement.accelerated',
      25,
      (a, _, out) => BitArray.complementAccelerated(a, out),
    ),
  ];
}

// ----- BitArray32x4 correctness + benchmarks ------------------------------

BitArray32x4 _randomArray32x4(int size, Random rng, int densityPercent) {
  final bits = BitArray32x4(size);
  _setRandomBits(bits.setBit, size, rng, densityPercent);
  return bits;
}

// Cross-implementation check: for the same seeded bit pattern, every
// `BitArray32x4` SIMD op must produce the same set of bits as its
// corresponding `BitArray.*Accelerated` counterpart.
void checkCrossImpl() {
  final rng = Random(0xC0DE);

  void compareSets(String op, BitArray u, BitArray32x4 s) {
    final uBits = <int>[];
    final sBits = <int>[];
    u.forEachSetBitAccelerated(uBits.add);
    s.forEachSetBit(sBits.add);
    _assertEq(sBits.length, uBits.length, '$op count');
    for (var i = 0; i < uBits.length; i++) {
      _assertEq(sBits[i], uBits[i], '$op [$i]');
    }
  }

  for (final size in const [0, 1, 31, 32, 33, 63, 64, 65, 127, 1000, 50000]) {
    for (final density in const [0, 3, 50, 97, 100]) {
      final u = _randomArray(size, rng, density);
      final uOther = _randomArray(size, rng, density);
      // Mirror both `u` operands into `BitArray32x4` via forEachSetBit.
      final s = BitArray32x4(size);
      u.forEachSetBitAccelerated(s.setBit);
      final sOther = BitArray32x4(size);
      uOther.forEachSetBitAccelerated(sOther.setBit);

      final label = 'cross(size=$size, density=$density)';

      final uInt = BitArray(size);
      final sInt = BitArray32x4(size);
      BitArray.intersectionAccelerated(u, uOther, uInt);
      BitArray32x4.intersection(s, sOther, sInt);
      compareSets('$label intersection', uInt, sInt);

      final uUni = BitArray(size);
      final sUni = BitArray32x4(size);
      BitArray.unionAccelerated(u, uOther, uUni);
      BitArray32x4.union(s, sOther, sUni);
      compareSets('$label union', uUni, sUni);

      final uXor = BitArray(size);
      final sXor = BitArray32x4(size);
      BitArray.xorAccelerated(u, uOther, uXor);
      BitArray32x4.xor(s, sOther, sXor);
      compareSets('$label xor', uXor, sXor);

      final uDif = BitArray(size);
      final sDif = BitArray32x4(size);
      BitArray.differenceAccelerated(u, uOther, uDif);
      BitArray32x4.difference(s, sOther, sDif);
      compareSets('$label difference', uDif, sDif);
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
  checkCorrectness();
  checkCrossImpl();
  for (final benchmark in _benchmarks()) {
    benchmark.report();
  }
  for (final benchmark in _benchmarks32x4()) {
    benchmark.report();
  }
}
