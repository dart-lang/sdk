// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A part of the dart:math library.

/**
 * A random number generator. The default implementation supplies a stream of
 * pseudo-random bits which is not suitable for cryptographic purposes.
 */
interface Random default _Random {
  /** 
   * Creates a random-number generator. The optional parameter [seed] is used
   * to initialize the internal state of the generator. The implementation of
   * the random stream can change between releases of the library.
   *
   * Implementation note: The default implementation uses up to 64-bits of seed.
   */
  Random([int seed]);

  /** 
   * Generates a positive random integer uniformly distributed on the range
   * from 0, inclusive, to [max], exclusive.
   *
   * Implementation note: The default implementation supports [max] values
   * between 1 and ((1<<32) - 1) inclusive.
   */
  int nextInt(int max);

  /** 
   * Generates a positive random floating point value uniformly distributed on
   * the range from 0.0, inclusive, to 1.0, exclusive.
   */
  double nextDouble();

  /** 
   * Generates a random boolean value.
   */
  bool nextBool();
}

class _Random implements Random {

  _Random([int seed = null]) {
    if (seed == null) {
      seed = _nextSeed();
    }
    do {
      seed = (seed + 0x5A17) & _MASK_64;
    } while (seed == 0);
    _state = seed;
  }

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

  static final _MASK_32 = (1 << 32) - 1;
  static final _MASK_64 = (1 << 64) - 1;
  static final _POW2_32 = 1 << 32;
  static final _POW2_53_D = 1.0 * (1 << 53);

  static final _A = 0xffffda61;

  var _state;

  int _nextSeed() {
    if (_prng == null) {
      // TODO(iposva): Use system to get a random seed.
      _prng = new _Random(new Date.now().value);
    }
    // Trigger the PRNG once to change the internal state.
    _prng._nextInt32();
    return _prng._state;
  }

  static var _prng = null;
}
