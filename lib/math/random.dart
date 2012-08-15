// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A part of the dart:math library.

/**
 * A random number generator. The default implementation supplies a stream of
 * pseudo-random bits which is not suitable for cryptographic purposes.
 */
class Random {
  /**
   * Creates a random-number generator. The optional parameter [seed] is used
   * to initialize the internal state of the generator. The implementation of
   * the random stream can change between releases of the library.
   *
   * Implementation note: The default implementation uses up to 64-bits of seed.
   */
  external factory Random([int seed]);

  /**
   * Generates a positive random integer uniformly distributed on the range
   * from 0, inclusive, to [max], exclusive.
   *
   * Implementation note: The default implementation supports [max] values
   * between 1 and ((1<<32) - 1) inclusive.
   */
  abstract int nextInt(int max);

  /**
   * Generates a positive random floating point value uniformly distributed on
   * the range from 0.0, inclusive, to 1.0, exclusive.
   */
  abstract double nextDouble();

  /**
   * Generates a random boolean value.
   */
  abstract bool nextBool();
}
