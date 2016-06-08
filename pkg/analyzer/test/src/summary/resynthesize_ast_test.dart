// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.resynthesize_ast_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
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
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../context/abstract_context.dart';
import '../task/strong/inferred_type_test.dart';
import 'resynthesize_test.dart';
import 'summary_common.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(ResynthesizeAstTest);
  runReflectiveTests(AstInferredTypeTest);
}

@reflectiveTest
class AstInferredTypeTest extends AbstractResynthesizeTest
    with _AstResynthesizeTestMixin, InferredTypeMixin {
  bool get checkPropagatedTypes {
    // AST-based summaries do not yet handle propagated types.
    // TODO(paulberry): fix this.
    return false;
  }

  @override
  bool get mayCheckTypesOfLocals => false;

  @override
  void addFile(String content, {String name: '/main.dart'}) {
    addLibrarySource(name, content);
  }

  @override
  CompilationUnitElement checkFile(String content) {
    Source source = addSource('/main.dart', content);
    SummaryResynthesizer resynthesizer = _encodeLibrary(source);
    LibraryElementImpl resynthesized = _checkSource(resynthesizer, source);
    for (Source otherSource in otherLibrarySources) {
      _checkSource(resynthesizer, otherSource);
    }
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
  AnalysisOptionsImpl createOptions() => new AnalysisOptionsImpl()
    ..enableGenericMethods = true
    ..strongMode = true;

  @override
  @failingTest
  void test_blockBodiedLambdas_async_allReturnsAreFutures_topLevel() {
    super.test_blockBodiedLambdas_async_allReturnsAreFutures_topLevel();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_async_allReturnsAreValues_topLevel() {
    super.test_blockBodiedLambdas_async_allReturnsAreValues_topLevel();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_async_mixOfValuesAndFutures_topLevel() {
    super.test_blockBodiedLambdas_async_mixOfValuesAndFutures_topLevel();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_asyncStar_topLevel() {
    super.test_blockBodiedLambdas_asyncStar_topLevel();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_basic_topLevel() {
    super.test_blockBodiedLambdas_basic_topLevel();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_doesNotInferBottom_async_topLevel() {
    super.test_blockBodiedLambdas_doesNotInferBottom_async_topLevel();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_doesNotInferBottom_asyncStar_topLevel() {
    super.test_blockBodiedLambdas_doesNotInferBottom_asyncStar_topLevel();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_doesNotInferBottom_syncStar_topLevel() {
    super.test_blockBodiedLambdas_doesNotInferBottom_syncStar_topLevel();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_LUB_topLevel() {
    super.test_blockBodiedLambdas_LUB_topLevel();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_nestedLambdas_topLevel() {
    super.test_blockBodiedLambdas_nestedLambdas_topLevel();
  }

  @override
  @failingTest
  void test_blockBodiedLambdas_syncStar_topLevel() {
    super.test_blockBodiedLambdas_syncStar_topLevel();
  }

  @override
  void test_canInferAlsoFromStaticAndInstanceFieldsFlagOn() {
    variablesWithNotConstInitializers.add('a2');
    super.test_canInferAlsoFromStaticAndInstanceFieldsFlagOn();
  }

  @override
  @failingTest
  void test_circularReference_viaClosures_initializerTypes() {
    super.test_circularReference_viaClosures_initializerTypes();
  }

  @override
  @failingTest
  void test_genericMethods_inferJSBuiltin() {
    super.test_genericMethods_inferJSBuiltin();
  }

  void test_infer_extractIndex_custom() {
    var unit = checkFile('''
class A {
  String operator [](_) => null;
}
var a = new A();
var b = a[0];
  ''');
    expect(unit.topLevelVariables[1].type.toString(), 'String');
  }

  void test_infer_extractIndex_fromList() {
    var unit = checkFile('''
var a = <int>[1, 2, 3];
var b = a[0];
  ''');
    expect(unit.topLevelVariables[1].type.toString(), 'int');
  }

  void test_infer_extractIndex_fromMap() {
    var unit = checkFile('''
var a = <int, double>{};
var b = a[0];
  ''');
    expect(unit.topLevelVariables[1].type.toString(), 'double');
  }

  void test_infer_extractProperty_getter() {
    checkFile(r'''
var a = 1.isEven;
var b = 2.isNaN;
var c = 3.foo;
var d = foo.bar;
  ''');
  }

  void test_infer_extractProperty_getter_sequence() {
    var unit = checkFile(r'''
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
    expect(unit.topLevelVariables[1].type.toString(), 'int');
  }

  void test_infer_extractProperty_getter_sequence_generic() {
    var unit = checkFile(r'''
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
    expect(unit.topLevelVariables[1].type.toString(), 'Map<List<double>, int>');
  }

  void test_infer_extractProperty_getter_sequence_withUnresolved() {
    var unit = checkFile(r'''
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

  void test_infer_extractProperty_method() {
    var unit = checkFile(r'''
class A {
  int m(double p1, String p2) => 42;
}
var a = new A();
var v = a.m;
  ''');
    expect(unit.topLevelVariables[1].type.toString(), '(double, String) → int');
  }

  void test_infer_extractProperty_method2() {
    var unit = checkFile(r'''
var a = 1.round;
  ''');
    expect(unit.topLevelVariables[0].type.toString(), '() → int');
  }

  void test_infer_extractProperty_method_sequence() {
    var unit = checkFile(r'''
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
    expect(unit.topLevelVariables[1].type.toString(), '(double, String) → int');
  }

  void test_infer_invokeConstructor_factoryRedirected() {
    checkFile(r'''
class A {
  factory A() = B;
}
class B implements A {}
var a = new A();
  ''');
  }

  void test_infer_invokeConstructor_named() {
    checkFile(r'''
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

  void test_infer_invokeConstructor_named_importedWithPrefix() {
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
    checkFile(r'''
import 'a.dart' as p;
var a = new p.A.aaa();
var b1 = new p.B.bbb();
var b2 = new p.B<int, String>.bbb();
  ''');
  }

  void test_infer_invokeConstructor_unnamed() {
    checkFile(r'''
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

  void test_infer_invokeConstructor_unnamed_synthetic() {
    checkFile(r'''
class A {}
class B<T> {}
var a = new A();
var b1 = new B();
var b2 = new B<int>();
  ''');
  }

  void test_infer_invokeMethodRef_function() {
    var unit = checkFile(r'''
int m() => 0;
var a = m();
  ''');
    expect(unit.topLevelVariables[0].type.toString(), 'int');
  }

  void test_infer_invokeMethodRef_function_generic() {
    var unit = checkFile(r'''
/*=Map<int, V>*/ m/*<V>*/(/*=V*/ a) => null;
var a = m(2.3);
  ''');
    expect(unit.topLevelVariables[0].type.toString(), 'Map<int, double>');
  }

  void test_infer_invokeMethodRef_function_importedWithPrefix() {
    addFile(
        r'''
int m() => 0;
''',
        name: '/a.dart');
    var unit = checkFile(r'''
import 'a.dart' as p;
var a = p.m();
  ''');
    expect(unit.topLevelVariables[0].type.toString(), 'int');
  }

  void test_infer_invokeMethodRef_method() {
    var unit = checkFile(r'''
class A {
  int m() => 0;
}
var a = new A();
var b = a.m();
  ''');
    expect(unit.topLevelVariables[1].type.toString(), 'int');
  }

  void test_infer_invokeMethodRef_method_g() {
    var unit = checkFile(r'''
class A {
  /*=T*/ m/*<T>*/(/*=T*/ a) => null;
}
var a = new A();
var b = a.m(1.0);
  ''');
    expect(unit.topLevelVariables[1].type.toString(), 'double');
  }

  void test_infer_invokeMethodRef_method_genericSequence() {
    var unit = checkFile(r'''
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
    expect(unit.topLevelVariables[1].type.toString(), 'Map<List<double>, int>');
  }

  void test_infer_invokeMethodRef_method_gg() {
    var unit = checkFile(r'''
class A<K> {
  /*=Map<K, V>*/ m/*<V>*/(/*=V*/ a) => null;
}
var a = new A<int>();
var b = a.m(1.0);
  ''');
    expect(unit.topLevelVariables[1].type.toString(), 'Map<int, double>');
  }

  void test_infer_invokeMethodRef_method_importedWithPrefix() {
    addFile(
        r'''
class A {
  int m() => 0;
}
var a = new A();
''',
        name: '/a.dart');
    var unit = checkFile(r'''
import 'a.dart' as p;
var b = p.a.m();
  ''');
    expect(unit.topLevelVariables[0].type.toString(), 'int');
  }

  void test_infer_invokeMethodRef_method_importedWithPrefix2() {
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
    var unit = checkFile(r'''
import 'a.dart' as p;
var b = p.a.b.m();
  ''');
    expect(unit.topLevelVariables[0].type.toString(), 'int');
  }

  void test_infer_invokeMethodRef_method_withInferredTypeInLibraryCycle() {
    var unit = checkFile('''
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

  void test_infer_invokeMethodRef_method_withInferredTypeOutsideLibraryCycle() {
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
    var unit = checkFile('''
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
  void test_inferCorrectlyOnMultipleVariablesDeclaredTogether() {
    super.test_inferCorrectlyOnMultipleVariablesDeclaredTogether();
  }

  @override
  @failingTest
  void test_inferenceInCyclesIsDeterministic() {
    super.test_inferenceInCyclesIsDeterministic();
  }

  @override
  @failingTest
  void test_inferredType_opAssignToProperty_prefixedIdentifier() {
    super.test_inferredType_opAssignToProperty_prefixedIdentifier();
  }

  @override
  @failingTest
  void test_inferredType_opAssignToProperty_prefixedIdentifier_viaInterface() {
    super
        .test_inferredType_opAssignToProperty_prefixedIdentifier_viaInterface();
  }

  void test_invokeMethod_notGeneric_genericClass() {
    var unit = checkFile(r'''
class C<T> {
  T m(int a, {String b, T c}) => null;
}
var v = new C<double>().m(1, b: 'bbb', c: 2.0);
  ''');
    expect(unit.topLevelVariables[0].type.toString(), 'double');
  }

  void test_invokeMethod_notGeneric_notGenericClass() {
    var unit = checkFile(r'''
class C {
  int m(int a, {String b, int c}) => null;
}
var v = new C().m(1, b: 'bbb', c: 2.0);
  ''');
    expect(unit.topLevelVariables[0].type.toString(), 'int');
  }

  LibraryElementImpl _checkSource(
      SummaryResynthesizer resynthesizer, Source source) {
    LibraryElementImpl resynthesized =
        resynthesizer.getLibraryElement(source.uri.toString());
    LibraryElementImpl original = context.computeLibraryElement(source);
    checkLibraryElements(original, resynthesized);
    return resynthesized;
  }
}

@reflectiveTest
class ResynthesizeAstTest extends ResynthesizeTest
    with _AstResynthesizeTestMixin {
  @override
  bool get checkPropagatedTypes => false;

  @override
  LibraryElementImpl checkLibrary(String text,
      {bool allowErrors: false, bool dumpSummaries: false}) {
    Source source = addTestSource(text);
    LibraryElementImpl resynthesized = _encodeDecodeLibraryElement(source);
    LibraryElementImpl original = context.computeLibraryElement(source);
    checkLibraryElements(original, resynthesized);
    return resynthesized;
  }

  @override
  DartSdk createDartSdk() => AbstractContextTest.SHARED_MOCK_SDK;

  @override
  TestSummaryResynthesizer encodeDecodeLibrarySource(Source source) {
    return _encodeLibrary(source);
  }
}

/**
 * Abstract mixin for serializing ASTs and resynthesizing elements from it.
 */
abstract class _AstResynthesizeTestMixin {
  final Set<Source> serializedSources = new Set<Source>();
  final PackageBundleAssembler bundleAssembler = new PackageBundleAssembler();
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
      if (linkedLibrary == null) {
        fail('Linker unexpectedly requested LinkedLibrary for "$absoluteUri".'
            '  Libraries available: ${sdkLibraries.keys}');
      }
      return linkedLibrary;
    }

    UnlinkedUnit getUnit(String absoluteUri) {
      UnlinkedUnit unit = uriToUnit[absoluteUri] ??
          SerializedMockSdk.instance.uriToUnlinkedUnit[absoluteUri];
      if (unit == null) {
        fail('Linker unexpectedly requested unit for "$absoluteUri".');
      }
      return unit;
    }

    Set<String> nonSdkLibraryUris = context.sources
        .where((Source source) =>
            !source.isInSystemLibrary &&
            context.computeKindOf(source) == SourceKind.LIBRARY)
        .map((Source source) => source.uri.toString())
        .toSet();

    Map<String, LinkedLibrary> linkedSummaries = link(nonSdkLibraryUris,
        getDependency, getUnit, context.analysisOptions.strongMode);

    return new TestSummaryResynthesizer(
        null,
        context,
        new Map<String, UnlinkedUnit>()
          ..addAll(SerializedMockSdk.instance.uriToUnlinkedUnit)
          ..addAll(unlinkedSummaries),
        new Map<String, LinkedLibrary>()
          ..addAll(SerializedMockSdk.instance.uriToLinkedLibrary)
          ..addAll(linkedSummaries));
  }

  UnlinkedUnit _getUnlinkedUnit(Source source) {
    String uriStr = source.uri.toString();
    {
      UnlinkedUnit unlinkedUnitInSdk =
          SerializedMockSdk.instance.uriToUnlinkedUnit[uriStr];
      if (unlinkedUnitInSdk != null) {
        return unlinkedUnitInSdk;
      }
    }
    return uriToUnit.putIfAbsent(uriStr, () {
      CompilationUnit unit = context.computeResult(source, PARSED_UNIT);
      UnlinkedUnitBuilder unlinkedUnit = serializeAstUnlinked(unit);
      bundleAssembler.addUnlinkedUnit(source, unlinkedUnit);
      return unlinkedUnit;
    });
  }

  void _serializeLibrary(Source librarySource) {
    if (librarySource.isInSystemLibrary) {
      return;
    }
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

    UnlinkedUnit getPart(String relativeUri) {
      return _getUnlinkedUnit(resolveRelativeUri(relativeUri));
    }

    UnlinkedPublicNamespace getImport(String relativeUri) {
      return getPart(relativeUri).publicNamespace;
    }

    UnlinkedUnit definingUnit = _getUnlinkedUnit(librarySource);
    LinkedLibraryBuilder linkedLibrary =
        prelink(definingUnit, getPart, getImport);
    linkedLibrary.dependencies.skip(1).forEach((LinkedDependency d) {
      _serializeLibrary(resolveRelativeUri(d.uri));
    });
  }
}
