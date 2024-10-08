// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.util.enumset;

import 'dart:collection';

import 'package:meta/meta.dart';

extension<E extends Enum> on E {
  int get mask {
    assert(index < 64);
    return 1 << index;
  }
}

int _fold<E extends Enum>(Iterable<E> values) =>
    values.fold(0, (acc, e) => acc | e.mask);

/// A set of enum values based on a bit mask of the shifted enum indices. The
/// enum indices used must be less than 64.
extension type const EnumSet<E extends Enum>(int mask) {
  /// Creates an empty set.
  const EnumSet.empty() : mask = 0;

  /// Creates a singleton set containing [value].
  EnumSet.fromValue(E value) : mask = value.mask;

  /// Creates a set containing [values].
  EnumSet.fromValues(Iterable<E> values) : mask = _fold(values);

  /// Returns a set containing all enum values in [this] as well as [enumValue].
  @useResult
  EnumSet<E> operator +(E enumValue) => EnumSet(mask | enumValue.mask);

  /// Returns a set containing all enum values in [this] except for [enumValue].
  @useResult
  EnumSet<E> operator -(E enumValue) => EnumSet(mask & ~enumValue.mask);

  /// Returns a set with the bit for [value] enabled or disabled depending on
  /// [state].
  @useResult
  EnumSet<E> update(E value, bool state) => state ? this + value : this - value;

  /// Returns a new set containing all values in both this and the [other] set.
  @useResult
  EnumSet<E> intersection(EnumSet<E> other) {
    return EnumSet(mask & other.mask);
  }

  /// Returns a new set containing all values either in this set or in the
  /// [other] set.
  @useResult
  EnumSet<E> union(EnumSet<E> other) {
    return EnumSet(mask | other.mask);
  }

  /// Returns a new set containing all values in this set that are not in the
  /// [other] set.
  @useResult
  EnumSet<E> setMinus(EnumSet<E> other) {
    return EnumSet(mask & ~other.mask);
  }

  /// Returns `true` if [enumValue] is in this set.
  bool contains(E enumValue) {
    return (mask & enumValue.mask) != 0;
  }

  /// Returns `true` if this and [other] have any elements in common.
  bool intersects(EnumSet<E> other) {
    return (mask & other.mask) != 0;
  }

  /// Returns `true` if this set is empty.
  bool get isEmpty => mask == 0;

  /// Returns `true` if this set is not empty.
  bool get isNotEmpty => mask != 0;

  /// Returns an [Iterable] of the values is in this set using [values] to
  /// convert the stored indices to enum values.
  ///
  /// The method is typically called with the `values` property of the enum
  /// class as argument:
  ///
  ///     EnumSet<EnumClass> set = ...
  ///     Iterable<EnumClass> iterable = set.iterable(EnumClass.values);
  ///
  Iterable<E> iterable(List<E> values) {
    // We may store extra data in the bits unused by the enum values, but that
    // will result in iteration attempting to look up enum values out of bounds.
    // We can avoid this by masking off such bits.
    return _EnumSetIterable(mask & ((1 << values.length) - 1), values);
  }
}

class _EnumSetIterable<E extends Enum> extends IterableBase<E> {
  final int _mask;
  final List<E> _values;

  _EnumSetIterable(this._mask, this._values);

  @override
  Iterator<E> get iterator => _EnumSetIterator(_mask, _values);
}

class _EnumSetIterator<E extends Enum> implements Iterator<E> {
  int _mask;
  final List<E> _values;
  E? _current;

  _EnumSetIterator(this._mask, this._values);

  @override
  E get current => _current!;

  @override
  bool moveNext() {
    if (_mask == 0) {
      _current = null;
      return false;
    }
    final value = _current = _values[_mask.bitLength - 1];
    _mask &= ~value.mask;
    return true;
  }
}
