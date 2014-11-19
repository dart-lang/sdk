// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.incremental_resolver_test;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/incremental_resolver.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import 'parser_test.dart';
import 'resolver_test.dart';
import 'test_support.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(DeclarationMatcherTest);
  runReflectiveTests(IncrementalResolverTest);
  runReflectiveTests(ScopeBuilderTest);
}


class DeclarationMatcherTest extends ResolverTestCase {
  void fail_test_methodDeclarationMatches_false_localVariable() {
    // TODO(scheglov) as I understand DeclarationMatcher, we care only
    // about externally visible model changes. So, because we analyze (at least
    // right now) incremental changes on method level, local variable can be
    // ignored.
    _assertMethodMatches(false, r'''
class C {
  int m(int p) {
    return p + p;
  }
}''', r'''
class C {
  int m(int p) {
    int product = p * p;
    return product + product;
  }
}''');
  }

  void test_compilationUnitMatches_true_different() {
    _assertCompilationUnitMatches(true, r'''
class C {
  int m(int p) {
    return p + p;
  }
}''', r'''
class C {
  int m(int p) {
    return (p * p) + (p * p);
  }
}''');
  }

  void test_compilationUnitMatches_true_same() {
    String content = r'''
class C {
  int m(int p) {
    return p + p;
  }
}''';
    _assertCompilationUnitMatches(true, content, content);
  }

  void test_false_topLevelVariable_list_add() {
    _assertCompilationUnitMatches(false, r'''
const int A = 1;
const int C = 3;
''', r'''
const int A = 1;
const int B = 2;
const int C = 3;
''');
  }

  void test_false_topLevelVariable_list_remove() {
    _assertCompilationUnitMatches(false, r'''
const int A = 1;
const int B = 2;
const int C = 3;
''', r'''
const int A = 1;
const int C = 3;
''');
  }

  void test_false_topLevelVariable_modifier_isConst() {
    _assertCompilationUnitMatches(false, r'''
final int A = 1;
''', r'''
const int A = 1;
''');
  }

  void test_false_topLevelVariable_modifier_isFinal() {
    _assertCompilationUnitMatches(false, r'''
int A = 1;
''', r'''
final int A = 1;
''');
  }

  void test_false_topLevelVariable_modifier_wasConst() {
    _assertCompilationUnitMatches(false, r'''
const int A = 1;
''', r'''
final int A = 1;
''');
  }

  void test_false_topLevelVariable_modifier_wasFinal() {
    _assertCompilationUnitMatches(false, r'''
final int A = 1;
''', r'''
int A = 1;
''');
  }

  void test_false_topLevelVariable_type_different() {
    _assertCompilationUnitMatches(false, r'''
int A;
''', r'''
String A;
''');
  }

  void test_false_topLevelVariable_type_differentArgs() {
    _assertCompilationUnitMatches(false, r'''
List<int> A;
''', r'''
List<String> A;
''');
  }

  void test_methodDeclarationMatches_false_parameter() {
    _assertMethodMatches(false, r'''
class C {
  int m(int p) {
    return p + p;
  }
}''', r'''
class C {
  int m(int p, int q) {
    return (p * q) + (q * p);
  }
}''');
  }

  void test_methodDeclarationMatches_true_different() {
    _assertMethodMatches(true, r'''
class C {
  int m(int p) {
    return p + p;
  }
}''', r'''
class C {
  int m(int p) {
    return (p * p) + (p * p);
  }
}''');
  }

  void test_methodDeclarationMatches_true_same() {
    String content = r'''
class C {
  int m(int p) {
    return p + p;
  }
}''';
    _assertMethodMatches(true, content, content);
  }

  void test_true_topLevelVariable_list_reorder() {
    _assertCompilationUnitMatches(true, r'''
const int A = 1;
const int B = 2;
const int C = 3;
''', r'''
const int C = 3;
const int A = 1;
const int B = 2;
''');
  }

  void test_true_topLevelVariable_list_same() {
    _assertCompilationUnitMatches(true, r'''
const int A = 1;
const int B = 2;
const int C = 3;
''', r'''
const int A = 1;
const int B = 2;
const int C = 3;
''');
  }

  void test_true_topLevelVariable_type_sameArgs() {
    _assertCompilationUnitMatches(true, r'''
Map<int, String> A;
''', r'''
Map<int, String> A;
''');
  }

  void _assertCompilationUnitMatches(bool expectMatch, String oldContent,
      String newContent) {
    Source source = addSource(oldContent);
    LibraryElement library = resolve(source);
    CompilationUnit oldUnit = resolveCompilationUnit(source, library);
    CompilationUnit newUnit = ParserTestCase.parseCompilationUnit(newContent);
    DeclarationMatcher matcher = new DeclarationMatcher();
    expect(matcher.matches(newUnit, oldUnit.element), expectMatch);
  }

