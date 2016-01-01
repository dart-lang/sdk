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
  return _doublePow(x.toDouble(), exponent.toDouble());
}

double _doublePow(double base, double exponent) {
  if (exponent == 0.0) {
    return 1.0;  // ECMA-262 15.8.2.13
  }
  // Speed up simple cases.
  if (exponent == 1.0) return base;
  if (exponent == 2.0) return base * base;
  if (exponent == 3.0) return base * base * base;
  
  if (base == 1.0) return 1.0;

  if (base.isNaN || exponent.isNaN) {
    return double.NAN;
  }
  if ((base != -double.INFINITY) && (exponent == 0.5)) {
    if (base == 0.0) {
      return 0.0;
    }
    return sqrt(base);
  }
  return _pow(base.toDouble(), exponent.toDouble());
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
    var state = _Random._setupSeed((seed == null) ? _Random._nextSeed() : seed);
    // Crank a couple of times to distribute the seed bits a bit further.
    return new _Random._withState(state).._nextState()
                                        .._nextState()
                                        .._nextState()
                                        .._nextState();
  }

  /*patch*/ factory Random.secure() {
    return new _SecureRandom();
  }
}


class _Random implements Random {
  // Internal state of the random number generator.
  final _state;
  static const _kSTATE_LO = 0;
  static const _kSTATE_HI = 1;  // Unused in Dart code.

  _Random._withState(Uint32List this._state);

  // The algorithm used here is Multiply with Carry (MWC) with a Base b = 2^32.
  // http://en.wikipedia.org/wiki/Multiply-with-carry
  // The constant A is selected from "Numerical Recipes 3rd Edition" p.348 B1.

  // Implements:
  //   var state =
  //       ((_A * (_state[_kSTATE_LO])) + _state[_kSTATE_HI]) & ((1 << 64) - 1);
  //   _state[_kSTATE_LO] = state & ((1 << 32) - 1);
  //   _state[_kSTATE_HI] = state >> 32;
  // This is a native to prevent 64-bit operations in Dart, which
  // fail with --throw_on_javascript_int_overflow.
  void _nextState() native "Random_nextState";

  int nextInt(int max) {
    const limit = 0x3FFFFFFF;
    if ((max <= 0) || ((max > limit) && (max > _POW2_32))) {
      throw new RangeError.range(max, 1, _POW2_32, "max",
                                 "Must be positive and <= 2^32");
    }
    if ((max & -max) == max) {
      // Fast case for powers of two.
      _nextState();
      return _state[_kSTATE_LO] & (max - 1);
    }

    var rnd32;
    var result;
    do {
      _nextState();
      rnd32 = _state[_kSTATE_LO];
      result = rnd32 % max;
    } while ((rnd32 - result + max) > _POW2_32);
    return result;
  }

  double nextDouble() {
    return ((nextInt(1 << 26) * _POW2_27_D) + nextInt(1 << 27)) / _POW2_53_D;
  }

  bool nextBool() {
    return nextInt(2) == 0;
  }

  // Constants used by the algorithm.
  static const _POW2_32 = 1 << 32;
  static const _POW2_53_D = 1.0 * (1 << 53);
  static const _POW2_27_D = 1.0 * (1 << 27);

  static const _A = 0xffffda61;

  // Use a singleton Random object to get a new seed if no seed was passed.
  static var _prng = new _Random._withState(_initialSeed());

  // This is a native to prevent 64-bit operations in Dart, which
  // fail with --throw_on_javascript_int_overflow.
  static Uint32List _setupSeed(int seed) native "Random_setupSeed";
  // Get a seed from the VM's random number provider.
  static Uint32List _initialSeed() native "Random_initialSeed";

  static int _nextSeed() {
    // Trigger the PRNG once to change the internal state.
    _prng._nextState();
    return _prng._state[_kSTATE_LO];
  }
}


class _SecureRandom implements Random {
  _SecureRandom() {
    // Throw early in constructor if entropy source is not hooked up.
    _getBytes(1);
  }

  // Return count bytes of entropy as a positive integer; count <= 8.
  static int _getBytes(int count) native "SecureRandom_getBytes";

  int nextInt(int max) {
    RangeError.checkValueInInterval(
        max, 1, _POW2_32, "max", "Must be positive and <= 2^32");
    final byteCount = ((max - 1).bitLength + 7) >> 3;
    if (byteCount == 0) {
      return 0;  // Not random if max == 1.
    }
    var rnd;
    var result;
    do {
      rnd = _getBytes(byteCount);
      result = rnd % max;
    } while ((rnd - result + max) > (1 << (byteCount << 3)));
    return result;
  }

  double nextDouble() {
    return (_getBytes(7) >> 3) / _POW2_53_D;
  }

  bool nextBool() {
    return _getBytes(1).isEven;
  }

  // Constants used by the algorithm.
  static const _POW2_32 = 1 << 32;
  static const _POW2_53_D = 1.0 * (1 << 53);
}

