// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/driver_resolution.dart';
import 'analysis_context_factory.dart';
import 'parser_test.dart';
import 'resolver_test_case.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDeltaTest);
    defineReflectiveTests(ChangeSetTest);
    defineReflectiveTests(EnclosedScopeTest);
    defineReflectiveTests(ErrorResolverTest);
    defineReflectiveTests(LibraryImportScopeTest);
    defineReflectiveTests(LibraryScopeTest);
    defineReflectiveTests(PrefixedNamespaceTest);
    defineReflectiveTests(ScopeTest);
    defineReflectiveTests(StrictModeTest);
    defineReflectiveTests(TypePropagationTest);
    defineReflectiveTests(TypeProviderImplTest);
    defineReflectiveTests(TypeResolverVisitorTest);
  });
}

/// Wrapper around the test package's `fail` function.
///
/// Unlike the test package's `fail` function, this function is not annotated
/// with @alwaysThrows, so we can call it at the top of a test method without
/// causing the rest of the method to be flagged as dead code.
void _fail(String message) {
  fail(message);
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
    expect(changeSet.removedSources, hasLength(0));
    expect(changeSet.removedContainers, hasLength(0));
  }

  void test_toString() {
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(new TestSource());
    changeSet.changedSource(new TestSource());
    changeSet.changedContent(new TestSource(), "");
    changeSet.changedRange(new TestSource(), "", 0, 0, 0);
    changeSet.removedSource(new TestSource());
    changeSet
        .removedContainer(new SourceContainer_ChangeSetTest_test_toString());
    expect(changeSet.toString(), isNotNull);
  }
}

@reflectiveTest
class EnclosedScopeTest extends ResolverTestCase {
  test_define_duplicate() async {
    Scope rootScope = new _RootScope();
    EnclosedScope scope = new EnclosedScope(rootScope);
    SimpleIdentifier identifier = AstTestFactory.identifier3('v');
    VariableElement element1 = ElementFactory.localVariableElement(identifier);
    VariableElement element2 = ElementFactory.localVariableElement(identifier);
    scope.define(element1);
    scope.define(element2);
    expect(scope.lookup(identifier, null), same(element1));
  }
}

@reflectiveTest
class ErrorResolverTest extends DriverResolutionTest {
  test_breakLabelOnSwitchMember() async {
    assertErrorsInCode(r'''
class A {
  void m(int i) {
    switch (i) {
      l: case 0:
        break;
      case 1:
        break l;
    }
  }
}''', [ResolverErrorCode.BREAK_LABEL_ON_SWITCH_MEMBER]);
  }

  test_continueLabelOnSwitch() async {
    assertErrorsInCode(r'''
class A {
  void m(int i) {
    l: switch (i) {
      case 0:
        continue l;
    }
  }
}''', [ResolverErrorCode.CONTINUE_LABEL_ON_SWITCH]);
  }

  test_enclosingElement_invalidLocalFunction() async {
    addTestFile(r'''
class C {
  C() {
    int get x => 0;
  }
}''');
    await resolveTestFile();
    assertTestErrors([
      ParserErrorCode.MISSING_FUNCTION_PARAMETERS,
      ParserErrorCode.EXPECTED_TOKEN
    ]);

    var constructor = findElement.unnamedConstructor('C');
    var x = findElement.localFunction('x');
    expect(x.enclosingElement, constructor);
  }
}

/**
 * Tests for generic method and function resolution that do not use strong mode.
 */
