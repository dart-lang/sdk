// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments_impl.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/src/version.dart';

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

  /// String to enable the experiment "triple-shift"
  static const String triple_shift = 'triple-shift';

  /// String to enable the experiment "bogus-disabled"
  static const String bogus_disabled = 'bogus-disabled';

  /// String to enable the experiment "bogus-enabled"
  static const String bogus_enabled = 'bogus-enabled';
}

class ExperimentalFeatures {
  static const constant_update_2018 = const ExperimentalFeature(
      0,
      EnableString.constant_update_2018,
      IsEnabledByDefault.constant_update_2018,
      IsExpired.constant_update_2018,
      'Q4 2018 Constant Update');

  static const non_nullable = const ExperimentalFeature(
      1,
      EnableString.non_nullable,
      IsEnabledByDefault.non_nullable,
      IsExpired.non_nullable,
      'Non Nullable');

  static const control_flow_collections = const ExperimentalFeature(
      2,
      EnableString.control_flow_collections,
      IsEnabledByDefault.control_flow_collections,
      IsExpired.control_flow_collections,
      'Control Flow Collections',
      firstSupportedVersion: '2.2.2');

  static const spread_collections = const ExperimentalFeature(
      3,
      EnableString.spread_collections,
      IsEnabledByDefault.spread_collections,
      IsExpired.spread_collections,
      'Spread Collections',
      firstSupportedVersion: '2.2.2');

  static const set_literals = const ExperimentalFeature(
      4,
      EnableString.set_literals,
      IsEnabledByDefault.set_literals,
      IsExpired.set_literals,
      'Set Literals',
      firstSupportedVersion: '2.2.0');

  static const triple_shift = const ExperimentalFeature(
      5,
      EnableString.triple_shift,
      IsEnabledByDefault.triple_shift,
      IsExpired.triple_shift,
      'Triple-shift operator');

  static const bogus_disabled = const ExperimentalFeature(
      6,
      EnableString.bogus_disabled,
      IsEnabledByDefault.bogus_disabled,
      IsExpired.bogus_disabled,
      null);

  static const bogus_enabled = const ExperimentalFeature(
      7,
      EnableString.bogus_enabled,
      IsEnabledByDefault.bogus_enabled,
      IsExpired.bogus_enabled,
      null,
      firstSupportedVersion: '1.0.0');
}

/// A representation of the set of experiments that are active and whether they
/// are enabled.
class ExperimentStatus implements FeatureSet {
  /// A map containing information about all known experimental flags.
  static const knownFeatures = <String, ExperimentalFeature>{
    EnableString.constant_update_2018:
        ExperimentalFeatures.constant_update_2018,
    EnableString.non_nullable: ExperimentalFeatures.non_nullable,
    EnableString.control_flow_collections:
        ExperimentalFeatures.control_flow_collections,
    EnableString.spread_collections: ExperimentalFeatures.spread_collections,
    EnableString.set_literals: ExperimentalFeatures.set_literals,
    EnableString.triple_shift: ExperimentalFeatures.triple_shift,
    EnableString.bogus_disabled: ExperimentalFeatures.bogus_disabled,
    EnableString.bogus_enabled: ExperimentalFeatures.bogus_enabled,
  };

  final List<bool> _enableFlags;

  /// Initializes a newly created set of experiments based on optional
  /// arguments.
  ExperimentStatus(
      {bool constant_update_2018,
      bool control_flow_collections,
      bool non_nullable,
      bool set_literals,
      bool spread_collections,
      bool triple_shift})
      : _enableFlags = <bool>[
          constant_update_2018 ?? IsEnabledByDefault.constant_update_2018,
          non_nullable ?? IsEnabledByDefault.non_nullable,
          true, // control-flow-collections
          true, // spread-collections
          true, // set-literals
          triple_shift ?? IsEnabledByDefault.triple_shift,
          false, // bogus-disabled
          true, // bogus-enabled
        ];

