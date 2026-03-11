// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart'
    show ExperimentStatus;
import 'package:analyzer_plugin/src/utilities/extensions/formatter_options.dart';
import 'package:dart_style/dart_style.dart';

/// A list of all features that are currently enabled by an experiment flag.
final _allowedExperiments = ExperimentStatus.knownFeatures.values
    .where((feature) => feature.status == FeatureStatus.future)
    .toList();

/// Creates a formatter with the appropriate settings for [result].
DartFormatter createFormatter(
  ParsedUnitResult result, {
  int? defaultPageWidth,
}) {
  var featureSet = result.unit.featureSet;
  var formatterOptions = result.analysisOptions.formatterOptions;
  var effectivePageWidth = formatterOptions.pageWidth ?? defaultPageWidth;
  var effectiveTrailingCommas = formatterOptions.dartStyleTrailingCommas;
  var effectiveLanguageVersion = result.unit.languageVersion.effective;
  return DartFormatter(
    pageWidth: effectivePageWidth,
    trailingCommas: effectiveTrailingCommas,
    languageVersion: effectiveLanguageVersion,
    experimentFlags: _getExperiments(featureSet),
  );
}

/// Gets the list of experiment strings enabled by [featureSet] that are
/// required for future features.
List<String> _getExperiments(FeatureSet featureSet) {
  return _allowedExperiments
      .where(featureSet.isEnabled)
      .map((feature) => feature.enableString)
      .toList();
}
