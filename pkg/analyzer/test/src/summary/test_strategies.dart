// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';

CompilationUnit parseText(
  String text,
  FeatureSet featureSet,
) {
  CharSequenceReader reader = CharSequenceReader(text);
  Scanner scanner =
      Scanner(_SourceMock.instance, reader, AnalysisErrorListener.NULL_LISTENER)
        ..configureFeatures(
          featureSetForOverriding: featureSet,
          featureSet: featureSet,
        );
  Token token = scanner.tokenize();
  // Pass the feature set from the scanner to the parser
  // because the scanner may have detected a language version comment
  // and downgraded the feature set it holds.
  Parser parser = Parser(
    NonExistingSource.unknown,
    AnalysisErrorListener.NULL_LISTENER,
    featureSet: scanner.featureSet,
  );
  var unit = parser.parseCompilationUnit(token);
  unit.lineInfo = LineInfo(scanner.lineStarts);

  unit.languageVersion = LibraryLanguageVersion(
    package: ExperimentStatus.currentVersion,
    override: null,
  );

  return unit;
}

class _SourceMock implements Source {
  static final Source instance = _SourceMock();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