  /// Computes a set of features for use in a unit test.  Computes the set of
  /// features enabled in [sdkVersion], plus any specified [additionalFeatures].
  ///
  /// If [sdkVersion] is not supplied (or is `null`), then the current set of
  /// enabled features is used as the starting point.
  @visibleForTesting
  ExperimentStatus.forTesting(
      {String sdkVersion, List<Feature> additionalFeatures: const []})
      : this._(enableFlagsForTesting(
            sdkVersion: sdkVersion, additionalFeatures: additionalFeatures));

  /// Decodes the strings given in [flags] into a representation of the set of
  /// experiments that should be enabled.
  ///
  /// Always succeeds, even if the input flags are invalid.  Expired and
  /// unrecognized flags are ignored, conflicting flags are resolved in favor of
  /// the flag appearing last.
  ExperimentStatus.fromStrings(List<String> flags) : this._(decodeFlags(flags));

  ExperimentStatus._(this._enableFlags);

  /// Current state for the flag "bogus_disabled"
  bool get bogus_disabled => isEnabled(ExperimentalFeatures.bogus_disabled);

  /// Current state for the flag "bogus_enabled"
  bool get bogus_enabled => isEnabled(ExperimentalFeatures.bogus_enabled);

  /// Current state for the flag "constant-update-2018"
  bool get constant_update_2018 =>
      isEnabled(ExperimentalFeatures.constant_update_2018);

  /// Current state for the flag "control_flow_collections"
  bool get control_flow_collections =>
      isEnabled(ExperimentalFeatures.control_flow_collections);

  @override
  int get hashCode {
    int hash = 0;
    for (var flag in _enableFlags) {
      hash = JenkinsSmiHash.combine(hash, flag.hashCode);
    }
    return JenkinsSmiHash.finish(hash);
  }

  /// Current state for the flag "non-nullable"
  bool get non_nullable => isEnabled(ExperimentalFeatures.non_nullable);

  /// Current state for the flag "set-literals"
  bool get set_literals => isEnabled(ExperimentalFeatures.set_literals);

  /// Current state for the flag "spread_collections"
  bool get spread_collections =>
      isEnabled(ExperimentalFeatures.spread_collections);

  /// Current state for the flag "triple_shift"
  bool get triple_shift => isEnabled(ExperimentalFeatures.triple_shift);

  @override
  operator ==(Object other) {
    if (other is ExperimentStatus) {
      if (_enableFlags.length != other._enableFlags.length) return false;
      for (int i = 0; i < _enableFlags.length; i++) {
        if (_enableFlags[i] != other._enableFlags[i]) return false;
      }
      return true;
    }
    return false;
  }

  /// Queries whether the given [feature] is enabled or disabled.
  @override
  bool isEnabled(covariant ExperimentalFeature feature) =>
      _enableFlags[feature.index];

  @override
  FeatureSet restrictToVersion(Version version) =>
      ExperimentStatus._(restrictEnableFlagsToVersion(_enableFlags, version));

  @override
  String toString() => experimentStatusToString(_enableFlags);

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
  static const bool control_flow_collections = true;

  /// Default state of the experiment "non-nullable"
  static const bool non_nullable = false;

  /// Default state of the experiment "set-literals"
  static const bool set_literals = true;

  /// Default state of the experiment "spread-collections"
  static const bool spread_collections = true;

  /// Default state of the experiment "triple-shift"
  static const bool triple_shift = false;

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
  static const bool control_flow_collections = true;

  /// Expiration status of the experiment "non-nullable"
  static const bool non_nullable = false;

  /// Expiration status of the experiment "set-literals"
  static const bool set_literals = true;

  /// Expiration status of the experiment "spread-collections"
  static const bool spread_collections = true;

  /// Expiration status of the experiment "triple-shift"
  static const bool triple_shift = false;

  /// Expiration status of the experiment "bogus-disabled"
  static const bool bogus_disabled = true;

  /// Expiration status of the experiment "bogus-enabled"
  static const bool bogus_enabled = true;
}
