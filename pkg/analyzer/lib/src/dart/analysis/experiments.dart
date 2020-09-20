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

part 'experiments.g.dart';

/// Gets access to the private list of boolean flags in an [ExperimentStatus]
/// object. For testing use only.
@visibleForTesting
List<bool> getExperimentalFlags_forTesting(ExperimentStatus status) =>
    status._flags;

/// Gets access to the private SDK language version in an [ExperimentStatus]
/// object. For testing use only.
@visibleForTesting
Version getSdkLanguageVersion_forTesting(ExperimentStatus status) =>
    status._sdkLanguageVersion;

/// A representation of the set of experiments that are active and whether they
/// are enabled.
class ExperimentStatus with _CurrentState implements FeatureSet {
  /// The current language version.
  static final Version currentVersion = Version.parse(_currentVersion);

  /// The language version to use in tests.
  static final Version testingSdkLanguageVersion = Version.parse('2.10.0');

  /// The latest known language version.
  static final Version latestSdkLanguageVersion = Version.parse('2.10.0');

  static final FeatureSet latestWithNullSafety = ExperimentStatus.fromStrings2(
    sdkLanguageVersion: latestSdkLanguageVersion,
    flags: [EnableString.non_nullable],
  );

  /// A map containing information about all known experimental flags.
  static final Map<String, ExperimentalFeature> knownFeatures = _knownFeatures;

  final Version _sdkLanguageVersion;
  final List<bool> _explicitEnabledFlags;
  final List<bool> _explicitDisabledFlags;
  final List<bool> _flags;

  factory ExperimentStatus() {
    return ExperimentStatus.latestLanguageVersion();
  }

  /// Computes a set of features for use in a unit test.  Computes the set of
  /// features enabled in [sdkVersion], plus any specified [additionalFeatures].
  ///
  /// If [sdkVersion] is not supplied (or is `null`), then the current set of
  /// enabled features is used as the starting point.
  @visibleForTesting
  factory ExperimentStatus.forTesting(
      // ignore:avoid_unused_constructor_parameters
      {String sdkVersion,
      List<Feature> additionalFeatures = const []}) {
    var explicitFlags = decodeExplicitFlags([]);
    for (ExperimentalFeature feature in additionalFeatures) {
      explicitFlags.enabled[feature.index] = true;
    }

    var sdkLanguageVersion = latestSdkLanguageVersion;
    var flags = restrictEnableFlagsToVersion(
      sdkLanguageVersion: sdkLanguageVersion,
      explicitEnabledFlags: explicitFlags.enabled,
      explicitDisabledFlags: explicitFlags.disabled,
      version: sdkLanguageVersion,
    );

    return ExperimentStatus._(
      sdkLanguageVersion,
      explicitFlags.enabled,
      explicitFlags.disabled,
      flags,
    );
  }

  factory ExperimentStatus.fromStorage(List<int> encoded) {
    var allFlags = encoded.skip(2).map((e) => e != 0).toList();
    var featureCount = allFlags.length ~/ 3;
    return ExperimentStatus._(
      Version(encoded[0], encoded[1], 0),
      allFlags.sublist(0, featureCount),
      allFlags.sublist(featureCount, featureCount * 2),
      allFlags.sublist(featureCount * 2, featureCount * 3),
    );
  }

  /// Decodes the strings given in [flags] into a representation of the set of
  /// experiments that should be enabled.
  ///
  /// Always succeeds, even if the input flags are invalid.  Expired and
  /// unrecognized flags are ignored, conflicting flags are resolved in favor of
  /// the flag appearing last.
  factory ExperimentStatus.fromStrings(List<String> flags) {
    return ExperimentStatus.fromStrings2(
      sdkLanguageVersion: latestSdkLanguageVersion,
      flags: flags,
    );
  }

  /// Decodes the strings given in [flags] into a representation of the set of
  /// experiments that should be enabled.
  ///
  /// Always succeeds, even if the input flags are invalid.  Expired and
  /// unrecognized flags are ignored, conflicting flags are resolved in favor of
  /// the flag appearing last.
  factory ExperimentStatus.fromStrings2({
    @required Version sdkLanguageVersion,
    @required List<String> flags,
    // TODO(scheglov) use restrictEnableFlagsToVersion
  }) {
    var explicitFlags = decodeExplicitFlags(flags);

    var decodedFlags = restrictEnableFlagsToVersion(
      sdkLanguageVersion: sdkLanguageVersion,
      explicitEnabledFlags: explicitFlags.enabled,
      explicitDisabledFlags: explicitFlags.disabled,
      version: sdkLanguageVersion,
    );

    return ExperimentStatus._(
      sdkLanguageVersion,
      explicitFlags.enabled,
      explicitFlags.disabled,
      decodedFlags,
    );
  }

  factory ExperimentStatus.latestLanguageVersion() {
    return ExperimentStatus.fromStrings2(
      sdkLanguageVersion: latestSdkLanguageVersion,
      flags: [],
    );
  }

  ExperimentStatus._(
    this._sdkLanguageVersion,
    this._explicitEnabledFlags,
    this._explicitDisabledFlags,
    this._flags,
  );

  @override
  int get hashCode {
    int hash = 0;
    for (var flag in _flags) {
      hash = JenkinsSmiHash.combine(hash, flag.hashCode);
    }
    return JenkinsSmiHash.finish(hash);
  }

  @override
  bool operator ==(Object other) {
    if (other is ExperimentStatus) {
      if (_sdkLanguageVersion != other._sdkLanguageVersion) {
        return false;
      }
      if (!_equalListOfBool(
          _explicitEnabledFlags, other._explicitEnabledFlags)) {
        return false;
      }
      if (!_equalListOfBool(
          _explicitDisabledFlags, other._explicitDisabledFlags)) {
        return false;
      }
      if (!_equalListOfBool(_flags, other._flags)) {
        return false;
      }
      return true;
    }
    return false;
  }

  /// Queries whether the given [feature] is enabled or disabled.
  @override
  bool isEnabled(covariant ExperimentalFeature feature) =>
      _flags[feature.index];

  @override
  FeatureSet restrictToVersion(Version version) {
    return ExperimentStatus._(
      _sdkLanguageVersion,
      _explicitEnabledFlags,
      _explicitDisabledFlags,
      restrictEnableFlagsToVersion(
        sdkLanguageVersion: _sdkLanguageVersion,
        explicitEnabledFlags: _explicitEnabledFlags,
        explicitDisabledFlags: _explicitDisabledFlags,
        version: version,
      ),
    );
  }

  /// Encode into the format suitable for [ExperimentStatus.fromStorage].
  List<int> toStorage() {
    return [
      _sdkLanguageVersion.major,
      _sdkLanguageVersion.minor,
      ..._explicitEnabledFlags.map((e) => e ? 1 : 0),
      ..._explicitDisabledFlags.map((e) => e ? 1 : 0),
      ..._flags.map((e) => e ? 1 : 0),
    ];
  }

  @override
  String toString() => experimentStatusToString(_flags);

  static bool _equalListOfBool(List<bool> first, List<bool> second) {
    if (first.length != second.length) return false;
    for (var i = 0; i < first.length; i++) {
      if (first[i] != second[i]) return false;
    }
    return true;
  }
}
