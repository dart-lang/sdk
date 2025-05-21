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

@Deprecated("Prefer to use 'RuleState'")
typedef State = RuleState;

/// A state that marks an analysis rule as deprecated.
final class DeprecatedRuleState extends RuleState {
  /// The optional name of an analysis rule which replaces the rule with this
  /// state.
  final String? replacedBy;

  const DeprecatedRuleState._({super.since, this.replacedBy});

  @override
  String get label => 'deprecated';
}

/// A state that marks an analysis rule as experimental.
final class ExperimentalRuleState extends RuleState {
  const ExperimentalRuleState._({super.since});

  @override
  String get label => 'experimental';
}

/// A state that marks an analysis rule as for internal (Dart SDK) use only.
final class InternalRuleState extends RuleState {
  const InternalRuleState._({super.since});

  @override
  String get label => 'internal';
}

/// A state that identifies an analysis rule as having been removed.
final class RemovedRuleState extends RuleState {
  /// An optional lint name that replaces the rule with this state.
  final String? replacedBy;

  const RemovedRuleState._({super.since, this.replacedBy});

  @override
  String get label => 'removed';
}

/// Describes the state of a lint.
sealed class RuleState {
  /// An Optional Dart language version that identifies the start of this state.
  final Version? since;

  /// Initialize a newly created State object.
  const RuleState({this.since});

  /// Initialize a newly created deprecated state with given values.
  const factory RuleState.deprecated({Version? since, String? replacedBy}) =
      DeprecatedRuleState._;

  /// Initialize a newly created experimental state with given values.
  const factory RuleState.experimental({Version? since}) =
      ExperimentalRuleState._;

  /// Initialize a newly created internal state with given values.
  const factory RuleState.internal({Version? since}) = InternalRuleState._;

  /// Initialize a newly created removed state with given values.
  const factory RuleState.removed({Version? since, String? replacedBy}) =
      RemovedRuleState._;

  /// Initialize a newly created stable state with given values.
  const factory RuleState.stable({Version? since}) = StableRuleState._;

  /// A short description, suitable for displaying in documentation or a
  /// diagnostic message.
  String get label;
}

/// A state that marks an analysis rule as stable.
final class StableRuleState extends RuleState {
  const StableRuleState._({super.since});

  @override
  String get label => 'stable';
}

extension StateExtension on RuleState {
  bool get isDeprecated => this is DeprecatedRuleState;
  bool get isExperimental => this is ExperimentalRuleState;
  bool get isInternal => this is InternalRuleState;
  bool get isRemoved => this is RemovedRuleState;
  bool get isStable => this is StableRuleState;
}
