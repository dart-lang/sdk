// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:math library.

// Imports checkNum etc. used below.
#import("js_helper.dart");

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

patch class Random {
  patch factory Random([int seed]) => const _Random();
}

class _Random implements Random {
  // The Dart2JS implementation of Random doesn't use a seed.
  const _Random();

  int nextInt(int max) {
    if (max < 0) throw new IllegalArgumentException("negative max: $max");
    if (max > 0xFFFFFFFF) max = 0xFFFFFFFF;
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
