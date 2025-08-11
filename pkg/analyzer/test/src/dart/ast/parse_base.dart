// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/engine.dart'
    show RecordingDiagnosticListener;
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';

class ParseBase with ResourceProviderMixin {
  /// Override this to change the analysis options for a given set of tests.
  AnalysisOptions get analysisOptions => AnalysisOptionsImpl();

  ParseResult parseUnit(String path) {
    var file = getFile(path);
    var source = FileSource(file);
    var content = file.readAsStringSync();

    var featureSet = analysisOptions.contextFeatures;

    var diagnosticListener = RecordingDiagnosticListener();

    var reader = CharSequenceReader(content);
    var scanner = Scanner(source, reader, diagnosticListener)
      ..configureFeatures(
        featureSetForOverriding: featureSet,
        featureSet: featureSet,
      );

    var token = scanner.tokenize();
    var lineInfo = LineInfo(scanner.lineStarts);
    var languageVersion = LibraryLanguageVersion(
      package: ExperimentStatus.currentVersion,
      override: scanner.overrideVersion,
    );
    featureSet = scanner.featureSet;

    var parser = Parser(
      source,
      diagnosticListener,
      featureSet: featureSet,
      languageVersion: languageVersion,
      lineInfo: lineInfo,
    );

    var unit = parser.parseCompilationUnit(token);

    return ParseResult(
      path,
      content,
      unit.lineInfo,
      unit,
      diagnosticListener.diagnostics,
    );
  }
}

class ParseResult {
  final String path;
  final String content;
  final LineInfo lineInfo;
  final CompilationUnit unit;
  final List<Diagnostic> diagnostics;

  ParseResult(
    this.path,
    this.content,
    this.lineInfo,
    this.unit,
    this.diagnostics,
  );
}
