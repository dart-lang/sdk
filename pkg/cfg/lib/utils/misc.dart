// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Compares elements of the given lists.
bool listEquals(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Mixes hash code with a given [value] to produce a derived hash code.
///
/// Unlike [Object.hash], this function is guaranteed to be
/// stable over different runs, which is needed to keep compiler
/// fully deterministic.
int combineHash(int hash, int value) {
  hash = 0x1fffffff & (hash + value);
  hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
  return hash ^ (hash >> 6);
}

/// Finishes hash code construction after combining multiple values.
int finalizeHash(int hash) {
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash = hash ^ (hash >> 11);
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}

/// Returns combined hash code of [list] elements.
///
/// Unlike [Object.hashAll], this function is guaranteed to be
/// stable over different runs, which is needed to keep compiler
/// fully deterministic.
int listHashCode(List<Object?> list) {
  var hash = 1;
  for (final e in list) {
    hash = combineHash(hash, e.hashCode);
  }
  return finalizeHash(hash);
}

/// Return true iff [x] is a power of 2.
bool isPowerOf2(int x) => (x != 0) && (x & (x - 1)) == 0;

/// Return log2 of the given [x], where [x] is a power of 2.
int log2OfPowerOf2(int x) {
  assert(isPowerOf2(x));
  return x > 0 ? x.bitLength - 1 : 63;
}

/// Rounds non-negative [value] down to the nearest multiple of [alignment].
/// [alignment] must be a power of 2.
@pragma("vm:prefer-inline")
int roundDown(int value, int alignment) {
  assert(value >= 0);
  assert(isPowerOf2(alignment));
  return value & ~(alignment - 1);
}

/// Rounds non-negative [value] up to the nearest multiple of [alignment].
/// [alignment] must be a power of 2.
@pragma("vm:prefer-inline")
int roundUp(int value, int alignment) {
  assert(value >= 0);
  return roundDown(value + alignment - 1, alignment);
}
