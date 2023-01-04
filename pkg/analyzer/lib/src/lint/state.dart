// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pub_semver/pub_semver.dart';

/// A version describing Dart 3.0.0.
final Version dart3 = Version(3, 0, 0);

/// A state that marks a lint as deprecated.
class DeprecatedState extends State {
  /// An optional lint name that replaces the rule with this state.
  final String? replacedBy;

  /// Initialize a newly created deprecated state with given values.
  const DeprecatedState({super.since, this.replacedBy})
      : super(label: 'deprecated');
}

/// A state that marks a lint as experimental.
class ExperimentalState extends State {
  /// Initialize a newly created experimental state with given values.
  const ExperimentalState({super.since}) : super(label: 'experimental');
}

/// A state that identifies a lint as having been removed.
class RemovedState extends State {
  /// An optional lint name that replaces the rule with this state.
  final String? replacedBy;

  /// Initialize a newly created removed state with given values.
  const RemovedState({required super.since, this.replacedBy})
      : super(label: 'removed');
}

/// A state that marks a lint as stable.
class StableState extends State {
  /// Initialize a newly created stable state with given values.
  const StableState({super.since}) : super(label: 'stable');
}

/// Describes the state of a lint.
abstract class State {
  /// A sentinel for a state that is 'unknown'.
  static const State unknown = UnknownState();

  /// An Optional Dart SDK version that identifies the start of this state.
  final Version? since;

  /// A short description, suitable for displaying in documentation or a
  /// diagnostic message.
  final String label;

  /// Initialize a newly created State object.
  const State({required this.label, this.since});

  /// Initialize a newly created deprecated state with given values.
  factory State.deprecated({Version? since, String? replacedBy}) =>
      DeprecatedState(since: since, replacedBy: replacedBy);

  /// Initialize a newly created experimental state with given values.
  factory State.experimental({Version? since}) =>
      ExperimentalState(since: since);

  /// Initialize a newly created removed state with given values.
  factory State.removed({required Version since, String? replacedBy}) =>
      RemovedState(since: since, replacedBy: replacedBy);

  /// Initialize a newly created stable state with given values.
  factory State.stable({Version? since}) => StableState(since: since);

  /// An optional description that can be used in documentation or diagnostic
  /// reporting.
  String? getDescription() => null;
}

/// A state that is unknown.
class UnknownState extends State {
  /// Initialize a newly created unknown state.
  const UnknownState() : super(label: 'unknown');
}

extension StateExtension on State {
  bool get isDeprecated => this is DeprecatedState;
  bool get isExperimental => this is ExperimentalState;
  bool get isRemoved => this is RemovedState;
  bool get isStable => this is StableState;
}
