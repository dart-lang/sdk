// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.util.enumset;

import 'dart:collection';

import 'package:meta/meta.dart';

import 'bitset.dart';

extension<E extends Enum> on E {
  Bitset mask(int offset) {
    assert(index + offset < 64);
    return Bitset(1 << (index + offset));
  }
}

/// A set of enum values based on a bit mask of the shifted enum indices. The
/// enum indices used must be less than 64.
extension type const EnumSet<E extends Enum>(Bitset mask) {
  const EnumSet.fromRawBits(int bits) : this(bits as Bitset);

  /// Creates an empty set.
  const EnumSet.empty() : this.fromRawBits(0);

  /// Creates a set containing all enum values in [E].
  /// [values] is intended to be the `values` property of the enum class.
  const EnumSet.allValues(Iterable<E> values)
      : this.fromRawBits((1 << values.length) - 1);

  /// Creates a singleton set containing [value].
  EnumSet.fromValue(E value) : this(value.mask(0));

  /// Creates a set containing [values].
  EnumSet.fromValues(Iterable<E> values)
      : this(values.fold(Bitset.empty(), (acc, e) => acc.union(e.mask(0))));

  /// Returns a set containing all enum values in [this] as well as [enumValue].
  @useResult
  EnumSet<E> add(E enumValue) => EnumSet(mask.union(enumValue.mask(0)));

  /// Returns a set containing all enum values in [this] except for [enumValue].
  @useResult
  EnumSet<E> remove(E enumValue) => EnumSet(mask.setMinus(enumValue.mask(0)));

  /// Returns a set with the bit for [value] enabled or disabled depending on
  /// [state].
  @useResult
  EnumSet<E> update(E value, bool state) => state ? add(value) : remove(value);

  /// Returns a new set containing all values in both this and the [other] set.
  @useResult
  EnumSet<E> intersection(EnumSet<E> other) =>
      EnumSet(mask.intersection(other.mask));

  /// Returns a new set containing all values either in this set or in the
  /// [other] set.
  @useResult
  EnumSet<E> union(EnumSet<E> other) => EnumSet(mask.union(other.mask));

  /// Returns a new set containing all values in this set that are not in the
  /// [other] set.
  @useResult
  EnumSet<E> setMinus(EnumSet<E> other) => EnumSet(mask.setMinus(other.mask));

  /// Returns `true` if [enumValue] is in this set.
  bool contains(E enumValue) => mask.intersects(enumValue.mask(0));

  /// Returns `true` if this and [other] have any values in common.
  bool intersects(EnumSet<E> other) => mask.intersects(other.mask);

  /// Returns `true` if this set is empty.
  bool get isEmpty => mask.isEmpty;

  /// Returns `true` if this set is not empty.
  bool get isNotEmpty => mask.isNotEmpty;

  /// Returns an [Iterable] of the values is in this set using [values] to
  /// convert the stored indices to enum values.
  ///
  /// The method is typically called with the `values` property of the enum
  /// class as argument:
  ///
  ///     EnumSet<EnumClass> set = ...
  ///     Iterable<EnumClass> iterable = set.iterable(EnumClass.values);
  ///
  Iterable<E> iterable(List<E> values) =>
      // We may store extra data in the bits unused by the enum values, but that
      // will result in iteration attempting to look up enum values out of bounds.
      // We can avoid this by masking off such bits.
      _EnumSetIterable(mask.bits & ((1 << values.length) - 1), values);
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
    _mask &= ~value.mask(0).bits;
    return true;
  }
}

/// Generalizes some [EnumSet] operations to support offsets.
/// The offset allows multiple enumsets to be compacted into the same shared
/// [int] by using different ranges of bits for different enums.
/// The shared [int] is provided to each operation rather than owned by `this`.
class EnumSetDomain<E extends Enum> {
  /// How many low-significance bits to skip over when converting enum values to
  /// bits, or equivalently, which bit is used to represent the smallest enum
  /// value, where 0 indicates the LSB and 63 indicates the MSB. An offset of 0
  /// is equivalent to using an [EnumSet] directly.
  final int offset;

  final Iterable<E> values;

  /// A bitset containing all enum values in [E].
  late final Bitset allValues = Bitset(((1 << values.length) - 1) << offset);

  EnumSetDomain(this.offset, this.values);

  /// When composing [EnumSetDomain]s, the [offset] to use for the next domain.
  int get nextOffset => offset + values.length;

  /// Returns a singleton bitset containing [value].
  Bitset fromValue(E value) => value.mask(offset);

  /// Returns a bitset containing [values].
  Bitset fromValues(Iterable<E> values) =>
      values.fold(Bitset.empty(), (acc, e) => acc.union(e.mask(offset)));

  /// Returns a bitset derived from [values] shifted by the appropriate offset.
  Bitset fromEnumSet(EnumSet<E> values) => Bitset(values.mask.bits << offset);

  EnumSet<E> toEnumSet(Bitset bits) =>
      EnumSet.fromRawBits(restrict(bits).bits >> offset);

  /// Returns a bitset equal to [bits] with only bits in this domain set.
  @useResult
  Bitset restrict(Bitset bits) => bits.intersection(allValues);

  /// Returns a bitset containing all enum values in [bits] as well as
  /// [enumValue].
  @useResult
  Bitset add(Bitset bits, E enumValue) => bits.union(enumValue.mask(offset));

  /// Returns a bitset containing all enum values in [bits] except for
  /// [enumValue].
  @useResult
  Bitset remove(Bitset bits, E enumValue) =>
      bits.setMinus(enumValue.mask(offset));

  /// Returns a copy of [bits] with the bit for [value] enabled or disabled
  /// depending on [state].
  @useResult
  Bitset update(Bitset bits, E value, bool state) =>
      state ? add(bits, value) : remove(bits, value);

  /// Returns `true` if [enumValue] is in [bits].
  bool contains(Bitset bits, E enumValue) =>
      bits.intersects(enumValue.mask(offset));

  /// Returns `true` if [bits] contains any [E].
  bool isNotEmpty(Bitset bits) => bits.intersects(allValues);

  /// Returns `true` if [bits] does not contain any [E].
  bool isEmpty(Bitset bits) => !isNotEmpty(bits);
}

class ComposedEnumSetDomains {
  final List<EnumSetDomain> domains;
  final int bitWidth;
  late final Bitset mask;
  late final Bitset notMask;

  ComposedEnumSetDomains(this.domains) : bitWidth = domains.last.nextOffset {
    final maskBits = (1 << bitWidth) - 1;
    mask = Bitset(maskBits);
    notMask = Bitset(~maskBits);
  }

  @useResult
  Bitset restrict(Bitset bits) => bits.intersection(mask);
}
