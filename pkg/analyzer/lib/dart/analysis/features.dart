// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

/// Information about a single language feature whose presence or absence
/// depends on the supported Dart SDK version, and possibly on the presence of
/// experimental flags.
abstract class Feature {
  /// Feature information for the 2018 constant update.
  static const constant_update_2018 = ExperimentalFeatures.constant_update_2018;

  /// Feature information for non-nullability by default.
  static const non_nullable = ExperimentalFeatures.non_nullable;

  /// Feature information for control flow collections.
  static const control_flow_collections =
      ExperimentalFeatures.control_flow_collections;

  /// Feature information for spread collections.
  static const spread_collections = ExperimentalFeatures.spread_collections;

  /// Feature information for set literals.
  static const set_literals = ExperimentalFeatures.set_literals;

  /// Feature information for the triple-shift operator.
  static const triple_shift = ExperimentalFeatures.triple_shift;

  /// If the feature may be enabled or disabled on the command line, the
  /// experimental flag that may be used to enable it.  Otherwise `null`.
  ///
  /// Should be `null` if [status] is `current` or `abandoned`.
  String get experimentalFlag;

  /// If [status] is not `future`, the first version of the Dart SDK in which
  /// the given feature was supported.  Otherwise `null`.
  Version get firstSupportedVersion;

  /// The status of the feature.
  FeatureStatus get status;
}

/// An unordered collection of [Feature] objects.
abstract class FeatureSet {
  /// Computes a set of features for use in a unit test.  Computes the set of
  /// features enabled in [sdkVersion], plus any specified [additionalFeatures].
  ///
  /// If [sdkVersion] is not supplied (or is `null`), then the current set of
  /// enabled features is used as the starting point.
  @visibleForTesting
  factory FeatureSet.forTesting(
          {String sdkVersion, List<Feature> additionalFeatures}) =
      // ignore: invalid_use_of_visible_for_testing_member
      ExperimentStatus.forTesting;

  /// Computes the set of features implied by the given set of experimental
  /// enable flags.
  factory FeatureSet.fromEnableFlags(List<String> flags) =
      ExperimentStatus.fromStrings;

  /// Queries whether the given [feature] is contained in this feature set.
  bool isEnabled(Feature feature);

  /// Computes a subset of this FeatureSet by removing any features that weren't
  /// available in the given Dart SDK version.
  FeatureSet restrictToVersion(Version version);
}

/// Information about the status of a language feature.
enum FeatureStatus {
  /// The language feature has not yet shipped.  It may not be used unless an
  /// experimental flag is used to enable it.
  future,

  /// The language feature has not yet shipped, but we are testing the effect of
  /// enabling it by default.  It may be used in any library with an appopriate
  /// version constraint, unless an experimental flag is used to disable it.
  provisional,

  /// The language feature has been shipped.  It may be used in any library with
  /// an appropriate version constraint.
  current,

  /// The language feature is no longer planned.  It may not be used.
  abandoned,
}
