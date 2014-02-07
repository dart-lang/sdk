// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:math library.
import 'dart:_foreign_helper' show JS;
import 'dart:_js_helper' show checkNum;

patch double sqrt(num x)
  => JS('double', r'Math.sqrt(#)', checkNum(x));

patch double sin(num x)
  => JS('double', r'Math.sin(#)', checkNum(x));

patch double cos(num x)
  => JS('double', r'Math.cos(#)', checkNum(x));

patch double tan(num x)
  => JS('double', r'Math.tan(#)', checkNum(x));

patch double acos(num x)
  => JS('double', r'Math.acos(#)', checkNum(x));

patch double asin(num x)
  => JS('double', r'Math.asin(#)', checkNum(x));

patch double atan(num x)
  => JS('double', r'Math.atan(#)', checkNum(x));

patch double atan2(num a, num b)
  => JS('double', r'Math.atan2(#, #)', checkNum(a), checkNum(b));

patch double exp(num x)
  => JS('double', r'Math.exp(#)', checkNum(x));

patch double log(num x)
  => JS('double', r'Math.log(#)', checkNum(x));

patch num pow(num x, num exponent) {
  checkNum(x);
  checkNum(exponent);
  return JS('num', r'Math.pow(#, #)', x, exponent);
}

const int _POW2_32 = 0x100000000;

patch class Random {
  patch factory Random([int seed]) =>
      (seed == null) ? const _JSRandom() : new _Random(seed);
}

class _JSRandom implements Random {
  // The Dart2JS implementation of Random doesn't use a seed.
  const _JSRandom();

  int nextInt(int max) {
    if (max <= 0 || max > _POW2_32) {
      throw new RangeError("max must be in range 0 < max ≤ 2^32, was $max");
    }
    return JS("int", "(Math.random() * #) >>> 0", max);
  }

  /**
   * Generates a positive random floating point value uniformly distributed on
   * the range from 0.0, inclusive, to 1.0, exclusive.
   */
  double nextDouble() => JS("double", "Math.random()");

  /**
   * Generates a random boolean value.
   */
  bool nextBool() => JS("bool", "Math.random() < 0.5");
}


class _Random implements Random {
  // Constants used by the algorithm or masking.
  static const double _POW2_53_D = 1.0 * (0x20000000000000);
  static const double _POW2_27_D = 1.0 * (1 << 27);
  static const int _MASK32 = 0xFFFFFFFF;

  // State comprised of two unsigned 32 bit integers.
  int _lo = 0;
  int _hi = 0;

