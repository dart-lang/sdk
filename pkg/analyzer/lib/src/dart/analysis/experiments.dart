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

/// Gets access to the private list of boolean flags in an [Experiments] object.
/// For testing use only.
@visibleForTesting
List<bool> getExperimentalFlags_forTesting(ExperimentStatus status) =>
    status._enableFlags;

/// A representation of the set of experiments that are active and whether they
/// are enabled.
class ExperimentStatus with _CurrentState implements FeatureSet {
  /// The current language version.
  static final Version currentVersion = Version.parse(_currentVersion);

  /// A map containing information about all known experimental flags.
  static const Map<String, ExperimentalFeature> knownFeatures = _knownFeatures;

  final List<bool> _enableFlags;

  /// Initializes a newly created set of experiments based on optional
  /// arguments.
  ExperimentStatus() : _enableFlags = _buildExperimentalFlagsArray();

  /// Computes a set of features for use in a unit test.  Computes the set of
  /// features enabled in [sdkVersion], plus any specified [additionalFeatures].
  ///
  /// If [sdkVersion] is not supplied (or is `null`), then the current set of
  /// enabled features is used as the starting point.
  @visibleForTesting
  ExperimentStatus.forTesting(
      {String sdkVersion, List<Feature> additionalFeatures = const []})
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

  @override
  int get hashCode {
    int hash = 0;
    for (var flag in _enableFlags) {
      hash = JenkinsSmiHash.combine(hash, flag.hashCode);
    }
    return JenkinsSmiHash.finish(hash);
  }

  @override
  bool operator ==(Object other) {
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
