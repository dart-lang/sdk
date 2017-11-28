// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.resynthesize_ast_test;

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart';
import 'package:analyzer/src/summary/prelink.dart';
import 'package:analyzer/src/summary/resynthesize.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:analyzer/src/summary/summarize_elements.dart'
    show PackageBundleAssembler;
import 'package:analyzer/task/dart.dart' show PARSED_UNIT;
import 'package:analyzer/task/general.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context/abstract_context.dart';
import 'element_text.dart';
import 'resynthesize_common.dart';
import 'summary_common.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResynthesizeAstSpecTest);
    defineReflectiveTests(ResynthesizeAstStrongTest);
    defineReflectiveTests(ApplyCheckElementTextReplacements);
  });
}

@reflectiveTest
class ApplyCheckElementTextReplacements {
  test_applyReplacements() {
    applyCheckElementTextReplacements();
  }
}

@reflectiveTest
class ResynthesizeAstSpecTest extends _ResynthesizeAstTest {
  @override
  bool get isStrongMode => false;
}

@reflectiveTest
class ResynthesizeAstStrongTest extends _ResynthesizeAstTest {
  @override
  bool get isStrongMode => true;

  @override
  AnalysisOptionsImpl createOptions() =>
      super.createOptions()..strongMode = true;

  @override
  @failingTest
  test_syntheticFunctionType_genericClosure() async {
    await super.test_syntheticFunctionType_genericClosure();
  }

  @override
  @failingTest
  test_syntheticFunctionType_inGenericClass() async {
    await super.test_syntheticFunctionType_inGenericClass();
  }

  @override
  @failingTest
  test_syntheticFunctionType_noArguments() async {
    await super.test_syntheticFunctionType_noArguments();
  }

  @override
  @failingTest
  test_syntheticFunctionType_withArguments() async {
    await super.test_syntheticFunctionType_withArguments();
  }
}

/**
 * Abstract mixin for serializing ASTs and resynthesizing elements from it.
 */
