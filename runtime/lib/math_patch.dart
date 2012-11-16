// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A VM patch of the dart:math library.
patch num pow(num x, num exponent) {
  if (exponent is int) {
    return x.pow(exponent);
  }
  // Double.pow will call exponent.toDouble().
  return x.toDouble().pow(exponent);
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
    do {
      seed = (seed + 0x5A17) & _Random._MASK_64;
    } while (seed == 0);
    return new _Random._internal(seed);
  }
}


class _Random implements Random {
  // Internal state of the random number generator.
  var _state;
  static const kSTATE_LO = 0;
  static const kSTATE_HI = 1;

  _Random._internal(state) {
    _state = new List(2);
    _state[kSTATE_LO] = state & _MASK_32;
    _state[kSTATE_HI] = state >> 32;
  }

  // The algorithm used here is Multiply with Carry (MWC) with a Base b = 2^32.
  // http://en.wikipedia.org/wiki/Multiply-with-carry
  // The constant A is selected from "Numerical Recipes 3rd Edition" p.348 B1.
  int _nextInt32() {
    var state = ((_A * (_state[kSTATE_LO])) + _state[kSTATE_HI]) & _MASK_64;
    _state[kSTATE_LO] = state & _MASK_32;
    _state[kSTATE_HI] = state >> 32;
    return _state[kSTATE_LO];
  }

  int nextInt(int max) {
    if (max <= 0 || max > _POW2_32) {
      throw new ArgumentError("max must be positive and < 2^32:"
                                         " $max");
    }
    if ((max & -max) == max) {
      // Fast case for powers of two.
      return _nextInt32() & (max - 1);
    }

    var rnd32;
    var result;
    do {
      rnd32 = _nextInt32();
      result = rnd32 % max;
    } while ((rnd32 - result + max) >= _POW2_32);
    return result;
  }

  double nextDouble() {
    return ((nextInt(1 << 26) << 27) + nextInt(1 << 27)) / _POW2_53_D;
  }

  bool nextBool() {
    return nextInt(2) == 0;
  }

  // Constants used by the algorithm or masking.
  static const _MASK_32 = (1 << 32) - 1;
  static const _MASK_64 = (1 << 64) - 1;
  static const _POW2_32 = 1 << 32;
  static const _POW2_53_D = 1.0 * (1 << 53);

  static const _A = 0xffffda61;

  // Use a singleton Random object to get a new seed if no seed was passed.
  static var _prng = null;

  static int _nextSeed() {
    if (_prng == null) {
      // TODO(iposva): Use system to get a random seed.
      _prng = new Random(new Date.now().millisecondsSinceEpoch);
    }
    // Trigger the PRNG once to change the internal state.
    return _prng._nextInt32();
  }
}
