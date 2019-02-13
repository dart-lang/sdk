// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';

class ParseBase with ResourceProviderMixin {
  /// Override this to change the analysis options for a given set of tests.
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl();

  ParseResult parseUnit(String path) {
    var file = getFile(path);
    var source = file.createSource();
    var content = file.readAsStringSync();

    var analysisOptions = this.analysisOptions;
    var experimentStatus = analysisOptions.experimentStatus;

    var errorListener = RecordingErrorListener();

    var reader = CharSequenceReader(content);
    var scanner = Scanner(source, reader, errorListener);

    scanner.enableGtGtGt = experimentStatus.constant_update_2018;
    var token = scanner.tokenize();

    var useFasta = analysisOptions.useFastaParser;
    var parser = Parser(source, errorListener, useFasta: useFasta);
    parser.enableOptionalNewAndConst = true;
    parser.enableNonNullable = experimentStatus.non_nullable;
    parser.enableSpreadCollections = experimentStatus.spread_collections;
    parser.enableControlFlowCollections =
        experimentStatus.control_flow_collections;

    var unit = parser.parseCompilationUnit(token);
    unit.lineInfo = LineInfo(scanner.lineStarts);

    return ParseResult(path, content, unit, errorListener.errors);
  }
}

class ParseResult {
  final String path;
  final String content;
  final CompilationUnit unit;
  final List<AnalysisError> errors;

  ParseResult(this.path, this.content, this.unit, this.errors);
}
