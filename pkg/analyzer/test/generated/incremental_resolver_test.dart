// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.incremental_resolver_test;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/incremental_resolver.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart';
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

  void test_false_class_list_add() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B {}
''', r'''
class A {}
class B {}
class C {}
''');
  }

  void test_false_class_list_remove() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B {}
class C {}
''', r'''
class A {}
class B {}
''');
  }

  void test_false_constructor_parameters_list_add() {
    _assertCompilationUnitMatches(false, r'''
class A {
  A();
}
''', r'''
class A {
  A(int p);
}
''');
  }

  void test_false_constructor_parameters_list_remove() {
    _assertCompilationUnitMatches(false, r'''
class A {
  A(int p);
}
''', r'''
class A {
  A();
}
''');
  }

  void test_false_constructor_parameters_type_edit() {
    _assertCompilationUnitMatches(false, r'''
class A {
  A(int p);
}
''', r'''
class A {
  A(String p);
}
''');
  }

  void test_false_constructor_unnamed_add_hadParameters() {
    _assertCompilationUnitMatches(false, r'''
class A {
}
''', r'''
class A {
  A(int p) {}
}
''');
  }

  void test_false_constructor_unnamed_remove_hadParameters() {
    _assertCompilationUnitMatches(false, r'''
class A {
  A(int p) {}
}
''', r'''
class A {
}
''');
  }

  void test_false_extendsClause_add() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B {}
''', r'''
class A {}
class B extends A {}
''');
  }

  void test_false_extendsClause_different() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B {}
class C extends A {}
''', r'''
class A {}
class B {}
class C extends B {}
''');
  }

  void test_false_extendsClause_remove() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B extends A{}
''', r'''
class A {}
class B {}
''');
  }

  void test_false_field_list_add() {
    _assertCompilationUnitMatches(false, r'''
class T {
  int A = 1;
  int C = 3;
}
''', r'''
class T {
  int A = 1;
  int B = 2;
  int C = 3;
}
''');
  }

  void test_false_field_list_remove() {
    _assertCompilationUnitMatches(false, r'''
class T {
  int A = 1;
  int B = 2;
  int C = 3;
}
''', r'''
class T {
  int A = 1;
  int C = 3;
}
''');
  }

  void test_false_field_modifier_isConst() {
    _assertCompilationUnitMatches(false, r'''
class T {
  static final A = 1;
}
''', r'''
class T {
  static const A = 1;
}
''');
  }

  void test_false_field_modifier_isFinal() {
    _assertCompilationUnitMatches(false, r'''
class T {
  int A = 1;
}
''', r'''
class T {
  final int A = 1;
}
''');
  }

  void test_false_field_modifier_isStatic() {
    _assertCompilationUnitMatches(false, r'''
class T {
  int A = 1;
}
''', r'''
class T {
  static int A = 1;
}
''');
  }

  void test_false_field_modifier_wasConst() {
    _assertCompilationUnitMatches(false, r'''
class T {
  static const A = 1;
}
''', r'''
class T {
  static final A = 1;
}
''');
  }

  void test_false_field_modifier_wasFinal() {
    _assertCompilationUnitMatches(false, r'''
class T {
  final int A = 1;
}
''', r'''
class T {
  int A = 1;
}
''');
  }

  void test_false_field_modifier_wasStatic() {
    _assertCompilationUnitMatches(false, r'''
class T {
  static int A = 1;
}
''', r'''
class T {
  int A = 1;
}
''');
  }

  void test_false_field_type_differentArgs() {
    _assertCompilationUnitMatches(false, r'''
class T {
  List<int> A;
}
''', r'''
class T {
  List<String> A;
}
''');
  }

  void test_false_final_type_different() {
    _assertCompilationUnitMatches(false, r'''
class T {
  int A;
}
''', r'''
class T {
  String A;
}
''');
  }

  void test_false_implementsClause_add() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B {}
''', r'''
class A {}
class B implements A {}
''');
  }

  void test_false_implementsClause_remove() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B implements A {}
