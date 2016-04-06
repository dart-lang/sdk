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
  void test_blockBodiedLambdas_async_allReturnsAreValues() {
    // TODO(scheglov) fix me
  }

  @override
  void test_blockBodiedLambdas_async_alReturnsAreFutures() {
    // TODO(scheglov) fix me
  }

  @override
  void test_blockBodiedLambdas_async_mixOfValuesAndFutures() {
    // TODO(scheglov) fix me
  }

  @override
  void test_blockBodiedLambdas_asyncStar() {
    // TODO(scheglov) fix me
  }

  @override
  void test_blockBodiedLambdas_basic() {
    // TODO(scheglov) fix me
  }

  @override
  void test_blockBodiedLambdas_doesNotInferBottom_async() {
    // TODO(scheglov) fix me
  }

  @override
  void test_blockBodiedLambdas_doesNotInferBottom_asyncStar() {
    // TODO(scheglov) fix me
  }

  @override
  void test_blockBodiedLambdas_doesNotInferBottom_sync() {
    // TODO(scheglov) fix me
  }

  @override
  void test_blockBodiedLambdas_doesNotInferBottom_syncStar() {
    // TODO(scheglov) fix me
  }

  @override
  void test_blockBodiedLambdas_downwardsIncompatibleWithUpwardsInference() {
    // TODO(scheglov) fix me
  }

  @override
  void test_blockBodiedLambdas_LUB() {
    // TODO(scheglov) fix me
  }

  @override
  void test_blockBodiedLambdas_nestedLambdas() {
    // TODO(scheglov) fix me
  }

  @override
  void test_blockBodiedLambdas_noReturn() {
    // TODO(scheglov) fix me
  }

  @override
  void test_blockBodiedLambdas_syncStar() {
    // TODO(scheglov) fix me
  }

  @override
  void test_canInferAlsoFromStaticAndInstanceFieldsFlagOn() {
    // TODO(scheglov) fix me
  }

  @override
  void test_conflictsCanHappen() {
    // TODO(scheglov) fix me
  }

  @override
  void test_conflictsCanHappen2() {
    // TODO(scheglov) fix me
  }

  @override
  void test_doNotInferOverriddenFieldsThatExplicitlySayDynamic_infer() {
    // TODO(scheglov) fix me
  }

  @override
  void test_dontInferFieldTypeWhenInitializerIsNull() {
    // TODO(scheglov) fix me
  }

  @override
  void test_dontInferTypeOnDynamic() {
    // TODO(scheglov) fix me
  }

  @override
  void test_dontInferTypeWhenInitializerIsNull() {
    // TODO(scheglov) fix me
  }

  @override
  void test_downwardInference_miscellaneous() {
    // TODO(scheglov) fix me
  }

  @override
  void test_downwardsInferenceAnnotations() {
    // TODO(scheglov) fix me
  }

  @override
  void test_downwardsInferenceAsyncAwait() {
    // TODO(scheglov) fix me
  }

  @override
  void test_downwardsInferenceForEach() {
    // TODO(scheglov) fix me
  }

  @override
  void test_downwardsInferenceInitializingFormalDefaultFormal() {
    // TODO(scheglov) fix me
  }

  @override
  void test_downwardsInferenceOnFunctionExpressions() {
    // TODO(scheglov) fix me
  }

  @override
  void test_downwardsInferenceOnFunctionOfTUsingTheT() {
    // TODO(scheglov) fix me
  }

  @override
  void test_downwardsInferenceOnGenericFunctionExpressions() {
    // TODO(scheglov) fix me
  }

  @override
  void test_downwardsInferenceOnInstanceCreations_inferDownwards() {
    // TODO(scheglov) fix me
  }

  @override
  void test_downwardsInferenceOnListLiterals_inferDownwards() {
    // TODO(scheglov) fix me
  }

  @override
  void test_downwardsInferenceOnMapLiterals() {
    // TODO(scheglov) fix me
  }

  @override
  void test_downwardsInferenceYieldYieldStar() {
    // TODO(scheglov) fix me
  }

  @override
  void test_genericMethods_IterableAndFuture() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferConstsTransitively() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferCorrectlyOnMultipleVariablesDeclaredTogether() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferenceInCyclesIsDeterministic() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferFromComplexExpressionsIfOuterMostValueIsPrecise() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferFromRhsOnlyIfItWontConflictWithOverriddenFields() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferFromRhsOnlyIfItWontConflictWithOverriddenFields2() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferFromVariablesInCycleLibsWhenFlagIsOn() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferFromVariablesInCycleLibsWhenFlagIsOn2() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferIfComplexExpressionsReadPossibleInferredField() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferListLiteralNestedInMapLiteral() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferredInitializingFormalChecksDefaultValue() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferStaticsTransitively() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferStaticsTransitively2() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferStaticsTransitively3() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferStaticsWithMethodInvocations() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferTypeOnOverriddenFields2() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferTypeOnOverriddenFields4() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferTypeOnVar() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferTypeOnVar2() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferTypeOnVarFromField() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferTypeOnVarFromTopLevel() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferTypesOnGenericInstantiations_3() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferTypesOnGenericInstantiations_5() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferTypesOnGenericInstantiations_infer() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferTypesOnGenericInstantiationsInLibraryCycle() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferTypesOnLoopIndices_forEachLoop() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferTypesOnLoopIndices_forLoopWithInference() {
    // TODO(scheglov) fix me
  }

  @override
  void test_listLiterals() {
    // TODO(scheglov) fix me
  }

  @override
  void test_listLiteralsShouldNotInferBottom() {
    // TODO(scheglov) fix me
  }

  @override
  void test_mapLiterals() {
    // TODO(scheglov) fix me
  }

  @override
  void test_mapLiteralsShouldNotInferBottom() {
    // TODO(scheglov) fix me
  }

  @override
  void test_noErrorWhenDeclaredTypeIsNumAndAssignedNull() {
    // TODO(scheglov) fix me
  }

  @override
  void test_nullLiteralShouldNotInferAsBottom() {
    // TODO(scheglov) fix me
  }

  @override
  void test_propagateInferenceToFieldInClass() {
    // TODO(scheglov) fix me
  }

  @override
  void test_propagateInferenceToFieldInClassDynamicWarnings() {
    // TODO(scheglov) fix me
  }

  @override
  void test_propagateInferenceTransitively() {
    // TODO(scheglov) fix me
  }

  @override
  void test_propagateInferenceTransitively2() {
    // TODO(scheglov) fix me
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

  void setUp() {
    super.setUp();
    addLibrary('dart:core');
  }

  @override
  void test_const_invokeConstructor_named() {
    // TODO(scheglov) fix me
  }

  @override
  void test_constructor_withCycles_const() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferred_function_type_in_generic_class_constructor() {
    // TODO(scheglov) fix me
  }

  @override
  void test_metadata_constructor_call_named() {
    // TODO(scheglov) fix me
  }

  @override
  void test_metadata_constructor_call_named_prefixed() {
    // TODO(scheglov) fix me
  }

  @override
  void test_metadata_constructor_call_unnamed() {
    // TODO(scheglov) fix me
  }

  @override
  void test_metadata_constructor_call_with_args() {
    // TODO(scheglov) fix me
  }

  @override
  void test_type_reference_to_import_part_in_subdir() {
    // TODO(scheglov) fix me
  }

  @override
  void test_unused_type_parameter() {
    // TODO(paulberry): fix.
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
