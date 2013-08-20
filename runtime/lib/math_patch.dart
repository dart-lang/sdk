// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:typed_data";

// A VM patch of the dart:math library.

// If [x] is an [int] and [exponent] is a non-negative [int], the result is
// an [int], otherwise the result is a [double].
patch num pow(num x, num exponent) {
  if ((x is int) && (exponent is int) && (exponent >= 0)) {
    return _intPow(x, exponent);
  }
  // doublePow will call exponent.toDouble().
  return _doublePow(x.toDouble(), exponent);
}

double _doublePow(double base, num exponent) {
  if (exponent == 0) {
    return 1.0;  // ECMA-262 15.8.2.13
  }
  if (exponent is! num) {
    throw new ArgumentError(null);
  }
  double doubleExponent = exponent.toDouble();
  if (base.isNaN || exponent.isNaN) {
    return double.NAN;
  }
  return _pow(base, doubleExponent);
}

double _pow(double base, double exponent) native "Math_doublePow";

int _intPow(int base, int exponent) {
  // Exponentiation by squaring.
  int result = 1;
  while (exponent != 0) {
    if ((exponent & 1) == 1) {
      result *= base;
    }
    exponent >>= 1;
    // Skip unnecessary operation (can overflow to Mint or Bigint).
    if (exponent != 0) {
      base *= base;
    }
  }
  return result;
}

patch double atan2(num a, num b) => _atan2(a.toDouble(), b.toDouble());
patch double sin(num value) => _sin(value.toDouble());
patch double cos(num value) => _cos(value.toDouble());
patch double tan(num value) => _tan(value.toDouble());
patch double acos(num value) => _acos(value.toDouble());
patch double asin(num value) => _asin(value.toDouble());
patch double atan(num value) => _atan(value.toDouble());
patch double sqrt(num value) => _sqrt(value.toDouble());
patch double exp(num value) => _exp(value.toDouble());
patch double log(num value) => _log(value.toDouble());

double _atan2(double a, double b) native "Math_atan2";
double _sin(double x) native "Math_sin";
double _cos(double x) native "Math_cos";
double _tan(double x) native "Math_tan";
double _acos(double x) native "Math_acos";
double _asin(double x) native "Math_asin";
double _atan(double x) native "Math_atan";
double _sqrt(double x) native "Math_sqrt";
double _exp(double x) native "Math_exp";
double _log(double x) native "Math_log";


// TODO(iposva): Handle patch methods within a patch class correctly.
patch class Random {

  /*patch*/ factory Random([int seed]) {
    if (seed == null) {
      seed = _Random._nextSeed();
    }
    // Crank a couple of times to distribute the seed bits a bit further.
    return new _Random().._setupSeed(seed)
                        .._nextState()
                        .._nextState()
                        .._nextState()
                        .._nextState();
  }
}


class _Random implements Random {
  // Internal state of the random number generator.
  final _state = new Uint32List(2);
  static const kSTATE_LO = 0;
  static const kSTATE_HI = 1;

  // Implements:
  //   do {
  //     seed = (seed + 0x5A17) & _Random._MASK_64;
  //   } while (seed == 0);
  //   _state[kSTATE_LO] = seed & _MASK_32;
  //   _state[kSTATE_HI] = seed >> 32;
  // This is a native to prevent 64-bit operations in Dart, which
  // fail with --throw_on_javascript_int_overflow.
  void _setupSeed(int seed) native "Random_setupSeed";

  // The algorithm used here is Multiply with Carry (MWC) with a Base b = 2^32.
  // http://en.wikipedia.org/wiki/Multiply-with-carry
  // The constant A is selected from "Numerical Recipes 3rd Edition" p.348 B1.

  // Implements:
  //   var state = ((_A * (_state[kSTATE_LO])) + _state[kSTATE_HI]) & _MASK_64;
  //   _state[kSTATE_LO] = state & _MASK_32;
  //   _state[kSTATE_HI] = state >> 32;
  // This is a native to prevent 64-bit operations in Dart, which
  // fail with --throw_on_javascript_int_overflow.
  void _nextState() native "Random_nextState";

  int nextInt(int max) {
    // TODO(srdjan): Remove the 'limit' check once optimizing  comparison of
    // Smi-s with Mint constants.
    final limit = 0x3FFFFFFF;
    if (max <= 0 || ((max > limit) && (max > _POW2_32))) {
      throw new ArgumentError("max must be positive and < 2^32:"
                                         " $max");
    }
    if ((max & -max) == max) {
      // Fast case for powers of two.
      _nextState();
      return _state[kSTATE_LO] & (max - 1);
    }

    var rnd32;
    var result;
    do {
      _nextState();
      rnd32 = _state[kSTATE_LO];
      result = rnd32 % max;
    } while ((rnd32 - result + max) >= _POW2_32);
    return result;
  }

  double nextDouble() {
    return ((nextInt(1 << 26) * _POW2_27_D) + nextInt(1 << 27)) / _POW2_53_D;
  }

  bool nextBool() {
    return nextInt(2) == 0;
  }

  // Constants used by the algorithm or masking.
  static const _MASK_32 = (1 << 32) - 1;
  static const _MASK_64 = (1 << 64) - 1;
  static const _POW2_32 = 1 << 32;
  static const _POW2_53_D = 1.0 * (1 << 53);
  static const _POW2_27_D = 1.0 * (1 << 27);

  static const _A = 0xffffda61;

  // Use a singleton Random object to get a new seed if no seed was passed.
  static var _prng = null;

  static int _nextSeed() {
    if (_prng == null) {
      // TODO(iposva): Use system to get a random seed.
      _prng = new Random(new DateTime.now().millisecondsSinceEpoch);
    }
    // Trigger the PRNG once to change the internal state.
    _prng._nextState();
    return _prng._state[kSTATE_LO];
  }
}
