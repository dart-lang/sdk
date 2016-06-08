// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.resolver_test;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine_io.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import '../utils.dart';
import 'analysis_context_factory.dart';
import 'resolver_test_case.dart';
import 'test_support.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(AnalysisDeltaTest);
  runReflectiveTests(ChangeSetTest);
  runReflectiveTests(DisableAsyncTestCase);
  runReflectiveTests(EnclosedScopeTest);
  runReflectiveTests(ErrorResolverTest);
  runReflectiveTests(LibraryImportScopeTest);
  runReflectiveTests(LibraryScopeTest);
  runReflectiveTests(PrefixedNamespaceTest);
  runReflectiveTests(ScopeTest);
  runReflectiveTests(StrictModeTest);
  runReflectiveTests(SubtypeManagerTest);
  runReflectiveTests(TypeOverrideManagerTest);
  runReflectiveTests(TypePropagationTest);
  runReflectiveTests(TypeProviderImplTest);
  runReflectiveTests(TypeResolverVisitorTest);
}

@reflectiveTest
class AnalysisDeltaTest extends EngineTestCase {
  TestSource source1 = new TestSource('/1.dart');
  TestSource source2 = new TestSource('/2.dart');
  TestSource source3 = new TestSource('/3.dart');

  void test_getAddedSources() {
    AnalysisDelta delta = new AnalysisDelta();
    delta.setAnalysisLevel(source1, AnalysisLevel.ALL);
    delta.setAnalysisLevel(source2, AnalysisLevel.ERRORS);
    delta.setAnalysisLevel(source3, AnalysisLevel.NONE);
    List<Source> addedSources = delta.addedSources;
    expect(addedSources, hasLength(2));
    expect(addedSources, unorderedEquals([source1, source2]));
  }

  void test_getAnalysisLevels() {
    AnalysisDelta delta = new AnalysisDelta();
    expect(delta.analysisLevels.length, 0);
  }

  void test_setAnalysisLevel() {
    AnalysisDelta delta = new AnalysisDelta();
    delta.setAnalysisLevel(source1, AnalysisLevel.ALL);
    delta.setAnalysisLevel(source2, AnalysisLevel.ERRORS);
    Map<Source, AnalysisLevel> levels = delta.analysisLevels;
    expect(levels.length, 2);
    expect(levels[source1], AnalysisLevel.ALL);
    expect(levels[source2], AnalysisLevel.ERRORS);
  }

  void test_toString() {
    AnalysisDelta delta = new AnalysisDelta();
    delta.setAnalysisLevel(new TestSource(), AnalysisLevel.ALL);
    String result = delta.toString();
    expect(result, isNotNull);
    expect(result.length > 0, isTrue);
  }
}

@reflectiveTest
class ChangeSetTest extends EngineTestCase {
  void test_changedContent() {
    TestSource source = new TestSource();
    String content = "";
    ChangeSet changeSet = new ChangeSet();
    changeSet.changedContent(source, content);
    expect(changeSet.addedSources, hasLength(0));
    expect(changeSet.changedSources, hasLength(0));
    Map<Source, String> map = changeSet.changedContents;
    expect(map, hasLength(1));
    expect(map[source], same(content));
    expect(changeSet.changedRanges, hasLength(0));
    expect(changeSet.deletedSources, hasLength(0));
    expect(changeSet.removedSources, hasLength(0));
    expect(changeSet.removedContainers, hasLength(0));
  }

  void test_changedRange() {
    TestSource source = new TestSource();
    String content = "";
    ChangeSet changeSet = new ChangeSet();
    changeSet.changedRange(source, content, 1, 2, 3);
    expect(changeSet.addedSources, hasLength(0));
    expect(changeSet.changedSources, hasLength(0));
    expect(changeSet.changedContents, hasLength(0));
    Map<Source, ChangeSet_ContentChange> map = changeSet.changedRanges;
    expect(map, hasLength(1));
    ChangeSet_ContentChange change = map[source];
    expect(change, isNotNull);
    expect(change.contents, content);
    expect(change.offset, 1);
    expect(change.oldLength, 2);
    expect(change.newLength, 3);
    expect(changeSet.deletedSources, hasLength(0));
    expect(changeSet.removedSources, hasLength(0));
    expect(changeSet.removedContainers, hasLength(0));
  }

  void test_toString() {
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(new TestSource());
    changeSet.changedSource(new TestSource());
    changeSet.changedContent(new TestSource(), "");
    changeSet.changedRange(new TestSource(), "", 0, 0, 0);
    changeSet.deletedSource(new TestSource());
    changeSet.removedSource(new TestSource());
    changeSet
        .removedContainer(new SourceContainer_ChangeSetTest_test_toString());
    expect(changeSet.toString(), isNotNull);
  }
}

@reflectiveTest
class DisableAsyncTestCase extends ResolverTestCase {
  @override
  void setUp() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableAsync = false;
    resetWithOptions(options);
  }

  void test_resolve() {
    Source source = addSource(r'''
class C {
  foo() {
    bar();
  }
  bar() {
    //
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, []);
  }

  void test_resolve_async() {
    Source source = addSource(r'''
class C {
  Future foo() async {
    await bar();
    return null;
  }
  Future bar() {
    return new Future.delayed(new Duration(milliseconds: 10));
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      StaticWarningCode.UNDEFINED_CLASS,
      StaticWarningCode.UNDEFINED_CLASS,
      StaticWarningCode.UNDEFINED_CLASS,
      StaticWarningCode.UNDEFINED_CLASS,
      ParserErrorCode.ASYNC_NOT_SUPPORTED
    ]);
  }
}

@reflectiveTest
class EnclosedScopeTest extends ResolverTestCase {
  void test_define_duplicate() {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scope rootScope =
        new Scope_EnclosedScopeTest_test_define_duplicate(listener);
    EnclosedScope scope = new EnclosedScope(rootScope);
    VariableElement element1 =
        ElementFactory.localVariableElement(AstFactory.identifier3("v1"));
    VariableElement element2 =
        ElementFactory.localVariableElement(AstFactory.identifier3("v1"));
    scope.define(element1);
    scope.define(element2);
    listener.assertErrorsWithSeverities([ErrorSeverity.ERROR]);
  }

  void test_define_normal() {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scope rootScope = new Scope_EnclosedScopeTest_test_define_normal(listener);
    EnclosedScope outerScope = new EnclosedScope(rootScope);
    EnclosedScope innerScope = new EnclosedScope(outerScope);
    VariableElement element1 =
        ElementFactory.localVariableElement(AstFactory.identifier3("v1"));
    VariableElement element2 =
        ElementFactory.localVariableElement(AstFactory.identifier3("v2"));
    outerScope.define(element1);
    innerScope.define(element2);
    listener.assertNoErrors();
  }
}

@reflectiveTest
class ErrorResolverTest extends ResolverTestCase {
  void test_breakLabelOnSwitchMember() {
    Source source = addSource(r'''
class A {
  void m(int i) {
    switch (i) {
      l: case 0:
        break;
      case 1:
        break l;
    }
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [ResolverErrorCode.BREAK_LABEL_ON_SWITCH_MEMBER]);
    verify([source]);
  }

  void test_continueLabelOnSwitch() {
    Source source = addSource(r'''
class A {
  void m(int i) {
    l: switch (i) {
      case 0:
        continue l;
    }
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [ResolverErrorCode.CONTINUE_LABEL_ON_SWITCH]);
    verify([source]);
  }

  void test_enclosingElement_invalidLocalFunction() {
    Source source = addSource(r'''
class C {
  C() {
    int get x => 0;
  }
}''');
    LibraryElement library = resolve2(source);
    expect(library, isNotNull);
    var unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    var types = unit.types;
    expect(types, isNotNull);
    expect(types, hasLength(1));
    var type = types[0];
    expect(type, isNotNull);
    var constructors = type.constructors;
    expect(constructors, isNotNull);
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    List<FunctionElement> functions = constructor.functions;
    expect(functions, isNotNull);
    expect(functions, hasLength(1));
    expect(functions[0].enclosingElement, constructor);
    assertErrors(source, [ParserErrorCode.GETTER_IN_FUNCTION]);
  }
}

/**
 * Tests for generic method and function resolution that do not use strong mode.
 */
@reflectiveTest
class GenericMethodResolverTest extends StaticTypeAnalyzer2TestShared {
  void setUp() {
    super.setUp();
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableGenericMethods = true;
    resetWithOptions(options);
  }

  void test_genericMethod_propagatedType_promotion() {
    // Regression test for:
    // https://github.com/dart-lang/sdk/issues/25340
    //
    // Note, after https://github.com/dart-lang/sdk/issues/25486 the original
    // strong mode example won't work, as we now compute a static type and
    // therefore discard the propagated type.
    //
    // So this test does not use strong mode.
    resolveTestUnit(r'''
abstract class Iter {
  List<S> map<S>(S f(x));
}
class C {}
C toSpan(dynamic element) {
  if (element is Iter) {
    var y = element.map(toSpan);
  }
  return null;
}''');
    expectIdentifierType('y = ', 'dynamic', 'List<dynamic>');
  }
}

@reflectiveTest
class LibraryImportScopeTest extends ResolverTestCase {
  void test_conflictingImports() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    String typeNameA = "A";
    String typeNameB = "B";
    String typeNameC = "C";
    ClassElement typeA = ElementFactory.classElement2(typeNameA);
    ClassElement typeB1 = ElementFactory.classElement2(typeNameB);
    ClassElement typeB2 = ElementFactory.classElement2(typeNameB);
    ClassElement typeC = ElementFactory.classElement2(typeNameC);
    LibraryElement importedLibrary1 = createTestLibrary(context, "imported1");
    (importedLibrary1.definingCompilationUnit as CompilationUnitElementImpl)
        .types = <ClassElement>[typeA, typeB1];
    ImportElementImpl import1 =
        ElementFactory.importFor(importedLibrary1, null);
    LibraryElement importedLibrary2 = createTestLibrary(context, "imported2");
    (importedLibrary2.definingCompilationUnit as CompilationUnitElementImpl)
        .types = <ClassElement>[typeB2, typeC];
    ImportElementImpl import2 =
        ElementFactory.importFor(importedLibrary2, null);
    LibraryElementImpl importingLibrary =
        createTestLibrary(context, "importing");
    importingLibrary.imports = <ImportElement>[import1, import2];
    {
      GatheringErrorListener errorListener = new GatheringErrorListener();
      Scope scope = new LibraryImportScope(importingLibrary, errorListener);
      expect(scope.lookup(AstFactory.identifier3(typeNameA), importingLibrary),
          typeA);
      errorListener.assertNoErrors();
      expect(scope.lookup(AstFactory.identifier3(typeNameC), importingLibrary),
          typeC);
      errorListener.assertNoErrors();
      Element element =
          scope.lookup(AstFactory.identifier3(typeNameB), importingLibrary);
      errorListener.assertErrorsWithCodes([StaticWarningCode.AMBIGUOUS_IMPORT]);
      EngineTestCase.assertInstanceOf((obj) => obj is MultiplyDefinedElement,
          MultiplyDefinedElement, element);
      List<Element> conflictingElements =
          (element as MultiplyDefinedElement).conflictingElements;
      expect(conflictingElements, hasLength(2));
      if (identical(conflictingElements[0], typeB1)) {
        expect(conflictingElements[1], same(typeB2));
      } else if (identical(conflictingElements[0], typeB2)) {
        expect(conflictingElements[1], same(typeB1));
      } else {
        expect(conflictingElements[0], same(typeB1));
      }
    }
    {
      GatheringErrorListener errorListener = new GatheringErrorListener();
      Scope scope = new LibraryImportScope(importingLibrary, errorListener);
      Identifier identifier = AstFactory.identifier3(typeNameB);
      AstFactory.methodDeclaration(null, AstFactory.typeName3(identifier), null,
          null, AstFactory.identifier3("foo"), null);
      Element element = scope.lookup(identifier, importingLibrary);
      errorListener.assertErrorsWithCodes([StaticWarningCode.AMBIGUOUS_IMPORT]);
      EngineTestCase.assertInstanceOf((obj) => obj is MultiplyDefinedElement,
          MultiplyDefinedElement, element);
    }
  }

  void test_creation_empty() {
    LibraryElement definingLibrary = createDefaultTestLibrary();
    GatheringErrorListener errorListener = new GatheringErrorListener();
    new LibraryImportScope(definingLibrary, errorListener);
  }

  void test_creation_nonEmpty() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    String importedTypeName = "A";
    ClassElement importedType =
        new ClassElementImpl.forNode(AstFactory.identifier3(importedTypeName));
    LibraryElement importedLibrary = createTestLibrary(context, "imported");
    (importedLibrary.definingCompilationUnit as CompilationUnitElementImpl)
        .types = <ClassElement>[importedType];
    LibraryElementImpl definingLibrary =
        createTestLibrary(context, "importing");
    ImportElementImpl importElement = new ImportElementImpl(0);
    importElement.importedLibrary = importedLibrary;
    definingLibrary.imports = <ImportElement>[importElement];
    GatheringErrorListener errorListener = new GatheringErrorListener();
    Scope scope = new LibraryImportScope(definingLibrary, errorListener);
    expect(
        scope.lookup(AstFactory.identifier3(importedTypeName), definingLibrary),
        importedType);
  }

