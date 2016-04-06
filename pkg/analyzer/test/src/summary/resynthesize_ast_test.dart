// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.resynthesize_ast_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/prelink.dart';
import 'package:analyzer/src/summary/resynthesize.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:analyzer/src/summary/summarize_elements.dart'
    show PackageBundleAssembler;
import 'package:analyzer/task/dart.dart' show PARSED_UNIT;
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../task/strong/inferred_type_test.dart';
import 'resynthesize_test.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(ResynthesizeAstTest);
  runReflectiveTests(AstInferredTypeTest);
}

@reflectiveTest
class AstInferredTypeTest extends AbstractResynthesizeTest
    with _AstResynthesizeTestMixin, InferredTypeMixin {
  @override
  bool get skipBrokenAstInference => true;

  @override
  void addFile(String content, {String name: '/main.dart'}) {
    addSource(name, content);
  }

  @override
  CompilationUnitElement checkFile(String content) {
    Source source = addSource('/main.dart', content);
    LibraryElementImpl resynthesized = _encodeDecodeLibraryElement(source);
    LibraryElementImpl original = context.computeLibraryElement(source);
    checkLibraryElements(original, resynthesized);
    return resynthesized.definingCompilationUnit;
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_async_allReturnsAreValues() {
    super.test_blockBodiedLambdas_async_allReturnsAreValues();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_async_alReturnsAreFutures() {
    super.test_blockBodiedLambdas_async_alReturnsAreFutures();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_async_mixOfValuesAndFutures() {
    super.test_blockBodiedLambdas_async_mixOfValuesAndFutures();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_asyncStar() {
    super.test_blockBodiedLambdas_asyncStar();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_doesNotInferBottom_async() {
    super.test_blockBodiedLambdas_doesNotInferBottom_async();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_doesNotInferBottom_asyncStar() {
    super.test_blockBodiedLambdas_doesNotInferBottom_asyncStar();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_doesNotInferBottom_sync() {
    super.test_blockBodiedLambdas_doesNotInferBottom_sync();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_doesNotInferBottom_syncStar() {
    super.test_blockBodiedLambdas_doesNotInferBottom_syncStar();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_downwardsIncompatibleWithUpwardsInference() {
    super.test_blockBodiedLambdas_downwardsIncompatibleWithUpwardsInference();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_nestedLambdas() {
    super.test_blockBodiedLambdas_nestedLambdas();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_noReturn() {
    super.test_blockBodiedLambdas_noReturn();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_syncStar() {
    super.test_blockBodiedLambdas_syncStar();
  }

  @override
  @failingTest
  void test_downwardsInferenceAnnotations() {
    super.test_downwardsInferenceAnnotations();
  }

  @override
  @failingTest
  void test_downwardsInferenceAsyncAwait() {
    super.test_downwardsInferenceAsyncAwait();
  }

  @override
  @failingTest
  void test_downwardsInferenceForEach() {
    super.test_downwardsInferenceForEach();
  }

  @override
  @failingTest
  void test_downwardsInferenceInitializingFormalDefaultFormal() {
    super.test_downwardsInferenceInitializingFormalDefaultFormal();
  }

  @override
  @failingTest
  void test_downwardsInferenceOnFunctionOfTUsingTheT() {
    super.test_downwardsInferenceOnFunctionOfTUsingTheT();
  }

  @override
  @failingTest
  void test_downwardsInferenceOnGenericFunctionExpressions() {
    super.test_downwardsInferenceOnGenericFunctionExpressions();
  }

  @override
  @failingTest
  void test_downwardsInferenceOnListLiterals_inferDownwards() {
    super.test_downwardsInferenceOnListLiterals_inferDownwards();
  }

  @override
  @failingTest
  void test_downwardsInferenceOnMapLiterals() {
    super.test_downwardsInferenceOnMapLiterals();
  }

  @override
  @failingTest
  void test_downwardsInferenceYieldYieldStar() {
    super.test_downwardsInferenceYieldYieldStar();
  }

  @override
  @failingTest
  void test_genericMethods_IterableAndFuture() {
    super.test_genericMethods_IterableAndFuture();
  }

  @override
  @failingTest
  void test_inferConstsTransitively() {
    super.test_inferConstsTransitively();
  }

  @override
  @failingTest
  void test_inferenceInCyclesIsDeterministic() {
    super.test_inferenceInCyclesIsDeterministic();
  }

  @override
  @failingTest
  void test_inferFromRhsOnlyIfItWontConflictWithOverriddenFields2() {
    super.test_inferFromRhsOnlyIfItWontConflictWithOverriddenFields2();
  }

  @override
  @failingTest
  void test_inferIfComplexExpressionsReadPossibleInferredField() {
    super.test_inferIfComplexExpressionsReadPossibleInferredField();
  }

  @override
  @failingTest
  void test_inferredInitializingFormalChecksDefaultValue() {
    super.test_inferredInitializingFormalChecksDefaultValue();
  }

  @override
  @failingTest
  void test_inferStaticsTransitively() {
    super.test_inferStaticsTransitively();
  }

  @override
  @failingTest
  void test_inferStaticsTransitively2() {
    super.test_inferStaticsTransitively2();
  }

  @override
  @failingTest
  void test_inferStaticsTransitively3() {
    super.test_inferStaticsTransitively3();
  }

  @override
  @failingTest
  void test_inferTypeOnVarFromField() {
    super.test_inferTypeOnVarFromField();
  }

  @override
  @failingTest
  void test_inferTypeOnVarFromTopLevel() {
    super.test_inferTypeOnVarFromTopLevel();
  }

  @override
  @failingTest
  void test_inferTypesOnLoopIndices_forEachLoop() {
    super.test_inferTypesOnLoopIndices_forEachLoop();
  }

  @override
  @failingTest
  void test_listLiteralsShouldNotInferBottom() {
    super.test_listLiteralsShouldNotInferBottom();
  }

  @override
  @failingTest
  void test_mapLiteralsShouldNotInferBottom() {
    super.test_mapLiteralsShouldNotInferBottom();
  }

  @override
  @failingTest
  void test_nullLiteralShouldNotInferAsBottom() {
    super.test_nullLiteralShouldNotInferAsBottom();
  }
}

@reflectiveTest
class ResynthesizeAstTest extends ResynthesizeTest
    with _AstResynthesizeTestMixin {
  @override
  bool get checkPropagatedTypes => false;

  @override
  void checkLibrary(String text,
      {bool allowErrors: false, bool dumpSummaries: false}) {
    Source source = addTestSource(text);
    LibraryElementImpl resynthesized = _encodeDecodeLibraryElement(source);
    LibraryElementImpl original = context.computeLibraryElement(source);
    checkLibraryElements(original, resynthesized);
  }

  @override
  TestSummaryResynthesizer encodeDecodeLibrarySource(Source source) {
    return _encodeLibrary(source);
  }

  @override
  @failingTest
  void test_constructor_withCycles_const() {
    super.test_constructor_withCycles_const();
  }

  @override
  @failingTest
  void test_inferred_function_type_in_generic_class_constructor() {
    super.test_inferred_function_type_in_generic_class_constructor();
  }

  @override
  @failingTest
  void test_metadata_constructor_call_named() {
    super.test_metadata_constructor_call_named();
  }

  @override
  @failingTest
  void test_metadata_constructor_call_named_prefixed() {
    super.test_metadata_constructor_call_named_prefixed();
  }

  @override
  @failingTest
  void test_metadata_constructor_call_unnamed() {
    super.test_metadata_constructor_call_unnamed();
  }

  @override
  @failingTest
  void test_metadata_constructor_call_with_args() {
    super.test_metadata_constructor_call_with_args();
  }

  @override
  @failingTest
  void test_type_reference_to_import_part_in_subdir() {
    super.test_type_reference_to_import_part_in_subdir();
  }
}

/**
 * Abstract mixin for serializing ASTs and resynthesizing elements from it.
 */
abstract class _AstResynthesizeTestMixin {
  final Set<Source> serializedSources = new Set<Source>();
  final PackageBundleAssembler bundleAssembler = new PackageBundleAssembler();
  final Map<Uri, UnlinkedUnitBuilder> uriToUnit = <Uri, UnlinkedUnitBuilder>{};

  AnalysisContext get context;

  LibraryElementImpl _encodeDecodeLibraryElement(Source source) {
    SummaryResynthesizer resynthesizer = _encodeLibrary(source);
    return resynthesizer.getLibraryElement(source.uri.toString());
  }

  TestSummaryResynthesizer _encodeLibrary(Source source) {
    _serializeLibrary(source);

    PackageBundle bundle =
        new PackageBundle.fromBuffer(bundleAssembler.assemble().toBuffer());

    Map<String, UnlinkedUnit> unlinkedSummaries = <String, UnlinkedUnit>{};
    Map<String, LinkedLibrary> linkedSummaries = <String, LinkedLibrary>{};
    for (int i = 0; i < bundle.unlinkedUnitUris.length; i++) {
      String uri = bundle.unlinkedUnitUris[i];
      unlinkedSummaries[uri] = bundle.unlinkedUnits[i];
    }
    for (int i = 0; i < bundle.linkedLibraryUris.length; i++) {
      String uri = bundle.linkedLibraryUris[i];
      linkedSummaries[uri] = bundle.linkedLibraries[i];
    }

    return new TestSummaryResynthesizer(
        null, context, unlinkedSummaries, linkedSummaries);
  }

  UnlinkedUnitBuilder _getUnlinkedUnit(Source source) {
    return uriToUnit.putIfAbsent(source.uri, () {
      CompilationUnit unit = context.computeResult(source, PARSED_UNIT);
      UnlinkedUnitBuilder unlinkedUnit = serializeAstUnlinked(unit);
      bundleAssembler.addUnlinkedUnit(source, unlinkedUnit);
      return unlinkedUnit;
    });
  }

  void _serializeLibrary(Source librarySource) {
    if (!serializedSources.add(librarySource)) {
      return;
    }

    Source resolveRelativeUri(String relativeUri) {
      Source resolvedSource =
          context.sourceFactory.resolveUri(librarySource, relativeUri);
      if (resolvedSource == null) {
        throw new StateError('Could not resolve $relativeUri in the context of '
            '$librarySource (${librarySource.runtimeType})');
      }
      return resolvedSource;
    }

    UnlinkedUnitBuilder getPart(String relativeUri) {
      return _getUnlinkedUnit(resolveRelativeUri(relativeUri));
    }

    UnlinkedPublicNamespace getImport(String relativeUri) {
      return getPart(relativeUri).publicNamespace;
    }

    UnlinkedUnitBuilder definingUnit = _getUnlinkedUnit(librarySource);
    LinkedLibraryBuilder linkedLibrary =
        prelink(definingUnit, getPart, getImport);
    bundleAssembler.addLinkedLibrary(
        librarySource.uri.toString(), linkedLibrary);
    linkedLibrary.dependencies.skip(1).forEach((LinkedDependency d) {
      _serializeLibrary(resolveRelativeUri(d.uri));
    });
  }
}
