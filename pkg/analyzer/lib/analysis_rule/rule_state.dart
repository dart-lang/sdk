// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pub_semver/pub_semver.dart';

/// A version describing Dart language version 2.12.0.
final Version dart2_12 = Version(2, 12, 0);

/// A version describing Dart language version 3.0.0.
final Version dart3 = Version(3, 0, 0);

/// A version describing Dart language version 3.3.0.
final Version dart3_3 = Version(3, 3, 0);

/// Describes the state of an analysis rule.
final class RuleState {
  /// An Optional Dart language version that identifies the start of this state.
  final Version? since;

  final _RuleStateType _type;

  /// The optional name of an analysis rule which replaces the rule with this
  /// state.
  final String? replacedBy;

  /// Initializes a state that marks an analysis rule as deprecated.
  const RuleState.deprecated({this.since, this.replacedBy})
    : _type = _RuleStateType.deprecated;

  /// Initializes a state that marks an analysis rule as experimental.
  const RuleState.experimental({this.since})
    : _type = _RuleStateType.experimental,
      replacedBy = null;

  /// Initializes a state that marks an analysis rule as for internal (Dart SDK)
  /// use only.
  const RuleState.internal({this.since})
    : _type = _RuleStateType.internal,
      replacedBy = null;

  /// Initializes a state that identifies an analysis rule as having been removed.
  const RuleState.removed({this.since, this.replacedBy})
    : _type = _RuleStateType.removed;

  /// Initializes a state that marks an analysis rule as stable.
  const RuleState.stable({this.since})
    : _type = _RuleStateType.stable,
      replacedBy = null;

  /// Whether this state marks an analysis rule as deprecated.
  bool get isDeprecated => _type == _RuleStateType.deprecated;

  /// Whether this state marks an analysis rule as experimental.
  bool get isExperimental => _type == _RuleStateType.experimental;

  /// Whether this state marks an analysis rule as internal.
  bool get isInternal => _type == _RuleStateType.internal;

  /// Whether this state marks an analysis rule as removed.
  bool get isRemoved => _type == _RuleStateType.removed;

  /// A short description, suitable for displaying in documentation or a
  /// diagnostic message.
  String get label => _type.name;
}

/// The type of a rule state.
enum _RuleStateType { deprecated, experimental, internal, removed, stable }
