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

/// A state that marks a lint as deprecated.
final class DeprecatedState extends State {
  /// An optional lint name that replaces the rule with this state.
  final String? replacedBy;

  /// Initialize a newly created deprecated state with given values.
  const DeprecatedState._({super.since, this.replacedBy});

  @override
  String get label => 'deprecated';
}

/// A state that marks a lint as experimental.
final class ExperimentalState extends State {
  /// Initialize a newly created experimental state with given values.
  const ExperimentalState._({super.since});

  @override
  String get label => 'experimental';
}

/// A state that marks a lint as for internal (Dart SDK) use only.
final class InternalState extends State {
  /// Initialize a newly created internal state with given values.
  const InternalState._({super.since});

  @override
  String get label => 'internal';
}

/// A state that identifies a lint as having been removed.
final class RemovedState extends State {
  /// An optional lint name that replaces the rule with this state.
  final String? replacedBy;

  /// Initialize a newly created removed state with given values.
  const RemovedState._({super.since, this.replacedBy});

  @override
  String get label => 'removed';
}

/// A state that marks a lint as stable.
final class StableState extends State {
  /// Initialize a newly created stable state with given values.
  const StableState._({super.since});

  @override
  String get label => 'stable';
}

/// Describes the state of a lint.
sealed class State {
  /// An Optional Dart language version that identifies the start of this state.
  final Version? since;

  /// Initialize a newly created State object.
  const State({this.since});

  /// Initialize a newly created deprecated state with given values.
  const factory State.deprecated({Version? since, String? replacedBy}) =
      DeprecatedState._;

  /// Initialize a newly created experimental state with given values.
  const factory State.experimental({Version? since}) = ExperimentalState._;

  /// Initialize a newly created internal state with given values.
  const factory State.internal({Version? since}) = InternalState._;

  /// Initialize a newly created removed state with given values.
  const factory State.removed({Version? since, String? replacedBy}) =
      RemovedState._;

  /// Initialize a newly created stable state with given values.
  const factory State.stable({Version? since}) = StableState._;

  /// A short description, suitable for displaying in documentation or a
  /// diagnostic message.
  String get label;

  /// An optional description that can be used in documentation or diagnostic
  /// reporting.
  @Deprecated('Not set by any lint rule, remove any usages.')
  String? getDescription() => null;
}

extension StateExtension on State {
  bool get isDeprecated => this is DeprecatedState;
  bool get isExperimental => this is ExperimentalState;
  bool get isInternal => this is InternalState;
  bool get isRemoved => this is RemovedState;
  bool get isStable => this is StableState;
}