@reflectiveTest
class GenericMethodResolverTest extends StaticTypeAnalyzer2TestShared {
  test_genericMethod_propagatedType_promotion() async {
    // Regression test for:
    // https://github.com/dart-lang/sdk/issues/25340
    //
    // Note, after https://github.com/dart-lang/sdk/issues/25486 the original
    // strong mode example won't work, as we now compute a static type and
    // therefore discard the propagated type.
    //
    // So this test does not use strong mode.
    await resolveTestUnit(r'''
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
    expectIdentifierType('y = ', 'dynamic');
  }
}

@reflectiveTest
class LibraryImportScopeTest extends ResolverTestCase {
  void test_creation_empty() {
    new LibraryImportScope(createDefaultTestLibrary());
  }

  void test_creation_nonEmpty() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore(
        resourceProvider: resourceProvider);
    String importedTypeName = "A";
    ClassElement importedType = new ClassElementImpl.forNode(
        AstTestFactory.identifier3(importedTypeName));
    LibraryElement importedLibrary = createTestLibrary(context, "imported");
    (importedLibrary.definingCompilationUnit as CompilationUnitElementImpl)
        .types = <ClassElement>[importedType];
    LibraryElementImpl definingLibrary =
        createTestLibrary(context, "importing");
    ImportElementImpl importElement = new ImportElementImpl(0);
    importElement.importedLibrary = importedLibrary;
    definingLibrary.imports = <ImportElement>[importElement];
    Scope scope = new LibraryImportScope(definingLibrary);
    expect(
        scope.lookup(
            AstTestFactory.identifier3(importedTypeName), definingLibrary),
        importedType);
  }

  void test_prefixedAndNonPrefixed() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore(
        resourceProvider: resourceProvider);
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
    Scope scope = new LibraryImportScope(importingLibrary);
    Element prefixedElement = scope.lookup(
        AstTestFactory.identifier5(prefixName, typeName), importingLibrary);
    expect(prefixedElement, same(prefixedType));
    Element nonPrefixedElement =
        scope.lookup(AstTestFactory.identifier3(typeName), importingLibrary);
    expect(nonPrefixedElement, same(nonPrefixedType));
  }
}

@reflectiveTest
class LibraryScopeTest extends ResolverTestCase {
  void test_creation_empty() {
    new LibraryScope(createDefaultTestLibrary());
  }

  void test_creation_nonEmpty() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore(
        resourceProvider: resourceProvider);
    String importedTypeName = "A";
    ClassElement importedType = new ClassElementImpl.forNode(
        AstTestFactory.identifier3(importedTypeName));
    LibraryElement importedLibrary = createTestLibrary(context, "imported");
    (importedLibrary.definingCompilationUnit as CompilationUnitElementImpl)
        .types = <ClassElement>[importedType];
    LibraryElementImpl definingLibrary =
        createTestLibrary(context, "importing");
    ImportElementImpl importElement = new ImportElementImpl(0);
    importElement.importedLibrary = importedLibrary;
    definingLibrary.imports = <ImportElement>[importElement];
    Scope scope = new LibraryScope(definingLibrary);
    expect(
        scope.lookup(
            AstTestFactory.identifier3(importedTypeName), definingLibrary),
        importedType);
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

  Map<String, Element> _toMap(List<Element> elements) {
    Map<String, Element> map = new HashMap<String, Element>();
    for (Element element in elements) {
      map[element.name] = element;
    }
    return map;
  }
}

@reflectiveTest
class ScopeTest extends ResolverTestCase {
  void test_define_duplicate() {
    Scope scope = new _RootScope();
    SimpleIdentifier identifier = AstTestFactory.identifier3('v');
    VariableElement element1 = ElementFactory.localVariableElement(identifier);
    VariableElement element2 = ElementFactory.localVariableElement(identifier);
    scope.define(element1);
    scope.define(element2);
    expect(scope.localLookup('v', null), same(element1));
  }

  void test_isPrivateName_nonPrivate() {
    expect(Scope.isPrivateName("Public"), isFalse);
  }

  void test_isPrivateName_private() {
    expect(Scope.isPrivateName("_Private"), isTrue);
  }
}

class SourceContainer_ChangeSetTest_test_toString implements SourceContainer {
  @override
  bool contains(Source source) => false;
}

/**
 * Instances of the class `StaticTypeVerifier` verify that all of the nodes in an AST
 * structure that should have a static type associated with them do have a static type.
 */
class StaticTypeVerifier extends GeneralizingAstVisitor<void> {
  /**
   * A list containing all of the AST Expression nodes that were not resolved.
   */
  List<Expression> _unresolvedExpressions = new List<Expression>();

  /**
   * The TypeAnnotation nodes that were not resolved.
   */
  List<TypeAnnotation> _unresolvedTypes = new List<TypeAnnotation>();

  /**
   * Counter for the number of Expression nodes visited that are resolved.
   */
  int _resolvedExpressionCount = 0;

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
        for (TypeAnnotation identifier in _unresolvedTypes) {
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
      fail(buffer.toString());
    }
  }

  @override
  void visitBreakStatement(BreakStatement node) {}

  @override
  void visitCommentReference(CommentReference node) {}

  @override
  void visitContinueStatement(ContinueStatement node) {}

  @override
  void visitExportDirective(ExportDirective node) {}

  @override
  void visitExpression(Expression node) {
    node.visitChildren(this);
    DartType staticType = node.staticType;
    if (staticType == null) {
      _unresolvedExpressions.add(node);
    } else {
      _resolvedExpressionCount++;
    }
  }

  @override
  void visitImportDirective(ImportDirective node) {}

  @override
  void visitLabel(Label node) {}

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {}

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // In cases where we have a prefixed identifier where the prefix is dynamic,
    // we don't want to assert that the node will have a type.
    if (node.staticType == null &&
        resolutionMap.staticTypeForExpression(node.prefix).isDynamic) {
      return;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // In cases where identifiers are being used for something other than an
    // expressions, then they can be ignored.
    AstNode parent = node.parent;
    if (parent is MethodInvocation && identical(node, parent.methodName)) {
      return;
    } else if (parent is RedirectingConstructorInvocation &&
        identical(node, parent.constructorName)) {
      return;
    } else if (parent is SuperConstructorInvocation &&
        identical(node, parent.constructorName)) {
      return;
    } else if (parent is ConstructorName && identical(node, parent.name)) {
      return;
    } else if (parent is ConstructorFieldInitializer &&
        identical(node, parent.fieldName)) {
      return;
    } else if (node.staticElement is PrefixElement) {
      // Prefixes don't have a type.
      return;
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitTypeAnnotation(TypeAnnotation node) {
    if (node.type == null) {
      _unresolvedTypes.add(node);
    } else {
      _resolvedTypeCount++;
    }
    super.visitTypeAnnotation(node);
  }

  @override
  void visitTypeName(TypeName node) {
    // Note: do not visit children from this node, the child SimpleIdentifier in
    // TypeName (i.e. "String") does not have a static type defined.
    // TODO(brianwilkerson) Not visiting the children means that we won't catch
    // type arguments that were not resolved.
    if (node.type == null) {
      _unresolvedTypes.add(node);
    } else {
      _resolvedTypeCount++;
    }
  }

  String _getFileName(AstNode node) {
    // TODO (jwren) there are two copies of this method, one here and one in
    // ResolutionVerifier, they should be resolved into a single method
    if (node != null) {
      AstNode root = node.root;
      if (root is CompilationUnit) {
        CompilationUnit rootCU = root;
        if (rootCU.declaredElement != null) {
          return resolutionMap
              .elementDeclaredByCompilationUnit(rootCU)
              .source
              .fullName;
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
  @override
  bool get enableNewAnalysisDriver => true;

  @override
  void setUp() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.hint = false;
    resetWith(options: options);
  }

  test_assert_is() async {
    Source source = addSource(r'''
int f(num n) {
  assert (n is int);
  return n & 0x0F;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_conditional_and_is() async {
    Source source = addSource(r'''
int f(num n) {
  return (n is int && n > 0) ? n & 0x0F : 0;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_conditional_is() async {
    Source source = addSource(r'''
int f(num n) {
  return (n is int) ? n & 0x0F : 0;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_conditional_isNot() async {
    Source source = addSource(r'''
int f(num n) {
  return (n is! int) ? 0 : n & 0x0F;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_conditional_or_is() async {
    Source source = addSource(r'''
int f(num n) {
  return (n is! int || n < 0) ? 0 : n & 0x0F;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  @failingTest
  test_for() async {
    Source source = addSource(r'''
int f(List<int> list) {
  num sum = 0;
  for (num i = 0; i < list.length; i++) {
    sum += list[i];
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_forEach() async {
    Source source = addSource(r'''
int f(List<int> list) {
  num sum = 0;
  for (num n in list) {
    sum += n & 0x0F;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_if_and_is() async {
    Source source = addSource(r'''
int f(num n) {
  if (n is int && n > 0) {
    return n & 0x0F;
  }
  return 0;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_if_is() async {
    Source source = addSource(r'''
int f(num n) {
  if (n is int) {
    return n & 0x0F;
  }
  return 0;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_if_isNot() async {
    Source source = addSource(r'''
int f(num n) {
  if (n is! int) {
    return 0;
  } else {
    return n & 0x0F;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_if_isNot_abrupt() async {
    Source source = addSource(r'''
int f(num n) {
  if (n is! int) {
    return 0;
  }
  return n & 0x0F;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_if_or_is() async {
    Source source = addSource(r'''
int f(num n) {
  if (n is! int || n < 0) {
    return 0;
  } else {
    return n & 0x0F;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_localVar() async {
    Source source = addSource(r'''
int f() {
  num n = 1234;
  return n & 0x0F;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
}

@reflectiveTest
class TypePropagationTest extends ResolverTestCase {
  @override
  bool get enableNewAnalysisDriver => true;

  test_assignment_null() async {
    String code = r'''
main() {
  int v; // declare
  v = null;
  return v; // return
}''';
    CompilationUnit unit;
    {
      Source source = addSource(code);
      TestAnalysisResult analysisResult = await computeAnalysisResult(source);
      assertNoErrors(source);
      verify([source]);
      unit = analysisResult.unit;
    }
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit, code, "v; // declare", (node) => node is SimpleIdentifier);
      expect(identifier.staticType, typeProvider.intType);
    }
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit, code, "v = null;", (node) => node is SimpleIdentifier);
      expect(identifier.staticType, typeProvider.intType);
    }
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit, code, "v; // return", (node) => node is SimpleIdentifier);
      expect(identifier.staticType, typeProvider.intType);
    }
  }

  test_functionExpression_asInvocationArgument_notSubtypeOfStaticType() async {
    String code = r'''
class A {
  m(void f(int i)) {}
}
x() {
  A a = new A();
  a.m(() => 0);
}''';
    Source source = addSource(code);
    CompilationUnit unit = await _computeResolvedUnit(source, noErrors: false);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    // () => 0
    FunctionExpression functionExpression = EngineTestCase.findNode(
        unit, code, "() => 0)", (node) => node is FunctionExpression);
    expect((functionExpression.staticType as FunctionType).parameters.length,
        same(0));
  }

  test_initializer_hasStaticType() async {
    Source source = addSource(r'''
f() {
  int v = 0;
  return v;
}''');
    CompilationUnit unit = await _computeResolvedUnit(source);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    NodeList<Statement> statements = body.block.statements;
    // Type of 'v' in declaration.
    {
      VariableDeclarationStatement statement =
          statements[0] as VariableDeclarationStatement;
      SimpleIdentifier variableName = statement.variables.variables[0].name;
      expect(variableName.staticType, typeProvider.intType);
    }
    // Type of 'v' in reference.
    {
      ReturnStatement statement = statements[1] as ReturnStatement;
      SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
      expect(variableName.staticType, typeProvider.intType);
    }
  }

  test_initializer_hasStaticType_parameterized() async {
    Source source = addSource(r'''
f() {
  List<int> v = <int>[];
  return v;
}''');
    CompilationUnit unit = await _computeResolvedUnit(source);
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
    }
    // Type of 'v' in reference.
    {
      ReturnStatement statement = statements[1] as ReturnStatement;
      SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
      expect(variableName.staticType, isNotNull);
    }
  }

  test_initializer_null() async {
    String code = r'''
main() {
  int v = null;
  return v; // marker
}''';
    CompilationUnit unit;
    {
      Source source = addSource(code);
      unit = await _computeResolvedUnit(source);
    }
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit, code, "v = null;", (node) => node is SimpleIdentifier);
      expect(identifier.staticType, typeProvider.intType);
    }
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit, code, "v; // marker", (node) => node is SimpleIdentifier);
      expect(identifier.staticType, typeProvider.intType);
    }
  }

  test_invocation_target_prefixed() async {
    addNamedSource('/helper.dart', '''
library helper;
int max(int x, int y) => 0;
''');
    String code = '''
import 'helper.dart' as helper;
main() {
  helper.max(10, 10); // marker
}''';
    CompilationUnit unit = await resolveSource(code);
    SimpleIdentifier methodName =
        findMarkedIdentifier(code, unit, "(10, 10); // marker");
    MethodInvocation methodInvoke = methodName.parent;
    expect(methodInvoke.methodName.staticElement, isNotNull);
  }

  test_is_subclass() async {
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
    CompilationUnit unit = await _computeResolvedUnit(source);
    FunctionDeclaration function = unit.declarations[2] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement =
        (ifStatement.thenStatement as Block).statements[0] as ReturnStatement;
    MethodInvocation invocation = statement.expression as MethodInvocation;
    expect(invocation.methodName.staticElement, isNotNull);
  }

  test_mutatedOutsideScope() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_objectAccessInference_disabled_for_library_prefix() async {
    String name = 'hashCode';
    addNamedSource('/helper.dart', '''
library helper;
dynamic get $name => 42;
''');
    String code = '''
import 'helper.dart' as helper;
main() {
  helper.$name; // marker
}''';

    CompilationUnit unit = await resolveSource(code);
    SimpleIdentifier id = findMarkedIdentifier(code, unit, "; // marker");
    PrefixedIdentifier prefixedId = id.parent;
    expect(id.staticType, typeProvider.dynamicType);
    expect(prefixedId.staticType, typeProvider.dynamicType);
  }

  test_objectAccessInference_disabled_for_local_getter() async {
    String name = 'hashCode';
    String code = '''
dynamic get $name => null;
main() {
  $name; // marker
}''';

    CompilationUnit unit = await resolveSource(code);
    SimpleIdentifier getter = findMarkedIdentifier(code, unit, "; // marker");
    expect(getter.staticType, typeProvider.dynamicType);
  }

  test_objectMethodInference_disabled_for_library_prefix() async {
    String name = 'toString';
    addNamedSource('/helper.dart', '''
library helper;
dynamic toString = (int x) => x + 42;
''');
    String code = '''
import 'helper.dart' as helper;
main() {
  helper.$name(); // marker
}''';
    CompilationUnit unit = await resolveSource(code);
    SimpleIdentifier methodName =
        findMarkedIdentifier(code, unit, "(); // marker");
    MethodInvocation methodInvoke = methodName.parent;
    expect(methodName.staticType, typeProvider.dynamicType);
    expect(methodInvoke.staticType, typeProvider.dynamicType);
  }

  test_objectMethodInference_disabled_for_local_function() async {
    String name = 'toString';
    String code = '''
main() {
  dynamic $name = () => null;
  $name(); // marker
}''';
    CompilationUnit unit = await resolveSource(code);

    SimpleIdentifier identifier = findMarkedIdentifier(code, unit, "$name = ");
    expect(identifier.staticType, typeProvider.dynamicType);

    SimpleIdentifier methodName =
        findMarkedIdentifier(code, unit, "(); // marker");
    MethodInvocation methodInvoke = methodName.parent;
    expect(methodName.staticType, typeProvider.dynamicType);
    expect(methodInvoke.staticType, typeProvider.dynamicType);
  }

  @failingTest
  test_propagatedReturnType_functionExpression() async {
    // TODO(scheglov) disabled because we don't resolve function expression
    String code = r'''
main() {
  var v = (() {return 42;})();
}''';
    CompilationUnit unit = await resolveSource(code);
    assertAssignedType(code, unit, typeProvider.dynamicType);
  }

  /**
   * Return the resolved unit for the given [source].
   *
   * If [noErrors] is not specified or is not `true`, [assertNoErrors].
   */
  Future<CompilationUnit> _computeResolvedUnit(Source source,
      {bool noErrors: true}) async {
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    if (noErrors) {
      assertNoErrors(source);
      verify([source]);
    }
    return analysisResult.unit;
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
    InterfaceType futureOrType =
        _classElement("FutureOr", objectType, ["T"]).type;
    InterfaceType intType = _classElement("int", numType).type;
    InterfaceType iterableType =
        _classElement("Iterable", objectType, ["T"]).type;
    InterfaceType listType = _classElement("List", objectType, ["E"]).type;
    InterfaceType mapType = _classElement("Map", objectType, ["K", "V"]).type;
    InterfaceType setType = _classElement("Set", objectType, ["E"]).type;
    InterfaceType stackTraceType = _classElement("StackTrace", objectType).type;
    InterfaceType streamType = _classElement("Stream", objectType, ["T"]).type;
    InterfaceType stringType = _classElement("String", objectType).type;
    InterfaceType symbolType = _classElement("Symbol", objectType).type;
    InterfaceType typeType = _classElement("Type", objectType).type;
    CompilationUnitElementImpl coreUnit = new CompilationUnitElementImpl();
    coreUnit.types = <ClassElement>[
      boolType.element,
      doubleType.element,
      functionType.element,
      intType.element,
      iterableType.element,
      listType.element,
      mapType.element,
      setType.element,
      objectType.element,
      stackTraceType.element,
      stringType.element,
      symbolType.element,
      typeType.element
    ];
    coreUnit.source = new TestSource('dart:core');
    coreUnit.librarySource = coreUnit.source;
    CompilationUnitElementImpl asyncUnit = new CompilationUnitElementImpl();
    asyncUnit.types = <ClassElement>[
      futureType.element,
      futureOrType.element,
      streamType.element
    ];
    asyncUnit.source = new TestSource('dart:async');
    asyncUnit.librarySource = asyncUnit.source;
    LibraryElementImpl coreLibrary = new LibraryElementImpl.forNode(
        null, null, AstTestFactory.libraryIdentifier2(["dart.core"]));
    coreLibrary.definingCompilationUnit = coreUnit;
    LibraryElementImpl asyncLibrary = new LibraryElementImpl.forNode(
        null, null, AstTestFactory.libraryIdentifier2(["dart.async"]));
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
    expect(provider.futureOrType, same(futureOrType));
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

  ClassElement _classElement(String typeName, InterfaceType superclassType,
      [List<String> parameterNames]) {
    ClassElementImpl element =
        new ClassElementImpl.forNode(AstTestFactory.identifier3(typeName));
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
                  AstTestFactory.identifier3(parameterNames[i]));
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
class TypeResolverVisitorTest extends ParserTestCase
    with ResourceProviderMixin {
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

  fail_visitConstructorDeclaration() async {
    _fail("Not yet tested");
    _listener.assertNoErrors();
  }

  fail_visitFunctionTypeAlias() async {
    _fail("Not yet tested");
    _listener.assertNoErrors();
  }

  fail_visitVariableDeclaration() async {
    _fail("Not yet tested");
    ClassElement type = ElementFactory.classElement2("A");
    VariableDeclaration node = AstTestFactory.variableDeclaration("a");
    AstTestFactory.variableDeclarationList(
        null, AstTestFactory.typeName(type), [node]);
    //resolve(node);
    expect(node.name.staticType, same(type.type));
    _listener.assertNoErrors();
  }

  void setUp({bool shouldSetElementSupertypes: false}) {
    _listener = new GatheringErrorListener();
    InternalAnalysisContext context = AnalysisContextFactory.contextWithCore(
        resourceProvider: resourceProvider);
    Source librarySource = new FileSource(getFile("/lib.dart"));
    LibraryElementImpl element = new LibraryElementImpl.forNode(
        context, null, AstTestFactory.libraryIdentifier2(["lib"]));
    element.definingCompilationUnit = new CompilationUnitElementImpl();
    _typeProvider = new TestTypeProvider();
    libraryScope = new LibraryScope(element);
    _visitor = new TypeResolverVisitor(
        element, librarySource, _typeProvider, _listener,
        nameScope: libraryScope,
        shouldSetElementSupertypes: shouldSetElementSupertypes);
  }

  test_modeApi() async {
    CompilationUnit unit = parseCompilationUnit(r'''
class C extends A with A implements A {
  A f = new A();
  A m() {
    A v1;
  }
}
A f([A p = const A()]) {
  A v2;
}
A V = new A();
''');
    var unitElement = new CompilationUnitElementImpl();
    ClassElementImpl A = ElementFactory.classElement2('A');

    // Build API elements.
    {
      var holder = new ElementHolder();
      unit.accept(new ApiElementBuilder(holder, unitElement));
    }

    // Resolve API types.
    {
      InternalAnalysisContext context = AnalysisContextFactory.contextWithCore(
          resourceProvider: resourceProvider);
      var source = getFile('/test.dart').createSource();
      var libraryElement = new LibraryElementImpl.forNode(context, null, null)
        ..definingCompilationUnit = unitElement;
      var libraryScope = new LibraryScope(libraryElement);
      var visitor = new TypeResolverVisitor(
          libraryElement, source, _typeProvider, _listener,
          nameScope: libraryScope, mode: TypeResolverMode.api);
      libraryScope.define(A);
      unit.accept(visitor);
    }

    // Top-level: C
    {
      var c = unit.declarations[0] as ClassDeclaration;

      // The extends/with/implements types are resolved.
      expect(c.extendsClause.superclass.toString(), 'A');
      expect(c.withClause.mixinTypes[0].type.toString(), 'A');
      expect(c.implementsClause.interfaces[0].type.toString(), 'A');

      {
        var fd = c.members[0] as FieldDeclaration;
        // The field type is resolved.
        expect(fd.fields.type.type.toString(), 'A');
        // The type in the initializer is not resolved.
        var f = fd.fields.variables[0];
        var fi = f.initializer as InstanceCreationExpression;
        expect(fi.constructorName.type.type, isNull);
      }

      {
        var m = c.members[1] as MethodDeclaration;
        // The return type is resolved.
        expect(m.returnType.type.toString(), 'A');
        // The local variable type is not resolved.
        var body = m.body as BlockFunctionBody;
        var vd = body.block.statements.single as VariableDeclarationStatement;
        expect(vd.variables.type.type, isNull);
      }
    }

    // Top-level: f
    {
      var f = unit.declarations[1] as FunctionDeclaration;
      FunctionExpression fe = f.functionExpression;
      // The return type is resolved.
      expect(f.returnType.type.toString(), 'A');
      // The parameter type is resolved.
      var pd = fe.parameters.parameters[0] as DefaultFormalParameter;
      var p = pd.parameter as SimpleFormalParameter;
      expect(p.type.type.toString(), 'A');
      // The parameter default is not resolved.
      {
        var pde = pd.defaultValue as InstanceCreationExpression;
        expect(pde.constructorName.type.type, isNull);
      }
      // The local variable type is not resolved.
      var body = fe.body as BlockFunctionBody;
      var vd = body.block.statements.single as VariableDeclarationStatement;
      expect(vd.variables.type.type, isNull);
    }

    // Top-level: V
    {
      var vd = unit.declarations[2] as TopLevelVariableDeclaration;
      // The type is resolved.
      expect(vd.variables.type.toString(), 'A');
      // The initializer is not resolved.
      VariableDeclaration v = vd.variables.variables[0];
      var vi = v.initializer as InstanceCreationExpression;
      expect(vi.constructorName.type.type, isNull);
    }
  }

  test_modeLocal_noContext() async {
    CompilationUnit unit;
    _resolveTypeModeLocal(r'''
class C {
  A f = new A();
  A m([A p = const A()]) {
    A v;
  }
}
A f([A p = const A()]) {
  A v1 = new A();
  A f2(A p2) {
    A v2;
  }
}
A V = new A();
A get G => new A();
''', (CompilationUnit u) {
      unit = u;
      return u;
    });

    // Top-level: C
    {
      var c = unit.declarations[0] as ClassDeclaration;
      {
        var fd = c.members[0] as FieldDeclaration;
        // The type of "f" is not resolved.
        expect(fd.fields.type.type, isNull);
        // The initializer of "f" is resolved.
        var f = fd.fields.variables[0];
        var fi = f.initializer as InstanceCreationExpression;
        expect(fi.constructorName.type.type.toString(), 'A');
      }
      {
        var m = c.members[1] as MethodDeclaration;
        // The return type of "m" is not resolved.
        expect(m.returnType.type, isNull);
        // The type of the parameter "p" is not resolved.
        var pd = m.parameters.parameters[0] as DefaultFormalParameter;
        var p = pd.parameter as SimpleFormalParameter;
        expect(p.type.type, isNull);
        // The default value of the parameter "p" is resolved.
        var pdd = pd.defaultValue as InstanceCreationExpression;
        expect(pdd.constructorName.type.type.toString(), 'A');
        // The type of "v" is resolved.
        var mb = m.body as BlockFunctionBody;
        var vd = mb.block.statements[0] as VariableDeclarationStatement;
        expect(vd.variables.type.type.toString(), 'A');
      }
    }

    // Top-level: f
    {
      var f = unit.declarations[1] as FunctionDeclaration;
      // The return type of "f" is not resolved.
      expect(f.returnType.type, isNull);
      // The type of the parameter "p" is not resolved.
      var fe = f.functionExpression;
      var pd = fe.parameters.parameters[0] as DefaultFormalParameter;
      var p = pd.parameter as SimpleFormalParameter;
      expect(p.type.type, isNull);
      // The default value of the parameter "p" is resolved.
      var pdd = pd.defaultValue as InstanceCreationExpression;
      expect(pdd.constructorName.type.type.toString(), 'A');
      // The type of "v1" is resolved.
      var fb = fe.body as BlockFunctionBody;
      var vd = fb.block.statements[0] as VariableDeclarationStatement;
      expect(vd.variables.type.type.toString(), 'A');
      // The initializer of "v1" is resolved.
      var v = vd.variables.variables[0];
      var vi = v.initializer as InstanceCreationExpression;
      expect(vi.constructorName.type.type.toString(), 'A');
      // Local: f2
      {
        var f2s = fb.block.statements[1] as FunctionDeclarationStatement;
        var f2 = f2s.functionDeclaration;
        // The return type of "f2" is resolved.
        expect(f2.returnType.type.toString(), 'A');
        // The type of the parameter "p2" is resolved.
        var f2e = f2.functionExpression;
        var p2 = f2e.parameters.parameters[0] as SimpleFormalParameter;
        expect(p2.type.type.toString(), 'A');
        // The type of "v2" is resolved.
        var f2b = f2e.body as BlockFunctionBody;
        var v2d = f2b.block.statements[0] as VariableDeclarationStatement;
        expect(v2d.variables.type.type.toString(), 'A');
      }
    }

    // Top-level: V
    {
      var vd = unit.declarations[2] as TopLevelVariableDeclaration;
      // The type is not resolved.
      expect(vd.variables.type.type, isNull);
      // The initializer is resolved.
      VariableDeclaration v = vd.variables.variables[0];
      var vi = v.initializer as InstanceCreationExpression;
      expect(vi.constructorName.type.type.toString(), 'A');
    }

    // Top-level: G
    {
      var g = unit.declarations[3] as FunctionDeclaration;
      // The return type is not resolved.
      expect(g.returnType.type, isNull);
      // The body is resolved.
      var gb = g.functionExpression.body as ExpressionFunctionBody;
      var ge = gb.expression as InstanceCreationExpression;
      expect(ge.constructorName.type.type.toString(), 'A');
    }
  }

  test_modeLocal_withContext_bad_methodBody() async {
    expect(() {
      _resolveTypeModeLocal(r'''
class C<T1> {
  A m<T2>() {
    T1 v1;
    T2 v2;
  }
}
''', (CompilationUnit u) {
        var c = u.declarations[0] as ClassDeclaration;
        var m = c.members[0] as MethodDeclaration;
        var mb = m.body as BlockFunctionBody;
        return mb;
      });
    }, throwsStateError);
  }

  test_modeLocal_withContext_bad_topLevelVariable_declaration() async {
    expect(() {
      _resolveTypeModeLocal(r'''
var v = new A();
''', (CompilationUnit u) {
        var tlv = u.declarations[0] as TopLevelVariableDeclaration;
        return tlv.variables.variables[0];
      });
    }, throwsStateError);
  }

  test_modeLocal_withContext_bad_topLevelVariable_initializer() async {
    expect(() {
      _resolveTypeModeLocal(r'''
var v = new A();
''', (CompilationUnit u) {
        var tlv = u.declarations[0] as TopLevelVariableDeclaration;
        return tlv.variables.variables[0].initializer;
      });
    }, throwsStateError);
  }

  test_modeLocal_withContext_class() async {
    ClassDeclaration c;
    _resolveTypeModeLocal(r'''
class C<T1> {
  A m<T2>() {
    T1 v1;
    T2 v2;
  }
}
''', (CompilationUnit u) {
      c = u.declarations[0] as ClassDeclaration;
      return c;
    });
    var m = c.members[0] as MethodDeclaration;

    // The return type of "m" is not resolved.
    expect(m.returnType.type, isNull);

    var mb = m.body as BlockFunctionBody;
    var ms = mb.block.statements;

    // The type of "v1" is resolved.
    {
      var vd = ms[0] as VariableDeclarationStatement;
      expect(vd.variables.type.type.toString(), 'T1');
    }

    // The type of "v2" is resolved.
    {
      var vd = ms[1] as VariableDeclarationStatement;
      expect(vd.variables.type.type.toString(), 'T2');
    }
  }

  test_modeLocal_withContext_inClass_constructor() async {
    ConstructorDeclaration cc;
    _resolveTypeModeLocal(r'''
class C<T> {
  C() {
    T v1;
  }
}
''', (CompilationUnit u) {
      var c = u.declarations[0] as ClassDeclaration;
      cc = c.members[0] as ConstructorDeclaration;
      return cc;
    });

    var ccb = cc.body as BlockFunctionBody;
    var ccs = ccb.block.statements;

    // The type of "v" is resolved.
    {
      var vd = ccs[0] as VariableDeclarationStatement;
      expect(vd.variables.type.type.toString(), 'T');
    }
  }

  test_modeLocal_withContext_inClass_method() async {
    MethodDeclaration m;
    _resolveTypeModeLocal(r'''
class C<T1> {
  A m<T2>() {
    T1 v1;
    T2 v2;
  }
}
''', (CompilationUnit u) {
      var c = u.declarations[0] as ClassDeclaration;
      m = c.members[0] as MethodDeclaration;
      return m;
    });

    // The return type of "m" is not resolved.
    expect(m.returnType.type, isNull);

    var mb = m.body as BlockFunctionBody;
    var ms = mb.block.statements;

    // The type of "v1" is resolved.
    {
      var vd = ms[0] as VariableDeclarationStatement;
      expect(vd.variables.type.type.toString(), 'T1');
    }

    // The type of "v2" is resolved.
    {
      var vd = ms[1] as VariableDeclarationStatement;
      expect(vd.variables.type.type.toString(), 'T2');
    }
  }

  test_modeLocal_withContext_topLevelFunction() async {
    FunctionDeclaration f;
    _resolveTypeModeLocal(r'''
A m<T>() {
  T v;
}
''', (CompilationUnit u) {
      f = u.declarations[0] as FunctionDeclaration;
      return f;
    });

    // The return type of "f" is not resolved.
    expect(f.returnType.type, isNull);

    var fb = f.functionExpression.body as BlockFunctionBody;
    var fs = fb.block.statements;

    // The type of "v" is resolved.
    var vd = fs[0] as VariableDeclarationStatement;
    expect(vd.variables.type.type.toString(), 'T');
  }

  test_modeLocal_withContext_topLevelVariable() async {
    TopLevelVariableDeclaration v;
    _resolveTypeModeLocal(r'''
A v = new A();
''', (CompilationUnit u) {
      v = u.declarations[0] as TopLevelVariableDeclaration;
      return v;
    });

    // The type of "v" is not resolved.
    expect(v.variables.type.type, isNull);

    // The type of "v" initializer is resolved.
    var vi = v.variables.variables[0].initializer as InstanceCreationExpression;
    expect(vi.constructorName.type.type.toString(), 'A');
  }

  test_visitCatchClause_exception() async {
    // catch (e)
    CatchClause clause = AstTestFactory.catchClause("e");
    SimpleIdentifier exceptionParameter = clause.exceptionParameter;
    exceptionParameter.staticElement =
        new LocalVariableElementImpl.forNode(exceptionParameter);
    _resolveCatchClause(clause, _typeProvider.dynamicType, null);
    _listener.assertNoErrors();
  }

  test_visitCatchClause_exception_stackTrace() async {
    // catch (e, s)
    CatchClause clause = AstTestFactory.catchClause2("e", "s");
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

  test_visitCatchClause_on_exception() async {
    // on E catch (e)
    ClassElement exceptionElement = ElementFactory.classElement2("E");
    TypeName exceptionType = AstTestFactory.typeName(exceptionElement);
    CatchClause clause = AstTestFactory.catchClause4(exceptionType, "e");
    SimpleIdentifier exceptionParameter = clause.exceptionParameter;
    exceptionParameter.staticElement =
        new LocalVariableElementImpl.forNode(exceptionParameter);
    _resolveCatchClause(
        clause, exceptionElement.type, null, [exceptionElement]);
    _listener.assertNoErrors();
  }

  test_visitCatchClause_on_exception_stackTrace() async {
    // on E catch (e, s)
    ClassElement exceptionElement = ElementFactory.classElement2("E");
    TypeName exceptionType = AstTestFactory.typeName(exceptionElement);
    (exceptionType.name as SimpleIdentifier).staticElement = exceptionElement;
    CatchClause clause = AstTestFactory.catchClause5(exceptionType, "e", "s");
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

  test_visitClassDeclaration() async {
    // class A extends B with C implements D {}
    // class B {}
    // class C {}
    // class D {}
    setUp(shouldSetElementSupertypes: true);
    ClassElement elementA = ElementFactory.classElement2("A");
    ClassElement elementB = ElementFactory.classElement2("B");
    ClassElement elementC = ElementFactory.classElement2("C");
    ClassElement elementD = ElementFactory.classElement2("D");
    ExtendsClause extendsClause =
        AstTestFactory.extendsClause(AstTestFactory.typeName(elementB));
    WithClause withClause =
        AstTestFactory.withClause([AstTestFactory.typeName(elementC)]);
    ImplementsClause implementsClause =
        AstTestFactory.implementsClause([AstTestFactory.typeName(elementD)]);
    ClassDeclaration declaration = AstTestFactory.classDeclaration(
        null, "A", null, extendsClause, withClause, implementsClause);
    declaration.name.staticElement = elementA;
    _resolveNode(declaration, [elementA, elementB, elementC, elementD]);
    expect(elementA.supertype, elementB.type);
    List<InterfaceType> mixins = elementA.mixins;
    expect(mixins, hasLength(1));
    expect(mixins[0], elementC.type);
    List<InterfaceType> interfaces = elementA.interfaces;
    expect(interfaces, hasLength(1));
    expect(interfaces[0], elementD.type);
    _listener.assertNoErrors();
  }

  test_visitClassDeclaration_instanceMemberCollidesWithClass() async {
    // class A {}
    // class B extends A {
    //   void A() {}
    // }
    setUp(shouldSetElementSupertypes: true);
    ClassElementImpl elementA = ElementFactory.classElement2("A");
    ClassElementImpl elementB = ElementFactory.classElement2("B");
    elementB.methods = <MethodElement>[
      ElementFactory.methodElement("A", VoidTypeImpl.instance)
    ];
    ExtendsClause extendsClause =
        AstTestFactory.extendsClause(AstTestFactory.typeName(elementA));
    ClassDeclaration declaration = AstTestFactory.classDeclaration(
        null, "B", null, extendsClause, null, null);
    declaration.name.staticElement = elementB;
    _resolveNode(declaration, [elementA, elementB]);
    expect(elementB.supertype, elementA.type);
    _listener.assertNoErrors();
  }

  test_visitFieldFormalParameter_functionType() async {
    InterfaceType intType = _typeProvider.intType;
    TypeName intTypeName = AstTestFactory.typeName4('int');

    String aName = 'a';
    SimpleFormalParameterImpl aNode =
        AstTestFactory.simpleFormalParameter3(aName);
    aNode.declaredElement = aNode.identifier.staticElement =
        ElementFactory.requiredParameter(aName);

    String pName = 'p';
    FormalParameter pNode = AstTestFactory.fieldFormalParameter(
        null, intTypeName, pName, AstTestFactory.formalParameterList([aNode]));
    var pElement = ElementFactory.requiredParameter(pName);
    pNode.identifier.staticElement = pElement;

    FunctionType pType = new FunctionTypeImpl(
        new GenericFunctionTypeElementImpl.forOffset(-1)
          ..parameters = [aNode.declaredElement]);
    pElement.type = pType;

    _resolveFormalParameter(pNode, [intType.element]);
    expect(pType.returnType, intType);
    expect(pType.parameters, hasLength(1));
    _listener.assertNoErrors();
  }

  test_visitFieldFormalParameter_noType() async {
    String parameterName = "p";
    FormalParameter node =
        AstTestFactory.fieldFormalParameter(Keyword.VAR, null, parameterName);
    node.identifier.staticElement =
        ElementFactory.requiredParameter(parameterName);
    expect(_resolveFormalParameter(node), same(_typeProvider.dynamicType));
    _listener.assertNoErrors();
  }

  test_visitFieldFormalParameter_type() async {
    InterfaceType intType = _typeProvider.intType;
    TypeName intTypeName = AstTestFactory.typeName4("int");
    String parameterName = "p";
    FormalParameter node =
        AstTestFactory.fieldFormalParameter(null, intTypeName, parameterName);
    node.identifier.staticElement =
        ElementFactory.requiredParameter(parameterName);
    expect(_resolveFormalParameter(node, [intType.element]), intType);
    _listener.assertNoErrors();
  }

  test_visitFunctionDeclaration() async {
    // R f(P p) {}
    // class R {}
    // class P {}
    ClassElement elementR = ElementFactory.classElement2('R');
    ClassElement elementP = ElementFactory.classElement2('P');
    FunctionElement elementF = ElementFactory.functionElement('f');
    FunctionDeclaration declaration = AstTestFactory.functionDeclaration(
        AstTestFactory.typeName4('R'),
        null,
        'f',
        AstTestFactory.functionExpression2(
            AstTestFactory.formalParameterList([
              AstTestFactory.simpleFormalParameter4(
                  AstTestFactory.typeName4('P'), 'p')
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

  test_visitFunctionDeclaration_typeParameter() async {
    // E f<E>(E e) {}
    TypeParameterElement elementE = ElementFactory.typeParameterElement('E');
    FunctionElementImpl elementF = ElementFactory.functionElement('f');
    elementF.typeParameters = <TypeParameterElement>[elementE];
    FunctionDeclaration declaration = AstTestFactory.functionDeclaration(
        AstTestFactory.typeName4('E'),
        null,
        'f',
        AstTestFactory.functionExpression2(
            AstTestFactory.formalParameterList([
              AstTestFactory.simpleFormalParameter4(
                  AstTestFactory.typeName4('E'), 'e')
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

  test_visitFunctionTypedFormalParameter() async {
    // R f(R g(P p)) {}
    // class R {}
    // class P {}
    ClassElement elementR = ElementFactory.classElement2('R');
    ClassElement elementP = ElementFactory.classElement2('P');

    SimpleFormalParameter pNode = AstTestFactory.simpleFormalParameter4(
        AstTestFactory.typeName4('P'), 'p');
    ParameterElementImpl pElement = ElementFactory.requiredParameter('p');
    pNode.identifier.staticElement = pElement;

    FunctionTypedFormalParameter gNode =
        AstTestFactory.functionTypedFormalParameter(
            AstTestFactory.typeName4('R'), 'g', [pNode]);
    ParameterElementImpl gElement = ElementFactory.requiredParameter('g');
    gNode.identifier.staticElement = gElement;

    FunctionTypeImpl gType = new FunctionTypeImpl(
        new GenericFunctionTypeElementImpl.forOffset(-1)
          ..parameters = [pElement]);
    gElement.type = gType;

    FunctionDeclaration fNode = AstTestFactory.functionDeclaration(
        AstTestFactory.typeName4('R'),
        null,
        'f',
        AstTestFactory.functionExpression2(
            AstTestFactory.formalParameterList([gNode]), null));
    fNode.name.staticElement = ElementFactory.functionElement('f');

    _resolveNode(fNode, [elementR, elementP]);

    expect(fNode.returnType.type, elementR.type);
    expect(gType.returnType, elementR.type);
    expect(gNode.returnType.type, elementR.type);
    expect(pNode.type.type, elementP.type);

    _listener.assertNoErrors();
  }

  test_visitFunctionTypedFormalParameter_typeParameter() async {
    // R f(R g<E>(E e)) {}
    // class R {}
    ClassElement elementR = ElementFactory.classElement2('R');
    TypeParameterElement elementE = ElementFactory.typeParameterElement('E');

    SimpleFormalParameterImpl eNode = AstTestFactory.simpleFormalParameter4(
        AstTestFactory.typeName4('E'), 'e');
    eNode.declaredElement = ElementFactory.requiredParameter('e');

    FunctionTypedFormalParameter gNode =
        AstTestFactory.functionTypedFormalParameter(
            AstTestFactory.typeName4('R'), 'g', [eNode]);
    ParameterElementImpl gElement = ElementFactory.requiredParameter('g');
    gNode.identifier.staticElement = gElement;

    FunctionTypeImpl gType =
        new FunctionTypeImpl(new GenericFunctionTypeElementImpl.forOffset(-1)
          ..typeParameters = [elementE]
          ..parameters = [eNode.declaredElement]);
    gElement.type = gType;

    FunctionDeclaration fNode = AstTestFactory.functionDeclaration(
        AstTestFactory.typeName4('R'),
        null,
        'f',
        AstTestFactory.functionExpression2(
            AstTestFactory.formalParameterList([gNode]), null));
    fNode.name.staticElement = ElementFactory.functionElement('f');

    _resolveNode(fNode, [elementR]);

    expect(fNode.returnType.type, elementR.type);
    expect(gType.returnType, elementR.type);
    expect(gNode.returnType.type, elementR.type);
    expect(eNode.type.type, elementE.type);

    _listener.assertNoErrors();
  }

  test_visitMethodDeclaration() async {
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
    MethodDeclaration declaration = AstTestFactory.methodDeclaration(
        null,
        AstTestFactory.typeName4('R'),
        null,
        null,
        AstTestFactory.identifier3('m'),
        AstTestFactory.formalParameterList([
          AstTestFactory.simpleFormalParameter4(
              AstTestFactory.typeName4('P'), 'p')
        ]));
    declaration.name.staticElement = elementM;
    _resolveNode(declaration, [elementA, elementR, elementP]);
    expect(declaration.returnType.type, elementR.type);
    SimpleFormalParameter parameter = declaration.parameters.parameters[0];
    expect(parameter.type.type, elementP.type);
    _listener.assertNoErrors();
  }

  test_visitMethodDeclaration_typeParameter() async {
    // class A {
    //   E m<E>(E e) {}
    // }
    ClassElementImpl elementA = ElementFactory.classElement2('A');
    TypeParameterElement elementE = ElementFactory.typeParameterElement('E');
    MethodElementImpl elementM = ElementFactory.methodElement('m', null);
    elementM.typeParameters = <TypeParameterElement>[elementE];
    elementA.methods = <MethodElement>[elementM];
    MethodDeclaration declaration = AstTestFactory.methodDeclaration(
        null,
        AstTestFactory.typeName4('E'),
        null,
        null,
        AstTestFactory.identifier3('m'),
        AstTestFactory.formalParameterList([
          AstTestFactory.simpleFormalParameter4(
              AstTestFactory.typeName4('E'), 'e')
        ]));
    declaration.name.staticElement = elementM;
    _resolveNode(declaration, [elementA]);
    expect(declaration.returnType.type, elementE.type);
    SimpleFormalParameter parameter = declaration.parameters.parameters[0];
    expect(parameter.type.type, elementE.type);
    _listener.assertNoErrors();
  }

  test_visitSimpleFormalParameter_noType() async {
    // p
    SimpleFormalParameterImpl node = AstTestFactory.simpleFormalParameter3("p");
    node.declaredElement = node.identifier.staticElement =
        new ParameterElementImpl.forNode(AstTestFactory.identifier3("p"));
    expect(_resolveFormalParameter(node), same(_typeProvider.dynamicType));
    _listener.assertNoErrors();
  }

  test_visitSimpleFormalParameter_type() async {
    // int p
    InterfaceType intType = _typeProvider.intType;
    ClassElement intElement = intType.element;
    SimpleFormalParameterImpl node = AstTestFactory.simpleFormalParameter4(
        AstTestFactory.typeName(intElement), "p");
    SimpleIdentifier identifier = node.identifier;
    ParameterElementImpl element = new ParameterElementImpl.forNode(identifier);
    node.declaredElement = identifier.staticElement = element;
    expect(_resolveFormalParameter(node, [intElement]), intType);
    _listener.assertNoErrors();
  }

  test_visitTypeName_noParameters_noArguments() async {
    ClassElement classA = ElementFactory.classElement2("A");
    TypeName typeName = AstTestFactory.typeName(classA);
    typeName.type = null;
    _resolveNode(typeName, [classA]);
    expect(typeName.type, classA.type);
    _listener.assertNoErrors();
  }

  test_visitTypeName_noParameters_noArguments_undefined() async {
    SimpleIdentifier id = AstTestFactory.identifier3("unknown")
      ..staticElement = new _StaleElement();
    TypeName typeName = astFactory.typeName(id, null);
    _resolveNode(typeName, []);
    expect(typeName.type, UndefinedTypeImpl.instance);
    expect(typeName.name.staticElement, null);
    _listener.assertErrorsWithCodes([StaticWarningCode.UNDEFINED_CLASS]);
  }

  test_visitTypeName_parameters_arguments() async {
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    ClassElement classB = ElementFactory.classElement2("B");
    TypeName typeName =
        AstTestFactory.typeName(classA, [AstTestFactory.typeName(classB)]);
    typeName.type = null;
    _resolveNode(typeName, [classA, classB]);
    InterfaceType resultType = typeName.type as InterfaceType;
    expect(resultType.element, same(classA));
    List<DartType> resultArguments = resultType.typeArguments;
    expect(resultArguments, hasLength(1));
    expect(resultArguments[0], classB.type);
    _listener.assertNoErrors();
  }

  test_visitTypeName_parameters_noArguments() async {
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    TypeName typeName = AstTestFactory.typeName(classA);
    typeName.type = null;
    _resolveNode(typeName, [classA]);
    InterfaceType resultType = typeName.type as InterfaceType;
    expect(resultType.element, same(classA));
    List<DartType> resultArguments = resultType.typeArguments;
    expect(resultArguments, hasLength(1));
    expect(resultArguments[0], same(DynamicTypeImpl.instance));
    _listener.assertNoErrors();
  }

  test_visitTypeName_prefixed_noParameters_noArguments_undefined() async {
    SimpleIdentifier prefix = AstTestFactory.identifier3("unknownPrefix")
      ..staticElement = new _StaleElement();
    SimpleIdentifier suffix = AstTestFactory.identifier3("unknownSuffix")
      ..staticElement = new _StaleElement();
    TypeName typeName =
        astFactory.typeName(AstTestFactory.identifier(prefix, suffix), null);
    _resolveNode(typeName, []);
    expect(typeName.type, UndefinedTypeImpl.instance);
    expect(prefix.staticElement, null);
    expect(suffix.staticElement, null);
    _listener.assertErrorsWithCodes([StaticWarningCode.UNDEFINED_CLASS]);
  }

  test_visitTypeName_void() async {
    ClassElement classA = ElementFactory.classElement2("A");
    TypeName typeName = AstTestFactory.typeName4("void");
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
      expect(exceptionParameter.staticType, exceptionType);
    }
    SimpleIdentifier stackTraceParameter = node.stackTraceParameter;
    if (stackTraceParameter != null) {
      expect(stackTraceParameter.staticType, stackTraceType);
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

  /**
   * Parse the given [code], build elements and resolve in the
   * [TypeResolverMode.local] mode. The [code] is allowed to use only the type
   * named `A`.
   */
  void _resolveTypeModeLocal(
      String code, AstNode getNodeToResolve(CompilationUnit unit)) {
    CompilationUnit unit = parseCompilationUnit2(code);
    var unitElement = new CompilationUnitElementImpl();

    // Build API elements.
    {
      var holder = new ElementHolder();
      unit.accept(new ElementBuilder(holder, unitElement));
    }

    // Prepare for resolution.
    LibraryScope libraryScope;
    TypeResolverVisitor visitor;
    {
      InternalAnalysisContext context = AnalysisContextFactory.contextWithCore(
          resourceProvider: resourceProvider);
      var source = getFile('/test.dart').createSource();
      var libraryElement = new LibraryElementImpl.forNode(context, null, null)
        ..definingCompilationUnit = unitElement;
      libraryScope = new LibraryScope(libraryElement);
      visitor = new TypeResolverVisitor(
          libraryElement, source, _typeProvider, _listener,
          nameScope: libraryScope, mode: TypeResolverMode.local);
    }

    // Define top-level types.
    ClassElementImpl A = ElementFactory.classElement2('A');
    libraryScope.define(A);

    // Perform resolution.
    AstNode nodeToResolve = getNodeToResolve(unit);
    nodeToResolve.accept(visitor);
  }
}

class _RootScope extends Scope {
  @override
  Element internalLookup(Identifier identifier, String name,
          LibraryElement referencingLibrary) =>
      null;
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
  T accept<T>(_) => throw "_StaleElement shouldn't be visited";
}
