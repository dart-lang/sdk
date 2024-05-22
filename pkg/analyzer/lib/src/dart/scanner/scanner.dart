// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/errors.dart'
    show translateErrorToken;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' as fasta;
import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show Token, TokenType;
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:pub_semver/pub_semver.dart';

export 'package:analyzer/src/dart/error/syntactic_errors.dart';

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

  final Source source;

  /// The text to be scanned.
  final String _contents;

  /// The offset of the first character from the reader.
  final int _readerOffset;

  /// The error listener that will be informed of any errors that are found
  /// during the scan.
  final AnalysisErrorListener _errorListener;

  /// If the file has [fasta.LanguageVersionToken], it is allowed to use the
  /// language version greater than the one specified in the package config.
  /// So, we need to know the full feature set for the context.
  late final FeatureSet _featureSetForOverriding;

  /// The flag specifying whether documentation comments should be parsed.
  bool _preserveComments = true;
  List<int>? _lineStarts;
  late final Token firstToken;

  Version? _overrideVersion;

  late FeatureSet _featureSet;

  /// Initialize a newly created scanner to scan characters from the given
  /// [source]. The given character [reader] will be used to read the characters
  /// in the source. The given [_errorListener] will be informed of any errors
  /// that are found.
  factory Scanner(Source source, CharacterReader reader,
          AnalysisErrorListener errorListener) =>
      Scanner.fasta(source, errorListener,
          contents: reader.getContents(), offset: reader.offset);

  factory Scanner.fasta(Source source, AnalysisErrorListener errorListener,
      {String? contents, int offset = -1}) {
    return Scanner._(
        source, contents ?? source.contents.data, offset, errorListener);
  }

  Scanner._(
      this.source, this._contents, this._readerOffset, this._errorListener);

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

  void reportError(
      ScannerErrorCode errorCode, int offset, List<Object?>? arguments) {
    _errorListener.onError(
      AnalysisError.tmp(
        source: source,
        offset: offset,
        length: 1,
        errorCode: errorCode,
        arguments: arguments ?? const [],
      ),
    );
  }

  /// The fasta parser handles error tokens produced by the scanner
  /// but the old parser used by angular does not
  /// and expects that scanner errors to be reported by this method.
  /// Set [reportScannerErrors] `true` when using the old parser.
  Token tokenize({bool reportScannerErrors = true}) {
    fasta.ScannerResult result = fasta.scanString(_contents,
        configuration: buildConfig(_featureSet),
        includeComments: _preserveComments,
        languageVersionChanged: _languageVersionChanged);

    // fasta pretends there is an additional line at EOF so we skip the last one.
    if (result.lineStarts.last > 65535) {
      Uint32List list = _lineStarts = Uint32List(result.lineStarts.length - 1);
      list.setRange(0, result.lineStarts.length - 1, result.lineStarts);
    } else {
      Uint16List list = _lineStarts = Uint16List(result.lineStarts.length - 1);
      list.setRange(0, result.lineStarts.length - 1, result.lineStarts);
    }

    fasta.Token token = result.tokens;

    // The fasta parser handles error tokens produced by the scanner
    // but the old parser used by angular does not
    // and expects that scanner errors to be reported here
    if (reportScannerErrors) {
      // The default recovery strategy used by scanString
      // places all error tokens at the head of the stream.
      while (token.type == TokenType.BAD_INPUT) {
        translateErrorToken(token as fasta.ErrorToken, reportError);
        token = token.next!;
      }
    }

    firstToken = token;
    // Update all token offsets based upon the reader's starting offset
    if (_readerOffset != -1) {
      int delta = _readerOffset + 1;
      do {
        token.offset += delta;
        token = token.next!;
      } while (!token.isEof);
    }
    return firstToken;
  }

  void _languageVersionChanged(
      fasta.Scanner scanner, fasta.LanguageVersionToken versionToken) {
    var overrideMajor = versionToken.major;
    var overrideMinor = versionToken.minor;
    if (overrideMajor < 0 || overrideMinor < 0) {
      return;
    }

    var overrideVersion = Version(overrideMajor, overrideMinor, 0);
    _overrideVersion = overrideVersion;

    var latestVersion = ExperimentStatus.currentVersion;
    if (overrideVersion > latestVersion) {
      _errorListener.onError(
        AnalysisError.tmp(
          source: source,
          offset: versionToken.offset,
          length: versionToken.length,
          errorCode: WarningCode.INVALID_LANGUAGE_VERSION_OVERRIDE_GREATER,
          arguments: [latestVersion.major, latestVersion.minor],
        ),
      );
      _overrideVersion = null;
    } else {
      _featureSet = _featureSetForOverriding.restrictToVersion(
        overrideVersion,
      );
      scanner.configuration = buildConfig(_featureSet);
    }
  }

  /// Return a ScannerConfiguration based upon the specified feature set.
  static fasta.ScannerConfiguration buildConfig(FeatureSet? featureSet) =>
      featureSet == null
          ? fasta.ScannerConfiguration()
          : fasta.ScannerConfiguration(
              enableExtensionMethods:
                  featureSet.isEnabled(Feature.extension_methods),
              enableTripleShift: featureSet.isEnabled(Feature.triple_shift),
              enableNonNullable: featureSet.isEnabled(Feature.non_nullable),
              forAugmentationLibrary: featureSet.isEnabled(Feature.macros),
            );
}
