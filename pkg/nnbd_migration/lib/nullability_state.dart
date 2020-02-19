// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// State representation used to determine whether a nullability node expresses
/// non-null intent.
class NonNullIntent {
  /// State of a nullability node for which no non-null intent has been seen.
  static const none = NonNullIntent._('none', false);

  /// State of a nullability node for which indirect evidence of non-null intent
  /// has been seen (e.g. an assertion or a use of a value in a non-null
  /// context).
  static const indirect = NonNullIntent._('indirect', true);

  /// State of a nullability node for which direct evidence of non-null intent
  /// has been seen (e.g. an explicit "/*!*/" on a type, or a non-nullable type
  /// coming from a migrated library).
  static const direct = NonNullIntent._('direct', true, isDirect: true);

  final String name;

  /// Indicates whether this state represents a determination that non-null
  /// intent is present.
  final bool isPresent;

  /// Indicates whether this state represents a direct determination of non-null
  /// intent (see [direct]).
  final bool isDirect;

  factory NonNullIntent.fromJson(dynamic json) {
    switch (json as String) {
      case 'none':
        return none;
      case 'indirect':
        return indirect;
      case 'direct':
        return direct;
      default:
        throw StateError('Unrecognized nullability $json');
    }
  }

  const NonNullIntent._(this.name, this.isPresent, {this.isDirect = false});

  /// Returns a [NonNullIntent] object representing the result of adding
  /// indirect non-null intent to `this`.
  NonNullIntent addIndirect() => isPresent ? this : indirect;

  String toJson() => name;

  @override
  String toString() => name;
}

/// State of a nullability node.
class Nullability {
  /// State of a nullability node that has been determined to be non-nullable
  /// by propagating upstream.
  static const nonNullable = Nullability._('non-nullable', false);

  /// State of a nullability node that has been determined to be nullable by
  /// propagating downstream.
  static const ordinaryNullable = Nullability._('ordinary nullable', true);

  /// State of a nullability node that has been determined to be nullable by
  /// propagating upstream from a contravariant use of a generic.
  static const exactNullable =
      Nullability._('exact nullable', true, isExactNullable: true);

  /// Name of the state (for use in debugging).
  final String name;

  /// Indicates whether the given state should be considered nullable.
  ///
  /// After propagation, any nodes that remain in the undetermined state are
  /// considered to be non-nullable, so this field is returns `false` for nodes
  /// in that state.
  final bool isNullable;

  /// Indicates whether a node in this state is "exact nullable", meaning that
  /// is needs to be nullable because it represents a type argument that will
  /// later be used in a contravariant way that requires it to be nullable.
  final bool isExactNullable;

  factory Nullability.fromJson(dynamic json) {
    switch (json as String) {
      case 'non-nullable':
        return nonNullable;
      case 'ordinary nullable':
        return ordinaryNullable;
      case 'exact nullable':
        return exactNullable;
      default:
        throw StateError('Unrecognized nullability $json');
    }
  }

  const Nullability._(this.name, this.isNullable,
      {this.isExactNullable = false});

  String toJson() => name;

  @override
  String toString() => name;
}
