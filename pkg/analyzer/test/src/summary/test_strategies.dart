// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';

import 'resynthesize_common.dart';

CompilationUnit parseText(
  String text,
  FeatureSet featureSet,
) {
  featureSet ??= FeatureSet.forTesting(sdkVersion: '2.3.0');
  CharSequenceReader reader = CharSequenceReader(text);
  Scanner scanner = Scanner(null, reader, AnalysisErrorListener.NULL_LISTENER)
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
  CompilationUnit unit = parser.parseCompilationUnit(token);
  unit.lineInfo = LineInfo(scanner.lineStarts);

  var unitImpl = unit as CompilationUnitImpl;
  unitImpl.languageVersion = LibraryLanguageVersion(
    package: ExperimentStatus.currentVersion,
    override: null,
  );

  return unit;
}

/// Abstract base class for tests of summary resynthesis.
///
/// Test classes should not extend this class directly; they should extend a
/// class that implements this class with methods that drive summary generation.
/// The tests themselves can then be provided via mixin, allowing summaries to
/// be tested in a variety of ways.
abstract class ResynthesizeTestStrategy {
  /// The set of features enabled in this test.
  FeatureSet featureSet;

  set allowMissingFiles(bool value);

  set declaredVariables(DeclaredVariables declaredVariables);

  MemoryResourceProvider get resourceProvider;

  set testFile(String value);

  Source get testSource;

  void addLibrary(String uri);

  Source addLibrarySource(String filePath, String contents);

  Source addSource(String path, String contents);

  Source addTestSource(String code, [Uri uri]);
}

/// Implementation of [ResynthesizeTestStrategy] that drives summary
/// generation using the old two-phase API.
class ResynthesizeTestStrategyTwoPhase extends AbstractResynthesizeTest
    implements ResynthesizeTestStrategy {
  @override
  FeatureSet featureSet = FeatureSet.forTesting(sdkVersion: '2.7.0');

  final Set<Source> serializedSources = <Source>{};

  PackageBundleAssembler bundleAssembler = PackageBundleAssembler();
}
