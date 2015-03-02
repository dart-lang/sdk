// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
part of dart.math;

/**
 * This is the [Jenkins hash function][1] but using masking to keep
 * values in SMI range.
 *
 * [1]: http://en.wikipedia.org/wiki/Jenkins_hash_function
 *
 * Use:
 * Hash each value with the hash of the previous value, then get the final
 * hash by calling finish.
 *
 *     var hash = 0;
 *     for (var value in values) {
 *       hash = JenkinsSmiHash.combine(hash, value.hashCode);
 *     }
 *     hash = JenkinsSmiHash.finish(hash);
 */
class _JenkinsSmiHash {
  // TODO(11617): This class should be optimized and standardized elsewhere.

  static int combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) <<  3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  static int hash2(a, b) => finish(combine(combine(0, a), b));

  static int hash4(a, b, c, d) =>
      finish(combine(combine(combine(combine(0, a), b), c), d));
}
