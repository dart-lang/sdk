// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/organize_imports.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart' as p;
import 'package:analyzer/src/string_source.dart';
import 'package:dart_style/dart_style.dart';

/// Return a formatted string if successful, throws a [FormatterException] if
/// unable to format. Takes a string as input.
String format(String content) {
  final code = SourceCode(content, uri: null, isCompilationUnit: true);
  var formatter = DartFormatter();
  SourceCode formattedResult;
  formattedResult = formatter.formatSource(code);
  return formattedResult.text;
}

/// Returns a [ParseStringResult]. If successful, the result contains the sorted
/// code. On failure, the result contains the unsorted original code, and the
/// cause of the failure, a list of [AnalysisError]'s.
ParseStringResult sortDirectives(String contents, {String? fileName}) {
  var (unit, errors) = _parse(contents, fullName: fileName);
  var hasParseErrors = errors.any((error) =>
      error.errorCode is ScannerErrorCode ||
      error.errorCode is ParserErrorCode);
  if (hasParseErrors) {
    return ParseStringResultImpl(contents, unit, errors);
  }
  var sorter = ImportOrganizer(contents, unit, errors);
  sorter.organize();
  return ParseStringResultImpl(sorter.code, unit, errors);
}

(CompilationUnit, List<AnalysisError>) _parse(String contents,
    {String? fullName}) {
  var source = StringSource(contents, fullName);
  var errorListener = RecordingErrorListener();
  var reader = CharSequenceReader(contents);
  var featureSet = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: ExperimentStatus.currentVersion,
    flags: [],
  );
  var scanner = Scanner(source, reader, errorListener)
    ..configureFeatures(
      featureSetForOverriding: FeatureSet.latestLanguageVersion(),
      featureSet: featureSet,
    );
  var token = scanner.tokenize(reportScannerErrors: false);
  var lineInfo = LineInfo(scanner.lineStarts);

  var parser = p.Parser(
    source,
    errorListener,
    featureSet: scanner.featureSet,
    lineInfo: lineInfo,
  );

  var unit = parser.parseCompilationUnit(token);
  return (unit, errorListener.errors);
}