abstract class _AstResynthesizeTestMixin
    implements _AstResynthesizeTestMixinInterface {
  final Set<Source> serializedSources = new Set<Source>();
  PackageBundleAssembler bundleAssembler = new PackageBundleAssembler();
  final Map<String, UnlinkedUnitBuilder> uriToUnit =
      <String, UnlinkedUnitBuilder>{};

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
    for (int i = 0; i < bundle.unlinkedUnitUris.length; i++) {
      String uri = bundle.unlinkedUnitUris[i];
      unlinkedSummaries[uri] = bundle.unlinkedUnits[i];
    }

    LinkedLibrary getDependency(String absoluteUri) {
      Map<String, LinkedLibrary> sdkLibraries =
          SerializedMockSdk.instance.uriToLinkedLibrary;
      LinkedLibrary linkedLibrary = sdkLibraries[absoluteUri];
      if (linkedLibrary == null && !allowMissingFiles) {
        fail('Linker unexpectedly requested LinkedLibrary for "$absoluteUri".'
            '  Libraries available: ${sdkLibraries.keys}');
      }
      return linkedLibrary;
    }

    UnlinkedUnit getUnit(String absoluteUri) {
      UnlinkedUnit unit = uriToUnit[absoluteUri] ??
          SerializedMockSdk.instance.uriToUnlinkedUnit[absoluteUri];
      if (unit == null && !allowMissingFiles) {
        fail('Linker unexpectedly requested unit for "$absoluteUri".');
      }
      return unit;
    }

    Set<String> nonSdkLibraryUris = serializedSources
        .where((Source source) =>
            !source.isInSystemLibrary &&
            context.computeKindOf(source) == SourceKind.LIBRARY)
        .map((Source source) => source.uri.toString())
        .toSet();

    Map<String, LinkedLibrary> linkedSummaries = link(
        nonSdkLibraryUris,
        getDependency,
        getUnit,
        context.declaredVariables.get,
        context.analysisOptions.strongMode);

    return new TestSummaryResynthesizer(
        context,
        new Map<String, UnlinkedUnit>()
          ..addAll(SerializedMockSdk.instance.uriToUnlinkedUnit)
          ..addAll(unlinkedSummaries),
        new Map<String, LinkedLibrary>()
          ..addAll(SerializedMockSdk.instance.uriToLinkedLibrary)
          ..addAll(linkedSummaries),
        allowMissingFiles);
  }

  UnlinkedUnit _getUnlinkedUnit(Source source) {
    if (source == null) {
      return new UnlinkedUnitBuilder();
    }

    String uriStr = source.uri.toString();
    {
      UnlinkedUnit unlinkedUnitInSdk =
          SerializedMockSdk.instance.uriToUnlinkedUnit[uriStr];
      if (unlinkedUnitInSdk != null) {
        return unlinkedUnitInSdk;
      }
    }
    return uriToUnit.putIfAbsent(uriStr, () {
      int modificationTime = context.computeResult(source, MODIFICATION_TIME);
      if (modificationTime < 0) {
        // Source does not exist.
        if (!allowMissingFiles) {
          fail('Unexpectedly tried to get unlinked summary for $source');
        }
        return null;
      }
      CompilationUnit unit = context.computeResult(source, PARSED_UNIT);
      UnlinkedUnitBuilder unlinkedUnit = serializeAstUnlinked(unit);
      bundleAssembler.addUnlinkedUnit(source, unlinkedUnit);
      return unlinkedUnit;
    });
  }

  void _serializeLibrary(Source librarySource) {
    if (librarySource == null || librarySource.isInSystemLibrary) {
      return;
    }
    if (!serializedSources.add(librarySource)) {
      return;
    }

    UnlinkedUnit getPart(String absoluteUri) {
      Source source = context.sourceFactory.forUri(absoluteUri);
      return _getUnlinkedUnit(source);
    }

    UnlinkedPublicNamespace getImport(String relativeUri) {
      return getPart(relativeUri)?.publicNamespace;
    }

    UnlinkedUnit definingUnit = _getUnlinkedUnit(librarySource);
    if (definingUnit != null) {
      LinkedLibraryBuilder linkedLibrary = prelink(librarySource.uri.toString(),
          definingUnit, getPart, getImport, context.declaredVariables.get);
      linkedLibrary.dependencies.skip(1).forEach((LinkedDependency d) {
        Source source = context.sourceFactory.forUri(d.uri);
        _serializeLibrary(source);
      });
    }
  }
}

/**
 * Interface that [_AstResynthesizeTestMixin] requires of classes it's mixed
 * into.  We can't place the getter below into [_AstResynthesizeTestMixin]
 * directly, because then it would be overriding a field at the site where the
 * mixin is instantiated.
 */
abstract class _AstResynthesizeTestMixinInterface {
  /**
   * A test should return `true` to indicate that a missing file at the time of
   * summary resynthesis shouldn't trigger an error.
   */
  bool get allowMissingFiles;
}