  void _assertMethodMatches(bool expectMatch, String oldContent,
      String newContent) {
    Source source = addSource(oldContent);
    LibraryElement library = resolve(source);
    CompilationUnit oldUnit = resolveCompilationUnit(source, library);
    MethodElement element = _getFirstMethod(oldUnit).element as MethodElement;
    AnalysisContext context = analysisContext;
    context.setContents(source, newContent);
    CompilationUnit newUnit = context.parseCompilationUnit(source);
    MethodDeclaration newMethod = _getFirstMethod(newUnit);
    DeclarationMatcher matcher = new DeclarationMatcher();
    expect(matcher.matches(newMethod, element), expectMatch);
  }

  MethodDeclaration _getFirstMethod(CompilationUnit unit) {
    ClassDeclaration classNode = unit.declarations[0] as ClassDeclaration;
    return classNode.members[0] as MethodDeclaration;
  }
}

class IncrementalResolverTest extends ResolverTestCase {
  void test_resolve() {
    MethodDeclaration method = _resolveMethod(r'''
class C {
  int m(int a) {
    return a + a;
  }
}''');
    BlockFunctionBody body = method.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[0] as ReturnStatement;
    BinaryExpression expression = statement.expression as BinaryExpression;
    SimpleIdentifier left = expression.leftOperand as SimpleIdentifier;
    Element leftElement = left.staticElement;
    SimpleIdentifier right = expression.rightOperand as SimpleIdentifier;
    Element rightElement = right.staticElement;
    expect(leftElement, isNotNull);
    expect(rightElement, same(leftElement));
  }

  MethodDeclaration _resolveMethod(String content) {
    Source source = addSource(content);
    LibraryElement library = resolve(source);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classNode = unit.declarations[0] as ClassDeclaration;
    MethodDeclaration method = classNode.members[0] as MethodDeclaration;
    method.body.accept(new ResolutionEraser());
    GatheringErrorListener errorListener = new GatheringErrorListener();
    IncrementalResolver resolver =
        new IncrementalResolver(library, source, typeProvider, errorListener);
    resolver.resolve(method.body);
    return method;
  }
}

