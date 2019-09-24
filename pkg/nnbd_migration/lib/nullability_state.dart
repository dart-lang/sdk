// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// State of a nullability node.
class NullabilityState {
  /// State of a nullability node whose nullability hasn't been decided yet.
  static const undetermined = NullabilityState._('undetermined', false);

  /// State of a nullability node that has been determined to be non-nullable
  /// by propagating upstream.
  static const nonNullable = NullabilityState._('non-nullable', false);

  /// State of a nullability node that has been determined to be nullable by
  /// propagating downstream.
  static const ordinaryNullable = NullabilityState._('ordinary nullable', true);

  /// State of a nullability node that has been determined to be nullable by
  /// propagating upstream from a contravariant use of a generic.
  static const exactNullable = NullabilityState._('exact nullable', true);

  /// Name of the state (for use in debugging).
  final String name;

  /// Indicates whether the given state should be considered nullable.
  ///
  /// After propagation, any nodes that remain in the undetermined state are
  /// considered to be non-nullable, so this field is returns `false` for nodes
  /// in that state.
  final bool isNullable;

  const NullabilityState._(this.name, this.isNullable);

  @override
  String toString() => name;
}
