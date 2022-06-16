// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Description of the exception behaviour of native code.
class NativeThrowBehavior {
  static const NativeThrowBehavior NEVER = NativeThrowBehavior._(0);
  static const NativeThrowBehavior MAY = NativeThrowBehavior._(1);

  /// Throws only if first argument is null.
  static const NativeThrowBehavior NULL_NSM = NativeThrowBehavior._(2);

  /// Throws if first argument is null, then may throw.
  static const NativeThrowBehavior NULL_NSM_THEN_MAY = NativeThrowBehavior._(3);

  final int _bits;
  const NativeThrowBehavior._(this._bits);

  bool get canThrow => this != NEVER;

  /// Does this behavior always throw a noSuchMethod check on a null first
  /// argument before any side effect or other exception?
  bool get isNullNSMGuard => this == NULL_NSM || this == NULL_NSM_THEN_MAY;

  /// Does this behavior always act as a null noSuchMethod check, and has no
  /// other throwing behavior?
  bool get isOnlyNullNSMGuard => this == NULL_NSM;

  /// Returns the behavior if we assume the first argument is not null.
  NativeThrowBehavior get onNonNull {
    if (this == NULL_NSM) return NEVER;
    if (this == NULL_NSM_THEN_MAY) return MAY;
    return this;
  }

  @override
  String toString() {
    if (this == NEVER) return 'never';
    if (this == MAY) return 'may';
    if (this == NULL_NSM) return 'null(1)';
    if (this == NULL_NSM_THEN_MAY) return 'null(1)+may';
    return 'NativeThrowBehavior($_bits)';
  }

  /// Canonical list of marker values.
  ///
  /// Added to make [NativeThrowBehavior] enum-like.
  static const List<NativeThrowBehavior> values = [
    NEVER,
    MAY,
    NULL_NSM,
    NULL_NSM_THEN_MAY,
  ];

  /// Index to this marker within [values].
  ///
  /// Added to make [NativeThrowBehavior] enum-like.
  int get index => values.indexOf(this);

  /// Deserializer helper.
  static NativeThrowBehavior bitsToValue(int bits) {
    switch (bits) {
      case 0:
        return NEVER;
      case 1:
        return MAY;
      case 2:
        return NULL_NSM;
      case 3:
        return NULL_NSM_THEN_MAY;
      default:
        throw StateError('Unknown serialized NativeThrowBehavior: $bits');
    }
  }

  int valueToBits() => _bits;

  /// Sequence operator.
  NativeThrowBehavior then(NativeThrowBehavior second) {
    if (this == NEVER) return second;
    if (this == MAY) return MAY;
    if (this == NULL_NSM_THEN_MAY) return NULL_NSM_THEN_MAY;
    assert(this == NULL_NSM);
    if (second == NEVER) return this;
    return NULL_NSM_THEN_MAY;
  }

  /// Choice operator.
  NativeThrowBehavior or(NativeThrowBehavior other) {
    if (this == other) return this;
    return MAY;
  }
}