  // Implements:
  //   uint64_t hash = 0;
  //   do {
  //      hash = hash * 1037 ^ mix64((uint64_t)seed);
  //      seed >>= 64;
  //   } while (seed != 0 && seed != -1);  // Limits for pos/neg seed.
  //   if (hash == 0) {
  //     hash = 0x5A17;
  //   }
  //   _lo = hash & _MASK_32;
  //   _hi = hash >> 32;
  // and then does four _nextState calls to shuffle bits around.
  _Random(int seed) {
    int empty_seed = 0;
    if (seed < 0) {
      empty_seed = -1;
    }
    do {
      int low = seed & _MASK32;
      seed = (seed - low) ~/ _POW2_32;
      int high = seed & _MASK32;
      seed = (seed - high) ~/ _POW2_32;

      // Thomas Wang's 64-bit mix function.
      // http://www.concentric.net/~Ttwang/tech/inthash.htm
      // via. http://web.archive.org/web/20071223173210/http://www.concentric.net/~Ttwang/tech/inthash.htm

      // key = ~key + (key << 21);
      int tmplow = low << 21;
      int tmphigh = (high << 21) | (low >> 11);
      tmplow = (~low & _MASK32) + tmplow;
      low = tmplow & _MASK32;
      high = (~high + tmphigh + ((tmplow - low) ~/ 0x100000000)) & _MASK32;
      // key = key ^ (key >> 24).
      tmphigh = high >> 24;
      tmplow = (low >> 24) | (high << 8);
      low ^= tmplow;
      high ^= tmphigh;
      // key = key * 265
      tmplow = low * 265;
      low = tmplow & _MASK32;
      high = (high * 265 + (tmplow - low) ~/ 0x100000000) & _MASK32;
      // key = key ^ (key >> 14);
      tmphigh = high >> 14;
      tmplow = (low >> 14) | (high << 18);
      low ^= tmplow;
      high ^= tmphigh;
      // key = key * 21
      tmplow = low * 21;
      low = tmplow & _MASK32;
      high = (high * 21 + (tmplow - low) ~/ 0x100000000) & _MASK32;
      // key = key ^ (key >> 28).
      tmphigh = high >> 28;
      tmplow = (low >> 28) | (high << 4);
      low ^= tmplow;
      high ^= tmphigh;
      // key = key + (key << 31);
      tmplow = low << 31;
      tmphigh = (high << 31) | (low >> 1);
      tmplow += low;
      low = tmplow & _MASK32;
      high = (high + tmphigh + (tmplow - low) ~/ 0x100000000) & _MASK32;
      // Mix end.

      // seed = seed * 1037 ^ key;
      tmplow = _lo * 1037;
      _lo = tmplow & _MASK32;
      _hi = (_hi * 1037 + (tmplow - _lo) ~/ 0x100000000) & _MASK32;
      _lo ^= low;
      _hi ^= high;
    } while (seed != empty_seed);

    if (_hi == 0 && _lo == 0) {
      _lo = 0x5A17;
    }
    _nextState();
    _nextState();
    _nextState();
    _nextState();
  }

  // The algorithm used here is Multiply with Carry (MWC) with a Base b = 2^32.
  // http://en.wikipedia.org/wiki/Multiply-with-carry
  // The constant A (0xFFFFDA61) is selected from "Numerical Recipes 3rd
  // Edition" p.348 B1.

  // Implements:
  //   var state = (A * _lo + _hi) & _MASK_64;
  //   _lo = state & _MASK_32;
  //   _hi = state >> 32;
  void _nextState() {
    // Simulate (0xFFFFDA61 * lo + hi) without overflowing 53 bits.
    int tmpHi = 0xFFFF0000 * _lo;  // At most 48 bits of significant result.
    int tmpHiLo = tmpHi & _MASK32;             // Get the lower 32 bits.
    int tmpHiHi = tmpHi - tmpHiLo;            // And just the upper 32 bits.
    int tmpLo = 0xDA61 * _lo;
    int tmpLoLo = tmpLo & _MASK32;
    int tmpLoHi = tmpLo - tmpLoLo;

    int newLo = tmpLoLo + tmpHiLo + _hi;
    _lo = newLo & _MASK32;
    int newLoHi = newLo - _lo;
    _hi = ((tmpLoHi + tmpHiHi + newLoHi) ~/ _POW2_32) & _MASK32;
    assert(_lo < _POW2_32);
    assert(_hi < _POW2_32);
  }

  int nextInt(int max) {
    if (max <= 0 || max > _POW2_32) {
      throw new RangeError("max must be in range 0 < max ≤ 2^32, was $max");
    }
    if ((max & (max - 1)) == 0) {
      // Fast case for powers of two.
      _nextState();
      return _lo & (max - 1);
    }

    int rnd32;
    int result;
    do {
      _nextState();
      rnd32 = _lo;
      result = rnd32.remainder(max); // % max;
    } while ((rnd32 - result + max) >= _POW2_32);
    return result;
  }

  double nextDouble() {
    _nextState();
    int bits26 = _lo & ((1 << 26) - 1);
    _nextState();
    int bits27 = _lo & ((1 << 27) - 1);
    return (bits26 * _POW2_27_D + bits27) / _POW2_53_D;
  }

  bool nextBool() {
    _nextState();
    return (_lo & 1) == 0;
  }
}