  void test_getErrorListener() {
    LibraryElement definingLibrary = createDefaultTestLibrary();
    GatheringErrorListener errorListener = new GatheringErrorListener();
    LibraryImportScope scope =
        new LibraryImportScope(definingLibrary, errorListener);
    expect(scope.errorListener, errorListener);
  }

  void test_nonConflictingImports_fromSdk() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    String typeName = "List";
    ClassElement type = ElementFactory.classElement2(typeName);
    LibraryElement importedLibrary = createTestLibrary(context, "lib");
    (importedLibrary.definingCompilationUnit as CompilationUnitElementImpl)
        .types = <ClassElement>[type];
    ImportElementImpl importCore = ElementFactory.importFor(
        context.getLibraryElement(context.sourceFactory.forUri("dart:core")),
        null);
    ImportElementImpl importLib =
        ElementFactory.importFor(importedLibrary, null);
    LibraryElementImpl importingLibrary =
        createTestLibrary(context, "importing");
    importingLibrary.imports = <ImportElement>[importCore, importLib];
    GatheringErrorListener errorListener = new GatheringErrorListener();
    Scope scope = new LibraryImportScope(importingLibrary, errorListener);
    expect(
        scope.lookup(AstFactory.identifier3(typeName), importingLibrary), type);
    errorListener
        .assertErrorsWithCodes([StaticWarningCode.CONFLICTING_DART_IMPORT]);
  }

  void test_nonConflictingImports_sameElement() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    String typeNameA = "A";
    String typeNameB = "B";
    ClassElement typeA = ElementFactory.classElement2(typeNameA);
    ClassElement typeB = ElementFactory.classElement2(typeNameB);
    LibraryElement importedLibrary = createTestLibrary(context, "imported");
    (importedLibrary.definingCompilationUnit as CompilationUnitElementImpl)
        .types = <ClassElement>[typeA, typeB];
    ImportElementImpl import1 = ElementFactory.importFor(importedLibrary, null);
    ImportElementImpl import2 = ElementFactory.importFor(importedLibrary, null);
    LibraryElementImpl importingLibrary =
        createTestLibrary(context, "importing");
    importingLibrary.imports = <ImportElement>[import1, import2];
    GatheringErrorListener errorListener = new GatheringErrorListener();
    Scope scope = new LibraryImportScope(importingLibrary, errorListener);
    expect(scope.lookup(AstFactory.identifier3(typeNameA), importingLibrary),
        typeA);
    errorListener.assertNoErrors();
    expect(scope.lookup(AstFactory.identifier3(typeNameB), importingLibrary),
        typeB);
    errorListener.assertNoErrors();
  }

  void test_prefixedAndNonPrefixed() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    String typeName = "C";
    String prefixName = "p";
    ClassElement prefixedType = ElementFactory.classElement2(typeName);
    ClassElement nonPrefixedType = ElementFactory.classElement2(typeName);
    LibraryElement prefixedLibrary =
        createTestLibrary(context, "import.prefixed");
    (prefixedLibrary.definingCompilationUnit as CompilationUnitElementImpl)
        .types = <ClassElement>[prefixedType];
    ImportElementImpl prefixedImport = ElementFactory.importFor(
        prefixedLibrary, ElementFactory.prefix(prefixName));
    LibraryElement nonPrefixedLibrary =
        createTestLibrary(context, "import.nonPrefixed");
    (nonPrefixedLibrary.definingCompilationUnit as CompilationUnitElementImpl)
        .types = <ClassElement>[nonPrefixedType];
    ImportElementImpl nonPrefixedImport =
        ElementFactory.importFor(nonPrefixedLibrary, null);
    LibraryElementImpl importingLibrary =
        createTestLibrary(context, "importing");
    importingLibrary.imports = <ImportElement>[
      prefixedImport,
      nonPrefixedImport
    ];
    GatheringErrorListener errorListener = new GatheringErrorListener();
    Scope scope = new LibraryImportScope(importingLibrary, errorListener);
    Element prefixedElement = scope.lookup(
        AstFactory.identifier5(prefixName, typeName), importingLibrary);
    errorListener.assertNoErrors();
    expect(prefixedElement, same(prefixedType));
    Element nonPrefixedElement =
        scope.lookup(AstFactory.identifier3(typeName), importingLibrary);
    errorListener.assertNoErrors();
    expect(nonPrefixedElement, same(nonPrefixedType));
  }
}

@reflectiveTest
class LibraryScopeTest extends ResolverTestCase {
  void test_creation_empty() {
    LibraryElement definingLibrary = createDefaultTestLibrary();
    GatheringErrorListener errorListener = new GatheringErrorListener();
    new LibraryScope(definingLibrary, errorListener);
  }

  void test_creation_nonEmpty() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    String importedTypeName = "A";
    ClassElement importedType =
        new ClassElementImpl.forNode(AstFactory.identifier3(importedTypeName));
    LibraryElement importedLibrary = createTestLibrary(context, "imported");
    (importedLibrary.definingCompilationUnit as CompilationUnitElementImpl)
        .types = <ClassElement>[importedType];
    LibraryElementImpl definingLibrary =
        createTestLibrary(context, "importing");
    ImportElementImpl importElement = new ImportElementImpl(0);
    importElement.importedLibrary = importedLibrary;
    definingLibrary.imports = <ImportElement>[importElement];
    GatheringErrorListener errorListener = new GatheringErrorListener();
    Scope scope = new LibraryScope(definingLibrary, errorListener);
    expect(
        scope.lookup(AstFactory.identifier3(importedTypeName), definingLibrary),
        importedType);
  }

  void test_getErrorListener() {
    LibraryElement definingLibrary = createDefaultTestLibrary();
    GatheringErrorListener errorListener = new GatheringErrorListener();
    LibraryScope scope = new LibraryScope(definingLibrary, errorListener);
    expect(scope.errorListener, errorListener);
  }
}

@reflectiveTest
class PrefixedNamespaceTest extends ResolverTestCase {
  void test_lookup_missing() {
    ClassElement element = ElementFactory.classElement2('A');
    PrefixedNamespace namespace = new PrefixedNamespace('p', _toMap([element]));
    expect(namespace.get('p.B'), isNull);
  }

  void test_lookup_missing_matchesPrefix() {
    ClassElement element = ElementFactory.classElement2('A');
    PrefixedNamespace namespace = new PrefixedNamespace('p', _toMap([element]));
    expect(namespace.get('p'), isNull);
  }

  void test_lookup_valid() {
    ClassElement element = ElementFactory.classElement2('A');
    PrefixedNamespace namespace = new PrefixedNamespace('p', _toMap([element]));
    expect(namespace.get('p.A'), same(element));
  }

  HashMap<String, Element> _toMap(List<Element> elements) {
    HashMap<String, Element> map = new HashMap<String, Element>();
    for (Element element in elements) {
      map[element.name] = element;
    }
    return map;
  }
}

class Scope_EnclosedScopeTest_test_define_duplicate extends Scope {
  GatheringErrorListener listener;

  Scope_EnclosedScopeTest_test_define_duplicate(this.listener) : super();

  @override
  AnalysisErrorListener get errorListener => listener;

  @override
  Element internalLookup(Identifier identifier, String name,
          LibraryElement referencingLibrary) =>
      null;
}

class Scope_EnclosedScopeTest_test_define_normal extends Scope {
  GatheringErrorListener listener;

  Scope_EnclosedScopeTest_test_define_normal(this.listener) : super();

  @override
  AnalysisErrorListener get errorListener => listener;

  @override
  Element internalLookup(Identifier identifier, String name,
          LibraryElement referencingLibrary) =>
      null;
}

@reflectiveTest
class ScopeTest extends ResolverTestCase {
  void test_define_duplicate() {
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ScopeTest_TestScope scope = new ScopeTest_TestScope(errorListener);
    VariableElement element1 =
        ElementFactory.localVariableElement(AstFactory.identifier3("v1"));
    VariableElement element2 =
        ElementFactory.localVariableElement(AstFactory.identifier3("v1"));
    scope.define(element1);
    scope.define(element2);
    errorListener.assertErrorsWithSeverities([ErrorSeverity.ERROR]);
  }

  void test_define_normal() {
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ScopeTest_TestScope scope = new ScopeTest_TestScope(errorListener);
    VariableElement element1 =
        ElementFactory.localVariableElement(AstFactory.identifier3("v1"));
    VariableElement element2 =
        ElementFactory.localVariableElement(AstFactory.identifier3("v2"));
    scope.define(element1);
    scope.define(element2);
    errorListener.assertNoErrors();
  }

  void test_getErrorListener() {
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ScopeTest_TestScope scope = new ScopeTest_TestScope(errorListener);
    expect(scope.errorListener, errorListener);
  }

  void test_isPrivateName_nonPrivate() {
    expect(Scope.isPrivateName("Public"), isFalse);
  }

  void test_isPrivateName_private() {
    expect(Scope.isPrivateName("_Private"), isTrue);
  }
}

/**
 * A non-abstract subclass that can be used for testing purposes.
 */
class ScopeTest_TestScope extends Scope {
  /**
   * The listener that is to be informed when an error is encountered.
   */
  final AnalysisErrorListener errorListener;

  ScopeTest_TestScope(this.errorListener);

  @override
  Element internalLookup(Identifier identifier, String name,
          LibraryElement referencingLibrary) =>
      localLookup(name, referencingLibrary);
}

class SourceContainer_ChangeSetTest_test_toString implements SourceContainer {
  @override
  bool contains(Source source) => false;
}

/**
 * Instances of the class `StaticTypeVerifier` verify that all of the nodes in an AST
 * structure that should have a static type associated with them do have a static type.
 */
class StaticTypeVerifier extends GeneralizingAstVisitor<Object> {
  /**
   * A list containing all of the AST Expression nodes that were not resolved.
   */
  List<Expression> _unresolvedExpressions = new List<Expression>();

  /**
   * A list containing all of the AST Expression nodes for which a propagated type was computed but
   * where that type was not more specific than the static type.
   */
  List<Expression> _invalidlyPropagatedExpressions = new List<Expression>();

  /**
   * A list containing all of the AST TypeName nodes that were not resolved.
   */
  List<TypeName> _unresolvedTypes = new List<TypeName>();

  /**
   * Counter for the number of Expression nodes visited that are resolved.
   */
  int _resolvedExpressionCount = 0;

  /**
   * Counter for the number of Expression nodes visited that have propagated type information.
   */
  int _propagatedExpressionCount = 0;

  /**
   * Counter for the number of TypeName nodes visited that are resolved.
   */
  int _resolvedTypeCount = 0;

  /**
   * Assert that all of the visited nodes have a static type associated with them.
   */
  void assertResolved() {
    if (!_unresolvedExpressions.isEmpty || !_unresolvedTypes.isEmpty) {
      StringBuffer buffer = new StringBuffer();
      int unresolvedTypeCount = _unresolvedTypes.length;
      if (unresolvedTypeCount > 0) {
        buffer.write("Failed to resolve ");
        buffer.write(unresolvedTypeCount);
        buffer.write(" of ");
        buffer.write(_resolvedTypeCount + unresolvedTypeCount);
        buffer.writeln(" type names:");
        for (TypeName identifier in _unresolvedTypes) {
          buffer.write("  ");
          buffer.write(identifier.toString());
          buffer.write(" (");
          buffer.write(_getFileName(identifier));
          buffer.write(" : ");
          buffer.write(identifier.offset);
          buffer.writeln(")");
        }
      }
      int unresolvedExpressionCount = _unresolvedExpressions.length;
      if (unresolvedExpressionCount > 0) {
        buffer.writeln("Failed to resolve ");
        buffer.write(unresolvedExpressionCount);
        buffer.write(" of ");
        buffer.write(_resolvedExpressionCount + unresolvedExpressionCount);
        buffer.writeln(" expressions:");
        for (Expression expression in _unresolvedExpressions) {
          buffer.write("  ");
          buffer.write(expression.toString());
          buffer.write(" (");
          buffer.write(_getFileName(expression));
          buffer.write(" : ");
          buffer.write(expression.offset);
          buffer.writeln(")");
        }
      }
      int invalidlyPropagatedExpressionCount =
          _invalidlyPropagatedExpressions.length;
      if (invalidlyPropagatedExpressionCount > 0) {
        buffer.writeln("Incorrectly propagated ");
        buffer.write(invalidlyPropagatedExpressionCount);
        buffer.write(" of ");
        buffer.write(_propagatedExpressionCount);
        buffer.writeln(" expressions:");
        for (Expression expression in _invalidlyPropagatedExpressions) {
          buffer.write("  ");
          buffer.write(expression.toString());
          buffer.write(" [");
          buffer.write(expression.staticType.displayName);
          buffer.write(", ");
          buffer.write(expression.propagatedType.displayName);
          buffer.writeln("]");
          buffer.write("    ");
          buffer.write(_getFileName(expression));
          buffer.write(" : ");
          buffer.write(expression.offset);
          buffer.writeln(")");
        }
      }
      fail(buffer.toString());
    }
  }

  @override
  Object visitBreakStatement(BreakStatement node) => null;

