// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:pub_semver/pub_semver.dart';

/// Lowers semantic language-feature directives to language-version overrides
/// understood by the analyzer.
final class LanguageFeatureDirectiveLowering {
  static final _languageVersionOverridePattern = RegExp(
    r'^[ \t]*//[ \t]*@dart[ \t]*=',
    multiLine: true,
  );

  static final _beforeLanguageFeaturePattern = RegExp(
    r'^([ \t]*)//[ \t]*%before-language-feature:[ \t]*'
    r'([a-z0-9-]+)[ \t]*(?=\r?$)',
    multiLine: true,
  );

  /// The code after lowering the semantic directive, if present.
  final String loweredCode;

  final ({
    String beforeLanguageFeatureDirective,
    String languageVersionOverride,
  })?
  _directiveReplacement;

  factory LanguageFeatureDirectiveLowering(String code) {
    var matches = _beforeLanguageFeaturePattern.allMatches(code).toList();
    if (matches.isEmpty) {
      return LanguageFeatureDirectiveLowering._(code, null);
    }

    if (matches.length > 1) {
      throw ArgumentError(
        'Only one %before-language-feature directive is supported per file.',
      );
    }

    if (_languageVersionOverridePattern.hasMatch(code)) {
      throw ArgumentError(
        'A %before-language-feature directive cannot be combined with an '
        '@dart language-version override.',
      );
    }

    var match = matches.single;
    var featureName = match.group(2)!;
    var version = languageVersionBefore(featureName);
    var directive = match.group(0)!;
    var override =
        '${match.group(1)}// @dart = '
        '${version.major}.${version.minor}';
    var loweredCode = code.replaceRange(match.start, match.end, override);

    return LanguageFeatureDirectiveLowering._(loweredCode, (
      beforeLanguageFeatureDirective: directive,
      languageVersionOverride: override,
    ));
  }

  LanguageFeatureDirectiveLowering._(
    this.loweredCode,
    this._directiveReplacement,
  );

  /// Restores the semantic directive in analyzer-generated test code.
  String restoreDirective(String code) {
    var replacement = _directiveReplacement;
    if (replacement == null) {
      return code;
    }

    return code.replaceFirst(
      replacement.languageVersionOverride,
      replacement.beforeLanguageFeatureDirective,
    );
  }

  /// Returns the latest language version before [featureName] is enabled.
  static Version languageVersionBefore(String featureName) {
    var feature = ExperimentStatus.knownFeatures[featureName];
    if (feature == null) {
      throw ArgumentError(
        "Unknown language feature '$featureName' in "
        '%before-language-feature directive.',
      );
    }

    return _languageVersionBefore(feature);
  }

  static Version _languageVersionBefore(ExperimentalFeature feature) {
    // Once a feature ships, its release version is the boundary that matters.
    // Until then, use the first version in which its experiment is available.
    var enabledVersion =
        feature.releaseVersion ??
        feature.experimentalReleaseVersion ??
        ExperimentStatus.currentVersion;

    if (enabledVersion.patch != 0) {
      throw StateError(
        "The '$feature' feature has a non-zero enabling patch version "
        '$enabledVersion.',
      );
    }

    if (enabledVersion.minor > 0) {
      return Version(enabledVersion.major, enabledVersion.minor - 1, 0);
    }

    // At a major-version boundary, use the latest known feature version from
    // the preceding language generation.
    Version? previousKnownVersion;
    for (var knownFeature in ExperimentStatus.knownFeatures.values) {
      for (var version in [
        knownFeature.releaseVersion,
        knownFeature.experimentalReleaseVersion,
      ]) {
        if (version != null &&
            version < enabledVersion &&
            (previousKnownVersion == null || version > previousKnownVersion)) {
          previousKnownVersion = version;
        }
      }
    }

    return previousKnownVersion ??
        (throw StateError(
          "Cannot determine a language version before '$enabledVersion'.",
        ));
  }
}
