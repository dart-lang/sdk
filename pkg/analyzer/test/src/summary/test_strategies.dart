// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';

import 'resynthesize_common.dart';

CompilationUnit parseText(
  String text,
  FeatureSet featureSet,
) {
  featureSet ??= FeatureSet.forTesting(sdkVersion: '2.3.0');
  CharSequenceReader reader = new CharSequenceReader(text);
  Scanner scanner =
      new Scanner(null, reader, AnalysisErrorListener.NULL_LISTENER)
        ..configureFeatures(featureSet);
  Token token = scanner.tokenize();
  // Pass the feature set from the scanner to the parser
  // because the scanner may have detected a language version comment
  // and downgraded the feature set it holds.
  Parser parser = new Parser(
      NonExistingSource.unknown, AnalysisErrorListener.NULL_LISTENER,
      featureSet: scanner.featureSet);
  CompilationUnit unit = parser.parseCompilationUnit(token);
  unit.lineInfo = new LineInfo(scanner.lineStarts);
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

  void set allowMissingFiles(bool value);

  set declaredVariables(DeclaredVariables declaredVariables);

  MemoryResourceProvider get resourceProvider;

  void set testFile(String value);

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
  FeatureSet featureSet = FeatureSet.forTesting(sdkVersion: '2.2.2');

  final Set<Source> serializedSources = new Set<Source>();

  final Map<String, UnlinkedUnitBuilder> uriToUnit =
      <String, UnlinkedUnitBuilder>{};

  PackageBundleAssembler bundleAssembler = new PackageBundleAssembler();
}

/// [SerializedMockSdk] is a singleton class representing the result of
/// serializing the mock SDK to summaries.  It is computed once and then shared
/// among test invocations so that we don't bog down the tests.
///
/// Note: should an exception occur during computation of [instance], it will
/// silently be set to null to allow other tests to complete quickly.
class SerializedMockSdk {
  static final SerializedMockSdk instance = _serializeMockSdk();

  final Map<String, UnlinkedUnit> uriToUnlinkedUnit;

  final Map<String, LinkedLibrary> uriToLinkedLibrary;

  SerializedMockSdk._(this.uriToUnlinkedUnit, this.uriToLinkedLibrary);

  static SerializedMockSdk _serializeMockSdk() {
    try {
      Map<String, UnlinkedUnit> uriToUnlinkedUnit = <String, UnlinkedUnit>{};
      Map<String, LinkedLibrary> uriToLinkedLibrary = <String, LinkedLibrary>{};
      var resourceProvider = new MemoryResourceProvider();
      PackageBundle bundle =
          new MockSdk(resourceProvider: resourceProvider).getLinkedBundle();
      for (int i = 0; i < bundle.unlinkedUnitUris.length; i++) {
        String uri = bundle.unlinkedUnitUris[i];
        uriToUnlinkedUnit[uri] = bundle.unlinkedUnits[i];
      }
      for (int i = 0; i < bundle.linkedLibraryUris.length; i++) {
        String uri = bundle.linkedLibraryUris[i];
        uriToLinkedLibrary[uri] = bundle.linkedLibraries[i];
      }
      return new SerializedMockSdk._(uriToUnlinkedUnit, uriToLinkedLibrary);
    } catch (_) {
      return null;
    }
  }
}