abstract class _ResynthesizeAstTest extends ResynthesizeTest
    with _AstResynthesizeTestMixin {
  bool get isStrongMode;

  bool get shouldCompareLibraryElements;

  @override
  Future<LibraryElementImpl> checkLibrary(String text,
      {bool allowErrors: false, bool dumpSummaries: false}) async {
    Source source = addTestSource(text);
    LibraryElementImpl resynthesized = _encodeDecodeLibraryElement(source);
    LibraryElementImpl original = context.computeLibraryElement(source);
    if (!allowErrors) {
      List<AnalysisError> errors = context.computeErrors(source);
      if (errors.where((e) => e.message.startsWith('unused')).isNotEmpty) {
        fail('Analysis errors: $errors');
      }
    }
    if (shouldCompareLibraryElements) {
      checkLibraryElements(original, resynthesized);
    }
    return resynthesized;
  }

  @override
  DartSdk createDartSdk() => AbstractContextTest.SHARED_MOCK_SDK;

  @override
  AnalysisOptionsImpl createOptions() =>
      super.createOptions()..strongMode = isStrongMode;

  test_getElement_constructor_named() async {
    String text = 'class C { C.named(); }';
    Source source = addLibrarySource('/test.dart', text);
    ConstructorElement original = context
        .computeLibraryElement(source)
        .getType('C')
        .getNamedConstructor('named');
    expect(original, isNotNull);
    ConstructorElement resynthesized = _validateGetElement(text, original);
    compareConstructorElements(resynthesized, original, 'C.constructor named');
  }

  test_getElement_constructor_unnamed() async {
    String text = 'class C { C(); }';
    Source source = addLibrarySource('/test.dart', text);
    ConstructorElement original =
        context.computeLibraryElement(source).getType('C').unnamedConstructor;
    expect(original, isNotNull);
    ConstructorElement resynthesized = _validateGetElement(text, original);
    compareConstructorElements(resynthesized, original, 'C.constructor');
  }

  test_getElement_field() async {
    String text = 'class C { var f; }';
    Source source = addLibrarySource('/test.dart', text);
    FieldElement original =
        context.computeLibraryElement(source).getType('C').getField('f');
    expect(original, isNotNull);
    FieldElement resynthesized = _validateGetElement(text, original);
    compareFieldElements(resynthesized, original, 'C.field f');
  }

  test_getElement_getter() async {
    String text = 'class C { get f => null; }';
    Source source = addLibrarySource('/test.dart', text);
    PropertyAccessorElement original =
        context.computeLibraryElement(source).getType('C').getGetter('f');
    expect(original, isNotNull);
    PropertyAccessorElement resynthesized = _validateGetElement(text, original);
    comparePropertyAccessorElements(resynthesized, original, 'C.getter f');
  }

  test_getElement_method() async {
    String text = 'class C { f() {} }';
    Source source = addLibrarySource('/test.dart', text);
    MethodElement original =
        context.computeLibraryElement(source).getType('C').getMethod('f');
    expect(original, isNotNull);
    MethodElement resynthesized = _validateGetElement(text, original);
    compareMethodElements(resynthesized, original, 'C.method f');
  }

  test_getElement_operator() async {
    String text = 'class C { operator+(x) => null; }';
    Source source = addLibrarySource('/test.dart', text);
    MethodElement original =
        context.computeLibraryElement(source).getType('C').getMethod('+');
    expect(original, isNotNull);
    MethodElement resynthesized = _validateGetElement(text, original);
    compareMethodElements(resynthesized, original, 'C.operator+');
  }

  test_getElement_setter() async {
    String text = 'class C { void set f(value) {} }';
    Source source = addLibrarySource('/test.dart', text);
    PropertyAccessorElement original =
        context.computeLibraryElement(source).getType('C').getSetter('f');
    expect(original, isNotNull);
    PropertyAccessorElement resynthesized = _validateGetElement(text, original);
    comparePropertyAccessorElements(resynthesized, original, 'C.setter f');
  }

  test_getElement_unit() async {
    String text = 'class C { f() {} }';
    Source source = addLibrarySource('/test.dart', text);
    CompilationUnitElement original =
        context.computeLibraryElement(source).definingCompilationUnit;
    expect(original, isNotNull);
    CompilationUnitElement resynthesized = _validateGetElement(text, original);
    compareCompilationUnitElements(resynthesized, original);
  }

  /**
   * Return a [SummaryResynthesizer] to resynthesize the library with the
   * given [Source].
   */
  TestSummaryResynthesizer _encodeDecodeLibrarySource(Source source) {
    return _encodeLibrary(source);
  }

  /**
   * Encode the library containing [original] into a summary and then use
   * [TestSummaryResynthesizer.getElement] to retrieve just the original
   * element from the resynthesized summary.
   */
  Element _validateGetElement(String text, Element original) {
    SummaryResynthesizer resynthesizer =
        _encodeDecodeLibrarySource(original.library.source);
    ElementLocationImpl location = original.location;
    Element result = resynthesizer.getElement(location);
    checkMinimalResynthesisWork(resynthesizer, original.library);
    // Check that no other summaries needed to be resynthesized to resynthesize
    // the library element.
    expect(resynthesizer.resynthesisCount, 3);
    expect(result.location, location);
    return result;
  }
}
