// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:_fe_analyzer_shared/src/parser/experimental_features.dart';
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' as fasta;
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

/// The class `Scanner` implements a scanner for Dart code.
///
/// The lexical structure of Dart is ambiguous without knowledge of the context
/// in which a token is being scanned. For example, without context we cannot
/// determine whether source of the form "<<" should be scanned as a single
/// left-shift operator or as two left angle brackets. This scanner does not
/// have any context, so it always resolves such conflicts by scanning the
/// longest possible token.
class Scanner {
  static final Uint8List _lineStartsZero = Uint8List(0);

  /// Allows to - by default - either preserve or not preserve comments while
  /// testing.
  @visibleForTesting
  static bool preserveCommentsDefaultForTesting = true;

  /// The input text to be scanned.
  final String _inputText;

  /// The callback to report diagnostics.
  final void Function(LocatedDiagnostic) reportError;

  /// If the file has [fasta.LanguageVersionToken], it is allowed to use the
  /// language version greater than the one specified in the package config.
  /// So, we need to know the full feature set for the context.
  late final FeatureSet _featureSetForOverriding;

  /// The flag specifying whether documentation comments should be parsed.
  bool _preserveComments = preserveCommentsDefaultForTesting;
  List<int>? _lineStarts;

  Version? _overrideVersion;

  late FeatureSet _featureSet;

  /// Initializes a scanner to scan the given [inputText].
  ///
  /// The [reportError] callback will be informed of any errors that are found.
  Scanner({required String inputText, required this.reportError})
    : _inputText = inputText;

  /// The features associated with this scanner.
  ///
  /// If a language version comment (e.g. '// @dart = 2.3') is detected
  /// when calling [tokenize] and this field is non-null, then this field
  /// will be updated to contain a downgraded feature set based upon the
  /// language version specified.
  ///
  /// Use [configureFeatures] to set the features.
  FeatureSet get featureSet => _featureSet;

  List<int> get lineStarts => _lineStarts ?? _lineStartsZero;

  /// The language version override specified for this compilation unit using a
  /// token like '// @dart = 2.7', or `null` if no override is specified.
  Version? get overrideVersion => _overrideVersion;

  set preserveComments(bool preserveComments) {
    _preserveComments = preserveComments;
  }

  /// Configures the scanner appropriately for the given [featureSet].
  void configureFeatures({
    required FeatureSet featureSetForOverriding,
    required FeatureSet featureSet,
  }) {
    _featureSetForOverriding = featureSetForOverriding;
    _featureSet = featureSet;
  }

  Token tokenize() {
    fasta.ScannerResult result = fasta.scanString(
      _inputText,
      configuration: ExperimentalFeaturesStatus(
        _featureSet,
      ).buildScannerConfiguration(),
      includeComments: _preserveComments,
      languageVersionChanged: _languageVersionChanged,
    );

    // fasta pretends there is an additional line at EOF so we skip the last one.
    if (result.lineStarts.last > 65535) {
      Uint32List list = _lineStarts = Uint32List(result.lineStarts.length - 1);
      list.setRange(0, result.lineStarts.length - 1, result.lineStarts);
    } else {
      Uint16List list = _lineStarts = Uint16List(result.lineStarts.length - 1);
      list.setRange(0, result.lineStarts.length - 1, result.lineStarts);
    }

    return result.tokens;
  }

  void _languageVersionChanged(
    fasta.Scanner scanner,
    fasta.LanguageVersionToken versionToken,
  ) {
    var overrideMajor = versionToken.major;
    var overrideMinor = versionToken.minor;
    if (overrideMajor < 0 || overrideMinor < 0) {
      return;
    }

    var overrideVersion = Version(overrideMajor, overrideMinor, 0);
    _overrideVersion = overrideVersion;

    var latestVersion = ExperimentStatus.currentVersion;
    if (overrideVersion > latestVersion) {
      reportError(
        diag.invalidLanguageVersionOverrideGreater
            .withArguments(
              latestMajor: latestVersion.major,
              latestMinor: latestVersion.minor,
            )
            .atOffset(offset: versionToken.offset, length: versionToken.length),
      );
      _overrideVersion = null;
    } else {
      _featureSet = _featureSetForOverriding.restrictToVersion(overrideVersion);
      scanner.configuration = ExperimentalFeaturesStatus(
        _featureSet,
      ).buildScannerConfiguration();
    }
  }
}