class ScopeBuilderTest extends EngineTestCase {
  void test_scopeFor_ClassDeclaration() {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scope scope =
        ScopeBuilder.scopeFor(_createResolvedClassDeclaration(), listener);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryScope,
        LibraryScope,
        scope);
  }

  void test_scopeFor_ClassTypeAlias() {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scope scope =
        ScopeBuilder.scopeFor(_createResolvedClassTypeAlias(), listener);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryScope,
        LibraryScope,
        scope);
  }

  void test_scopeFor_CompilationUnit() {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scope scope =
        ScopeBuilder.scopeFor(_createResolvedCompilationUnit(), listener);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryScope,
        LibraryScope,
        scope);
  }

  void test_scopeFor_ConstructorDeclaration() {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scope scope =
        ScopeBuilder.scopeFor(_createResolvedConstructorDeclaration(), listener);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassScope,
        ClassScope,
        scope);
  }

  void test_scopeFor_ConstructorDeclaration_parameters() {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scope scope = ScopeBuilder.scopeFor(
        _createResolvedConstructorDeclaration().parameters,
        listener);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionScope,
        FunctionScope,
        scope);
  }

  void test_scopeFor_FunctionDeclaration() {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scope scope =
        ScopeBuilder.scopeFor(_createResolvedFunctionDeclaration(), listener);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryScope,
        LibraryScope,
        scope);
  }

  void test_scopeFor_FunctionDeclaration_parameters() {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scope scope = ScopeBuilder.scopeFor(
        _createResolvedFunctionDeclaration().functionExpression.parameters,
        listener);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionScope,
        FunctionScope,
        scope);
  }

  void test_scopeFor_FunctionTypeAlias() {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scope scope =
        ScopeBuilder.scopeFor(_createResolvedFunctionTypeAlias(), listener);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryScope,
        LibraryScope,
        scope);
  }

  void test_scopeFor_FunctionTypeAlias_parameters() {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scope scope =
        ScopeBuilder.scopeFor(_createResolvedFunctionTypeAlias().parameters, listener);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionTypeScope,
        FunctionTypeScope,
        scope);
  }

  void test_scopeFor_MethodDeclaration() {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scope scope =
        ScopeBuilder.scopeFor(_createResolvedMethodDeclaration(), listener);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassScope,
        ClassScope,
        scope);
  }

  void test_scopeFor_MethodDeclaration_body() {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scope scope =
        ScopeBuilder.scopeFor(_createResolvedMethodDeclaration().body, listener);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionScope,
        FunctionScope,
        scope);
  }

  void test_scopeFor_notInCompilationUnit() {
    GatheringErrorListener listener = new GatheringErrorListener();
    try {
      ScopeBuilder.scopeFor(AstFactory.identifier3("x"), listener);
      fail("Expected AnalysisException");
    } on AnalysisException catch (exception) {
      // Expected
    }
  }

  void test_scopeFor_null() {
    GatheringErrorListener listener = new GatheringErrorListener();
    try {
      ScopeBuilder.scopeFor(null, listener);
      fail("Expected AnalysisException");
    } on AnalysisException catch (exception) {
      // Expected
    }
  }

  void test_scopeFor_unresolved() {
    GatheringErrorListener listener = new GatheringErrorListener();
    try {
      ScopeBuilder.scopeFor(AstFactory.compilationUnit(), listener);
      fail("Expected AnalysisException");
    } on AnalysisException catch (exception) {
      // Expected
    }
  }

  ClassDeclaration _createResolvedClassDeclaration() {
    CompilationUnit unit = _createResolvedCompilationUnit();
    String className = "C";
    ClassDeclaration classNode = AstFactory.classDeclaration(
        null,
        className,
        AstFactory.typeParameterList(),
        null,
        null,
        null);
    unit.declarations.add(classNode);
    ClassElement classElement = ElementFactory.classElement2(className);
    classNode.name.staticElement = classElement;
    (unit.element as CompilationUnitElementImpl).types =
        <ClassElement>[classElement];
    return classNode;
  }

  ClassTypeAlias _createResolvedClassTypeAlias() {
    CompilationUnit unit = _createResolvedCompilationUnit();
    String className = "C";
    ClassTypeAlias classNode = AstFactory.classTypeAlias(
        className,
        AstFactory.typeParameterList(),
        null,
        null,
        null,
        null);
    unit.declarations.add(classNode);
    ClassElement classElement = ElementFactory.classElement2(className);
    classNode.name.staticElement = classElement;
    (unit.element as CompilationUnitElementImpl).types =
        <ClassElement>[classElement];
    return classNode;
  }

  CompilationUnit _createResolvedCompilationUnit() {
    CompilationUnit unit = AstFactory.compilationUnit();
    LibraryElementImpl library =
        ElementFactory.library(AnalysisContextFactory.contextWithCore(), "lib");
    unit.element = library.definingCompilationUnit;
    return unit;
  }

  ConstructorDeclaration _createResolvedConstructorDeclaration() {
    ClassDeclaration classNode = _createResolvedClassDeclaration();
    String constructorName = "f";
    ConstructorDeclaration constructorNode = AstFactory.constructorDeclaration(
        AstFactory.identifier3(constructorName),
        null,
        AstFactory.formalParameterList(),
        null);
    classNode.members.add(constructorNode);
    ConstructorElement constructorElement =
        ElementFactory.constructorElement2(classNode.element, null);
    constructorNode.element = constructorElement;
    (classNode.element as ClassElementImpl).constructors =
        <ConstructorElement>[constructorElement];
    return constructorNode;
  }

  FunctionDeclaration _createResolvedFunctionDeclaration() {
    CompilationUnit unit = _createResolvedCompilationUnit();
    String functionName = "f";
    FunctionDeclaration functionNode = AstFactory.functionDeclaration(
        null,
        null,
        functionName,
        AstFactory.functionExpression());
    unit.declarations.add(functionNode);
    FunctionElement functionElement =
        ElementFactory.functionElement(functionName);
    functionNode.name.staticElement = functionElement;
    (unit.element as CompilationUnitElementImpl).functions =
        <FunctionElement>[functionElement];
    return functionNode;
  }

  FunctionTypeAlias _createResolvedFunctionTypeAlias() {
    CompilationUnit unit = _createResolvedCompilationUnit();
    FunctionTypeAlias aliasNode = AstFactory.typeAlias(
        AstFactory.typeName4("A"),
        "F",
        AstFactory.typeParameterList(),
        AstFactory.formalParameterList());
    unit.declarations.add(aliasNode);
    SimpleIdentifier aliasName = aliasNode.name;
    FunctionTypeAliasElement aliasElement =
        new FunctionTypeAliasElementImpl.forNode(aliasName);
    aliasName.staticElement = aliasElement;
    (unit.element as CompilationUnitElementImpl).typeAliases =
        <FunctionTypeAliasElement>[aliasElement];
    return aliasNode;
  }

  MethodDeclaration _createResolvedMethodDeclaration() {
    ClassDeclaration classNode = _createResolvedClassDeclaration();
    String methodName = "f";
    MethodDeclaration methodNode = AstFactory.methodDeclaration(
        null,
        null,
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList());
    classNode.members.add(methodNode);
    MethodElement methodElement =
        ElementFactory.methodElement(methodName, null);
    methodNode.name.staticElement = methodElement;
    (classNode.element as ClassElementImpl).methods =
        <MethodElement>[methodElement];
    return methodNode;
  }
}
