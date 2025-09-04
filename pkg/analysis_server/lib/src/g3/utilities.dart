// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/organize_imports.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart' as p;
import 'package:analyzer/src/string_source.dart';
import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';

/// Return a formatted string if successful, throws a [FormatterException] if
/// unable to format. Takes a string as input and an optional [languageVersion].
String format(String content, {Version? languageVersion}) {
  var code = SourceCode(content);
  var formatter = DartFormatter(
    languageVersion: languageVersion ?? DartFormatter.latestLanguageVersion,
  );
  SourceCode formattedResult;
  formattedResult = formatter.formatSource(code);
  return formattedResult.text;
}

/// Returns a [ParseStringResult]. If successful, the result contains the sorted
/// code. On failure, the result contains the unsorted original code, and the
/// cause of the failure, a list of [Diagnostic]s.
ParseStringResult sortDirectives(String contents, {String? fileName}) {
  var (unit, diagnostics) = _parse(contents, fullName: fileName);
  var parseErrors = diagnostics
      .where(
        (d) =>
            d.diagnosticCode is ScannerErrorCode ||
            d.diagnosticCode is ParserErrorCode,
      )
      .toList();
  if (parseErrors.isNotEmpty) {
    return ParseStringResultImpl(contents, unit, parseErrors);
  }
  var sorter = ImportOrganizer(contents, unit, parseErrors);
  sorter.organize();
  return ParseStringResultImpl(sorter.code, unit, parseErrors);
}

(CompilationUnit, List<Diagnostic>) _parse(
  String contents, {
  String? fullName,
}) {
  var source = StringSource(contents, fullName);
  var diagnosticListener = RecordingDiagnosticListener();
  var reader = CharSequenceReader(contents);
  var featureSet = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: ExperimentStatus.currentVersion,
    flags: [],
  );
  var scanner = Scanner(source, reader, diagnosticListener)
    ..configureFeatures(
      featureSetForOverriding: FeatureSet.latestLanguageVersion(),
      featureSet: featureSet,
    );
  var token = scanner.tokenize(reportScannerErrors: false);
  var lineInfo = LineInfo(scanner.lineStarts);
  var languageVersion = LibraryLanguageVersion(
    package: ExperimentStatus.currentVersion,
    override: scanner.overrideVersion,
  );

  var parser = p.Parser(
    source,
    diagnosticListener,
    featureSet: scanner.featureSet,
    lineInfo: lineInfo,
    languageVersion: languageVersion,
  );

  var unit = parser.parseCompilationUnit(token);
  return (unit, diagnosticListener.diagnostics);
}
