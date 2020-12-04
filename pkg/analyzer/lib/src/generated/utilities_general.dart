// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:yaml/yaml.dart';

/// Test if the given [value] is `false` or the string "false"
/// (case-insensitive).
bool isFalse(Object value) =>
    value is bool ? !value : toLowerCase(value) == 'false';

/// Test if the given [value] is `true` or the string "true" (case-insensitive).
bool isTrue(Object value) =>
    value is bool ? value : toLowerCase(value) == 'true';

/// Safely convert the given [value] to a bool value, or return `null` if the
/// value could not be converted.
bool toBool(Object value) {
  if (value is YamlScalar) {
    value = (value as YamlScalar).value;
  }
  if (value is bool) {
    return value;
  }
  String string = toLowerCase(value);
  if (string == 'true') {
    return true;
  }
  if (string == 'false') {
    return false;
  }
  return null;
}

/// Safely convert this [value] to lower case, returning `null` if [value] is
/// null.
String toLowerCase(Object value) => value?.toString()?.toLowerCase();

/// Safely convert this [value] to upper case, returning `null` if [value] is
/// null.
String toUpperCase(Object value) => value?.toString()?.toUpperCase();

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
  int _hash = 0;

  /// Finalizes the hash and return the resulting hashcode.
  @override
  int get hashCode => finish(_hash);

  /// Accumulates the object [o] into the hash.
  void add(Object o) {
    _hash = combine(_hash, o.hashCode);
  }

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
  static int hash2(int a, int b) => finish(combine(combine(0, a), b));

  /// Combines together three hash codes.
  static int hash3(int a, int b, int c) =>
      finish(combine(combine(combine(0, a), b), c));

  /// Combines together four hash codes.
  static int hash4(int a, int b, int c, int d) =>
      finish(combine(combine(combine(combine(0, a), b), c), d));
}

/// A simple limited queue.
class LimitedQueue<E> extends ListQueue<E> {
  final int limit;

  /// Create a queue with [limit] items.
  LimitedQueue(this.limit);

  @override
  void add(E o) {
    super.add(o);
    while (length > limit) {
      remove(first);
    }
  }
}
