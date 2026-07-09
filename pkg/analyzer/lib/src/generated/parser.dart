// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/parser.dart' as fasta;
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart'
    show ExperimentalFeaturesStatus;
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/fasta/ast_builder.dart';

/// A parser used to parse tokens into an AST structure.
class Parser {
  /// The fasta parser being wrapped.
  late final fasta.Parser fastaParser;

  /// The builder which creates the analyzer AST data structures
  /// based on the Fasta parser.
  final AstBuilder astBuilder;

  Parser(
    DiagnosticReporter diagnosticReporter, {
    required FeatureSet featureSet,
    required LibraryLanguageVersion languageVersion,
    required LineInfo lineInfo,
  }) : astBuilder = AstBuilder(
         diagnosticReporter,
         diagnosticReporter.source.uri,
         true,
         featureSet,
         languageVersion,
         lineInfo,
       ) {
    fastaParser = fasta.Parser(
      astBuilder,
      experimentalFeatures: ExperimentalFeaturesStatus(featureSet),
    );
    astBuilder.parser = fastaParser;
    astBuilder.allowNativeClause = true;
  }

  CompilationUnitImpl parseCompilationUnit(Token token) {
    fastaParser.parseUnit(token);
    return astBuilder.pop() as CompilationUnitImpl;
  }

  CompilationUnitImpl parseDirectives(Token token) {
    fastaParser.parseDirectives(token);
    return astBuilder.pop() as CompilationUnitImpl;
  }
}