  @override
  Object visitCommentReference(CommentReference node) => null;

  @override
  Object visitContinueStatement(ContinueStatement node) => null;

  @override
  Object visitExportDirective(ExportDirective node) => null;

  @override
  Object visitExpression(Expression node) {
    node.visitChildren(this);
    DartType staticType = node.staticType;
    if (staticType == null) {
      _unresolvedExpressions.add(node);
    } else {
      _resolvedExpressionCount++;
      DartType propagatedType = node.propagatedType;
      if (propagatedType != null) {
        _propagatedExpressionCount++;
        if (!propagatedType.isMoreSpecificThan(staticType)) {
          _invalidlyPropagatedExpressions.add(node);
        }
      }
    }
    return null;
  }

  @override
  Object visitImportDirective(ImportDirective node) => null;

  @override
  Object visitLabel(Label node) => null;

  @override
  Object visitLibraryIdentifier(LibraryIdentifier node) => null;

  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    // In cases where we have a prefixed identifier where the prefix is dynamic,
    // we don't want to assert that the node will have a type.
    if (node.staticType == null && node.prefix.staticType.isDynamic) {
      return null;
    }
    return super.visitPrefixedIdentifier(node);
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    // In cases where identifiers are being used for something other than an
    // expressions, then they can be ignored.
    AstNode parent = node.parent;
    if (parent is MethodInvocation && identical(node, parent.methodName)) {
      return null;
    } else if (parent is RedirectingConstructorInvocation &&
        identical(node, parent.constructorName)) {
      return null;
    } else if (parent is SuperConstructorInvocation &&
        identical(node, parent.constructorName)) {
      return null;
    } else if (parent is ConstructorName && identical(node, parent.name)) {
      return null;
    } else if (parent is ConstructorFieldInitializer &&
        identical(node, parent.fieldName)) {
      return null;
    } else if (node.staticElement is PrefixElement) {
      // Prefixes don't have a type.
      return null;
    }
    return super.visitSimpleIdentifier(node);
  }

  @override
  Object visitTypeName(TypeName node) {
    // Note: do not visit children from this node, the child SimpleIdentifier in
    // TypeName (i.e. "String") does not have a static type defined.
    if (node.type == null) {
      _unresolvedTypes.add(node);
    } else {
      _resolvedTypeCount++;
    }
    return null;
  }

  String _getFileName(AstNode node) {
    // TODO (jwren) there are two copies of this method, one here and one in
    // ResolutionVerifier, they should be resolved into a single method
    if (node != null) {
      AstNode root = node.root;
      if (root is CompilationUnit) {
        CompilationUnit rootCU = root;
        if (rootCU.element != null) {
          return rootCU.element.source.fullName;
        } else {
          return "<unknown file- CompilationUnit.getElement() returned null>";
        }
      } else {
        return "<unknown file- CompilationUnit.getRoot() is not a CompilationUnit>";
      }
    }
    return "<unknown file- ASTNode is null>";
  }
}

/**
 * The class `StrictModeTest` contains tests to ensure that the correct errors and warnings
 * are reported when the analysis engine is run in strict mode.
 */
