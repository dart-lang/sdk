// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.util.enumset;

import 'dart:collection';

/// A set of enum values based on a bit mask of the shifted enum indices.
abstract class EnumSet<E> {
  /// Creates an empty mutable set.
  factory EnumSet() = _EnumSet<E>;

  /// Creates a mutable set from the bit mask [value].
  factory EnumSet.fromValue(int value) = _EnumSet<E>.fromValue;

  /// Creates an immutable set from the bit mask [value].
  const factory EnumSet.fixed(int value) = _ConstEnumSet<E>;

  /// Create a set containing the [values]. If [fixed] is `true` the set is
  /// immutable.
  factory EnumSet.fromValues(Iterable<E> values, {bool fixed: false}) {
    if (fixed) {
      return new _ConstEnumSet<E>.fromValues(values);
    } else {
      return new _EnumSet<E>.fromValues(values);
    }
  }

  const EnumSet._();

  /// The bit mask of the shifted indices for the enum values in this set.
  int get value;

  /// Sets the enum values in this set through a bit mask of the shifted enum
  /// value indices.
  void set value(int mask);

  /// Adds [enumValue] to this set. Returns `true` if the set was changed by
  /// this action.
  bool add(E enumValue);

  /// Adds all enum values in [set] to this set.
  void addAll(EnumSet<E> set);

  /// Removes [enumValue] from this set. Returns `true` if the set was changed
  /// by this action.
  bool remove(E enumValue);

  /// Removes all enum values in [set] from this set. The set of removed values
  /// is returned.
  EnumSet<E> removeAll(EnumSet<E> set);

  /// Returns a new set containing all values in both this and the [other] set.
  EnumSet<E> intersection(EnumSet<E> other) {
    return new EnumSet.fromValue(value & other.value);
  }

  /// Returns a new set containing all values either in this set or in the
  /// [other] set.
  EnumSet<E> union(EnumSet<E> other) {
    return new EnumSet.fromValue(value | other.value);
  }

  /// Returns a new set containing all values in this set that are not in the
  /// [other] set.
  EnumSet<E> minus(EnumSet<E> other) {
    return new EnumSet.fromValue(value & ~other.value);
  }

  /// Clears this set.
  void clear();

  /// Returns `true` if [enumValue] is in this set.
  bool contains(E enumValue) {
    return (value & (1 << (enumValue as dynamic).index)) != 0;
  }

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
    return new _EnumSetIterable(this, values);
  }

  /// Returns `true` if this and [other] have any elements in common.
  bool intersects(EnumSet<E> other) {
    return (value & other.value) != 0;
  }

  /// Returns `true` if this set is empty.
  bool get isEmpty => value == 0;

  /// Returns `true` if this set is not empty.
  bool get isNotEmpty => value != 0;

  /// Returns a new mutable enum set that contains the values of this set.
  EnumSet<E> clone() => new EnumSet<E>.fromValue(value);

  @override
  int get hashCode => value.hashCode * 19;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! EnumSet<E>) return false;
    return value == other.value;
  }

  @override
  String toString() {
    if (value == 0) return '0';
    int index = value.bitLength - 1;
    StringBuffer sb = new StringBuffer();
    int mask = 1 << index;
    while (index >= 0) {
      sb.write((value & mask) != 0 ? '1' : '0');
      index--;
      mask >>= 1;
    }
    return sb.toString();
  }
}

/// Mutable implementation of [EnumSet].
class _EnumSet<E> extends EnumSet<E> {
  int _value;

  _EnumSet() : this.fromValue(0);

  _EnumSet.fromValue(this._value) : super._();

  _EnumSet.fromValues(Iterable<E> values)
      : this._value = 0,
        super._() {
    values.forEach(add);
  }

  @override
  int get value => _value;

  @override
  void set value(int mask) {
    _value = mask;
  }

  @override
  bool add(E enumValue) {
    int before = _value;
    _value |= 1 << (enumValue as dynamic).index;
    return _value != before;
  }

  @override
  void addAll(EnumSet<E> set) {
    _value |= set.value;
  }

  @override
  bool remove(E enumValue) {
    int before = _value;
    _value &= ~(1 << (enumValue as dynamic).index);
    return _value != before;
  }

  @override
  EnumSet<E> removeAll(EnumSet<E> set) {
    int removed = _value & set.value;
    _value &= ~set.value;
    return new EnumSet<E>.fromValue(removed);
  }

  @override
  void clear() {
    _value = 0;
  }
}

/// Immutable implementation of [EnumSet].
class _ConstEnumSet<E> extends EnumSet<E> {
  @override
  final int value;

  const _ConstEnumSet(this.value) : super._();

  factory _ConstEnumSet.fromValues(Iterable<E> values) {
    int value = 0;
    void add(E enumValue) {
      if (enumValue != null) {
        value |= 1 << (enumValue as dynamic).index;
      }
    }

    values.forEach(add);
    return new _ConstEnumSet(value);
  }

  @override
  void set value(int mask) {
    throw new UnsupportedError('EnumSet.value=');
  }

  @override
  bool add(E enumValue) {
    throw new UnsupportedError('EnumSet.add');
  }

  @override
  void addAll(EnumSet<E> set) {
    throw new UnsupportedError('EnumSet.addAll');
  }

  @override
  void clear() {
    if (isEmpty) {
      // We allow this no-op operation on an immutable set to support using a
      // constant empty set together with mutable sets where applicable.
    } else {
      throw new UnsupportedError('EnumSet.clear');
    }
  }

  @override
  bool remove(E enumValue) {
    if (isEmpty) {
      // We allow this no-op operation on an immutable set to support using a
      // constant empty set together with mutable sets where applicable.
      return false;
    }
    throw new UnsupportedError('EnumSet.remove');
  }

  @override
  EnumSet<E> removeAll(EnumSet<E> set) {
    if (isEmpty) {
      // We allow this no-op operation on an immutable set to support using a
      // constant empty set together with mutable sets where applicable.
      return this;
    }
    if (set.isEmpty) {
      // We allow this no-op operation on an immutable set to support using a
      // constant empty set together with mutable sets where applicable.
      return set.clone();
    }
    throw new UnsupportedError('EnumSet.removeAll');
  }
}

class _EnumSetIterable<E> extends IterableBase<E> {
  final EnumSet<E> _enumSet;
  final List<E> _values;

  _EnumSetIterable(this._enumSet, this._values);

  @override
  Iterator<E> get iterator => new _EnumSetIterator(_enumSet.value, _values);
}

class _EnumSetIterator<E> implements Iterator<E> {
  int _value;
  int _index;
  int _mask;
  final List<E> _values;
  E _current;

  _EnumSetIterator(this._value, this._values);

  @override
  E get current => _current;

  @override
  bool moveNext() {
    if (_value == 0) {
      return false;
    } else {
      if (_mask == null) {
        _index = _value.bitLength - 1;
        _mask = 1 << _index;
      }
      _current = null;
      while (_index >= 0) {
        if (_mask & _value != 0) {
          _current = _values[_index];
        }
        _mask >>= 1;
        _index--;
        if (_current != null) {
          break;
        }
      }
      return _current != null;
    }
  }
}
