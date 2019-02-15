// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Note: the plan is to generate this file from a YAML representation somewhere
// in the SDK repo.  Please do not add any code to this file that can't be
// easily code generated based on a knowledge of the current set of experimental
// flags and their status.
// TODO(paulberry,kmillikin): once code generation is implemented, replace this
// notice with a notice that this file is generated and a pointer to the source
// YAML file and the regeneration tool.

// Note: to demonstrate how code is supposed to be generated for expired flags,
// this file contains bogus expired flags called "bogus-enabled" and
// "bogus-disabled".  They are not used and can be removed at the time that code
// generation is implemented.

import 'package:analyzer/src/dart/analysis/experiments_impl.dart';
import 'package:meta/meta.dart';

export 'package:analyzer/src/dart/analysis/experiments_impl.dart'
    show
        ConflictingFlags,
        ExperimentalFeature,
        IllegalUseOfExpiredFlag,
        UnnecessaryUseOfExpiredFlag,
        UnrecognizedFlag,
        validateFlags,
        ValidationResult;

/// Gets access to the private list of boolean flags in an [Experiments] object.
/// For testing use only.
@visibleForTesting
List<bool> getExperimentalFlags_forTesting(ExperimentStatus status) =>
    status._enableFlags;

/// Constant strings for enabling each of the currently known experimental
/// flags.
class EnableString {
  /// String to enable the experiment "constant-update"
  static const String constant_update_2018 = 'constant-update-2018';

  /// String to enable the experiment "control-flow-collections"
  static const String control_flow_collections = 'control-flow-collections';

  /// String to enable the experiment "non-nullable"
  static const String non_nullable = 'non-nullable';

  /// String to enable the experiment "set-literals"
  static const String set_literals = 'set-literals';

  /// String to enable the experiment "spread-collections"
  static const String spread_collections = 'spread-collections';

  /// String to enable the experiment "bogus-disabled"
  static const String bogus_disabled = 'bogus-disabled';

  /// String to enable the experiment "bogus-enabled"
  static const String bogus_enabled = 'bogus-enabled';
}

/// A representation of the set of experiments that are active and whether they
/// are enabled.
class ExperimentStatus {
  /// A map containing information about all known experimental flags.
  static const knownFeatures = <String, ExperimentalFeature>{
    EnableString.constant_update_2018: const ExperimentalFeature(
        0,
        EnableString.constant_update_2018,
        IsEnabledByDefault.constant_update_2018,
        IsExpired.constant_update_2018,
        'Q4 2018 Constant Update'),
    EnableString.non_nullable: const ExperimentalFeature(
        1,
        EnableString.non_nullable,
        IsEnabledByDefault.non_nullable,
        IsExpired.non_nullable,
        'Non Nullable'),
    EnableString.control_flow_collections: const ExperimentalFeature(
        2,
        EnableString.control_flow_collections,
        IsEnabledByDefault.control_flow_collections,
        IsExpired.control_flow_collections,
        'Control Flow Collections'),
    EnableString.spread_collections: const ExperimentalFeature(
        3,
        EnableString.spread_collections,
        IsEnabledByDefault.spread_collections,
        IsExpired.spread_collections,
        'Spread Collections'),
    EnableString.set_literals: const ExperimentalFeature(
        null,
        EnableString.set_literals,
        IsEnabledByDefault.set_literals,
        IsExpired.set_literals,
        'Set Literals'),
    EnableString.bogus_disabled: const ExperimentalFeature(
        null,
        EnableString.bogus_disabled,
        IsEnabledByDefault.bogus_disabled,
        IsExpired.bogus_disabled,
        null),
    EnableString.bogus_enabled: const ExperimentalFeature(
        null,
        EnableString.bogus_enabled,
        IsEnabledByDefault.bogus_enabled,
        IsExpired.bogus_enabled,
        null),
  };

  final List<bool> _enableFlags;

  /// Initializes a newly created set of experiments based on optional
  /// arguments.
  ExperimentStatus(
      {bool constant_update_2018,
      bool control_flow_collections,
      bool non_nullable,
      bool set_literals,
      bool spread_collections})
      : _enableFlags = <bool>[
          constant_update_2018 ?? IsEnabledByDefault.constant_update_2018,
          non_nullable ?? IsEnabledByDefault.non_nullable,
          control_flow_collections ??
              IsEnabledByDefault.control_flow_collections,
          spread_collections ?? IsEnabledByDefault.spread_collections,
        ];

  /// Decodes the strings given in [flags] into a representation of the set of
  /// experiments that should be enabled.
  ///
  /// Always succeeds, even if the input flags are invalid.  Expired and
  /// unrecognized flags are ignored, conflicting flags are resolved in favor of
  /// the flag appearing last.
  ExperimentStatus.fromStrings(List<String> flags) : this._(decodeFlags(flags));

  ExperimentStatus._(this._enableFlags);

  /// Hardcoded state for the expired flag "bogus_disabled"
  bool get bogus_disabled => false;

  /// Hardcoded state for the expired flag "bogus_enabled"
  bool get bogus_enabled => true;

  /// Current state for the flag "constant-update-2018"
  bool get constant_update_2018 => _enableFlags[0];

  /// Current state for the flag "control_flow_collections"
  bool get control_flow_collections => _enableFlags[2];

  /// Current state for the flag "non-nullable"
  bool get non_nullable => _enableFlags[1];

  /// Current state for the flag "set-literals"
  bool get set_literals => true;

  /// Current state for the flag "spread_collections"
  bool get spread_collections => _enableFlags[3];

  /// Queries whether the given [feature] is enabled or disabled.
  bool isEnabled(ExperimentalFeature feature) => feature.isExpired
      ? feature.isEnabledByDefault
      : _enableFlags[feature.index];

  /// Returns a list of strings suitable for passing to
  /// [ExperimentStatus.fromStrings].
  List<String> toStringList() => experimentStatusToStringList(this);
}

/// Constant bools indicating whether each experimental flag is currently
/// enabled by default.
class IsEnabledByDefault {
  /// Default state of the experiment "constant-update"
  static const bool constant_update_2018 = false;

  /// Default state of the experiment "control-flow-collections"
  static const bool control_flow_collections = false;

  /// Default state of the experiment "non-nullable"
  static const bool non_nullable = false;

  /// Default state of the experiment "set-literals"
  static const bool set_literals = true;

  /// Default state of the experiment "spread-collections"
  static const bool spread_collections = false;

  /// Default state of the experiment "bogus-disabled"
  static const bool bogus_disabled = false;

  /// Default state of the experiment "bogus-enabled"
  static const bool bogus_enabled = true;
}

/// Constant bools indicating whether each experimental flag is currently
/// expired (meaning its enable/disable status can no longer be altered from the
/// value in [IsEnabledByDefault]).
class IsExpired {
  /// Expiration status of the experiment "constant-update"
  static const bool constant_update_2018 = false;

  /// Expiration status of the experiment "control-flow-collections"
  static const bool control_flow_collections = false;

  /// Expiration status of the experiment "non-nullable"
  static const bool non_nullable = false;

  /// Expiration status of the experiment "set-literals"
  static const bool set_literals = true;

  /// Expiration status of the experiment "spread-collections"
  static const bool spread_collections = false;

  /// Expiration status of the experiment "bogus-disabled"
  static const bool bogus_disabled = true;

  /// Expiration status of the experiment "bogus-enabled"
  static const bool bogus_enabled = true;
}