@reflectiveTest
class StrictModeTest extends ResolverTestCase {
  void fail_for() {
    Source source = addSource(r'''
int f(List<int> list) {
  num sum = 0;
  for (num i = 0; i < list.length; i++) {
    sum += list[i];
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  @override
  void setUp() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.hint = false;
    resetWithOptions(options);
  }

  void test_assert_is() {
    Source source = addSource(r'''
int f(num n) {
  assert (n is int);
  return n & 0x0F;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_conditional_and_is() {
    Source source = addSource(r'''
int f(num n) {
  return (n is int && n > 0) ? n & 0x0F : 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_conditional_is() {
    Source source = addSource(r'''
int f(num n) {
  return (n is int) ? n & 0x0F : 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_conditional_isNot() {
    Source source = addSource(r'''
int f(num n) {
  return (n is! int) ? 0 : n & 0x0F;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_conditional_or_is() {
    Source source = addSource(r'''
int f(num n) {
  return (n is! int || n < 0) ? 0 : n & 0x0F;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_forEach() {
    Source source = addSource(r'''
int f(List<int> list) {
  num sum = 0;
  for (num n in list) {
    sum += n & 0x0F;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_if_and_is() {
    Source source = addSource(r'''
int f(num n) {
  if (n is int && n > 0) {
    return n & 0x0F;
  }
  return 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_if_is() {
    Source source = addSource(r'''
int f(num n) {
  if (n is int) {
    return n & 0x0F;
  }
  return 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_if_isNot() {
    Source source = addSource(r'''
int f(num n) {
  if (n is! int) {
    return 0;
  } else {
    return n & 0x0F;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_if_isNot_abrupt() {
    Source source = addSource(r'''
int f(num n) {
  if (n is! int) {
    return 0;
  }
  return n & 0x0F;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_if_or_is() {
    Source source = addSource(r'''
int f(num n) {
  if (n is! int || n < 0) {
    return 0;
  } else {
    return n & 0x0F;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_localVar() {
    Source source = addSource(r'''
int f() {
  num n = 1234;
  return n & 0x0F;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
}

@reflectiveTest
class SubtypeManagerTest {
  /**
   * The inheritance manager being tested.
   */
  SubtypeManager _subtypeManager;

  /**
   * The compilation unit element containing all of the types setup in each test.
   */
  CompilationUnitElementImpl _definingCompilationUnit;

  void setUp() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    FileBasedSource source =
        new FileBasedSource(FileUtilities2.createFile("/test.dart"));
    _definingCompilationUnit = new CompilationUnitElementImpl("test.dart");
    _definingCompilationUnit.librarySource =
        _definingCompilationUnit.source = source;
    LibraryElementImpl definingLibrary =
        ElementFactory.library(context, "test");
    definingLibrary.definingCompilationUnit = _definingCompilationUnit;
    _subtypeManager = new SubtypeManager();
  }

  void test_computeAllSubtypes_infiniteLoop() {
    //
    // class A extends B
    // class B extends A
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    classA.supertype = classB.type;
    _definingCompilationUnit.types = <ClassElement>[classA, classB];
    HashSet<ClassElement> subtypesOfA =
        _subtypeManager.computeAllSubtypes(classA);
    List<ClassElement> arraySubtypesOfA = new List.from(subtypesOfA);
    expect(subtypesOfA, hasLength(2));
    expect(arraySubtypesOfA, unorderedEquals([classA, classB]));
  }

  void test_computeAllSubtypes_manyRecursiveSubtypes() {
    //
    // class A
    // class B extends A
    // class C extends B
    // class D extends B
    // class E extends B
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classB.type);
    ClassElementImpl classD = ElementFactory.classElement("D", classB.type);
    ClassElementImpl classE = ElementFactory.classElement("E", classB.type);
    _definingCompilationUnit.types = <ClassElement>[
      classA,
      classB,
      classC,
      classD,
      classE
    ];
    HashSet<ClassElement> subtypesOfA =
        _subtypeManager.computeAllSubtypes(classA);
    List<ClassElement> arraySubtypesOfA = new List.from(subtypesOfA);
    HashSet<ClassElement> subtypesOfB =
        _subtypeManager.computeAllSubtypes(classB);
    List<ClassElement> arraySubtypesOfB = new List.from(subtypesOfB);
    expect(subtypesOfA, hasLength(4));
    expect(arraySubtypesOfA, unorderedEquals([classB, classC, classD, classE]));
    expect(subtypesOfB, hasLength(3));
    expect(arraySubtypesOfB, unorderedEquals([classC, classD, classE]));
  }

  void test_computeAllSubtypes_noSubtypes() {
    //
    // class A
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    _definingCompilationUnit.types = <ClassElement>[classA];
    HashSet<ClassElement> subtypesOfA =
        _subtypeManager.computeAllSubtypes(classA);
    expect(subtypesOfA, hasLength(0));
  }

  void test_computeAllSubtypes_oneSubtype() {
    //
    // class A
    // class B extends A
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    _definingCompilationUnit.types = <ClassElement>[classA, classB];
    HashSet<ClassElement> subtypesOfA =
        _subtypeManager.computeAllSubtypes(classA);
    List<ClassElement> arraySubtypesOfA = new List.from(subtypesOfA);
    expect(subtypesOfA, hasLength(1));
    expect(arraySubtypesOfA, unorderedEquals([classB]));
  }
}

@reflectiveTest
class TypeOverrideManagerTest extends EngineTestCase {
  void test_exitScope_noScopes() {
    TypeOverrideManager manager = new TypeOverrideManager();
    try {
      manager.exitScope();
      fail("Expected IllegalStateException");
    } on IllegalStateException {
      // Expected
    }
  }

  void test_exitScope_oneScope() {
    TypeOverrideManager manager = new TypeOverrideManager();
    manager.enterScope();
    manager.exitScope();
    try {
      manager.exitScope();
      fail("Expected IllegalStateException");
    } on IllegalStateException {
      // Expected
    }
  }

  void test_exitScope_twoScopes() {
    TypeOverrideManager manager = new TypeOverrideManager();
    manager.enterScope();
    manager.exitScope();
    manager.enterScope();
    manager.exitScope();
    try {
      manager.exitScope();
      fail("Expected IllegalStateException");
    } on IllegalStateException {
      // Expected
    }
  }

  void test_getType_enclosedOverride() {
    TypeOverrideManager manager = new TypeOverrideManager();
    LocalVariableElementImpl element =
        ElementFactory.localVariableElement2("v");
    InterfaceType type = ElementFactory.classElement2("C").type;
    manager.enterScope();
    manager.setType(element, type);
    manager.enterScope();
    expect(manager.getType(element), same(type));
  }

  void test_getType_immediateOverride() {
    TypeOverrideManager manager = new TypeOverrideManager();
    LocalVariableElementImpl element =
        ElementFactory.localVariableElement2("v");
    InterfaceType type = ElementFactory.classElement2("C").type;
    manager.enterScope();
    manager.setType(element, type);
    expect(manager.getType(element), same(type));
  }

  void test_getType_noOverride() {
    TypeOverrideManager manager = new TypeOverrideManager();
    manager.enterScope();
    expect(manager.getType(ElementFactory.localVariableElement2("v")), isNull);
  }

  void test_getType_noScope() {
    TypeOverrideManager manager = new TypeOverrideManager();
    expect(manager.getType(ElementFactory.localVariableElement2("v")), isNull);
  }
}

@reflectiveTest
class TypePropagationTest extends ResolverTestCase {
  void fail_mergePropagatedTypesAtJoinPoint_1() {
    // https://code.google.com/p/dart/issues/detail?id=19929
    assertTypeOfMarkedExpression(
        r'''
f1(x) {
  var y = [];
  if (x) {
    y = 0;
  } else {
    y = '';
  }
  // Propagated type is [List] here: incorrect.
  // Best we can do is [Object]?
  return y; // marker
}''',
        null,
        typeProvider.dynamicType);
  }

  void fail_mergePropagatedTypesAtJoinPoint_2() {
    // https://code.google.com/p/dart/issues/detail?id=19929
    assertTypeOfMarkedExpression(
        r'''
f2(x) {
  var y = [];
  if (x) {
    y = 0;
  } else {
  }
  // Propagated type is [List] here: incorrect.
  // Best we can do is [Object]?
  return y; // marker
}''',
        null,
        typeProvider.dynamicType);
  }

  void fail_mergePropagatedTypesAtJoinPoint_3() {
    // https://code.google.com/p/dart/issues/detail?id=19929
    assertTypeOfMarkedExpression(
        r'''
f4(x) {
  var y = [];
  if (x) {
    y = 0;
  } else {
    y = 1.5;
  }
  // Propagated type is [List] here: incorrect.
  // A correct answer is the least upper bound of [int] and [double],
  // i.e. [num].
  return y; // marker
}''',
        null,
        typeProvider.numType);
  }

  void fail_mergePropagatedTypesAtJoinPoint_5() {
    // https://code.google.com/p/dart/issues/detail?id=19929
    assertTypeOfMarkedExpression(
        r'''
f6(x,y) {
  var z = [];
  if (x || (z = y) < 0) {
  } else {
    z = 0;
  }
  // Propagated type is [List] here: incorrect.
  // Best we can do is [Object]?
  return z; // marker
}''',
        null,
        typeProvider.dynamicType);
  }

  void fail_mergePropagatedTypesAtJoinPoint_7() {
    // https://code.google.com/p/dart/issues/detail?id=19929
    //
    // In general [continue]s are unsafe for the purposes of
    // [isAbruptTerminationStatement].
    //
    // This is like example 6, but less tricky: the code in the branch that
    // [continue]s is in effect after the [if].
    String code = r'''
f() {
  var x = 0;
  var c = false;
  var d = true;
  while (d) {
    if (c) {
      d = false;
    } else {
      x = '';
      c = true;
      continue;
    }
    x; // marker
  }
}''';
    DartType t = findMarkedIdentifier(code, "; // marker").propagatedType;
    expect(typeProvider.intType.isSubtypeOf(t), isTrue);
    expect(typeProvider.stringType.isSubtypeOf(t), isTrue);
  }

  void fail_mergePropagatedTypesAtJoinPoint_8() {
    // https://code.google.com/p/dart/issues/detail?id=19929
    //
    // In nested loops [breaks]s are unsafe for the purposes of
    // [isAbruptTerminationStatement].
    //
    // This is a combination of 6 and 7: we use an unlabeled [break]
    // like a continue for the outer loop / like a labeled [break] to
    // jump just above the [if].
    String code = r'''
f() {
  var x = 0;
  var c = false;
  var d = true;
  while (d) {
    while (d) {
      if (c) {
        d = false;
      } else {
        x = '';
        c = true;
        break;
      }
      x; // marker
    }
  }
}''';
    DartType t = findMarkedIdentifier(code, "; // marker").propagatedType;
    expect(typeProvider.intType.isSubtypeOf(t), isTrue);
    expect(typeProvider.stringType.isSubtypeOf(t), isTrue);
  }

  void fail_propagatedReturnType_functionExpression() {
    // TODO(scheglov) disabled because we don't resolve function expression
    String code = r'''
main() {
  var v = (() {return 42;})();
}''';
    assertPropagatedAssignedType(
        code, typeProvider.dynamicType, typeProvider.intType);
  }

  void test_as() {
    Source source = addSource(r'''
class A {
  bool get g => true;
}
A f(var p) {
  if ((p as A).g) {
    return p;
  } else {
    return null;
  }
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement =
        (ifStatement.thenStatement as Block).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_assert() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  assert (p is A);
  return p;
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_assignment() {
    Source source = addSource(r'''
f() {
  var v;
  v = 0;
  return v;
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[2] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeProvider.intType));
  }

  void test_assignment_afterInitializer() {
    Source source = addSource(r'''
f() {
  var v = 0;
  v = 1.0;
  return v;
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[2] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeProvider.doubleType));
  }

  void test_assignment_null() {
    String code = r'''
main() {
  int v; // declare
  v = null;
  return v; // return
}''';
    CompilationUnit unit;
    {
      Source source = addSource(code);
      LibraryElement library = resolve2(source);
      assertNoErrors(source);
      verify([source]);
      unit = resolveCompilationUnit(source, library);
    }
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit, code, "v; // declare", (node) => node is SimpleIdentifier);
      expect(identifier.staticType, same(typeProvider.intType));
      expect(identifier.propagatedType, same(null));
    }
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit, code, "v = null;", (node) => node is SimpleIdentifier);
      expect(identifier.staticType, same(typeProvider.intType));
      expect(identifier.propagatedType, same(null));
    }
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit, code, "v; // return", (node) => node is SimpleIdentifier);
      expect(identifier.staticType, same(typeProvider.intType));
      expect(identifier.propagatedType, same(null));
    }
  }

  void test_CanvasElement_getContext() {
    String code = r'''
import 'dart:html';
main(CanvasElement canvas) {
  var context = canvas.getContext('2d');
}''';
    Source source = addSource(code);
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    SimpleIdentifier identifier = EngineTestCase.findNode(
        unit, code, "context", (node) => node is SimpleIdentifier);
    expect(identifier.propagatedType.name, "CanvasRenderingContext2D");
  }

  void test_finalPropertyInducingVariable_classMember_instance() {
    addNamedSource(
        "/lib.dart",
        r'''
class A {
  final v = 0;
}''');
    String code = r'''
import 'lib.dart';
f(A a) {
  return a.v; // marker
}''';
    assertTypeOfMarkedExpression(
        code, typeProvider.dynamicType, typeProvider.intType);
  }

  void test_finalPropertyInducingVariable_classMember_instance_inherited() {
    addNamedSource(
        "/lib.dart",
        r'''
class A {
  final v = 0;
}''');
    String code = r'''
import 'lib.dart';
class B extends A {
  m() {
    return v; // marker
  }
}''';
    assertTypeOfMarkedExpression(
        code, typeProvider.dynamicType, typeProvider.intType);
  }

  void
      test_finalPropertyInducingVariable_classMember_instance_propagatedTarget() {
    addNamedSource(
        "/lib.dart",
        r'''
class A {
  final v = 0;
}''');
    String code = r'''
import 'lib.dart';
f(p) {
  if (p is A) {
    return p.v; // marker
  }
}''';
    assertTypeOfMarkedExpression(
        code, typeProvider.dynamicType, typeProvider.intType);
  }

  void test_finalPropertyInducingVariable_classMember_instance_unprefixed() {
    String code = r'''
class A {
  final v = 0;
  m() {
    v; // marker
  }
}''';
    assertTypeOfMarkedExpression(
        code, typeProvider.dynamicType, typeProvider.intType);
  }

  void test_finalPropertyInducingVariable_classMember_static() {
    addNamedSource(
        "/lib.dart",
        r'''
class A {
  static final V = 0;
}''');
    String code = r'''
import 'lib.dart';
f() {
  return A.V; // marker
}''';
    assertTypeOfMarkedExpression(
        code, typeProvider.dynamicType, typeProvider.intType);
  }

  void test_finalPropertyInducingVariable_topLevelVariable_prefixed() {
    addNamedSource("/lib.dart", "final V = 0;");
    String code = r'''
import 'lib.dart' as p;
f() {
  var v2 = p.V; // marker prefixed
}''';
    assertTypeOfMarkedExpression(
        code, typeProvider.dynamicType, typeProvider.intType);
  }

  void test_finalPropertyInducingVariable_topLevelVariable_simple() {
    addNamedSource("/lib.dart", "final V = 0;");
    String code = r'''
import 'lib.dart';
f() {
  return V; // marker simple
}''';
    assertTypeOfMarkedExpression(
        code, typeProvider.dynamicType, typeProvider.intType);
  }

  void test_forEach() {
    String code = r'''
main() {
  var list = <String> [];
  for (var e in list) {
    e;
  }
}''';
    Source source = addSource(code);
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    InterfaceType stringType = typeProvider.stringType;
    // in the declaration
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit, code, "e in", (node) => node is SimpleIdentifier);
      expect(identifier.propagatedType, same(stringType));
    }
    // in the loop body
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit, code, "e;", (node) => node is SimpleIdentifier);
      expect(identifier.propagatedType, same(stringType));
    }
  }

  void test_forEach_async() {
    String code = r'''
import 'dart:async';
f(Stream<String> stream) async {
  await for (var e in stream) {
    e;
  }
}''';
    Source source = addSource(code);
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    InterfaceType stringType = typeProvider.stringType;
    // in the declaration
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit, code, "e in", (node) => node is SimpleIdentifier);
      expect(identifier.propagatedType, same(stringType));
    }
    // in the loop body
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit, code, "e;", (node) => node is SimpleIdentifier);
      expect(identifier.propagatedType, same(stringType));
    }
  }

  void test_forEach_async_inheritedStream() {
    // From https://github.com/dart-lang/sdk/issues/24191, this ensures that
    // `await for` works for types where the generic parameter doesn't
    // correspond to the type of the Stream's data.
    String code = r'''
import 'dart:async';
abstract class MyCustomStream<T> implements Stream<List<T>> {}
f(MyCustomStream<String> stream) async {
  await for (var e in stream) {
    e;
  }
}''';
    Source source = addSource(code);
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    InterfaceType listOfStringType =
        typeProvider.listType.instantiate([typeProvider.stringType]);
    // in the declaration
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit, code, "e in", (node) => node is SimpleIdentifier);
      expect(identifier.propagatedType, equals(listOfStringType));
    }
    // in the loop body
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit, code, "e;", (node) => node is SimpleIdentifier);
      expect(identifier.propagatedType, equals(listOfStringType));
    }
  }

  void test_functionExpression_asInvocationArgument() {
    String code = r'''
class MyMap<K, V> {
  forEach(f(K key, V value)) {}
}
f(MyMap<int, String> m) {
  m.forEach((k, v) {
    k;
    v;
  });
}''';
    Source source = addSource(code);
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    // k
    DartType intType = typeProvider.intType;
    FormalParameter kParameter = EngineTestCase.findNode(
        unit, code, "k, ", (node) => node is SimpleFormalParameter);
    expect(kParameter.identifier.propagatedType, same(intType));
    SimpleIdentifier kIdentifier = EngineTestCase.findNode(
        unit, code, "k;", (node) => node is SimpleIdentifier);
    expect(kIdentifier.propagatedType, same(intType));
    expect(kIdentifier.staticType, same(typeProvider.dynamicType));
    // v
    DartType stringType = typeProvider.stringType;
    FormalParameter vParameter = EngineTestCase.findNode(
        unit, code, "v)", (node) => node is SimpleFormalParameter);
    expect(vParameter.identifier.propagatedType, same(stringType));
    SimpleIdentifier vIdentifier = EngineTestCase.findNode(
        unit, code, "v;", (node) => node is SimpleIdentifier);
    expect(vIdentifier.propagatedType, same(stringType));
    expect(vIdentifier.staticType, same(typeProvider.dynamicType));
  }

  void test_functionExpression_asInvocationArgument_fromInferredInvocation() {
    String code = r'''
class MyMap<K, V> {
  forEach(f(K key, V value)) {}
}
f(MyMap<int, String> m) {
  var m2 = m;
  m2.forEach((k, v) {});
}''';
    Source source = addSource(code);
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    // k
    DartType intType = typeProvider.intType;
    FormalParameter kParameter = EngineTestCase.findNode(
        unit, code, "k, ", (node) => node is SimpleFormalParameter);
    expect(kParameter.identifier.propagatedType, same(intType));
    // v
    DartType stringType = typeProvider.stringType;
    FormalParameter vParameter = EngineTestCase.findNode(
        unit, code, "v)", (node) => node is SimpleFormalParameter);
    expect(vParameter.identifier.propagatedType, same(stringType));
  }

  void
      test_functionExpression_asInvocationArgument_functionExpressionInvocation() {
    String code = r'''
main() {
  (f(String value)) {} ((v) {
    v;
  });
}''';
    Source source = addSource(code);
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    // v
    DartType dynamicType = typeProvider.dynamicType;
    DartType stringType = typeProvider.stringType;
    FormalParameter vParameter = EngineTestCase.findNode(
        unit, code, "v)", (node) => node is FormalParameter);
    expect(vParameter.identifier.propagatedType, same(stringType));
    expect(vParameter.identifier.staticType, same(dynamicType));
    SimpleIdentifier vIdentifier = EngineTestCase.findNode(
        unit, code, "v;", (node) => node is SimpleIdentifier);
    expect(vIdentifier.propagatedType, same(stringType));
    expect(vIdentifier.staticType, same(dynamicType));
  }

  void test_functionExpression_asInvocationArgument_keepIfLessSpecific() {
    String code = r'''
class MyList {
  forEach(f(Object value)) {}
}
f(MyList list) {
  list.forEach((int v) {
    v;
  });
}''';
    Source source = addSource(code);
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    // v
    DartType intType = typeProvider.intType;
    FormalParameter vParameter = EngineTestCase.findNode(
        unit, code, "v)", (node) => node is SimpleFormalParameter);
    expect(vParameter.identifier.propagatedType, same(null));
    expect(vParameter.identifier.staticType, same(intType));
    SimpleIdentifier vIdentifier = EngineTestCase.findNode(
        unit, code, "v;", (node) => node is SimpleIdentifier);
    expect(vIdentifier.staticType, same(intType));
    expect(vIdentifier.propagatedType, same(null));
  }

  void test_functionExpression_asInvocationArgument_notSubtypeOfStaticType() {
    String code = r'''
class A {
  m(void f(int i)) {}
}
x() {
  A a = new A();
  a.m(() => 0);
}''';
    Source source = addSource(code);
    LibraryElement library = resolve2(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    // () => 0
    FunctionExpression functionExpression = EngineTestCase.findNode(
        unit, code, "() => 0)", (node) => node is FunctionExpression);
    expect((functionExpression.staticType as FunctionType).parameters.length,
        same(0));
    expect(functionExpression.propagatedType, same(null));
  }

  void test_functionExpression_asInvocationArgument_replaceIfMoreSpecific() {
    String code = r'''
class MyList<E> {
  forEach(f(E value)) {}
}
f(MyList<String> list) {
  list.forEach((Object v) {
    v;
  });
}''';
    Source source = addSource(code);
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    // v
    DartType stringType = typeProvider.stringType;
    FormalParameter vParameter = EngineTestCase.findNode(
        unit, code, "v)", (node) => node is SimpleFormalParameter);
    expect(vParameter.identifier.propagatedType, same(stringType));
    expect(vParameter.identifier.staticType, same(typeProvider.objectType));
    SimpleIdentifier vIdentifier = EngineTestCase.findNode(
        unit, code, "v;", (node) => node is SimpleIdentifier);
    expect(vIdentifier.propagatedType, same(stringType));
  }

  void test_Future_then() {
    String code = r'''
import 'dart:async';
main(Future<int> firstFuture) {
  firstFuture.then((p1) {
    return 1.0;
  }).then((p2) {
    return new Future<String>.value('str');
  }).then((p3) {
  });
}''';
    Source source = addSource(code);
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    // p1
    FormalParameter p1 = EngineTestCase.findNode(
        unit, code, "p1) {", (node) => node is SimpleFormalParameter);
    expect(p1.identifier.propagatedType, same(typeProvider.intType));
    // p2
    FormalParameter p2 = EngineTestCase.findNode(
        unit, code, "p2) {", (node) => node is SimpleFormalParameter);
    expect(p2.identifier.propagatedType, same(typeProvider.doubleType));
    // p3
    FormalParameter p3 = EngineTestCase.findNode(
        unit, code, "p3) {", (node) => node is SimpleFormalParameter);
    expect(p3.identifier.propagatedType, same(typeProvider.stringType));
  }

  void test_initializer() {
    Source source = addSource(r'''
f() {
  var v = 0;
  return v;
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    NodeList<Statement> statements = body.block.statements;
    // Type of 'v' in declaration.
    {
      VariableDeclarationStatement statement =
          statements[0] as VariableDeclarationStatement;
      SimpleIdentifier variableName = statement.variables.variables[0].name;
      expect(variableName.staticType, same(typeProvider.dynamicType));
      expect(variableName.propagatedType, same(typeProvider.intType));
    }
    // Type of 'v' in reference.
    {
      ReturnStatement statement = statements[1] as ReturnStatement;
      SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
      expect(variableName.propagatedType, same(typeProvider.intType));
    }
  }

  void test_initializer_dereference() {
    Source source = addSource(r'''
f() {
  var v = 'String';
  v.
}''');
    LibraryElement library = resolve2(source);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ExpressionStatement statement =
        body.block.statements[1] as ExpressionStatement;
    PrefixedIdentifier invocation = statement.expression as PrefixedIdentifier;
    SimpleIdentifier variableName = invocation.prefix;
    expect(variableName.propagatedType, same(typeProvider.stringType));
  }

  void test_initializer_hasStaticType() {
    Source source = addSource(r'''
f() {
  int v = 0;
  return v;
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    NodeList<Statement> statements = body.block.statements;
    // Type of 'v' in declaration.
    {
      VariableDeclarationStatement statement =
          statements[0] as VariableDeclarationStatement;
      SimpleIdentifier variableName = statement.variables.variables[0].name;
      expect(variableName.staticType, same(typeProvider.intType));
      expect(variableName.propagatedType, isNull);
    }
    // Type of 'v' in reference.
    {
      ReturnStatement statement = statements[1] as ReturnStatement;
      SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
      expect(variableName.staticType, same(typeProvider.intType));
      expect(variableName.propagatedType, isNull);
    }
  }

  void test_initializer_hasStaticType_parameterized() {
    Source source = addSource(r'''
f() {
  List<int> v = <int>[];
  return v;
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    NodeList<Statement> statements = body.block.statements;
    // Type of 'v' in declaration.
    {
      VariableDeclarationStatement statement =
          statements[0] as VariableDeclarationStatement;
      SimpleIdentifier variableName = statement.variables.variables[0].name;
      expect(variableName.staticType, isNotNull);
      expect(variableName.propagatedType, isNull);
    }
    // Type of 'v' in reference.
    {
      ReturnStatement statement = statements[1] as ReturnStatement;
      SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
      expect(variableName.staticType, isNotNull);
      expect(variableName.propagatedType, isNull);
    }
  }

  void test_initializer_null() {
    String code = r'''
main() {
  int v = null;
  return v; // marker
}''';
    CompilationUnit unit;
    {
      Source source = addSource(code);
      LibraryElement library = resolve2(source);
      assertNoErrors(source);
      verify([source]);
      unit = resolveCompilationUnit(source, library);
    }
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit, code, "v = null;", (node) => node is SimpleIdentifier);
      expect(identifier.staticType, same(typeProvider.intType));
      expect(identifier.propagatedType, same(null));
    }
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit, code, "v; // marker", (node) => node is SimpleIdentifier);
      expect(identifier.staticType, same(typeProvider.intType));
      expect(identifier.propagatedType, same(null));
    }
  }

  void test_invocation_target_prefixed() {
    addNamedSource(
        '/helper.dart',
        '''
library helper;
int max(int x, int y) => 0;
''');
    String code = '''
import 'helper.dart' as helper;
main() {
  helper.max(10, 10); // marker
}''';
    SimpleIdentifier methodName =
        findMarkedIdentifier(code, "(10, 10); // marker");
    MethodInvocation methodInvoke = methodName.parent;
    expect(methodInvoke.methodName.staticElement, isNotNull);
    expect(methodInvoke.methodName.propagatedElement, isNull);
  }

  void test_is_conditional() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  return (p is A) ? p : null;
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[0] as ReturnStatement;
    ConditionalExpression conditional =
        statement.expression as ConditionalExpression;
    SimpleIdentifier variableName =
        conditional.thenExpression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_is_if() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  if (p is A) {
    return p;
  } else {
    return null;
  }
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    // prepare A
    InterfaceType typeA;
    {
      ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
      typeA = classA.element.type;
    }
    // verify "f"
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    // "p is A"
    {
      IsExpression isExpression = ifStatement.condition;
      SimpleIdentifier variableName = isExpression.expression;
      expect(variableName.propagatedType, isNull);
    }
    // "return p;"
    {
      ReturnStatement statement =
          (ifStatement.thenStatement as Block).statements[0] as ReturnStatement;
      SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
      expect(variableName.propagatedType, same(typeA));
    }
  }

  void test_is_if_lessSpecific() {
    Source source = addSource(r'''
class A {}
A f(A p) {
  if (p is String) {
    return p;
  } else {
    return null;
  }
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
//    ClassDeclaration classA = (ClassDeclaration) unit.getDeclarations().get(0);
//    InterfaceType typeA = classA.getElement().getType();
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement =
        (ifStatement.thenStatement as Block).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(null));
  }

  void test_is_if_logicalAnd() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  if (p is A && p != null) {
    return p;
  } else {
    return null;
  }
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement =
        (ifStatement.thenStatement as Block).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_is_postConditional() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  A a = (p is A) ? p : throw null;
  return p;
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_is_postIf() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  if (p is A) {
    A a = p;
  } else {
    return null;
  }
  return p;
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_is_subclass() {
    Source source = addSource(r'''
class A {}
class B extends A {
  B m() => this;
}
A f(A p) {
  if (p is B) {
    return p.m();
  }
  return p;
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[2] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement =
        (ifStatement.thenStatement as Block).statements[0] as ReturnStatement;
    MethodInvocation invocation = statement.expression as MethodInvocation;
    expect(invocation.methodName.staticElement, isNotNull);
    expect(invocation.methodName.propagatedElement, isNull);
  }

  void test_is_while() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  while (p is A) {
    return p;
  }
  return p;
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    WhileStatement whileStatement = body.block.statements[0] as WhileStatement;
    ReturnStatement statement =
        (whileStatement.body as Block).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_isNot_conditional() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  return (p is! A) ? null : p;
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[0] as ReturnStatement;
    ConditionalExpression conditional =
        statement.expression as ConditionalExpression;
    SimpleIdentifier variableName =
        conditional.elseExpression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_isNot_if() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  if (p is! A) {
    return null;
  } else {
    return p;
  }
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement =
        (ifStatement.elseStatement as Block).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_isNot_if_logicalOr() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  if (p is! A || null == p) {
    return null;
  } else {
    return p;
  }
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement =
        (ifStatement.elseStatement as Block).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_isNot_postConditional() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  A a = (p is! A) ? throw null : p;
  return p;
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_isNot_postIf() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  if (p is! A) {
    return null;
  }
  return p;
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_issue20904BuggyTypePromotionAtIfJoin_5() {
    // https://code.google.com/p/dart/issues/detail?id=20904
    //
    // This is not an example of the 20904 bug, but rather,
    // an example of something that one obvious fix changes inadvertently: we
    // want to avoid using type information from is-checks when it
    // loses precision. I can't see how to get a bad hint this way, since
    // it seems the propagated type is not used to generate hints when a
    // more precise type would cause no hint. For example, for code like the
    // following, when the propagated type of [x] is [A] -- as happens for the
    // fix these tests aim to warn against -- there is no warning for

    // calling a method defined on [B] but not [A] (there aren't any, but
    // pretend), but there is for calling a method not defined on either.
    // By not overriding the propagated type via an is-check that loses
    // precision, we get more precise completion under an is-check. However,
    // I can only imagine strange code would make use of this feature.
    //
    // Here the is-check improves precision, so we use it.
    String code = r'''
class A {}
class B extends A {}
f() {
  var a = new A();
  var b = new B();
  b; // B
  if (a is B) {
    return a; // marker
  }
}''';
    DartType tB = findMarkedIdentifier(code, "; // B").propagatedType;
    assertTypeOfMarkedExpression(code, null, tB);
  }

  void test_issue20904BuggyTypePromotionAtIfJoin_6() {
    // https://code.google.com/p/dart/issues/detail?id=20904
    //
    // The other half of the *_5() test.
    //
    // Here the is-check loses precision, so we don't use it.
    String code = r'''
class A {}
class B extends A {}
f() {
  var b = new B();
  b; // B
  if (b is A) {
    return b; // marker
  }
}''';
    DartType tB = findMarkedIdentifier(code, "; // B").propagatedType;
    assertTypeOfMarkedExpression(code, null, tB);
  }

  void test_listLiteral_different() {
    Source source = addSource(r'''
f() {
  var v = [0, '1', 2];
  return v[2];
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    IndexExpression indexExpression = statement.expression as IndexExpression;
    expect(indexExpression.propagatedType, isNull);
  }

  void test_listLiteral_same() {
    Source source = addSource(r'''
f() {
  var v = [0, 1, 2];
  return v[2];
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    IndexExpression indexExpression = statement.expression as IndexExpression;
    expect(indexExpression.propagatedType, isNull);
    Expression v = indexExpression.target;
    InterfaceType propagatedType = v.propagatedType as InterfaceType;
    expect(propagatedType.element, same(typeProvider.listType.element));
    List<DartType> typeArguments = propagatedType.typeArguments;
    expect(typeArguments, hasLength(1));
    expect(typeArguments[0], same(typeProvider.dynamicType));
  }

  void test_mapLiteral_different() {
    Source source = addSource(r'''
f() {
  var v = {'0' : 0, 1 : '1', '2' : 2};
  return v;
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier identifier = statement.expression as SimpleIdentifier;
    InterfaceType propagatedType = identifier.propagatedType as InterfaceType;
    expect(propagatedType.element, same(typeProvider.mapType.element));
    List<DartType> typeArguments = propagatedType.typeArguments;
    expect(typeArguments, hasLength(2));
    expect(typeArguments[0], same(typeProvider.dynamicType));
    expect(typeArguments[1], same(typeProvider.dynamicType));
  }

  void test_mapLiteral_same() {
    Source source = addSource(r'''
f() {
  var v = {'a' : 0, 'b' : 1, 'c' : 2};
  return v;
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier identifier = statement.expression as SimpleIdentifier;
    InterfaceType propagatedType = identifier.propagatedType as InterfaceType;
    expect(propagatedType.element, same(typeProvider.mapType.element));
    List<DartType> typeArguments = propagatedType.typeArguments;
    expect(typeArguments, hasLength(2));
    expect(typeArguments[0], same(typeProvider.dynamicType));
    expect(typeArguments[1], same(typeProvider.dynamicType));
  }

  void test_mergePropagatedTypes_afterIfThen_different() {
    String code = r'''
main() {
  var v = 0;
  if (v != null) {
    v = '';
  }
  return v;
}''';
    {
      SimpleIdentifier identifier = findMarkedIdentifier(code, "v;");
      expect(identifier.propagatedType, null);
    }
    {
      SimpleIdentifier identifier = findMarkedIdentifier(code, "v = '';");
      expect(identifier.propagatedType, typeProvider.stringType);
    }
  }

  void test_mergePropagatedTypes_afterIfThen_same() {
    assertTypeOfMarkedExpression(
        r'''
main() {
  var v = 1;
  if (v != null) {
    v = 2;
  }
  return v; // marker
}''',
        null,
        typeProvider.intType);
  }

  void test_mergePropagatedTypes_afterIfThenElse_different() {
    assertTypeOfMarkedExpression(
        r'''
main() {
  var v = 1;
  if (v != null) {
    v = 2;
  } else {
    v = '3';
  }
  return v; // marker
}''',
        null,
        null);
  }

  void test_mergePropagatedTypes_afterIfThenElse_same() {
    assertTypeOfMarkedExpression(
        r'''
main() {
  var v = 1;
  if (v != null) {
    v = 2;
  } else {
    v = 3;
  }
  return v; // marker
}''',
        null,
        typeProvider.intType);
  }

  void test_mergePropagatedTypesAtJoinPoint_4() {
    // https://code.google.com/p/dart/issues/detail?id=19929
    assertTypeOfMarkedExpression(
        r'''
f5(x) {
  var y = [];
  if (x) {
    y = 0;
  } else {
    return y;
  }
  // Propagated type is [int] here: correct.
  return y; // marker
}''',
        null,
        typeProvider.intType);
  }

  void test_mutatedOutsideScope() {
    // https://code.google.com/p/dart/issues/detail?id=22732
    Source source = addSource(r'''
class Base {
}

class Derived extends Base {
  get y => null;
}

class C {
  void f() {
    Base x = null;
    if (x is Derived) {
      print(x.y); // BAD
    }
    x = null;
  }
}

void g() {
  Base x = null;
  if (x is Derived) {
    print(x.y); // GOOD
  }
  x = null;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_objectAccessInference_disabled_for_library_prefix() {
    String name = 'hashCode';
    addNamedSource(
        '/helper.dart',
        '''
library helper;
dynamic get $name => 42;
''');
    String code = '''
import 'helper.dart' as helper;
main() {
  helper.$name; // marker
}''';

    SimpleIdentifier id = findMarkedIdentifier(code, "; // marker");
    PrefixedIdentifier prefixedId = id.parent;
    expect(id.staticType, typeProvider.dynamicType);
    expect(prefixedId.staticType, typeProvider.dynamicType);
  }

  void test_objectAccessInference_disabled_for_local_getter() {
    String name = 'hashCode';
    String code = '''
dynamic get $name => null;
main() {
  $name; // marker
}''';

    SimpleIdentifier getter = findMarkedIdentifier(code, "; // marker");
    expect(getter.staticType, typeProvider.dynamicType);
  }

  void test_objectAccessInference_enabled_for_cascades() {
    String name = 'hashCode';
    String code = '''
main() {
  dynamic obj;
  obj..$name..$name; // marker
}''';
    PropertyAccess access = findMarkedIdentifier(code, "; // marker").parent;
    expect(access.staticType, typeProvider.dynamicType);
    expect(access.realTarget.staticType, typeProvider.dynamicType);
  }

  void test_objectMethodInference_disabled_for_library_prefix() {
    String name = 'toString';
    addNamedSource(
        '/helper.dart',
        '''
library helper;
dynamic $name = (int x) => x + 42');
''');
    String code = '''
import 'helper.dart' as helper;
main() {
  helper.$name(); // marker
}''';
    SimpleIdentifier methodName = findMarkedIdentifier(code, "(); // marker");
    MethodInvocation methodInvoke = methodName.parent;
    expect(methodName.staticType, typeProvider.dynamicType);
    expect(methodInvoke.staticType, typeProvider.dynamicType);
  }

  void test_objectMethodInference_disabled_for_local_function() {
    String name = 'toString';
    String code = '''
main() {
  dynamic $name = () => null;
  $name(); // marker
}''';
    SimpleIdentifier identifier = findMarkedIdentifier(code, "$name = ");
    expect(identifier.staticType, typeProvider.dynamicType);

    SimpleIdentifier methodName = findMarkedIdentifier(code, "(); // marker");
    MethodInvocation methodInvoke = methodName.parent;
    expect(methodName.staticType, typeProvider.dynamicType);
    expect(methodInvoke.staticType, typeProvider.dynamicType);
  }

  void test_objectMethodInference_enabled_for_cascades() {
    String name = 'toString';
    String code = '''
main() {
  dynamic obj;
  obj..$name()..$name(); // marker
}''';
    SimpleIdentifier methodName = findMarkedIdentifier(code, "(); // marker");
    MethodInvocation methodInvoke = methodName.parent;

    expect(methodInvoke.staticType, typeProvider.dynamicType);
    expect(methodInvoke.realTarget.staticType, typeProvider.dynamicType);
  }

  void test_objectMethodOnDynamicExpression_doubleEquals() {
    // https://code.google.com/p/dart/issues/detail?id=20342
    //
    // This was not actually part of Issue 20342, since the spec specifies a
    // static type of [bool] for [==] comparison and the implementation
    // was already consistent with the spec there. But, it's another
    // [Object] method, so it's included here.
    assertTypeOfMarkedExpression(
        r'''
f1(x) {
  var v = (x == x);
  return v; // marker
}''',
        null,
        typeProvider.boolType);
  }

  void test_objectMethodOnDynamicExpression_hashCode() {
    // https://code.google.com/p/dart/issues/detail?id=20342
    assertTypeOfMarkedExpression(
        r'''
f1(x) {
  var v = x.hashCode;
  return v; // marker
}''',
        null,
        typeProvider.intType);
  }

  void test_objectMethodOnDynamicExpression_runtimeType() {
    // https://code.google.com/p/dart/issues/detail?id=20342
    assertTypeOfMarkedExpression(
        r'''
f1(x) {
  var v = x.runtimeType;
  return v; // marker
}''',
        null,
        typeProvider.typeType);
  }

  void test_objectMethodOnDynamicExpression_toString() {
    // https://code.google.com/p/dart/issues/detail?id=20342
    assertTypeOfMarkedExpression(
        r'''
f1(x) {
  var v = x.toString();
  return v; // marker
}''',
        null,
        typeProvider.stringType);
  }

  void test_propagatedReturnType_localFunction() {
    String code = r'''
main() {
  f() => 42;
  var v = f();
}''';
    assertPropagatedAssignedType(
        code, typeProvider.dynamicType, typeProvider.intType);
  }

  void test_query() {
    Source source = addSource(r'''
import 'dart:html';

main() {
  var v1 = query('a');
  var v2 = query('A');
  var v3 = query('body:active');
  var v4 = query('button[foo="bar"]');
  var v5 = query('div.class');
  var v6 = query('input#id');
  var v7 = query('select#id');
  // invocation of method
  var m1 = document.query('div');
 // unsupported currently
  var b1 = query('noSuchTag');
  var b2 = query('DART_EDITOR_NO_SUCH_TYPE');
  var b3 = query('body div');
  return [v1, v2, v3, v4, v5, v6, v7, m1, b1, b2, b3];
}''');
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration main = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body = main.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[11] as ReturnStatement;
    NodeList<Expression> elements =
        (statement.expression as ListLiteral).elements;
    expect(elements[0].propagatedType.name, "AnchorElement");
    expect(elements[1].propagatedType.name, "AnchorElement");
    expect(elements[2].propagatedType.name, "BodyElement");
    expect(elements[3].propagatedType.name, "ButtonElement");
    expect(elements[4].propagatedType.name, "DivElement");
    expect(elements[5].propagatedType.name, "InputElement");
    expect(elements[6].propagatedType.name, "SelectElement");
    expect(elements[7].propagatedType.name, "DivElement");
    expect(elements[8].propagatedType.name, "Element");
    expect(elements[9].propagatedType.name, "Element");
    expect(elements[10].propagatedType.name, "Element");
  }
}

@reflectiveTest
class TypeProviderImplTest extends EngineTestCase {
  void test_creation() {
    //
    // Create a mock library element with the types expected to be in dart:core.
    // We cannot use either ElementFactory or TestTypeProvider (which uses
    // ElementFactory) because we side-effect the elements in ways that would
    // break other tests.
    //
    InterfaceType objectType = _classElement("Object", null).type;
    InterfaceType boolType = _classElement("bool", objectType).type;
    InterfaceType numType = _classElement("num", objectType).type;
    InterfaceType doubleType = _classElement("double", numType).type;
    InterfaceType functionType = _classElement("Function", objectType).type;
    InterfaceType futureType = _classElement("Future", objectType, ["T"]).type;
    InterfaceType intType = _classElement("int", numType).type;
    InterfaceType iterableType =
        _classElement("Iterable", objectType, ["T"]).type;
    InterfaceType listType = _classElement("List", objectType, ["E"]).type;
    InterfaceType mapType = _classElement("Map", objectType, ["K", "V"]).type;
    InterfaceType stackTraceType = _classElement("StackTrace", objectType).type;
    InterfaceType streamType = _classElement("Stream", objectType, ["T"]).type;
    InterfaceType stringType = _classElement("String", objectType).type;
    InterfaceType symbolType = _classElement("Symbol", objectType).type;
    InterfaceType typeType = _classElement("Type", objectType).type;
    CompilationUnitElementImpl coreUnit =
        new CompilationUnitElementImpl("core.dart");
    coreUnit.types = <ClassElement>[
      boolType.element,
      doubleType.element,
      functionType.element,
      intType.element,
      iterableType.element,
      listType.element,
      mapType.element,
      objectType.element,
      stackTraceType.element,
      stringType.element,
      symbolType.element,
      typeType.element
    ];
    CompilationUnitElementImpl asyncUnit =
        new CompilationUnitElementImpl("async.dart");
    asyncUnit.types = <ClassElement>[futureType.element, streamType.element];
    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    LibraryElementImpl coreLibrary = new LibraryElementImpl.forNode(
        context, AstFactory.libraryIdentifier2(["dart.core"]));
    coreLibrary.definingCompilationUnit = coreUnit;
    LibraryElementImpl asyncLibrary = new LibraryElementImpl.forNode(
        context, AstFactory.libraryIdentifier2(["dart.async"]));
    asyncLibrary.definingCompilationUnit = asyncUnit;
    //
    // Create a type provider and ensure that it can return the expected types.
    //
    TypeProviderImpl provider = new TypeProviderImpl(coreLibrary, asyncLibrary);
    expect(provider.boolType, same(boolType));
    expect(provider.bottomType, isNotNull);
    expect(provider.doubleType, same(doubleType));
    expect(provider.dynamicType, isNotNull);
    expect(provider.functionType, same(functionType));
    expect(provider.futureType, same(futureType));
    expect(provider.intType, same(intType));
    expect(provider.listType, same(listType));
    expect(provider.mapType, same(mapType));
    expect(provider.objectType, same(objectType));
    expect(provider.stackTraceType, same(stackTraceType));
    expect(provider.streamType, same(streamType));
    expect(provider.stringType, same(stringType));
    expect(provider.symbolType, same(symbolType));
    expect(provider.typeType, same(typeType));
  }

  void test_creation_no_async() {
    //
    // Create a mock library element with the types expected to be in dart:core.
    // We cannot use either ElementFactory or TestTypeProvider (which uses
    // ElementFactory) because we side-effect the elements in ways that would
    // break other tests.
    //
    InterfaceType objectType = _classElement("Object", null).type;
    InterfaceType boolType = _classElement("bool", objectType).type;
    InterfaceType numType = _classElement("num", objectType).type;
    InterfaceType doubleType = _classElement("double", numType).type;
    InterfaceType functionType = _classElement("Function", objectType).type;
    InterfaceType intType = _classElement("int", numType).type;
    InterfaceType iterableType =
        _classElement("Iterable", objectType, ["T"]).type;
    InterfaceType listType = _classElement("List", objectType, ["E"]).type;
    InterfaceType mapType = _classElement("Map", objectType, ["K", "V"]).type;
    InterfaceType stackTraceType = _classElement("StackTrace", objectType).type;
    InterfaceType stringType = _classElement("String", objectType).type;
    InterfaceType symbolType = _classElement("Symbol", objectType).type;
    InterfaceType typeType = _classElement("Type", objectType).type;
    CompilationUnitElementImpl coreUnit =
        new CompilationUnitElementImpl("core.dart");
    coreUnit.types = <ClassElement>[
      boolType.element,
      doubleType.element,
      functionType.element,
      intType.element,
      iterableType.element,
      listType.element,
      mapType.element,
      objectType.element,
      stackTraceType.element,
      stringType.element,
      symbolType.element,
      typeType.element
    ];
    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    LibraryElementImpl coreLibrary = new LibraryElementImpl.forNode(
        context, AstFactory.libraryIdentifier2(["dart.core"]));
    coreLibrary.definingCompilationUnit = coreUnit;

    Source asyncSource = new NonExistingSource(
        'async.dart', Uri.parse('dart:async'), UriKind.DART_URI);
    LibraryElementImpl mockAsyncLib = (context as AnalysisContextImpl)
        .createMockAsyncLib(coreLibrary, asyncSource);
    expect(mockAsyncLib.source, same(asyncSource));
    expect(mockAsyncLib.definingCompilationUnit.source, same(asyncSource));
    expect(mockAsyncLib.publicNamespace, isNotNull);

    //
    // Create a type provider and ensure that it can return the expected types.
    //
    TypeProviderImpl provider = new TypeProviderImpl(coreLibrary, mockAsyncLib);
    expect(provider.boolType, same(boolType));
    expect(provider.bottomType, isNotNull);
    expect(provider.doubleType, same(doubleType));
    expect(provider.dynamicType, isNotNull);
    expect(provider.functionType, same(functionType));
    InterfaceType mockFutureType = mockAsyncLib.getType('Future').type;
    expect(provider.futureType, same(mockFutureType));
    expect(provider.intType, same(intType));
    expect(provider.listType, same(listType));
    expect(provider.mapType, same(mapType));
    expect(provider.objectType, same(objectType));
    expect(provider.stackTraceType, same(stackTraceType));
    expect(provider.stringType, same(stringType));
    expect(provider.symbolType, same(symbolType));
    InterfaceType mockStreamType = mockAsyncLib.getType('Stream').type;
    expect(provider.streamType, same(mockStreamType));
    expect(provider.typeType, same(typeType));
  }

  ClassElement _classElement(String typeName, InterfaceType superclassType,
      [List<String> parameterNames]) {
    ClassElementImpl element =
        new ClassElementImpl.forNode(AstFactory.identifier3(typeName));
    element.supertype = superclassType;
    if (parameterNames != null) {
      int count = parameterNames.length;
      if (count > 0) {
        List<TypeParameterElementImpl> typeParameters =
            new List<TypeParameterElementImpl>(count);
        List<TypeParameterTypeImpl> typeArguments =
            new List<TypeParameterTypeImpl>(count);
        for (int i = 0; i < count; i++) {
          TypeParameterElementImpl typeParameter =
              new TypeParameterElementImpl.forNode(
                  AstFactory.identifier3(parameterNames[i]));
          typeParameters[i] = typeParameter;
          typeArguments[i] = new TypeParameterTypeImpl(typeParameter);
          typeParameter.type = typeArguments[i];
        }
        element.typeParameters = typeParameters;
      }
    }
    return element;
  }
}

@reflectiveTest
class TypeResolverVisitorTest {
  /**
   * The error listener to which errors will be reported.
   */
  GatheringErrorListener _listener;

  /**
   * The type provider used to access the types.
   */
  TestTypeProvider _typeProvider;

  /**
   * The library scope in which types are to be resolved.
   */
  LibraryScope libraryScope;

  /**
   * The visitor used to resolve types needed to form the type hierarchy.
   */
  TypeResolverVisitor _visitor;

  void fail_visitConstructorDeclaration() {
    fail("Not yet tested");
    _listener.assertNoErrors();
  }

  void fail_visitFunctionTypeAlias() {
    fail("Not yet tested");
    _listener.assertNoErrors();
  }

  void fail_visitVariableDeclaration() {
    fail("Not yet tested");
    ClassElement type = ElementFactory.classElement2("A");
    VariableDeclaration node = AstFactory.variableDeclaration("a");
    AstFactory.variableDeclarationList(null, AstFactory.typeName(type), [node]);
    //resolve(node);
    expect(node.name.staticType, same(type.type));
    _listener.assertNoErrors();
  }

  void setUp() {
    _listener = new GatheringErrorListener();
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore();
    Source librarySource =
        new FileBasedSource(FileUtilities2.createFile("/lib.dart"));
    LibraryElementImpl element = new LibraryElementImpl.forNode(
        context, AstFactory.libraryIdentifier2(["lib"]));
    element.definingCompilationUnit =
        new CompilationUnitElementImpl("lib.dart");
    _typeProvider = new TestTypeProvider();
    libraryScope = new LibraryScope(element, _listener);
    _visitor = new TypeResolverVisitor(
        element, librarySource, _typeProvider, _listener,
        nameScope: libraryScope);
  }

  void test_visitCatchClause_exception() {
    // catch (e)
    CatchClause clause = AstFactory.catchClause("e");
    SimpleIdentifier exceptionParameter = clause.exceptionParameter;
    exceptionParameter.staticElement =
        new LocalVariableElementImpl.forNode(exceptionParameter);
    _resolveCatchClause(clause, _typeProvider.dynamicType, null);
    _listener.assertNoErrors();
  }

  void test_visitCatchClause_exception_stackTrace() {
    // catch (e, s)
    CatchClause clause = AstFactory.catchClause2("e", "s");
    SimpleIdentifier exceptionParameter = clause.exceptionParameter;
    exceptionParameter.staticElement =
        new LocalVariableElementImpl.forNode(exceptionParameter);
    SimpleIdentifier stackTraceParameter = clause.stackTraceParameter;
    stackTraceParameter.staticElement =
        new LocalVariableElementImpl.forNode(stackTraceParameter);
    _resolveCatchClause(
        clause, _typeProvider.dynamicType, _typeProvider.stackTraceType);
    _listener.assertNoErrors();
  }

  void test_visitCatchClause_on_exception() {
    // on E catch (e)
    ClassElement exceptionElement = ElementFactory.classElement2("E");
    TypeName exceptionType = AstFactory.typeName(exceptionElement);
    CatchClause clause = AstFactory.catchClause4(exceptionType, "e");
    SimpleIdentifier exceptionParameter = clause.exceptionParameter;
    exceptionParameter.staticElement =
        new LocalVariableElementImpl.forNode(exceptionParameter);
    _resolveCatchClause(
        clause, exceptionElement.type, null, [exceptionElement]);
    _listener.assertNoErrors();
  }

  void test_visitCatchClause_on_exception_stackTrace() {
    // on E catch (e, s)
    ClassElement exceptionElement = ElementFactory.classElement2("E");
    TypeName exceptionType = AstFactory.typeName(exceptionElement);
    (exceptionType.name as SimpleIdentifier).staticElement = exceptionElement;
    CatchClause clause = AstFactory.catchClause5(exceptionType, "e", "s");
    SimpleIdentifier exceptionParameter = clause.exceptionParameter;
    exceptionParameter.staticElement =
        new LocalVariableElementImpl.forNode(exceptionParameter);
    SimpleIdentifier stackTraceParameter = clause.stackTraceParameter;
    stackTraceParameter.staticElement =
        new LocalVariableElementImpl.forNode(stackTraceParameter);
    _resolveCatchClause(clause, exceptionElement.type,
        _typeProvider.stackTraceType, [exceptionElement]);
    _listener.assertNoErrors();
  }

  void test_visitClassDeclaration() {
    // class A extends B with C implements D {}
    // class B {}
    // class C {}
    // class D {}
    ClassElement elementA = ElementFactory.classElement2("A");
    ClassElement elementB = ElementFactory.classElement2("B");
    ClassElement elementC = ElementFactory.classElement2("C");
    ClassElement elementD = ElementFactory.classElement2("D");
    ExtendsClause extendsClause =
        AstFactory.extendsClause(AstFactory.typeName(elementB));
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(elementC)]);
    ImplementsClause implementsClause =
        AstFactory.implementsClause([AstFactory.typeName(elementD)]);
    ClassDeclaration declaration = AstFactory.classDeclaration(
        null, "A", null, extendsClause, withClause, implementsClause);
    declaration.name.staticElement = elementA;
    _resolveNode(declaration, [elementA, elementB, elementC, elementD]);
    expect(elementA.supertype, same(elementB.type));
    List<InterfaceType> mixins = elementA.mixins;
    expect(mixins, hasLength(1));
    expect(mixins[0], same(elementC.type));
    List<InterfaceType> interfaces = elementA.interfaces;
    expect(interfaces, hasLength(1));
    expect(interfaces[0], same(elementD.type));
    _listener.assertNoErrors();
  }

  void test_visitClassDeclaration_instanceMemberCollidesWithClass() {
    // class A {}
    // class B extends A {
    //   void A() {}
    // }
    ClassElementImpl elementA = ElementFactory.classElement2("A");
    ClassElementImpl elementB = ElementFactory.classElement2("B");
    elementB.methods = <MethodElement>[
      ElementFactory.methodElement("A", VoidTypeImpl.instance)
    ];
    ExtendsClause extendsClause =
        AstFactory.extendsClause(AstFactory.typeName(elementA));
    ClassDeclaration declaration =
        AstFactory.classDeclaration(null, "B", null, extendsClause, null, null);
    declaration.name.staticElement = elementB;
    _resolveNode(declaration, [elementA, elementB]);
    expect(elementB.supertype, same(elementA.type));
    _listener.assertNoErrors();
  }

  void test_visitClassTypeAlias() {
    // class A = B with C implements D;
    ClassElement elementA = ElementFactory.classElement2("A");
    ClassElement elementB = ElementFactory.classElement2("B");
    ClassElement elementC = ElementFactory.classElement2("C");
    ClassElement elementD = ElementFactory.classElement2("D");
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(elementC)]);
    ImplementsClause implementsClause =
        AstFactory.implementsClause([AstFactory.typeName(elementD)]);
    ClassTypeAlias alias = AstFactory.classTypeAlias("A", null, null,
        AstFactory.typeName(elementB), withClause, implementsClause);
    alias.name.staticElement = elementA;
    _resolveNode(alias, [elementA, elementB, elementC, elementD]);
    expect(elementA.supertype, same(elementB.type));
    List<InterfaceType> mixins = elementA.mixins;
    expect(mixins, hasLength(1));
    expect(mixins[0], same(elementC.type));
    List<InterfaceType> interfaces = elementA.interfaces;
    expect(interfaces, hasLength(1));
    expect(interfaces[0], same(elementD.type));
    _listener.assertNoErrors();
  }

  void test_visitClassTypeAlias_constructorWithOptionalParams_ignored() {
    // class T {}
    // class B {
    //   B.c1();
    //   B.c2([T a0]);
    //   B.c3({T a0});
    // }
    // class M {}
    // class C = B with M
    ClassElement classT = ElementFactory.classElement2('T', []);
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorBc1 =
        ElementFactory.constructorElement2(classB, 'c1', []);
    ConstructorElementImpl constructorBc2 =
        ElementFactory.constructorElement2(classB, 'c2', [classT.type]);
    (constructorBc2.parameters[0] as ParameterElementImpl).parameterKind =
        ParameterKind.POSITIONAL;
    ConstructorElementImpl constructorBc3 =
        ElementFactory.constructorElement2(classB, 'c3', [classT.type]);
    (constructorBc3.parameters[0] as ParameterElementImpl).parameterKind =
        ParameterKind.NAMED;
    classB.constructors = [constructorBc1, constructorBc2, constructorBc3];
    ClassElement classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(classM, [])]);
    ClassElement classC = ElementFactory.classTypeAlias2('C', []);
    ClassTypeAlias alias = AstFactory.classTypeAlias(
        'C', null, null, AstFactory.typeName(classB, []), withClause, null);
    alias.name.staticElement = classC;
    _resolveNode(alias, [classT, classB, classM, classC]);
    expect(classC.constructors, hasLength(1));
    ConstructorElement constructor = classC.constructors[0];
    expect(constructor.isFactory, isFalse);
    expect(constructor.isSynthetic, isTrue);
    expect(constructor.name, 'c1');
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, isEmpty);
  }

  void test_visitClassTypeAlias_constructorWithParams() {
    // class T {}
    // class B {
    //   B(T a0);
    // }
    // class M {}
    // class C = B with M
    ClassElement classT = ElementFactory.classElement2('T', []);
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorB =
        ElementFactory.constructorElement2(classB, '', [classT.type]);
    classB.constructors = [constructorB];
    ClassElement classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(classM, [])]);
    ClassElement classC = ElementFactory.classTypeAlias2('C', []);
    ClassTypeAlias alias = AstFactory.classTypeAlias(
        'C', null, null, AstFactory.typeName(classB, []), withClause, null);
    alias.name.staticElement = classC;
    _resolveNode(alias, [classT, classB, classM, classC]);
    expect(classC.constructors, hasLength(1));
    ConstructorElement constructor = classC.constructors[0];
    expect(constructor.isFactory, isFalse);
    expect(constructor.isSynthetic, isTrue);
    expect(constructor.name, '');
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(1));
    expect(constructor.parameters[0].type, equals(classT.type));
    expect(constructor.parameters[0].name,
        equals(constructorB.parameters[0].name));
  }

  void test_visitClassTypeAlias_defaultConstructor() {
    // class B {}
    // class M {}
    // class C = B with M
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorB =
        ElementFactory.constructorElement2(classB, '', []);
    constructorB.setModifier(Modifier.SYNTHETIC, true);
    classB.constructors = [constructorB];
    ClassElement classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(classM, [])]);
    ClassElement classC = ElementFactory.classTypeAlias2('C', []);
    ClassTypeAlias alias = AstFactory.classTypeAlias(
        'C', null, null, AstFactory.typeName(classB, []), withClause, null);
    alias.name.staticElement = classC;
    _resolveNode(alias, [classB, classM, classC]);
    expect(classC.constructors, hasLength(1));
    ConstructorElement constructor = classC.constructors[0];
    expect(constructor.isFactory, isFalse);
    expect(constructor.isSynthetic, isTrue);
    expect(constructor.name, '');
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, isEmpty);
  }

  void test_visitFieldFormalParameter_functionType() {
    InterfaceType intType = _typeProvider.intType;
    TypeName intTypeName = AstFactory.typeName4("int");
    String innerParameterName = "a";
    SimpleFormalParameter parameter =
        AstFactory.simpleFormalParameter3(innerParameterName);
    parameter.identifier.staticElement =
        ElementFactory.requiredParameter(innerParameterName);
    String outerParameterName = "p";
    FormalParameter node = AstFactory.fieldFormalParameter(null, intTypeName,
        outerParameterName, AstFactory.formalParameterList([parameter]));
    node.identifier.staticElement =
        ElementFactory.requiredParameter(outerParameterName);
    DartType parameterType = _resolveFormalParameter(node, [intType.element]);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionType, FunctionType, parameterType);
    FunctionType functionType = parameterType as FunctionType;
    expect(functionType.returnType, same(intType));
    expect(functionType.parameters, hasLength(1));
    _listener.assertNoErrors();
  }

  void test_visitFieldFormalParameter_noType() {
    String parameterName = "p";
    FormalParameter node =
        AstFactory.fieldFormalParameter(Keyword.VAR, null, parameterName);
    node.identifier.staticElement =
        ElementFactory.requiredParameter(parameterName);
    expect(_resolveFormalParameter(node), same(_typeProvider.dynamicType));
    _listener.assertNoErrors();
  }

  void test_visitFieldFormalParameter_type() {
    InterfaceType intType = _typeProvider.intType;
    TypeName intTypeName = AstFactory.typeName4("int");
    String parameterName = "p";
    FormalParameter node =
        AstFactory.fieldFormalParameter(null, intTypeName, parameterName);
    node.identifier.staticElement =
        ElementFactory.requiredParameter(parameterName);
    expect(_resolveFormalParameter(node, [intType.element]), same(intType));
    _listener.assertNoErrors();
  }

  void test_visitFunctionDeclaration() {
    // R f(P p) {}
    // class R {}
    // class P {}
    ClassElement elementR = ElementFactory.classElement2('R');
    ClassElement elementP = ElementFactory.classElement2('P');
    FunctionElement elementF = ElementFactory.functionElement('f');
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        AstFactory.typeName4('R'),
        null,
        'f',
        AstFactory.functionExpression2(
            AstFactory.formalParameterList([
              AstFactory.simpleFormalParameter4(AstFactory.typeName4('P'), 'p')
            ]),
            null));
    declaration.name.staticElement = elementF;
    _resolveNode(declaration, [elementR, elementP]);
    expect(declaration.returnType.type, elementR.type);
    SimpleFormalParameter parameter =
        declaration.functionExpression.parameters.parameters[0];
    expect(parameter.type.type, elementP.type);
    _listener.assertNoErrors();
  }

  void test_visitFunctionDeclaration_typeParameter() {
    // E f<E>(E e) {}
    TypeParameterElement elementE = ElementFactory.typeParameterElement('E');
    FunctionElementImpl elementF = ElementFactory.functionElement('f');
    elementF.typeParameters = <TypeParameterElement>[elementE];
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        AstFactory.typeName4('E'),
        null,
        'f',
        AstFactory.functionExpression2(
            AstFactory.formalParameterList([
              AstFactory.simpleFormalParameter4(AstFactory.typeName4('E'), 'e')
            ]),
            null));
    declaration.name.staticElement = elementF;
    _resolveNode(declaration, []);
    expect(declaration.returnType.type, elementE.type);
    SimpleFormalParameter parameter =
        declaration.functionExpression.parameters.parameters[0];
    expect(parameter.type.type, elementE.type);
    _listener.assertNoErrors();
  }

