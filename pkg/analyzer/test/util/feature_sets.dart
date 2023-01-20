// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:pub_semver/pub_semver.dart';

class FeatureSets {
  static final FeatureSet language_2_3 = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: Version.parse('2.3.0'),
    flags: [],
  );

  static final FeatureSet language_2_9 = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: Version.parse('2.9.0'),
    flags: [],
  );

  static final FeatureSet language_2_12 = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: Version.parse('2.12.0'),
    flags: [],
  );

  static final FeatureSet language_2_13 = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: Version.parse('2.13.0'),
    flags: [],
  );

  static final FeatureSet language_2_16 = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: Version.parse('2.16.0'),
    flags: [],
  );

  static final FeatureSet language_2_18 = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: Version.parse('2.18.0'),
    flags: [],
  );

  static final FeatureSet language_2_19 = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: Version.parse('2.19.0'),
    flags: [],
  );

  static final FeatureSet latest = FeatureSet.latestLanguageVersion();

  static final FeatureSet latestWithExperiments = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: ExperimentStatus.currentVersion,
    flags: [
      Feature.class_modifiers.enableString,
      Feature.extension_types.enableString,
      Feature.inline_class.enableString,
      Feature.macros.enableString,
      Feature.patterns.enableString,
      Feature.records.enableString,
      Feature.sealed_class.enableString,
    ],
  );

  static final FeatureSet latestWithVariance = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: ExperimentStatus.currentVersion,
    flags: [
      Feature.variance.enableString,
    ],
  );

  FeatureSets._();
}
