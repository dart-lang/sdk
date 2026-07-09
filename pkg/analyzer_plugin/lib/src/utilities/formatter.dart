// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart'
    show ExperimentStatus;
import 'package:analyzer_plugin/src/utilities/extensions/formatter_options.dart';
import 'package:dart_style/dart_style.dart';

/// The default version to use for formatting code when there is no better
/// effective language version for the code.
///
/// This is the minimum of the latest version supported by the formatter or
/// the current language version.
final defaultFormatterVersion =
    DartFormatter.latestLanguageVersion < ExperimentStatus.currentVersion
    ? DartFormatter.latestLanguageVersion
    : ExperimentStatus.currentVersion;

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

extension DartFormatterExtension on DartFormatter {
  /// Formats the content, returning the original content if any error occurs
  /// (for example a parse error) during formatting.
  SourceCode formatSafely(
    String content, {
    int? selectionStart,
    int? selectionLength,
  }) {
    var source = SourceCode(
      content,
      selectionStart: selectionStart,
      selectionLength: selectionLength,
    );
    try {
      return formatSource(source);
    } catch (_) {
      // Return the original source if formatting failed for any reason.
      return source;
    }
  }
}