  void test_visitFunctionTypedFormalParameter() {
    // R f(R g(P p)) {}
    // class R {}
    // class P {}
    ClassElement elementR = ElementFactory.classElement2('R');
    ClassElement elementP = ElementFactory.classElement2('P');
    FunctionElement elementF = ElementFactory.functionElement('f');
    ParameterElementImpl requiredParameter =
        ElementFactory.requiredParameter('p');
    FunctionTypedFormalParameter parameterDeclaration = AstFactory
        .functionTypedFormalParameter(AstFactory.typeName4('R'), 'g', [
      AstFactory.simpleFormalParameter4(AstFactory.typeName4('P'), 'p')
    ]);
    parameterDeclaration.identifier.staticElement = requiredParameter;
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        AstFactory.typeName4('R'),
        null,
        'f',
        AstFactory.functionExpression2(
            AstFactory.formalParameterList([parameterDeclaration]), null));
    declaration.name.staticElement = elementF;
    _resolveNode(declaration, [elementR, elementP]);
    expect(declaration.returnType.type, elementR.type);
    FunctionTypedFormalParameter parameter =
        declaration.functionExpression.parameters.parameters[0];
    expect(parameter.returnType.type, elementR.type);
    SimpleFormalParameter innerParameter = parameter.parameters.parameters[0];
    expect(innerParameter.type.type, elementP.type);
    _listener.assertNoErrors();
  }

  void test_visitFunctionTypedFormalParameter_typeParameter() {
    // R f(R g<E>(E e)) {}
    // class R {}
    ClassElement elementR = ElementFactory.classElement2('R');
    TypeParameterElement elementE = ElementFactory.typeParameterElement('E');
    FunctionElement elementF = ElementFactory.functionElement('f');
    ParameterElementImpl requiredParameter =
        ElementFactory.requiredParameter('g');
    requiredParameter.typeParameters = <TypeParameterElement>[elementE];
    FunctionTypedFormalParameter parameterDeclaration = AstFactory
        .functionTypedFormalParameter(AstFactory.typeName4('R'), 'g', [
      AstFactory.simpleFormalParameter4(AstFactory.typeName4('E'), 'e')
    ]);
    parameterDeclaration.identifier.staticElement = requiredParameter;
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        AstFactory.typeName4('R'),
        null,
        'f',
        AstFactory.functionExpression2(
            AstFactory.formalParameterList([parameterDeclaration]), null));
    declaration.name.staticElement = elementF;
    _resolveNode(declaration, [elementR]);
    expect(declaration.returnType.type, elementR.type);
    FunctionTypedFormalParameter parameter =
        declaration.functionExpression.parameters.parameters[0];
    expect(parameter.returnType.type, elementR.type);
    SimpleFormalParameter innerParameter = parameter.parameters.parameters[0];
    expect(innerParameter.type.type, elementE.type);
    _listener.assertNoErrors();
  }

  void test_visitMethodDeclaration() {
    // class A {
    //   R m(P p) {}
    // }
    // class R {}
    // class P {}
    ClassElementImpl elementA = ElementFactory.classElement2('A');
    ClassElement elementR = ElementFactory.classElement2('R');
    ClassElement elementP = ElementFactory.classElement2('P');
    MethodElement elementM = ElementFactory.methodElement('m', null);
    elementA.methods = <MethodElement>[elementM];
    MethodDeclaration declaration = AstFactory.methodDeclaration(
        null,
        AstFactory.typeName4('R'),
        null,
        null,
        AstFactory.identifier3('m'),
        AstFactory.formalParameterList([
          AstFactory.simpleFormalParameter4(AstFactory.typeName4('P'), 'p')
        ]));
    declaration.name.staticElement = elementM;
    _resolveNode(declaration, [elementA, elementR, elementP]);
    expect(declaration.returnType.type, elementR.type);
    SimpleFormalParameter parameter = declaration.parameters.parameters[0];
    expect(parameter.type.type, elementP.type);
    _listener.assertNoErrors();
  }

  void test_visitMethodDeclaration_typeParameter() {
    // class A {
    //   E m<E>(E e) {}
    // }
    ClassElementImpl elementA = ElementFactory.classElement2('A');
    TypeParameterElement elementE = ElementFactory.typeParameterElement('E');
    MethodElementImpl elementM = ElementFactory.methodElement('m', null);
    elementM.typeParameters = <TypeParameterElement>[elementE];
    elementA.methods = <MethodElement>[elementM];
    MethodDeclaration declaration = AstFactory.methodDeclaration(
        null,
        AstFactory.typeName4('E'),
        null,
        null,
        AstFactory.identifier3('m'),
        AstFactory.formalParameterList([
          AstFactory.simpleFormalParameter4(AstFactory.typeName4('E'), 'e')
        ]));
    declaration.name.staticElement = elementM;
    _resolveNode(declaration, [elementA]);
    expect(declaration.returnType.type, elementE.type);
    SimpleFormalParameter parameter = declaration.parameters.parameters[0];
    expect(parameter.type.type, elementE.type);
    _listener.assertNoErrors();
  }

  void test_visitSimpleFormalParameter_noType() {
    // p
    FormalParameter node = AstFactory.simpleFormalParameter3("p");
    node.identifier.staticElement =
        new ParameterElementImpl.forNode(AstFactory.identifier3("p"));
    expect(_resolveFormalParameter(node), same(_typeProvider.dynamicType));
    _listener.assertNoErrors();
  }

  void test_visitSimpleFormalParameter_type() {
    // int p
    InterfaceType intType = _typeProvider.intType;
    ClassElement intElement = intType.element;
    FormalParameter node =
        AstFactory.simpleFormalParameter4(AstFactory.typeName(intElement), "p");
    SimpleIdentifier identifier = node.identifier;
    ParameterElementImpl element = new ParameterElementImpl.forNode(identifier);
    identifier.staticElement = element;
    expect(_resolveFormalParameter(node, [intElement]), same(intType));
    _listener.assertNoErrors();
  }

  void test_visitTypeName_noParameters_noArguments() {
    ClassElement classA = ElementFactory.classElement2("A");
    TypeName typeName = AstFactory.typeName(classA);
    typeName.type = null;
    _resolveNode(typeName, [classA]);
    expect(typeName.type, same(classA.type));
    _listener.assertNoErrors();
  }

  void test_visitTypeName_noParameters_noArguments_undefined() {
    SimpleIdentifier id = AstFactory.identifier3("unknown")
      ..staticElement = new _StaleElement();
    TypeName typeName = new TypeName(id, null);
    _resolveNode(typeName, []);
    expect(typeName.type, UndefinedTypeImpl.instance);
    expect(typeName.name.staticElement, null);
    _listener.assertErrorsWithCodes([StaticWarningCode.UNDEFINED_CLASS]);
  }

  void test_visitTypeName_parameters_arguments() {
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    ClassElement classB = ElementFactory.classElement2("B");
    TypeName typeName =
        AstFactory.typeName(classA, [AstFactory.typeName(classB)]);
    typeName.type = null;
    _resolveNode(typeName, [classA, classB]);
    InterfaceType resultType = typeName.type as InterfaceType;
    expect(resultType.element, same(classA));
    List<DartType> resultArguments = resultType.typeArguments;
    expect(resultArguments, hasLength(1));
    expect(resultArguments[0], same(classB.type));
    _listener.assertNoErrors();
  }

  void test_visitTypeName_parameters_noArguments() {
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    TypeName typeName = AstFactory.typeName(classA);
    typeName.type = null;
    _resolveNode(typeName, [classA]);
    InterfaceType resultType = typeName.type as InterfaceType;
    expect(resultType.element, same(classA));
    List<DartType> resultArguments = resultType.typeArguments;
    expect(resultArguments, hasLength(1));
    expect(resultArguments[0], same(DynamicTypeImpl.instance));
    _listener.assertNoErrors();
  }

  void test_visitTypeName_prefixed_noParameters_noArguments_undefined() {
    SimpleIdentifier prefix = AstFactory.identifier3("unknownPrefix")
      ..staticElement = new _StaleElement();
    SimpleIdentifier suffix = AstFactory.identifier3("unknownSuffix")
      ..staticElement = new _StaleElement();
    TypeName typeName =
        new TypeName(AstFactory.identifier(prefix, suffix), null);
    _resolveNode(typeName, []);
    expect(typeName.type, UndefinedTypeImpl.instance);
    expect(prefix.staticElement, null);
    expect(suffix.staticElement, null);
    _listener.assertErrorsWithCodes([StaticWarningCode.UNDEFINED_CLASS]);
  }

  void test_visitTypeName_void() {
    ClassElement classA = ElementFactory.classElement2("A");
    TypeName typeName = AstFactory.typeName4("void");
    _resolveNode(typeName, [classA]);
    expect(typeName.type, same(VoidTypeImpl.instance));
    _listener.assertNoErrors();
  }

  /**
   * Analyze the given catch clause and assert that the types of the parameters have been set to the
   * given types. The types can be null if the catch clause does not have the corresponding
   * parameter.
   *
   * @param node the catch clause to be analyzed
   * @param exceptionType the expected type of the exception parameter
   * @param stackTraceType the expected type of the stack trace parameter
   * @param definedElements the elements that are to be defined in the scope in which the element is
   *          being resolved
   */
  void _resolveCatchClause(
      CatchClause node, DartType exceptionType, InterfaceType stackTraceType,
      [List<Element> definedElements]) {
    _resolveNode(node, definedElements);
    SimpleIdentifier exceptionParameter = node.exceptionParameter;
    if (exceptionParameter != null) {
      expect(exceptionParameter.staticType, same(exceptionType));
    }
    SimpleIdentifier stackTraceParameter = node.stackTraceParameter;
    if (stackTraceParameter != null) {
      expect(stackTraceParameter.staticType, same(stackTraceType));
    }
  }

  /**
   * Return the type associated with the given parameter after the static type analyzer has computed
   * a type for it.
   *
   * @param node the parameter with which the type is associated
   * @param definedElements the elements that are to be defined in the scope in which the element is
   *          being resolved
   * @return the type associated with the parameter
   */
  DartType _resolveFormalParameter(FormalParameter node,
      [List<Element> definedElements]) {
    _resolveNode(node, definedElements);
    return (node.identifier.staticElement as ParameterElement).type;
  }

  /**
   * Return the element associated with the given identifier after the resolver has resolved the
   * identifier.
   *
   * @param node the expression to be resolved
   * @param definedElements the elements that are to be defined in the scope in which the element is
   *          being resolved
   * @return the element to which the expression was resolved
   */
  void _resolveNode(AstNode node, [List<Element> definedElements]) {
    if (definedElements != null) {
      for (Element element in definedElements) {
        libraryScope.define(element);
      }
    }
    node.accept(_visitor);
  }
}

/**
 * Represents an element left over from a previous resolver run.
 *
 * A _StaleElement should always be replaced with either null or a new Element.
 */
class _StaleElement extends ElementImpl {
  _StaleElement() : super("_StaleElement", -1);

  @override
  get kind => throw "_StaleElement's kind shouldn't be accessed";

  @override
  accept(_) => throw "_StaleElement shouldn't be visited";
}
