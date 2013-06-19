// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer;

import 'dart:io';

import 'package:pathos/path.dart' as pathos;

import 'src/error.dart';
import 'src/generated/ast.dart';
import 'src/generated/error.dart';
import 'src/generated/java_io.dart';
import 'src/generated/parser.dart';
import 'src/generated/scanner.dart';
import 'src/generated/source_io.dart';

export 'src/error.dart';
export 'src/generated/ast.dart';
export 'src/generated/error.dart';
export 'src/generated/utilities_dart.dart';

/// Parses a Dart file into an AST.
CompilationUnit parseDartFile(String path) {
  var contents = new File(path).readAsStringSync();
  var errorCollector = new _ErrorCollector();
  var sourceFactory = new SourceFactory.con2([new FileUriResolver()]);
  var source = sourceFactory.forUri(pathos.toUri(path).toString());
  var scanner = new StringScanner(source, contents, errorCollector);
  var token = scanner.tokenize();
  var parser = new Parser(source, errorCollector);
  var unit = parser.parseCompilationUnit(token);
  unit.lineInfo = new LineInfo(scanner.lineStarts);

  if (errorCollector.hasErrors) throw errorCollector.group;

  return unit;
}

/// Converts an AST node representing a string literal into a [String].
String stringLiteralToString(StringLiteral literal) {
  if (literal is AdjacentStrings) {
    return literal.strings.map(stringLiteralToString).join();
  } else if (literal is SimpleStringLiteral) {
    return literal.value;
  } else {
    throw new ArgumentError("Can't convert $literal to a Dart string.");
  }
}

/// A simple error listener that collects errors into an [AnalysisErrorGroup].
class _ErrorCollector extends AnalysisErrorListener {
  final _errors = <AnalysisError>[];

  /// Whether any errors where collected.
  bool get hasErrors => !_errors.isEmpty;

  /// The group of errors collected.
  AnalyzerErrorGroup get group =>
    new AnalyzerErrorGroup.fromAnalysisErrors(_errors);

  _ErrorCollector();

  void onError(AnalysisError error) => _errors.add(error);
}
