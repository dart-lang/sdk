// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A VM patch of the dart:math library.
patch int parseInt(String str) => MathNatives.parseInt(str);
patch double parseDouble(String str) => MathNatives.parseDouble(str);
patch num pow(num x, num exponent) => MathNatives.pow(x, exponent);
patch double atan2(num a, num b) => MathNatives.atan2(a, b);
patch double sin(num x) => MathNatives.sin(x);
patch double cos(num x) => MathNatives.cos(x);
patch double tan(num x) => MathNatives.tan(x);
patch double acos(num x) => MathNatives.acos(x);
patch double asin(num x) => MathNatives.asin(x);
patch double atan(num x) => MathNatives.atan(x);
patch double sqrt(num x) => MathNatives.sqrt(x);
patch double exp(num x) => MathNatives.exp(x);
patch double log(num x) => MathNatives.log(x);


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

  _Random._internal(this._state);

  // The algorithm used here is Multiply with Carry (MWC) with a Base b = 2^32.
  // http://en.wikipedia.org/wiki/Multiply-with-carry
  // The constant A is selected from "Numerical Recipes 3rd Edition" p.348 B1.
  int _nextInt32() {
    _state = ((_A * (_state & _MASK_32)) + (_state >> 32)) & _MASK_64;
    return _state & _MASK_32;
  }

  int nextInt(int max) {
    if (max <= 0 || max > _POW2_32) {
      throw new IllegalArgumentException("max must be positive and < 2^32:"
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
    } while (rnd32 - result + max >= _POW2_32);
    return result;
  }

  double nextDouble() {
    return ((nextInt(1 << (26)) << 27) + nextInt(1 << 27)) / _POW2_53_D;
  }

  bool nextBool() {
    return nextInt(1) == 0;
  }

  // Constants used by the algorithm or masking.
  static final _MASK_32 = (1 << 32) - 1;
  static final _MASK_64 = (1 << 64) - 1;
  static final _POW2_32 = 1 << 32;
  static final _POW2_53_D = 1.0 * (1 << 53);

  static final _A = 0xffffda61;

  // Use a singleton Random object to get a new seed if no seed was passed.
  static var _prng = null;

  static int _nextSeed() {
    if (_prng == null) {
      // TODO(iposva): Use system to get a random seed.
      _prng = new Random(new Date.now().millisecondsSinceEpoch);
    }
    // Trigger the PRNG once to change the internal state.
    _prng._nextInt32();
    return _prng._state;
  }
}
