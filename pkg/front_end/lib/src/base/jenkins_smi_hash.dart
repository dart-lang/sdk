// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Jenkins hash function, optimized for small integers.
///
/// Static methods borrowed from sdk/lib/math/jenkins_smi_hash.dart.  Non-static
/// methods are an enhancement for the "front_end" package.
///
/// Where performance is critical, use [hash2], [hash3], or [hash4], or the
/// pattern `finish(combine(combine(...combine(0, a), b)..., z))`, where a..z
/// are hash codes to be combined.
///
/// For ease of use, you may also use this pattern:
/// `(new JenkinsSmiHash()..add(a)..add(b)....add(z)).hashCode`, where a..z are
/// the sub-objects whose hashes should be combined.  This pattern performs the
/// same operations as the performance critical variant, but allocates an extra
/// object.
class JenkinsSmiHash {
  /// Accumulates the hash code [value] into the running hash [hash].
  static int combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  /// Finalizes a running hash produced by [combine].
  static int finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  /// Combines together two hash codes.
  static int hash2(a, b) => finish(combine(combine(0, a), b));

  /// Combines together three hash codes.
  static int hash3(a, b, c) => finish(combine(combine(combine(0, a), b), c));

  /// Combines together four hash codes.
  static int hash4(a, b, c, d) =>
      finish(combine(combine(combine(combine(0, a), b), c), d));

  int _hash = 0;

  /// Accumulates the object [o] into the hash.
  void add(Object o) {
    _hash = combine(_hash, o.hashCode);
  }

  /// Finalizes the hash and return the resulting hashcode.
  int get hashCode => finish(_hash);
}
