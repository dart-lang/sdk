// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Description of the exception behaviour of native code.
enum NativeThrowBehavior {
  never,
  may,

  /// Throws only if first argument is null.
  nullNsm,

  /// Throws if first argument is null, then may throw.
  nullNsmThenMay,
  ;

  bool get canThrow => this != never;

  /// Does this behavior always throw a noSuchMethod check on a null first
  /// argument before any side effect or other exception?
  bool get isNullNSMGuard => this == nullNsm || this == nullNsmThenMay;

  /// Does this behavior always act as a null noSuchMethod check, and has no
  /// other throwing behavior?
  bool get isOnlyNullNSMGuard => this == nullNsm;

  /// Returns the behavior if we assume the first argument is not null.
  NativeThrowBehavior get onNonNull {
    if (this == nullNsm) return never;
    if (this == nullNsmThenMay) return may;
    return this;
  }

  @override
  String toString() {
    if (this == never) return 'never';
    if (this == may) return 'may';
    if (this == nullNsm) return 'null(1)';
    if (this == nullNsmThenMay) return 'null(1)+may';
    return 'NativeThrowBehavior($index)';
  }

  /// Sequence operator.
  NativeThrowBehavior then(NativeThrowBehavior second) {
    if (this == never) return second;
    if (this == may) return may;
    if (this == nullNsmThenMay) return nullNsmThenMay;
    assert(this == nullNsm);
    if (second == never) return this;
    return nullNsmThenMay;
  }

  /// Choice operator.
  NativeThrowBehavior or(NativeThrowBehavior other) {
    if (this == other) return this;
    return may;
  }
}
