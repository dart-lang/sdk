// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library is no longer supported, but most of the functionality it
/// provides is available through supported analyzer APIs.  See specific methods
/// below for more information about their supported replacements.
@Deprecated('See package:analyzer/analyzer.dart file for details')
library analyzer;

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/error.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:path/path.dart' as pathos;

export 'package:analyzer/dart/ast/ast.dart';
export 'package:analyzer/dart/ast/visitor.dart';
export 'package:analyzer/error/error.dart';
export 'package:analyzer/error/listener.dart';
export 'package:analyzer/src/dart/ast/utilities.dart';
export 'package:analyzer/src/error.dart';
export 'package:analyzer/src/error/codes.dart';
export 'package:analyzer/src/generated/utilities_dart.dart';

/// Parses a string of Dart code into an AST.
///
/// If [name] is passed, it's used in error messages as the name of the code
/// being parsed.
///
/// Throws an [AnalyzerErrorGroup] if any errors occurred, unless
/// [suppressErrors] is `true`, in which case any errors are discarded.
///
/// If [parseFunctionBodies] is [false] then only function signatures will be
/// parsed.  (Currently broken; function bodies are always parsed).
///
/// Deprecated - please use the `parseString` function
/// (from package:analyzer/dart/analysis/utilities.dart) instead.
///
/// Note that `parseString` does not support the `parseFunctionBodies` option;
/// callers that don't require function bodies should simply ignore them.
@Deprecated('Please use parseString instead')
CompilationUnit parseCompilationUnit(String contents,
    {String name,
    bool suppressErrors = false,
    bool parseFunctionBodies = true,
    FeatureSet featureSet}) {
  // TODO(paulberry): make featureSet a required parameter
  featureSet ??= FeatureSet.fromEnableFlags([]);
  Source source = StringSource(contents, name);
  return _parseSource(contents, source, featureSet,
      suppressErrors: suppressErrors, parseFunctionBodies: parseFunctionBodies);
}

/// Parses a Dart file into an AST.
///
/// Throws an [AnalyzerErrorGroup] if any errors occurred, unless
/// [suppressErrors] is `true`, in which case any errors are discarded.
///
/// If [parseFunctionBodies] is [false] then only function signatures will be
/// parsed.  (Currently broken; function bodies are always parsed).
///
/// Deprecated - please use the `parseFile` function
/// (from package:analyzer/dart/analysis/utilities.dart) instead.
///
/// Note that `parseFile` does not support the `parseFunctionBodies` option;
/// callers that don't require function bodies should simply ignore them.
@Deprecated('Please use parseFile instead')
CompilationUnit parseDartFile(String path,
    {bool suppressErrors = false,
    bool parseFunctionBodies = true,
    FeatureSet featureSet}) {
  // TODO(paulberry): Make featureSet a required parameter
  featureSet ??= FeatureSet.fromEnableFlags([]);
  String contents = File(path).readAsStringSync();
  var sourceFactory =
      SourceFactory([ResourceUriResolver(PhysicalResourceProvider.INSTANCE)]);

  var absolutePath = pathos.absolute(path);
  var source = sourceFactory.forUri(pathos.toUri(absolutePath).toString());
  if (source == null) {
    throw ArgumentError("Can't get source for path $path");
  }
  if (!source.exists()) {
    throw ArgumentError("Source $source doesn't exist");
  }

  return _parseSource(contents, source, featureSet,
      suppressErrors: suppressErrors, parseFunctionBodies: parseFunctionBodies);
}

/// Parses the script tag and directives in a string of Dart code into an AST.
/// (Currently broken; the entire file is parsed).
///
/// Stops parsing when the first non-directive is encountered. The rest of the
/// string will not be parsed.
///
/// If [name] is passed, it's used in error messages as the name of the code
/// being parsed.
///
/// Throws an [AnalyzerErrorGroup] if any errors occurred, unless
/// [suppressErrors] is `true`, in which case any errors are discarded.
///
/// Deprecated - please use the `parseString` function
/// (from package:analyzer/dart/analysis/utilities.dart) instead.
///
/// Note that `parseString` parses the whole file; callers that only require
/// directives should simply ignore the rest of the parse result.
@Deprecated('Please use parseString instead')
CompilationUnit parseDirectives(String contents,
    {String name, bool suppressErrors = false, FeatureSet featureSet}) {
  // TODO(paulberry): make featureSet a required parameter.
  featureSet ??= FeatureSet.fromEnableFlags([]);
  var source = StringSource(contents, name);
  var errorCollector = _ErrorCollector();
  var reader = CharSequenceReader(contents);
  var scanner = Scanner(source, reader, errorCollector)
    ..configureFeatures(
      featureSetForOverriding: featureSet,
      featureSet: featureSet,
    );
  var token = scanner.tokenize();
  var parser = Parser(
    source,
    errorCollector,
    featureSet: featureSet,
  );
  var unit = parser.parseDirectives(token);
  unit.lineInfo = LineInfo(scanner.lineStarts);

  if (errorCollector.hasErrors && !suppressErrors) throw errorCollector.group;

  return unit;
}

/// Converts an AST node representing a string literal into a [String].
@Deprecated('Please use StringLiteral.stringValue instead')
String stringLiteralToString(StringLiteral literal) {
  return literal.stringValue;
}

CompilationUnit _parseSource(
    String contents, Source source, FeatureSet featureSet,
    {bool suppressErrors = false, bool parseFunctionBodies = true}) {
  var reader = CharSequenceReader(contents);
  var errorCollector = _ErrorCollector();
  var scanner = Scanner(source, reader, errorCollector)
    ..configureFeatures(
      featureSetForOverriding: featureSet,
      featureSet: featureSet,
    );
  var token = scanner.tokenize();
  var parser = Parser(
    source,
    errorCollector,
    featureSet: featureSet,
  )..parseFunctionBodies = parseFunctionBodies;
  var unit = parser.parseCompilationUnit(token)
    ..lineInfo = LineInfo(scanner.lineStarts);

  if (errorCollector.hasErrors && !suppressErrors) throw errorCollector.group;

  return unit;
}

/// A simple error listener that collects errors into an [AnalyzerErrorGroup].
class _ErrorCollector extends AnalysisErrorListener {
  final _errors = <AnalysisError>[];

  _ErrorCollector();

  /// The group of errors collected.
  AnalyzerErrorGroup get group =>
      AnalyzerErrorGroup.fromAnalysisErrors(_errors);

  /// Whether any errors where collected.
  bool get hasErrors => _errors.isNotEmpty;

  @override
  void onError(AnalysisError error) => _errors.add(error);
}
