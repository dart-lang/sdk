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
import '../task/strong/inferred_type_test.dart';
import 'element_text.dart';
import 'resynthesize_common.dart';
import 'summary_common.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResynthesizeAstSpecTest);
    defineReflectiveTests(ResynthesizeAstStrongTest);
    defineReflectiveTests(AstInferredTypeTest);
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
class AstInferredTypeTest extends AbstractResynthesizeTest
    with _AstResynthesizeTestMixin, InferredTypeMixin {
  @override
  bool get isStrongMode => true;

  @override
  bool get mayCheckTypesOfLocals => false;

  bool shouldCompareElementsWithAnalysisContext = true;

  @override
  void addFile(String content, {String name: '/main.dart'}) {
    addLibrarySource(name, content);
  }

  @override
  Future<CompilationUnitElement> checkFileElement(String content) async {
    Source source = addSource('/main.dart', content);
    SummaryResynthesizer resynthesizer = _encodeLibrary(source);
    LibraryElementImpl resynthesized = _checkSource(resynthesizer, source);
    for (Source otherSource in otherLibrarySources) {
      _checkSource(resynthesizer, otherSource);
    }
    _reset();
    return resynthesized.definingCompilationUnit;
  }

  @override
  void compareLocalElementsOfExecutable(ExecutableElement resynthesized,
      ExecutableElement original, String desc) {
    // We don't resynthesize local elements during link.
    // So, we should not compare them.
  }

  @override
  DartSdk createDartSdk() => AbstractContextTest.SHARED_STRONG_MOCK_SDK;

  @override
  AnalysisOptionsImpl createOptions() =>
      new AnalysisOptionsImpl()..strongMode = true;

  @override
  @failingTest
  test_blockBodiedLambdas_async_allReturnsAreFutures_topLevel() async {
    await super.test_blockBodiedLambdas_async_allReturnsAreFutures_topLevel();
  }

  @override
  @failingTest
  test_blockBodiedLambdas_async_allReturnsAreValues_topLevel() async {
    await super.test_blockBodiedLambdas_async_allReturnsAreValues_topLevel();
  }

  @override
  @failingTest
  test_blockBodiedLambdas_async_mixOfValuesAndFutures_topLevel() async {
    await super.test_blockBodiedLambdas_async_mixOfValuesAndFutures_topLevel();
  }

  @override
  @failingTest
  test_blockBodiedLambdas_asyncStar_topLevel() async {
    await super.test_blockBodiedLambdas_asyncStar_topLevel();
  }

  @override
  @failingTest
  test_blockBodiedLambdas_basic_topLevel() async {
    await super.test_blockBodiedLambdas_basic_topLevel();
  }

  @override
  @failingTest
  test_blockBodiedLambdas_inferBottom_async_topLevel() async {
    await super.test_blockBodiedLambdas_inferBottom_async_topLevel();
  }

  @override
  @failingTest
  test_blockBodiedLambdas_inferBottom_asyncStar_topLevel() async {
    await super.test_blockBodiedLambdas_inferBottom_asyncStar_topLevel();
  }

  @override
  @failingTest
  test_blockBodiedLambdas_inferBottom_sync_topLevel() async {
    await super.test_blockBodiedLambdas_inferBottom_sync_topLevel();
  }

  @override
  @failingTest
  test_blockBodiedLambdas_inferBottom_syncStar_topLevel() async {
    await super.test_blockBodiedLambdas_inferBottom_syncStar_topLevel();
  }

  @override
  @failingTest
  test_blockBodiedLambdas_LUB_topLevel() async {
    await super.test_blockBodiedLambdas_LUB_topLevel();
  }

  @override
  @failingTest
  test_blockBodiedLambdas_nestedLambdas_topLevel() async {
    await super.test_blockBodiedLambdas_nestedLambdas_topLevel();
  }

  @override
  @failingTest
  test_blockBodiedLambdas_noReturn_topLevel() =>
      super.test_blockBodiedLambdas_noReturn_topLevel();

  @override
  @failingTest
  test_blockBodiedLambdas_syncStar_topLevel() async {
    await super.test_blockBodiedLambdas_syncStar_topLevel();
  }

  @override
  @failingTest
  test_circularReference_viaClosures_initializerTypes() async {
    await super.test_circularReference_viaClosures_initializerTypes();
  }

  test_infer_extractIndex_custom() async {
    var unit = await checkFileElement('''
class A {
  String operator [](_) => null;
}
var a = new A();
var b = a[0];
  ''');
    expect(unit.topLevelVariables[1].type.toString(), 'String');
  }

  test_infer_extractIndex_fromList() async {
    var unit = await checkFileElement('''
var a = <int>[1, 2, 3];
var b = a[0];
  ''');
    expect(unit.topLevelVariables[1].type.toString(), 'int');
  }

  test_infer_extractIndex_fromMap() async {
    var unit = await checkFileElement('''
var a = <int, double>{};
var b = a[0];
  ''');
    expect(unit.topLevelVariables[1].type.toString(), 'double');
  }

  test_infer_extractProperty_getter() async {
    await checkFileElement(r'''
var a = 1.isEven;
var b = 2.isNaN;
var c = 3.foo;
var d = foo.bar;
  ''');
  }

  test_infer_extractProperty_getter_sequence() async {
    var unit = await checkFileElement(r'''
class A {
  B b = new B();
}
class B {
  C c = new C();
}
class C {
  int d;
}
var a = new A();
var v = a.b.c.d;
  ''');
    expect(unit.topLevelVariables[1].type.toString(), 'dynamic');
  }

  test_infer_extractProperty_getter_sequence_generic() async {
    var unit = await checkFileElement(r'''
class A<T> {
  B<T> b = new B<T>();
}
class B<K> {
  C<List<K>, int> c = new C<List<K>, int>();
}
class C<K, V> {
  Map<K, V> d;
}
var a = new A<double>();
var v = a.b.c.d;
  ''');
    expect(unit.topLevelVariables[1].type.toString(), 'dynamic');
  }

  test_infer_extractProperty_getter_sequence_withUnresolved() async {
    var unit = await checkFileElement(r'''
class A {
  B b = new B();
}
class B {
  int c;
}
var a = new A();
var v = a.b.foo.c;
  ''');
    expect(unit.topLevelVariables[1].type.toString(), 'dynamic');
  }

  test_infer_extractProperty_method() async {
    var unit = await checkFileElement(r'''
class A {
  int m(double p1, String p2) => 42;
}
var a = new A();
var v = a.m;
  ''');
    expect(unit.topLevelVariables[1].type.toString(), '(double, String) → int');
  }

  test_infer_extractProperty_method2() async {
    var unit = await checkFileElement(r'''
var a = 1.round;
  ''');
    expect(unit.topLevelVariables[0].type.toString(), '() → int');
  }

  test_infer_extractProperty_method_sequence() async {
    var unit = await checkFileElement(r'''
class A {
  B b = new B();
}
class B {
  C c = new C();
}
class C {
  int m(double p1, String p2) => 42;
}
var a = new A();
var v = a.b.c.m;
  ''');
    expect(unit.topLevelVariables[1].type.toString(), 'dynamic');
  }

  test_infer_invokeConstructor_factoryRedirected() async {
    await checkFileElement(r'''
class A {
  factory A() = B;
}
class B implements A {}
var a = new A();
  ''');
  }

  test_infer_invokeConstructor_named() async {
    await checkFileElement(r'''
class A {
  A.aaa();
}
class B<K, V> {
  B.bbb();
}
var a = new A.aaa();
var b1 = new B.bbb();
var b2 = new B<int, String>.bbb();
var b3 = new B<List<int>, Map<List<int>, Set<String>>>.bbb();
  ''');
  }

  test_infer_invokeConstructor_named_importedWithPrefix() async {
    addFile(
        r'''
class A {
  A.aaa();
}
class B<K, V> {
  B.bbb();
}
''',
        name: '/a.dart');
    await checkFileElement(r'''
import 'a.dart' as p;
var a = new p.A.aaa();
var b1 = new p.B.bbb();
var b2 = new p.B<int, String>.bbb();
  ''');
  }

  test_infer_invokeConstructor_unnamed() async {
    await checkFileElement(r'''
class A {
  A();
}
class B<T> {
  B();
}
var a = new A();
var b1 = new B();
var b2 = new B<int>();
  ''');
  }

  test_infer_invokeConstructor_unnamed_synthetic() async {
    await checkFileElement(r'''
class A {}
class B<T> {}
var a = new A();
var b1 = new B();
var b2 = new B<int>();
  ''');
  }

  test_infer_invokeMethodRef_function() async {
    var unit = await checkFileElement(r'''
int m() => 0;
var a = m();
  ''');
    expect(unit.topLevelVariables[0].type.toString(), 'int');
  }

  test_infer_invokeMethodRef_function_generic() async {
    var unit = await checkFileElement(r'''
/*=Map<int, V>*/ m/*<V>*/(/*=V*/ a) => null;
var a = m(2.3);
  ''');
    expect(unit.topLevelVariables[0].type.toString(), 'Map<int, double>');
  }

  test_infer_invokeMethodRef_function_importedWithPrefix() async {
    addFile(
        r'''
int m() => 0;
''',
        name: '/a.dart');
    var unit = await checkFileElement(r'''
import 'a.dart' as p;
var a = p.m();
  ''');
    expect(unit.topLevelVariables[0].type.toString(), 'int');
  }

  test_infer_invokeMethodRef_method() async {
    var unit = await checkFileElement(r'''
class A {
  int m() => 0;
}
var a = new A();
var b = a.m();
  ''');
    expect(unit.topLevelVariables[1].type.toString(), 'int');
  }

  test_infer_invokeMethodRef_method_g() async {
    var unit = await checkFileElement(r'''
class A {
  /*=T*/ m/*<T>*/(/*=T*/ a) => null;
}
var a = new A();
var b = a.m(1.0);
  ''');
    expect(unit.topLevelVariables[1].type.toString(), 'double');
  }

  test_infer_invokeMethodRef_method_genericSequence() async {
    var unit = await checkFileElement(r'''
class A<T> {
  B<T> b = new B<T>();
}
class B<K> {
  C<List<K>, int> c = new C<List<K>, int>();
}
class C<K, V> {
  Map<K, V> m() => null;
}
var a = new A<double>();
var v = a.b.c.m();
  ''');
    expect(unit.topLevelVariables[1].type.toString(), 'dynamic');
  }

  test_infer_invokeMethodRef_method_gg() async {
    var unit = await checkFileElement(r'''
class A<K> {
  /*=Map<K, V>*/ m/*<V>*/(/*=V*/ a) => null;
}
var a = new A<int>();
var b = a.m(1.0);
  ''');
    expect(unit.topLevelVariables[1].type.toString(), 'Map<int, double>');
  }

  test_infer_invokeMethodRef_method_importedWithPrefix() async {
    addFile(
        r'''
class A {
  int m() => 0;
}
var a = new A();
''',
        name: '/a.dart');
    var unit = await checkFileElement(r'''
import 'a.dart' as p;
var b = p.a.m();
  ''');
    expect(unit.topLevelVariables[0].type.toString(), 'int');
  }

  test_infer_invokeMethodRef_method_importedWithPrefix2() async {
    addFile(
        r'''
class A {
  B b = new B();
}
class B {
  int m() => 0;
}
var a = new A();
''',
        name: '/a.dart');
    var unit = await checkFileElement(r'''
import 'a.dart' as p;
var b = p.a.b.m();
  ''');
    expect(unit.topLevelVariables[0].type.toString(), 'dynamic');
  }

  test_infer_invokeMethodRef_method_withInferredTypeInLibraryCycle() async {
    var unit = await checkFileElement('''
class Base {
  int m() => 0;
}
class A extends Base {
  m() => 0; // Inferred return type: int
}
var a = new A();
var b = a.m();
    ''');
    // Type inference operates on static and top level variables prior to
    // instance members.  So at the time `b` is inferred, `A.m` still has return
    // type `dynamic`.
    expect(unit.topLevelVariables[1].type.toString(), 'dynamic');
  }

  test_infer_invokeMethodRef_method_withInferredTypeOutsideLibraryCycle() async {
    addFile(
        '''
class Base {
  int m() => 0;
}
class A extends Base {
  m() => 0; // Inferred return type: int
}
''',
        name: '/a.dart');
    var unit = await checkFileElement('''
import 'a.dart';
var a = new A();
var b = a.m();
''');
    // Since a.dart is in a separate library file from the compilation unit
    // containing `a` and `b`, its types are inferred first; then `a` and `b`'s
    // types are inferred.  So the inferred return type of `int` should be
    // propagated to `b`.
    expect(unit.topLevelVariables[1].type.toString(), 'int');
  }

  @override
  @failingTest
  test_inferLocalFunctionReturnType() async {
    await super.test_inferLocalFunctionReturnType();
  }

  @override
  @failingTest
  test_inferredType_blockBodiedClosure_noArguments() async {
    await super.test_inferredType_blockBodiedClosure_noArguments();
  }

  @override
  @failingTest
  test_inferredType_blockClosure_noArgs_noReturn() async {
    await super.test_inferredType_blockClosure_noArgs_noReturn();
  }

  @override
  test_instantiateToBounds_typeName_OK_hasBound_definedAfter() async {
    shouldCompareElementsWithAnalysisContext = false;
    await super.test_instantiateToBounds_typeName_OK_hasBound_definedAfter();
  }

  test_invokeMethod_notGeneric_genericClass() async {
    var unit = await checkFileElement(r'''
class C<T> {
  T m(int a, {String b, T c}) => null;
}
var v = new C<double>().m(1, b: 'bbb', c: 2.0);
  ''');
    expect(unit.topLevelVariables[0].type.toString(), 'double');
  }

  test_invokeMethod_notGeneric_notGenericClass() async {
    var unit = await checkFileElement(r'''
class C {
  int m(int a, {String b, int c}) => null;
}
var v = new C().m(1, b: 'bbb', c: 2.0);
  ''');
    expect(unit.topLevelVariables[0].type.toString(), 'int');
  }

  @failingTest
  @override
  test_listLiteralsCanInferNull_topLevel() =>
      super.test_listLiteralsCanInferNull_topLevel();

  @failingTest
  @override
  test_mapLiteralsCanInferNull_topLevel() =>
      super.test_mapLiteralsCanInferNull_topLevel();

  @override
  @failingTest
  test_nullCoalescingOperator() async {
    await super.test_nullCoalescingOperator();
  }

  @override
  @failingTest
  test_unsafeBlockClosureInference_closureCall() async {
    await super.test_unsafeBlockClosureInference_closureCall();
  }

  @override
  @failingTest
  test_unsafeBlockClosureInference_constructorCall_implicitTypeParam() async {
    return super
        .test_unsafeBlockClosureInference_constructorCall_implicitTypeParam();
  }

  @override
  @failingTest
  test_unsafeBlockClosureInference_functionCall_explicitDynamicParam_viaExpr2() async {
    return super
        .test_unsafeBlockClosureInference_functionCall_explicitDynamicParam_viaExpr2();
  }

  @override
  @failingTest
  test_unsafeBlockClosureInference_functionCall_explicitDynamicParam_viaExpr2_comment() async {
    return super
        .test_unsafeBlockClosureInference_functionCall_explicitDynamicParam_viaExpr2_comment();
  }

  @override
  @failingTest
  test_unsafeBlockClosureInference_functionCall_explicitTypeParam_viaExpr2() async {
    return super
        .test_unsafeBlockClosureInference_functionCall_explicitTypeParam_viaExpr2();
  }

  @override
  @failingTest
  test_unsafeBlockClosureInference_functionCall_explicitTypeParam_viaExpr2_comment() async {
    return super
        .test_unsafeBlockClosureInference_functionCall_explicitTypeParam_viaExpr2_comment();
  }

  @override
  @failingTest
  test_unsafeBlockClosureInference_functionCall_implicitTypeParam() async {
    return super
        .test_unsafeBlockClosureInference_functionCall_implicitTypeParam();
  }

  @override
  @failingTest
  test_unsafeBlockClosureInference_functionCall_implicitTypeParam_comment() async {
    return super
        .test_unsafeBlockClosureInference_functionCall_implicitTypeParam_comment();
  }

  @override
  @failingTest
  test_unsafeBlockClosureInference_functionCall_implicitTypeParam_viaExpr() async {
    return super
        .test_unsafeBlockClosureInference_functionCall_implicitTypeParam_viaExpr();
  }

  @override
  @failingTest
  test_unsafeBlockClosureInference_functionCall_implicitTypeParam_viaExpr_comment() async {
    return super
        .test_unsafeBlockClosureInference_functionCall_implicitTypeParam_viaExpr_comment();
  }

  @override
  @failingTest
  test_unsafeBlockClosureInference_functionCall_noTypeParam_viaExpr() async {
    return super
        .test_unsafeBlockClosureInference_functionCall_noTypeParam_viaExpr();
  }

  @override
  @failingTest
  test_unsafeBlockClosureInference_inList_untyped() async {
    await super.test_unsafeBlockClosureInference_inList_untyped();
  }

  @override
  @failingTest
  test_unsafeBlockClosureInference_inMap_untyped() async {
    await super.test_unsafeBlockClosureInference_inMap_untyped();
  }

  @override
  @failingTest
  test_unsafeBlockClosureInference_methodCall_implicitTypeParam() async {
    return super
        .test_unsafeBlockClosureInference_methodCall_implicitTypeParam();
  }

  @override
  @failingTest
  test_unsafeBlockClosureInference_methodCall_implicitTypeParam_comment() async {
    return super
        .test_unsafeBlockClosureInference_methodCall_implicitTypeParam_comment();
  }

  LibraryElementImpl _checkSource(
      SummaryResynthesizer resynthesizer, Source source) {
    LibraryElementImpl resynthesized =
        resynthesizer.getLibraryElement(source.uri.toString());
    if (shouldCompareElementsWithAnalysisContext) {
      LibraryElementImpl original = context.computeLibraryElement(source);
      checkLibraryElements(original, resynthesized);
    }
    return resynthesized;
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
  test_instantiateToBounds_boundRefersToItself() async {
    await super.test_instantiateToBounds_boundRefersToItself();
  }

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

  void _reset() {
    serializedSources.clear();
    bundleAssembler = new PackageBundleAssembler();
    uriToUnit.clear();
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

  @override
  LibraryElementImpl checkLibrary(String text,
      {bool allowErrors: false, bool dumpSummaries: false}) {
    Source source = addTestSource(text);
    LibraryElementImpl resynthesized = _encodeDecodeLibraryElement(source);
    LibraryElementImpl original = context.computeLibraryElement(source);
    if (!allowErrors) {
      List<AnalysisError> errors = context.computeErrors(source);
      if (errors.where((e) => e.message.startsWith('unused')).isNotEmpty) {
        fail('Analysis errors: $errors');
      }
    }
    checkLibraryElements(original, resynthesized);
    return resynthesized;
  }

  @override
  void compareLocalElementsOfExecutable(ExecutableElement resynthesized,
      ExecutableElement original, String desc) {
    // We don't resynthesize local elements during link.
    // So, we should not compare them.
  }

  @override
  DartSdk createDartSdk() => AbstractContextTest.SHARED_MOCK_SDK;

  @override
  AnalysisOptionsImpl createOptions() =>
      super.createOptions()..strongMode = isStrongMode;

  @override
  TestSummaryResynthesizer encodeDecodeLibrarySource(Source source) {
    return _encodeLibrary(source);
  }
}