''', r'''
class A {}
class B {}
''');
  }

  void test_false_implementsClause_reorder() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B {}
class C implements A, B {}
''', r'''
class A {}
class B {}
class C implements B, A {}
''');
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

  void test_false_topLevelVariable_synthetic_wasGetter() {
    _assertCompilationUnitMatches(false, r'''
int get A => 1;
''', r'''
final int A = 1;
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

  void test_false_withClause_add() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B {}
''', r'''
class A {}
class B extends Object with A {}
''');
  }

  void test_false_withClause_remove() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B extends Object with A {}
''', r'''
class A {}
class B {}
''');
  }

  void test_false_withClause_reorder() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B {}
class C extends Object with A, B {}
''', r'''
class A {}
class B {}
class C extends Object with B, A {}
''');
  }

  void test_true_class_list_reorder() {
    _assertCompilationUnitMatches(true, r'''
class A {}
class B {}
class C {}
''', r'''
class C {}
class A {}
class B {}
''');
  }

  void test_true_class_list_same() {
    _assertCompilationUnitMatches(true, r'''
class A {}
class B {}
class C {}
''', r'''
class A {}
class B {}
class C {}
''');
  }

  void test_true_class_typeParameters_same() {
    _assertCompilationUnitMatches(true, r'''
class A<T> {}
''', r'''
class A<T> {}
''');
  }

  void test_true_constructor_named_same() {
    _assertCompilationUnitMatches(true, r'''
class A {
  A.name(int p);
}
''', r'''
class A {
  A.name(int p);
}
''');
  }

  void test_true_constructor_unnamed_add_noParameters() {
    _assertCompilationUnitMatches(true, r'''
class A {
}
''', r'''
class A {
  A() {}
}
''');
  }

  void test_true_constructor_unnamed_remove_noParameters() {
    _assertCompilationUnitMatches(true, r'''
class A {
  A() {}
}
''', r'''
class A {
}
''');
  }

  void test_true_constructor_unnamed_same() {
    _assertCompilationUnitMatches(true, r'''
class A {
  A(int p);
}
''', r'''
class A {
  A(int p);
}
''');
  }

  void test_true_executable_same_hasLabel() {
    _assertCompilationUnitMatches(true, r'''
main() {
  label: return 42;
}
''', r'''
main() {
  label: return 42;
}
''');
  }

  void test_true_executable_same_hasLocalVariable() {
    _assertCompilationUnitMatches(true, r'''
main() {
  int a = 42;
}
''', r'''
main() {
  int a = 42;
}
''');
  }

  void test_true_extendsClause_same() {
    _assertCompilationUnitMatches(true, r'''
class A {}
class B extends A {}
''', r'''
class A {}
class B extends A {}
''');
  }

  void test_true_field_list_reorder() {
    _assertCompilationUnitMatches(true, r'''
class T {
  int A = 1;
  int B = 2;
  int C = 3;
}
''', r'''
class T {
  int C = 3;
  int A = 1;
  int B = 2;
}
''');
  }

  void test_true_field_list_same() {
    _assertCompilationUnitMatches(true, r'''
class T {
  int A = 1;
  int B = 2;
  int C = 3;
}
''', r'''
class T {
  int A = 1;
  int B = 2;
  int C = 3;
}
''');
  }

  void test_true_implementsClause_same() {
    _assertCompilationUnitMatches(true, r'''
class A {}
class B implements A {}
''', r'''
class A {}
class B implements A {}
''');
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

  void test_true_withClause_same() {
    _assertCompilationUnitMatches(true, r'''
class A {}
class B extends Object with A {}
''', r'''
class A {}
class B extends Object with A {}
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
  Source source;
  String code;
  LibraryElement library;
  CompilationUnit unit;

  void fail_test_functionBody_addLocalVariable() {
    // TODO(scheglov) this test fails, because we don't create element models
    // for new local variables
    _resolveUnit(r'''
main(int a, int b) {
  return a + b;
}
''');
    _resolve(_editString('  return a + b;', r'''
  int res = a + b;
  return res;
'''), _isBlock);
  }

  void test_functionBody_body() {
    _resolveUnit(r'''
main(int a, int b) {
  return a + b;
}''');
    _resolve(_editString('+', '*'), _isFunctionBody);
  }

  void test_functionBody_statement() {
    _resolveUnit(r'''
main(int a, int b) {
  return a + b;
}''');
    _resolve(_editString('+', '*'), _isStatement);
  }

  void test_updateElementOffset() {
    _resolveUnit(r'''
class A {
  int am(String ap) {
    int av = 1;
    return av;
  }
}
main(int a, int b) {
  return a + b;
}
class B {
  int bm(String bp) {
    int bv = 1;
    return bv;
  }
}
''');
    _resolve(_editString('+', ' + '), _isStatement);
  }

  _Edit _editString(String search, String replacement, [int length]) {
    int offset = code.indexOf(search);
    expect(offset, isNot(-1));
    if (length == null) {
      length = search.length;
    }
    return new _Edit(offset, length, replacement);
  }

  /**
   * Applies [edit] to [code], find the [AstNode] specified by [predicate]
   * and incrementally resolves it.
   *
   * Then resolves the new code from scratch and validates that results of
   * the incremental resolution and non-incremental resolutions are the same.
   */
  void _resolve(_Edit edit, Predicate<AstNode> predicate) {
    int offset = edit.offset;
    // parse "newCode"
    String newCode =
        code.substring(0, offset) +
        edit.replacement +
        code.substring(offset + edit.length);
    CompilationUnit newUnit = _parseUnit(newCode);
    // replace the node
    AstNode oldNode = _findNodeAt(unit, offset, predicate);
    AstNode newNode = _findNodeAt(newUnit, offset, predicate);
    bool success = NodeReplacer.replace(oldNode, newNode);
    expect(success, isTrue);
    // do incremental resolution
    GatheringErrorListener errorListener = new GatheringErrorListener();
    IncrementalResolver resolver = new IncrementalResolver(
        errorListener,
        typeProvider,
        library,
        unit.element,
        source,
        edit.offset,
        edit.length,
        edit.replacement.length);
    resolver.resolve(newNode);
    // resolve "newCode" from scratch
    CompilationUnit fullNewUnit;
    {
      source = addSource(newCode);
      LibraryElement library = resolve(source);
      fullNewUnit = resolveCompilationUnit(source, library);
    }
    _SameResolutionValidator.assertSameResolution(unit, fullNewUnit);
  }

  void _resolveUnit(String code) {
    this.code = code;
    source = addSource(code);
    library = resolve(source);
    unit = resolveCompilationUnit(source, library);
  }

  static AstNode _findNodeAt(CompilationUnit oldUnit, int offset,
      Predicate<AstNode> predicate) {
    NodeLocator locator = new NodeLocator.con1(offset);
    AstNode node = locator.searchWithin(oldUnit);
    return node.getAncestor(predicate);
  }

  static bool _isBlock(AstNode node) => node is Block;

  static bool _isFunctionBody(AstNode node) => node is FunctionBody;

  static bool _isStatement(AstNode node) => node is Statement;

  static CompilationUnit _parseUnit(String code) {
    var errorListener = new BooleanErrorListener();
    var reader = new CharSequenceReader(code);
    var scanner = new Scanner(null, reader, errorListener);
    var token = scanner.tokenize();
    var parser = new Parser(null, errorListener);
    return parser.parseCompilationUnit(token);
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


class _Edit {
  final int offset;
  final int length;
  final String replacement;
  _Edit(this.offset, this.length, this.replacement);
}


class _SameResolutionValidator implements AstVisitor {
  AstNode other;

  _SameResolutionValidator(this.other);

  @override
  visitAdjacentStrings(AdjacentStrings node) {
  }

  @override
  visitAnnotation(Annotation node) {
    Annotation other = this.other;
    _visitNode(node.name, other.name);
    _visitNode(node.constructorName, other.constructorName);
    _visitNode(node.arguments, other.arguments);
    _verifyElement(node.element, other.element);
  }

  @override
  visitArgumentList(ArgumentList node) {
    ArgumentList other = this.other;
    _visitList(node.arguments, other.arguments);
  }

  @override
  visitAsExpression(AsExpression node) {
    AsExpression other = this.other;
    _visitExpression(node, other);
    _visitNode(node.expression, other.expression);
    _visitNode(node.type, other.type);
  }

  @override
  visitAssertStatement(AssertStatement node) {
    AssertStatement other = this.other;
    _visitNode(node.condition, other.condition);
  }

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    AssignmentExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitNode(node.leftHandSide, other.leftHandSide);
    _visitNode(node.rightHandSide, other.rightHandSide);
  }

  @override
  visitAwaitExpression(AwaitExpression node) {
    AwaitExpression other = this.other;
    _visitExpression(node, other);
    _visitNode(node.expression, other.expression);
  }

  @override
  visitBinaryExpression(BinaryExpression node) {
    BinaryExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitNode(node.leftOperand, other.leftOperand);
    _visitNode(node.rightOperand, other.rightOperand);
  }

  @override
  visitBlock(Block node) {
    Block other = this.other;
    _visitList(node.statements, other.statements);
  }

  @override
  visitBlockFunctionBody(BlockFunctionBody node) {
    BlockFunctionBody other = this.other;
    _visitNode(node.block, other.block);
  }

  @override
  visitBooleanLiteral(BooleanLiteral node) {
    BooleanLiteral other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitBreakStatement(BreakStatement node) {
    BreakStatement other = this.other;
    _visitNode(node.label, other.label);
  }

  @override
  visitCascadeExpression(CascadeExpression node) {
    CascadeExpression other = this.other;
    _visitExpression(node, other);
    _visitNode(node.target, other.target);
    _visitList(node.cascadeSections, other.cascadeSections);
  }

  @override
  visitCatchClause(CatchClause node) {
    CatchClause other = this.other;
    _visitNode(node.exceptionType, other.exceptionType);
    _visitNode(node.exceptionParameter, other.exceptionParameter);
    _visitNode(node.stackTraceParameter, other.stackTraceParameter);
    _visitNode(node.body, other.body);
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    ClassDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.name, other.name);
    _visitNode(node.typeParameters, other.typeParameters);
    _visitNode(node.extendsClause, other.extendsClause);
    _visitNode(node.implementsClause, other.implementsClause);
    _visitNode(node.withClause, other.withClause);
    _visitList(node.members, other.members);
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    ClassTypeAlias other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.name, other.name);
    _visitNode(node.typeParameters, other.typeParameters);
    _visitNode(node.superclass, other.superclass);
    _visitNode(node.withClause, other.withClause);
  }

  @override
  visitComment(Comment node) {
    Comment other = this.other;
    _visitList(node.references, other.references);
  }

  @override
  visitCommentReference(CommentReference node) {
    CommentReference other = this.other;
    _visitNode(node.identifier, other.identifier);
  }

  @override
  visitCompilationUnit(CompilationUnit node) {
    CompilationUnit other = this.other;
    _verifyElement(node.element, other.element);
    _visitList(node.directives, other.directives);
    _visitList(node.declarations, other.declarations);
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    ConditionalExpression other = this.other;
    _visitExpression(node, other);
    _visitNode(node.condition, other.condition);
    _visitNode(node.thenExpression, other.thenExpression);
    _visitNode(node.elseExpression, other.elseExpression);
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    ConstructorDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.returnType, other.returnType);
    _visitNode(node.name, other.name);
    _visitNode(node.parameters, other.parameters);
    _visitNode(node.redirectedConstructor, other.redirectedConstructor);
    _visitList(node.initializers, other.initializers);
  }

  @override
  visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    ConstructorFieldInitializer other = this.other;
    _visitNode(node.fieldName, other.fieldName);
    _visitNode(node.expression, other.expression);
  }

  @override
  visitConstructorName(ConstructorName node) {
    ConstructorName other = this.other;
    _verifyElement(node.staticElement, other.staticElement);
    _visitNode(node.type, other.type);
    _visitNode(node.name, other.name);
  }

  @override
  visitContinueStatement(ContinueStatement node) {
    ContinueStatement other = this.other;
    _visitNode(node.label, other.label);
  }

  @override
  visitDeclaredIdentifier(DeclaredIdentifier node) {
    DeclaredIdentifier other = this.other;
    _visitNode(node.type, other.type);
    _visitNode(node.identifier, other.identifier);
  }

  @override
  visitDefaultFormalParameter(DefaultFormalParameter node) {
    DefaultFormalParameter other = this.other;
    _visitNode(node.parameter, other.parameter);
    _visitNode(node.defaultValue, other.defaultValue);
  }

  @override
  visitDoStatement(DoStatement node) {
    DoStatement other = this.other;
    _visitNode(node.condition, other.condition);
    _visitNode(node.body, other.body);
  }

  @override
  visitDoubleLiteral(DoubleLiteral node) {
    DoubleLiteral other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitEmptyFunctionBody(EmptyFunctionBody node) {
  }

  @override
  visitEmptyStatement(EmptyStatement node) {
  }

  @override
  visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    EnumConstantDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.name, other.name);
  }

  @override
  visitEnumDeclaration(EnumDeclaration node) {
    EnumDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.name, other.name);
    _visitList(node.constants, other.constants);
  }

  @override
  visitExportDirective(ExportDirective node) {
    ExportDirective other = this.other;
    _visitDirective(node, other);
  }

  @override
  visitExpressionFunctionBody(ExpressionFunctionBody node) {
    ExpressionFunctionBody other = this.other;
    _visitNode(node.expression, other.expression);
  }

  @override
  visitExpressionStatement(ExpressionStatement node) {
    ExpressionStatement other = this.other;
    _visitNode(node.expression, other.expression);
  }

  @override
  visitExtendsClause(ExtendsClause node) {
    ExtendsClause other = this.other;
    _visitNode(node.superclass, other.superclass);
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    FieldDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.fields, other.fields);
  }

  @override
  visitFieldFormalParameter(FieldFormalParameter node) {
    FieldFormalParameter other = this.other;
    _visitNormalFormalParameter(node, other);
    _visitNode(node.type, other.type);
    _visitNode(node.parameters, other.parameters);
  }

  @override
  visitForEachStatement(ForEachStatement node) {
    ForEachStatement other = this.other;
    _visitNode(node.identifier, other.identifier);
    _visitNode(node.loopVariable, other.loopVariable);
    _visitNode(node.iterable, other.iterable);
  }

  @override
  visitFormalParameterList(FormalParameterList node) {
    FormalParameterList other = this.other;
    _visitList(node.parameters, other.parameters);
  }

  @override
  visitForStatement(ForStatement node) {
    ForStatement other = this.other;
    _visitNode(node.variables, other.variables);
    _visitNode(node.initialization, other.initialization);
    _visitNode(node.condition, other.condition);
    _visitList(node.updaters, other.updaters);
    _visitNode(node.body, other.body);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.returnType, other.returnType);
    _visitNode(node.name, other.name);
    _visitNode(node.functionExpression, other.functionExpression);
  }

  @override
  visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    FunctionDeclarationStatement other = this.other;
    _visitNode(node.functionDeclaration, other.functionDeclaration);
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    FunctionExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.element, other.element);
    _visitNode(node.parameters, other.parameters);
    _visitNode(node.body, other.body);
  }

  @override
  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    FunctionExpressionInvocation other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitNode(node.function, other.function);
    _visitNode(node.argumentList, other.argumentList);
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    FunctionTypeAlias other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.returnType, other.returnType);
    _visitNode(node.name, other.name);
    _visitNode(node.typeParameters, other.typeParameters);
    _visitNode(node.parameters, other.parameters);
  }

  @override
  visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    FunctionTypedFormalParameter other = this.other;
    _visitNormalFormalParameter(node, other);
    _visitNode(node.returnType, other.returnType);
    _visitNode(node.parameters, other.parameters);
  }

  @override
  visitHideCombinator(HideCombinator node) {
    HideCombinator other = this.other;
    _visitList(node.hiddenNames, other.hiddenNames);
  }

  @override
  visitIfStatement(IfStatement node) {
    IfStatement other = this.other;
    _visitNode(node.condition, other.condition);
    _visitNode(node.thenStatement, other.thenStatement);
    _visitNode(node.elseStatement, other.elseStatement);
  }

  @override
  visitImplementsClause(ImplementsClause node) {
    ImplementsClause other = this.other;
    _visitList(node.interfaces, other.interfaces);
  }

  @override
  visitImportDirective(ImportDirective node) {
    ImportDirective other = this.other;
    _visitDirective(node, other);
    _visitNode(node.prefix, other.prefix);
    _verifyElement(node.uriElement, other.uriElement);
  }

  @override
  visitIndexExpression(IndexExpression node) {
    IndexExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitNode(node.target, other.target);
    _visitNode(node.index, other.index);
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    InstanceCreationExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _visitNode(node.constructorName, other.constructorName);
    _visitNode(node.argumentList, other.argumentList);
  }

  @override
  visitIntegerLiteral(IntegerLiteral node) {
    IntegerLiteral other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitInterpolationExpression(InterpolationExpression node) {
    InterpolationExpression other = this.other;
    _visitNode(node.expression, other.expression);
  }

  @override
  visitInterpolationString(InterpolationString node) {
  }

  @override
  visitIsExpression(IsExpression node) {
    IsExpression other = this.other;
    _visitExpression(node, other);
    _visitNode(node.expression, other.expression);
    _visitNode(node.type, other.type);
  }

  @override
  visitLabel(Label node) {
    Label other = this.other;
    _visitNode(node.label, other.label);
  }

  @override
  visitLabeledStatement(LabeledStatement node) {
    LabeledStatement other = this.other;
    _visitList(node.labels, other.labels);
    _visitNode(node.statement, other.statement);
  }

  @override
  visitLibraryDirective(LibraryDirective node) {
    LibraryDirective other = this.other;
    _visitDirective(node, other);
    _visitNode(node.name, other.name);
  }

  @override
  visitLibraryIdentifier(LibraryIdentifier node) {
    LibraryIdentifier other = this.other;
    _visitList(node.components, other.components);
  }

  @override
  visitListLiteral(ListLiteral node) {
    ListLiteral other = this.other;
    _visitExpression(node, other);
    _visitList(node.elements, other.elements);
  }

  @override
  visitMapLiteral(MapLiteral node) {
    MapLiteral other = this.other;
    _visitExpression(node, other);
    _visitList(node.entries, other.entries);
  }

  @override
  visitMapLiteralEntry(MapLiteralEntry node) {
    MapLiteralEntry other = this.other;
    _visitNode(node.key, other.key);
    _visitNode(node.value, other.value);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    MethodDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.name, other.name);
    _visitNode(node.parameters, other.parameters);
    _visitNode(node.body, other.body);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    MethodInvocation other = this.other;
    _visitNode(node.target, other.target);
    _visitNode(node.methodName, other.methodName);
    _visitNode(node.argumentList, other.argumentList);
  }

  @override
  visitNamedExpression(NamedExpression node) {
    NamedExpression other = this.other;
    _visitNode(node.name, other.name);
    _visitNode(node.expression, other.expression);
  }

  @override
  visitNativeClause(NativeClause node) {
  }

  @override
  visitNativeFunctionBody(NativeFunctionBody node) {
  }

  @override
  visitNullLiteral(NullLiteral node) {
    NullLiteral other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitParenthesizedExpression(ParenthesizedExpression node) {
    ParenthesizedExpression other = this.other;
    _visitNode(node.expression, other.expression);
  }

  @override
  visitPartDirective(PartDirective node) {
    PartDirective other = this.other;
    _visitDirective(node, other);
  }

  @override
  visitPartOfDirective(PartOfDirective node) {
    PartOfDirective other = this.other;
    _visitDirective(node, other);
    _visitNode(node.libraryName, other.libraryName);
  }

  @override
  visitPostfixExpression(PostfixExpression node) {
    PostfixExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitNode(node.operand, other.operand);
  }

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    PrefixedIdentifier other = this.other;
    _visitExpression(node, other);
    _visitNode(node.prefix, other.prefix);
    _visitNode(node.identifier, other.identifier);
  }

  @override
  visitPrefixExpression(PrefixExpression node) {
    PrefixExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitNode(node.operand, other.operand);
  }

  @override
  visitPropertyAccess(PropertyAccess node) {
    PropertyAccess other = this.other;
    _visitExpression(node, other);
    _visitNode(node.target, other.target);
    _visitNode(node.propertyName, other.propertyName);
  }

  @override
  visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    RedirectingConstructorInvocation other = this.other;
    _verifyElement(node.staticElement, other.staticElement);
    _visitNode(node.constructorName, other.constructorName);
    _visitNode(node.argumentList, other.argumentList);
  }

  @override
  visitRethrowExpression(RethrowExpression node) {
    RethrowExpression other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    ReturnStatement other = this.other;
    _visitNode(node.expression, other.expression);
  }

  @override
  visitScriptTag(ScriptTag node) {
  }

  @override
  visitShowCombinator(ShowCombinator node) {
    ShowCombinator other = this.other;
    _visitList(node.shownNames, other.shownNames);
  }

  @override
  visitSimpleFormalParameter(SimpleFormalParameter node) {
    SimpleFormalParameter other = this.other;
    _visitNormalFormalParameter(node, other);
    _visitNode(node.type, other.type);
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    SimpleIdentifier other = this.other;
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitExpression(node, other);
  }

  @override
  visitSimpleStringLiteral(SimpleStringLiteral node) {
  }

  @override
  visitStringInterpolation(StringInterpolation node) {
    StringInterpolation other = this.other;
    _visitList(node.elements, other.elements);
  }

  @override
  visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    SuperConstructorInvocation other = this.other;
    _verifyElement(node.staticElement, other.staticElement);
    _visitNode(node.constructorName, other.constructorName);
    _visitNode(node.argumentList, other.argumentList);
  }

  @override
  visitSuperExpression(SuperExpression node) {
    SuperExpression other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitSwitchCase(SwitchCase node) {
    SwitchCase other = this.other;
    _visitList(node.labels, other.labels);
    _visitNode(node.expression, other.expression);
    _visitList(node.statements, other.statements);
  }

  @override
  visitSwitchDefault(SwitchDefault node) {
    SwitchDefault other = this.other;
    _visitList(node.statements, other.statements);
  }

  @override
  visitSwitchStatement(SwitchStatement node) {
    SwitchStatement other = this.other;
    _visitNode(node.expression, other.expression);
    _visitList(node.members, other.members);
  }

  @override
  visitSymbolLiteral(SymbolLiteral node) {
  }

  @override
  visitThisExpression(ThisExpression node) {
    ThisExpression other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitThrowExpression(ThrowExpression node) {
    ThrowExpression other = this.other;
    _visitNode(node.expression, other.expression);
  }

  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    TopLevelVariableDeclaration other = this.other;
    _visitNode(node.variables, other.variables);
  }

  @override
  visitTryStatement(TryStatement node) {
    TryStatement other = this.other;
    _visitNode(node.body, other.body);
    _visitList(node.catchClauses, other.catchClauses);
    _visitNode(node.finallyBlock, other.finallyBlock);
  }

  @override
  visitTypeArgumentList(TypeArgumentList node) {
    TypeArgumentList other = this.other;
    _visitList(node.arguments, other.arguments);
  }

  @override
  visitTypeName(TypeName node) {
    TypeName other = this.other;
    _verifyType(node.type, other.type);
    _visitNode(node.name, node.name);
    _visitNode(node.typeArguments, other.typeArguments);
  }

  @override
  visitTypeParameter(TypeParameter node) {
    TypeParameter other = this.other;
    _visitNode(node.name, other.name);
    _visitNode(node.bound, other.bound);
  }

  @override
  visitTypeParameterList(TypeParameterList node) {
    TypeParameterList other = this.other;
    _visitList(node.typeParameters, other.typeParameters);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    VariableDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.name, other.name);
    _visitNode(node.initializer, other.initializer);
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
    VariableDeclarationList other = this.other;
    _visitNode(node.type, other.type);
    _visitList(node.variables, other.variables);
  }

  @override
  visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    VariableDeclarationStatement other = this.other;
    _visitNode(node.variables, other.variables);
  }

  @override
  visitWhileStatement(WhileStatement node) {
    WhileStatement other = this.other;
    _visitNode(node.condition, other.condition);
    _visitNode(node.body, other.body);
  }

  @override
  visitWithClause(WithClause node) {
    WithClause other = this.other;
    _visitList(node.mixinTypes, other.mixinTypes);
  }

  @override
  visitYieldStatement(YieldStatement node) {
    YieldStatement other = this.other;
    _visitNode(node.expression, other.expression);
  }

  void _verifyElement(Element a, Element b) {
    if (a != b) {
      fail('Expected: $b\n  Actual: $a');
    }
    if (a == null && b == null) {
      return;
    }
    expect(a.nameOffset, b.nameOffset);
  }

  void _verifyType(DartType a, DartType b) {
    expect(a, equals(b));
  }

  void _visitAnnotatedNode(AnnotatedNode node, AnnotatedNode other) {
    _visitNode(node.documentationComment, other.documentationComment);
    _visitList(node.metadata, other.metadata);
  }

  _visitDeclaration(Declaration node, Declaration other) {
    _verifyElement(node.element, other.element);
    _visitAnnotatedNode(node, other);
  }

  _visitDirective(Directive node, Directive other) {
    _verifyElement(node.element, other.element);
    _visitAnnotatedNode(node, other);
  }

  void _visitExpression(Expression a, Expression b) {
    _verifyType(a.staticType, b.staticType);
    _verifyType(a.propagatedType, b.propagatedType);
    _verifyElement(a.staticParameterElement, b.staticParameterElement);
    _verifyElement(a.propagatedParameterElement, b.propagatedParameterElement);
  }

  void _visitList(NodeList nodeList, NodeList otherList) {
    int length = nodeList.length;
    expect(otherList, hasLength(length));
    for (int i = 0; i < length; i++) {
      _visitNode(nodeList[i], otherList[i]);
    }
  }

  void _visitNode(AstNode node, AstNode other) {
    if (node == null) {
      expect(other, isNull);
    } else {
      this.other = other;
      node.accept(this);
    }
  }

  void _visitNormalFormalParameter(NormalFormalParameter node,
      NormalFormalParameter other) {
    _verifyElement(node.element, other.element);
    _visitNode(node.documentationComment, other.documentationComment);
    _visitList(node.metadata, other.metadata);
    _visitNode(node.identifier, other.identifier);
  }

  static void assertSameResolution(CompilationUnit actual,
      CompilationUnit expected) {
    _SameResolutionValidator validator = new _SameResolutionValidator(expected);
    actual.accept(validator);
  }
}
