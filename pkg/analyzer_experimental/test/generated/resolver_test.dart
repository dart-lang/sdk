// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.
library engine.resolver_test;
import 'dart:collection';
import 'package:analyzer_experimental/src/generated/java_core.dart';
import 'package:analyzer_experimental/src/generated/java_engine.dart';
import 'package:analyzer_experimental/src/generated/java_junit.dart';
import 'package:analyzer_experimental/src/generated/source_io.dart';
import 'package:analyzer_experimental/src/generated/error.dart';
import 'package:analyzer_experimental/src/generated/scanner.dart';
import 'package:analyzer_experimental/src/generated/ast.dart';
import 'package:analyzer_experimental/src/generated/parser.dart' show ParserErrorCode;
import 'package:analyzer_experimental/src/generated/element.dart';
import 'package:analyzer_experimental/src/generated/resolver.dart';
import 'package:analyzer_experimental/src/generated/engine.dart';
import 'package:analyzer_experimental/src/generated/java_engine_io.dart';
import 'package:analyzer_experimental/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer_experimental/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:unittest/unittest.dart' as _ut;
import 'test_support.dart';
import 'ast_test.dart' show ASTFactory;
import 'element_test.dart' show ElementFactory;
class TypePropagationTest extends ResolverTestCase {
  void test_as() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  bool get g => true;", "}", "A f(var p) {", "  if ((p as A).g) {", "    return p;", "  } else {", "    return null;", "  }", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement = ((ifStatement.thenStatement as Block)).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.propagatedType);
  }
  void test_assert() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "A f(var p) {", "  assert (p is A);", "  return p;", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.propagatedType);
  }
  void test_assignment() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  var v;", "  v = 0;", "  return v;", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[2] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeProvider.intType, variableName.propagatedType);
  }
  void test_assignment_afterInitializer() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  var v = 0;", "  v = 1.0;", "  return v;", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[2] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeProvider.doubleType, variableName.propagatedType);
  }
  void test_forEach() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "A f(List<A> p) {", "  for (var e in p) {", "    return e;", "  }", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    ForEachStatement forStatement = body.block.statements[0] as ForEachStatement;
    ReturnStatement statement = ((forStatement.body as Block)).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.propagatedType);
  }
  void test_initializer() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  var v = 0;", "  return v;", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeProvider.intType, variableName.propagatedType);
  }
  void test_initializer_dereference() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  var v = 'String';", "  v.", "}"]));
    LibraryElement library = resolve(source);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    ExpressionStatement statement = body.block.statements[1] as ExpressionStatement;
    PrefixedIdentifier invocation = statement.expression as PrefixedIdentifier;
    SimpleIdentifier variableName = invocation.prefix;
    JUnitTestCase.assertSame(typeProvider.stringType, variableName.propagatedType);
  }
  void test_is_conditional() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "A f(var p) {", "  return (p is A) ? p : null;", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[0] as ReturnStatement;
    ConditionalExpression conditional = statement.expression as ConditionalExpression;
    SimpleIdentifier variableName = conditional.thenExpression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.propagatedType);
  }
  void test_is_if() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "A f(var p) {", "  if (p is A) {", "    return p;", "  } else {", "    return null;", "  }", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement = ((ifStatement.thenStatement as Block)).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.propagatedType);
  }
  void test_is_if_lessSpecific() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "A f(A p) {", "  if (p is Object) {", "    return p;", "  } else {", "    return null;", "  }", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement = ((ifStatement.thenStatement as Block)).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(null, variableName.propagatedType);
  }
  void test_is_if_logicalAnd() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "A f(var p) {", "  if (p is A && p != null) {", "    return p;", "  } else {", "    return null;", "  }", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement = ((ifStatement.thenStatement as Block)).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.propagatedType);
  }
  void test_is_postConditional() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "A f(var p) {", "  A a = (p is A) ? p : throw null;", "  return p;", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.propagatedType);
  }
  void test_is_postIf() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "A f(var p) {", "  if (p is A) {", "    A a = p;", "  } else {", "    return null;", "  }", "  return p;", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.propagatedType);
  }
  void test_is_subclass() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B extends A {", "  B m() => this;", "}", "A f(A p) {", "  if (p is B) {", "    return p.m();", "  }", "}"]));
    LibraryElement library = resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_METHOD]);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[2] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement = ((ifStatement.thenStatement as Block)).statements[0] as ReturnStatement;
    MethodInvocation invocation = statement.expression as MethodInvocation;
    JUnitTestCase.assertNotNull(invocation.methodName.element);
  }
  void test_is_while() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "A f(var p) {", "  while (p is A) {", "    return p;", "  }", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    WhileStatement whileStatement = body.block.statements[0] as WhileStatement;
    ReturnStatement statement = ((whileStatement.body as Block)).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.propagatedType);
  }
  void test_isNot_conditional() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "A f(var p) {", "  return (p is! A) ? null : p;", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[0] as ReturnStatement;
    ConditionalExpression conditional = statement.expression as ConditionalExpression;
    SimpleIdentifier variableName = conditional.elseExpression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.propagatedType);
  }
  void test_isNot_if() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "A f(var p) {", "  if (p is! A) {", "    return null;", "  } else {", "    return p;", "  }", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement = ((ifStatement.elseStatement as Block)).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.propagatedType);
  }
  void test_isNot_if_logicalOr() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "A f(var p) {", "  if (p is! A || null == p) {", "    return null;", "  } else {", "    return p;", "  }", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement = ((ifStatement.elseStatement as Block)).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.propagatedType);
  }
  void test_isNot_postConditional() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "A f(var p) {", "  A a = (p is! A) ? throw null : p;", "  return p;", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.propagatedType);
  }
  void test_isNot_postIf() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "A f(var p) {", "  if (p is! A) {", "    return null;", "  }", "  return p;", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.propagatedType);
  }
  void test_listLiteral_different() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  var v = [0, '1', 2];", "  return v[2];", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    IndexExpression indexExpression = statement.expression as IndexExpression;
    JUnitTestCase.assertNull(indexExpression.propagatedType);
  }
  void test_listLiteral_same() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  var v = [0, 1, 2];", "  return v[2];", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    IndexExpression indexExpression = statement.expression as IndexExpression;
    JUnitTestCase.assertSame(typeProvider.intType, indexExpression.propagatedType);
  }
  void test_mapLiteral_different() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  var v = {'0' : 0, 1 : '1', '2' : 2};", "  return v;", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier identifier = statement.expression as SimpleIdentifier;
    InterfaceType propagatedType = identifier.propagatedType as InterfaceType;
    JUnitTestCase.assertSame(typeProvider.mapType.element, propagatedType.element);
    List<Type2> typeArguments = propagatedType.typeArguments;
    EngineTestCase.assertLength(2, typeArguments);
    JUnitTestCase.assertSame(typeProvider.dynamicType, typeArguments[0]);
    JUnitTestCase.assertSame(typeProvider.dynamicType, typeArguments[1]);
  }
  void test_mapLiteral_same() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  var v = {'a' : 0, 'b' : 1, 'c' : 2};", "  return v;", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier identifier = statement.expression as SimpleIdentifier;
    InterfaceType propagatedType = identifier.propagatedType as InterfaceType;
    JUnitTestCase.assertSame(typeProvider.mapType.element, propagatedType.element);
    List<Type2> typeArguments = propagatedType.typeArguments;
    EngineTestCase.assertLength(2, typeArguments);
    JUnitTestCase.assertSame(typeProvider.stringType, typeArguments[0]);
    JUnitTestCase.assertSame(typeProvider.intType, typeArguments[1]);
  }
  void test_query() {
    Source source = addSource(EngineTestCase.createSource(["import 'dart:html';", "", "main() {", "  var v1 = query('a');", "  var v2 = query('A');", "  var v3 = query('body:active');", "  var v4 = query('button[foo=\"bar\"]');", "  var v5 = query('div.class');", "  var v6 = query('input#id');", "  var v7 = query('select#id');", "  // invocation of method", "  var m1 = document.query('div');", " // unsupported currently", "  var b1 = query('noSuchTag');", "  var b2 = query('DART_EDITOR_NO_SUCH_TYPE');", "  var b3 = query('body div');", "  return [v1, v2, v3, v4, v5, v6, v7, m1, b1, b2, b3];", "}"]));
    LibraryElement library = resolve(source);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration main = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body = main.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[11] as ReturnStatement;
    NodeList<Expression> elements = ((statement.expression as ListLiteral)).elements;
    JUnitTestCase.assertEquals("AnchorElement", elements[0].propagatedType.name);
    JUnitTestCase.assertEquals("AnchorElement", elements[1].propagatedType.name);
    JUnitTestCase.assertEquals("BodyElement", elements[2].propagatedType.name);
    JUnitTestCase.assertEquals("ButtonElement", elements[3].propagatedType.name);
    JUnitTestCase.assertEquals("DivElement", elements[4].propagatedType.name);
    JUnitTestCase.assertEquals("InputElement", elements[5].propagatedType.name);
    JUnitTestCase.assertEquals("SelectElement", elements[6].propagatedType.name);
    JUnitTestCase.assertEquals("DivElement", elements[7].propagatedType.name);
    JUnitTestCase.assertEquals("Element", elements[8].propagatedType.name);
    JUnitTestCase.assertEquals("Element", elements[9].propagatedType.name);
    JUnitTestCase.assertEquals("Element", elements[10].propagatedType.name);
  }
  static dartSuite() {
    _ut.group('TypePropagationTest', () {
      _ut.test('test_as', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_as);
      });
      _ut.test('test_assert', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_assert);
      });
      _ut.test('test_assignment', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_assignment);
      });
      _ut.test('test_assignment_afterInitializer', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_assignment_afterInitializer);
      });
      _ut.test('test_forEach', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_forEach);
      });
      _ut.test('test_initializer', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_initializer);
      });
      _ut.test('test_initializer_dereference', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_initializer_dereference);
      });
      _ut.test('test_isNot_conditional', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_isNot_conditional);
      });
      _ut.test('test_isNot_if', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_isNot_if);
      });
      _ut.test('test_isNot_if_logicalOr', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_isNot_if_logicalOr);
      });
      _ut.test('test_isNot_postConditional', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_isNot_postConditional);
      });
      _ut.test('test_isNot_postIf', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_isNot_postIf);
      });
      _ut.test('test_is_conditional', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_is_conditional);
      });
      _ut.test('test_is_if', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_is_if);
      });
      _ut.test('test_is_if_lessSpecific', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_is_if_lessSpecific);
      });
      _ut.test('test_is_if_logicalAnd', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_is_if_logicalAnd);
      });
      _ut.test('test_is_postConditional', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_is_postConditional);
      });
      _ut.test('test_is_postIf', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_is_postIf);
      });
      _ut.test('test_is_subclass', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_is_subclass);
      });
      _ut.test('test_is_while', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_is_while);
      });
      _ut.test('test_listLiteral_different', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_listLiteral_different);
      });
      _ut.test('test_listLiteral_same', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_listLiteral_same);
      });
      _ut.test('test_mapLiteral_different', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_mapLiteral_different);
      });
      _ut.test('test_mapLiteral_same', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_mapLiteral_same);
      });
      _ut.test('test_query', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_query);
      });
    });
  }
}
class NonErrorResolverTest extends ResolverTestCase {
  void test_ambiguousExport() {
    Source source = addSource(EngineTestCase.createSource(["library L;", "export 'lib1.dart';", "export 'lib2.dart';"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["library lib1;", "class M {}"]));
    addSource2("/lib2.dart", EngineTestCase.createSource(["library lib2;", "class N {}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_ambiguousExport_combinators_hide() {
    Source source = addSource(EngineTestCase.createSource(["library L;", "export 'lib1.dart';", "export 'lib2.dart' hide B;"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["library L1;", "class A {}", "class B {}"]));
    addSource2("/lib2.dart", EngineTestCase.createSource(["library L2;", "class B {}", "class C {}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_ambiguousExport_combinators_show() {
    Source source = addSource(EngineTestCase.createSource(["library L;", "export 'lib1.dart';", "export 'lib2.dart' show C;"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["library L1;", "class A {}", "class B {}"]));
    addSource2("/lib2.dart", EngineTestCase.createSource(["library L2;", "class B {}", "class C {}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_argumentDefinitionTestNonParameter_formalParameter() {
    Source source = addSource(EngineTestCase.createSource(["f(var v) {", "  return ?v;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_argumentDefinitionTestNonParameter_namedParameter() {
    Source source = addSource(EngineTestCase.createSource(["f({var v : 0}) {", "  return ?v;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_argumentDefinitionTestNonParameter_optionalParameter() {
    Source source = addSource(EngineTestCase.createSource(["f([var v]) {", "  return ?v;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_argumentTypeNotAssignable_classWithCall_Function() {
    Source source = addSource(EngineTestCase.createSource(["  caller(Function callee) {", "    callee();", "  }", "", "  class CallMeBack {", "    call() => 0;", "  }", "", "  main() {", "    caller(new CallMeBack());", "  }"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_argumentTypeNotAssignable_invocation_functionParameter_generic() {
    Source source = addSource(EngineTestCase.createSource(["class A<K> {", "  m(f(K k), K v) {", "    f(v);", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_argumentTypeNotAssignable_invocation_typedef_generic() {
    Source source = addSource(EngineTestCase.createSource(["typedef A<T>(T p);", "f(A<int> a) {", "  a(1);", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_argumentTypeNotAssignable_Object_Function() {
    Source source = addSource(EngineTestCase.createSource(["main() {", "  process(() {});", "}", "process(Object x) {}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_argumentTypeNotAssignable_typedef_local() {
    Source source = addSource(EngineTestCase.createSource(["typedef A(int p1, String p2);", "A getA() => null;", "f() {", "  A a = getA();", "  a(1, '2');", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_argumentTypeNotAssignable_typedef_parameter() {
    Source source = addSource(EngineTestCase.createSource(["typedef A(int p1, String p2);", "f(A a) {", "  a(1, '2');", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_assignmentToFinal_prefixNegate() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  final x = 0;", "  -x;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_assignmentToFinals_importWithPrefix() {
    Source source = addSource(EngineTestCase.createSource(["library lib;", "import 'lib1.dart' as foo;", "main() {", "  foo.x = true;", "}"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["library lib1;", "bool x = false;"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_breakWithoutLabelInSwitch() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void m(int i) {", "    switch (i) {", "      case 0:", "        break;", "    }", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_builtInIdentifierAsType_dynamic() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  dynamic x;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_caseBlockNotTerminated() {
    Source source = addSource(EngineTestCase.createSource(["f(int p) {", "  for (int i = 0; i < 10; i++) {", "    switch (p) {", "      case 0:", "        break;", "      case 1:", "        continue;", "      case 2:", "        return;", "      case 3:", "        throw new Object();", "      case 4:", "      case 5:", "        return;", "      case 6:", "      default:", "        return;", "    }", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_caseBlockNotTerminated_lastCase() {
    Source source = addSource(EngineTestCase.createSource(["f(int p) {", "  switch (p) {", "    case 0:", "      p = p + 1;", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_caseExpressionTypeImplementsEquals_int() {
    Source source = addSource(EngineTestCase.createSource(["f(int i) {", "  switch(i) {", "    case(1) : return 1;", "    default: return 0;", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_caseExpressionTypeImplementsEquals_Object() {
    Source source = addSource(EngineTestCase.createSource(["class IntWrapper {", "  final int value;", "  const IntWrapper(this.value);", "}", "", "f(IntWrapper intWrapper) {", "  switch(intWrapper) {", "    case(const IntWrapper(1)) : return 1;", "    default: return 0;", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_caseExpressionTypeImplementsEquals_String() {
    Source source = addSource(EngineTestCase.createSource(["f(String s) {", "  switch(s) {", "    case('1') : return 1;", "    default: return 0;", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_concreteClassWithAbstractMember() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A {", "  m();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_conflictingInstanceGetterAndSuperclassMember_instance() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  get v => 0;", "}", "class B extends A {", "  get v => 1;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_conflictingStaticGetterAndInstanceSetter_thisClass() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static get x => 0;", "  static set x(int p) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_conflictingStaticSetterAndInstanceMember_thisClass_method() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static x() {}", "  static set x(int p) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_constConstructorWithNonFinalField_finalInstanceVar() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final int x = 0;", "  const A();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_constConstructorWithNonFinalField_mixin() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  a() {}", "}", "class B extends Object with A {", "  const B();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_constConstructorWithNonFinalField_static() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static int x;", "  const A();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_constConstructorWithNonFinalField_syntheticField() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  const A();", "  set x(value) {}", "  get x {return 0;}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_constEvalTypeBoolNumString_equal() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  const A();", "}", "class B {", "  final v;", "  const B.a1(bool p) : v = p == true;", "  const B.a2(bool p) : v = p == false;", "  const B.a3(bool p) : v = p == 0;", "  const B.a4(bool p) : v = p == 0.0;", "  const B.a5(bool p) : v = p == '';", "  const B.b1(int p) : v = p == true;", "  const B.b2(int p) : v = p == false;", "  const B.b3(int p) : v = p == 0;", "  const B.b4(int p) : v = p == 0.0;", "  const B.b5(int p) : v = p == '';", "  const B.c1(String p) : v = p == true;", "  const B.c2(String p) : v = p == false;", "  const B.c3(String p) : v = p == 0;", "  const B.c4(String p) : v = p == 0.0;", "  const B.c5(String p) : v = p == '';", "  const B.n1(num p) : v = p == null;", "  const B.n2(num p) : v = null == p;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_constEvalTypeBoolNumString_notEqual() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  const A();", "}", "class B {", "  final v;", "  const B.a1(bool p) : v = p != true;", "  const B.a2(bool p) : v = p != false;", "  const B.a3(bool p) : v = p != 0;", "  const B.a4(bool p) : v = p != 0.0;", "  const B.a5(bool p) : v = p != '';", "  const B.b1(int p) : v = p != true;", "  const B.b2(int p) : v = p != false;", "  const B.b3(int p) : v = p != 0;", "  const B.b4(int p) : v = p != 0.0;", "  const B.b5(int p) : v = p != '';", "  const B.c1(String p) : v = p != true;", "  const B.c2(String p) : v = p != false;", "  const B.c3(String p) : v = p != 0;", "  const B.c4(String p) : v = p != 0.0;", "  const B.c5(String p) : v = p != '';", "  const B.n1(num p) : v = p != null;", "  const B.n2(num p) : v = null != p;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_constWithNonConstantArgument_literals() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  const A(a, b, c, d);", "}", "f() { return const A(true, 0, 1.0, '2'); }"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_constWithTypeParameters_direct() {
    Source source = addSource(EngineTestCase.createSource(["class A<T> {", "  static const V = const A<int>();", "  const A();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_constWithUndefinedConstructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  const A.name();", "}", "f() {", "  return const A.name();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_constWithUndefinedConstructorDefault() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  const A();", "}", "f() {", "  return const A();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_defaultValueInFunctionTypeAlias() {
    Source source = addSource(EngineTestCase.createSource(["typedef F([x]);"]));
    resolve(source);
    assertErrors([]);
    verify([source]);
  }
  void test_duplicateDefinition_emptyName() {
    Source source = addSource(EngineTestCase.createSource(["Map _globalMap = {", "  'a' : () {},", "  'b' : () {}", "};"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_duplicateDefinition_getter() {
    Source source = addSource(EngineTestCase.createSource(["bool get a => true;"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_exportOfNonLibrary_libraryDeclared() {
    Source source = addSource(EngineTestCase.createSource(["library L;", "export 'lib1.dart';"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["library lib1;"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_exportOfNonLibrary_libraryNotDeclared() {
    Source source = addSource(EngineTestCase.createSource(["library L;", "export 'lib1.dart';"]));
    addSource2("/lib1.dart", EngineTestCase.createSource([""]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_extraPositionalArguments_function() {
    Source source = addSource(EngineTestCase.createSource(["f(p1, p2) {}", "main() {", "  f(1, 2);", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_extraPositionalArguments_Function() {
    Source source = addSource(EngineTestCase.createSource(["f(Function a) {", "  a(1, 2);", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_extraPositionalArguments_typedef_local() {
    Source source = addSource(EngineTestCase.createSource(["typedef A(p1, p2);", "A getA() => null;", "f() {", "  A a = getA();", "  a(1, 2);", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_extraPositionalArguments_typedef_parameter() {
    Source source = addSource(EngineTestCase.createSource(["typedef A(p1, p2);", "f(A a) {", "  a(1, 2);", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_fieldInitializedByMultipleInitializers() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "  int y;", "  A() : x = 0, y = 0 {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_fieldInitializedInInitializerAndDeclaration_fieldNotFinal() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x = 0;", "  A() : x = 1 {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_fieldInitializedInInitializerAndDeclaration_finalFieldNotSet() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final int x;", "  A() : x = 1 {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_fieldInitializerOutsideConstructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "  A(this.x) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_fieldInitializerOutsideConstructor_defaultParameters() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "  A([this.x]) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_fieldInitializerRedirectingConstructor_super() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A() {}", "}", "class B extends A {", "  int x;", "  A(this.x) : super();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_finalInitializedInDeclarationAndConstructor_initializer() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final x;", "  A() : x = 1 {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_finalInitializedInDeclarationAndConstructor_initializingFormal() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final x;", "  A(this.x) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_finalNotInitialized_atDeclaration() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final int x = 0;", "  A() {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_finalNotInitialized_fieldFormal() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final int x = 0;", "  A() {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_finalNotInitialized_initializer() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final int x;", "  A() : x = 0 {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_implicitThisReferenceInInitializer_constructorName() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A.named() {}", "}", "class B {", "  var v;", "  B() : v = new A.named();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_implicitThisReferenceInInitializer_prefixedIdentifier() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  var f;", "}", "class B {", "  var v;", "  B(A a) : v = a.f;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_implicitThisReferenceInInitializer_qualifiedMethodInvocation() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  f() {}", "}", "class B {", "  var v;", "  B() : v = new A().f();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_implicitThisReferenceInInitializer_qualifiedPropertyAccess() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  var f;", "}", "class B {", "  var v;", "  B() : v = new A().f;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_implicitThisReferenceInInitializer_staticField_superClass() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static var f;", "}", "class B extends A {", "  var v;", "  B() : v = f;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_implicitThisReferenceInInitializer_staticField_thisClass() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  var v;", "  A() : v = f;", "  static var f;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_implicitThisReferenceInInitializer_staticGetter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  var v;", "  A() : v = f;", "  static get f => 42;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_implicitThisReferenceInInitializer_staticMethod() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  var v;", "  A() : v = f();", "  static f() => 42;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_implicitThisReferenceInInitializer_topLevelField() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  var v;", "  A() : v = f;", "}", "var f = 42;"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_implicitThisReferenceInInitializer_topLevelFunction() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  var v;", "  A() : v = f();", "}", "f() => 42;"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_implicitThisReferenceInInitializer_topLevelGetter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  var v;", "  A() : v = f;", "}", "get f => 42;"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_implicitThisReferenceInInitializer_typeVariable() {
    Source source = addSource(EngineTestCase.createSource(["class A<T> {", "  var v;", "  A(p) : v = (p is T);", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_importDuplicatedLibraryName() {
    Source source = addSource(EngineTestCase.createSource(["library test;", "import 'lib.dart';", "import 'lib.dart';"]));
    addSource2("/lib.dart", "library lib;");
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_importOfNonLibrary_libraryDeclared() {
    Source source = addSource(EngineTestCase.createSource(["library lib;", "import 'part.dart';"]));
    addSource2("/part.dart", EngineTestCase.createSource(["library lib1;"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_importOfNonLibrary_libraryNotDeclared() {
    Source source = addSource(EngineTestCase.createSource(["library lib;", "import 'part.dart';"]));
    addSource2("/part.dart", EngineTestCase.createSource([""]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_inconsistentCaseExpressionTypes() {
    Source source = addSource(EngineTestCase.createSource(["f(var p) {", "  switch (p) {", "    case 1:", "      break;", "    case 2:", "      break;", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_initializingFormalForNonExistantField() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "  A(this.x) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidAssignment() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  var x;", "  var y;", "  x = y;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidAssignment_compoundAssignment() {
    Source source = addSource(EngineTestCase.createSource(["class byte {", "  int _value;", "  byte(this._value);", "  byte operator +(int val) {}", "}", "", "void main() {", "  byte b = new byte(52);", "  b += 3;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidAssignment_toDynamic() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  var g;", "  g = () => 0;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidFactoryNameNotAClass() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  factory A() {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidMethodOverrideNamedParamType() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m({int a}) {}", "}", "class B implements A {", "  m({int a, int b}) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidOverrideDifferentDefaultValues_named() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m({int p : 0}) {}", "}", "class B extends A {", "  m({int p : 0}) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidOverrideDifferentDefaultValues_positional() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m([int p = 0]) {}", "}", "class B extends A {", "  m([int p = 0]) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidOverrideDifferentDefaultValues_positional_changedOrder() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m([int a = 0, String b = '0']) {}", "}", "class B extends A {", "  m([int b = 0, String a = '0']) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidOverrideNamed_unorderedNamedParameter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m({a, b}) {}", "}", "class B extends A {", "  m({b, a}) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidOverrideReturnType_returnType_interface() {
    Source source = addSource2("/test.dart", EngineTestCase.createSource(["abstract class A {", "  num m();", "}", "class B implements A {", "  int m() { return 1; }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidOverrideReturnType_returnType_interface2() {
    Source source = addSource2("/test.dart", EngineTestCase.createSource(["abstract class A {", "  num m();", "}", "abstract class B implements A {", "}", "class C implements B {", "  int m() { return 1; }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidOverrideReturnType_returnType_mixin() {
    Source source = addSource2("/test.dart", EngineTestCase.createSource(["class A {", "  num m() { return 0; }", "}", "class B extends Object with A {", "  int m() { return 1; }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidOverrideReturnType_returnType_parameterizedTypes() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A<E> {", "  List<E> m();", "}", "class B extends A<dynamic> {", "  List<dynamic> m() { return new List<dynamic>(); }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidOverrideReturnType_returnType_sameType() {
    Source source = addSource2("/test.dart", EngineTestCase.createSource(["class A {", "  int m() { return 0; }", "}", "class B extends A {", "  int m() { return 1; }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidOverrideReturnType_returnType_superclass() {
    Source source = addSource2("/test.dart", EngineTestCase.createSource(["class A {", "  num m() { return 0; }", "}", "class B extends A {", "  int m() { return 1; }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidOverrideReturnType_returnType_superclass2() {
    Source source = addSource2("/test.dart", EngineTestCase.createSource(["class A {", "  num m() { return 0; }", "}", "class B extends A {", "}", "class C extends B {", "  int m() { return 1; }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidOverrideReturnType_returnType_void() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void m() {}", "}", "class B extends A {", "  int m() {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidReferenceToThis_constructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A() {", "    var v = this;", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidReferenceToThis_instanceMethod() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m() {", "    var v = this;", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidTypeArgumentInConstList() {
    Source source = addSource(EngineTestCase.createSource(["class A<E> {", "  m() {", "    return <E>[];", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidTypeArgumentInConstMap() {
    Source source = addSource(EngineTestCase.createSource(["class A<E> {", "  m() {", "    return <String, E>{};", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invocationOfNonFunction_dynamic() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  var f;", "}", "class B extends A {", "  g() {", "    f();", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invocationOfNonFunction_getter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  var g;", "}", "f() {", "  A a;", "  a.g();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invocationOfNonFunction_localVariable() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  var g;", "  g();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_memberWithClassName_setter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  set A(v) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_misMatchedGetterAndSetterTypes_instance_sameTypes() {
    Source source = addSource(EngineTestCase.createSource(["class C {", "  int get x => 0;", "  set x(int v) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_misMatchedGetterAndSetterTypes_instance_unspecifiedGetter() {
    Source source = addSource(EngineTestCase.createSource(["class C {", "  get x => 0;", "  set x(String v) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_misMatchedGetterAndSetterTypes_instance_unspecifiedSetter() {
    Source source = addSource(EngineTestCase.createSource(["class C {", "  int get x => 0;", "  set x(v) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_misMatchedGetterAndSetterTypes_topLevel_sameTypes() {
    Source source = addSource(EngineTestCase.createSource(["int get x => 0;", "set x(int v) {}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_misMatchedGetterAndSetterTypes_topLevel_unspecifiedGetter() {
    Source source = addSource(EngineTestCase.createSource(["get x => 0;", "set x(String v) {}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_misMatchedGetterAndSetterTypes_topLevel_unspecifiedSetter() {
    Source source = addSource(EngineTestCase.createSource(["int get x => 0;", "set x(v) {}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_mixinDeclaresConstructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m() {}", "}", "class B extends Object with A {}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_mixinDeclaresConstructor_factory() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  factory A() {}", "}", "class B extends Object with A {}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_mixinInheritsFromNotObject_classDeclaration_mixTypedef() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "typedef B = Object with A;", "class C extends Object with B {}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_mixinInheritsFromNotObject_typedef_mixTypedef() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "typedef B = Object with A;", "typedef C = Object with B;"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_multipleSuperInitializers_no() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B extends A {", "  B() {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_multipleSuperInitializers_single() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B extends A {", "  B() : super() {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_newWithAbstractClass_factory() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A {", "  factory A() { return new B(); }", "}", "class B implements A {", "  B() {}", "}", "A f() {", "  return new A();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_newWithUndefinedConstructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A.name() {}", "}", "f() {", "  new A.name();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_newWithUndefinedConstructorDefault() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A() {}", "}", "f() {", "  new A();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonBoolExpression_assert_bool() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  assert(true);", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonBoolExpression_assert_functionType() {
    Source source = addSource(EngineTestCase.createSource(["bool makeAssertion() => true;", "f() {", "  assert(makeAssertion);", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonConstantDefaultValue_function_named() {
    Source source = addSource(EngineTestCase.createSource(["f({x : 2 + 3}) {}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonConstantDefaultValue_function_positional() {
    Source source = addSource(EngineTestCase.createSource(["f([x = 2 + 3]) {}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonConstantDefaultValue_inConstructor_named() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A({x : 2 + 3}) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonConstantDefaultValue_inConstructor_positional() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A([x = 2 + 3]) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonConstantDefaultValue_method_named() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m({x : 2 + 3}) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonConstantDefaultValue_method_positional() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m([x = 2 + 3]) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonConstCaseExpression() {
    Source source = addSource(EngineTestCase.createSource(["f(Type t) {", "  switch (t) {", "    case bool:", "    case int:", "      return true;", "    default:", "      return false;", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonConstMapAsExpressionStatement_const() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  const {'a' : 0, 'b' : 1};", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonConstMapAsExpressionStatement_notExpressionStatement() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  var m = {'a' : 0, 'b' : 1};", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonConstMapAsExpressionStatement_typeArguments() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  <String, int> {'a' : 0, 'b' : 1};", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonConstValueInInitializer_binary_bool() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final v;", "  const A.a1(bool p) : v = p && true;", "  const A.a2(bool p) : v = true && p;", "  const A.b1(bool p) : v = p || true;", "  const A.b2(bool p) : v = true || p;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonConstValueInInitializer_binary_dynamic() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final v;", "  const A.a1(p) : v = p + 5;", "  const A.a2(p) : v = 5 + p;", "  const A.b1(p) : v = p - 5;", "  const A.b2(p) : v = 5 - p;", "  const A.c1(p) : v = p * 5;", "  const A.c2(p) : v = 5 * p;", "  const A.d1(p) : v = p / 5;", "  const A.d2(p) : v = 5 / p;", "  const A.e1(p) : v = p ~/ 5;", "  const A.e2(p) : v = 5 ~/ p;", "  const A.f1(p) : v = p > 5;", "  const A.f2(p) : v = 5 > p;", "  const A.g1(p) : v = p < 5;", "  const A.g2(p) : v = 5 < p;", "  const A.h1(p) : v = p >= 5;", "  const A.h2(p) : v = 5 >= p;", "  const A.i1(p) : v = p <= 5;", "  const A.i2(p) : v = 5 <= p;", "  const A.j1(p) : v = p % 5;", "  const A.j2(p) : v = 5 % p;", "}"]));
    resolve(source);
    assertNoErrors();
  }
  void test_nonConstValueInInitializer_binary_int() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final v;", "  const A.a1(int p) : v = p ^ 5;", "  const A.a2(int p) : v = 5 ^ p;", "  const A.b1(int p) : v = p & 5;", "  const A.b2(int p) : v = 5 & p;", "  const A.c1(int p) : v = p | 5;", "  const A.c2(int p) : v = 5 | p;", "  const A.d1(int p) : v = p >> 5;", "  const A.d2(int p) : v = 5 >> p;", "  const A.e1(int p) : v = p << 5;", "  const A.e2(int p) : v = 5 << p;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonConstValueInInitializer_binary_num() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final v;", "  const A.a1(num p) : v = p + 5;", "  const A.a2(num p) : v = 5 + p;", "  const A.b1(num p) : v = p - 5;", "  const A.b2(num p) : v = 5 - p;", "  const A.c1(num p) : v = p * 5;", "  const A.c2(num p) : v = 5 * p;", "  const A.d1(num p) : v = p / 5;", "  const A.d2(num p) : v = 5 / p;", "  const A.e1(num p) : v = p ~/ 5;", "  const A.e2(num p) : v = 5 ~/ p;", "  const A.f1(num p) : v = p > 5;", "  const A.f2(num p) : v = 5 > p;", "  const A.g1(num p) : v = p < 5;", "  const A.g2(num p) : v = 5 < p;", "  const A.h1(num p) : v = p >= 5;", "  const A.h2(num p) : v = 5 >= p;", "  const A.i1(num p) : v = p <= 5;", "  const A.i2(num p) : v = 5 <= p;", "  const A.j1(num p) : v = p % 5;", "  const A.j2(num p) : v = 5 % p;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonConstValueInInitializer_field() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final int a;", "  const A() : a = 5;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonConstValueInInitializer_redirecting() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  const A.named(p);", "  const A() : this.named(42);", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonConstValueInInitializer_super() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  const A(p);", "}", "class B extends A {", "  const B() : super(42);", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonConstValueInInitializer_unary() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final v;", "  const A.a(bool p) : v = !p;", "  const A.b(int p) : v = ~p;", "  const A.c(num p) : v = -p;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonGenerativeConstructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A.named() {}", "  factory A() {}", "}", "class B extends A {", "  B() : super.named();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonTypeInCatchClause_isClass() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  try {", "  } on String catch (e) {", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonTypeInCatchClause_isFunctionTypeAlias() {
    Source source = addSource(EngineTestCase.createSource(["typedef F();", "f() {", "  try {", "  } on F catch (e) {", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonTypeInCatchClause_isTypeVariable() {
    Source source = addSource(EngineTestCase.createSource(["class A<T> {", "  f() {", "    try {", "    } on T catch (e) {", "    }", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonTypeInCatchClause_noType() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  try {", "  } catch (e) {", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonVoidReturnForOperator_no() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  operator []=(a, b) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonVoidReturnForOperator_void() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void operator []=(a, b) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonVoidReturnForSetter_function_no() {
    Source source = addSource("set x(v) {}");
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonVoidReturnForSetter_function_void() {
    Source source = addSource("void set x(v) {}");
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonVoidReturnForSetter_method_no() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  set x(v) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_nonVoidReturnForSetter_method_void() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void set x(v) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_optionalParameterInOperator_required() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  operator +(p) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_prefixCollidesWithTopLevelMembers() {
    addSource2("/lib.dart", "library lib;");
    Source source = addSource(EngineTestCase.createSource(["import '/lib.dart' as p;", "typedef P();", "p2() {}", "var p3;", "class p4 {}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_recursiveConstructorRedirect() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A.a() : this.b();", "  A.b() : this.c();", "  A.c() {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_recursiveFactoryRedirect() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  factory A() = B;", "}", "class B implements A {", "  factory B() = C;", "}", "class C implements B {", "  factory C() {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_redirectToInvalidFunctionType() {
    Source source = addSource(EngineTestCase.createSource(["class A implements B {", "  A(int p) {}", "}", "class B {", "  B(int p) = A;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_redirectToNonConstConstructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  const A.a();", "  const factory A.b() = A.a;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_referenceToDeclaredVariableInInitializer_constructorName() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A.x() {}", "}", "f() {", "  var x = new A.x();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_referenceToDeclaredVariableInInitializer_methodName() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  x() {}", "}", "f(A a) {", "  var x = a.x();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_referenceToDeclaredVariableInInitializer_propertyName() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  var x;", "}", "f(A a) {", "  var x = a.x;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_rethrowOutsideCatch() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void m() {", "    try {} catch (e) {rethrow;}", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_returnInGenerativeConstructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A() { return; }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_returnOfInvalidType_dynamic() {
    Source source = addSource(EngineTestCase.createSource(["class TypeError {}", "class A {", "  static void testLogicalOp() {", "    testOr(a, b, onTypeError) {", "      try {", "        return a || b;", "      } on TypeError catch (t) {", "        return onTypeError;", "      }", "    }", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_returnOfInvalidType_subtype() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B extends A {}", "A f(B b) { return b; }"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_returnOfInvalidType_supertype() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B extends A {}", "B f(A a) { return a; }"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_returnOfInvalidType_void() {
    Source source = addSource(EngineTestCase.createSource(["void f1() {}", "void f2() { return; }", "void f3() { return null; }", "void f4() { return g1(); }", "void f5() { return g2(); }", "g1() {}", "void g2() {}", ""]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_returnWithoutValue_noReturnType() {
    Source source = addSource(EngineTestCase.createSource(["f() { return; }"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_returnWithoutValue_void() {
    Source source = addSource(EngineTestCase.createSource(["void f() { return; }"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_staticAccessToInstanceMember_method() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static m() {}", "}", "main() {", "  A.m;", "  A.m();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_staticAccessToInstanceMember_propertyAccess_field() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static var f;", "}", "main() {", "  A.f;", "  A.f = 1;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_staticAccessToInstanceMember_propertyAccess_propertyAccessor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static get f => 42;", "  static set f(x) {}", "}", "main() {", "  A.f;", "  A.f = 1;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_superInInvalidContext() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m() {}", "}", "class B extends A {", "  B() {", "    var v = super.m();", "  }", "  n() {", "    var v = super.m();", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_typeArgumentNotMatchingBounds_const() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B extends A {}", "class G<E extends A> {", "  const G();", "}", "f() { return const G<B>(); }"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_typeArgumentNotMatchingBounds_new() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B extends A {}", "class G<E extends A> {}", "f() { return new G<B>(); }"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_undefinedConstructorInInitializer_explicit_named() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A.named() {}", "}", "class B extends A {", "  B() : super.named();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_undefinedConstructorInInitializer_explicit_unnamed() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A() {}", "}", "class B extends A {", "  B() : super();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_undefinedConstructorInInitializer_hasOptionalParameters() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A([p]) {}", "}", "class B extends A {", "  B();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_undefinedConstructorInInitializer_implicit() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A() {}", "}", "class B extends A {", "  B();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_undefinedConstructorInInitializer_implicit_typedef() {
    Source source = addSource(EngineTestCase.createSource(["class M {}", "typedef A = Object with M;", "class B extends A {", "  B();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_undefinedConstructorInInitializer_redirecting() {
    Source source = addSource(EngineTestCase.createSource(["class Foo {", "  Foo.ctor();", "}", "class Bar extends Foo {", "  Bar() : this.ctor();", "  Bar.ctor() : super.ctor();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_undefinedGetter_noSuchMethod_getter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  noSuchMethod(invocation) {}", "}", "f() {", "  (new A()).g;", "}"]));
    resolve(source);
    assertNoErrors();
  }
  void test_undefinedGetter_noSuchMethod_getter2() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  noSuchMethod(invocation) {}", "}", "class B {", "  A a = new A();", "  m() {", "    a.g;", "  }", "}"]));
    resolve(source);
    assertNoErrors();
  }
  void test_undefinedGetter_typeSubstitution() {
    Source source = addSource(EngineTestCase.createSource(["class A<E> {", "  E element;", "}", "class B extends A<List> {", "  m() {", "    element.last;", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_undefinedIdentifier_hide() {
    Source source = addSource(EngineTestCase.createSource(["library L;", "export 'lib1.dart' hide a;"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["library lib1;"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_undefinedIdentifier_noSuchMethod() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  noSuchMethod(invocation) {}", "  f() {", "    var v = a;", "  }", "}"]));
    resolve(source);
    assertNoErrors();
  }
  void test_undefinedIdentifier_show() {
    Source source = addSource(EngineTestCase.createSource(["library L;", "export 'lib1.dart' show a;"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["library lib1;"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_undefinedMethod_noSuchMethod() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  noSuchMethod(invocation) {}", "}", "f() {", "  (new A()).m();", "}"]));
    resolve(source);
    assertNoErrors();
  }
  void test_undefinedOperator_index() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  operator [](a) {}", "  operator []=(a, b) {}", "}", "f(A a) {", "  a[0];", "  a[0] = 1;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_undefinedOperator_tilde() {
    Source source = addSource(EngineTestCase.createSource(["const A = 3;", "const B = ~((1 << A) - 1);"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_undefinedSetter_noSuchMethod() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  noSuchMethod(invocation) {}", "}", "f() {", "  (new A()).s = 1;", "}"]));
    resolve(source);
    assertNoErrors();
  }
  void test_wrongNumberOfParametersForOperator_index() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  operator []=(a, b) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_wrongNumberOfParametersForOperator_minus() {
    check_wrongNumberOfParametersForOperator("-", "");
    check_wrongNumberOfParametersForOperator("-", "a");
  }
  void test_wrongNumberOfParametersForOperator1() {
    check_wrongNumberOfParametersForOperator1("<");
    check_wrongNumberOfParametersForOperator1(">");
    check_wrongNumberOfParametersForOperator1("<=");
    check_wrongNumberOfParametersForOperator1(">=");
    check_wrongNumberOfParametersForOperator1("+");
    check_wrongNumberOfParametersForOperator1("/");
    check_wrongNumberOfParametersForOperator1("~/");
    check_wrongNumberOfParametersForOperator1("*");
    check_wrongNumberOfParametersForOperator1("%");
    check_wrongNumberOfParametersForOperator1("|");
    check_wrongNumberOfParametersForOperator1("^");
    check_wrongNumberOfParametersForOperator1("&");
    check_wrongNumberOfParametersForOperator1("<<");
    check_wrongNumberOfParametersForOperator1(">>");
    check_wrongNumberOfParametersForOperator1("[]");
  }
  void test_wrongNumberOfParametersForSetter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  set x(a) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void check_wrongNumberOfParametersForOperator(String name, String parameters) {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  operator ${name}(${parameters}) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
    reset();
  }
  void check_wrongNumberOfParametersForOperator1(String name) {
    check_wrongNumberOfParametersForOperator(name, "a");
  }
  static dartSuite() {
    _ut.group('NonErrorResolverTest', () {
      _ut.test('test_ambiguousExport', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_ambiguousExport);
      });
      _ut.test('test_ambiguousExport_combinators_hide', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_ambiguousExport_combinators_hide);
      });
      _ut.test('test_ambiguousExport_combinators_show', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_ambiguousExport_combinators_show);
      });
      _ut.test('test_argumentDefinitionTestNonParameter_formalParameter', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_argumentDefinitionTestNonParameter_formalParameter);
      });
      _ut.test('test_argumentDefinitionTestNonParameter_namedParameter', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_argumentDefinitionTestNonParameter_namedParameter);
      });
      _ut.test('test_argumentDefinitionTestNonParameter_optionalParameter', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_argumentDefinitionTestNonParameter_optionalParameter);
      });
      _ut.test('test_argumentTypeNotAssignable_Object_Function', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_Object_Function);
      });
      _ut.test('test_argumentTypeNotAssignable_classWithCall_Function', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_classWithCall_Function);
      });
      _ut.test('test_argumentTypeNotAssignable_invocation_functionParameter_generic', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_invocation_functionParameter_generic);
      });
      _ut.test('test_argumentTypeNotAssignable_invocation_typedef_generic', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_invocation_typedef_generic);
      });
      _ut.test('test_argumentTypeNotAssignable_typedef_local', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_typedef_local);
      });
      _ut.test('test_argumentTypeNotAssignable_typedef_parameter', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_typedef_parameter);
      });
      _ut.test('test_assignmentToFinal_prefixNegate', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_assignmentToFinal_prefixNegate);
      });
      _ut.test('test_assignmentToFinals_importWithPrefix', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_assignmentToFinals_importWithPrefix);
      });
      _ut.test('test_breakWithoutLabelInSwitch', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_breakWithoutLabelInSwitch);
      });
      _ut.test('test_builtInIdentifierAsType_dynamic', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_builtInIdentifierAsType_dynamic);
      });
      _ut.test('test_caseBlockNotTerminated', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_caseBlockNotTerminated);
      });
      _ut.test('test_caseBlockNotTerminated_lastCase', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_caseBlockNotTerminated_lastCase);
      });
      _ut.test('test_caseExpressionTypeImplementsEquals_Object', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_caseExpressionTypeImplementsEquals_Object);
      });
      _ut.test('test_caseExpressionTypeImplementsEquals_String', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_caseExpressionTypeImplementsEquals_String);
      });
      _ut.test('test_caseExpressionTypeImplementsEquals_int', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_caseExpressionTypeImplementsEquals_int);
      });
      _ut.test('test_concreteClassWithAbstractMember', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_concreteClassWithAbstractMember);
      });
      _ut.test('test_conflictingInstanceGetterAndSuperclassMember_instance', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_conflictingInstanceGetterAndSuperclassMember_instance);
      });
      _ut.test('test_conflictingStaticGetterAndInstanceSetter_thisClass', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_conflictingStaticGetterAndInstanceSetter_thisClass);
      });
      _ut.test('test_conflictingStaticSetterAndInstanceMember_thisClass_method', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_conflictingStaticSetterAndInstanceMember_thisClass_method);
      });
      _ut.test('test_constConstructorWithNonFinalField_finalInstanceVar', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_constConstructorWithNonFinalField_finalInstanceVar);
      });
      _ut.test('test_constConstructorWithNonFinalField_mixin', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_constConstructorWithNonFinalField_mixin);
      });
      _ut.test('test_constConstructorWithNonFinalField_static', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_constConstructorWithNonFinalField_static);
      });
      _ut.test('test_constConstructorWithNonFinalField_syntheticField', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_constConstructorWithNonFinalField_syntheticField);
      });
      _ut.test('test_constEvalTypeBoolNumString_equal', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_constEvalTypeBoolNumString_equal);
      });
      _ut.test('test_constEvalTypeBoolNumString_notEqual', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_constEvalTypeBoolNumString_notEqual);
      });
      _ut.test('test_constWithNonConstantArgument_literals', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_constWithNonConstantArgument_literals);
      });
      _ut.test('test_constWithTypeParameters_direct', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_constWithTypeParameters_direct);
      });
      _ut.test('test_constWithUndefinedConstructor', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_constWithUndefinedConstructor);
      });
      _ut.test('test_constWithUndefinedConstructorDefault', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_constWithUndefinedConstructorDefault);
      });
      _ut.test('test_defaultValueInFunctionTypeAlias', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_defaultValueInFunctionTypeAlias);
      });
      _ut.test('test_duplicateDefinition_emptyName', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_duplicateDefinition_emptyName);
      });
      _ut.test('test_duplicateDefinition_getter', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_duplicateDefinition_getter);
      });
      _ut.test('test_exportOfNonLibrary_libraryDeclared', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_exportOfNonLibrary_libraryDeclared);
      });
      _ut.test('test_exportOfNonLibrary_libraryNotDeclared', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_exportOfNonLibrary_libraryNotDeclared);
      });
      _ut.test('test_extraPositionalArguments_Function', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_extraPositionalArguments_Function);
      });
      _ut.test('test_extraPositionalArguments_function', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_extraPositionalArguments_function);
      });
      _ut.test('test_extraPositionalArguments_typedef_local', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_extraPositionalArguments_typedef_local);
      });
      _ut.test('test_extraPositionalArguments_typedef_parameter', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_extraPositionalArguments_typedef_parameter);
      });
      _ut.test('test_fieldInitializedByMultipleInitializers', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_fieldInitializedByMultipleInitializers);
      });
      _ut.test('test_fieldInitializedInInitializerAndDeclaration_fieldNotFinal', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_fieldInitializedInInitializerAndDeclaration_fieldNotFinal);
      });
      _ut.test('test_fieldInitializedInInitializerAndDeclaration_finalFieldNotSet', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_fieldInitializedInInitializerAndDeclaration_finalFieldNotSet);
      });
      _ut.test('test_fieldInitializerOutsideConstructor', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_fieldInitializerOutsideConstructor);
      });
      _ut.test('test_fieldInitializerOutsideConstructor_defaultParameters', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_fieldInitializerOutsideConstructor_defaultParameters);
      });
      _ut.test('test_fieldInitializerRedirectingConstructor_super', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_fieldInitializerRedirectingConstructor_super);
      });
      _ut.test('test_finalInitializedInDeclarationAndConstructor_initializer', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_finalInitializedInDeclarationAndConstructor_initializer);
      });
      _ut.test('test_finalInitializedInDeclarationAndConstructor_initializingFormal', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_finalInitializedInDeclarationAndConstructor_initializingFormal);
      });
      _ut.test('test_finalNotInitialized_atDeclaration', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_finalNotInitialized_atDeclaration);
      });
      _ut.test('test_finalNotInitialized_fieldFormal', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_finalNotInitialized_fieldFormal);
      });
      _ut.test('test_finalNotInitialized_initializer', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_finalNotInitialized_initializer);
      });
      _ut.test('test_implicitThisReferenceInInitializer_constructorName', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_implicitThisReferenceInInitializer_constructorName);
      });
      _ut.test('test_implicitThisReferenceInInitializer_prefixedIdentifier', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_implicitThisReferenceInInitializer_prefixedIdentifier);
      });
      _ut.test('test_implicitThisReferenceInInitializer_qualifiedMethodInvocation', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_implicitThisReferenceInInitializer_qualifiedMethodInvocation);
      });
      _ut.test('test_implicitThisReferenceInInitializer_qualifiedPropertyAccess', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_implicitThisReferenceInInitializer_qualifiedPropertyAccess);
      });
      _ut.test('test_implicitThisReferenceInInitializer_staticField_superClass', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_implicitThisReferenceInInitializer_staticField_superClass);
      });
      _ut.test('test_implicitThisReferenceInInitializer_staticField_thisClass', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_implicitThisReferenceInInitializer_staticField_thisClass);
      });
      _ut.test('test_implicitThisReferenceInInitializer_staticGetter', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_implicitThisReferenceInInitializer_staticGetter);
      });
      _ut.test('test_implicitThisReferenceInInitializer_staticMethod', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_implicitThisReferenceInInitializer_staticMethod);
      });
      _ut.test('test_implicitThisReferenceInInitializer_topLevelField', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_implicitThisReferenceInInitializer_topLevelField);
      });
      _ut.test('test_implicitThisReferenceInInitializer_topLevelFunction', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_implicitThisReferenceInInitializer_topLevelFunction);
      });
      _ut.test('test_implicitThisReferenceInInitializer_topLevelGetter', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_implicitThisReferenceInInitializer_topLevelGetter);
      });
      _ut.test('test_implicitThisReferenceInInitializer_typeVariable', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_implicitThisReferenceInInitializer_typeVariable);
      });
      _ut.test('test_importDuplicatedLibraryName', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_importDuplicatedLibraryName);
      });
      _ut.test('test_importOfNonLibrary_libraryDeclared', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_importOfNonLibrary_libraryDeclared);
      });
      _ut.test('test_importOfNonLibrary_libraryNotDeclared', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_importOfNonLibrary_libraryNotDeclared);
      });
      _ut.test('test_inconsistentCaseExpressionTypes', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_inconsistentCaseExpressionTypes);
      });
      _ut.test('test_initializingFormalForNonExistantField', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_initializingFormalForNonExistantField);
      });
      _ut.test('test_invalidAssignment', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidAssignment);
      });
      _ut.test('test_invalidAssignment_compoundAssignment', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidAssignment_compoundAssignment);
      });
      _ut.test('test_invalidAssignment_toDynamic', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidAssignment_toDynamic);
      });
      _ut.test('test_invalidFactoryNameNotAClass', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidFactoryNameNotAClass);
      });
      _ut.test('test_invalidMethodOverrideNamedParamType', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidMethodOverrideNamedParamType);
      });
      _ut.test('test_invalidOverrideDifferentDefaultValues_named', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidOverrideDifferentDefaultValues_named);
      });
      _ut.test('test_invalidOverrideDifferentDefaultValues_positional', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidOverrideDifferentDefaultValues_positional);
      });
      _ut.test('test_invalidOverrideDifferentDefaultValues_positional_changedOrder', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidOverrideDifferentDefaultValues_positional_changedOrder);
      });
      _ut.test('test_invalidOverrideNamed_unorderedNamedParameter', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidOverrideNamed_unorderedNamedParameter);
      });
      _ut.test('test_invalidOverrideReturnType_returnType_interface', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidOverrideReturnType_returnType_interface);
      });
      _ut.test('test_invalidOverrideReturnType_returnType_interface2', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidOverrideReturnType_returnType_interface2);
      });
      _ut.test('test_invalidOverrideReturnType_returnType_mixin', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidOverrideReturnType_returnType_mixin);
      });
      _ut.test('test_invalidOverrideReturnType_returnType_parameterizedTypes', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidOverrideReturnType_returnType_parameterizedTypes);
      });
      _ut.test('test_invalidOverrideReturnType_returnType_sameType', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidOverrideReturnType_returnType_sameType);
      });
      _ut.test('test_invalidOverrideReturnType_returnType_superclass', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidOverrideReturnType_returnType_superclass);
      });
      _ut.test('test_invalidOverrideReturnType_returnType_superclass2', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidOverrideReturnType_returnType_superclass2);
      });
      _ut.test('test_invalidOverrideReturnType_returnType_void', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidOverrideReturnType_returnType_void);
      });
      _ut.test('test_invalidReferenceToThis_constructor', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidReferenceToThis_constructor);
      });
      _ut.test('test_invalidReferenceToThis_instanceMethod', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidReferenceToThis_instanceMethod);
      });
      _ut.test('test_invalidTypeArgumentInConstList', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidTypeArgumentInConstList);
      });
      _ut.test('test_invalidTypeArgumentInConstMap', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidTypeArgumentInConstMap);
      });
      _ut.test('test_invocationOfNonFunction_dynamic', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invocationOfNonFunction_dynamic);
      });
      _ut.test('test_invocationOfNonFunction_getter', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invocationOfNonFunction_getter);
      });
      _ut.test('test_invocationOfNonFunction_localVariable', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invocationOfNonFunction_localVariable);
      });
      _ut.test('test_memberWithClassName_setter', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_memberWithClassName_setter);
      });
      _ut.test('test_misMatchedGetterAndSetterTypes_instance_sameTypes', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_misMatchedGetterAndSetterTypes_instance_sameTypes);
      });
      _ut.test('test_misMatchedGetterAndSetterTypes_instance_unspecifiedGetter', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_misMatchedGetterAndSetterTypes_instance_unspecifiedGetter);
      });
      _ut.test('test_misMatchedGetterAndSetterTypes_instance_unspecifiedSetter', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_misMatchedGetterAndSetterTypes_instance_unspecifiedSetter);
      });
      _ut.test('test_misMatchedGetterAndSetterTypes_topLevel_sameTypes', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_misMatchedGetterAndSetterTypes_topLevel_sameTypes);
      });
      _ut.test('test_misMatchedGetterAndSetterTypes_topLevel_unspecifiedGetter', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_misMatchedGetterAndSetterTypes_topLevel_unspecifiedGetter);
      });
      _ut.test('test_misMatchedGetterAndSetterTypes_topLevel_unspecifiedSetter', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_misMatchedGetterAndSetterTypes_topLevel_unspecifiedSetter);
      });
      _ut.test('test_mixinDeclaresConstructor', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_mixinDeclaresConstructor);
      });
      _ut.test('test_mixinDeclaresConstructor_factory', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_mixinDeclaresConstructor_factory);
      });
      _ut.test('test_mixinInheritsFromNotObject_classDeclaration_mixTypedef', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_mixinInheritsFromNotObject_classDeclaration_mixTypedef);
      });
      _ut.test('test_mixinInheritsFromNotObject_typedef_mixTypedef', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_mixinInheritsFromNotObject_typedef_mixTypedef);
      });
      _ut.test('test_multipleSuperInitializers_no', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_multipleSuperInitializers_no);
      });
      _ut.test('test_multipleSuperInitializers_single', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_multipleSuperInitializers_single);
      });
      _ut.test('test_newWithAbstractClass_factory', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_newWithAbstractClass_factory);
      });
      _ut.test('test_newWithUndefinedConstructor', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_newWithUndefinedConstructor);
      });
      _ut.test('test_newWithUndefinedConstructorDefault', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_newWithUndefinedConstructorDefault);
      });
      _ut.test('test_nonBoolExpression_assert_bool', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonBoolExpression_assert_bool);
      });
      _ut.test('test_nonBoolExpression_assert_functionType', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonBoolExpression_assert_functionType);
      });
      _ut.test('test_nonConstCaseExpression', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonConstCaseExpression);
      });
      _ut.test('test_nonConstMapAsExpressionStatement_const', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonConstMapAsExpressionStatement_const);
      });
      _ut.test('test_nonConstMapAsExpressionStatement_notExpressionStatement', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonConstMapAsExpressionStatement_notExpressionStatement);
      });
      _ut.test('test_nonConstMapAsExpressionStatement_typeArguments', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonConstMapAsExpressionStatement_typeArguments);
      });
      _ut.test('test_nonConstValueInInitializer_binary_bool', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonConstValueInInitializer_binary_bool);
      });
      _ut.test('test_nonConstValueInInitializer_binary_dynamic', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonConstValueInInitializer_binary_dynamic);
      });
      _ut.test('test_nonConstValueInInitializer_binary_int', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonConstValueInInitializer_binary_int);
      });
      _ut.test('test_nonConstValueInInitializer_binary_num', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonConstValueInInitializer_binary_num);
      });
      _ut.test('test_nonConstValueInInitializer_field', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonConstValueInInitializer_field);
      });
      _ut.test('test_nonConstValueInInitializer_redirecting', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonConstValueInInitializer_redirecting);
      });
      _ut.test('test_nonConstValueInInitializer_super', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonConstValueInInitializer_super);
      });
      _ut.test('test_nonConstValueInInitializer_unary', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonConstValueInInitializer_unary);
      });
      _ut.test('test_nonConstantDefaultValue_function_named', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonConstantDefaultValue_function_named);
      });
      _ut.test('test_nonConstantDefaultValue_function_positional', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonConstantDefaultValue_function_positional);
      });
      _ut.test('test_nonConstantDefaultValue_inConstructor_named', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonConstantDefaultValue_inConstructor_named);
      });
      _ut.test('test_nonConstantDefaultValue_inConstructor_positional', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonConstantDefaultValue_inConstructor_positional);
      });
      _ut.test('test_nonConstantDefaultValue_method_named', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonConstantDefaultValue_method_named);
      });
      _ut.test('test_nonConstantDefaultValue_method_positional', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonConstantDefaultValue_method_positional);
      });
      _ut.test('test_nonGenerativeConstructor', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonGenerativeConstructor);
      });
      _ut.test('test_nonTypeInCatchClause_isClass', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonTypeInCatchClause_isClass);
      });
      _ut.test('test_nonTypeInCatchClause_isFunctionTypeAlias', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonTypeInCatchClause_isFunctionTypeAlias);
      });
      _ut.test('test_nonTypeInCatchClause_isTypeVariable', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonTypeInCatchClause_isTypeVariable);
      });
      _ut.test('test_nonTypeInCatchClause_noType', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonTypeInCatchClause_noType);
      });
      _ut.test('test_nonVoidReturnForOperator_no', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonVoidReturnForOperator_no);
      });
      _ut.test('test_nonVoidReturnForOperator_void', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonVoidReturnForOperator_void);
      });
      _ut.test('test_nonVoidReturnForSetter_function_no', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonVoidReturnForSetter_function_no);
      });
      _ut.test('test_nonVoidReturnForSetter_function_void', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonVoidReturnForSetter_function_void);
      });
      _ut.test('test_nonVoidReturnForSetter_method_no', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonVoidReturnForSetter_method_no);
      });
      _ut.test('test_nonVoidReturnForSetter_method_void', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonVoidReturnForSetter_method_void);
      });
      _ut.test('test_optionalParameterInOperator_required', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_optionalParameterInOperator_required);
      });
      _ut.test('test_prefixCollidesWithTopLevelMembers', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_prefixCollidesWithTopLevelMembers);
      });
      _ut.test('test_recursiveConstructorRedirect', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_recursiveConstructorRedirect);
      });
      _ut.test('test_recursiveFactoryRedirect', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_recursiveFactoryRedirect);
      });
      _ut.test('test_redirectToInvalidFunctionType', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_redirectToInvalidFunctionType);
      });
      _ut.test('test_redirectToNonConstConstructor', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_redirectToNonConstConstructor);
      });
      _ut.test('test_referenceToDeclaredVariableInInitializer_constructorName', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_referenceToDeclaredVariableInInitializer_constructorName);
      });
      _ut.test('test_referenceToDeclaredVariableInInitializer_methodName', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_referenceToDeclaredVariableInInitializer_methodName);
      });
      _ut.test('test_referenceToDeclaredVariableInInitializer_propertyName', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_referenceToDeclaredVariableInInitializer_propertyName);
      });
      _ut.test('test_rethrowOutsideCatch', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_rethrowOutsideCatch);
      });
      _ut.test('test_returnInGenerativeConstructor', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_returnInGenerativeConstructor);
      });
      _ut.test('test_returnOfInvalidType_dynamic', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_returnOfInvalidType_dynamic);
      });
      _ut.test('test_returnOfInvalidType_subtype', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_returnOfInvalidType_subtype);
      });
      _ut.test('test_returnOfInvalidType_supertype', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_returnOfInvalidType_supertype);
      });
      _ut.test('test_returnOfInvalidType_void', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_returnOfInvalidType_void);
      });
      _ut.test('test_returnWithoutValue_noReturnType', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_returnWithoutValue_noReturnType);
      });
      _ut.test('test_returnWithoutValue_void', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_returnWithoutValue_void);
      });
      _ut.test('test_staticAccessToInstanceMember_method', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_staticAccessToInstanceMember_method);
      });
      _ut.test('test_staticAccessToInstanceMember_propertyAccess_field', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_staticAccessToInstanceMember_propertyAccess_field);
      });
      _ut.test('test_staticAccessToInstanceMember_propertyAccess_propertyAccessor', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_staticAccessToInstanceMember_propertyAccess_propertyAccessor);
      });
      _ut.test('test_superInInvalidContext', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_superInInvalidContext);
      });
      _ut.test('test_typeArgumentNotMatchingBounds_const', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_typeArgumentNotMatchingBounds_const);
      });
      _ut.test('test_typeArgumentNotMatchingBounds_new', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_typeArgumentNotMatchingBounds_new);
      });
      _ut.test('test_undefinedConstructorInInitializer_explicit_named', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_undefinedConstructorInInitializer_explicit_named);
      });
      _ut.test('test_undefinedConstructorInInitializer_explicit_unnamed', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_undefinedConstructorInInitializer_explicit_unnamed);
      });
      _ut.test('test_undefinedConstructorInInitializer_hasOptionalParameters', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_undefinedConstructorInInitializer_hasOptionalParameters);
      });
      _ut.test('test_undefinedConstructorInInitializer_implicit', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_undefinedConstructorInInitializer_implicit);
      });
      _ut.test('test_undefinedConstructorInInitializer_implicit_typedef', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_undefinedConstructorInInitializer_implicit_typedef);
      });
      _ut.test('test_undefinedConstructorInInitializer_redirecting', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_undefinedConstructorInInitializer_redirecting);
      });
      _ut.test('test_undefinedGetter_noSuchMethod_getter', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_undefinedGetter_noSuchMethod_getter);
      });
      _ut.test('test_undefinedGetter_noSuchMethod_getter2', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_undefinedGetter_noSuchMethod_getter2);
      });
      _ut.test('test_undefinedGetter_typeSubstitution', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_undefinedGetter_typeSubstitution);
      });
      _ut.test('test_undefinedIdentifier_hide', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_undefinedIdentifier_hide);
      });
      _ut.test('test_undefinedIdentifier_noSuchMethod', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_undefinedIdentifier_noSuchMethod);
      });
      _ut.test('test_undefinedIdentifier_show', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_undefinedIdentifier_show);
      });
      _ut.test('test_undefinedMethod_noSuchMethod', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_undefinedMethod_noSuchMethod);
      });
      _ut.test('test_undefinedOperator_index', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_undefinedOperator_index);
      });
      _ut.test('test_undefinedOperator_tilde', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_undefinedOperator_tilde);
      });
      _ut.test('test_undefinedSetter_noSuchMethod', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_undefinedSetter_noSuchMethod);
      });
      _ut.test('test_wrongNumberOfParametersForOperator1', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_wrongNumberOfParametersForOperator1);
      });
      _ut.test('test_wrongNumberOfParametersForOperator_index', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_wrongNumberOfParametersForOperator_index);
      });
      _ut.test('test_wrongNumberOfParametersForOperator_minus', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_wrongNumberOfParametersForOperator_minus);
      });
      _ut.test('test_wrongNumberOfParametersForSetter', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_wrongNumberOfParametersForSetter);
      });
    });
  }
}
class LibraryTest extends EngineTestCase {

  /**
   * The error listener to which all errors will be reported.
   */
  GatheringErrorListener _errorListener;

  /**
   * The source factory used to create libraries.
   */
  SourceFactory _sourceFactory;

  /**
   * The analysis context to pass in to all libraries created by the tests.
   */
  AnalysisContextImpl _analysisContext;

  /**
   * The library used by the tests.
   */
  Library _library5;
  void setUp() {
    _sourceFactory = new SourceFactory.con2([new FileUriResolver()]);
    _analysisContext = new AnalysisContextImpl();
    _analysisContext.sourceFactory = _sourceFactory;
    _errorListener = new GatheringErrorListener();
    _library5 = library("/lib.dart");
  }
  void test_addExport() {
    Library exportLibrary = library("/exported.dart");
    _library5.addExport(ASTFactory.exportDirective2("exported.dart", []), exportLibrary);
    List<Library> exports = _library5.exports;
    EngineTestCase.assertLength(1, exports);
    JUnitTestCase.assertSame(exportLibrary, exports[0]);
    _errorListener.assertNoErrors();
  }
  void test_addImport() {
    Library importLibrary = library("/imported.dart");
    _library5.addImport(ASTFactory.importDirective2("imported.dart", null, []), importLibrary);
    List<Library> imports = _library5.imports;
    EngineTestCase.assertLength(1, imports);
    JUnitTestCase.assertSame(importLibrary, imports[0]);
    _errorListener.assertNoErrors();
  }
  void test_getExplicitlyImportsCore() {
    JUnitTestCase.assertFalse(_library5.explicitlyImportsCore);
    _errorListener.assertNoErrors();
  }
  void test_getExport() {
    ExportDirective directive = ASTFactory.exportDirective2("exported.dart", []);
    Library exportLibrary = library("/exported.dart");
    _library5.addExport(directive, exportLibrary);
    JUnitTestCase.assertSame(exportLibrary, _library5.getExport(directive));
    _errorListener.assertNoErrors();
  }
  void test_getExports() {
    EngineTestCase.assertLength(0, _library5.exports);
    _errorListener.assertNoErrors();
  }
  void test_getImport() {
    ImportDirective directive = ASTFactory.importDirective2("imported.dart", null, []);
    Library importLibrary = library("/imported.dart");
    _library5.addImport(directive, importLibrary);
    JUnitTestCase.assertSame(importLibrary, _library5.getImport(directive));
    _errorListener.assertNoErrors();
  }
  void test_getImports() {
    EngineTestCase.assertLength(0, _library5.imports);
    _errorListener.assertNoErrors();
  }
  void test_getImportsAndExports() {
    _library5.addImport(ASTFactory.importDirective2("imported.dart", null, []), library("/imported.dart"));
    _library5.addExport(ASTFactory.exportDirective2("exported.dart", []), library("/exported.dart"));
    EngineTestCase.assertLength(2, _library5.importsAndExports);
    _errorListener.assertNoErrors();
  }
  void test_getLibraryScope() {
    LibraryElementImpl element = new LibraryElementImpl(_analysisContext, ASTFactory.libraryIdentifier2(["lib"]));
    element.definingCompilationUnit = new CompilationUnitElementImpl("lib.dart");
    _library5.libraryElement = element;
    JUnitTestCase.assertNotNull(_library5.libraryScope);
    _errorListener.assertNoErrors();
  }
  void test_getLibrarySource() {
    JUnitTestCase.assertNotNull(_library5.librarySource);
  }
  void test_setExplicitlyImportsCore() {
    _library5.explicitlyImportsCore = true;
    JUnitTestCase.assertTrue(_library5.explicitlyImportsCore);
    _errorListener.assertNoErrors();
  }
  void test_setLibraryElement() {
    LibraryElementImpl element = new LibraryElementImpl(_analysisContext, ASTFactory.libraryIdentifier2(["lib"]));
    _library5.libraryElement = element;
    JUnitTestCase.assertSame(element, _library5.libraryElement);
  }
  Library library(String definingCompilationUnitPath) => new Library(_analysisContext, _errorListener, new FileBasedSource.con1(_sourceFactory.contentCache, FileUtilities2.createFile(definingCompilationUnitPath)));
  static dartSuite() {
    _ut.group('LibraryTest', () {
      _ut.test('test_addExport', () {
        final __test = new LibraryTest();
        runJUnitTest(__test, __test.test_addExport);
      });
      _ut.test('test_addImport', () {
        final __test = new LibraryTest();
        runJUnitTest(__test, __test.test_addImport);
      });
      _ut.test('test_getExplicitlyImportsCore', () {
        final __test = new LibraryTest();
        runJUnitTest(__test, __test.test_getExplicitlyImportsCore);
      });
      _ut.test('test_getExport', () {
        final __test = new LibraryTest();
        runJUnitTest(__test, __test.test_getExport);
      });
      _ut.test('test_getExports', () {
        final __test = new LibraryTest();
        runJUnitTest(__test, __test.test_getExports);
      });
      _ut.test('test_getImport', () {
        final __test = new LibraryTest();
        runJUnitTest(__test, __test.test_getImport);
      });
      _ut.test('test_getImports', () {
        final __test = new LibraryTest();
        runJUnitTest(__test, __test.test_getImports);
      });
      _ut.test('test_getImportsAndExports', () {
        final __test = new LibraryTest();
        runJUnitTest(__test, __test.test_getImportsAndExports);
      });
      _ut.test('test_getLibraryScope', () {
        final __test = new LibraryTest();
        runJUnitTest(__test, __test.test_getLibraryScope);
      });
      _ut.test('test_getLibrarySource', () {
        final __test = new LibraryTest();
        runJUnitTest(__test, __test.test_getLibrarySource);
      });
      _ut.test('test_setExplicitlyImportsCore', () {
        final __test = new LibraryTest();
        runJUnitTest(__test, __test.test_setExplicitlyImportsCore);
      });
      _ut.test('test_setLibraryElement', () {
        final __test = new LibraryTest();
        runJUnitTest(__test, __test.test_setLibraryElement);
      });
    });
  }
}
class StaticTypeWarningCodeTest extends ResolverTestCase {
  void fail_inaccessibleSetter() {
    Source source = addSource(EngineTestCase.createSource([]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.INACCESSIBLE_SETTER]);
    verify([source]);
  }
  void fail_nonTypeAsTypeArgument() {
    Source source = addSource(EngineTestCase.createSource(["int A;", "class B<E> {}", "f(B<A> b) {}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT]);
    verify([source]);
  }
  void fail_redirectWithInvalidTypeParameters() {
    Source source = addSource(EngineTestCase.createSource([]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.REDIRECT_WITH_INVALID_TYPE_PARAMETERS]);
    verify([source]);
  }
  void fail_typeArgumentViolatesBounds() {
    Source source = addSource(EngineTestCase.createSource([]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.TYPE_ARGUMENT_VIOLATES_BOUNDS]);
    verify([source]);
  }
  void test_inconsistentMethodInheritance_paramCount() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A {", "  int x();", "}", "abstract class B {", "  int x(int y);", "}", "class C implements A, B {", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE]);
    verify([source]);
  }
  void test_inconsistentMethodInheritance_paramType() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A {", "  x(int i);", "}", "abstract class B {", "  x(String s);", "}", "abstract class C implements A, B {}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE]);
    verify([source]);
  }
  void test_inconsistentMethodInheritance_returnType() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A {", "  int x();", "}", "abstract class B {", "  String x();", "}", "abstract class C implements A, B {}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE]);
    verify([source]);
  }
  void test_invalidAssignment_compoundAssignment() {
    Source source = addSource(EngineTestCase.createSource(["class byte {", "  int _value;", "  byte(this._value);", "  int operator +(int val) {}", "}", "", "void main() {", "  byte b = new byte(52);", "  b += 3;", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }
  void test_invalidAssignment_instanceVariable() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "}", "f() {", "  A a;", "  a.x = '0';", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }
  void test_invalidAssignment_localVariable() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  int x;", "  x = '0';", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }
  void test_invalidAssignment_staticVariable() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static int x;", "}", "f() {", "  A.x = '0';", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }
  void test_invalidAssignment_topLevelVariableDeclaration() {
    Source source = addSource(EngineTestCase.createSource(["int x = 'string';"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }
  void test_invalidAssignment_variableDeclaration() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x = 'string';", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }
  void test_invocationOfNonFunction_class() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void m() {", "    A();", "  }", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION]);
  }
  void test_invocationOfNonFunction_localVariable() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  int x;", "  return x();", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION]);
    verify([source]);
  }
  void test_invocationOfNonFunction_ordinaryInvocation() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static int x;", "}", "class B {", "  m() {", "    A.x();", "  }", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION]);
  }
  void test_invocationOfNonFunction_staticInvocation() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static int get g => 0;", "  f() {", "    A.g();", "  }", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION]);
  }
  void test_nonBoolCondition_conditional() {
    Source source = addSource(EngineTestCase.createSource(["f() { return 3 ? 2 : 1; }"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.NON_BOOL_CONDITION]);
    verify([source]);
  }
  void test_nonBoolCondition_do() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  do {} while (3);", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.NON_BOOL_CONDITION]);
    verify([source]);
  }
  void test_nonBoolCondition_if() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  if (3) return 2; else return 1;", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.NON_BOOL_CONDITION]);
    verify([source]);
  }
  void test_nonBoolCondition_while() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  while (3) {}", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.NON_BOOL_CONDITION]);
    verify([source]);
  }
  void test_nonBoolExpression() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  assert(0);", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.NON_BOOL_EXPRESSION]);
    verify([source]);
  }
  void test_returnOfInvalidType_expressionFunctionBody_function() {
    Source source = addSource(EngineTestCase.createSource(["int f() => '0';"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }
  void test_returnOfInvalidType_expressionFunctionBody_getter() {
    Source source = addSource(EngineTestCase.createSource(["int get g => '0';"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }
  void test_returnOfInvalidType_expressionFunctionBody_localFunction() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  String m() {", "    int f() => '0';", "  }", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }
  void test_returnOfInvalidType_expressionFunctionBody_method() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int f() => '0';", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }
  void test_returnOfInvalidType_expressionFunctionBody_void() {
    Source source = addSource(EngineTestCase.createSource(["void f() => 42;"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }
  void test_returnOfInvalidType_function() {
    Source source = addSource(EngineTestCase.createSource(["int f() { return '0'; }"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }
  void test_returnOfInvalidType_getter() {
    Source source = addSource(EngineTestCase.createSource(["int get g { return '0'; }"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }
  void test_returnOfInvalidType_localFunction() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  String m() {", "    int f() { return '0'; }", "  }", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }
  void test_returnOfInvalidType_method() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int f() { return '0'; }", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }
  void test_returnOfInvalidType_void() {
    Source source = addSource(EngineTestCase.createSource(["void f() { return 42; }"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }
  void test_typeArgumentNotMatchingBounds_const() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B {}", "class G<E extends A> {", "  const G();", "}", "f() { return const G<B>(); }"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }
  void test_typeArgumentNotMatchingBounds_new() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B {}", "class G<E extends A> {}", "f() { return new G<B>(); }"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }
  void test_undefinedFunction() {
    Source source = addSource(EngineTestCase.createSource(["void f() {", "  g();", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_FUNCTION]);
  }
  void test_undefinedGetter() {
    Source source = addSource(EngineTestCase.createSource(["class T {}", "f(T e) { return e.m; }"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_GETTER]);
  }
  void test_undefinedGetter_static() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "var a = A.B;"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_GETTER]);
  }
  void test_undefinedMethod() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void m() {", "    n();", "  }", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_METHOD]);
  }
  void test_undefinedMethod_ignoreTypePropagation() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B extends A {", "  m() {}", "}", "class C {", "f() {", "    A a = new B();", "    a.m();", "  }", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_METHOD]);
  }
  void test_undefinedOperator_indexBoth() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "f(A a) {", "  a[0]++;", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
  void test_undefinedOperator_indexGetter() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "f(A a) {", "  a[0];", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
  void test_undefinedOperator_indexSetter() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "f(A a) {", "  a[0] = 1;", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
  void test_undefinedOperator_plus() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "f(A a) {", "  a + 1;", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
  void test_undefinedSetter() {
    Source source = addSource(EngineTestCase.createSource(["class T {}", "f(T e1) { e1.m = 0; }"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_SETTER]);
  }
  void test_undefinedSetter_static() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "f() { A.B = 0;}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_SETTER]);
  }
  void test_undefinedSuperMethod() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B extends A {", "  m() { return super.m(); }", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_SUPER_METHOD]);
  }
  void test_wrongNumberOfTypeArguments_tooFew() {
    Source source = addSource(EngineTestCase.createSource(["class A<E, F> {}", "A<A> a = null;"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }
  void test_wrongNumberOfTypeArguments_tooMany() {
    Source source = addSource(EngineTestCase.createSource(["class A<E> {}", "A<A, A> a = null;"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }
  static dartSuite() {
    _ut.group('StaticTypeWarningCodeTest', () {
      _ut.test('test_inconsistentMethodInheritance_paramCount', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_inconsistentMethodInheritance_paramCount);
      });
      _ut.test('test_inconsistentMethodInheritance_paramType', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_inconsistentMethodInheritance_paramType);
      });
      _ut.test('test_inconsistentMethodInheritance_returnType', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_inconsistentMethodInheritance_returnType);
      });
      _ut.test('test_invalidAssignment_compoundAssignment', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_invalidAssignment_compoundAssignment);
      });
      _ut.test('test_invalidAssignment_instanceVariable', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_invalidAssignment_instanceVariable);
      });
      _ut.test('test_invalidAssignment_localVariable', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_invalidAssignment_localVariable);
      });
      _ut.test('test_invalidAssignment_staticVariable', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_invalidAssignment_staticVariable);
      });
      _ut.test('test_invalidAssignment_topLevelVariableDeclaration', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_invalidAssignment_topLevelVariableDeclaration);
      });
      _ut.test('test_invalidAssignment_variableDeclaration', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_invalidAssignment_variableDeclaration);
      });
      _ut.test('test_invocationOfNonFunction_class', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_invocationOfNonFunction_class);
      });
      _ut.test('test_invocationOfNonFunction_localVariable', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_invocationOfNonFunction_localVariable);
      });
      _ut.test('test_invocationOfNonFunction_ordinaryInvocation', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_invocationOfNonFunction_ordinaryInvocation);
      });
      _ut.test('test_invocationOfNonFunction_staticInvocation', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_invocationOfNonFunction_staticInvocation);
      });
      _ut.test('test_nonBoolCondition_conditional', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_nonBoolCondition_conditional);
      });
      _ut.test('test_nonBoolCondition_do', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_nonBoolCondition_do);
      });
      _ut.test('test_nonBoolCondition_if', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_nonBoolCondition_if);
      });
      _ut.test('test_nonBoolCondition_while', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_nonBoolCondition_while);
      });
      _ut.test('test_nonBoolExpression', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_nonBoolExpression);
      });
      _ut.test('test_returnOfInvalidType_expressionFunctionBody_function', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_returnOfInvalidType_expressionFunctionBody_function);
      });
      _ut.test('test_returnOfInvalidType_expressionFunctionBody_getter', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_returnOfInvalidType_expressionFunctionBody_getter);
      });
      _ut.test('test_returnOfInvalidType_expressionFunctionBody_localFunction', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_returnOfInvalidType_expressionFunctionBody_localFunction);
      });
      _ut.test('test_returnOfInvalidType_expressionFunctionBody_method', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_returnOfInvalidType_expressionFunctionBody_method);
      });
      _ut.test('test_returnOfInvalidType_expressionFunctionBody_void', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_returnOfInvalidType_expressionFunctionBody_void);
      });
      _ut.test('test_returnOfInvalidType_function', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_returnOfInvalidType_function);
      });
      _ut.test('test_returnOfInvalidType_getter', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_returnOfInvalidType_getter);
      });
      _ut.test('test_returnOfInvalidType_localFunction', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_returnOfInvalidType_localFunction);
      });
      _ut.test('test_returnOfInvalidType_method', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_returnOfInvalidType_method);
      });
      _ut.test('test_returnOfInvalidType_void', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_returnOfInvalidType_void);
      });
      _ut.test('test_typeArgumentNotMatchingBounds_const', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_typeArgumentNotMatchingBounds_const);
      });
      _ut.test('test_typeArgumentNotMatchingBounds_new', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_typeArgumentNotMatchingBounds_new);
      });
      _ut.test('test_undefinedFunction', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_undefinedFunction);
      });
      _ut.test('test_undefinedGetter', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_undefinedGetter);
      });
      _ut.test('test_undefinedGetter_static', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_undefinedGetter_static);
      });
      _ut.test('test_undefinedMethod', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_undefinedMethod);
      });
      _ut.test('test_undefinedMethod_ignoreTypePropagation', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_undefinedMethod_ignoreTypePropagation);
      });
      _ut.test('test_undefinedOperator_indexBoth', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_undefinedOperator_indexBoth);
      });
      _ut.test('test_undefinedOperator_indexGetter', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_undefinedOperator_indexGetter);
      });
      _ut.test('test_undefinedOperator_indexSetter', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_undefinedOperator_indexSetter);
      });
      _ut.test('test_undefinedOperator_plus', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_undefinedOperator_plus);
      });
      _ut.test('test_undefinedSetter', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_undefinedSetter);
      });
      _ut.test('test_undefinedSetter_static', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_undefinedSetter_static);
      });
      _ut.test('test_undefinedSuperMethod', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_undefinedSuperMethod);
      });
      _ut.test('test_wrongNumberOfTypeArguments_tooFew', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_wrongNumberOfTypeArguments_tooFew);
      });
      _ut.test('test_wrongNumberOfTypeArguments_tooMany', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_wrongNumberOfTypeArguments_tooMany);
      });
    });
  }
}
class TypeResolverVisitorTest extends EngineTestCase {

  /**
   * The error listener to which errors will be reported.
   */
  GatheringErrorListener _listener;

  /**
   * The object representing the information about the library in which the types are being
   * resolved.
   */
  Library _library;

  /**
   * The type provider used to access the types.
   */
  TestTypeProvider _typeProvider;

  /**
   * The visitor used to resolve types needed to form the type hierarchy.
   */
  TypeResolverVisitor _visitor;
  void fail_visitConstructorDeclaration() {
    JUnitTestCase.fail("Not yet tested");
    _listener.assertNoErrors();
  }
  void fail_visitFieldFormalParameter_noType() {
    FormalParameter node = ASTFactory.fieldFormalParameter(Keyword.VAR, null, "p");
    JUnitTestCase.assertSame(_typeProvider.dynamicType, resolve6(node, []));
    _listener.assertNoErrors();
  }
  void fail_visitFieldFormalParameter_type() {
    FormalParameter node = ASTFactory.fieldFormalParameter(null, ASTFactory.typeName4("int", []), "p");
    JUnitTestCase.assertSame(_typeProvider.intType, resolve6(node, []));
    _listener.assertNoErrors();
  }
  void fail_visitFunctionDeclaration() {
    JUnitTestCase.fail("Not yet tested");
    _listener.assertNoErrors();
  }
  void fail_visitFunctionTypeAlias() {
    JUnitTestCase.fail("Not yet tested");
    _listener.assertNoErrors();
  }
  void fail_visitFunctionTypedFormalParameter() {
    JUnitTestCase.fail("Not yet tested");
    _listener.assertNoErrors();
  }
  void fail_visitMethodDeclaration() {
    JUnitTestCase.fail("Not yet tested");
    _listener.assertNoErrors();
  }
  void fail_visitVariableDeclaration() {
    JUnitTestCase.fail("Not yet tested");
    ClassElement type = ElementFactory.classElement2("A", []);
    VariableDeclaration node = ASTFactory.variableDeclaration("a");
    ASTFactory.variableDeclarationList(null, ASTFactory.typeName(type, []), [node]);
    JUnitTestCase.assertSame(type.type, node.name.staticType);
    _listener.assertNoErrors();
  }
  void setUp() {
    _listener = new GatheringErrorListener();
    SourceFactory factory = new SourceFactory.con2([new FileUriResolver()]);
    AnalysisContextImpl context = new AnalysisContextImpl();
    context.sourceFactory = factory;
    Source librarySource = new FileBasedSource.con1(factory.contentCache, FileUtilities2.createFile("/lib.dart"));
    _library = new Library(context, _listener, librarySource);
    LibraryElementImpl element = new LibraryElementImpl(context, ASTFactory.libraryIdentifier2(["lib"]));
    element.definingCompilationUnit = new CompilationUnitElementImpl("lib.dart");
    _library.libraryElement = element;
    _typeProvider = new TestTypeProvider();
    _visitor = new TypeResolverVisitor.con1(_library, librarySource, _typeProvider);
  }
  void test_visitCatchClause_exception() {
    CatchClause clause = ASTFactory.catchClause("e", []);
    SimpleIdentifier exceptionParameter = clause.exceptionParameter;
    exceptionParameter.element = new LocalVariableElementImpl(exceptionParameter);
    resolve(clause, _typeProvider.objectType, null, []);
    _listener.assertNoErrors();
  }
  void test_visitCatchClause_exception_stackTrace() {
    CatchClause clause = ASTFactory.catchClause2("e", "s", []);
    SimpleIdentifier exceptionParameter = clause.exceptionParameter;
    exceptionParameter.element = new LocalVariableElementImpl(exceptionParameter);
    SimpleIdentifier stackTraceParameter = clause.stackTraceParameter;
    stackTraceParameter.element = new LocalVariableElementImpl(stackTraceParameter);
    resolve(clause, _typeProvider.objectType, _typeProvider.stackTraceType, []);
    _listener.assertNoErrors();
  }
  void test_visitCatchClause_on_exception() {
    ClassElement exceptionElement = ElementFactory.classElement2("E", []);
    TypeName exceptionType = ASTFactory.typeName(exceptionElement, []);
    CatchClause clause = ASTFactory.catchClause4(exceptionType, "e", []);
    SimpleIdentifier exceptionParameter = clause.exceptionParameter;
    exceptionParameter.element = new LocalVariableElementImpl(exceptionParameter);
    resolve(clause, exceptionElement.type, null, [exceptionElement]);
    _listener.assertNoErrors();
  }
  void test_visitCatchClause_on_exception_stackTrace() {
    ClassElement exceptionElement = ElementFactory.classElement2("E", []);
    TypeName exceptionType = ASTFactory.typeName(exceptionElement, []);
    ((exceptionType.name as SimpleIdentifier)).element = exceptionElement;
    CatchClause clause = ASTFactory.catchClause5(exceptionType, "e", "s", []);
    SimpleIdentifier exceptionParameter = clause.exceptionParameter;
    exceptionParameter.element = new LocalVariableElementImpl(exceptionParameter);
    SimpleIdentifier stackTraceParameter = clause.stackTraceParameter;
    stackTraceParameter.element = new LocalVariableElementImpl(stackTraceParameter);
    resolve(clause, exceptionElement.type, _typeProvider.stackTraceType, [exceptionElement]);
    _listener.assertNoErrors();
  }
  void test_visitClassDeclaration() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement2("B", []);
    ClassElement elementC = ElementFactory.classElement2("C", []);
    ClassElement elementD = ElementFactory.classElement2("D", []);
    ExtendsClause extendsClause = ASTFactory.extendsClause(ASTFactory.typeName(elementB, []));
    WithClause withClause = ASTFactory.withClause([ASTFactory.typeName(elementC, [])]);
    ImplementsClause implementsClause = ASTFactory.implementsClause([ASTFactory.typeName(elementD, [])]);
    ClassDeclaration declaration = ASTFactory.classDeclaration(null, "A", null, extendsClause, withClause, implementsClause, []);
    declaration.name.element = elementA;
    resolveNode(declaration, [elementA, elementB, elementC, elementD]);
    JUnitTestCase.assertSame(elementB.type, elementA.supertype);
    List<InterfaceType> mixins = elementA.mixins;
    EngineTestCase.assertLength(1, mixins);
    JUnitTestCase.assertSame(elementC.type, mixins[0]);
    List<InterfaceType> interfaces = elementA.interfaces;
    EngineTestCase.assertLength(1, interfaces);
    JUnitTestCase.assertSame(elementD.type, interfaces[0]);
    _listener.assertNoErrors();
  }
  void test_visitClassTypeAlias() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement2("B", []);
    ClassElement elementC = ElementFactory.classElement2("C", []);
    ClassElement elementD = ElementFactory.classElement2("D", []);
    WithClause withClause = ASTFactory.withClause([ASTFactory.typeName(elementC, [])]);
    ImplementsClause implementsClause = ASTFactory.implementsClause([ASTFactory.typeName(elementD, [])]);
    ClassTypeAlias alias = ASTFactory.classTypeAlias("A", null, null, ASTFactory.typeName(elementB, []), withClause, implementsClause);
    alias.name.element = elementA;
    resolveNode(alias, [elementA, elementB, elementC, elementD]);
    JUnitTestCase.assertSame(elementB.type, elementA.supertype);
    List<InterfaceType> mixins = elementA.mixins;
    EngineTestCase.assertLength(1, mixins);
    JUnitTestCase.assertSame(elementC.type, mixins[0]);
    List<InterfaceType> interfaces = elementA.interfaces;
    EngineTestCase.assertLength(1, interfaces);
    JUnitTestCase.assertSame(elementD.type, interfaces[0]);
    _listener.assertNoErrors();
  }
  void test_visitSimpleFormalParameter_noType() {
    FormalParameter node = ASTFactory.simpleFormalParameter3("p");
    node.identifier.element = new ParameterElementImpl(ASTFactory.identifier3("p"));
    JUnitTestCase.assertSame(_typeProvider.dynamicType, resolve6(node, []));
    _listener.assertNoErrors();
  }
  void test_visitSimpleFormalParameter_type() {
    InterfaceType intType = _typeProvider.intType;
    ClassElement intElement = intType.element;
    FormalParameter node = ASTFactory.simpleFormalParameter4(ASTFactory.typeName(intElement, []), "p");
    SimpleIdentifier identifier = node.identifier;
    ParameterElementImpl element = new ParameterElementImpl(identifier);
    identifier.element = element;
    JUnitTestCase.assertSame(intType, resolve6(node, [intElement]));
    _listener.assertNoErrors();
  }
  void test_visitTypeName_noParameters_noArguments() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    TypeName typeName = ASTFactory.typeName(classA, []);
    typeName.type = null;
    resolveNode(typeName, [classA]);
    JUnitTestCase.assertSame(classA.type, typeName.type);
    _listener.assertNoErrors();
  }
  void test_visitTypeName_parameters_arguments() {
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    ClassElement classB = ElementFactory.classElement2("B", []);
    TypeName typeName = ASTFactory.typeName(classA, [ASTFactory.typeName(classB, [])]);
    typeName.type = null;
    resolveNode(typeName, [classA, classB]);
    InterfaceType resultType = typeName.type as InterfaceType;
    JUnitTestCase.assertSame(classA, resultType.element);
    List<Type2> resultArguments = resultType.typeArguments;
    EngineTestCase.assertLength(1, resultArguments);
    JUnitTestCase.assertSame(classB.type, resultArguments[0]);
    _listener.assertNoErrors();
  }
  void test_visitTypeName_parameters_noArguments() {
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    TypeName typeName = ASTFactory.typeName(classA, []);
    typeName.type = null;
    resolveNode(typeName, [classA]);
    InterfaceType resultType = typeName.type as InterfaceType;
    JUnitTestCase.assertSame(classA, resultType.element);
    List<Type2> resultArguments = resultType.typeArguments;
    EngineTestCase.assertLength(1, resultArguments);
    JUnitTestCase.assertSame(DynamicTypeImpl.instance, resultArguments[0]);
    _listener.assertNoErrors();
  }
  void test_visitTypeName_void() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    TypeName typeName = ASTFactory.typeName4("void", []);
    resolveNode(typeName, [classA]);
    JUnitTestCase.assertSame(VoidTypeImpl.instance, typeName.type);
    _listener.assertNoErrors();
  }

  /**
   * Analyze the given catch clause and assert that the types of the parameters have been set to the
   * given types. The types can be null if the catch clause does not have the corresponding
   * parameter.
   * @param node the catch clause to be analyzed
   * @param exceptionType the expected type of the exception parameter
   * @param stackTraceType the expected type of the stack trace parameter
   * @param definedElements the elements that are to be defined in the scope in which the element is
   * being resolved
   */
  void resolve(CatchClause node, InterfaceType exceptionType, InterfaceType stackTraceType, List<Element> definedElements) {
    resolveNode(node, definedElements);
    SimpleIdentifier exceptionParameter = node.exceptionParameter;
    if (exceptionParameter != null) {
      JUnitTestCase.assertSame(exceptionType, exceptionParameter.staticType);
    }
    SimpleIdentifier stackTraceParameter = node.stackTraceParameter;
    if (stackTraceParameter != null) {
      JUnitTestCase.assertSame(stackTraceType, stackTraceParameter.staticType);
    }
  }

  /**
   * Return the type associated with the given parameter after the static type analyzer has computed
   * a type for it.
   * @param node the parameter with which the type is associated
   * @param definedElements the elements that are to be defined in the scope in which the element is
   * being resolved
   * @return the type associated with the parameter
   */
  Type2 resolve6(FormalParameter node, List<Element> definedElements) {
    resolveNode(node, definedElements);
    return ((node.identifier.element as ParameterElement)).type;
  }

  /**
   * Return the element associated with the given identifier after the resolver has resolved the
   * identifier.
   * @param node the expression to be resolved
   * @param definedElements the elements that are to be defined in the scope in which the element is
   * being resolved
   * @return the element to which the expression was resolved
   */
  void resolveNode(ASTNode node, List<Element> definedElements) {
    for (Element element in definedElements) {
      _library.libraryScope.define(element);
    }
    node.accept(_visitor);
  }
  static dartSuite() {
    _ut.group('TypeResolverVisitorTest', () {
      _ut.test('test_visitCatchClause_exception', () {
        final __test = new TypeResolverVisitorTest();
        runJUnitTest(__test, __test.test_visitCatchClause_exception);
      });
      _ut.test('test_visitCatchClause_exception_stackTrace', () {
        final __test = new TypeResolverVisitorTest();
        runJUnitTest(__test, __test.test_visitCatchClause_exception_stackTrace);
      });
      _ut.test('test_visitCatchClause_on_exception', () {
        final __test = new TypeResolverVisitorTest();
        runJUnitTest(__test, __test.test_visitCatchClause_on_exception);
      });
      _ut.test('test_visitCatchClause_on_exception_stackTrace', () {
        final __test = new TypeResolverVisitorTest();
        runJUnitTest(__test, __test.test_visitCatchClause_on_exception_stackTrace);
      });
      _ut.test('test_visitClassDeclaration', () {
        final __test = new TypeResolverVisitorTest();
        runJUnitTest(__test, __test.test_visitClassDeclaration);
      });
      _ut.test('test_visitClassTypeAlias', () {
        final __test = new TypeResolverVisitorTest();
        runJUnitTest(__test, __test.test_visitClassTypeAlias);
      });
      _ut.test('test_visitSimpleFormalParameter_noType', () {
        final __test = new TypeResolverVisitorTest();
        runJUnitTest(__test, __test.test_visitSimpleFormalParameter_noType);
      });
      _ut.test('test_visitSimpleFormalParameter_type', () {
        final __test = new TypeResolverVisitorTest();
        runJUnitTest(__test, __test.test_visitSimpleFormalParameter_type);
      });
      _ut.test('test_visitTypeName_noParameters_noArguments', () {
        final __test = new TypeResolverVisitorTest();
        runJUnitTest(__test, __test.test_visitTypeName_noParameters_noArguments);
      });
      _ut.test('test_visitTypeName_parameters_arguments', () {
        final __test = new TypeResolverVisitorTest();
        runJUnitTest(__test, __test.test_visitTypeName_parameters_arguments);
      });
      _ut.test('test_visitTypeName_parameters_noArguments', () {
        final __test = new TypeResolverVisitorTest();
        runJUnitTest(__test, __test.test_visitTypeName_parameters_noArguments);
      });
      _ut.test('test_visitTypeName_void', () {
        final __test = new TypeResolverVisitorTest();
        runJUnitTest(__test, __test.test_visitTypeName_void);
      });
    });
  }
}
class ResolverTestCase extends EngineTestCase {

  /**
   * The source factory used to create [Source sources].
   */
  SourceFactory _sourceFactory;

  /**
   * The analysis context used to parse the compilation units being resolved.
   */
  AnalysisContextImpl _analysisContext;
  void setUp() {
    reset();
  }

  /**
   * Add a source file to the content provider.
   * @param contents the contents to be returned by the content provider for the specified file
   * @return the source object representing the added file
   */
  Source addSource(String contents) => addSource2("/test.dart", contents);

  /**
   * Add a source file to the content provider. The file path should be absolute.
   * @param filePath the path of the file being added
   * @param contents the contents to be returned by the content provider for the specified file
   * @return the source object representing the added file
   */
  Source addSource2(String filePath, String contents) {
    Source source = cacheSource(filePath, contents);
    ChangeSet changeSet = new ChangeSet();
    changeSet.added(source);
    _analysisContext.applyChanges(changeSet);
    return source;
  }

  /**
   * Assert that the number of errors that have been gathered matches the number of errors that are
   * given and that they have the expected error codes. The order in which the errors were gathered
   * is ignored.
   * @param expectedErrorCodes the error codes of the errors that should have been gathered
   * @throws AssertionFailedError if a different number of errors have been gathered than were
   * expected
   */
  void assertErrors(List<ErrorCode> expectedErrorCodes) {
    GatheringErrorListener errorListener = new GatheringErrorListener();
    for (ChangeNotice notice in _analysisContext.performAnalysisTask()) {
      for (AnalysisError error in notice.errors) {
        errorListener.onError(error);
      }
    }
    errorListener.assertErrors2(expectedErrorCodes);
  }

  /**
   * Assert that no errors have been gathered.
   * @throws AssertionFailedError if any errors have been gathered
   */
  void assertNoErrors() {
    GatheringErrorListener errorListener = new GatheringErrorListener();
    for (ChangeNotice notice in _analysisContext.performAnalysisTask()) {
      for (AnalysisError error in notice.errors) {
        errorListener.onError(error);
      }
    }
    errorListener.assertNoErrors();
  }

  /**
   * Cache the source file content in the source factory but don't add the source to the analysis
   * context. The file path should be absolute.
   * @param filePath the path of the file being cached
   * @param contents the contents to be returned by the content provider for the specified file
   * @return the source object representing the cached file
   */
  Source cacheSource(String filePath, String contents) {
    Source source = new FileBasedSource.con1(_sourceFactory.contentCache, FileUtilities2.createFile(filePath));
    _sourceFactory.setContents(source, contents);
    return source;
  }

  /**
   * Create a library element that represents a library named `"test"` containing a single
   * empty compilation unit.
   * @return the library element that was created
   */
  LibraryElementImpl createTestLibrary() => createTestLibrary2(new AnalysisContextImpl(), "test", []);

  /**
   * Create a library element that represents a library with the given name containing a single
   * empty compilation unit.
   * @param libraryName the name of the library to be created
   * @return the library element that was created
   */
  LibraryElementImpl createTestLibrary2(AnalysisContext context, String libraryName, List<String> typeNames) {
    int count = typeNames.length;
    List<CompilationUnitElementImpl> sourcedCompilationUnits = new List<CompilationUnitElementImpl>(count);
    for (int i = 0; i < count; i++) {
      String typeName = typeNames[i];
      ClassElementImpl type = new ClassElementImpl(ASTFactory.identifier3(typeName));
      String fileName = "${typeName}.dart";
      CompilationUnitElementImpl compilationUnit = new CompilationUnitElementImpl(fileName);
      compilationUnit.source = createSource2(fileName);
      compilationUnit.types = <ClassElement> [type];
      sourcedCompilationUnits[i] = compilationUnit;
    }
    String fileName = "${libraryName}.dart";
    CompilationUnitElementImpl compilationUnit = new CompilationUnitElementImpl(fileName);
    compilationUnit.source = createSource2(fileName);
    LibraryElementImpl library = new LibraryElementImpl(context, ASTFactory.libraryIdentifier2([libraryName]));
    library.definingCompilationUnit = compilationUnit;
    library.parts = sourcedCompilationUnits;
    return library;
  }
  AnalysisContext get analysisContext => _analysisContext;
  SourceFactory get sourceFactory => _sourceFactory;

  /**
   * Return a type provider that can be used to test the results of resolution.
   * @return a type provider
   */
  TypeProvider get typeProvider {
    Source coreSource = _analysisContext.sourceFactory.forUri(DartSdk.DART_CORE);
    LibraryElement coreElement = _analysisContext.getLibraryElement(coreSource);
    return new TypeProviderImpl(coreElement);
  }

  /**
   * In the rare cases we want to group several tests into single "test_" method, so need a way to
   * reset test instance to reuse it.
   */
  void reset() {
    _analysisContext = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _analysisContext.sourceFactory;
  }

  /**
   * Given a library and all of its parts, resolve the contents of the library and the contents of
   * the parts. This assumes that the sources for the library and its parts have already been added
   * to the content provider using the method [addSource].
   * @param librarySource the source for the compilation unit that defines the library
   * @return the element representing the resolved library
   * @throws AnalysisException if the analysis could not be performed
   */
  LibraryElement resolve(Source librarySource) => _analysisContext.computeLibraryElement(librarySource);

  /**
   * Return the resolved compilation unit corresponding to the given source in the given library.
   * @param source the source of the compilation unit to be returned
   * @param library the library in which the compilation unit is to be resolved
   * @return the resolved compilation unit
   * @throws Exception if the compilation unit could not be resolved
   */
  CompilationUnit resolveCompilationUnit(Source source, LibraryElement library) => _analysisContext.resolveCompilationUnit(source, library);

  /**
   * Verify that all of the identifiers in the compilation units associated with the given sources
   * have been resolved.
   * @param resolvedElementMap a table mapping the AST nodes that have been resolved to the element
   * to which they were resolved
   * @param sources the sources identifying the compilation units to be verified
   * @throws Exception if the contents of the compilation unit cannot be accessed
   */
  void verify(List<Source> sources) {
    ResolutionVerifier verifier = new ResolutionVerifier();
    for (Source source in sources) {
      _analysisContext.parseCompilationUnit(source).accept(verifier);
    }
    verifier.assertResolved();
  }

  /**
   * Create a source object representing a file with the given name and give it an empty content.
   * @param fileName the name of the file for which a source is to be created
   * @return the source that was created
   */
  FileBasedSource createSource2(String fileName) {
    FileBasedSource source = new FileBasedSource.con1(_sourceFactory.contentCache, FileUtilities2.createFile(fileName));
    _sourceFactory.setContents(source, "");
    return source;
  }
  static dartSuite() {
    _ut.group('ResolverTestCase', () {
    });
  }
}
class TypeProviderImplTest extends EngineTestCase {
  void test_creation() {
    InterfaceType objectType = classElement("Object", null, []).type;
    InterfaceType boolType = classElement("bool", objectType, []).type;
    InterfaceType numType = classElement("num", objectType, []).type;
    InterfaceType doubleType = classElement("double", numType, []).type;
    InterfaceType functionType = classElement("Function", objectType, []).type;
    InterfaceType intType = classElement("int", numType, []).type;
    InterfaceType listType = classElement("List", objectType, ["E"]).type;
    InterfaceType mapType = classElement("Map", objectType, ["K", "V"]).type;
    InterfaceType stackTraceType = classElement("StackTrace", objectType, []).type;
    InterfaceType stringType = classElement("String", objectType, []).type;
    InterfaceType typeType = classElement("Type", objectType, []).type;
    CompilationUnitElementImpl unit = new CompilationUnitElementImpl("lib.dart");
    unit.types = <ClassElement> [boolType.element, doubleType.element, functionType.element, intType.element, listType.element, mapType.element, objectType.element, stackTraceType.element, stringType.element, typeType.element];
    LibraryElementImpl library = new LibraryElementImpl(new AnalysisContextImpl(), ASTFactory.libraryIdentifier2(["lib"]));
    library.definingCompilationUnit = unit;
    TypeProviderImpl provider = new TypeProviderImpl(library);
    JUnitTestCase.assertSame(boolType, provider.boolType);
    JUnitTestCase.assertNotNull(provider.bottomType);
    JUnitTestCase.assertSame(doubleType, provider.doubleType);
    JUnitTestCase.assertNotNull(provider.dynamicType);
    JUnitTestCase.assertSame(functionType, provider.functionType);
    JUnitTestCase.assertSame(intType, provider.intType);
    JUnitTestCase.assertSame(listType, provider.listType);
    JUnitTestCase.assertSame(mapType, provider.mapType);
    JUnitTestCase.assertSame(objectType, provider.objectType);
    JUnitTestCase.assertSame(stackTraceType, provider.stackTraceType);
    JUnitTestCase.assertSame(stringType, provider.stringType);
    JUnitTestCase.assertSame(typeType, provider.typeType);
  }
  ClassElement classElement(String typeName, InterfaceType superclassType, List<String> parameterNames) {
    ClassElementImpl element = new ClassElementImpl(ASTFactory.identifier3(typeName));
    element.supertype = superclassType;
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(element);
    element.type = type;
    int count = parameterNames.length;
    if (count > 0) {
      List<TypeVariableElementImpl> typeVariables = new List<TypeVariableElementImpl>(count);
      List<TypeVariableTypeImpl> typeArguments = new List<TypeVariableTypeImpl>(count);
      for (int i = 0; i < count; i++) {
        TypeVariableElementImpl variable = new TypeVariableElementImpl(ASTFactory.identifier3(parameterNames[i]));
        typeVariables[i] = variable;
        typeArguments[i] = new TypeVariableTypeImpl(variable);
        variable.type = typeArguments[i];
      }
      element.typeVariables = typeVariables;
      type.typeArguments = typeArguments;
    }
    return element;
  }
  static dartSuite() {
    _ut.group('TypeProviderImplTest', () {
      _ut.test('test_creation', () {
        final __test = new TypeProviderImplTest();
        runJUnitTest(__test, __test.test_creation);
      });
    });
  }
}
class InheritanceManagerTest extends EngineTestCase {

  /**
   * The type provider used to access the types.
   */
  TestTypeProvider _typeProvider;

  /**
   * The library containing the code being resolved.
   */
  LibraryElementImpl _definingLibrary;

  /**
   * The inheritance manager being tested.
   */
  InheritanceManager _inheritanceManager;
  void setUp() {
    _typeProvider = new TestTypeProvider();
    _inheritanceManager = createInheritanceManager();
  }
  void test_lookupInheritance_interface_getter() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String getterName = "g";
    PropertyAccessorElement getterG = ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement> [getterG];
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    classB.interfaces = <InterfaceType> [classA.type];
    JUnitTestCase.assertSame(getterG, _inheritanceManager.lookupInheritance(classB, getterName));
    assertNoErrors(classA);
    assertNoErrors(classB);
  }
  void test_lookupInheritance_interface_method() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement methodM = ElementFactory.methodElement(methodName, _typeProvider.intType, []);
    classA.methods = <MethodElement> [methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    classB.interfaces = <InterfaceType> [classA.type];
    JUnitTestCase.assertSame(methodM, _inheritanceManager.lookupInheritance(classB, methodName));
    assertNoErrors(classA);
    assertNoErrors(classB);
  }
  void test_lookupInheritance_interface_setter() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String setterName = "s";
    PropertyAccessorElement setterS = ElementFactory.setterElement(setterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement> [setterS];
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    classB.interfaces = <InterfaceType> [classA.type];
    JUnitTestCase.assertSame(setterS, _inheritanceManager.lookupInheritance(classB, "${setterName}="));
    assertNoErrors(classA);
    assertNoErrors(classB);
  }
  void test_lookupInheritance_interface_staticMember() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement methodM = ElementFactory.methodElement(methodName, _typeProvider.intType, []);
    ((methodM as MethodElementImpl)).static = true;
    classA.methods = <MethodElement> [methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    classB.interfaces = <InterfaceType> [classA.type];
    JUnitTestCase.assertNull(_inheritanceManager.lookupInheritance(classB, methodName));
    assertNoErrors(classA);
    assertNoErrors(classB);
  }
  void test_lookupInheritance_interfaces_infiniteLoop() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    classA.interfaces = <InterfaceType> [classA.type];
    JUnitTestCase.assertNull(_inheritanceManager.lookupInheritance(classA, "name"));
    assertNoErrors(classA);
  }
  void test_lookupInheritance_interfaces_infiniteLoop2() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    classA.interfaces = <InterfaceType> [classB.type];
    classB.interfaces = <InterfaceType> [classA.type];
    JUnitTestCase.assertNull(_inheritanceManager.lookupInheritance(classA, "name"));
    assertNoErrors(classA);
    assertNoErrors(classB);
  }
  void test_lookupInheritance_interfaces_STWC_inconsistentMethodInheritance() {
    ClassElementImpl classI1 = ElementFactory.classElement2("I1", []);
    String methodName = "m";
    MethodElement methodM1 = ElementFactory.methodElement(methodName, null, [_typeProvider.intType]);
    classI1.methods = <MethodElement> [methodM1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2", []);
    MethodElement methodM2 = ElementFactory.methodElement(methodName, null, [_typeProvider.stringType]);
    classI2.methods = <MethodElement> [methodM2];
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    classA.interfaces = <InterfaceType> [classI1.type, classI2.type];
    JUnitTestCase.assertNull(_inheritanceManager.lookupInheritance(classA, methodName));
    assertNoErrors(classI1);
    assertNoErrors(classI2);
    assertErrors(classA, [StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE]);
  }
  void test_lookupInheritance_interfaces_SWC_inconsistentMethodInheritance() {
    ClassElementImpl classI1 = ElementFactory.classElement2("I1", []);
    String methodName = "m";
    MethodElement methodM = ElementFactory.methodElement(methodName, _typeProvider.intType, []);
    classI1.methods = <MethodElement> [methodM];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2", []);
    PropertyAccessorElement getter = ElementFactory.getterElement(methodName, false, _typeProvider.intType);
    classI2.accessors = <PropertyAccessorElement> [getter];
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    classA.interfaces = <InterfaceType> [classI1.type, classI2.type];
    JUnitTestCase.assertNull(_inheritanceManager.lookupInheritance(classA, methodName));
    assertNoErrors(classI1);
    assertNoErrors(classI2);
    assertErrors(classA, [StaticWarningCode.INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD]);
  }
  void test_lookupInheritance_interfaces_union1() {
    ClassElementImpl classI1 = ElementFactory.classElement2("I1", []);
    String methodName1 = "m1";
    MethodElement methodM1 = ElementFactory.methodElement(methodName1, _typeProvider.intType, []);
    classI1.methods = <MethodElement> [methodM1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2", []);
    String methodName2 = "m2";
    MethodElement methodM2 = ElementFactory.methodElement(methodName2, _typeProvider.intType, []);
    classI2.methods = <MethodElement> [methodM2];
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    classA.interfaces = <InterfaceType> [classI1.type, classI2.type];
    JUnitTestCase.assertSame(methodM1, _inheritanceManager.lookupInheritance(classA, methodName1));
    JUnitTestCase.assertSame(methodM2, _inheritanceManager.lookupInheritance(classA, methodName2));
    assertNoErrors(classI1);
    assertNoErrors(classI2);
    assertNoErrors(classA);
  }
  void test_lookupInheritance_interfaces_union2() {
    ClassElementImpl classI1 = ElementFactory.classElement2("I1", []);
    String methodName1 = "m1";
    MethodElement methodM1 = ElementFactory.methodElement(methodName1, _typeProvider.intType, []);
    classI1.methods = <MethodElement> [methodM1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2", []);
    String methodName2 = "m2";
    MethodElement methodM2 = ElementFactory.methodElement(methodName2, _typeProvider.intType, []);
    classI2.methods = <MethodElement> [methodM2];
    classI2.interfaces = <InterfaceType> [classI1.type];
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    classA.interfaces = <InterfaceType> [classI2.type];
    JUnitTestCase.assertSame(methodM1, _inheritanceManager.lookupInheritance(classA, methodName1));
    JUnitTestCase.assertSame(methodM2, _inheritanceManager.lookupInheritance(classA, methodName2));
    assertNoErrors(classI1);
    assertNoErrors(classI2);
    assertNoErrors(classA);
  }
  void test_lookupInheritance_mixin_getter() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String getterName = "g";
    PropertyAccessorElement getterG = ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement> [getterG];
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    classB.mixins = <InterfaceType> [classA.type];
    JUnitTestCase.assertSame(getterG, _inheritanceManager.lookupInheritance(classB, getterName));
    assertNoErrors(classA);
    assertNoErrors(classB);
  }
  void test_lookupInheritance_mixin_method() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement methodM = ElementFactory.methodElement(methodName, _typeProvider.intType, []);
    classA.methods = <MethodElement> [methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    classB.mixins = <InterfaceType> [classA.type];
    JUnitTestCase.assertSame(methodM, _inheritanceManager.lookupInheritance(classB, methodName));
    assertNoErrors(classA);
    assertNoErrors(classB);
  }
  void test_lookupInheritance_mixin_setter() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String setterName = "s";
    PropertyAccessorElement setterS = ElementFactory.setterElement(setterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement> [setterS];
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    classB.mixins = <InterfaceType> [classA.type];
    JUnitTestCase.assertSame(setterS, _inheritanceManager.lookupInheritance(classB, "${setterName}="));
    assertNoErrors(classA);
    assertNoErrors(classB);
  }
  void test_lookupInheritance_mixin_staticMember() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement methodM = ElementFactory.methodElement(methodName, _typeProvider.intType, []);
    ((methodM as MethodElementImpl)).static = true;
    classA.methods = <MethodElement> [methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    classB.mixins = <InterfaceType> [classA.type];
    JUnitTestCase.assertNull(_inheritanceManager.lookupInheritance(classB, methodName));
    assertNoErrors(classA);
    assertNoErrors(classB);
  }
  void test_lookupInheritance_noMember() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    JUnitTestCase.assertNull(_inheritanceManager.lookupInheritance(classA, "a"));
    assertNoErrors(classA);
  }
  void test_lookupInheritance_superclass_getter() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String getterName = "g";
    PropertyAccessorElement getterG = ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement> [getterG];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    JUnitTestCase.assertSame(getterG, _inheritanceManager.lookupInheritance(classB, getterName));
    assertNoErrors(classA);
    assertNoErrors(classB);
  }
  void test_lookupInheritance_superclass_infiniteLoop() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    classA.supertype = classA.type;
    JUnitTestCase.assertNull(_inheritanceManager.lookupInheritance(classA, "name"));
    assertNoErrors(classA);
  }
  void test_lookupInheritance_superclass_infiniteLoop2() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    classA.supertype = classB.type;
    classB.supertype = classA.type;
    JUnitTestCase.assertNull(_inheritanceManager.lookupInheritance(classA, "name"));
    assertNoErrors(classA);
    assertNoErrors(classB);
  }
  void test_lookupInheritance_superclass_method() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement methodM = ElementFactory.methodElement(methodName, _typeProvider.intType, []);
    classA.methods = <MethodElement> [methodM];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    JUnitTestCase.assertSame(methodM, _inheritanceManager.lookupInheritance(classB, methodName));
    assertNoErrors(classA);
    assertNoErrors(classB);
  }
  void test_lookupInheritance_superclass_setter() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String setterName = "s";
    PropertyAccessorElement setterS = ElementFactory.setterElement(setterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement> [setterS];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    JUnitTestCase.assertSame(setterS, _inheritanceManager.lookupInheritance(classB, "${setterName}="));
    assertNoErrors(classA);
    assertNoErrors(classB);
  }
  void test_lookupInheritance_superclass_staticMember() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement methodM = ElementFactory.methodElement(methodName, _typeProvider.intType, []);
    ((methodM as MethodElementImpl)).static = true;
    classA.methods = <MethodElement> [methodM];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type, []);
    JUnitTestCase.assertNull(_inheritanceManager.lookupInheritance(classB, methodName));
    assertNoErrors(classA);
    assertNoErrors(classB);
  }
  void test_lookupMember_getter() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String getterName = "g";
    PropertyAccessorElement getterG = ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement> [getterG];
    JUnitTestCase.assertSame(getterG, _inheritanceManager.lookupMember(classA, getterName));
    assertNoErrors(classA);
  }
  void test_lookupMember_getter_static() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String getterName = "g";
    PropertyAccessorElement getterG = ElementFactory.getterElement(getterName, true, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement> [getterG];
    JUnitTestCase.assertNull(_inheritanceManager.lookupMember(classA, getterName));
    assertNoErrors(classA);
  }
  void test_lookupMember_method() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement methodM = ElementFactory.methodElement(methodName, _typeProvider.intType, []);
    classA.methods = <MethodElement> [methodM];
    JUnitTestCase.assertSame(methodM, _inheritanceManager.lookupMember(classA, methodName));
    assertNoErrors(classA);
  }
  void test_lookupMember_method_static() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    MethodElement methodM = ElementFactory.methodElement(methodName, _typeProvider.intType, []);
    ((methodM as MethodElementImpl)).static = true;
    classA.methods = <MethodElement> [methodM];
    JUnitTestCase.assertNull(_inheritanceManager.lookupMember(classA, methodName));
    assertNoErrors(classA);
  }
  void test_lookupMember_noMember() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    JUnitTestCase.assertNull(_inheritanceManager.lookupMember(classA, "a"));
    assertNoErrors(classA);
  }
  void test_lookupMember_setter() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String setterName = "s";
    PropertyAccessorElement setterS = ElementFactory.setterElement(setterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement> [setterS];
    JUnitTestCase.assertSame(setterS, _inheritanceManager.lookupMember(classA, "${setterName}="));
    assertNoErrors(classA);
  }
  void test_lookupMember_setter_static() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String setterName = "s";
    PropertyAccessorElement setterS = ElementFactory.setterElement(setterName, true, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement> [setterS];
    JUnitTestCase.assertNull(_inheritanceManager.lookupMember(classA, setterName));
    assertNoErrors(classA);
  }
  void assertErrors(ClassElement classElt, List<ErrorCode> expectedErrorCodes) {
    GatheringErrorListener errorListener = new GatheringErrorListener();
    Set<AnalysisError> actualErrors = _inheritanceManager.getErrors(classElt);
    if (actualErrors != null) {
      for (AnalysisError error in actualErrors) {
        errorListener.onError(error);
      }
    }
    errorListener.assertErrors2(expectedErrorCodes);
  }
  void assertNoErrors(ClassElement classElt) {
    assertErrors(classElt, []);
  }

  /**
   * Create the inheritance manager used by the tests.
   * @return the inheritance manager that was created
   */
  InheritanceManager createInheritanceManager() {
    AnalysisContextImpl context = AnalysisContextFactory.contextWithCore();
    FileBasedSource source = new FileBasedSource.con1(new ContentCache(), FileUtilities2.createFile("/test.dart"));
    CompilationUnitElementImpl definingCompilationUnit = new CompilationUnitElementImpl("test.dart");
    definingCompilationUnit.source = source;
    _definingLibrary = ElementFactory.library(context, "test");
    _definingLibrary.definingCompilationUnit = definingCompilationUnit;
    return new InheritanceManager(_definingLibrary);
  }
  static dartSuite() {
    _ut.group('InheritanceManagerTest', () {
      _ut.test('test_lookupInheritance_interface_getter', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_interface_getter);
      });
      _ut.test('test_lookupInheritance_interface_method', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_interface_method);
      });
      _ut.test('test_lookupInheritance_interface_setter', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_interface_setter);
      });
      _ut.test('test_lookupInheritance_interface_staticMember', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_interface_staticMember);
      });
      _ut.test('test_lookupInheritance_interfaces_STWC_inconsistentMethodInheritance', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_interfaces_STWC_inconsistentMethodInheritance);
      });
      _ut.test('test_lookupInheritance_interfaces_SWC_inconsistentMethodInheritance', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_interfaces_SWC_inconsistentMethodInheritance);
      });
      _ut.test('test_lookupInheritance_interfaces_infiniteLoop', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_interfaces_infiniteLoop);
      });
      _ut.test('test_lookupInheritance_interfaces_infiniteLoop2', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_interfaces_infiniteLoop2);
      });
      _ut.test('test_lookupInheritance_interfaces_union1', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_interfaces_union1);
      });
      _ut.test('test_lookupInheritance_interfaces_union2', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_interfaces_union2);
      });
      _ut.test('test_lookupInheritance_mixin_getter', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_mixin_getter);
      });
      _ut.test('test_lookupInheritance_mixin_method', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_mixin_method);
      });
      _ut.test('test_lookupInheritance_mixin_setter', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_mixin_setter);
      });
      _ut.test('test_lookupInheritance_mixin_staticMember', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_mixin_staticMember);
      });
      _ut.test('test_lookupInheritance_noMember', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_noMember);
      });
      _ut.test('test_lookupInheritance_superclass_getter', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_superclass_getter);
      });
      _ut.test('test_lookupInheritance_superclass_infiniteLoop', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_superclass_infiniteLoop);
      });
      _ut.test('test_lookupInheritance_superclass_infiniteLoop2', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_superclass_infiniteLoop2);
      });
      _ut.test('test_lookupInheritance_superclass_method', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_superclass_method);
      });
      _ut.test('test_lookupInheritance_superclass_setter', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_superclass_setter);
      });
      _ut.test('test_lookupInheritance_superclass_staticMember', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupInheritance_superclass_staticMember);
      });
      _ut.test('test_lookupMember_getter', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupMember_getter);
      });
      _ut.test('test_lookupMember_getter_static', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupMember_getter_static);
      });
      _ut.test('test_lookupMember_method', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupMember_method);
      });
      _ut.test('test_lookupMember_method_static', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupMember_method_static);
      });
      _ut.test('test_lookupMember_noMember', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupMember_noMember);
      });
      _ut.test('test_lookupMember_setter', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupMember_setter);
      });
      _ut.test('test_lookupMember_setter_static', () {
        final __test = new InheritanceManagerTest();
        runJUnitTest(__test, __test.test_lookupMember_setter_static);
      });
    });
  }
}
class CompileTimeErrorCodeTest extends ResolverTestCase {
  void fail_compileTimeConstantRaisesException() {
    Source source = addSource(EngineTestCase.createSource([]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.COMPILE_TIME_CONSTANT_RAISES_EXCEPTION]);
    verify([source]);
  }
  void fail_constEvalThrowsException() {
    Source source = addSource(EngineTestCase.createSource(["class C {", "  const C();", "}", "f() { return const C(); }"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION]);
    verify([source]);
  }
  void fail_duplicateDefinition() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  int m = 0;", "  m(a) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }
  void fail_duplicateMemberError_classMembers_fields() {
    Source librarySource = addSource(EngineTestCase.createSource(["class A {", "  int a;", "  int a;", "}"]));
    resolve(librarySource);
    assertErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([librarySource]);
  }
  void fail_duplicateMemberError_localFields() {
    Source librarySource = addSource(EngineTestCase.createSource(["class A {", "  m() {", "    int a;", "    int a;", "  }", "}"]));
    resolve(librarySource);
    assertErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([librarySource]);
  }
  void fail_duplicateMemberName() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x = 0;", "  int x() {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.DUPLICATE_MEMBER_NAME]);
    verify([source]);
  }
  void fail_duplicateMemberNameInstanceStatic() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "  static int x;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.DUPLICATE_MEMBER_NAME_INSTANCE_STATIC]);
    verify([source]);
  }
  void fail_extendsOrImplementsDisallowedClass_extends_null() {
    Source source = addSource(EngineTestCase.createSource(["class A extends Null {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
    verify([source]);
  }
  void fail_extendsOrImplementsDisallowedClass_implements_null() {
    Source source = addSource(EngineTestCase.createSource(["class A implements Null {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }
  void fail_invalidOverrideDefaultValue() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m([a = 0]) {}", "}", "class B extends A {", "  m([a = 1]) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_OVERRIDE_DEFAULT_VALUE]);
    verify([source]);
  }
  void fail_mixinDeclaresConstructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A() {}", "}", "class B extends Object mixin A {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR]);
    verify([source]);
  }
  void fail_mixinOfNonClass() {
    Source source = addSource(EngineTestCase.createSource(["var A;", "class B extends Object mixin A {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.MIXIN_OF_NON_CLASS]);
    verify([source]);
  }
  void fail_objectCannotExtendAnotherClass() {
    Source source = addSource(EngineTestCase.createSource([]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.OBJECT_CANNOT_EXTEND_ANOTHER_CLASS]);
    verify([source]);
  }
  void fail_recursiveCompileTimeConstant() {
    Source source = addSource(EngineTestCase.createSource(["const x = y + 1;", "const y = x + 1;"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT]);
    verify([source]);
  }
  void fail_recursiveFunctionTypeAlias_direct() {
    Source source = addSource(EngineTestCase.createSource(["typedef F(F f);"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RECURSIVE_FUNCTION_TYPE_ALIAS]);
    verify([source]);
  }
  void fail_recursiveFunctionTypeAlias_indirect() {
    Source source = addSource(EngineTestCase.createSource(["typedef F(G g);", "typedef G(F f);"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RECURSIVE_FUNCTION_TYPE_ALIAS]);
    verify([source]);
  }
  void fail_reservedWordAsIdentifier() {
    Source source = addSource(EngineTestCase.createSource(["int class = 2;"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RESERVED_WORD_AS_IDENTIFIER]);
    verify([source]);
  }
  void fail_staticTopLevelFunction_topLevel() {
    Source source = addSource(EngineTestCase.createSource(["static f() {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.STATIC_TOP_LEVEL_FUNCTION]);
    verify([source]);
  }
  void fail_staticTopLevelVariable() {
    Source source = addSource(EngineTestCase.createSource(["static int x;"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.STATIC_TOP_LEVEL_VARIABLE]);
    verify([source]);
  }
  void fail_superInitializerInObject() {
    Source source = addSource(EngineTestCase.createSource([]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.SUPER_INITIALIZER_IN_OBJECT]);
    verify([source]);
  }
  void fail_uninitializedFinalField() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final int i;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.UNINITIALIZED_FINAL_FIELD]);
    verify([source]);
  }
  void fail_wrongNumberOfTypeArguments_creation_const_tooFew() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class C<K, V> {}", "f(p) {", "  return const C<A>();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }
  void fail_wrongNumberOfTypeArguments_creation_const_tooMany() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class C<E> {}", "f(p) {", "  return const C<A, A>();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }
  void fail_wrongNumberOfTypeArguments_creation_new_tooFew() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class C<K, V> {}", "f(p) {", "  return new C<A>();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }
  void fail_wrongNumberOfTypeArguments_creation_new_tooMany() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class C<E> {}", "f(p) {", "  return new C<A, A>();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }
  void fail_wrongNumberOfTypeArguments_typeTest_tooFew() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class C<K, V> {}", "f(p) {", "  return p is C<A>;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }
  void fail_wrongNumberOfTypeArguments_typeTest_tooMany() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class C<E> {}", "f(p) {", "  return p is C<A, A>;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }
  void test_ambiguousExport() {
    Source source = addSource(EngineTestCase.createSource(["library L;", "export 'lib1.dart';", "export 'lib2.dart';"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["library lib1;", "class N {}"]));
    addSource2("/lib2.dart", EngineTestCase.createSource(["library lib2;", "class N {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.AMBIGUOUS_EXPORT]);
    verify([source]);
  }
  void test_ambiguousImport_as() {
    Source source = addSource(EngineTestCase.createSource(["import 'lib1.dart';", "import 'lib2.dart';", "f(p) {p as N;}"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["library lib1;", "class N {}"]));
    addSource2("/lib2.dart", EngineTestCase.createSource(["library lib2;", "class N {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.AMBIGUOUS_IMPORT]);
  }
  void test_ambiguousImport_extends() {
    Source source = addSource(EngineTestCase.createSource(["import 'lib1.dart';", "import 'lib2.dart';", "class A extends N {}"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["library lib1;", "class N {}"]));
    addSource2("/lib2.dart", EngineTestCase.createSource(["library lib2;", "class N {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.AMBIGUOUS_IMPORT, CompileTimeErrorCode.EXTENDS_NON_CLASS]);
  }
  void test_ambiguousImport_function() {
    Source source = addSource(EngineTestCase.createSource(["import 'lib1.dart';", "import 'lib2.dart';", "g() { return f(); }"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["library lib1;", "f() {}"]));
    addSource2("/lib2.dart", EngineTestCase.createSource(["library lib2;", "f() {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.AMBIGUOUS_IMPORT, StaticTypeWarningCode.UNDEFINED_FUNCTION]);
  }
  void test_ambiguousImport_implements() {
    Source source = addSource(EngineTestCase.createSource(["import 'lib1.dart';", "import 'lib2.dart';", "class A implements N {}"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["library lib1;", "class N {}"]));
    addSource2("/lib2.dart", EngineTestCase.createSource(["library lib2;", "class N {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.AMBIGUOUS_IMPORT, CompileTimeErrorCode.IMPLEMENTS_NON_CLASS]);
  }
  void test_ambiguousImport_instanceCreation() {
    Source source = addSource(EngineTestCase.createSource(["library L;", "import 'lib1.dart';", "import 'lib2.dart';", "f() {new N();}"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["library lib1;", "class N {}"]));
    addSource2("/lib2.dart", EngineTestCase.createSource(["library lib2;", "class N {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.AMBIGUOUS_IMPORT]);
  }
  void test_ambiguousImport_is() {
    Source source = addSource(EngineTestCase.createSource(["import 'lib1.dart';", "import 'lib2.dart';", "f(p) {p is N;}"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["library lib1;", "class N {}"]));
    addSource2("/lib2.dart", EngineTestCase.createSource(["library lib2;", "class N {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.AMBIGUOUS_IMPORT]);
  }
  void test_ambiguousImport_qualifier() {
    Source source = addSource(EngineTestCase.createSource(["import 'lib1.dart';", "import 'lib2.dart';", "g() { N.FOO; }"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["library lib1;", "class N {}"]));
    addSource2("/lib2.dart", EngineTestCase.createSource(["library lib2;", "class N {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.AMBIGUOUS_IMPORT]);
  }
  void test_ambiguousImport_typeArgument_instanceCreation() {
    Source source = addSource(EngineTestCase.createSource(["import 'lib1.dart';", "import 'lib2.dart';", "class A<T> {}", "f() {new A<N>();}"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["library lib1;", "class N {}"]));
    addSource2("/lib2.dart", EngineTestCase.createSource(["library lib2;", "class N {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.AMBIGUOUS_IMPORT]);
  }
  void test_ambiguousImport_varRead() {
    Source source = addSource(EngineTestCase.createSource(["import 'lib1.dart';", "import 'lib2.dart';", "f() { g(v); }", "g(p) {}"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["library lib1;", "var v;"]));
    addSource2("/lib2.dart", EngineTestCase.createSource(["library lib2;", "var v;"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.AMBIGUOUS_IMPORT]);
  }
  void test_ambiguousImport_varWrite() {
    Source source = addSource(EngineTestCase.createSource(["import 'lib1.dart';", "import 'lib2.dart';", "f() { v = 0; }"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["library lib1;", "var v;"]));
    addSource2("/lib2.dart", EngineTestCase.createSource(["library lib2;", "var v;"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.AMBIGUOUS_IMPORT]);
  }
  void test_argumentDefinitionTestNonParameter() {
    Source source = addSource(EngineTestCase.createSource(["f() {", " var v = 0;", " return ?v;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.ARGUMENT_DEFINITION_TEST_NON_PARAMETER]);
    verify([source]);
  }
  void test_builtInIdentifierAsType() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  typedef x;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, StaticWarningCode.UNDEFINED_CLASS]);
    verify([source]);
  }
  void test_builtInIdentifierAsTypedefName_classTypeAlias() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B {}", "typedef as = A with B;"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME]);
    verify([source]);
  }
  void test_builtInIdentifierAsTypedefName_functionTypeAlias() {
    Source source = addSource(EngineTestCase.createSource(["typedef bool as();"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME]);
    verify([source]);
  }
  void test_builtInIdentifierAsTypeName() {
    Source source = addSource(EngineTestCase.createSource(["class as {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME]);
    verify([source]);
  }
  void test_builtInIdentifierAsTypeVariableName() {
    Source source = addSource(EngineTestCase.createSource(["class A<as> {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME]);
    verify([source]);
  }
  void test_caseExpressionTypeImplementsEquals() {
    Source source = addSource(EngineTestCase.createSource(["class IntWrapper {", "  final int value;", "  const IntWrapper(this.value);", "  bool operator ==(IntWrapper x) {", "    return value == x.value;", "  }", "}", "", "f(IntWrapper a) {", "  switch(a) {", "    case(const IntWrapper(1)) : return 1;", "    default: return 0;", "  }", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }
  void test_conflictingConstructorNameAndMember_field() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "  A.x() {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD]);
    verify([source]);
  }
  void test_conflictingConstructorNameAndMember_method() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  const A.x();", "  void x() {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD]);
    verify([source]);
  }
  void test_constConstructorWithNonFinalField_mixin() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  var a;", "}", "class B extends Object with A {", "  const B();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD]);
    verify([source]);
  }
  void test_constConstructorWithNonFinalField_super() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  var a;", "}", "class B extends A {", "  const B();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD]);
    verify([source]);
  }
  void test_constConstructorWithNonFinalField_this() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "  const A();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD]);
    verify([source]);
  }
  void test_constEvalThrowsException_binaryMinus_null() {
    check_constEvalThrowsException_binary_null("null - 5", false);
    check_constEvalThrowsException_binary_null("5 - null", true);
  }
  void test_constEvalThrowsException_binaryPlus_null() {
    check_constEvalThrowsException_binary_null("null + 5", false);
    check_constEvalThrowsException_binary_null("5 + null", true);
  }
  void test_constEvalThrowsException_unaryBitNot_null() {
    Source source = addSource("const C = ~null;");
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
  void test_constEvalThrowsException_unaryNegated_null() {
    Source source = addSource("const C = -null;");
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
  void test_constEvalThrowsException_unaryNot_null() {
    Source source = addSource("const C = !null;");
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
    verify([source]);
  }
  void test_constEvalTypeBool_binary() {
    check_constEvalTypeBool_withParameter_binary("p && ''");
    check_constEvalTypeBool_withParameter_binary("p || ''");
  }
  void test_constEvalTypeBoolNumString_equal() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  const A();", "}", "class B {", "  final a;", "  const B(num p) : a = p == const A();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING]);
    verify([source]);
  }
  void test_constEvalTypeBoolNumString_notEqual() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  const A();", "}", "class B {", "  final a;", "  const B(String p) : a = p != const A();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING]);
    verify([source]);
  }
  void test_constEvalTypeInt_binary() {
    check_constEvalTypeInt_withParameter_binary("p ^ ''");
    check_constEvalTypeInt_withParameter_binary("p & ''");
    check_constEvalTypeInt_withParameter_binary("p | ''");
    check_constEvalTypeInt_withParameter_binary("p >> ''");
    check_constEvalTypeInt_withParameter_binary("p << ''");
  }
  void test_constEvalTypeNum_binary() {
    check_constEvalTypeNum_withParameter_binary("p + ''");
    check_constEvalTypeNum_withParameter_binary("p - ''");
    check_constEvalTypeNum_withParameter_binary("p * ''");
    check_constEvalTypeNum_withParameter_binary("p / ''");
    check_constEvalTypeNum_withParameter_binary("p ~/ ''");
    check_constEvalTypeNum_withParameter_binary("p > ''");
    check_constEvalTypeNum_withParameter_binary("p < ''");
    check_constEvalTypeNum_withParameter_binary("p >= ''");
    check_constEvalTypeNum_withParameter_binary("p <= ''");
    check_constEvalTypeNum_withParameter_binary("p % ''");
  }
  void test_constFormalParameter_fieldFormalParameter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  var x;", "  A(const this.x) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_FORMAL_PARAMETER]);
    verify([source]);
  }
  void test_constFormalParameter_simpleFormalParameter() {
    Source source = addSource(EngineTestCase.createSource(["f(const x) {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_FORMAL_PARAMETER]);
    verify([source]);
  }
  void test_constInitializedWithNonConstValue() {
    Source source = addSource(EngineTestCase.createSource(["f(p) {", "  const C = p;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
    verify([source]);
  }
  void test_constInitializedWithNonConstValue_missingConstInListLiteral() {
    Source source = addSource("const List L = [0];");
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
    verify([source]);
  }
  void test_constInitializedWithNonConstValue_missingConstInMapLiteral() {
    Source source = addSource("const Map M = {'a' : 0};");
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
    verify([source]);
  }
  void test_constInstanceField() {
    Source source = addSource(EngineTestCase.createSource(["class C {", "  const int f = 0;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_INSTANCE_FIELD]);
    verify([source]);
  }
  void test_constWithInvalidTypeParameters() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  const A();", "}", "f() { return const A<A>(); }"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS]);
    verify([source]);
  }
  void test_constWithNonConst() {
    Source source = addSource(EngineTestCase.createSource(["class T {", "  T(a, b, {c, d}) {}", "}", "f() { return const T(0, 1, c: 2, d: 3); }"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_WITH_NON_CONST]);
    verify([source]);
  }
  void test_constWithNonConstantArgument() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  const A(a);", "}", "f(p) { return const A(p); }"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT]);
    verify([source]);
  }
  void test_constWithNonType() {
    Source source = addSource(EngineTestCase.createSource(["int A;", "f() {", "  return const A();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_WITH_NON_TYPE]);
    verify([source]);
  }
  void test_constWithTypeParameters_direct() {
    Source source = addSource(EngineTestCase.createSource(["class A<T> {", "  static const V = const A<T>();", "  const A();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS]);
    verify([source]);
  }
  void test_constWithTypeParameters_indirect() {
    Source source = addSource(EngineTestCase.createSource(["class A<T> {", "  static const V = const A<List<T>>();", "  const A();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS]);
    verify([source]);
  }
  void test_constWithUndefinedConstructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  const A();", "}", "f() {", "  return const A.noSuchConstructor();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR]);
  }
  void test_constWithUndefinedConstructorDefault() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  const A.name();", "}", "f() {", "  return const A();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT]);
    verify([source]);
  }
  void test_defaultValueInFunctionTypeAlias() {
    Source source = addSource(EngineTestCase.createSource(["typedef F([x = 0]);"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS]);
    verify([source]);
  }
  void test_duplicateConstructorName_named() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A.a() {}", "  A.a() {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME, CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME]);
    verify([source]);
  }
  void test_duplicateConstructorName_unnamed() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A() {}", "  A() {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT]);
    verify([source]);
  }
  void test_duplicateDefinition_parameterWithFunctionName_local() {
    Source source = addSource(EngineTestCase.createSource(["main() {", "  f(f) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION, CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }
  void test_duplicateDefinition_parameterWithFunctionName_topLevel() {
    Source source = addSource(EngineTestCase.createSource(["main() {", "  f(f) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION, CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }
  void test_duplicateMemberError() {
    Source librarySource = addSource2("/lib.dart", EngineTestCase.createSource(["library lib;", "", "part 'a.dart';", "part 'b.dart';"]));
    Source sourceA = addSource2("/a.dart", EngineTestCase.createSource(["part of lib;", "", "class A {}"]));
    Source sourceB = addSource2("/b.dart", EngineTestCase.createSource(["part of lib;", "", "class A {}"]));
    resolve(librarySource);
    assertErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([librarySource, sourceA, sourceB]);
  }
  void test_duplicateMemberError_classMembers_methods() {
    Source librarySource = addSource(EngineTestCase.createSource(["class A {", "  m() {}", "  m() {}", "}"]));
    resolve(librarySource);
    assertErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION, CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([librarySource]);
  }
  void test_duplicateNamedArgument() {
    Source source = addSource(EngineTestCase.createSource(["f({a, b}) {}", "main() {", "  f(a: 1, a: 2);", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT]);
    verify([source]);
  }
  void test_exportInternalLibrary() {
    Source source = addSource(EngineTestCase.createSource(["export 'dart:_interceptors';"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY]);
    verify([source]);
  }
  void test_exportOfNonLibrary() {
    Source source = addSource(EngineTestCase.createSource(["library L;", "export 'lib1.dart';"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["part of lib;"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY]);
    verify([source]);
  }
  void test_extendsNonClass_class() {
    Source source = addSource(EngineTestCase.createSource(["int A;", "class B extends A {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.EXTENDS_NON_CLASS]);
    verify([source]);
  }
  void test_extendsOrImplementsDisallowedClass_extends_bool() {
    Source source = addSource(EngineTestCase.createSource(["class A extends bool {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, StaticWarningCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }
  void test_extendsOrImplementsDisallowedClass_extends_double() {
    Source source = addSource(EngineTestCase.createSource(["class A extends double {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, StaticWarningCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }
  void test_extendsOrImplementsDisallowedClass_extends_int() {
    Source source = addSource(EngineTestCase.createSource(["class A extends int {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, StaticWarningCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }
  void test_extendsOrImplementsDisallowedClass_extends_num() {
    Source source = addSource(EngineTestCase.createSource(["class A extends num {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, StaticWarningCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }
  void test_extendsOrImplementsDisallowedClass_extends_String() {
    Source source = addSource(EngineTestCase.createSource(["class A extends String {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, StaticWarningCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }
  void test_extendsOrImplementsDisallowedClass_implements_bool() {
    Source source = addSource(EngineTestCase.createSource(["class A implements bool {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }
  void test_extendsOrImplementsDisallowedClass_implements_double() {
    Source source = addSource(EngineTestCase.createSource(["class A implements double {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }
  void test_extendsOrImplementsDisallowedClass_implements_int() {
    Source source = addSource(EngineTestCase.createSource(["class A implements int {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }
  void test_extendsOrImplementsDisallowedClass_implements_num() {
    Source source = addSource(EngineTestCase.createSource(["class A implements num {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }
  void test_extendsOrImplementsDisallowedClass_implements_String() {
    Source source = addSource(EngineTestCase.createSource(["class A implements String {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }
  void test_extraPositionalArguments_const() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  const A();", "}", "main() {", "  const A(0);", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS]);
    verify([source]);
  }
  void test_fieldInitializedByMultipleInitializers() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "  A() : x = 0, x = 1 {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS]);
    verify([source]);
  }
  void test_fieldInitializedByMultipleInitializers_multipleInits() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "  A() : x = 0, x = 1, x = 2 {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS, CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS]);
    verify([source]);
  }
  void test_fieldInitializedByMultipleInitializers_multipleNames() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "  int y;", "  A() : x = 0, x = 1, y = 0, y = 1 {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS, CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS]);
    verify([source]);
  }
  void test_fieldInitializedInInitializerAndDeclaration_final() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final int x = 0;", "  A() : x = 1 {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION]);
    verify([source]);
  }
  void test_fieldInitializedInParameterAndInitializer() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "  A(this.x) : x = 1 {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER]);
    verify([source]);
  }
  void test_fieldInitializerFactoryConstructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "  factory A(this.x) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR]);
    verify([source]);
  }
  void test_fieldInitializerNotAssignable() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final int x;", "  const A() : x = '';", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_fieldInitializerOutsideConstructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "  m(this.x) {}", "}"]));
    resolve(source);
    assertErrors([ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR]);
    verify([source]);
  }
  void test_fieldInitializerOutsideConstructor_defaultParameter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "  m([this.x]) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR]);
    verify([source]);
  }
  void test_fieldInitializerRedirectingConstructor_afterRedirection() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "  A.named() {}", "  A() : this.named(), x = 42;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR]);
    verify([source]);
  }
  void test_fieldInitializerRedirectingConstructor_beforeRedirection() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "  A.named() {}", "  A() : x = 42, this.named();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR]);
    verify([source]);
  }
  void test_fieldInitializingFormalRedirectingConstructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "  A.named() {}", "  A(this.x) : this.named();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR]);
    verify([source]);
  }

  /**
   * This test doesn't test the FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR code, but tests the
   * FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION code instead. It is provided here to show
   * coverage over all of the permutations of initializers in constructor declarations.
   *
   * Note: FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION covers a subset of
   * FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR, since it more specific, we use it instead of
   * the broader code
   */
  void test_finalInitializedInDeclarationAndConstructor_initializers() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final x = 0;", "  A() : x = 0 {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION]);
    verify([source]);
  }
  void test_finalInitializedInDeclarationAndConstructor_initializingFormal() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final x = 0;", "  A(this.x) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR]);
    verify([source]);
  }
  void test_finalInitializedMultipleTimes_initializers() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final x;", "  A() : x = 0, x = 0 {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS]);
    verify([source]);
  }

  /**
   * This test doesn't test the FINAL_INITIALIZED_MULTIPLE_TIMES code, but tests the
   * FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER code instead. It is provided here to show
   * coverage over all of the permutations of initializers in constructor declarations.
   *
   * Note: FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER covers a subset of
   * FINAL_INITIALIZED_MULTIPLE_TIMES, since it more specific, we use it instead of the broader code
   */
  void test_finalInitializedMultipleTimes_initializingFormal_initializer() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final x;", "  A(this.x) : x = 0 {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER]);
    verify([source]);
  }
  void test_finalInitializedMultipleTimes_initializingFormals() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final x;", "  A(this.x, this.x) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.FINAL_INITIALIZED_MULTIPLE_TIMES]);
    verify([source]);
  }
  void test_getterAndMethodWithSameName() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  x(y) {}", "  get x => 0;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.GETTER_AND_METHOD_WITH_SAME_NAME, CompileTimeErrorCode.GETTER_AND_METHOD_WITH_SAME_NAME]);
    verify([source]);
  }
  void test_implementsDynamic() {
    Source source = addSource(EngineTestCase.createSource(["class A implements dynamic {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_DYNAMIC]);
    verify([source]);
  }
  void test_implementsNonClass_class() {
    Source source = addSource(EngineTestCase.createSource(["int A;", "class B implements A {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_NON_CLASS]);
    verify([source]);
  }
  void test_implementsNonClass_typedef() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "int B;", "typedef C = A implements B;"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_NON_CLASS]);
    verify([source]);
  }
  void test_implementsRepeated() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B implements A, A {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_REPEATED]);
    verify([source]);
  }
  void test_implementsRepeated_3times() {
    Source source = addSource(EngineTestCase.createSource(["class A {} class C{}", "class B implements A, A, A, A {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_REPEATED, CompileTimeErrorCode.IMPLEMENTS_REPEATED, CompileTimeErrorCode.IMPLEMENTS_REPEATED]);
    verify([source]);
  }
  void test_implicitThisReferenceInInitializer_field() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  var v;", "  A() : v = f;", "  var f;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
    verify([source]);
  }
  void test_implicitThisReferenceInInitializer_invocation() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  var v;", "  A() : v = f();", "  f() {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
    verify([source]);
  }
  void test_implicitThisReferenceInInitializer_redirectingConstructorInvocation() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A(p) {}", "  A.named() : this(f);", "  var f;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
    verify([source]);
  }
  void test_implicitThisReferenceInInitializer_superConstructorInvocation() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A(p) {}", "}", "class B extends A {", "  B() : super(f);", "  var f;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
    verify([source]);
  }
  void test_importInternalLibrary() {
    Source source = addSource(EngineTestCase.createSource(["import 'dart:_interceptors';"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY]);
    verify([source]);
  }
  void test_importInternalLibrary_collection() {
    Source source = addSource(EngineTestCase.createSource(["import 'dart:_collection-dev';"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY]);
    verify([source]);
  }
  void test_importOfNonLibrary() {
    Source source = addSource(EngineTestCase.createSource(["library lib;", "import 'part.dart';"]));
    addSource2("/part.dart", EngineTestCase.createSource(["part of lib;"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY]);
    verify([source]);
  }
  void test_inconsistentCaseExpressionTypes() {
    Source source = addSource(EngineTestCase.createSource(["f(var p) {", "  switch (p) {", "    case 1:", "      break;", "    case 'a':", "      break;", "  }", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES]);
    verify([source]);
  }
  void test_inconsistentCaseExpressionTypes_repeated() {
    Source source = addSource(EngineTestCase.createSource(["f(var p) {", "  switch (p) {", "    case 1:", "      break;", "    case 'a':", "      break;", "    case 'b':", "      break;", "  }", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES, CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES]);
    verify([source]);
  }
  void test_initializerForNonExistant_initializer() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A() : x = 0 {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTANT_FIELD]);
  }
  void test_initializerForStaticField() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static int x;", "  A() : x = 0 {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD]);
    verify([source]);
  }
  void test_initializingFormalForNonExistantField() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A(this.x) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTANT_FIELD]);
    verify([source]);
  }
  void test_initializingFormalForNonExistantField_notInEnclosingClass() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "int x;", "}", "class B extends A {", "  B(this.x) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTANT_FIELD]);
    verify([source]);
  }
  void test_initializingFormalForNonExistantField_optional() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A([this.x]) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTANT_FIELD]);
    verify([source]);
  }
  void test_initializingFormalForNonExistantField_static() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static int x;", "  A([this.x]) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_STATIC_FIELD]);
    verify([source]);
  }
  void test_invalidConstructorName_notEnclosingClassName() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  B() : super();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME]);
  }
  void test_invalidFactoryNameNotAClass_notClassName() {
    Source source = addSource(EngineTestCase.createSource(["int B;", "class A {", "  factory B() {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS]);
    verify([source]);
  }
  void test_invalidFactoryNameNotAClass_notEnclosingClassName() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  factory B() {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS]);
  }
  void test_invalidOverrideNamed_fewerNamedParameters() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m({a, b}) {}", "}", "class B extends A {", "  m({a}) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_OVERRIDE_NAMED]);
    verify([source]);
  }
  void test_invalidOverrideNamed_missingNamedParameter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m({a, b}) {}", "}", "class B extends A {", "  m({a, c}) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_OVERRIDE_NAMED]);
    verify([source]);
  }
  void test_invalidOverridePositional() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m([a, b]) {}", "}", "class B extends A {", "  m([a]) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_OVERRIDE_POSITIONAL]);
    verify([source]);
  }
  void test_invalidOverrideRequired() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m(a) {}", "}", "class B extends A {", "  m(a, b) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_OVERRIDE_REQUIRED]);
    verify([source]);
  }
  void test_invalidReferenceToThis_factoryConstructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  factory A() { return this; }", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }
  void test_invalidReferenceToThis_instanceVariableInitializer_inConstructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  var f;", "  A() : f = this;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }
  void test_invalidReferenceToThis_instanceVariableInitializer_inDeclaration() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  var f = this;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }
  void test_invalidReferenceToThis_staticMethod() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static m() { return this; }", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }
  void test_invalidReferenceToThis_staticVariableInitializer() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static A f = this;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }
  void test_invalidReferenceToThis_topLevelFunction() {
    Source source = addSource("f() { return this; }");
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }
  void test_invalidReferenceToThis_variableInitializer() {
    Source source = addSource("int x = this;");
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }
  void test_invalidTypeArgumentForKey() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m() {", "    return const <int, int>{};", "  }", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_FOR_KEY]);
    verify([source]);
  }
  void test_invalidTypeArgumentInConstList() {
    Source source = addSource(EngineTestCase.createSource(["class A<E> {", "  m() {", "    return const <E>[];", "  }", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_LIST]);
    verify([source]);
  }
  void test_invalidTypeArgumentInConstMap() {
    Source source = addSource(EngineTestCase.createSource(["class A<E> {", "  m() {", "    return const <String, E>{};", "  }", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP]);
    verify([source]);
  }
  void test_invalidUri_export() {
    Source source = addSource(EngineTestCase.createSource(["export 'ht:';"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_URI]);
  }
  void test_invalidUri_import() {
    Source source = addSource(EngineTestCase.createSource(["import 'ht:';"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_URI]);
  }
  void test_invalidUri_part() {
    Source source = addSource(EngineTestCase.createSource(["part 'ht:';"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.INVALID_URI]);
  }
  void test_labelInOuterScope() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void m(int i) {", "    l: while (i > 0) {", "      void f() {", "        break l;", "      };", "    }", "  }", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.LABEL_IN_OUTER_SCOPE]);
  }
  void test_labelUndefined_break() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  x: while (true) {", "    break y;", "  }", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.LABEL_UNDEFINED]);
  }
  void test_labelUndefined_continue() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  x: while (true) {", "    continue y;", "  }", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.LABEL_UNDEFINED]);
  }
  void test_memberWithClassName_field() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int A = 0;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
    verify([source]);
  }
  void test_memberWithClassName_field2() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int z, A, b = 0;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
    verify([source]);
  }
  void test_memberWithClassName_getter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  get A => 0;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
    verify([source]);
  }
  void test_memberWithClassName_method() {
  }
  void test_methodAndGetterWithSameName() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  get x => 0;", "  x(y) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.METHOD_AND_GETTER_WITH_SAME_NAME, CompileTimeErrorCode.METHOD_AND_GETTER_WITH_SAME_NAME]);
    verify([source]);
  }
  void test_mixinDeclaresConstructor_classDeclaration() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A() {}", "}", "class B extends Object with A {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR]);
    verify([source]);
  }
  void test_mixinDeclaresConstructor_typedef() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A() {}", "}", "typedef B = Object with A;"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR]);
    verify([source]);
  }
  void test_mixinInheritsFromNotObject_classDeclaration_extends() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B extends A {}", "class C extends Object with B {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT]);
    verify([source]);
  }
  void test_mixinInheritsFromNotObject_classDeclaration_with() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B extends Object with A {}", "class C extends Object with B {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT]);
    verify([source]);
  }
  void test_mixinInheritsFromNotObject_typedef_extends() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B extends A {}", "typedef C = Object with B;"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT]);
    verify([source]);
  }
  void test_mixinInheritsFromNotObject_typedef_with() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B extends Object with A {}", "typedef C = Object with B;"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT]);
    verify([source]);
  }
  void test_mixinOfNonClass_class() {
    Source source = addSource(EngineTestCase.createSource(["int A;", "class B extends Object with A {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.MIXIN_OF_NON_CLASS]);
    verify([source]);
  }
  void test_mixinOfNonClass_typedef() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "int B;", "typedef C = A with B;"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.MIXIN_OF_NON_CLASS]);
    verify([source]);
  }
  void test_mixinReferencesSuper() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  toString() => super.toString();", "}", "class B extends Object with A {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.MIXIN_REFERENCES_SUPER]);
    verify([source]);
  }
  void test_mixinWithNonClassSuperclass_class() {
    Source source = addSource(EngineTestCase.createSource(["int A;", "class B {}", "class C extends A with B {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS]);
    verify([source]);
  }
  void test_mixinWithNonClassSuperclass_typedef() {
    Source source = addSource(EngineTestCase.createSource(["int A;", "class B {}", "typedef C = A with B;"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS]);
    verify([source]);
  }
  void test_multipleRedirectingConstructorInvocations() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A() : this.a(), this.b();", "  A.a() {}", "  A.b() {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS]);
    verify([source]);
  }
  void test_multipleSuperInitializers() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B extends A {", "  B() : super(), super() {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.MULTIPLE_SUPER_INITIALIZERS]);
    verify([source]);
  }
  void test_nativeFunctionBodyInNonSDKCode_function() {
    Source source = addSource(EngineTestCase.createSource(["int m(a) native 'string';"]));
    resolve(source);
    assertErrors([ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE]);
    verify([source]);
  }
  void test_nativeFunctionBodyInNonSDKCode_method() {
    Source source = addSource(EngineTestCase.createSource(["class A{", "  static int m(a) native 'string';", "}"]));
    resolve(source);
    assertErrors([ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE]);
    verify([source]);
  }
  void test_newWithInvalidTypeParameters() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "f() { return new A<A>(); }"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NEW_WITH_INVALID_TYPE_PARAMETERS]);
    verify([source]);
  }
  void test_nonConstantDefaultValue_function_named() {
    Source source = addSource(EngineTestCase.createSource(["int y;", "f({x : y}) {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }
  void test_nonConstantDefaultValue_function_positional() {
    Source source = addSource(EngineTestCase.createSource(["int y;", "f([x = y]) {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }
  void test_nonConstantDefaultValue_inConstructor_named() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int y;", "  A({x : y}) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }
  void test_nonConstantDefaultValue_inConstructor_positional() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int y;", "  A([x = y]) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }
  void test_nonConstantDefaultValue_method_named() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int y;", "  m({x : y}) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }
  void test_nonConstantDefaultValue_method_positional() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int y;", "  m([x = y]) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }
  void test_nonConstCaseExpression() {
    Source source = addSource(EngineTestCase.createSource(["f(int p, int q) {", "  switch (p) {", "    case 3 + q:", "      break;", "  }", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION]);
    verify([source]);
  }
  void test_nonConstListElement() {
    Source source = addSource(EngineTestCase.createSource(["f(a) {", "  return const [a];", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT]);
    verify([source]);
  }
  void test_nonConstMapAsExpressionStatement_begin() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  {'a' : 0, 'b' : 1}.length;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT]);
    verify([source]);
  }
  void test_nonConstMapAsExpressionStatement_only() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  {'a' : 0, 'b' : 1};", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT]);
    verify([source]);
  }
  void test_nonConstMapKey() {
    Source source = addSource(EngineTestCase.createSource(["f(a) {", "  return const {a : 0};", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_MAP_KEY]);
    verify([source]);
  }
  void test_nonConstMapValue() {
    Source source = addSource(EngineTestCase.createSource(["f(a) {", "  return const {'a' : a};", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE]);
    verify([source]);
  }
  void test_nonConstValueInInitializer_binary_notBool_left() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final bool a;", "  const A(String p) : a = p && true;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER]);
    verify([source]);
  }
  void test_nonConstValueInInitializer_binary_notBool_right() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final bool a;", "  const A(String p) : a = true && p;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER]);
    verify([source]);
  }
  void test_nonConstValueInInitializer_binary_notInt() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final int a;", "  const A(String p) : a = 5 & p;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER, StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_nonConstValueInInitializer_binary_notNum() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final int a;", "  const A(String p) : a = 5 + p;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER, StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_nonConstValueInInitializer_field() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static int C;", "  final int a;", "  const A() : a = C;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER]);
    verify([source]);
  }
  void test_nonConstValueInInitializer_redirecting() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static var C;", "  const A.named(p);", "  const A() : this.named(C);", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER]);
    verify([source]);
  }
  void test_nonConstValueInInitializer_super() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  const A(p);", "}", "class B extends A {", "  static var C;", "  const B() : super(C);", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER]);
    verify([source]);
  }
  void test_nonGenerativeConstructor_explicit() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  factory A.named() {}", "}", "class B extends A {", "  B() : super.named();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR]);
    verify([source]);
  }
  void test_nonGenerativeConstructor_implicit() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  factory A() {}", "}", "class B extends A {", "  B();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR]);
    verify([source]);
  }
  void test_notEnoughRequiredArguments_const() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  const A(int p);", "}", "main() {", "  const A();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.NOT_ENOUGH_REQUIRED_ARGUMENTS]);
    verify([source]);
  }
  void test_optionalParameterInOperator_named() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  operator +({p}) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR]);
    verify([source]);
  }
  void test_optionalParameterInOperator_positional() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  operator +([p]) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR]);
    verify([source]);
  }
  void test_partOfNonPart() {
    Source source = addSource(EngineTestCase.createSource(["library l1;", "part 'l2.dart';"]));
    addSource2("/l2.dart", EngineTestCase.createSource(["library l2;"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.PART_OF_NON_PART]);
    verify([source]);
  }
  void test_prefixCollidesWithTopLevelMembers_functionTypeAlias() {
    addSource2("/lib.dart", "library lib;");
    Source source = addSource(EngineTestCase.createSource(["import '/lib.dart' as p;", "typedef p();"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER]);
    verify([source]);
  }
  void test_prefixCollidesWithTopLevelMembers_topLevelFunction() {
    addSource2("/lib.dart", "library lib;");
    Source source = addSource(EngineTestCase.createSource(["import '/lib.dart' as p;", "p() {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER]);
    verify([source]);
  }
  void test_prefixCollidesWithTopLevelMembers_topLevelVariable() {
    addSource2("/lib.dart", "library lib;");
    Source source = addSource(EngineTestCase.createSource(["import '/lib.dart' as p;", "var p = null;"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER]);
    verify([source]);
  }
  void test_prefixCollidesWithTopLevelMembers_type() {
    addSource2("/lib.dart", "library lib;");
    Source source = addSource(EngineTestCase.createSource(["import '/lib.dart' as p;", "class p {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER]);
    verify([source]);
  }
  void test_privateOptionalParameter() {
    Source source = addSource(EngineTestCase.createSource(["f({_p : 0}) {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER]);
    verify([source]);
  }
  void test_recursiveConstructorRedirect() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A.a() : this.b();", "  A.b() : this.a();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT, CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT]);
    verify([source]);
  }
  void test_recursiveConstructorRedirect_directSelfReference() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A() : this();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT]);
    verify([source]);
  }
  void test_recursiveFactoryRedirect() {
    Source source = addSource(EngineTestCase.createSource(["class A implements B {", "  factory A() = C;", "}", "class B implements C {", "  factory B() = A;", "}", "class C implements A {", "  factory C() = B;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }
  void test_recursiveFactoryRedirect_directSelfReference() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  factory A() = A;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT]);
    verify([source]);
  }
  void test_recursiveFactoryRedirect_generic() {
    Source source = addSource(EngineTestCase.createSource(["class A<T> implements B<T> {", "  factory A() = C;", "}", "class B<T> implements C<T> {", "  factory B() = A;", "}", "class C<T> implements A<T> {", "  factory C() = B;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }
  void test_recursiveFactoryRedirect_named() {
    Source source = addSource(EngineTestCase.createSource(["class A implements B {", "  factory A.nameA() = C.nameC;", "}", "class B implements C {", "  factory B.nameB() = A.nameA;", "}", "class C implements A {", "  factory C.nameC() = B.nameB;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }

  /**
   * "A" references "C" which has cycle with "B". But we should not report problem for "A" - it is
   * not the part of a cycle.
   */
  void test_recursiveFactoryRedirect_outsideCycle() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  factory A() = C;", "}", "class B implements C {", "  factory B() = C;", "}", "class C implements A, B {", "  factory C() = B;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }
  void test_recursiveInterfaceInheritance_extends() {
    Source source = addSource(EngineTestCase.createSource(["class A extends B {}", "class B extends A {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }
  void test_recursiveInterfaceInheritance_extends_implements() {
    Source source = addSource(EngineTestCase.createSource(["class A extends B {}", "class B implements A {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }
  void test_recursiveInterfaceInheritance_implements() {
    Source source = addSource(EngineTestCase.createSource(["class A implements B {}", "class B implements A {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }
  void test_recursiveInterfaceInheritance_tail() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A implements A {}", "class B implements A {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS]);
    verify([source]);
  }
  void test_recursiveInterfaceInheritance_tail2() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A implements B {}", "abstract class B implements A {}", "class C implements A {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }
  void test_recursiveInterfaceInheritance_tail3() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A implements B {}", "abstract class B implements C {}", "abstract class C implements A {}", "class D implements A {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }
  void test_recursiveInterfaceInheritanceBaseCaseExtends() {
    Source source = addSource(EngineTestCase.createSource(["class A extends A {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS]);
    verify([source]);
  }
  void test_recursiveInterfaceInheritanceBaseCaseImplements() {
    Source source = addSource(EngineTestCase.createSource(["class A implements A {}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS]);
    verify([source]);
  }
  void test_recursiveInterfaceInheritanceBaseCaseImplements_typedef() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class M {}", "typedef B = A with M implements B;"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS]);
    verify([source]);
  }
  void test_redirectToNonConstConstructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A.a() {}", "  const factory A.b() = A.a;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.REDIRECT_TO_NON_CONST_CONSTRUCTOR]);
    verify([source]);
  }
  void test_referenceToDeclaredVariableInInitializer_closure() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  var x = (x) {};", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.REFERENCE_TO_DECLARED_VARIABLE_IN_INITIALIZER]);
    verify([source]);
  }
  void test_referenceToDeclaredVariableInInitializer_getter() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  int x = x + 1;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.REFERENCE_TO_DECLARED_VARIABLE_IN_INITIALIZER]);
    verify([source]);
  }
  void test_referenceToDeclaredVariableInInitializer_setter() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  int x = x++;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.REFERENCE_TO_DECLARED_VARIABLE_IN_INITIALIZER]);
    verify([source]);
  }
  void test_referenceToDeclaredVariableInInitializer_unqualifiedInvocation() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  var x = x();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.REFERENCE_TO_DECLARED_VARIABLE_IN_INITIALIZER]);
    verify([source]);
  }
  void test_rethrowOutsideCatch() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  rethrow;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RETHROW_OUTSIDE_CATCH]);
    verify([source]);
  }
  void test_returnInGenerativeConstructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A() { return 0; }", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR]);
    verify([source]);
  }
  void test_superInInvalidContext_binaryExpression() {
    Source source = addSource(EngineTestCase.createSource(["var v = super + 0;"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
  }
  void test_superInInvalidContext_constructorFieldInitializer() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m() {}", "}", "class B extends A {", "  var f;", "  B() : f = super.m();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
  }
  void test_superInInvalidContext_factoryConstructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m() {}", "}", "class B extends A {", "  factory B() {", "    super.m();", "  }", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
  }
  void test_superInInvalidContext_instanceVariableInitializer() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  var a;", "}", "class B extends A {", " var b = super.a;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
  }
  void test_superInInvalidContext_staticMethod() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static m() {}", "}", "class B extends A {", "  static n() { return super.m(); }", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
  }
  void test_superInInvalidContext_staticVariableInitializer() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static int a = 0;", "}", "class B extends A {", "  static int b = super.a;", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
  }
  void test_superInInvalidContext_topLevelFunction() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  super.f();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
  }
  void test_superInInvalidContext_topLevelVariableInitializer() {
    Source source = addSource(EngineTestCase.createSource(["var v = super.y;"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
  }
  void test_superInRedirectingConstructor_redirectionSuper() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B {", "  B() : this.name(), super();", "  B.name() {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR]);
    verify([source]);
  }
  void test_superInRedirectingConstructor_superRedirection() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B {", "  B() : super(), this.name();", "  B.name() {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR]);
    verify([source]);
  }
  void test_undefinedClass_const() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  return const A();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.UNDEFINED_CLASS]);
    verify([source]);
  }
  void test_undefinedConstructorInInitializer_explicit_named() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B extends A {", "  B() : super.named();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER]);
  }
  void test_undefinedConstructorInInitializer_explicit_unnamed() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A.named() {}", "}", "class B extends A {", "  B() : super();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT]);
    verify([source]);
  }
  void test_undefinedConstructorInInitializer_implicit() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A.named() {}", "}", "class B extends A {", "  B();", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT]);
    verify([source]);
  }
  void test_undefinedNamedParameter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  const A();", "}", "main() {", "  const A(p: 0);", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER]);
  }
  void test_uriDoesNotExist_export() {
    Source source = addSource(EngineTestCase.createSource(["export 'unknown.dart';"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }
  void test_uriDoesNotExist_import() {
    Source source = addSource(EngineTestCase.createSource(["import 'unknown.dart';"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }
  void test_uriDoesNotExist_part() {
    Source source = addSource(EngineTestCase.createSource(["part 'unknown.dart';"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }
  void test_uriWithInterpolation_constant() {
    Source source = addSource(EngineTestCase.createSource(["import 'stuff_\$platform.dart';"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.URI_WITH_INTERPOLATION, StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }
  void test_uriWithInterpolation_nonConstant() {
    Source source = addSource(EngineTestCase.createSource(["library lib;", "part '\${'a'}.dart';"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.URI_WITH_INTERPOLATION]);
  }
  void test_wrongNumberOfParametersForOperator_minus() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  operator -(a, b) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS]);
    verify([source]);
    reset();
  }
  void test_wrongNumberOfParametersForOperator_tilde() {
    check_wrongNumberOfParametersForOperator("~", "a");
    check_wrongNumberOfParametersForOperator("~", "a, b");
  }
  void test_wrongNumberOfParametersForOperator1() {
    check_wrongNumberOfParametersForOperator1("<");
    check_wrongNumberOfParametersForOperator1(">");
    check_wrongNumberOfParametersForOperator1("<=");
    check_wrongNumberOfParametersForOperator1(">=");
    check_wrongNumberOfParametersForOperator1("+");
    check_wrongNumberOfParametersForOperator1("/");
    check_wrongNumberOfParametersForOperator1("~/");
    check_wrongNumberOfParametersForOperator1("*");
    check_wrongNumberOfParametersForOperator1("%");
    check_wrongNumberOfParametersForOperator1("|");
    check_wrongNumberOfParametersForOperator1("^");
    check_wrongNumberOfParametersForOperator1("&");
    check_wrongNumberOfParametersForOperator1("<<");
    check_wrongNumberOfParametersForOperator1(">>");
    check_wrongNumberOfParametersForOperator1("[]");
  }
  void test_wrongNumberOfParametersForSetter_function_tooFew() {
    Source source = addSource("set x() {}");
    resolve(source);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }
  void test_wrongNumberOfParametersForSetter_function_tooMany() {
    Source source = addSource("set x(a, b) {}");
    resolve(source);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }
  void test_wrongNumberOfParametersForSetter_method_tooFew() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  set x() {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }
  void test_wrongNumberOfParametersForSetter_method_tooMany() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  set x(a, b) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }
  void check_constEvalThrowsException_binary_null(String expr, bool resolved) {
    Source source = addSource("const C = ${expr};");
    resolve(source);
    if (resolved) {
      assertErrors([CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
      verify([source]);
    } else {
      assertErrors([CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, StaticTypeWarningCode.UNDEFINED_OPERATOR]);
    }
    reset();
  }
  void check_constEvalTypeBool_withParameter_binary(String expr) {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final a;", "  const A(bool p) : a = ${expr};", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL]);
    verify([source]);
    reset();
  }
  void check_constEvalTypeInt_withParameter_binary(String expr) {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final a;", "  const A(int p) : a = ${expr};", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_EVAL_TYPE_INT, StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
    reset();
  }
  void check_constEvalTypeNum_withParameter_binary(String expr) {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final a;", "  const A(num p) : a = ${expr};", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.CONST_EVAL_TYPE_NUM, StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
    reset();
  }
  void check_wrongNumberOfParametersForOperator(String name, String parameters) {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  operator ${name}(${parameters}) {}", "}"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR]);
    verify([source]);
    reset();
  }
  void check_wrongNumberOfParametersForOperator1(String name) {
    check_wrongNumberOfParametersForOperator(name, "");
    check_wrongNumberOfParametersForOperator(name, "a, b");
  }
  static dartSuite() {
    _ut.group('CompileTimeErrorCodeTest', () {
      _ut.test('test_ambiguousExport', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_ambiguousExport);
      });
      _ut.test('test_ambiguousImport_as', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_ambiguousImport_as);
      });
      _ut.test('test_ambiguousImport_extends', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_ambiguousImport_extends);
      });
      _ut.test('test_ambiguousImport_function', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_ambiguousImport_function);
      });
      _ut.test('test_ambiguousImport_implements', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_ambiguousImport_implements);
      });
      _ut.test('test_ambiguousImport_instanceCreation', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_ambiguousImport_instanceCreation);
      });
      _ut.test('test_ambiguousImport_is', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_ambiguousImport_is);
      });
      _ut.test('test_ambiguousImport_qualifier', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_ambiguousImport_qualifier);
      });
      _ut.test('test_ambiguousImport_typeArgument_instanceCreation', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_ambiguousImport_typeArgument_instanceCreation);
      });
      _ut.test('test_ambiguousImport_varRead', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_ambiguousImport_varRead);
      });
      _ut.test('test_ambiguousImport_varWrite', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_ambiguousImport_varWrite);
      });
      _ut.test('test_argumentDefinitionTestNonParameter', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_argumentDefinitionTestNonParameter);
      });
      _ut.test('test_builtInIdentifierAsType', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_builtInIdentifierAsType);
      });
      _ut.test('test_builtInIdentifierAsTypeName', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_builtInIdentifierAsTypeName);
      });
      _ut.test('test_builtInIdentifierAsTypeVariableName', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_builtInIdentifierAsTypeVariableName);
      });
      _ut.test('test_builtInIdentifierAsTypedefName_classTypeAlias', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_builtInIdentifierAsTypedefName_classTypeAlias);
      });
      _ut.test('test_builtInIdentifierAsTypedefName_functionTypeAlias', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_builtInIdentifierAsTypedefName_functionTypeAlias);
      });
      _ut.test('test_caseExpressionTypeImplementsEquals', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_caseExpressionTypeImplementsEquals);
      });
      _ut.test('test_conflictingConstructorNameAndMember_field', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_conflictingConstructorNameAndMember_field);
      });
      _ut.test('test_conflictingConstructorNameAndMember_method', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_conflictingConstructorNameAndMember_method);
      });
      _ut.test('test_constConstructorWithNonFinalField_mixin', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constConstructorWithNonFinalField_mixin);
      });
      _ut.test('test_constConstructorWithNonFinalField_super', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constConstructorWithNonFinalField_super);
      });
      _ut.test('test_constConstructorWithNonFinalField_this', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constConstructorWithNonFinalField_this);
      });
      _ut.test('test_constEvalThrowsException_binaryMinus_null', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constEvalThrowsException_binaryMinus_null);
      });
      _ut.test('test_constEvalThrowsException_binaryPlus_null', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constEvalThrowsException_binaryPlus_null);
      });
      _ut.test('test_constEvalThrowsException_unaryBitNot_null', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constEvalThrowsException_unaryBitNot_null);
      });
      _ut.test('test_constEvalThrowsException_unaryNegated_null', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constEvalThrowsException_unaryNegated_null);
      });
      _ut.test('test_constEvalThrowsException_unaryNot_null', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constEvalThrowsException_unaryNot_null);
      });
      _ut.test('test_constEvalTypeBoolNumString_equal', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constEvalTypeBoolNumString_equal);
      });
      _ut.test('test_constEvalTypeBoolNumString_notEqual', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constEvalTypeBoolNumString_notEqual);
      });
      _ut.test('test_constEvalTypeBool_binary', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constEvalTypeBool_binary);
      });
      _ut.test('test_constEvalTypeInt_binary', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constEvalTypeInt_binary);
      });
      _ut.test('test_constEvalTypeNum_binary', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constEvalTypeNum_binary);
      });
      _ut.test('test_constFormalParameter_fieldFormalParameter', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constFormalParameter_fieldFormalParameter);
      });
      _ut.test('test_constFormalParameter_simpleFormalParameter', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constFormalParameter_simpleFormalParameter);
      });
      _ut.test('test_constInitializedWithNonConstValue', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constInitializedWithNonConstValue);
      });
      _ut.test('test_constInitializedWithNonConstValue_missingConstInListLiteral', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constInitializedWithNonConstValue_missingConstInListLiteral);
      });
      _ut.test('test_constInitializedWithNonConstValue_missingConstInMapLiteral', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constInitializedWithNonConstValue_missingConstInMapLiteral);
      });
      _ut.test('test_constInstanceField', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constInstanceField);
      });
      _ut.test('test_constWithInvalidTypeParameters', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constWithInvalidTypeParameters);
      });
      _ut.test('test_constWithNonConst', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constWithNonConst);
      });
      _ut.test('test_constWithNonConstantArgument', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constWithNonConstantArgument);
      });
      _ut.test('test_constWithNonType', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constWithNonType);
      });
      _ut.test('test_constWithTypeParameters_direct', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constWithTypeParameters_direct);
      });
      _ut.test('test_constWithTypeParameters_indirect', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constWithTypeParameters_indirect);
      });
      _ut.test('test_constWithUndefinedConstructor', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constWithUndefinedConstructor);
      });
      _ut.test('test_constWithUndefinedConstructorDefault', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constWithUndefinedConstructorDefault);
      });
      _ut.test('test_defaultValueInFunctionTypeAlias', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_defaultValueInFunctionTypeAlias);
      });
      _ut.test('test_duplicateConstructorName_named', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_duplicateConstructorName_named);
      });
      _ut.test('test_duplicateConstructorName_unnamed', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_duplicateConstructorName_unnamed);
      });
      _ut.test('test_duplicateDefinition_parameterWithFunctionName_local', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_duplicateDefinition_parameterWithFunctionName_local);
      });
      _ut.test('test_duplicateDefinition_parameterWithFunctionName_topLevel', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_duplicateDefinition_parameterWithFunctionName_topLevel);
      });
      _ut.test('test_duplicateMemberError', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_duplicateMemberError);
      });
      _ut.test('test_duplicateMemberError_classMembers_methods', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_duplicateMemberError_classMembers_methods);
      });
      _ut.test('test_duplicateNamedArgument', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_duplicateNamedArgument);
      });
      _ut.test('test_exportInternalLibrary', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_exportInternalLibrary);
      });
      _ut.test('test_exportOfNonLibrary', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_exportOfNonLibrary);
      });
      _ut.test('test_extendsNonClass_class', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_extendsNonClass_class);
      });
      _ut.test('test_extendsOrImplementsDisallowedClass_extends_String', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_extendsOrImplementsDisallowedClass_extends_String);
      });
      _ut.test('test_extendsOrImplementsDisallowedClass_extends_bool', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_extendsOrImplementsDisallowedClass_extends_bool);
      });
      _ut.test('test_extendsOrImplementsDisallowedClass_extends_double', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_extendsOrImplementsDisallowedClass_extends_double);
      });
      _ut.test('test_extendsOrImplementsDisallowedClass_extends_int', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_extendsOrImplementsDisallowedClass_extends_int);
      });
      _ut.test('test_extendsOrImplementsDisallowedClass_extends_num', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_extendsOrImplementsDisallowedClass_extends_num);
      });
      _ut.test('test_extendsOrImplementsDisallowedClass_implements_String', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_extendsOrImplementsDisallowedClass_implements_String);
      });
      _ut.test('test_extendsOrImplementsDisallowedClass_implements_bool', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_extendsOrImplementsDisallowedClass_implements_bool);
      });
      _ut.test('test_extendsOrImplementsDisallowedClass_implements_double', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_extendsOrImplementsDisallowedClass_implements_double);
      });
      _ut.test('test_extendsOrImplementsDisallowedClass_implements_int', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_extendsOrImplementsDisallowedClass_implements_int);
      });
      _ut.test('test_extendsOrImplementsDisallowedClass_implements_num', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_extendsOrImplementsDisallowedClass_implements_num);
      });
      _ut.test('test_extraPositionalArguments_const', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_extraPositionalArguments_const);
      });
      _ut.test('test_fieldInitializedByMultipleInitializers', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_fieldInitializedByMultipleInitializers);
      });
      _ut.test('test_fieldInitializedByMultipleInitializers_multipleInits', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_fieldInitializedByMultipleInitializers_multipleInits);
      });
      _ut.test('test_fieldInitializedByMultipleInitializers_multipleNames', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_fieldInitializedByMultipleInitializers_multipleNames);
      });
      _ut.test('test_fieldInitializedInInitializerAndDeclaration_final', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_fieldInitializedInInitializerAndDeclaration_final);
      });
      _ut.test('test_fieldInitializedInParameterAndInitializer', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_fieldInitializedInParameterAndInitializer);
      });
      _ut.test('test_fieldInitializerFactoryConstructor', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_fieldInitializerFactoryConstructor);
      });
      _ut.test('test_fieldInitializerNotAssignable', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_fieldInitializerNotAssignable);
      });
      _ut.test('test_fieldInitializerOutsideConstructor', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_fieldInitializerOutsideConstructor);
      });
      _ut.test('test_fieldInitializerOutsideConstructor_defaultParameter', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_fieldInitializerOutsideConstructor_defaultParameter);
      });
      _ut.test('test_fieldInitializerRedirectingConstructor_afterRedirection', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_fieldInitializerRedirectingConstructor_afterRedirection);
      });
      _ut.test('test_fieldInitializerRedirectingConstructor_beforeRedirection', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_fieldInitializerRedirectingConstructor_beforeRedirection);
      });
      _ut.test('test_fieldInitializingFormalRedirectingConstructor', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_fieldInitializingFormalRedirectingConstructor);
      });
      _ut.test('test_finalInitializedInDeclarationAndConstructor_initializers', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_finalInitializedInDeclarationAndConstructor_initializers);
      });
      _ut.test('test_finalInitializedInDeclarationAndConstructor_initializingFormal', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_finalInitializedInDeclarationAndConstructor_initializingFormal);
      });
      _ut.test('test_finalInitializedMultipleTimes_initializers', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_finalInitializedMultipleTimes_initializers);
      });
      _ut.test('test_finalInitializedMultipleTimes_initializingFormal_initializer', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_finalInitializedMultipleTimes_initializingFormal_initializer);
      });
      _ut.test('test_finalInitializedMultipleTimes_initializingFormals', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_finalInitializedMultipleTimes_initializingFormals);
      });
      _ut.test('test_getterAndMethodWithSameName', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_getterAndMethodWithSameName);
      });
      _ut.test('test_implementsDynamic', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_implementsDynamic);
      });
      _ut.test('test_implementsNonClass_class', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_implementsNonClass_class);
      });
      _ut.test('test_implementsNonClass_typedef', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_implementsNonClass_typedef);
      });
      _ut.test('test_implementsRepeated', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_implementsRepeated);
      });
      _ut.test('test_implementsRepeated_3times', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_implementsRepeated_3times);
      });
      _ut.test('test_implicitThisReferenceInInitializer_field', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_implicitThisReferenceInInitializer_field);
      });
      _ut.test('test_implicitThisReferenceInInitializer_invocation', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_implicitThisReferenceInInitializer_invocation);
      });
      _ut.test('test_implicitThisReferenceInInitializer_redirectingConstructorInvocation', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_implicitThisReferenceInInitializer_redirectingConstructorInvocation);
      });
      _ut.test('test_implicitThisReferenceInInitializer_superConstructorInvocation', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_implicitThisReferenceInInitializer_superConstructorInvocation);
      });
      _ut.test('test_importInternalLibrary', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_importInternalLibrary);
      });
      _ut.test('test_importInternalLibrary_collection', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_importInternalLibrary_collection);
      });
      _ut.test('test_importOfNonLibrary', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_importOfNonLibrary);
      });
      _ut.test('test_inconsistentCaseExpressionTypes', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_inconsistentCaseExpressionTypes);
      });
      _ut.test('test_inconsistentCaseExpressionTypes_repeated', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_inconsistentCaseExpressionTypes_repeated);
      });
      _ut.test('test_initializerForNonExistant_initializer', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_initializerForNonExistant_initializer);
      });
      _ut.test('test_initializerForStaticField', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_initializerForStaticField);
      });
      _ut.test('test_initializingFormalForNonExistantField', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_initializingFormalForNonExistantField);
      });
      _ut.test('test_initializingFormalForNonExistantField_notInEnclosingClass', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_initializingFormalForNonExistantField_notInEnclosingClass);
      });
      _ut.test('test_initializingFormalForNonExistantField_optional', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_initializingFormalForNonExistantField_optional);
      });
      _ut.test('test_initializingFormalForNonExistantField_static', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_initializingFormalForNonExistantField_static);
      });
      _ut.test('test_invalidConstructorName_notEnclosingClassName', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_invalidConstructorName_notEnclosingClassName);
      });
      _ut.test('test_invalidFactoryNameNotAClass_notClassName', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_invalidFactoryNameNotAClass_notClassName);
      });
      _ut.test('test_invalidFactoryNameNotAClass_notEnclosingClassName', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_invalidFactoryNameNotAClass_notEnclosingClassName);
      });
      _ut.test('test_invalidOverrideNamed_fewerNamedParameters', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_invalidOverrideNamed_fewerNamedParameters);
      });
      _ut.test('test_invalidOverrideNamed_missingNamedParameter', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_invalidOverrideNamed_missingNamedParameter);
      });
      _ut.test('test_invalidOverridePositional', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_invalidOverridePositional);
      });
      _ut.test('test_invalidOverrideRequired', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_invalidOverrideRequired);
      });
      _ut.test('test_invalidReferenceToThis_factoryConstructor', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_invalidReferenceToThis_factoryConstructor);
      });
      _ut.test('test_invalidReferenceToThis_instanceVariableInitializer_inConstructor', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_invalidReferenceToThis_instanceVariableInitializer_inConstructor);
      });
      _ut.test('test_invalidReferenceToThis_instanceVariableInitializer_inDeclaration', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_invalidReferenceToThis_instanceVariableInitializer_inDeclaration);
      });
      _ut.test('test_invalidReferenceToThis_staticMethod', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_invalidReferenceToThis_staticMethod);
      });
      _ut.test('test_invalidReferenceToThis_staticVariableInitializer', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_invalidReferenceToThis_staticVariableInitializer);
      });
      _ut.test('test_invalidReferenceToThis_topLevelFunction', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_invalidReferenceToThis_topLevelFunction);
      });
      _ut.test('test_invalidReferenceToThis_variableInitializer', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_invalidReferenceToThis_variableInitializer);
      });
      _ut.test('test_invalidTypeArgumentForKey', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_invalidTypeArgumentForKey);
      });
      _ut.test('test_invalidTypeArgumentInConstList', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_invalidTypeArgumentInConstList);
      });
      _ut.test('test_invalidTypeArgumentInConstMap', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_invalidTypeArgumentInConstMap);
      });
      _ut.test('test_invalidUri_export', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_invalidUri_export);
      });
      _ut.test('test_invalidUri_import', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_invalidUri_import);
      });
      _ut.test('test_invalidUri_part', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_invalidUri_part);
      });
      _ut.test('test_labelInOuterScope', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_labelInOuterScope);
      });
      _ut.test('test_labelUndefined_break', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_labelUndefined_break);
      });
      _ut.test('test_labelUndefined_continue', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_labelUndefined_continue);
      });
      _ut.test('test_memberWithClassName_field', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_memberWithClassName_field);
      });
      _ut.test('test_memberWithClassName_field2', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_memberWithClassName_field2);
      });
      _ut.test('test_memberWithClassName_getter', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_memberWithClassName_getter);
      });
      _ut.test('test_memberWithClassName_method', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_memberWithClassName_method);
      });
      _ut.test('test_methodAndGetterWithSameName', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_methodAndGetterWithSameName);
      });
      _ut.test('test_mixinDeclaresConstructor_classDeclaration', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_mixinDeclaresConstructor_classDeclaration);
      });
      _ut.test('test_mixinDeclaresConstructor_typedef', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_mixinDeclaresConstructor_typedef);
      });
      _ut.test('test_mixinInheritsFromNotObject_classDeclaration_extends', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_mixinInheritsFromNotObject_classDeclaration_extends);
      });
      _ut.test('test_mixinInheritsFromNotObject_classDeclaration_with', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_mixinInheritsFromNotObject_classDeclaration_with);
      });
      _ut.test('test_mixinInheritsFromNotObject_typedef_extends', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_mixinInheritsFromNotObject_typedef_extends);
      });
      _ut.test('test_mixinInheritsFromNotObject_typedef_with', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_mixinInheritsFromNotObject_typedef_with);
      });
      _ut.test('test_mixinOfNonClass_class', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_mixinOfNonClass_class);
      });
      _ut.test('test_mixinOfNonClass_typedef', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_mixinOfNonClass_typedef);
      });
      _ut.test('test_mixinReferencesSuper', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_mixinReferencesSuper);
      });
      _ut.test('test_mixinWithNonClassSuperclass_class', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_mixinWithNonClassSuperclass_class);
      });
      _ut.test('test_mixinWithNonClassSuperclass_typedef', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_mixinWithNonClassSuperclass_typedef);
      });
      _ut.test('test_multipleRedirectingConstructorInvocations', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_multipleRedirectingConstructorInvocations);
      });
      _ut.test('test_multipleSuperInitializers', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_multipleSuperInitializers);
      });
      _ut.test('test_nativeFunctionBodyInNonSDKCode_function', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nativeFunctionBodyInNonSDKCode_function);
      });
      _ut.test('test_nativeFunctionBodyInNonSDKCode_method', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nativeFunctionBodyInNonSDKCode_method);
      });
      _ut.test('test_newWithInvalidTypeParameters', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_newWithInvalidTypeParameters);
      });
      _ut.test('test_nonConstCaseExpression', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonConstCaseExpression);
      });
      _ut.test('test_nonConstListElement', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonConstListElement);
      });
      _ut.test('test_nonConstMapAsExpressionStatement_begin', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonConstMapAsExpressionStatement_begin);
      });
      _ut.test('test_nonConstMapAsExpressionStatement_only', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonConstMapAsExpressionStatement_only);
      });
      _ut.test('test_nonConstMapKey', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonConstMapKey);
      });
      _ut.test('test_nonConstMapValue', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonConstMapValue);
      });
      _ut.test('test_nonConstValueInInitializer_binary_notBool_left', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonConstValueInInitializer_binary_notBool_left);
      });
      _ut.test('test_nonConstValueInInitializer_binary_notBool_right', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonConstValueInInitializer_binary_notBool_right);
      });
      _ut.test('test_nonConstValueInInitializer_binary_notInt', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonConstValueInInitializer_binary_notInt);
      });
      _ut.test('test_nonConstValueInInitializer_binary_notNum', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonConstValueInInitializer_binary_notNum);
      });
      _ut.test('test_nonConstValueInInitializer_field', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonConstValueInInitializer_field);
      });
      _ut.test('test_nonConstValueInInitializer_redirecting', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonConstValueInInitializer_redirecting);
      });
      _ut.test('test_nonConstValueInInitializer_super', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonConstValueInInitializer_super);
      });
      _ut.test('test_nonConstantDefaultValue_function_named', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonConstantDefaultValue_function_named);
      });
      _ut.test('test_nonConstantDefaultValue_function_positional', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonConstantDefaultValue_function_positional);
      });
      _ut.test('test_nonConstantDefaultValue_inConstructor_named', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonConstantDefaultValue_inConstructor_named);
      });
      _ut.test('test_nonConstantDefaultValue_inConstructor_positional', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonConstantDefaultValue_inConstructor_positional);
      });
      _ut.test('test_nonConstantDefaultValue_method_named', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonConstantDefaultValue_method_named);
      });
      _ut.test('test_nonConstantDefaultValue_method_positional', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonConstantDefaultValue_method_positional);
      });
      _ut.test('test_nonGenerativeConstructor_explicit', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonGenerativeConstructor_explicit);
      });
      _ut.test('test_nonGenerativeConstructor_implicit', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonGenerativeConstructor_implicit);
      });
      _ut.test('test_notEnoughRequiredArguments_const', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_notEnoughRequiredArguments_const);
      });
      _ut.test('test_optionalParameterInOperator_named', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_optionalParameterInOperator_named);
      });
      _ut.test('test_optionalParameterInOperator_positional', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_optionalParameterInOperator_positional);
      });
      _ut.test('test_partOfNonPart', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_partOfNonPart);
      });
      _ut.test('test_prefixCollidesWithTopLevelMembers_functionTypeAlias', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_prefixCollidesWithTopLevelMembers_functionTypeAlias);
      });
      _ut.test('test_prefixCollidesWithTopLevelMembers_topLevelFunction', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_prefixCollidesWithTopLevelMembers_topLevelFunction);
      });
      _ut.test('test_prefixCollidesWithTopLevelMembers_topLevelVariable', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_prefixCollidesWithTopLevelMembers_topLevelVariable);
      });
      _ut.test('test_prefixCollidesWithTopLevelMembers_type', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_prefixCollidesWithTopLevelMembers_type);
      });
      _ut.test('test_privateOptionalParameter', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_privateOptionalParameter);
      });
      _ut.test('test_recursiveConstructorRedirect', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_recursiveConstructorRedirect);
      });
      _ut.test('test_recursiveConstructorRedirect_directSelfReference', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_recursiveConstructorRedirect_directSelfReference);
      });
      _ut.test('test_recursiveFactoryRedirect', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_recursiveFactoryRedirect);
      });
      _ut.test('test_recursiveFactoryRedirect_directSelfReference', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_recursiveFactoryRedirect_directSelfReference);
      });
      _ut.test('test_recursiveFactoryRedirect_generic', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_recursiveFactoryRedirect_generic);
      });
      _ut.test('test_recursiveFactoryRedirect_named', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_recursiveFactoryRedirect_named);
      });
      _ut.test('test_recursiveFactoryRedirect_outsideCycle', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_recursiveFactoryRedirect_outsideCycle);
      });
      _ut.test('test_recursiveInterfaceInheritanceBaseCaseExtends', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_recursiveInterfaceInheritanceBaseCaseExtends);
      });
      _ut.test('test_recursiveInterfaceInheritanceBaseCaseImplements', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_recursiveInterfaceInheritanceBaseCaseImplements);
      });
      _ut.test('test_recursiveInterfaceInheritanceBaseCaseImplements_typedef', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_recursiveInterfaceInheritanceBaseCaseImplements_typedef);
      });
      _ut.test('test_recursiveInterfaceInheritance_extends', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_recursiveInterfaceInheritance_extends);
      });
      _ut.test('test_recursiveInterfaceInheritance_extends_implements', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_recursiveInterfaceInheritance_extends_implements);
      });
      _ut.test('test_recursiveInterfaceInheritance_implements', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_recursiveInterfaceInheritance_implements);
      });
      _ut.test('test_recursiveInterfaceInheritance_tail', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_recursiveInterfaceInheritance_tail);
      });
      _ut.test('test_recursiveInterfaceInheritance_tail2', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_recursiveInterfaceInheritance_tail2);
      });
      _ut.test('test_recursiveInterfaceInheritance_tail3', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_recursiveInterfaceInheritance_tail3);
      });
      _ut.test('test_redirectToNonConstConstructor', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_redirectToNonConstConstructor);
      });
      _ut.test('test_referenceToDeclaredVariableInInitializer_closure', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_referenceToDeclaredVariableInInitializer_closure);
      });
      _ut.test('test_referenceToDeclaredVariableInInitializer_getter', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_referenceToDeclaredVariableInInitializer_getter);
      });
      _ut.test('test_referenceToDeclaredVariableInInitializer_setter', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_referenceToDeclaredVariableInInitializer_setter);
      });
      _ut.test('test_referenceToDeclaredVariableInInitializer_unqualifiedInvocation', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_referenceToDeclaredVariableInInitializer_unqualifiedInvocation);
      });
      _ut.test('test_rethrowOutsideCatch', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_rethrowOutsideCatch);
      });
      _ut.test('test_returnInGenerativeConstructor', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_returnInGenerativeConstructor);
      });
      _ut.test('test_superInInvalidContext_binaryExpression', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_superInInvalidContext_binaryExpression);
      });
      _ut.test('test_superInInvalidContext_constructorFieldInitializer', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_superInInvalidContext_constructorFieldInitializer);
      });
      _ut.test('test_superInInvalidContext_factoryConstructor', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_superInInvalidContext_factoryConstructor);
      });
      _ut.test('test_superInInvalidContext_instanceVariableInitializer', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_superInInvalidContext_instanceVariableInitializer);
      });
      _ut.test('test_superInInvalidContext_staticMethod', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_superInInvalidContext_staticMethod);
      });
      _ut.test('test_superInInvalidContext_staticVariableInitializer', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_superInInvalidContext_staticVariableInitializer);
      });
      _ut.test('test_superInInvalidContext_topLevelFunction', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_superInInvalidContext_topLevelFunction);
      });
      _ut.test('test_superInInvalidContext_topLevelVariableInitializer', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_superInInvalidContext_topLevelVariableInitializer);
      });
      _ut.test('test_superInRedirectingConstructor_redirectionSuper', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_superInRedirectingConstructor_redirectionSuper);
      });
      _ut.test('test_superInRedirectingConstructor_superRedirection', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_superInRedirectingConstructor_superRedirection);
      });
      _ut.test('test_undefinedClass_const', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_undefinedClass_const);
      });
      _ut.test('test_undefinedConstructorInInitializer_explicit_named', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_undefinedConstructorInInitializer_explicit_named);
      });
      _ut.test('test_undefinedConstructorInInitializer_explicit_unnamed', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_undefinedConstructorInInitializer_explicit_unnamed);
      });
      _ut.test('test_undefinedConstructorInInitializer_implicit', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_undefinedConstructorInInitializer_implicit);
      });
      _ut.test('test_undefinedNamedParameter', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_undefinedNamedParameter);
      });
      _ut.test('test_uriDoesNotExist_export', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_uriDoesNotExist_export);
      });
      _ut.test('test_uriDoesNotExist_import', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_uriDoesNotExist_import);
      });
      _ut.test('test_uriDoesNotExist_part', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_uriDoesNotExist_part);
      });
      _ut.test('test_uriWithInterpolation_constant', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_uriWithInterpolation_constant);
      });
      _ut.test('test_uriWithInterpolation_nonConstant', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_uriWithInterpolation_nonConstant);
      });
      _ut.test('test_wrongNumberOfParametersForOperator1', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_wrongNumberOfParametersForOperator1);
      });
      _ut.test('test_wrongNumberOfParametersForOperator_minus', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_wrongNumberOfParametersForOperator_minus);
      });
      _ut.test('test_wrongNumberOfParametersForOperator_tilde', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_wrongNumberOfParametersForOperator_tilde);
      });
      _ut.test('test_wrongNumberOfParametersForSetter_function_tooFew', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_wrongNumberOfParametersForSetter_function_tooFew);
      });
      _ut.test('test_wrongNumberOfParametersForSetter_function_tooMany', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_wrongNumberOfParametersForSetter_function_tooMany);
      });
      _ut.test('test_wrongNumberOfParametersForSetter_method_tooFew', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_wrongNumberOfParametersForSetter_method_tooFew);
      });
      _ut.test('test_wrongNumberOfParametersForSetter_method_tooMany', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_wrongNumberOfParametersForSetter_method_tooMany);
      });
    });
  }
}
/**
 * Instances of the class `StaticTypeVerifier` verify that all of the nodes in an AST
 * structure that should have a static type associated with them do have a static type.
 */
class StaticTypeVerifier extends GeneralizingASTVisitor<Object> {

  /**
   * A list containing all of the AST Expression nodes that were not resolved.
   */
  List<Expression> _unresolvedExpressions = new List<Expression>();

  /**
   * A list containing all of the AST TypeName nodes that were not resolved.
   */
  List<TypeName> _unresolvedTypes = new List<TypeName>();

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
      int unresolvedExpressionCount = _unresolvedExpressions.length;
      int unresolvedTypeCount = _unresolvedTypes.length;
      PrintStringWriter writer = new PrintStringWriter();
      writer.print("Failed to associate types with nodes: ");
      writer.print(unresolvedExpressionCount);
      writer.print("/");
      writer.print(_resolvedExpressionCount + unresolvedExpressionCount);
      writer.print(" Expressions and ");
      writer.print(unresolvedTypeCount);
      writer.print("/");
      writer.print(_resolvedTypeCount + unresolvedTypeCount);
      writer.println(" TypeNames.");
      if (unresolvedTypeCount > 0) {
        writer.println("TypeNames:");
        for (TypeName identifier in _unresolvedTypes) {
          writer.print("  ");
          writer.print(identifier.toString());
          writer.print(" (");
          writer.print(getFileName(identifier));
          writer.print(" : ");
          writer.print(identifier.offset);
          writer.println(")");
        }
      }
      if (unresolvedExpressionCount > 0) {
        writer.println("Expressions:");
        for (Expression identifier in _unresolvedExpressions) {
          writer.print("  ");
          writer.print(identifier.toString());
          writer.print(" (");
          writer.print(getFileName(identifier));
          writer.print(" : ");
          writer.print(identifier.offset);
          writer.println(")");
        }
      }
      JUnitTestCase.fail(writer.toString());
    }
  }
  Object visitBreakStatement(BreakStatement node) => null;
  Object visitCommentReference(CommentReference node) => null;
  Object visitContinueStatement(ContinueStatement node) => null;
  Object visitExportDirective(ExportDirective node) => null;
  Object visitExpression(Expression node) {
    node.visitChildren(this);
    if (node.staticType == null) {
      _unresolvedExpressions.add(node);
    } else {
      _resolvedExpressionCount++;
    }
    return null;
  }
  Object visitImportDirective(ImportDirective node) => null;
  Object visitLabel(Label node) => null;
  Object visitLibraryIdentifier(LibraryIdentifier node) => null;
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.staticType == null && identical(node.prefix.staticType, DynamicTypeImpl.instance)) {
      return null;
    }
    return super.visitPrefixedIdentifier(node);
  }
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    ASTNode parent = node.parent;
    if (parent is MethodInvocation && identical(node, ((parent as MethodInvocation)).methodName)) {
      return null;
    } else if (parent is RedirectingConstructorInvocation && identical(node, ((parent as RedirectingConstructorInvocation)).constructorName)) {
      return null;
    } else if (parent is SuperConstructorInvocation && identical(node, ((parent as SuperConstructorInvocation)).constructorName)) {
      return null;
    } else if (parent is ConstructorName && identical(node, ((parent as ConstructorName)).name)) {
      return null;
    } else if (parent is ConstructorFieldInitializer && identical(node, ((parent as ConstructorFieldInitializer)).fieldName)) {
      return null;
    } else if (node.element is PrefixElement) {
      return null;
    }
    return super.visitSimpleIdentifier(node);
  }
  Object visitTypeName(TypeName node) {
    if (node.type == null) {
      _unresolvedTypes.add(node);
    } else {
      _resolvedTypeCount++;
    }
    return null;
  }
  String getFileName(ASTNode node) {
    if (node != null) {
      ASTNode root = node.root;
      if (root is CompilationUnit) {
        CompilationUnit rootCU = (root as CompilationUnit);
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
class StrictModeTest extends ResolverTestCase {
  void fail_for() {
    Source source = addSource(EngineTestCase.createSource(["int f(List<int> list) {", "  num sum = 0;", "  for (num i = 0; i < list.length; i++) {", "    sum += list[i];", "  }", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
  void setUp() {
    super.setUp();
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.strictMode = true;
    analysisContext.analysisOptions = options;
  }
  void test_assert_is() {
    Source source = addSource(EngineTestCase.createSource(["int f(num n) {", "  assert (n is int);", "  return n & 0x0F;", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
  void test_conditional_and_is() {
    Source source = addSource(EngineTestCase.createSource(["int f(num n) {", "  return (n is int && n > 0) ? n & 0x0F : 0;", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
  void test_conditional_is() {
    Source source = addSource(EngineTestCase.createSource(["int f(num n) {", "  return (n is int) ? n & 0x0F : 0;", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
  void test_conditional_isNot() {
    Source source = addSource(EngineTestCase.createSource(["int f(num n) {", "  return (n is! int) ? 0 : n & 0x0F;", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
  void test_conditional_or_is() {
    Source source = addSource(EngineTestCase.createSource(["int f(num n) {", "  return (n is! int || n < 0) ? 0 : n & 0x0F;", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
  void test_forEach() {
    Source source = addSource(EngineTestCase.createSource(["int f(List<int> list) {", "  num sum = 0;", "  for (num n in list) {", "    sum += n & 0x0F;", "  }", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
  void test_if_and_is() {
    Source source = addSource(EngineTestCase.createSource(["int f(num n) {", "  if (n is int && n > 0) {", "    return n & 0x0F;", "  }", "  return 0;", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
  void test_if_is() {
    Source source = addSource(EngineTestCase.createSource(["int f(num n) {", "  if (n is int) {", "    return n & 0x0F;", "  }", "  return 0;", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
  void test_if_isNot() {
    Source source = addSource(EngineTestCase.createSource(["int f(num n) {", "  if (n is! int) {", "    return 0;", "  } else {", "    return n & 0x0F;", "  }", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
  void test_if_isNot_abrupt() {
    Source source = addSource(EngineTestCase.createSource(["int f(num n) {", "  if (n is! int) {", "    return 0;", "  }", "  return n & 0x0F;", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
  void test_if_or_is() {
    Source source = addSource(EngineTestCase.createSource(["int f(num n) {", "  if (n is! int || n < 0) {", "    return 0;", "  } else {", "    return n & 0x0F;", "  }", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
  void test_localVar() {
    Source source = addSource(EngineTestCase.createSource(["int f() {", "  num n = 1234;", "  return n & 0x0F;", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
  static dartSuite() {
    _ut.group('StrictModeTest', () {
      _ut.test('test_assert_is', () {
        final __test = new StrictModeTest();
        runJUnitTest(__test, __test.test_assert_is);
      });
      _ut.test('test_conditional_and_is', () {
        final __test = new StrictModeTest();
        runJUnitTest(__test, __test.test_conditional_and_is);
      });
      _ut.test('test_conditional_is', () {
        final __test = new StrictModeTest();
        runJUnitTest(__test, __test.test_conditional_is);
      });
      _ut.test('test_conditional_isNot', () {
        final __test = new StrictModeTest();
        runJUnitTest(__test, __test.test_conditional_isNot);
      });
      _ut.test('test_conditional_or_is', () {
        final __test = new StrictModeTest();
        runJUnitTest(__test, __test.test_conditional_or_is);
      });
      _ut.test('test_forEach', () {
        final __test = new StrictModeTest();
        runJUnitTest(__test, __test.test_forEach);
      });
      _ut.test('test_if_and_is', () {
        final __test = new StrictModeTest();
        runJUnitTest(__test, __test.test_if_and_is);
      });
      _ut.test('test_if_is', () {
        final __test = new StrictModeTest();
        runJUnitTest(__test, __test.test_if_is);
      });
      _ut.test('test_if_isNot', () {
        final __test = new StrictModeTest();
        runJUnitTest(__test, __test.test_if_isNot);
      });
      _ut.test('test_if_isNot_abrupt', () {
        final __test = new StrictModeTest();
        runJUnitTest(__test, __test.test_if_isNot_abrupt);
      });
      _ut.test('test_if_or_is', () {
        final __test = new StrictModeTest();
        runJUnitTest(__test, __test.test_if_or_is);
      });
      _ut.test('test_localVar', () {
        final __test = new StrictModeTest();
        runJUnitTest(__test, __test.test_localVar);
      });
    });
  }
}
class ElementResolverTest extends EngineTestCase {

  /**
   * The error listener to which errors will be reported.
   */
  GatheringErrorListener _listener;

  /**
   * The type provider used to access the types.
   */
  TestTypeProvider _typeProvider;

  /**
   * The library containing the code being resolved.
   */
  LibraryElementImpl _definingLibrary;

  /**
   * The resolver visitor that maintains the state for the resolver.
   */
  ResolverVisitor _visitor;

  /**
   * The resolver being used to resolve the test cases.
   */
  ElementResolver _resolver;
  void fail_visitExportDirective_combinators() {
    JUnitTestCase.fail("Not yet tested");
    ExportDirective directive = ASTFactory.exportDirective2(null, [ASTFactory.hideCombinator2(["A"])]);
    resolveNode(directive, []);
    _listener.assertNoErrors();
  }
  void fail_visitFunctionExpressionInvocation() {
    JUnitTestCase.fail("Not yet tested");
    _listener.assertNoErrors();
  }
  void fail_visitImportDirective_combinators_noPrefix() {
    JUnitTestCase.fail("Not yet tested");
    ImportDirective directive = ASTFactory.importDirective2(null, null, [ASTFactory.showCombinator2(["A"])]);
    resolveNode(directive, []);
    _listener.assertNoErrors();
  }
  void fail_visitImportDirective_combinators_prefix() {
    JUnitTestCase.fail("Not yet tested");
    String prefixName = "p";
    _definingLibrary.imports = <ImportElement> [ElementFactory.importFor(null, ElementFactory.prefix(prefixName), [])];
    ImportDirective directive = ASTFactory.importDirective2(null, prefixName, [ASTFactory.showCombinator2(["A"]), ASTFactory.hideCombinator2(["B"])]);
    resolveNode(directive, []);
    _listener.assertNoErrors();
  }
  void fail_visitRedirectingConstructorInvocation() {
    JUnitTestCase.fail("Not yet tested");
    _listener.assertNoErrors();
  }
  void setUp() {
    _listener = new GatheringErrorListener();
    _typeProvider = new TestTypeProvider();
    _resolver = createResolver();
  }
  void test_lookUpMethodInInterfaces() {
    InterfaceType intType = _typeProvider.intType;
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    MethodElement operator = ElementFactory.methodElement("[]", intType, [intType]);
    classA.methods = <MethodElement> [operator];
    ClassElementImpl classB = ElementFactory.classElement2("B", []);
    classB.interfaces = <InterfaceType> [classA.type];
    ClassElementImpl classC = ElementFactory.classElement2("C", []);
    classC.mixins = <InterfaceType> [classB.type];
    ClassElementImpl classD = ElementFactory.classElement("D", classC.type, []);
    SimpleIdentifier array = ASTFactory.identifier3("a");
    array.staticType = classD.type;
    IndexExpression expression = ASTFactory.indexExpression(array, ASTFactory.identifier3("i"));
    JUnitTestCase.assertSame(operator, resolve5(expression, []));
    _listener.assertNoErrors();
  }
  void test_visitAssignmentExpression_compound() {
    InterfaceType intType = _typeProvider.intType;
    SimpleIdentifier leftHandSide = ASTFactory.identifier3("a");
    leftHandSide.staticType = intType;
    AssignmentExpression assignment = ASTFactory.assignmentExpression(leftHandSide, TokenType.PLUS_EQ, ASTFactory.integer(1));
    resolveNode(assignment, []);
    JUnitTestCase.assertSame(getMethod(_typeProvider.numType, "+"), assignment.element);
    _listener.assertNoErrors();
  }
  void test_visitAssignmentExpression_simple() {
    AssignmentExpression expression = ASTFactory.assignmentExpression(ASTFactory.identifier3("x"), TokenType.EQ, ASTFactory.integer(0));
    resolveNode(expression, []);
    JUnitTestCase.assertNull(expression.element);
    _listener.assertNoErrors();
  }
  void test_visitBinaryExpression() {
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier left = ASTFactory.identifier3("i");
    left.staticType = numType;
    BinaryExpression expression = ASTFactory.binaryExpression(left, TokenType.PLUS, ASTFactory.identifier3("j"));
    resolveNode(expression, []);
    JUnitTestCase.assertEquals(getMethod(numType, "+"), expression.element);
    _listener.assertNoErrors();
  }
  void test_visitBreakStatement_withLabel() {
    String label = "loop";
    LabelElementImpl labelElement = new LabelElementImpl(ASTFactory.identifier3(label), false, false);
    BreakStatement statement = ASTFactory.breakStatement2(label);
    JUnitTestCase.assertSame(labelElement, resolve(statement, labelElement));
    _listener.assertNoErrors();
  }
  void test_visitBreakStatement_withoutLabel() {
    BreakStatement statement = ASTFactory.breakStatement();
    resolveStatement(statement, null);
    _listener.assertNoErrors();
  }
  void test_visitConstructorName_named() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String constructorName = "a";
    ConstructorElement constructor = ElementFactory.constructorElement(classA, constructorName);
    classA.constructors = <ConstructorElement> [constructor];
    ConstructorName name = ASTFactory.constructorName(ASTFactory.typeName(classA, []), constructorName);
    resolveNode(name, []);
    JUnitTestCase.assertSame(constructor, name.element);
    _listener.assertNoErrors();
  }
  void test_visitConstructorName_unnamed() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String constructorName = null;
    ConstructorElement constructor = ElementFactory.constructorElement(classA, constructorName);
    classA.constructors = <ConstructorElement> [constructor];
    ConstructorName name = ASTFactory.constructorName(ASTFactory.typeName(classA, []), constructorName);
    resolveNode(name, []);
    JUnitTestCase.assertSame(constructor, name.element);
    _listener.assertNoErrors();
  }
  void test_visitContinueStatement_withLabel() {
    String label = "loop";
    LabelElementImpl labelElement = new LabelElementImpl(ASTFactory.identifier3(label), false, false);
    ContinueStatement statement = ASTFactory.continueStatement2(label);
    JUnitTestCase.assertSame(labelElement, resolve3(statement, labelElement));
    _listener.assertNoErrors();
  }
  void test_visitContinueStatement_withoutLabel() {
    ContinueStatement statement = ASTFactory.continueStatement();
    resolveStatement(statement, null);
    _listener.assertNoErrors();
  }
  void test_visitExportDirective_noCombinators() {
    ExportDirective directive = ASTFactory.exportDirective2(null, []);
    directive.element = ElementFactory.exportFor(ElementFactory.library(_definingLibrary.context, "lib"), []);
    resolveNode(directive, []);
    _listener.assertNoErrors();
  }
  void test_visitFieldFormalParameter() {
    InterfaceType intType = _typeProvider.intType;
    String fieldName = "f";
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    classA.fields = <FieldElement> [ElementFactory.fieldElement(fieldName, false, false, false, intType)];
    FieldFormalParameter parameter = ASTFactory.fieldFormalParameter2(fieldName);
    parameter.identifier.element = ElementFactory.fieldFormalParameter(parameter.identifier);
    resolveInClass(parameter, classA);
    JUnitTestCase.assertSame(intType, parameter.element.type);
  }
  void test_visitImportDirective_noCombinators_noPrefix() {
    ImportDirective directive = ASTFactory.importDirective2(null, null, []);
    directive.element = ElementFactory.importFor(ElementFactory.library(_definingLibrary.context, "lib"), null, []);
    resolveNode(directive, []);
    _listener.assertNoErrors();
  }
  void test_visitImportDirective_noCombinators_prefix() {
    String prefixName = "p";
    ImportElement importElement = ElementFactory.importFor(ElementFactory.library(_definingLibrary.context, "lib"), ElementFactory.prefix(prefixName), []);
    _definingLibrary.imports = <ImportElement> [importElement];
    ImportDirective directive = ASTFactory.importDirective2(null, prefixName, []);
    directive.element = importElement;
    resolveNode(directive, []);
    _listener.assertNoErrors();
  }
  void test_visitIndexExpression_get() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    InterfaceType intType = _typeProvider.intType;
    MethodElement getter = ElementFactory.methodElement("[]", intType, [intType]);
    classA.methods = <MethodElement> [getter];
    SimpleIdentifier array = ASTFactory.identifier3("a");
    array.staticType = classA.type;
    IndexExpression expression = ASTFactory.indexExpression(array, ASTFactory.identifier3("i"));
    JUnitTestCase.assertSame(getter, resolve5(expression, []));
    _listener.assertNoErrors();
  }
  void test_visitIndexExpression_set() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    InterfaceType intType = _typeProvider.intType;
    MethodElement setter = ElementFactory.methodElement("[]=", intType, [intType]);
    classA.methods = <MethodElement> [setter];
    SimpleIdentifier array = ASTFactory.identifier3("a");
    array.staticType = classA.type;
    IndexExpression expression = ASTFactory.indexExpression(array, ASTFactory.identifier3("i"));
    ASTFactory.assignmentExpression(expression, TokenType.EQ, ASTFactory.integer(0));
    JUnitTestCase.assertSame(setter, resolve5(expression, []));
    _listener.assertNoErrors();
  }
  void test_visitInstanceCreationExpression_named() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String constructorName = "a";
    ConstructorElement constructor = ElementFactory.constructorElement(classA, constructorName);
    classA.constructors = <ConstructorElement> [constructor];
    ConstructorName name = ASTFactory.constructorName(ASTFactory.typeName(classA, []), constructorName);
    name.element = constructor;
    InstanceCreationExpression creation = ASTFactory.instanceCreationExpression(Keyword.NEW, name, []);
    resolveNode(creation, []);
    JUnitTestCase.assertSame(constructor, creation.element);
    _listener.assertNoErrors();
  }
  void test_visitInstanceCreationExpression_unnamed() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String constructorName = null;
    ConstructorElement constructor = ElementFactory.constructorElement(classA, constructorName);
    classA.constructors = <ConstructorElement> [constructor];
    ConstructorName name = ASTFactory.constructorName(ASTFactory.typeName(classA, []), constructorName);
    name.element = constructor;
    InstanceCreationExpression creation = ASTFactory.instanceCreationExpression(Keyword.NEW, name, []);
    resolveNode(creation, []);
    JUnitTestCase.assertSame(constructor, creation.element);
    _listener.assertNoErrors();
  }
  void test_visitInstanceCreationExpression_unnamed_namedParameter() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String constructorName = null;
    ConstructorElementImpl constructor = ElementFactory.constructorElement(classA, constructorName);
    String parameterName = "a";
    ParameterElement parameter = ElementFactory.namedParameter(parameterName);
    constructor.parameters = <ParameterElement> [parameter];
    classA.constructors = <ConstructorElement> [constructor];
    ConstructorName name = ASTFactory.constructorName(ASTFactory.typeName(classA, []), constructorName);
    name.element = constructor;
    InstanceCreationExpression creation = ASTFactory.instanceCreationExpression(Keyword.NEW, name, [ASTFactory.namedExpression2(parameterName, ASTFactory.integer(0))]);
    resolveNode(creation, []);
    JUnitTestCase.assertSame(constructor, creation.element);
    JUnitTestCase.assertSame(parameter, ((creation.argumentList.arguments[0] as NamedExpression)).name.label.element);
    _listener.assertNoErrors();
  }
  void test_visitMethodInvocation() {
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier left = ASTFactory.identifier3("i");
    left.staticType = numType;
    String methodName = "abs";
    MethodInvocation invocation = ASTFactory.methodInvocation(left, methodName, []);
    resolveNode(invocation, []);
    JUnitTestCase.assertSame(getMethod(numType, methodName), invocation.methodName.element);
    _listener.assertNoErrors();
  }
  void test_visitMethodInvocation_namedParameter() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String methodName = "m";
    String parameterName = "p";
    MethodElementImpl method = ElementFactory.methodElement(methodName, null, []);
    ParameterElement parameter = ElementFactory.namedParameter(parameterName);
    method.parameters = <ParameterElement> [parameter];
    classA.methods = <MethodElement> [method];
    SimpleIdentifier left = ASTFactory.identifier3("i");
    left.staticType = classA.type;
    MethodInvocation invocation = ASTFactory.methodInvocation(left, methodName, [ASTFactory.namedExpression2(parameterName, ASTFactory.integer(0))]);
    resolveNode(invocation, []);
    JUnitTestCase.assertSame(method, invocation.methodName.element);
    JUnitTestCase.assertSame(parameter, ((invocation.argumentList.arguments[0] as NamedExpression)).name.label.element);
    _listener.assertNoErrors();
  }
  void test_visitPostfixExpression() {
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier operand = ASTFactory.identifier3("i");
    operand.staticType = numType;
    PostfixExpression expression = ASTFactory.postfixExpression(operand, TokenType.PLUS_PLUS);
    resolveNode(expression, []);
    JUnitTestCase.assertEquals(getMethod(numType, "+"), expression.element);
    _listener.assertNoErrors();
  }
  void test_visitPrefixedIdentifier_dynamic() {
    Type2 dynamicType = _typeProvider.dynamicType;
    SimpleIdentifier target = ASTFactory.identifier3("a");
    VariableElementImpl variable = ElementFactory.localVariableElement(target);
    variable.type = dynamicType;
    target.element = variable;
    target.staticType = dynamicType;
    PrefixedIdentifier identifier = ASTFactory.identifier(target, ASTFactory.identifier3("b"));
    resolveNode(identifier, []);
    JUnitTestCase.assertNull(identifier.element);
    JUnitTestCase.assertNull(identifier.identifier.element);
    _listener.assertNoErrors();
  }
  void test_visitPrefixedIdentifier_nonDynamic() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String getterName = "b";
    PropertyAccessorElement getter = ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement> [getter];
    SimpleIdentifier target = ASTFactory.identifier3("a");
    VariableElementImpl variable = ElementFactory.localVariableElement(target);
    variable.type = classA.type;
    target.element = variable;
    target.staticType = classA.type;
    PrefixedIdentifier identifier = ASTFactory.identifier(target, ASTFactory.identifier3(getterName));
    resolveNode(identifier, []);
    JUnitTestCase.assertSame(getter, identifier.element);
    JUnitTestCase.assertSame(getter, identifier.identifier.element);
    _listener.assertNoErrors();
  }
  void test_visitPrefixExpression() {
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier operand = ASTFactory.identifier3("i");
    operand.staticType = numType;
    PrefixExpression expression = ASTFactory.prefixExpression(TokenType.PLUS_PLUS, operand);
    resolveNode(expression, []);
    JUnitTestCase.assertEquals(getMethod(numType, "+"), expression.element);
    _listener.assertNoErrors();
  }
  void test_visitPropertyAccess_getter_identifier() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String getterName = "b";
    PropertyAccessorElement getter = ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement> [getter];
    SimpleIdentifier target = ASTFactory.identifier3("a");
    target.staticType = classA.type;
    PropertyAccess access = ASTFactory.propertyAccess2(target, getterName);
    resolveNode(access, []);
    JUnitTestCase.assertSame(getter, access.propertyName.element);
    _listener.assertNoErrors();
  }
  void test_visitPropertyAccess_getter_super() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String getterName = "b";
    PropertyAccessorElement getter = ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement> [getter];
    SuperExpression target = ASTFactory.superExpression();
    target.staticType = ElementFactory.classElement("B", classA.type, []).type;
    PropertyAccess access = ASTFactory.propertyAccess2(target, getterName);
    ASTFactory.methodDeclaration2(null, null, null, null, ASTFactory.identifier3("m"), ASTFactory.formalParameterList([]), ASTFactory.expressionFunctionBody(access));
    resolveNode(access, []);
    JUnitTestCase.assertSame(getter, access.propertyName.element);
    _listener.assertNoErrors();
  }
  void test_visitPropertyAccess_setter_this() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String setterName = "b";
    PropertyAccessorElement setter = ElementFactory.setterElement(setterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement> [setter];
    ThisExpression target = ASTFactory.thisExpression();
    target.staticType = classA.type;
    PropertyAccess access = ASTFactory.propertyAccess2(target, setterName);
    ASTFactory.assignmentExpression(access, TokenType.EQ, ASTFactory.integer(0));
    resolveNode(access, []);
    JUnitTestCase.assertSame(setter, access.propertyName.element);
    _listener.assertNoErrors();
  }
  void test_visitSimpleIdentifier_classScope() {
    InterfaceType doubleType = _typeProvider.doubleType;
    String fieldName = "NAN";
    SimpleIdentifier node = ASTFactory.identifier3(fieldName);
    resolveInClass(node, doubleType.element);
    JUnitTestCase.assertEquals(getGetter(doubleType, fieldName), node.element);
    _listener.assertNoErrors();
  }
  void test_visitSimpleIdentifier_lexicalScope() {
    SimpleIdentifier node = ASTFactory.identifier3("i");
    VariableElementImpl element = ElementFactory.localVariableElement(node);
    JUnitTestCase.assertSame(element, resolve4(node, [element]));
    _listener.assertNoErrors();
  }
  void test_visitSimpleIdentifier_lexicalScope_field_setter() {
    InterfaceType intType = _typeProvider.intType;
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String fieldName = "a";
    FieldElement field = ElementFactory.fieldElement(fieldName, false, false, false, intType);
    classA.fields = <FieldElement> [field];
    classA.accessors = <PropertyAccessorElement> [field.getter, field.setter];
    SimpleIdentifier node = ASTFactory.identifier3(fieldName);
    ASTFactory.assignmentExpression(node, TokenType.EQ, ASTFactory.integer(0));
    resolveInClass(node, classA);
    Element element = node.element;
    EngineTestCase.assertInstanceOf(PropertyAccessorElement, element);
    JUnitTestCase.assertTrue(((element as PropertyAccessorElement)).isSetter);
    _listener.assertNoErrors();
  }
  void test_visitSuperConstructorInvocation() {
    ClassElementImpl superclass = ElementFactory.classElement2("A", []);
    ConstructorElementImpl superConstructor = ElementFactory.constructorElement(superclass, null);
    superclass.constructors = <ConstructorElement> [superConstructor];
    ClassElementImpl subclass = ElementFactory.classElement("B", superclass.type, []);
    ConstructorElementImpl subConstructor = ElementFactory.constructorElement(subclass, null);
    subclass.constructors = <ConstructorElement> [subConstructor];
    SuperConstructorInvocation invocation = ASTFactory.superConstructorInvocation([]);
    resolveInClass(invocation, subclass);
    JUnitTestCase.assertEquals(superConstructor, invocation.element);
    _listener.assertNoErrors();
  }
  void test_visitSuperConstructorInvocation_namedParameter() {
    ClassElementImpl superclass = ElementFactory.classElement2("A", []);
    ConstructorElementImpl superConstructor = ElementFactory.constructorElement(superclass, null);
    String parameterName = "p";
    ParameterElement parameter = ElementFactory.namedParameter(parameterName);
    superConstructor.parameters = <ParameterElement> [parameter];
    superclass.constructors = <ConstructorElement> [superConstructor];
    ClassElementImpl subclass = ElementFactory.classElement("B", superclass.type, []);
    ConstructorElementImpl subConstructor = ElementFactory.constructorElement(subclass, null);
    subclass.constructors = <ConstructorElement> [subConstructor];
    SuperConstructorInvocation invocation = ASTFactory.superConstructorInvocation([ASTFactory.namedExpression2(parameterName, ASTFactory.integer(0))]);
    resolveInClass(invocation, subclass);
    JUnitTestCase.assertEquals(superConstructor, invocation.element);
    JUnitTestCase.assertSame(parameter, ((invocation.argumentList.arguments[0] as NamedExpression)).name.label.element);
    _listener.assertNoErrors();
  }

  /**
   * Create the resolver used by the tests.
   * @return the resolver that was created
   */
  ElementResolver createResolver() {
    AnalysisContextImpl context = new AnalysisContextImpl();
    ContentCache contentCache = new ContentCache();
    SourceFactory sourceFactory = new SourceFactory.con1(contentCache, [new DartUriResolver(DirectoryBasedDartSdk.defaultSdk)]);
    context.sourceFactory = sourceFactory;
    FileBasedSource source = new FileBasedSource.con1(contentCache, FileUtilities2.createFile("/test.dart"));
    CompilationUnitElementImpl definingCompilationUnit = new CompilationUnitElementImpl("test.dart");
    definingCompilationUnit.source = source;
    _definingLibrary = ElementFactory.library(context, "test");
    _definingLibrary.definingCompilationUnit = definingCompilationUnit;
    Library library = new Library(context, _listener, source);
    library.libraryElement = _definingLibrary;
    _visitor = new ResolverVisitor.con1(library, source, _typeProvider);
    try {
      return _visitor.elementResolver_J2DAccessor as ElementResolver;
    } catch (exception) {
      throw new IllegalArgumentException("Could not create resolver", exception);
    }
  }

  /**
   * Return the element associated with the label of the given statement after the resolver has
   * resolved the statement.
   * @param statement the statement to be resolved
   * @param labelElement the label element to be defined in the statement's label scope
   * @return the element to which the statement's label was resolved
   */
  Element resolve(BreakStatement statement, LabelElementImpl labelElement) {
    resolveStatement(statement, labelElement);
    return statement.label.element;
  }

  /**
   * Return the element associated with the label of the given statement after the resolver has
   * resolved the statement.
   * @param statement the statement to be resolved
   * @param labelElement the label element to be defined in the statement's label scope
   * @return the element to which the statement's label was resolved
   */
  Element resolve3(ContinueStatement statement, LabelElementImpl labelElement) {
    resolveStatement(statement, labelElement);
    return statement.label.element;
  }

  /**
   * Return the element associated with the given identifier after the resolver has resolved the
   * identifier.
   * @param node the expression to be resolved
   * @param definedElements the elements that are to be defined in the scope in which the element is
   * being resolved
   * @return the element to which the expression was resolved
   */
  Element resolve4(Identifier node, List<Element> definedElements) {
    resolveNode(node, definedElements);
    return node.element;
  }

  /**
   * Return the element associated with the given expression after the resolver has resolved the
   * expression.
   * @param node the expression to be resolved
   * @param definedElements the elements that are to be defined in the scope in which the element is
   * being resolved
   * @return the element to which the expression was resolved
   */
  Element resolve5(IndexExpression node, List<Element> definedElements) {
    resolveNode(node, definedElements);
    return node.element;
  }

  /**
   * Return the element associated with the given identifier after the resolver has resolved the
   * identifier.
   * @param node the expression to be resolved
   * @param enclosingClass the element representing the class enclosing the identifier
   * @return the element to which the expression was resolved
   */
  void resolveInClass(ASTNode node, ClassElement enclosingClass) {
    try {
      Scope outerScope = _visitor.nameScope_J2DAccessor as Scope;
      try {
        _visitor.enclosingClass_J2DAccessor = enclosingClass;
        EnclosedScope innerScope = new ClassScope(outerScope, enclosingClass);
        _visitor.nameScope_J2DAccessor = innerScope;
        node.accept(_resolver);
      } finally {
        _visitor.enclosingClass_J2DAccessor = null;
        _visitor.nameScope_J2DAccessor = outerScope;
      }
    } catch (exception) {
      throw new IllegalArgumentException("Could not resolve node", exception);
    }
  }

  /**
   * Return the element associated with the given identifier after the resolver has resolved the
   * identifier.
   * @param node the expression to be resolved
   * @param definedElements the elements that are to be defined in the scope in which the element is
   * being resolved
   * @return the element to which the expression was resolved
   */
  void resolveNode(ASTNode node, List<Element> definedElements) {
    try {
      Scope outerScope = _visitor.nameScope_J2DAccessor as Scope;
      try {
        EnclosedScope innerScope = new EnclosedScope(outerScope);
        for (Element element in definedElements) {
          innerScope.define(element);
        }
        _visitor.nameScope_J2DAccessor = innerScope;
        node.accept(_resolver);
      } finally {
        _visitor.nameScope_J2DAccessor = outerScope;
      }
    } catch (exception) {
      throw new IllegalArgumentException("Could not resolve node", exception);
    }
  }

  /**
   * Return the element associated with the label of the given statement after the resolver has
   * resolved the statement.
   * @param statement the statement to be resolved
   * @param labelElement the label element to be defined in the statement's label scope
   * @return the element to which the statement's label was resolved
   */
  void resolveStatement(Statement statement, LabelElementImpl labelElement) {
    try {
      LabelScope outerScope = _visitor.labelScope_J2DAccessor as LabelScope;
      try {
        LabelScope innerScope;
        if (labelElement == null) {
          innerScope = new LabelScope.con1(outerScope, false, false);
        } else {
          innerScope = new LabelScope.con2(outerScope, labelElement.name, labelElement);
        }
        _visitor.labelScope_J2DAccessor = innerScope;
        statement.accept(_resolver);
      } finally {
        _visitor.labelScope_J2DAccessor = outerScope;
      }
    } catch (exception) {
      throw new IllegalArgumentException("Could not resolve node", exception);
    }
  }
  static dartSuite() {
    _ut.group('ElementResolverTest', () {
      _ut.test('test_lookUpMethodInInterfaces', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_lookUpMethodInInterfaces);
      });
      _ut.test('test_visitAssignmentExpression_compound', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitAssignmentExpression_compound);
      });
      _ut.test('test_visitAssignmentExpression_simple', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitAssignmentExpression_simple);
      });
      _ut.test('test_visitBinaryExpression', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitBinaryExpression);
      });
      _ut.test('test_visitBreakStatement_withLabel', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitBreakStatement_withLabel);
      });
      _ut.test('test_visitBreakStatement_withoutLabel', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitBreakStatement_withoutLabel);
      });
      _ut.test('test_visitConstructorName_named', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitConstructorName_named);
      });
      _ut.test('test_visitConstructorName_unnamed', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitConstructorName_unnamed);
      });
      _ut.test('test_visitContinueStatement_withLabel', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitContinueStatement_withLabel);
      });
      _ut.test('test_visitContinueStatement_withoutLabel', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitContinueStatement_withoutLabel);
      });
      _ut.test('test_visitExportDirective_noCombinators', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitExportDirective_noCombinators);
      });
      _ut.test('test_visitFieldFormalParameter', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitFieldFormalParameter);
      });
      _ut.test('test_visitImportDirective_noCombinators_noPrefix', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitImportDirective_noCombinators_noPrefix);
      });
      _ut.test('test_visitImportDirective_noCombinators_prefix', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitImportDirective_noCombinators_prefix);
      });
      _ut.test('test_visitIndexExpression_get', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitIndexExpression_get);
      });
      _ut.test('test_visitIndexExpression_set', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitIndexExpression_set);
      });
      _ut.test('test_visitInstanceCreationExpression_named', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitInstanceCreationExpression_named);
      });
      _ut.test('test_visitInstanceCreationExpression_unnamed', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitInstanceCreationExpression_unnamed);
      });
      _ut.test('test_visitInstanceCreationExpression_unnamed_namedParameter', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitInstanceCreationExpression_unnamed_namedParameter);
      });
      _ut.test('test_visitMethodInvocation', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitMethodInvocation);
      });
      _ut.test('test_visitMethodInvocation_namedParameter', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitMethodInvocation_namedParameter);
      });
      _ut.test('test_visitPostfixExpression', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitPostfixExpression);
      });
      _ut.test('test_visitPrefixExpression', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitPrefixExpression);
      });
      _ut.test('test_visitPrefixedIdentifier_dynamic', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitPrefixedIdentifier_dynamic);
      });
      _ut.test('test_visitPrefixedIdentifier_nonDynamic', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitPrefixedIdentifier_nonDynamic);
      });
      _ut.test('test_visitPropertyAccess_getter_identifier', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitPropertyAccess_getter_identifier);
      });
      _ut.test('test_visitPropertyAccess_getter_super', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitPropertyAccess_getter_super);
      });
      _ut.test('test_visitPropertyAccess_setter_this', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitPropertyAccess_setter_this);
      });
      _ut.test('test_visitSimpleIdentifier_classScope', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitSimpleIdentifier_classScope);
      });
      _ut.test('test_visitSimpleIdentifier_lexicalScope', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitSimpleIdentifier_lexicalScope);
      });
      _ut.test('test_visitSimpleIdentifier_lexicalScope_field_setter', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitSimpleIdentifier_lexicalScope_field_setter);
      });
      _ut.test('test_visitSuperConstructorInvocation', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitSuperConstructorInvocation);
      });
      _ut.test('test_visitSuperConstructorInvocation_namedParameter', () {
        final __test = new ElementResolverTest();
        runJUnitTest(__test, __test.test_visitSuperConstructorInvocation_namedParameter);
      });
    });
  }
}
class TypeOverrideManagerTest extends EngineTestCase {
  void test_exitScope_noScopes() {
    TypeOverrideManager manager = new TypeOverrideManager();
    try {
      manager.exitScope();
      JUnitTestCase.fail("Expected IllegalStateException");
    } on IllegalStateException catch (exception) {
    }
  }
  void test_exitScope_oneScope() {
    TypeOverrideManager manager = new TypeOverrideManager();
    manager.enterScope();
    manager.exitScope();
    try {
      manager.exitScope();
      JUnitTestCase.fail("Expected IllegalStateException");
    } on IllegalStateException catch (exception) {
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
      JUnitTestCase.fail("Expected IllegalStateException");
    } on IllegalStateException catch (exception) {
    }
  }
  void test_getType_enclosedOverride() {
    TypeOverrideManager manager = new TypeOverrideManager();
    LocalVariableElementImpl element = ElementFactory.localVariableElement2("v");
    InterfaceType type = ElementFactory.classElement2("C", []).type;
    manager.enterScope();
    manager.setType(element, type);
    manager.enterScope();
    JUnitTestCase.assertSame(type, manager.getType(element));
  }
  void test_getType_immediateOverride() {
    TypeOverrideManager manager = new TypeOverrideManager();
    LocalVariableElementImpl element = ElementFactory.localVariableElement2("v");
    InterfaceType type = ElementFactory.classElement2("C", []).type;
    manager.enterScope();
    manager.setType(element, type);
    JUnitTestCase.assertSame(type, manager.getType(element));
  }
  void test_getType_noOverride() {
    TypeOverrideManager manager = new TypeOverrideManager();
    manager.enterScope();
    JUnitTestCase.assertNull(manager.getType(ElementFactory.localVariableElement2("v")));
  }
  void test_getType_noScope() {
    TypeOverrideManager manager = new TypeOverrideManager();
    JUnitTestCase.assertNull(manager.getType(ElementFactory.localVariableElement2("v")));
  }
  static dartSuite() {
    _ut.group('TypeOverrideManagerTest', () {
      _ut.test('test_exitScope_noScopes', () {
        final __test = new TypeOverrideManagerTest();
        runJUnitTest(__test, __test.test_exitScope_noScopes);
      });
      _ut.test('test_exitScope_oneScope', () {
        final __test = new TypeOverrideManagerTest();
        runJUnitTest(__test, __test.test_exitScope_oneScope);
      });
      _ut.test('test_exitScope_twoScopes', () {
        final __test = new TypeOverrideManagerTest();
        runJUnitTest(__test, __test.test_exitScope_twoScopes);
      });
      _ut.test('test_getType_enclosedOverride', () {
        final __test = new TypeOverrideManagerTest();
        runJUnitTest(__test, __test.test_getType_enclosedOverride);
      });
      _ut.test('test_getType_immediateOverride', () {
        final __test = new TypeOverrideManagerTest();
        runJUnitTest(__test, __test.test_getType_immediateOverride);
      });
      _ut.test('test_getType_noOverride', () {
        final __test = new TypeOverrideManagerTest();
        runJUnitTest(__test, __test.test_getType_noOverride);
      });
      _ut.test('test_getType_noScope', () {
        final __test = new TypeOverrideManagerTest();
        runJUnitTest(__test, __test.test_getType_noScope);
      });
    });
  }
}
class PubSuggestionCodeTest extends ResolverTestCase {
  void test_import_package() {
    Source source = addSource(EngineTestCase.createSource(["import 'package:somepackage/other.dart';"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }
  void test_import_packageWithDotDot() {
    Source source = addSource(EngineTestCase.createSource(["import 'package:somepackage/../other.dart';"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.URI_DOES_NOT_EXIST, PubSuggestionCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT]);
  }
  void test_import_packageWithLeadingDotDot() {
    Source source = addSource(EngineTestCase.createSource(["import 'package:../other.dart';"]));
    resolve(source);
    assertErrors([CompileTimeErrorCode.URI_DOES_NOT_EXIST, PubSuggestionCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT]);
  }
  void test_import_referenceIntoLibDirectory() {
    cacheSource("/myproj/pubspec.yaml", "");
    cacheSource("/myproj/lib/other.dart", "");
    Source source = addSource2("/myproj/web/test.dart", EngineTestCase.createSource(["import '../lib/other.dart';"]));
    resolve(source);
    assertErrors([PubSuggestionCode.FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE]);
  }
  void test_import_referenceIntoLibDirectory_no_pubspec() {
    cacheSource("/myproj/lib/other.dart", "");
    Source source = addSource2("/myproj/web/test.dart", EngineTestCase.createSource(["import '../lib/other.dart';"]));
    resolve(source);
    assertNoErrors();
  }
  void test_import_referenceOutOfLibDirectory() {
    cacheSource("/myproj/pubspec.yaml", "");
    cacheSource("/myproj/web/other.dart", "");
    Source source = addSource2("/myproj/lib/test.dart", EngineTestCase.createSource(["import '../web/other.dart';"]));
    resolve(source);
    assertErrors([PubSuggestionCode.FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE]);
  }
  void test_import_referenceOutOfLibDirectory_no_pubspec() {
    cacheSource("/myproj/web/other.dart", "");
    Source source = addSource2("/myproj/lib/test.dart", EngineTestCase.createSource(["import '../web/other.dart';"]));
    resolve(source);
    assertNoErrors();
  }
  void test_import_valid_inside_lib1() {
    cacheSource("/myproj/pubspec.yaml", "");
    cacheSource("/myproj/lib/other.dart", "");
    Source source = addSource2("/myproj/lib/test.dart", EngineTestCase.createSource(["import 'other.dart';"]));
    resolve(source);
    assertNoErrors();
  }
  void test_import_valid_inside_lib2() {
    cacheSource("/myproj/pubspec.yaml", "");
    cacheSource("/myproj/lib/bar/other.dart", "");
    Source source = addSource2("/myproj/lib/foo/test.dart", EngineTestCase.createSource(["import '../bar/other.dart';"]));
    resolve(source);
    assertNoErrors();
  }
  void test_import_valid_outside_lib() {
    cacheSource("/myproj/pubspec.yaml", "");
    cacheSource("/myproj/web/other.dart", "");
    Source source = addSource2("/myproj/lib2/test.dart", EngineTestCase.createSource(["import '../web/other.dart';"]));
    resolve(source);
    assertNoErrors();
  }
  static dartSuite() {
    _ut.group('PubSuggestionCodeTest', () {
      _ut.test('test_import_package', () {
        final __test = new PubSuggestionCodeTest();
        runJUnitTest(__test, __test.test_import_package);
      });
      _ut.test('test_import_packageWithDotDot', () {
        final __test = new PubSuggestionCodeTest();
        runJUnitTest(__test, __test.test_import_packageWithDotDot);
      });
      _ut.test('test_import_packageWithLeadingDotDot', () {
        final __test = new PubSuggestionCodeTest();
        runJUnitTest(__test, __test.test_import_packageWithLeadingDotDot);
      });
      _ut.test('test_import_referenceIntoLibDirectory', () {
        final __test = new PubSuggestionCodeTest();
        runJUnitTest(__test, __test.test_import_referenceIntoLibDirectory);
      });
      _ut.test('test_import_referenceIntoLibDirectory_no_pubspec', () {
        final __test = new PubSuggestionCodeTest();
        runJUnitTest(__test, __test.test_import_referenceIntoLibDirectory_no_pubspec);
      });
      _ut.test('test_import_referenceOutOfLibDirectory', () {
        final __test = new PubSuggestionCodeTest();
        runJUnitTest(__test, __test.test_import_referenceOutOfLibDirectory);
      });
      _ut.test('test_import_referenceOutOfLibDirectory_no_pubspec', () {
        final __test = new PubSuggestionCodeTest();
        runJUnitTest(__test, __test.test_import_referenceOutOfLibDirectory_no_pubspec);
      });
      _ut.test('test_import_valid_inside_lib1', () {
        final __test = new PubSuggestionCodeTest();
        runJUnitTest(__test, __test.test_import_valid_inside_lib1);
      });
      _ut.test('test_import_valid_inside_lib2', () {
        final __test = new PubSuggestionCodeTest();
        runJUnitTest(__test, __test.test_import_valid_inside_lib2);
      });
      _ut.test('test_import_valid_outside_lib', () {
        final __test = new PubSuggestionCodeTest();
        runJUnitTest(__test, __test.test_import_valid_outside_lib);
      });
    });
  }
}
class StaticWarningCodeTest extends ResolverTestCase {
  void fail_argumentTypeNotAssignable_invocation_functionParameter_generic() {
    Source source = addSource(EngineTestCase.createSource(["class A<K, V> {", "  m(f(K k), V v) {", "    f(v);", "  }", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void fail_commentReferenceConstructorNotVisible() {
    Source source = addSource(EngineTestCase.createSource([]));
    resolve(source);
    assertErrors([StaticWarningCode.COMMENT_REFERENCE_CONSTRUCTOR_NOT_VISIBLE]);
    verify([source]);
  }
  void fail_commentReferenceIdentifierNotVisible() {
    Source source = addSource(EngineTestCase.createSource([]));
    resolve(source);
    assertErrors([StaticWarningCode.COMMENT_REFERENCE_IDENTIFIER_NOT_VISIBLE]);
    verify([source]);
  }
  void fail_commentReferenceUndeclaredConstructor() {
    Source source = addSource(EngineTestCase.createSource([]));
    resolve(source);
    assertErrors([StaticWarningCode.COMMENT_REFERENCE_UNDECLARED_CONSTRUCTOR]);
    verify([source]);
  }
  void fail_commentReferenceUndeclaredIdentifier() {
    Source source = addSource(EngineTestCase.createSource([]));
    resolve(source);
    assertErrors([StaticWarningCode.COMMENT_REFERENCE_UNDECLARED_IDENTIFIER]);
    verify([source]);
  }
  void fail_commentReferenceUriNotLibrary() {
    Source source = addSource(EngineTestCase.createSource([]));
    resolve(source);
    assertErrors([StaticWarningCode.COMMENT_REFERENCE_URI_NOT_LIBRARY]);
    verify([source]);
  }
  void fail_finalNotInitialized_inConstructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final int x;", "  A() {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }
  void fail_incorrectNumberOfArguments_tooFew() {
    Source source = addSource(EngineTestCase.createSource(["f(a, b) => 0;", "g() {", "  f(2);", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INCORRECT_NUMBER_OF_ARGUMENTS]);
    verify([source]);
  }
  void fail_incorrectNumberOfArguments_tooMany() {
    Source source = addSource(EngineTestCase.createSource(["f(a, b) => 0;", "g() {", "  f(2, 3, 4);", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INCORRECT_NUMBER_OF_ARGUMENTS]);
    verify([source]);
  }
  void fail_invalidFactoryName() {
    Source source = addSource(EngineTestCase.createSource([]));
    resolve(source);
    assertErrors([StaticWarningCode.INVALID_FACTORY_NAME]);
    verify([source]);
  }
  void fail_invocationOfNonFunction() {
    Source source = addSource(EngineTestCase.createSource([]));
    resolve(source);
    assertErrors([StaticWarningCode.INVOCATION_OF_NON_FUNCTION]);
    verify([source]);
  }
  void fail_mismatchedAccessorTypes_getterAndSuperSetter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int get g { return 0; }", "  set g(int v) {}", "}", "class B extends A {", "  set g(String v) {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES]);
    verify([source]);
  }
  void fail_mismatchedAccessorTypes_superGetterAndSetter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int get g { return 0; }", "  set g(int v) {}", "}", "class B extends A {", "  String get g { return ''; }", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES]);
    verify([source]);
  }
  void fail_undefinedGetter() {
    Source source = addSource(EngineTestCase.createSource([]));
    resolve(source);
    assertErrors([StaticWarningCode.UNDEFINED_GETTER]);
    verify([source]);
  }
  void fail_undefinedIdentifier_commentReference() {
    Source source = addSource(EngineTestCase.createSource(["/** [m] xxx [new B.c] */", "class A {", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.UNDEFINED_IDENTIFIER, StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }
  void fail_undefinedIdentifier_function() {
    Source source = addSource(EngineTestCase.createSource(["int a() => b;"]));
    resolve(source);
    assertErrors([StaticWarningCode.UNDEFINED_IDENTIFIER]);
    verify([source]);
  }
  void fail_undefinedSetter() {
    Source source = addSource(EngineTestCase.createSource(["class C {}", "f(var p) {", "  C.m = 0;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.UNDEFINED_SETTER]);
    verify([source]);
  }
  void fail_undefinedStaticMethodOrGetter_getter() {
    Source source = addSource(EngineTestCase.createSource(["class C {}", "f(var p) {", "  f(C.m);", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.UNDEFINED_STATIC_METHOD_OR_GETTER]);
    verify([source]);
  }
  void fail_undefinedStaticMethodOrGetter_method() {
    Source source = addSource(EngineTestCase.createSource(["class C {}", "f(var p) {", "  f(C.m());", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.UNDEFINED_STATIC_METHOD_OR_GETTER]);
    verify([source]);
  }
  void test_ambiguousImport_typeAnnotation() {
    Source source = addSource(EngineTestCase.createSource(["import 'lib1.dart';", "import 'lib2.dart';", "typedef N FT(N p);", "N f(N p) {", "  N v;", "}", "class A {", "  N m() {}", "}", "class B<T extends N> {}"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["library lib1;", "class N {}"]));
    addSource2("/lib2.dart", EngineTestCase.createSource(["library lib2;", "class N {}"]));
    resolve(source);
    assertErrors([StaticWarningCode.AMBIGUOUS_IMPORT, StaticWarningCode.AMBIGUOUS_IMPORT, StaticWarningCode.AMBIGUOUS_IMPORT, StaticWarningCode.AMBIGUOUS_IMPORT, StaticWarningCode.AMBIGUOUS_IMPORT, StaticWarningCode.AMBIGUOUS_IMPORT, StaticWarningCode.AMBIGUOUS_IMPORT]);
  }
  void test_ambiguousImport_typeArgument_annotation() {
    Source source = addSource(EngineTestCase.createSource(["import 'lib1.dart';", "import 'lib2.dart';", "class A<T> {}", "A<N> f() {}"]));
    addSource2("/lib1.dart", EngineTestCase.createSource(["library lib1;", "class N {}"]));
    addSource2("/lib2.dart", EngineTestCase.createSource(["library lib2;", "class N {}"]));
    resolve(source);
    assertErrors([StaticWarningCode.AMBIGUOUS_IMPORT]);
  }
  void test_argumentTypeNotAssignable_binary() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  operator +(int p) {}", "}", "f(A a) {", "  a + '0';", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_argumentTypeNotAssignable_index() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  operator [](int index) {}", "}", "f(A a) {", "  a['0'];", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_argumentTypeNotAssignable_invocation_callParameter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  call(int p) {}", "}", "f(A a) {", "  a('0');", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_argumentTypeNotAssignable_invocation_callVariable() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  call(int p) {}", "}", "main() {", "  A a = new A();", "  a('0');", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_argumentTypeNotAssignable_invocation_functionParameter() {
    Source source = addSource(EngineTestCase.createSource(["a(b(int p)) {", "  b('0');", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_argumentTypeNotAssignable_invocation_generic() {
    Source source = addSource(EngineTestCase.createSource(["class A<T> {", "  m(T t) {}", "}", "f(A<String> a) {", "  a.m(1);", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_argumentTypeNotAssignable_invocation_named() {
    Source source = addSource(EngineTestCase.createSource(["f({String p}) {}", "main() {", "  f(p: 42);", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_argumentTypeNotAssignable_invocation_optional() {
    Source source = addSource(EngineTestCase.createSource(["f([String p]) {}", "main() {", "  f(42);", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_argumentTypeNotAssignable_invocation_required() {
    Source source = addSource(EngineTestCase.createSource(["f(String p) {}", "main() {", "  f(42);", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_argumentTypeNotAssignable_invocation_typedef_generic() {
    Source source = addSource(EngineTestCase.createSource(["typedef A<T>(T p);", "f(A<int> a) {", "  a('1');", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_argumentTypeNotAssignable_invocation_typedef_local() {
    Source source = addSource(EngineTestCase.createSource(["typedef A(int p);", "A getA() => null;", "main() {", "  A a = getA();", "  a('1');", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_argumentTypeNotAssignable_invocation_typedef_parameter() {
    Source source = addSource(EngineTestCase.createSource(["typedef A(int p);", "f(A a) {", "  a('1');", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_argumentTypeNotAssignable_new_generic() {
    Source source = addSource(EngineTestCase.createSource(["class A<T> {", "  A(T p) {}", "}", "main() {", "  new A<String>(42);", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_argumentTypeNotAssignable_new_optional() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A([String p]) {}", "}", "main() {", "  new A(42);", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_argumentTypeNotAssignable_new_required() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A(String p) {}", "}", "main() {", "  new A(42);", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_assignmentToFinal_instanceVariable() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final v = 0;", "}", "f() {", "  A a = new A();", "  a.v = 1;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }
  void test_assignmentToFinal_localVariable() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  final x = 0;", "  x = 1;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }
  void test_assignmentToFinal_prefixMinusMinus() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  final x = 0;", "  --x;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }
  void test_assignmentToFinal_prefixPlusPlus() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  final x = 0;", "  ++x;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }
  void test_assignmentToFinal_propertyAccess() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int get x => 0;", "}", "class B {", "  static A a;", "}", "main() {", "  B.a.x = 0;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }
  void test_assignmentToFinal_suffixMinusMinus() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  final x = 0;", "  x--;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }
  void test_assignmentToFinal_suffixPlusPlus() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  final x = 0;", "  x++;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }
  void test_assignmentToFinal_topLevelVariable() {
    Source source = addSource(EngineTestCase.createSource(["final x = 0;", "f() { x = 1; }"]));
    resolve(source);
    assertErrors([StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }
  void test_caseBlockNotTerminated() {
    Source source = addSource(EngineTestCase.createSource(["f(int p) {", "  switch (p) {", "    case 0:", "      f(p);", "    case 1:", "      break;", "  }", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.CASE_BLOCK_NOT_TERMINATED]);
    verify([source]);
  }
  void test_castToNonType() {
    Source source = addSource(EngineTestCase.createSource(["var A = 0;", "f(String s) { var x = s as A; }"]));
    resolve(source);
    assertErrors([StaticWarningCode.CAST_TO_NON_TYPE]);
    verify([source]);
  }
  void test_concreteClassWithAbstractMember() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m();", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER]);
    verify([source]);
  }
  void test_conflictingInstanceGetterAndSuperclassMember_direct_field() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static int v;", "}", "class B extends A {", "  get v => 0;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER]);
    verify([source]);
  }
  void test_conflictingInstanceGetterAndSuperclassMember_direct_getter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static get v => 0;", "}", "class B extends A {", "  get v => 0;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER]);
    verify([source]);
  }
  void test_conflictingInstanceGetterAndSuperclassMember_direct_method() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static v() {}", "}", "class B extends A {", "  get v => 0;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER]);
    verify([source]);
  }
  void test_conflictingInstanceGetterAndSuperclassMember_direct_setter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static set v(x) {}", "}", "class B extends A {", "  get v => 0;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER]);
    verify([source]);
  }
  void test_conflictingInstanceGetterAndSuperclassMember_indirect() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static int v;", "}", "class B extends A {}", "class C extends B {", "  get v => 0;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER]);
    verify([source]);
  }
  void test_conflictingInstanceGetterAndSuperclassMember_mixin() {
    Source source = addSource(EngineTestCase.createSource(["class M {", "  static int v;", "}", "class B extends Object with M {", "  get v => 0;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER]);
    verify([source]);
  }
  void test_conflictingInstanceSetterAndSuperclassMember() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static int v;", "}", "class B extends A {", "  set v(x) {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER]);
    verify([source]);
  }
  void test_conflictingStaticGetterAndInstanceSetter_mixin() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  set x(int p) {}", "}", "class B extends Object with A {", "  static get x => 0;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER]);
    verify([source]);
  }
  void test_conflictingStaticGetterAndInstanceSetter_superClass() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  set x(int p) {}", "}", "class B extends A {", "  static get x => 0;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER]);
    verify([source]);
  }
  void test_conflictingStaticGetterAndInstanceSetter_thisClass() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static get x => 0;", "  set x(int p) {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER]);
    verify([source]);
  }
  void test_conflictingStaticSetterAndInstanceMember_thisClass_getter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  get x => 0;", "  static set x(int p) {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER]);
    verify([source]);
  }
  void test_conflictingStaticSetterAndInstanceMember_thisClass_method() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  x() {}", "  static set x(int p) {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER]);
    verify([source]);
  }
  void test_constWithAbstractClass() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A {", "  const A();", "}", "void f() {", "  A a = const A();", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.CONST_WITH_ABSTRACT_CLASS]);
    verify([source]);
  }
  void test_equalKeysInMap() {
    Source source = addSource(EngineTestCase.createSource(["var m = {'a' : 0, 'b' : 1, 'a' : 2};"]));
    resolve(source);
    assertErrors([StaticWarningCode.EQUAL_KEYS_IN_MAP]);
    verify([source]);
  }
  void test_exportDuplicatedLibraryName() {
    Source source = addSource(EngineTestCase.createSource(["library test;", "export 'lib1.dart';", "export 'lib2.dart';"]));
    addSource2("/lib1.dart", "library lib;");
    addSource2("/lib2.dart", "library lib;");
    resolve(source);
    assertErrors([StaticWarningCode.EXPORT_DUPLICATED_LIBRARY_NAME]);
    verify([source]);
  }
  void test_extraPositionalArguments() {
    Source source = addSource(EngineTestCase.createSource(["f() {}", "main() {", "  f(0, 1, '2');", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS]);
    verify([source]);
  }
  void test_fieldInitializerNotAssignable() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "  A() : x = '';", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_fieldInitializingFormalNotAssignable() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "  A(String this.x) {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_finalNotInitialized_instanceField_const_static() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static const F;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }
  void test_finalNotInitialized_instanceField_final() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  final F;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }
  void test_finalNotInitialized_instanceField_final_static() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static final F;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }
  void test_finalNotInitialized_library_const() {
    Source source = addSource(EngineTestCase.createSource(["const F;"]));
    resolve(source);
    assertErrors([StaticWarningCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }
  void test_finalNotInitialized_library_final() {
    Source source = addSource(EngineTestCase.createSource(["final F;"]));
    resolve(source);
    assertErrors([StaticWarningCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }
  void test_finalNotInitialized_local_const() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  const int x;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }
  void test_finalNotInitialized_local_final() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  final int x;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }
  void test_importDuplicatedLibraryName() {
    Source source = addSource(EngineTestCase.createSource(["library test;", "import 'lib1.dart';", "import 'lib2.dart';"]));
    addSource2("/lib1.dart", "library lib;");
    addSource2("/lib2.dart", "library lib;");
    resolve(source);
    assertErrors([StaticWarningCode.IMPORT_DUPLICATED_LIBRARY_NAME]);
    verify([source]);
  }
  void test_inconsistentMethodInheritanceGetterAndMethod() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A {", "  int x();", "}", "abstract class B {", "  int get x;", "}", "class C implements A, B {", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD]);
    verify([source]);
  }
  void test_instanceMethodNameCollidesWithSuperclassStatic_field() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static var n;", "}", "class B extends A {", "  void n() {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC]);
    verify([source]);
  }
  void test_instanceMethodNameCollidesWithSuperclassStatic_field2() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static var n;", "}", "class B extends A {", "}", "class C extends B {", "  void n() {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC]);
    verify([source]);
  }
  void test_instanceMethodNameCollidesWithSuperclassStatic_getter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static get n {return 0;}", "}", "class B extends A {", "  void n() {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC]);
    verify([source]);
  }
  void test_instanceMethodNameCollidesWithSuperclassStatic_getter2() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static get n {return 0;}", "}", "class B extends A {", "}", "class C extends B {", "  void n() {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC]);
    verify([source]);
  }
  void test_instanceMethodNameCollidesWithSuperclassStatic_method() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static n () {}", "}", "class B extends A {", "  void n() {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC]);
    verify([source]);
  }
  void test_instanceMethodNameCollidesWithSuperclassStatic_method2() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static n () {}", "}", "class B extends A {", "}", "class C extends B {", "  void n() {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC]);
    verify([source]);
  }
  void test_instanceMethodNameCollidesWithSuperclassStatic_setter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int i = 0;", "  static set n(int x) {i = x;}", "}", "class B extends A {", "  void n() {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC]);
    verify([source]);
  }
  void test_instanceMethodNameCollidesWithSuperclassStatic_setter2() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int i = 0;", "  static set n(int x) {i = x;}", "}", "class B extends A {", "}", "class C extends B {", "  void n() {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC]);
    verify([source]);
  }
  void test_invalidGetterOverrideReturnType() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int get g { return 0; }", "}", "class B extends A {", "  String get g { return 'a'; }", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INVALID_GETTER_OVERRIDE_RETURN_TYPE]);
    verify([source]);
  }
  void test_invalidMethodOverrideNamedParamType() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m({int a}) {}", "}", "class B implements A {", "  m({String a}) {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE]);
    verify([source]);
  }
  void test_invalidMethodOverrideNormalParamType() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m(int a) {}", "}", "class B implements A {", "  m(String a) {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE]);
    verify([source]);
  }
  void test_invalidMethodOverrideOptionalParamType() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m([int a]) {}", "}", "class B implements A {", "  m([String a]) {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE]);
    verify([source]);
  }
  void test_invalidMethodOverrideReturnType_interface() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int m() { return 0; }", "}", "class B implements A {", "  String m() { return 'a'; }", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INVALID_METHOD_OVERRIDE_RETURN_TYPE]);
    verify([source]);
  }
  void test_invalidMethodOverrideReturnType_interface2() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A {", "  int m();", "}", "abstract class B implements A {", "}", "class C implements B {", "  String m() { return 'a'; }", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INVALID_METHOD_OVERRIDE_RETURN_TYPE]);
    verify([source]);
  }
  void test_invalidMethodOverrideReturnType_mixin() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int m() { return 0; }", "}", "class B extends Object with A {", "  String m() { return 'a'; }", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INVALID_METHOD_OVERRIDE_RETURN_TYPE]);
    verify([source]);
  }
  void test_invalidMethodOverrideReturnType_superclass() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int m() { return 0; }", "}", "class B extends A {", "  String m() { return 'a'; }", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INVALID_METHOD_OVERRIDE_RETURN_TYPE]);
    verify([source]);
  }
  void test_invalidMethodOverrideReturnType_superclass2() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int m() { return 0; }", "}", "class B extends A {", "}", "class C extends B {", "  String m() { return 'a'; }", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INVALID_METHOD_OVERRIDE_RETURN_TYPE]);
    verify([source]);
  }
  void test_invalidMethodOverrideReturnType_void() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int m() {}", "}", "class B extends A {", "  void m() {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INVALID_METHOD_OVERRIDE_RETURN_TYPE]);
    verify([source]);
  }
  void test_invalidOverrideDifferentDefaultValues_named() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m({int p : 0}) {}", "}", "class B extends A {", "  m({int p : 1}) {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED]);
    verify([source]);
  }
  void test_invalidOverrideDifferentDefaultValues_positional() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m([int p = 0]) {}", "}", "class B extends A {", "  m([int p = 1]) {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL]);
    verify([source]);
  }
  void test_invalidSetterOverrideNormalParamType() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void set s(int v) {}", "}", "class B extends A {", "  void set s(String v) {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE]);
    verify([source]);
  }
  void test_mismatchedAccessorTypes_class() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int get g { return 0; }", "  set g(String v) {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES]);
    verify([source]);
  }
  void test_mismatchedAccessorTypes_topLevel() {
    Source source = addSource(EngineTestCase.createSource(["int get g { return 0; }", "set g(String v) {}"]));
    resolve(source);
    assertErrors([StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES]);
    verify([source]);
  }
  void test_newWithAbstractClass() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A {}", "void f() {", "  A a = new A();", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NEW_WITH_ABSTRACT_CLASS]);
    verify([source]);
  }
  void test_newWithNonType() {
    Source source = addSource(EngineTestCase.createSource(["var A = 0;", "void f() {", "  var a = new A();", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NEW_WITH_NON_TYPE]);
    verify([source]);
  }
  void test_newWithUndefinedConstructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A() {}", "}", "f() {", "  new A.name();", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR]);
  }
  void test_newWithUndefinedConstructorDefault() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A.name() {}", "}", "f() {", "  new A();", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT]);
    verify([source]);
  }
  void test_noDefaultSuperConstructorExplicit() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A(p);", "}", "class B extends A {", "  B() {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT]);
    verify([source]);
  }
  void test_noDefaultSuperConstructorImplicit_superHasParameters() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A(p);", "}", "class B extends A {", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }
  void test_noDefaultSuperConstructorImplicit_superOnlyNamed() {
    Source source = addSource(EngineTestCase.createSource(["class A { A.named() {} }", "class B extends A {}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }
  void test_nonAbstractClassInheritsAbstractMemberFivePlus() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A {", "  m();", "  n();", "  o();", "  p();", "  q();", "}", "class C extends A {", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS]);
    verify([source]);
  }
  void test_nonAbstractClassInheritsAbstractMemberFour() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A {", "  m();", "  n();", "  o();", "  p();", "}", "class C extends A {", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR]);
    verify([source]);
  }
  void test_nonAbstractClassInheritsAbstractMemberOne_getter_fromInterface() {
    Source source = addSource(EngineTestCase.createSource(["class I {", "  int get g {return 1;}", "}", "class C implements I {", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }
  void test_nonAbstractClassInheritsAbstractMemberOne_getter_fromSuperclass() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A {", "  int get g;", "}", "class C extends A {", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }
  void test_nonAbstractClassInheritsAbstractMemberOne_method_fromInterface() {
    Source source = addSource(EngineTestCase.createSource(["class I {", "  m(p) {}", "}", "class C implements I {", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }
  void test_nonAbstractClassInheritsAbstractMemberOne_method_fromSuperclass() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A {", "  m(p);", "}", "class C extends A {", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }
  void test_nonAbstractClassInheritsAbstractMemberOne_method_optionalParamCount() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A {", "  int x(int a);", "}", "abstract class B {", "  int x(int a, [int b]);", "}", "class C implements A, B {", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }
  void test_nonAbstractClassInheritsAbstractMemberOne_setter_fromInterface() {
    Source source = addSource(EngineTestCase.createSource(["class I {", "  set s(int i) {}", "}", "class C implements I {", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }
  void test_nonAbstractClassInheritsAbstractMemberOne_setter_fromSuperclass() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A {", "  set s(int i);", "}", "class C extends A {", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }
  void test_nonAbstractClassInheritsAbstractMemberOne_superclasses_interface() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  get a => 'a';", "}", "abstract class B implements A {", "  get b => 'b';", "}", "class C extends B {", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE]);
    verify([source]);
  }
  void test_nonAbstractClassInheritsAbstractMemberThree() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A {", "  m();", "  n();", "  o();", "}", "class C extends A {", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE]);
    verify([source]);
  }
  void test_nonAbstractClassInheritsAbstractMemberTwo() {
    Source source = addSource(EngineTestCase.createSource(["abstract class A {", "  m();", "  n();", "}", "class C extends A {", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO]);
    verify([source]);
  }
  void test_nonTypeInCatchClause_noElement() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  try {", "  } on T catch (e) {", "  }", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE]);
    verify([source]);
  }
  void test_nonTypeInCatchClause_notType() {
    Source source = addSource(EngineTestCase.createSource(["var T = 0;", "f() {", "  try {", "  } on T catch (e) {", "  }", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE]);
    verify([source]);
  }
  void test_nonVoidReturnForOperator() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int operator []=(a, b) {}", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NON_VOID_RETURN_FOR_OPERATOR]);
    verify([source]);
  }
  void test_nonVoidReturnForSetter_function() {
    Source source = addSource(EngineTestCase.createSource(["int set x(int v) {", "  return 42;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NON_VOID_RETURN_FOR_SETTER]);
    verify([source]);
  }
  void test_nonVoidReturnForSetter_method() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int set x(int v) {", "    return 42;", "  }", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NON_VOID_RETURN_FOR_SETTER]);
    verify([source]);
  }
  void test_notAType() {
    Source source = addSource(EngineTestCase.createSource(["f() {}", "main() {", "  f v = null;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NOT_A_TYPE]);
    verify([source]);
  }
  void test_notEnoughRequiredArguments() {
    Source source = addSource(EngineTestCase.createSource(["f(int a, String b) {}", "main() {", "  f();", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.NOT_ENOUGH_REQUIRED_ARGUMENTS]);
    verify([source]);
  }
  void test_partOfDifferentLibrary() {
    Source source = addSource(EngineTestCase.createSource(["library lib;", "part 'part.dart';"]));
    addSource2("/part.dart", EngineTestCase.createSource(["part of lub;"]));
    resolve(source);
    assertErrors([StaticWarningCode.PART_OF_DIFFERENT_LIBRARY]);
    verify([source]);
  }
  void test_redirectToInvalidFunctionType() {
    Source source = addSource(EngineTestCase.createSource(["class A implements B {", "  A(int p) {}", "}", "class B {", "  B() = A;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.REDIRECT_TO_INVALID_FUNCTION_TYPE]);
    verify([source]);
  }
  void test_redirectToInvalidReturnType() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A() {}", "}", "class B {", "  B() = A;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.REDIRECT_TO_INVALID_RETURN_TYPE]);
    verify([source]);
  }
  void test_redirectToMissingConstructor_named() {
    Source source = addSource(EngineTestCase.createSource(["class A implements B{", "  A() {}", "}", "class B {", "  B() = A.name;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.REDIRECT_TO_MISSING_CONSTRUCTOR]);
  }
  void test_redirectToMissingConstructor_unnamed() {
    Source source = addSource(EngineTestCase.createSource(["class A implements B{", "  A.name() {}", "}", "class B {", "  B() = A;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.REDIRECT_TO_MISSING_CONSTRUCTOR]);
  }
  void test_redirectToNonClass() {
    Source source = addSource(EngineTestCase.createSource(["class B {", "  B() = A;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.REDIRECT_TO_NON_CLASS]);
    verify([source]);
  }
  void test_returnWithoutValue() {
    Source source = addSource(EngineTestCase.createSource(["int f() { return; }"]));
    resolve(source);
    assertErrors([StaticWarningCode.RETURN_WITHOUT_VALUE]);
    verify([source]);
  }
  void test_staticAccessToInstanceMember_method_invocation() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m() {}", "}", "main() {", "  A.m();", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER]);
    verify([source]);
  }
  void test_staticAccessToInstanceMember_method_reference() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  m() {}", "}", "main() {", "  A.m;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER]);
    verify([source]);
  }
  void test_staticAccessToInstanceMember_propertyAccess_field() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  var f;", "}", "main() {", "  A.f;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER]);
    verify([source]);
  }
  void test_staticAccessToInstanceMember_propertyAccess_getter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  get f => 42;", "}", "main() {", "  A.f;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER]);
    verify([source]);
  }
  void test_staticAccessToInstanceMember_propertyAccess_setter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  set f(x) {}", "}", "main() {", "  A.f = 42;", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER]);
    verify([source]);
  }
  void test_switchExpressionNotAssignable() {
    Source source = addSource(EngineTestCase.createSource(["f(int p) {", "  switch (p) {", "    case 'a': break;", "  }", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.SWITCH_EXPRESSION_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void test_typeTestNonType() {
    Source source = addSource(EngineTestCase.createSource(["var A = 0;", "f(var p) {", "  if (p is A) {", "  }", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.TYPE_TEST_NON_TYPE]);
    verify([source]);
  }
  void test_undefinedClass_instanceCreation() {
    Source source = addSource(EngineTestCase.createSource(["f() { new C(); }"]));
    resolve(source);
    assertErrors([StaticWarningCode.UNDEFINED_CLASS]);
  }
  void test_undefinedClass_variableDeclaration() {
    Source source = addSource(EngineTestCase.createSource(["f() { C c; }"]));
    resolve(source);
    assertErrors([StaticWarningCode.UNDEFINED_CLASS]);
  }
  void test_undefinedClassBoolean_variableDeclaration() {
    Source source = addSource(EngineTestCase.createSource(["f() { boolean v; }"]));
    resolve(source);
    assertErrors([StaticWarningCode.UNDEFINED_CLASS_BOOLEAN]);
  }
  void test_undefinedIdentifier_initializer() {
    Source source = addSource(EngineTestCase.createSource(["var a = b;"]));
    resolve(source);
    assertErrors([StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }
  void test_undefinedIdentifier_metadata() {
    Source source = addSource(EngineTestCase.createSource(["@undefined class A {}"]));
    resolve(source);
    assertErrors([StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }
  void test_undefinedIdentifier_methodInvocation() {
    Source source = addSource(EngineTestCase.createSource(["f() { C.m(); }"]));
    resolve(source);
    assertErrors([StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }
  void test_undefinedNamedParameter() {
    Source source = addSource(EngineTestCase.createSource(["f({a, b}) {}", "main() {", "  f(c: 1);", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.UNDEFINED_NAMED_PARAMETER]);
  }
  static dartSuite() {
    _ut.group('StaticWarningCodeTest', () {
      _ut.test('test_ambiguousImport_typeAnnotation', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_ambiguousImport_typeAnnotation);
      });
      _ut.test('test_ambiguousImport_typeArgument_annotation', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_ambiguousImport_typeArgument_annotation);
      });
      _ut.test('test_argumentTypeNotAssignable_binary', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_binary);
      });
      _ut.test('test_argumentTypeNotAssignable_index', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_index);
      });
      _ut.test('test_argumentTypeNotAssignable_invocation_callParameter', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_invocation_callParameter);
      });
      _ut.test('test_argumentTypeNotAssignable_invocation_callVariable', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_invocation_callVariable);
      });
      _ut.test('test_argumentTypeNotAssignable_invocation_functionParameter', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_invocation_functionParameter);
      });
      _ut.test('test_argumentTypeNotAssignable_invocation_generic', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_invocation_generic);
      });
      _ut.test('test_argumentTypeNotAssignable_invocation_named', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_invocation_named);
      });
      _ut.test('test_argumentTypeNotAssignable_invocation_optional', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_invocation_optional);
      });
      _ut.test('test_argumentTypeNotAssignable_invocation_required', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_invocation_required);
      });
      _ut.test('test_argumentTypeNotAssignable_invocation_typedef_generic', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_invocation_typedef_generic);
      });
      _ut.test('test_argumentTypeNotAssignable_invocation_typedef_local', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_invocation_typedef_local);
      });
      _ut.test('test_argumentTypeNotAssignable_invocation_typedef_parameter', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_invocation_typedef_parameter);
      });
      _ut.test('test_argumentTypeNotAssignable_new_generic', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_new_generic);
      });
      _ut.test('test_argumentTypeNotAssignable_new_optional', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_new_optional);
      });
      _ut.test('test_argumentTypeNotAssignable_new_required', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_argumentTypeNotAssignable_new_required);
      });
      _ut.test('test_assignmentToFinal_instanceVariable', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_assignmentToFinal_instanceVariable);
      });
      _ut.test('test_assignmentToFinal_localVariable', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_assignmentToFinal_localVariable);
      });
      _ut.test('test_assignmentToFinal_prefixMinusMinus', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_assignmentToFinal_prefixMinusMinus);
      });
      _ut.test('test_assignmentToFinal_prefixPlusPlus', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_assignmentToFinal_prefixPlusPlus);
      });
      _ut.test('test_assignmentToFinal_propertyAccess', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_assignmentToFinal_propertyAccess);
      });
      _ut.test('test_assignmentToFinal_suffixMinusMinus', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_assignmentToFinal_suffixMinusMinus);
      });
      _ut.test('test_assignmentToFinal_suffixPlusPlus', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_assignmentToFinal_suffixPlusPlus);
      });
      _ut.test('test_assignmentToFinal_topLevelVariable', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_assignmentToFinal_topLevelVariable);
      });
      _ut.test('test_caseBlockNotTerminated', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_caseBlockNotTerminated);
      });
      _ut.test('test_castToNonType', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_castToNonType);
      });
      _ut.test('test_concreteClassWithAbstractMember', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_concreteClassWithAbstractMember);
      });
      _ut.test('test_conflictingInstanceGetterAndSuperclassMember_direct_field', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_conflictingInstanceGetterAndSuperclassMember_direct_field);
      });
      _ut.test('test_conflictingInstanceGetterAndSuperclassMember_direct_getter', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_conflictingInstanceGetterAndSuperclassMember_direct_getter);
      });
      _ut.test('test_conflictingInstanceGetterAndSuperclassMember_direct_method', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_conflictingInstanceGetterAndSuperclassMember_direct_method);
      });
      _ut.test('test_conflictingInstanceGetterAndSuperclassMember_direct_setter', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_conflictingInstanceGetterAndSuperclassMember_direct_setter);
      });
      _ut.test('test_conflictingInstanceGetterAndSuperclassMember_indirect', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_conflictingInstanceGetterAndSuperclassMember_indirect);
      });
      _ut.test('test_conflictingInstanceGetterAndSuperclassMember_mixin', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_conflictingInstanceGetterAndSuperclassMember_mixin);
      });
      _ut.test('test_conflictingInstanceSetterAndSuperclassMember', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_conflictingInstanceSetterAndSuperclassMember);
      });
      _ut.test('test_conflictingStaticGetterAndInstanceSetter_mixin', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_conflictingStaticGetterAndInstanceSetter_mixin);
      });
      _ut.test('test_conflictingStaticGetterAndInstanceSetter_superClass', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_conflictingStaticGetterAndInstanceSetter_superClass);
      });
      _ut.test('test_conflictingStaticGetterAndInstanceSetter_thisClass', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_conflictingStaticGetterAndInstanceSetter_thisClass);
      });
      _ut.test('test_conflictingStaticSetterAndInstanceMember_thisClass_getter', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_conflictingStaticSetterAndInstanceMember_thisClass_getter);
      });
      _ut.test('test_conflictingStaticSetterAndInstanceMember_thisClass_method', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_conflictingStaticSetterAndInstanceMember_thisClass_method);
      });
      _ut.test('test_constWithAbstractClass', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_constWithAbstractClass);
      });
      _ut.test('test_equalKeysInMap', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_equalKeysInMap);
      });
      _ut.test('test_exportDuplicatedLibraryName', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_exportDuplicatedLibraryName);
      });
      _ut.test('test_extraPositionalArguments', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_extraPositionalArguments);
      });
      _ut.test('test_fieldInitializerNotAssignable', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_fieldInitializerNotAssignable);
      });
      _ut.test('test_fieldInitializingFormalNotAssignable', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_fieldInitializingFormalNotAssignable);
      });
      _ut.test('test_finalNotInitialized_instanceField_const_static', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_finalNotInitialized_instanceField_const_static);
      });
      _ut.test('test_finalNotInitialized_instanceField_final', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_finalNotInitialized_instanceField_final);
      });
      _ut.test('test_finalNotInitialized_instanceField_final_static', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_finalNotInitialized_instanceField_final_static);
      });
      _ut.test('test_finalNotInitialized_library_const', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_finalNotInitialized_library_const);
      });
      _ut.test('test_finalNotInitialized_library_final', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_finalNotInitialized_library_final);
      });
      _ut.test('test_finalNotInitialized_local_const', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_finalNotInitialized_local_const);
      });
      _ut.test('test_finalNotInitialized_local_final', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_finalNotInitialized_local_final);
      });
      _ut.test('test_importDuplicatedLibraryName', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_importDuplicatedLibraryName);
      });
      _ut.test('test_inconsistentMethodInheritanceGetterAndMethod', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_inconsistentMethodInheritanceGetterAndMethod);
      });
      _ut.test('test_instanceMethodNameCollidesWithSuperclassStatic_field', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_instanceMethodNameCollidesWithSuperclassStatic_field);
      });
      _ut.test('test_instanceMethodNameCollidesWithSuperclassStatic_field2', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_instanceMethodNameCollidesWithSuperclassStatic_field2);
      });
      _ut.test('test_instanceMethodNameCollidesWithSuperclassStatic_getter', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_instanceMethodNameCollidesWithSuperclassStatic_getter);
      });
      _ut.test('test_instanceMethodNameCollidesWithSuperclassStatic_getter2', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_instanceMethodNameCollidesWithSuperclassStatic_getter2);
      });
      _ut.test('test_instanceMethodNameCollidesWithSuperclassStatic_method', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_instanceMethodNameCollidesWithSuperclassStatic_method);
      });
      _ut.test('test_instanceMethodNameCollidesWithSuperclassStatic_method2', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_instanceMethodNameCollidesWithSuperclassStatic_method2);
      });
      _ut.test('test_instanceMethodNameCollidesWithSuperclassStatic_setter', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_instanceMethodNameCollidesWithSuperclassStatic_setter);
      });
      _ut.test('test_instanceMethodNameCollidesWithSuperclassStatic_setter2', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_instanceMethodNameCollidesWithSuperclassStatic_setter2);
      });
      _ut.test('test_invalidGetterOverrideReturnType', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_invalidGetterOverrideReturnType);
      });
      _ut.test('test_invalidMethodOverrideNamedParamType', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_invalidMethodOverrideNamedParamType);
      });
      _ut.test('test_invalidMethodOverrideNormalParamType', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_invalidMethodOverrideNormalParamType);
      });
      _ut.test('test_invalidMethodOverrideOptionalParamType', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_invalidMethodOverrideOptionalParamType);
      });
      _ut.test('test_invalidMethodOverrideReturnType_interface', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_invalidMethodOverrideReturnType_interface);
      });
      _ut.test('test_invalidMethodOverrideReturnType_interface2', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_invalidMethodOverrideReturnType_interface2);
      });
      _ut.test('test_invalidMethodOverrideReturnType_mixin', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_invalidMethodOverrideReturnType_mixin);
      });
      _ut.test('test_invalidMethodOverrideReturnType_superclass', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_invalidMethodOverrideReturnType_superclass);
      });
      _ut.test('test_invalidMethodOverrideReturnType_superclass2', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_invalidMethodOverrideReturnType_superclass2);
      });
      _ut.test('test_invalidMethodOverrideReturnType_void', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_invalidMethodOverrideReturnType_void);
      });
      _ut.test('test_invalidOverrideDifferentDefaultValues_named', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_invalidOverrideDifferentDefaultValues_named);
      });
      _ut.test('test_invalidOverrideDifferentDefaultValues_positional', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_invalidOverrideDifferentDefaultValues_positional);
      });
      _ut.test('test_invalidSetterOverrideNormalParamType', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_invalidSetterOverrideNormalParamType);
      });
      _ut.test('test_mismatchedAccessorTypes_class', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_mismatchedAccessorTypes_class);
      });
      _ut.test('test_mismatchedAccessorTypes_topLevel', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_mismatchedAccessorTypes_topLevel);
      });
      _ut.test('test_newWithAbstractClass', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_newWithAbstractClass);
      });
      _ut.test('test_newWithNonType', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_newWithNonType);
      });
      _ut.test('test_newWithUndefinedConstructor', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_newWithUndefinedConstructor);
      });
      _ut.test('test_newWithUndefinedConstructorDefault', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_newWithUndefinedConstructorDefault);
      });
      _ut.test('test_noDefaultSuperConstructorExplicit', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_noDefaultSuperConstructorExplicit);
      });
      _ut.test('test_noDefaultSuperConstructorImplicit_superHasParameters', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_noDefaultSuperConstructorImplicit_superHasParameters);
      });
      _ut.test('test_noDefaultSuperConstructorImplicit_superOnlyNamed', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_noDefaultSuperConstructorImplicit_superOnlyNamed);
      });
      _ut.test('test_nonAbstractClassInheritsAbstractMemberFivePlus', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_nonAbstractClassInheritsAbstractMemberFivePlus);
      });
      _ut.test('test_nonAbstractClassInheritsAbstractMemberFour', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_nonAbstractClassInheritsAbstractMemberFour);
      });
      _ut.test('test_nonAbstractClassInheritsAbstractMemberOne_getter_fromInterface', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_nonAbstractClassInheritsAbstractMemberOne_getter_fromInterface);
      });
      _ut.test('test_nonAbstractClassInheritsAbstractMemberOne_getter_fromSuperclass', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_nonAbstractClassInheritsAbstractMemberOne_getter_fromSuperclass);
      });
      _ut.test('test_nonAbstractClassInheritsAbstractMemberOne_method_fromInterface', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_nonAbstractClassInheritsAbstractMemberOne_method_fromInterface);
      });
      _ut.test('test_nonAbstractClassInheritsAbstractMemberOne_method_fromSuperclass', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_nonAbstractClassInheritsAbstractMemberOne_method_fromSuperclass);
      });
      _ut.test('test_nonAbstractClassInheritsAbstractMemberOne_method_optionalParamCount', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_nonAbstractClassInheritsAbstractMemberOne_method_optionalParamCount);
      });
      _ut.test('test_nonAbstractClassInheritsAbstractMemberOne_setter_fromInterface', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_nonAbstractClassInheritsAbstractMemberOne_setter_fromInterface);
      });
      _ut.test('test_nonAbstractClassInheritsAbstractMemberOne_setter_fromSuperclass', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_nonAbstractClassInheritsAbstractMemberOne_setter_fromSuperclass);
      });
      _ut.test('test_nonAbstractClassInheritsAbstractMemberOne_superclasses_interface', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_nonAbstractClassInheritsAbstractMemberOne_superclasses_interface);
      });
      _ut.test('test_nonAbstractClassInheritsAbstractMemberThree', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_nonAbstractClassInheritsAbstractMemberThree);
      });
      _ut.test('test_nonAbstractClassInheritsAbstractMemberTwo', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_nonAbstractClassInheritsAbstractMemberTwo);
      });
      _ut.test('test_nonTypeInCatchClause_noElement', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_nonTypeInCatchClause_noElement);
      });
      _ut.test('test_nonTypeInCatchClause_notType', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_nonTypeInCatchClause_notType);
      });
      _ut.test('test_nonVoidReturnForOperator', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_nonVoidReturnForOperator);
      });
      _ut.test('test_nonVoidReturnForSetter_function', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_nonVoidReturnForSetter_function);
      });
      _ut.test('test_nonVoidReturnForSetter_method', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_nonVoidReturnForSetter_method);
      });
      _ut.test('test_notAType', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_notAType);
      });
      _ut.test('test_notEnoughRequiredArguments', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_notEnoughRequiredArguments);
      });
      _ut.test('test_partOfDifferentLibrary', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_partOfDifferentLibrary);
      });
      _ut.test('test_redirectToInvalidFunctionType', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_redirectToInvalidFunctionType);
      });
      _ut.test('test_redirectToInvalidReturnType', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_redirectToInvalidReturnType);
      });
      _ut.test('test_redirectToMissingConstructor_named', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_redirectToMissingConstructor_named);
      });
      _ut.test('test_redirectToMissingConstructor_unnamed', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_redirectToMissingConstructor_unnamed);
      });
      _ut.test('test_redirectToNonClass', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_redirectToNonClass);
      });
      _ut.test('test_returnWithoutValue', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_returnWithoutValue);
      });
      _ut.test('test_staticAccessToInstanceMember_method_invocation', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_staticAccessToInstanceMember_method_invocation);
      });
      _ut.test('test_staticAccessToInstanceMember_method_reference', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_staticAccessToInstanceMember_method_reference);
      });
      _ut.test('test_staticAccessToInstanceMember_propertyAccess_field', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_staticAccessToInstanceMember_propertyAccess_field);
      });
      _ut.test('test_staticAccessToInstanceMember_propertyAccess_getter', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_staticAccessToInstanceMember_propertyAccess_getter);
      });
      _ut.test('test_staticAccessToInstanceMember_propertyAccess_setter', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_staticAccessToInstanceMember_propertyAccess_setter);
      });
      _ut.test('test_switchExpressionNotAssignable', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_switchExpressionNotAssignable);
      });
      _ut.test('test_typeTestNonType', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_typeTestNonType);
      });
      _ut.test('test_undefinedClassBoolean_variableDeclaration', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_undefinedClassBoolean_variableDeclaration);
      });
      _ut.test('test_undefinedClass_instanceCreation', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_undefinedClass_instanceCreation);
      });
      _ut.test('test_undefinedClass_variableDeclaration', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_undefinedClass_variableDeclaration);
      });
      _ut.test('test_undefinedIdentifier_initializer', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_undefinedIdentifier_initializer);
      });
      _ut.test('test_undefinedIdentifier_metadata', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_undefinedIdentifier_metadata);
      });
      _ut.test('test_undefinedIdentifier_methodInvocation', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_undefinedIdentifier_methodInvocation);
      });
      _ut.test('test_undefinedNamedParameter', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_undefinedNamedParameter);
      });
    });
  }
}
class ErrorResolverTest extends ResolverTestCase {
  void test_breakLabelOnSwitchMember() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void m(int i) {", "    switch (i) {", "      l: case 0:", "        break;", "      case 1:", "        break l;", "    }", "  }", "}"]));
    resolve(source);
    assertErrors([ResolverErrorCode.BREAK_LABEL_ON_SWITCH_MEMBER]);
    verify([source]);
  }
  void test_continueLabelOnSwitch() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void m(int i) {", "    l: switch (i) {", "      case 0:", "        continue l;", "    }", "  }", "}"]));
    resolve(source);
    assertErrors([ResolverErrorCode.CONTINUE_LABEL_ON_SWITCH]);
    verify([source]);
  }
  static dartSuite() {
    _ut.group('ErrorResolverTest', () {
      _ut.test('test_breakLabelOnSwitchMember', () {
        final __test = new ErrorResolverTest();
        runJUnitTest(__test, __test.test_breakLabelOnSwitchMember);
      });
      _ut.test('test_continueLabelOnSwitch', () {
        final __test = new ErrorResolverTest();
        runJUnitTest(__test, __test.test_continueLabelOnSwitch);
      });
    });
  }
}
/**
 * Instances of the class `TestTypeProvider` implement a type provider that can be used by
 * tests without creating the element model for the core library.
 */
class TestTypeProvider implements TypeProvider {

  /**
   * The type representing the built-in type 'bool'.
   */
  InterfaceType _boolType;

  /**
   * The type representing the type 'bottom'.
   */
  Type2 _bottomType;

  /**
   * The type representing the built-in type 'double'.
   */
  InterfaceType _doubleType;

  /**
   * The type representing the built-in type 'dynamic'.
   */
  Type2 _dynamicType;

  /**
   * The type representing the built-in type 'Function'.
   */
  InterfaceType _functionType;

  /**
   * The type representing the built-in type 'int'.
   */
  InterfaceType _intType;

  /**
   * The type representing the built-in type 'Iterable'.
   */
  InterfaceType _iterableType;

  /**
   * The type representing the built-in type 'Iterator'.
   */
  InterfaceType _iteratorType;

  /**
   * The type representing the built-in type 'List'.
   */
  InterfaceType _listType;

  /**
   * The type representing the built-in type 'Map'.
   */
  InterfaceType _mapType;

  /**
   * The type representing the built-in type 'num'.
   */
  InterfaceType _numType;

  /**
   * The type representing the built-in type 'Object'.
   */
  InterfaceType _objectType;

  /**
   * The type representing the built-in type 'StackTrace'.
   */
  InterfaceType _stackTraceType;

  /**
   * The type representing the built-in type 'String'.
   */
  InterfaceType _stringType;

  /**
   * The type representing the built-in type 'Type'.
   */
  InterfaceType _typeType;
  InterfaceType get boolType {
    if (_boolType == null) {
      _boolType = ElementFactory.classElement2("bool", []).type;
    }
    return _boolType;
  }
  Type2 get bottomType {
    if (_bottomType == null) {
      _bottomType = BottomTypeImpl.instance;
    }
    return _bottomType;
  }
  InterfaceType get doubleType {
    if (_doubleType == null) {
      initializeNumericTypes();
    }
    return _doubleType;
  }
  Type2 get dynamicType {
    if (_dynamicType == null) {
      _dynamicType = DynamicTypeImpl.instance;
    }
    return _dynamicType;
  }
  InterfaceType get functionType {
    if (_functionType == null) {
      _functionType = ElementFactory.classElement2("Function", []).type;
    }
    return _functionType;
  }
  InterfaceType get intType {
    if (_intType == null) {
      initializeNumericTypes();
    }
    return _intType;
  }
  InterfaceType get iterableType {
    if (_iterableType == null) {
      ClassElementImpl iterableElement = ElementFactory.classElement2("Iterable", ["E"]);
      _iterableType = iterableElement.type;
      Type2 eType = iterableElement.typeVariables[0].type;
      iterableElement.accessors = <PropertyAccessorElement> [ElementFactory.getterElement("iterator", false, iteratorType.substitute5(<Type2> [eType])), ElementFactory.getterElement("last", false, eType)];
      propagateTypeArguments(iterableElement);
    }
    return _iterableType;
  }
  InterfaceType get iteratorType {
    if (_iteratorType == null) {
      ClassElementImpl iteratorElement = ElementFactory.classElement2("Iterator", ["E"]);
      _iteratorType = iteratorElement.type;
      Type2 eType = iteratorElement.typeVariables[0].type;
      iteratorElement.accessors = <PropertyAccessorElement> [ElementFactory.getterElement("current", false, eType)];
      propagateTypeArguments(iteratorElement);
    }
    return _iteratorType;
  }
  InterfaceType get listType {
    if (_listType == null) {
      ClassElementImpl listElement = ElementFactory.classElement2("List", ["E"]);
      listElement.constructors = <ConstructorElement> [ElementFactory.constructorElement(listElement, null)];
      _listType = listElement.type;
      Type2 eType = listElement.typeVariables[0].type;
      InterfaceType supertype = iterableType.substitute5(<Type2> [eType]);
      listElement.supertype = supertype;
      listElement.accessors = <PropertyAccessorElement> [ElementFactory.getterElement("length", false, intType)];
      listElement.methods = <MethodElement> [ElementFactory.methodElement("[]", eType, [intType]), ElementFactory.methodElement("[]=", VoidTypeImpl.instance, [intType, eType]), ElementFactory.methodElement("add", VoidTypeImpl.instance, [eType])];
      propagateTypeArguments(listElement);
    }
    return _listType;
  }
  InterfaceType get mapType {
    if (_mapType == null) {
      ClassElementImpl mapElement = ElementFactory.classElement2("Map", ["K", "V"]);
      _mapType = mapElement.type;
      mapElement.accessors = <PropertyAccessorElement> [ElementFactory.getterElement("length", false, intType)];
      propagateTypeArguments(mapElement);
    }
    return _mapType;
  }
  InterfaceType get numType {
    if (_numType == null) {
      initializeNumericTypes();
    }
    return _numType;
  }
  InterfaceType get objectType {
    if (_objectType == null) {
      ClassElementImpl objectElement = ElementFactory.object;
      _objectType = objectElement.type;
      if (objectElement.methods.length == 0) {
        objectElement.constructors = <ConstructorElement> [ElementFactory.constructorElement(objectElement, null)];
        objectElement.methods = <MethodElement> [ElementFactory.methodElement("toString", stringType, []), ElementFactory.methodElement("==", boolType, [_objectType]), ElementFactory.methodElement("noSuchMethod", dynamicType, [dynamicType])];
        objectElement.accessors = <PropertyAccessorElement> [ElementFactory.getterElement("hashCode", false, intType), ElementFactory.getterElement("runtimeType", false, typeType)];
      }
    }
    return _objectType;
  }
  InterfaceType get stackTraceType {
    if (_stackTraceType == null) {
      _stackTraceType = ElementFactory.classElement2("StackTrace", []).type;
    }
    return _stackTraceType;
  }
  InterfaceType get stringType {
    if (_stringType == null) {
      _stringType = ElementFactory.classElement2("String", []).type;
      ClassElementImpl stringElement = _stringType.element as ClassElementImpl;
      stringElement.accessors = <PropertyAccessorElement> [ElementFactory.getterElement("isEmpty", false, boolType), ElementFactory.getterElement("length", false, intType), ElementFactory.getterElement("codeUnits", false, listType.substitute5(<Type2> [intType]))];
      stringElement.methods = <MethodElement> [ElementFactory.methodElement("toLowerCase", _stringType, []), ElementFactory.methodElement("toUpperCase", _stringType, [])];
    }
    return _stringType;
  }
  InterfaceType get typeType {
    if (_typeType == null) {
      _typeType = ElementFactory.classElement2("Type", []).type;
    }
    return _typeType;
  }

  /**
   * Initialize the numeric types. They are created as a group so that we can (a) create the right
   * hierarchy and (b) add members to them.
   */
  void initializeNumericTypes() {
    ClassElementImpl numElement = ElementFactory.classElement2("num", []);
    _numType = numElement.type;
    ClassElementImpl intElement = ElementFactory.classElement("int", _numType, []);
    _intType = intElement.type;
    ClassElementImpl doubleElement = ElementFactory.classElement("double", _numType, []);
    _doubleType = doubleElement.type;
    boolType;
    stringType;
    numElement.methods = <MethodElement> [ElementFactory.methodElement("+", _numType, [_numType]), ElementFactory.methodElement("-", _numType, [_numType]), ElementFactory.methodElement("*", _numType, [_numType]), ElementFactory.methodElement("%", _numType, [_numType]), ElementFactory.methodElement("/", _doubleType, [_numType]), ElementFactory.methodElement("~/", _numType, [_numType]), ElementFactory.methodElement("-", _numType, []), ElementFactory.methodElement("remainder", _numType, [_numType]), ElementFactory.methodElement("<", _boolType, [_numType]), ElementFactory.methodElement("<=", _boolType, [_numType]), ElementFactory.methodElement(">", _boolType, [_numType]), ElementFactory.methodElement(">=", _boolType, [_numType]), ElementFactory.methodElement("isNaN", _boolType, []), ElementFactory.methodElement("isNegative", _boolType, []), ElementFactory.methodElement("isInfinite", _boolType, []), ElementFactory.methodElement("abs", _numType, []), ElementFactory.methodElement("floor", _numType, []), ElementFactory.methodElement("ceil", _numType, []), ElementFactory.methodElement("round", _numType, []), ElementFactory.methodElement("truncate", _numType, []), ElementFactory.methodElement("toInt", _intType, []), ElementFactory.methodElement("toDouble", _doubleType, []), ElementFactory.methodElement("toStringAsFixed", _stringType, [_intType]), ElementFactory.methodElement("toStringAsExponential", _stringType, [_intType]), ElementFactory.methodElement("toStringAsPrecision", _stringType, [_intType]), ElementFactory.methodElement("toRadixString", _stringType, [_intType])];
    intElement.methods = <MethodElement> [ElementFactory.methodElement("&", _intType, [_intType]), ElementFactory.methodElement("|", _intType, [_intType]), ElementFactory.methodElement("^", _intType, [_intType]), ElementFactory.methodElement("~", _intType, []), ElementFactory.methodElement("<<", _intType, [_intType]), ElementFactory.methodElement(">>", _intType, [_intType]), ElementFactory.methodElement("-", _intType, []), ElementFactory.methodElement("abs", _intType, []), ElementFactory.methodElement("round", _intType, []), ElementFactory.methodElement("floor", _intType, []), ElementFactory.methodElement("ceil", _intType, []), ElementFactory.methodElement("truncate", _intType, []), ElementFactory.methodElement("toString", _stringType, [])];
    List<FieldElement> fields = <FieldElement> [ElementFactory.fieldElement("NAN", true, false, true, _doubleType), ElementFactory.fieldElement("INFINITY", true, false, true, _doubleType), ElementFactory.fieldElement("NEGATIVE_INFINITY", true, false, true, _doubleType), ElementFactory.fieldElement("MIN_POSITIVE", true, false, true, _doubleType), ElementFactory.fieldElement("MAX_FINITE", true, false, true, _doubleType)];
    doubleElement.fields = fields;
    int fieldCount = fields.length;
    List<PropertyAccessorElement> accessors = new List<PropertyAccessorElement>(fieldCount);
    for (int i = 0; i < fieldCount; i++) {
      accessors[i] = fields[i].getter;
    }
    doubleElement.accessors = accessors;
    doubleElement.methods = <MethodElement> [ElementFactory.methodElement("remainder", _doubleType, [_numType]), ElementFactory.methodElement("+", _doubleType, [_numType]), ElementFactory.methodElement("-", _doubleType, [_numType]), ElementFactory.methodElement("*", _doubleType, [_numType]), ElementFactory.methodElement("%", _doubleType, [_numType]), ElementFactory.methodElement("/", _doubleType, [_numType]), ElementFactory.methodElement("~/", _doubleType, [_numType]), ElementFactory.methodElement("-", _doubleType, []), ElementFactory.methodElement("abs", _doubleType, []), ElementFactory.methodElement("round", _doubleType, []), ElementFactory.methodElement("floor", _doubleType, []), ElementFactory.methodElement("ceil", _doubleType, []), ElementFactory.methodElement("truncate", _doubleType, []), ElementFactory.methodElement("toString", _stringType, [])];
  }

  /**
   * Given a class element representing a class with type parameters, propagate those type
   * parameters to all of the accessors, methods and constructors defined for the class.
   * @param classElement the element representing the class with type parameters
   */
  void propagateTypeArguments(ClassElementImpl classElement) {
    List<Type2> typeArguments = TypeVariableTypeImpl.getTypes(classElement.typeVariables);
    for (PropertyAccessorElement accessor in classElement.accessors) {
      FunctionTypeImpl functionType = accessor.type as FunctionTypeImpl;
      functionType.typeArguments = typeArguments;
    }
    for (MethodElement method in classElement.methods) {
      FunctionTypeImpl functionType = method.type as FunctionTypeImpl;
      functionType.typeArguments = typeArguments;
    }
    for (ConstructorElement constructor in classElement.constructors) {
      FunctionTypeImpl functionType = constructor.type as FunctionTypeImpl;
      functionType.typeArguments = typeArguments;
    }
  }
}
/**
 * The class `AnalysisContextFactory` defines utility methods used to create analysis contexts
 * for testing purposes.
 */
class AnalysisContextFactory {

  /**
   * Create an analysis context that has a fake core library already resolved.
   * @return the analysis context that was created
   */
  static AnalysisContextImpl contextWithCore() {
    AnalysisContextImpl sdkContext = DirectoryBasedDartSdk.defaultSdk.context as AnalysisContextImpl;
    SourceFactory sourceFactory = sdkContext.sourceFactory;
    TestTypeProvider provider = new TestTypeProvider();
    CompilationUnitElementImpl coreUnit = new CompilationUnitElementImpl("core.dart");
    Source coreSource = sourceFactory.forUri(DartSdk.DART_CORE);
    sdkContext.setContents(coreSource, "");
    coreUnit.source = coreSource;
    coreUnit.types = <ClassElement> [provider.boolType.element, provider.doubleType.element, provider.functionType.element, provider.intType.element, provider.listType.element, provider.mapType.element, provider.numType.element, provider.objectType.element, provider.stackTraceType.element, provider.stringType.element, provider.typeType.element];
    LibraryElementImpl coreLibrary = new LibraryElementImpl(sdkContext, ASTFactory.libraryIdentifier2(["dart", "core"]));
    coreLibrary.definingCompilationUnit = coreUnit;
    CompilationUnitElementImpl htmlUnit = new CompilationUnitElementImpl("html_dartium.dart");
    Source htmlSource = sourceFactory.forUri(DartSdk.DART_HTML);
    sdkContext.setContents(htmlSource, "");
    htmlUnit.source = htmlSource;
    ClassElementImpl elementElement = ElementFactory.classElement2("Element", []);
    InterfaceType elementType = elementElement.type;
    ClassElementImpl documentElement = ElementFactory.classElement("Document", elementType, []);
    ClassElementImpl htmlDocumentElement = ElementFactory.classElement("HtmlDocument", documentElement.type, []);
    htmlDocumentElement.methods = <MethodElement> [ElementFactory.methodElement("query", elementType, <Type2> [provider.stringType])];
    htmlUnit.types = <ClassElement> [ElementFactory.classElement("AnchorElement", elementType, []), ElementFactory.classElement("BodyElement", elementType, []), ElementFactory.classElement("ButtonElement", elementType, []), ElementFactory.classElement("DivElement", elementType, []), documentElement, elementElement, htmlDocumentElement, ElementFactory.classElement("InputElement", elementType, []), ElementFactory.classElement("SelectElement", elementType, [])];
    htmlUnit.functions = <FunctionElement> [ElementFactory.functionElement3("query", elementElement, <ClassElement> [provider.stringType.element], ClassElementImpl.EMPTY_ARRAY)];
    TopLevelVariableElementImpl document = ElementFactory.topLevelVariableElement3("document", true, htmlDocumentElement.type);
    htmlUnit.topLevelVariables = <TopLevelVariableElement> [document];
    htmlUnit.accessors = <PropertyAccessorElement> [document.getter];
    LibraryElementImpl htmlLibrary = new LibraryElementImpl(sdkContext, ASTFactory.libraryIdentifier2(["dart", "dom", "html"]));
    htmlLibrary.definingCompilationUnit = htmlUnit;
    Map<Source, LibraryElement> elementMap = new Map<Source, LibraryElement>();
    elementMap[coreSource] = coreLibrary;
    elementMap[htmlSource] = htmlLibrary;
    sdkContext.recordLibraryElements(elementMap);
    AnalysisContextImpl context = new DelegatingAnalysisContextImpl();
    sourceFactory = new SourceFactory.con2([new DartUriResolver(sdkContext.sourceFactory.dartSdk), new FileUriResolver()]);
    context.sourceFactory = sourceFactory;
    return context;
  }
}
class LibraryImportScopeTest extends ResolverTestCase {
  void test_conflictingImports() {
    AnalysisContext context = new AnalysisContextImpl();
    String typeNameA = "A";
    String typeNameB = "B";
    String typeNameC = "C";
    ClassElement typeA = ElementFactory.classElement2(typeNameA, []);
    ClassElement typeB1 = ElementFactory.classElement2(typeNameB, []);
    ClassElement typeB2 = ElementFactory.classElement2(typeNameB, []);
    ClassElement typeC = ElementFactory.classElement2(typeNameC, []);
    LibraryElement importedLibrary1 = createTestLibrary2(context, "imported1", []);
    ((importedLibrary1.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [typeA, typeB1];
    ImportElementImpl import1 = ElementFactory.importFor(importedLibrary1, null, []);
    LibraryElement importedLibrary2 = createTestLibrary2(context, "imported2", []);
    ((importedLibrary2.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [typeB2, typeC];
    ImportElementImpl import2 = ElementFactory.importFor(importedLibrary2, null, []);
    LibraryElementImpl importingLibrary = createTestLibrary2(context, "importing", []);
    importingLibrary.imports = <ImportElement> [import1, import2];
    {
      GatheringErrorListener errorListener = new GatheringErrorListener();
      Scope scope = new LibraryImportScope(importingLibrary, errorListener);
      JUnitTestCase.assertEquals(typeA, scope.lookup(ASTFactory.identifier3(typeNameA), importingLibrary));
      errorListener.assertNoErrors();
      JUnitTestCase.assertEquals(typeC, scope.lookup(ASTFactory.identifier3(typeNameC), importingLibrary));
      errorListener.assertNoErrors();
      Element element = scope.lookup(ASTFactory.identifier3(typeNameB), importingLibrary);
      errorListener.assertErrors2([CompileTimeErrorCode.AMBIGUOUS_IMPORT]);
      EngineTestCase.assertInstanceOf(MultiplyDefinedElement, element);
      List<Element> conflictingElements = ((element as MultiplyDefinedElement)).conflictingElements;
      JUnitTestCase.assertEquals(typeB1, conflictingElements[0]);
      JUnitTestCase.assertEquals(typeB2, conflictingElements[1]);
      JUnitTestCase.assertEquals(2, conflictingElements.length);
    }
    {
      GatheringErrorListener errorListener = new GatheringErrorListener();
      Scope scope = new LibraryImportScope(importingLibrary, errorListener);
      Identifier identifier = ASTFactory.identifier3(typeNameB);
      ASTFactory.methodDeclaration(null, ASTFactory.typeName3(identifier, []), null, null, ASTFactory.identifier3("foo"), null);
      Element element = scope.lookup(identifier, importingLibrary);
      errorListener.assertErrors2([StaticWarningCode.AMBIGUOUS_IMPORT]);
      EngineTestCase.assertInstanceOf(MultiplyDefinedElement, element);
    }
  }
  void test_creation_empty() {
    LibraryElement definingLibrary = createTestLibrary();
    GatheringErrorListener errorListener = new GatheringErrorListener();
    new LibraryImportScope(definingLibrary, errorListener);
  }
  void test_creation_nonEmpty() {
    AnalysisContext context = new AnalysisContextImpl();
    String importedTypeName = "A";
    ClassElement importedType = new ClassElementImpl(ASTFactory.identifier3(importedTypeName));
    LibraryElement importedLibrary = createTestLibrary2(context, "imported", []);
    ((importedLibrary.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [importedType];
    LibraryElementImpl definingLibrary = createTestLibrary2(context, "importing", []);
    ImportElementImpl importElement = new ImportElementImpl();
    importElement.importedLibrary = importedLibrary;
    definingLibrary.imports = <ImportElement> [importElement];
    GatheringErrorListener errorListener = new GatheringErrorListener();
    Scope scope = new LibraryImportScope(definingLibrary, errorListener);
    JUnitTestCase.assertEquals(importedType, scope.lookup(ASTFactory.identifier3(importedTypeName), definingLibrary));
  }
  void test_getDefiningLibrary() {
    LibraryElement definingLibrary = createTestLibrary();
    GatheringErrorListener errorListener = new GatheringErrorListener();
    Scope scope = new LibraryImportScope(definingLibrary, errorListener);
    JUnitTestCase.assertEquals(definingLibrary, scope.definingLibrary);
  }
  void test_getErrorListener() {
    LibraryElement definingLibrary = createTestLibrary();
    GatheringErrorListener errorListener = new GatheringErrorListener();
    Scope scope = new LibraryImportScope(definingLibrary, errorListener);
    JUnitTestCase.assertEquals(errorListener, scope.errorListener);
  }
  void test_prefixedAndNonPrefixed() {
    AnalysisContext context = new AnalysisContextImpl();
    String typeName = "C";
    String prefixName = "p";
    ClassElement prefixedType = ElementFactory.classElement2(typeName, []);
    ClassElement nonPrefixedType = ElementFactory.classElement2(typeName, []);
    LibraryElement prefixedLibrary = createTestLibrary2(context, "import.prefixed", []);
    ((prefixedLibrary.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [prefixedType];
    ImportElementImpl prefixedImport = ElementFactory.importFor(prefixedLibrary, ElementFactory.prefix(prefixName), []);
    LibraryElement nonPrefixedLibrary = createTestLibrary2(context, "import.nonPrefixed", []);
    ((nonPrefixedLibrary.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [nonPrefixedType];
    ImportElementImpl nonPrefixedImport = ElementFactory.importFor(nonPrefixedLibrary, null, []);
    LibraryElementImpl importingLibrary = createTestLibrary2(context, "importing", []);
    importingLibrary.imports = <ImportElement> [prefixedImport, nonPrefixedImport];
    GatheringErrorListener errorListener = new GatheringErrorListener();
    Scope scope = new LibraryImportScope(importingLibrary, errorListener);
    Element prefixedElement = scope.lookup(ASTFactory.identifier5(prefixName, typeName), importingLibrary);
    errorListener.assertNoErrors();
    JUnitTestCase.assertSame(prefixedType, prefixedElement);
    Element nonPrefixedElement = scope.lookup(ASTFactory.identifier3(typeName), importingLibrary);
    errorListener.assertNoErrors();
    JUnitTestCase.assertSame(nonPrefixedType, nonPrefixedElement);
  }
  static dartSuite() {
    _ut.group('LibraryImportScopeTest', () {
      _ut.test('test_conflictingImports', () {
        final __test = new LibraryImportScopeTest();
        runJUnitTest(__test, __test.test_conflictingImports);
      });
      _ut.test('test_creation_empty', () {
        final __test = new LibraryImportScopeTest();
        runJUnitTest(__test, __test.test_creation_empty);
      });
      _ut.test('test_creation_nonEmpty', () {
        final __test = new LibraryImportScopeTest();
        runJUnitTest(__test, __test.test_creation_nonEmpty);
      });
      _ut.test('test_getDefiningLibrary', () {
        final __test = new LibraryImportScopeTest();
        runJUnitTest(__test, __test.test_getDefiningLibrary);
      });
      _ut.test('test_getErrorListener', () {
        final __test = new LibraryImportScopeTest();
        runJUnitTest(__test, __test.test_getErrorListener);
      });
      _ut.test('test_prefixedAndNonPrefixed', () {
        final __test = new LibraryImportScopeTest();
        runJUnitTest(__test, __test.test_prefixedAndNonPrefixed);
      });
    });
  }
}
/**
 * Instances of the class `ResolutionVerifier` verify that all of the nodes in an AST
 * structure that should have been resolved were resolved.
 */
class ResolutionVerifier extends RecursiveASTVisitor<Object> {

  /**
   * A set containing nodes that are known to not be resolvable and should therefore not cause the
   * test to fail.
   */
  Set<ASTNode> _knownExceptions;

  /**
   * A list containing all of the AST nodes that were not resolved.
   */
  List<ASTNode> _unresolvedNodes = new List<ASTNode>();

  /**
   * A list containing all of the AST nodes that were resolved to an element of the wrong type.
   */
  List<ASTNode> _wrongTypedNodes = new List<ASTNode>();

  /**
   * Initialize a newly created verifier to verify that all of the nodes in the visited AST
   * structures that are expected to have been resolved have an element associated with them.
   */
  ResolutionVerifier() {
    _jtd_constructor_361_impl();
  }
  _jtd_constructor_361_impl() {
    _jtd_constructor_362_impl(null);
  }

  /**
   * Initialize a newly created verifier to verify that all of the identifiers in the visited AST
   * structures that are expected to have been resolved have an element associated with them. Nodes
   * in the set of known exceptions are not expected to have been resolved, even if they normally
   * would have been expected to have been resolved.
   * @param knownExceptions a set containing nodes that are known to not be resolvable and should
   * therefore not cause the test to fail
   */
  ResolutionVerifier.con1(Set<ASTNode> knownExceptions2) {
    _jtd_constructor_362_impl(knownExceptions2);
  }
  _jtd_constructor_362_impl(Set<ASTNode> knownExceptions2) {
    this._knownExceptions = knownExceptions2;
  }

  /**
   * Assert that all of the visited identifiers were resolved.
   */
  void assertResolved() {
    if (!_unresolvedNodes.isEmpty || !_wrongTypedNodes.isEmpty) {
      PrintStringWriter writer = new PrintStringWriter();
      if (!_unresolvedNodes.isEmpty) {
        writer.print("Failed to resolve ");
        writer.print(_unresolvedNodes.length);
        writer.println(" nodes:");
        printNodes(writer, _unresolvedNodes);
      }
      if (!_wrongTypedNodes.isEmpty) {
        writer.print("Resolved ");
        writer.print(_wrongTypedNodes.length);
        writer.println(" to the wrong type of element:");
        printNodes(writer, _wrongTypedNodes);
      }
      JUnitTestCase.fail(writer.toString());
    }
  }
  Object visitBinaryExpression(BinaryExpression node) {
    node.visitChildren(this);
    if (!node.operator.isUserDefinableOperator) {
      return null;
    }
    return checkResolved2(node, node.element, MethodElement);
  }
  Object visitCompilationUnit(CompilationUnit node) {
    node.visitChildren(this);
    return checkResolved2(node, node.element, CompilationUnitElement);
  }
  Object visitExportDirective(ExportDirective node) => checkResolved2(node, node.element, ExportElement);
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    node.visitChildren(this);
    if (node.element is LibraryElement) {
      _wrongTypedNodes.add(node);
    }
    return null;
  }
  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.visitChildren(this);
    return checkResolved2(node, node.element, FunctionElement);
  }
  Object visitImportDirective(ImportDirective node) {
    checkResolved2(node, node.element, ImportElement);
    SimpleIdentifier prefix = node.prefix;
    if (prefix == null) {
      return null;
    }
    return checkResolved2(prefix, prefix.element, PrefixElement);
  }
  Object visitIndexExpression(IndexExpression node) {
    node.visitChildren(this);
    return checkResolved2(node, node.element, MethodElement);
  }
  Object visitLibraryDirective(LibraryDirective node) => checkResolved2(node, node.element, LibraryElement);
  Object visitPartDirective(PartDirective node) => checkResolved2(node, node.element, CompilationUnitElement);
  Object visitPartOfDirective(PartOfDirective node) => checkResolved2(node, node.element, LibraryElement);
  Object visitPostfixExpression(PostfixExpression node) {
    node.visitChildren(this);
    if (!node.operator.isUserDefinableOperator) {
      return null;
    }
    return checkResolved2(node, node.element, MethodElement);
  }
  Object visitPrefixExpression(PrefixExpression node) {
    node.visitChildren(this);
    if (!node.operator.isUserDefinableOperator) {
      return null;
    }
    return checkResolved2(node, node.element, MethodElement);
  }
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == "void") {
      return null;
    }
    return checkResolved(node, node.element);
  }
  Object checkResolved(ASTNode node, Element element) => checkResolved2(node, element, null);
  Object checkResolved2(ASTNode node, Element element, Type expectedClass) {
    if (element == null) {
      if (node.parent is CommentReference) {
        return null;
      }
      if (_knownExceptions == null || !_knownExceptions.contains(node)) {
        _unresolvedNodes.add(node);
      }
    } else if (expectedClass != null) {
      if (!isInstanceOf(element, expectedClass)) {
        _wrongTypedNodes.add(node);
      }
    }
    return null;
  }
  String getFileName(ASTNode node) {
    if (node != null) {
      ASTNode root = node.root;
      if (root is CompilationUnit) {
        CompilationUnit rootCU = (root as CompilationUnit);
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
  void printNodes(PrintStringWriter writer, List<ASTNode> nodes) {
    for (ASTNode identifier in nodes) {
      writer.print("  ");
      writer.print(identifier.toString());
      writer.print(" (");
      writer.print(getFileName(identifier));
      writer.print(" : ");
      writer.print(identifier.offset);
      writer.println(")");
    }
  }
}
class LibraryScopeTest extends ResolverTestCase {
  void test_creation_empty() {
    LibraryElement definingLibrary = createTestLibrary();
    GatheringErrorListener errorListener = new GatheringErrorListener();
    new LibraryScope(definingLibrary, errorListener);
  }
  void test_creation_nonEmpty() {
    AnalysisContext context = new AnalysisContextImpl();
    String importedTypeName = "A";
    ClassElement importedType = new ClassElementImpl(ASTFactory.identifier3(importedTypeName));
    LibraryElement importedLibrary = createTestLibrary2(context, "imported", []);
    ((importedLibrary.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [importedType];
    LibraryElementImpl definingLibrary = createTestLibrary2(context, "importing", []);
    ImportElementImpl importElement = new ImportElementImpl();
    importElement.importedLibrary = importedLibrary;
    definingLibrary.imports = <ImportElement> [importElement];
    GatheringErrorListener errorListener = new GatheringErrorListener();
    Scope scope = new LibraryScope(definingLibrary, errorListener);
    JUnitTestCase.assertEquals(importedType, scope.lookup(ASTFactory.identifier3(importedTypeName), definingLibrary));
  }
  void test_getDefiningLibrary() {
    LibraryElement definingLibrary = createTestLibrary();
    GatheringErrorListener errorListener = new GatheringErrorListener();
    Scope scope = new LibraryScope(definingLibrary, errorListener);
    JUnitTestCase.assertEquals(definingLibrary, scope.definingLibrary);
  }
  void test_getErrorListener() {
    LibraryElement definingLibrary = createTestLibrary();
    GatheringErrorListener errorListener = new GatheringErrorListener();
    Scope scope = new LibraryScope(definingLibrary, errorListener);
    JUnitTestCase.assertEquals(errorListener, scope.errorListener);
  }
  static dartSuite() {
    _ut.group('LibraryScopeTest', () {
      _ut.test('test_creation_empty', () {
        final __test = new LibraryScopeTest();
        runJUnitTest(__test, __test.test_creation_empty);
      });
      _ut.test('test_creation_nonEmpty', () {
        final __test = new LibraryScopeTest();
        runJUnitTest(__test, __test.test_creation_nonEmpty);
      });
      _ut.test('test_getDefiningLibrary', () {
        final __test = new LibraryScopeTest();
        runJUnitTest(__test, __test.test_getDefiningLibrary);
      });
      _ut.test('test_getErrorListener', () {
        final __test = new LibraryScopeTest();
        runJUnitTest(__test, __test.test_getErrorListener);
      });
    });
  }
}
class StaticTypeAnalyzerTest extends EngineTestCase {

  /**
   * The error listener to which errors will be reported.
   */
  GatheringErrorListener _listener;

  /**
   * The resolver visitor used to create the analyzer.
   */
  ResolverVisitor _visitor;

  /**
   * The analyzer being used to analyze the test cases.
   */
  StaticTypeAnalyzer _analyzer;

  /**
   * The type provider used to access the types.
   */
  TestTypeProvider _typeProvider;
  void fail_visitFunctionExpressionInvocation() {
    JUnitTestCase.fail("Not yet tested");
    _listener.assertNoErrors();
  }
  void fail_visitMethodInvocation() {
    JUnitTestCase.fail("Not yet tested");
    _listener.assertNoErrors();
  }
  void fail_visitSimpleIdentifier() {
    JUnitTestCase.fail("Not yet tested");
    _listener.assertNoErrors();
  }
  void setUp() {
    _listener = new GatheringErrorListener();
    _typeProvider = new TestTypeProvider();
    _analyzer = createAnalyzer();
  }
  void test_visitAdjacentStrings() {
    Expression node = ASTFactory.adjacentStrings([resolvedString("a"), resolvedString("b")]);
    JUnitTestCase.assertSame(_typeProvider.stringType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitArgumentDefinitionTest() {
    Expression node = ASTFactory.argumentDefinitionTest("p");
    JUnitTestCase.assertSame(_typeProvider.boolType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitAsExpression() {
    ClassElement superclass = ElementFactory.classElement2("A", []);
    InterfaceType superclassType = superclass.type;
    ClassElement subclass = ElementFactory.classElement("B", superclassType, []);
    Expression node = ASTFactory.asExpression(ASTFactory.thisExpression(), ASTFactory.typeName(subclass, []));
    JUnitTestCase.assertSame(subclass.type, analyze2(node, superclassType));
    _listener.assertNoErrors();
  }
  void test_visitAssignmentExpression_compound() {
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier identifier = resolvedVariable(_typeProvider.intType, "i");
    AssignmentExpression node = ASTFactory.assignmentExpression(identifier, TokenType.PLUS_EQ, resolvedInteger(1));
    MethodElement plusMethod = getMethod(numType, "+");
    node.staticElement = plusMethod;
    node.element = plusMethod;
    JUnitTestCase.assertSame(numType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitAssignmentExpression_simple() {
    InterfaceType intType = _typeProvider.intType;
    Expression node = ASTFactory.assignmentExpression(resolvedVariable(intType, "i"), TokenType.EQ, resolvedInteger(0));
    JUnitTestCase.assertSame(intType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitBinaryExpression_equals() {
    Expression node = ASTFactory.binaryExpression(resolvedInteger(2), TokenType.EQ_EQ, resolvedInteger(3));
    JUnitTestCase.assertSame(_typeProvider.boolType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitBinaryExpression_logicalAnd() {
    Expression node = ASTFactory.binaryExpression(ASTFactory.booleanLiteral(false), TokenType.AMPERSAND_AMPERSAND, ASTFactory.booleanLiteral(true));
    JUnitTestCase.assertSame(_typeProvider.boolType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitBinaryExpression_logicalOr() {
    Expression node = ASTFactory.binaryExpression(ASTFactory.booleanLiteral(false), TokenType.BAR_BAR, ASTFactory.booleanLiteral(true));
    JUnitTestCase.assertSame(_typeProvider.boolType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitBinaryExpression_notEquals() {
    Expression node = ASTFactory.binaryExpression(resolvedInteger(2), TokenType.BANG_EQ, resolvedInteger(3));
    JUnitTestCase.assertSame(_typeProvider.boolType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitBinaryExpression_plusID() {
    BinaryExpression node = ASTFactory.binaryExpression(resolvedInteger(1), TokenType.PLUS, resolvedDouble(2.0));
    setStaticElement(node, getMethod(_typeProvider.numType, "+"));
    JUnitTestCase.assertSame(_typeProvider.doubleType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitBinaryExpression_plusII() {
    BinaryExpression node = ASTFactory.binaryExpression(resolvedInteger(1), TokenType.PLUS, resolvedInteger(2));
    setStaticElement(node, getMethod(_typeProvider.numType, "+"));
    JUnitTestCase.assertSame(_typeProvider.intType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitBinaryExpression_slash() {
    BinaryExpression node = ASTFactory.binaryExpression(resolvedInteger(2), TokenType.SLASH, resolvedInteger(2));
    setStaticElement(node, getMethod(_typeProvider.numType, "/"));
    JUnitTestCase.assertSame(_typeProvider.doubleType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitBinaryExpression_star_notSpecial() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    InterfaceType typeA = classA.type;
    MethodElement operator = ElementFactory.methodElement("*", typeA, [_typeProvider.doubleType]);
    classA.methods = <MethodElement> [operator];
    BinaryExpression node = ASTFactory.binaryExpression(ASTFactory.asExpression(ASTFactory.identifier3("a"), ASTFactory.typeName(classA, [])), TokenType.PLUS, resolvedDouble(2.0));
    setStaticElement(node, operator);
    JUnitTestCase.assertSame(typeA, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitBinaryExpression_starID() {
    BinaryExpression node = ASTFactory.binaryExpression(resolvedInteger(1), TokenType.PLUS, resolvedDouble(2.0));
    setStaticElement(node, getMethod(_typeProvider.numType, "*"));
    JUnitTestCase.assertSame(_typeProvider.doubleType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitBooleanLiteral_false() {
    Expression node = ASTFactory.booleanLiteral(false);
    JUnitTestCase.assertSame(_typeProvider.boolType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitBooleanLiteral_true() {
    Expression node = ASTFactory.booleanLiteral(true);
    JUnitTestCase.assertSame(_typeProvider.boolType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitCascadeExpression() {
    Expression node = ASTFactory.cascadeExpression(resolvedString("a"), [ASTFactory.propertyAccess2(null, "length")]);
    JUnitTestCase.assertSame(_typeProvider.stringType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitConditionalExpression_differentTypes() {
    Expression node = ASTFactory.conditionalExpression(ASTFactory.booleanLiteral(true), resolvedDouble(1.0), resolvedInteger(0));
    JUnitTestCase.assertSame(_typeProvider.numType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitConditionalExpression_sameTypes() {
    Expression node = ASTFactory.conditionalExpression(ASTFactory.booleanLiteral(true), resolvedInteger(1), resolvedInteger(0));
    JUnitTestCase.assertSame(_typeProvider.intType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitDoubleLiteral() {
    Expression node = ASTFactory.doubleLiteral(4.33);
    JUnitTestCase.assertSame(_typeProvider.doubleType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitFunctionExpression_named_block() {
    Type2 dynamicType = _typeProvider.dynamicType;
    FormalParameter p1 = ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("p1"), resolvedInteger(0));
    setType(p1, dynamicType);
    FormalParameter p2 = ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("p2"), resolvedInteger(0));
    setType(p2, dynamicType);
    FunctionExpression node = resolvedFunctionExpression(ASTFactory.formalParameterList([p1, p2]), ASTFactory.blockFunctionBody([]));
    analyze3(p1);
    analyze3(p2);
    Type2 resultType = analyze(node);
    Map<String, Type2> expectedNamedTypes = new Map<String, Type2>();
    expectedNamedTypes["p1"] = dynamicType;
    expectedNamedTypes["p2"] = dynamicType;
    assertFunctionType(dynamicType, null, null, expectedNamedTypes, resultType);
    _listener.assertNoErrors();
  }
  void test_visitFunctionExpression_named_expression() {
    Type2 dynamicType = _typeProvider.dynamicType;
    FormalParameter p = ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("p"), resolvedInteger(0));
    setType(p, dynamicType);
    FunctionExpression node = resolvedFunctionExpression(ASTFactory.formalParameterList([p]), ASTFactory.expressionFunctionBody(resolvedInteger(0)));
    analyze3(p);
    Type2 resultType = analyze(node);
    Map<String, Type2> expectedNamedTypes = new Map<String, Type2>();
    expectedNamedTypes["p"] = dynamicType;
    assertFunctionType(_typeProvider.intType, null, null, expectedNamedTypes, resultType);
    _listener.assertNoErrors();
  }
  void test_visitFunctionExpression_normal_block() {
    Type2 dynamicType = _typeProvider.dynamicType;
    FormalParameter p1 = ASTFactory.simpleFormalParameter3("p1");
    setType(p1, dynamicType);
    FormalParameter p2 = ASTFactory.simpleFormalParameter3("p2");
    setType(p2, dynamicType);
    FunctionExpression node = resolvedFunctionExpression(ASTFactory.formalParameterList([p1, p2]), ASTFactory.blockFunctionBody([]));
    analyze3(p1);
    analyze3(p2);
    Type2 resultType = analyze(node);
    assertFunctionType(dynamicType, <Type2> [dynamicType, dynamicType], null, null, resultType);
    _listener.assertNoErrors();
  }
  void test_visitFunctionExpression_normal_expression() {
    Type2 dynamicType = _typeProvider.dynamicType;
    FormalParameter p = ASTFactory.simpleFormalParameter3("p");
    setType(p, dynamicType);
    FunctionExpression node = resolvedFunctionExpression(ASTFactory.formalParameterList([p]), ASTFactory.expressionFunctionBody(resolvedInteger(0)));
    analyze3(p);
    Type2 resultType = analyze(node);
    assertFunctionType(_typeProvider.intType, <Type2> [dynamicType], null, null, resultType);
    _listener.assertNoErrors();
  }
  void test_visitFunctionExpression_normalAndNamed_block() {
    Type2 dynamicType = _typeProvider.dynamicType;
    FormalParameter p1 = ASTFactory.simpleFormalParameter3("p1");
    setType(p1, dynamicType);
    FormalParameter p2 = ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("p2"), resolvedInteger(0));
    setType(p2, dynamicType);
    FunctionExpression node = resolvedFunctionExpression(ASTFactory.formalParameterList([p1, p2]), ASTFactory.blockFunctionBody([]));
    analyze3(p2);
    Type2 resultType = analyze(node);
    Map<String, Type2> expectedNamedTypes = new Map<String, Type2>();
    expectedNamedTypes["p2"] = dynamicType;
    assertFunctionType(dynamicType, <Type2> [dynamicType], null, expectedNamedTypes, resultType);
    _listener.assertNoErrors();
  }
  void test_visitFunctionExpression_normalAndNamed_expression() {
    Type2 dynamicType = _typeProvider.dynamicType;
    FormalParameter p1 = ASTFactory.simpleFormalParameter3("p1");
    setType(p1, dynamicType);
    FormalParameter p2 = ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("p2"), resolvedInteger(0));
    setType(p2, dynamicType);
    FunctionExpression node = resolvedFunctionExpression(ASTFactory.formalParameterList([p1, p2]), ASTFactory.expressionFunctionBody(resolvedInteger(0)));
    analyze3(p2);
    Type2 resultType = analyze(node);
    Map<String, Type2> expectedNamedTypes = new Map<String, Type2>();
    expectedNamedTypes["p2"] = dynamicType;
    assertFunctionType(_typeProvider.intType, <Type2> [dynamicType], null, expectedNamedTypes, resultType);
    _listener.assertNoErrors();
  }
  void test_visitFunctionExpression_normalAndPositional_block() {
    Type2 dynamicType = _typeProvider.dynamicType;
    FormalParameter p1 = ASTFactory.simpleFormalParameter3("p1");
    setType(p1, dynamicType);
    FormalParameter p2 = ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("p2"), resolvedInteger(0));
    setType(p2, dynamicType);
    FunctionExpression node = resolvedFunctionExpression(ASTFactory.formalParameterList([p1, p2]), ASTFactory.blockFunctionBody([]));
    analyze3(p1);
    analyze3(p2);
    Type2 resultType = analyze(node);
    assertFunctionType(dynamicType, <Type2> [dynamicType], <Type2> [dynamicType], null, resultType);
    _listener.assertNoErrors();
  }
  void test_visitFunctionExpression_normalAndPositional_expression() {
    Type2 dynamicType = _typeProvider.dynamicType;
    FormalParameter p1 = ASTFactory.simpleFormalParameter3("p1");
    setType(p1, dynamicType);
    FormalParameter p2 = ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("p2"), resolvedInteger(0));
    setType(p2, dynamicType);
    FunctionExpression node = resolvedFunctionExpression(ASTFactory.formalParameterList([p1, p2]), ASTFactory.expressionFunctionBody(resolvedInteger(0)));
    analyze3(p1);
    analyze3(p2);
    Type2 resultType = analyze(node);
    assertFunctionType(_typeProvider.intType, <Type2> [dynamicType], <Type2> [dynamicType], null, resultType);
    _listener.assertNoErrors();
  }
  void test_visitFunctionExpression_positional_block() {
    Type2 dynamicType = _typeProvider.dynamicType;
    FormalParameter p1 = ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("p1"), resolvedInteger(0));
    setType(p1, dynamicType);
    FormalParameter p2 = ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("p2"), resolvedInteger(0));
    setType(p2, dynamicType);
    FunctionExpression node = resolvedFunctionExpression(ASTFactory.formalParameterList([p1, p2]), ASTFactory.blockFunctionBody([]));
    analyze3(p1);
    analyze3(p2);
    Type2 resultType = analyze(node);
    assertFunctionType(dynamicType, null, <Type2> [dynamicType, dynamicType], null, resultType);
    _listener.assertNoErrors();
  }
  void test_visitFunctionExpression_positional_expression() {
    Type2 dynamicType = _typeProvider.dynamicType;
    FormalParameter p = ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("p"), resolvedInteger(0));
    setType(p, dynamicType);
    FunctionExpression node = resolvedFunctionExpression(ASTFactory.formalParameterList([p]), ASTFactory.expressionFunctionBody(resolvedInteger(0)));
    analyze3(p);
    Type2 resultType = analyze(node);
    assertFunctionType(_typeProvider.intType, null, <Type2> [dynamicType], null, resultType);
    _listener.assertNoErrors();
  }
  void test_visitIndexExpression_getter() {
    InterfaceType listType = _typeProvider.listType;
    SimpleIdentifier identifier = resolvedVariable(listType, "a");
    IndexExpression node = ASTFactory.indexExpression(identifier, resolvedInteger(2));
    MethodElement indexMethod = listType.element.methods[0];
    node.staticElement = indexMethod;
    node.element = indexMethod;
    JUnitTestCase.assertSame(listType.typeArguments[0], analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitIndexExpression_setter() {
    InterfaceType listType = _typeProvider.listType;
    SimpleIdentifier identifier = resolvedVariable(listType, "a");
    IndexExpression node = ASTFactory.indexExpression(identifier, resolvedInteger(2));
    MethodElement indexMethod = listType.element.methods[1];
    node.staticElement = indexMethod;
    node.element = indexMethod;
    ASTFactory.assignmentExpression(node, TokenType.EQ, ASTFactory.integer(0));
    JUnitTestCase.assertSame(listType.typeArguments[0], analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitIndexExpression_typeParameters() {
    InterfaceType intType = _typeProvider.intType;
    InterfaceType listType = _typeProvider.listType;
    MethodElement methodElement = getMethod(listType, "[]");
    SimpleIdentifier identifier = ASTFactory.identifier3("list");
    InterfaceType listOfIntType = listType.substitute5(<Type2> [intType]);
    identifier.staticType = listOfIntType;
    IndexExpression indexExpression = ASTFactory.indexExpression(identifier, ASTFactory.integer(0));
    MethodElement indexMethod = MethodMember.from(methodElement, listOfIntType);
    indexExpression.staticElement = indexMethod;
    indexExpression.element = indexMethod;
    JUnitTestCase.assertSame(intType, analyze(indexExpression));
    _listener.assertNoErrors();
  }
  void test_visitIndexExpression_typeParameters_inSetterContext() {
    InterfaceType intType = _typeProvider.intType;
    InterfaceType listType = _typeProvider.listType;
    MethodElement methodElement = getMethod(listType, "[]=");
    SimpleIdentifier identifier = ASTFactory.identifier3("list");
    InterfaceType listOfIntType = listType.substitute5(<Type2> [intType]);
    identifier.staticType = listOfIntType;
    IndexExpression indexExpression = ASTFactory.indexExpression(identifier, ASTFactory.integer(0));
    MethodElement indexMethod = MethodMember.from(methodElement, listOfIntType);
    indexExpression.staticElement = indexMethod;
    indexExpression.element = indexMethod;
    ASTFactory.assignmentExpression(indexExpression, TokenType.EQ, ASTFactory.integer(0));
    JUnitTestCase.assertSame(intType, analyze(indexExpression));
    _listener.assertNoErrors();
  }
  void test_visitInstanceCreationExpression_named() {
    ClassElementImpl classElement = ElementFactory.classElement2("C", []);
    String constructorName = "m";
    ConstructorElementImpl constructor = ElementFactory.constructorElement(classElement, constructorName);
    constructor.returnType = classElement.type;
    FunctionTypeImpl constructorType = new FunctionTypeImpl.con1(constructor);
    constructor.type = constructorType;
    classElement.constructors = <ConstructorElement> [constructor];
    InstanceCreationExpression node = ASTFactory.instanceCreationExpression2(null, ASTFactory.typeName(classElement, []), [ASTFactory.identifier3(constructorName)]);
    node.element = constructor;
    JUnitTestCase.assertSame(classElement.type, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitInstanceCreationExpression_typeParameters() {
    ClassElementImpl elementC = ElementFactory.classElement2("C", ["E"]);
    ClassElementImpl elementI = ElementFactory.classElement2("I", []);
    ConstructorElementImpl constructor = ElementFactory.constructorElement(elementC, null);
    elementC.constructors = <ConstructorElement> [constructor];
    constructor.returnType = elementC.type;
    FunctionTypeImpl constructorType = new FunctionTypeImpl.con1(constructor);
    constructor.type = constructorType;
    TypeName typeName = ASTFactory.typeName(elementC, [ASTFactory.typeName(elementI, [])]);
    typeName.type = elementC.type.substitute5(<Type2> [elementI.type]);
    InstanceCreationExpression node = ASTFactory.instanceCreationExpression2(null, typeName, []);
    node.element = constructor;
    InterfaceType interfaceType = analyze(node) as InterfaceType;
    List<Type2> typeArgs = interfaceType.typeArguments;
    JUnitTestCase.assertEquals(1, typeArgs.length);
    JUnitTestCase.assertEquals(elementI.type, typeArgs[0]);
    _listener.assertNoErrors();
  }
  void test_visitInstanceCreationExpression_unnamed() {
    ClassElementImpl classElement = ElementFactory.classElement2("C", []);
    ConstructorElementImpl constructor = ElementFactory.constructorElement(classElement, null);
    constructor.returnType = classElement.type;
    FunctionTypeImpl constructorType = new FunctionTypeImpl.con1(constructor);
    constructor.type = constructorType;
    classElement.constructors = <ConstructorElement> [constructor];
    InstanceCreationExpression node = ASTFactory.instanceCreationExpression2(null, ASTFactory.typeName(classElement, []), []);
    node.element = constructor;
    JUnitTestCase.assertSame(classElement.type, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitIntegerLiteral() {
    Expression node = resolvedInteger(42);
    JUnitTestCase.assertSame(_typeProvider.intType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitIsExpression_negated() {
    Expression node = ASTFactory.isExpression(resolvedString("a"), true, ASTFactory.typeName4("String", []));
    JUnitTestCase.assertSame(_typeProvider.boolType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitIsExpression_notNegated() {
    Expression node = ASTFactory.isExpression(resolvedString("a"), false, ASTFactory.typeName4("String", []));
    JUnitTestCase.assertSame(_typeProvider.boolType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitListLiteral_empty() {
    Expression node = ASTFactory.listLiteral([]);
    Type2 resultType = analyze(node);
    assertType2(_typeProvider.listType.substitute5(<Type2> [_typeProvider.dynamicType]), resultType);
    _listener.assertNoErrors();
  }
  void test_visitListLiteral_nonEmpty() {
    Expression node = ASTFactory.listLiteral([resolvedInteger(0)]);
    Type2 resultType = analyze(node);
    assertType2(_typeProvider.listType.substitute5(<Type2> [_typeProvider.dynamicType]), resultType);
    _listener.assertNoErrors();
  }
  void test_visitMapLiteral_empty() {
    Expression node = ASTFactory.mapLiteral2([]);
    Type2 resultType = analyze(node);
    assertType2(_typeProvider.mapType.substitute5(<Type2> [_typeProvider.dynamicType, _typeProvider.dynamicType]), resultType);
    _listener.assertNoErrors();
  }
  void test_visitMapLiteral_nonEmpty() {
    Expression node = ASTFactory.mapLiteral2([ASTFactory.mapLiteralEntry("k", resolvedInteger(0))]);
    Type2 resultType = analyze(node);
    assertType2(_typeProvider.mapType.substitute5(<Type2> [_typeProvider.dynamicType, _typeProvider.dynamicType]), resultType);
    _listener.assertNoErrors();
  }
  void test_visitNamedExpression() {
    Expression node = ASTFactory.namedExpression2("n", resolvedString("a"));
    JUnitTestCase.assertSame(_typeProvider.stringType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitNullLiteral() {
    Expression node = ASTFactory.nullLiteral();
    JUnitTestCase.assertSame(_typeProvider.bottomType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitParenthesizedExpression() {
    Expression node = ASTFactory.parenthesizedExpression(resolvedInteger(0));
    JUnitTestCase.assertSame(_typeProvider.intType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitPostfixExpression_minusMinus() {
    PostfixExpression node = ASTFactory.postfixExpression(resolvedInteger(0), TokenType.MINUS_MINUS);
    JUnitTestCase.assertSame(_typeProvider.intType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitPostfixExpression_plusPlus() {
    PostfixExpression node = ASTFactory.postfixExpression(resolvedInteger(0), TokenType.PLUS_PLUS);
    JUnitTestCase.assertSame(_typeProvider.intType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitPrefixedIdentifier_getter() {
    Type2 boolType = _typeProvider.boolType;
    PropertyAccessorElementImpl getter = ElementFactory.getterElement("b", false, boolType);
    PrefixedIdentifier node = ASTFactory.identifier5("a", "b");
    node.identifier.element = getter;
    JUnitTestCase.assertSame(boolType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitPrefixedIdentifier_setter() {
    Type2 boolType = _typeProvider.boolType;
    FieldElementImpl field = ElementFactory.fieldElement("b", false, false, false, boolType);
    PropertyAccessorElement setter = field.setter;
    PrefixedIdentifier node = ASTFactory.identifier5("a", "b");
    node.identifier.element = setter;
    JUnitTestCase.assertSame(boolType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitPrefixedIdentifier_variable() {
    VariableElementImpl variable = ElementFactory.localVariableElement2("b");
    variable.type = _typeProvider.boolType;
    PrefixedIdentifier node = ASTFactory.identifier5("a", "b");
    node.identifier.element = variable;
    JUnitTestCase.assertSame(_typeProvider.boolType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitPrefixExpression_bang() {
    PrefixExpression node = ASTFactory.prefixExpression(TokenType.BANG, resolvedInteger(0));
    JUnitTestCase.assertSame(_typeProvider.boolType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitPrefixExpression_minus() {
    PrefixExpression node = ASTFactory.prefixExpression(TokenType.MINUS, resolvedInteger(0));
    MethodElement minusMethod = getMethod(_typeProvider.numType, "-");
    node.staticElement = minusMethod;
    node.element = minusMethod;
    JUnitTestCase.assertSame(_typeProvider.numType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitPrefixExpression_minusMinus() {
    PrefixExpression node = ASTFactory.prefixExpression(TokenType.MINUS_MINUS, resolvedInteger(0));
    MethodElement minusMethod = getMethod(_typeProvider.numType, "-");
    node.staticElement = minusMethod;
    node.element = minusMethod;
    JUnitTestCase.assertSame(_typeProvider.intType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitPrefixExpression_not() {
    Expression node = ASTFactory.prefixExpression(TokenType.BANG, ASTFactory.booleanLiteral(true));
    JUnitTestCase.assertSame(_typeProvider.boolType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitPrefixExpression_plusPlus() {
    PrefixExpression node = ASTFactory.prefixExpression(TokenType.PLUS_PLUS, resolvedInteger(0));
    MethodElement plusMethod = getMethod(_typeProvider.numType, "+");
    node.staticElement = plusMethod;
    node.element = plusMethod;
    JUnitTestCase.assertSame(_typeProvider.intType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitPrefixExpression_tilde() {
    PrefixExpression node = ASTFactory.prefixExpression(TokenType.TILDE, resolvedInteger(0));
    MethodElement tildeMethod = getMethod(_typeProvider.intType, "~");
    node.staticElement = tildeMethod;
    node.element = tildeMethod;
    JUnitTestCase.assertSame(_typeProvider.intType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitPropertyAccess_getter() {
    Type2 boolType = _typeProvider.boolType;
    PropertyAccessorElementImpl getter = ElementFactory.getterElement("b", false, boolType);
    PropertyAccess node = ASTFactory.propertyAccess2(ASTFactory.identifier3("a"), "b");
    node.propertyName.element = getter;
    JUnitTestCase.assertSame(boolType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitPropertyAccess_setter() {
    Type2 boolType = _typeProvider.boolType;
    FieldElementImpl field = ElementFactory.fieldElement("b", false, false, false, boolType);
    PropertyAccessorElement setter = field.setter;
    PropertyAccess node = ASTFactory.propertyAccess2(ASTFactory.identifier3("a"), "b");
    node.propertyName.element = setter;
    JUnitTestCase.assertSame(boolType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitSimpleStringLiteral() {
    Expression node = resolvedString("a");
    JUnitTestCase.assertSame(_typeProvider.stringType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitStringInterpolation() {
    Expression node = ASTFactory.string([ASTFactory.interpolationString("a", "a"), ASTFactory.interpolationExpression(resolvedString("b")), ASTFactory.interpolationString("c", "c")]);
    JUnitTestCase.assertSame(_typeProvider.stringType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitSuperExpression() {
    InterfaceType superType = ElementFactory.classElement2("A", []).type;
    InterfaceType thisType = ElementFactory.classElement("B", superType, []).type;
    Expression node = ASTFactory.superExpression();
    JUnitTestCase.assertSame(thisType, analyze2(node, thisType));
    _listener.assertNoErrors();
  }
  void test_visitThisExpression() {
    InterfaceType thisType = ElementFactory.classElement("B", ElementFactory.classElement2("A", []).type, []).type;
    Expression node = ASTFactory.thisExpression();
    JUnitTestCase.assertSame(thisType, analyze2(node, thisType));
    _listener.assertNoErrors();
  }
  void test_visitThrowExpression_withoutValue() {
    Expression node = ASTFactory.throwExpression();
    JUnitTestCase.assertSame(_typeProvider.bottomType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitThrowExpression_withValue() {
    Expression node = ASTFactory.throwExpression2(resolvedInteger(0));
    JUnitTestCase.assertSame(_typeProvider.bottomType, analyze(node));
    _listener.assertNoErrors();
  }

  /**
   * Return the type associated with the given expression after the static type analyzer has
   * computed a type for it.
   * @param node the expression with which the type is associated
   * @return the type associated with the expression
   */
  Type2 analyze(Expression node) => analyze2(node, null);

  /**
   * Return the type associated with the given expression after the static type analyzer has
   * computed a type for it.
   * @param node the expression with which the type is associated
   * @param thisType the type of 'this'
   * @return the type associated with the expression
   */
  Type2 analyze2(Expression node, InterfaceType thisType) {
    try {
      _analyzer.thisType_J2DAccessor = thisType;
    } catch (exception) {
      throw new IllegalArgumentException("Could not set type of 'this'", exception);
    }
    node.accept(_analyzer);
    return node.staticType;
  }

  /**
   * Return the type associated with the given parameter after the static type analyzer has computed
   * a type for it.
   * @param node the parameter with which the type is associated
   * @return the type associated with the parameter
   */
  Type2 analyze3(FormalParameter node) {
    node.accept(_analyzer);
    return ((node.identifier.element as ParameterElement)).type;
  }

  /**
   * Assert that the actual type is a function type with the expected characteristics.
   * @param expectedReturnType the expected return type of the function
   * @param expectedNormalTypes the expected types of the normal parameters
   * @param expectedOptionalTypes the expected types of the optional parameters
   * @param expectedNamedTypes the expected types of the named parameters
   * @param actualType the type being tested
   */
  void assertFunctionType(Type2 expectedReturnType, List<Type2> expectedNormalTypes, List<Type2> expectedOptionalTypes, Map<String, Type2> expectedNamedTypes, Type2 actualType) {
    EngineTestCase.assertInstanceOf(FunctionType, actualType);
    FunctionType functionType = actualType as FunctionType;
    List<Type2> normalTypes = functionType.normalParameterTypes;
    if (expectedNormalTypes == null) {
      EngineTestCase.assertLength(0, normalTypes);
    } else {
      int expectedCount = expectedNormalTypes.length;
      EngineTestCase.assertLength(expectedCount, normalTypes);
      for (int i = 0; i < expectedCount; i++) {
        JUnitTestCase.assertSame(expectedNormalTypes[i], normalTypes[i]);
      }
    }
    List<Type2> optionalTypes = functionType.optionalParameterTypes;
    if (expectedOptionalTypes == null) {
      EngineTestCase.assertLength(0, optionalTypes);
    } else {
      int expectedCount = expectedOptionalTypes.length;
      EngineTestCase.assertLength(expectedCount, optionalTypes);
      for (int i = 0; i < expectedCount; i++) {
        JUnitTestCase.assertSame(expectedOptionalTypes[i], optionalTypes[i]);
      }
    }
    Map<String, Type2> namedTypes = functionType.namedParameterTypes;
    if (expectedNamedTypes == null) {
      EngineTestCase.assertSize2(0, namedTypes);
    } else {
      EngineTestCase.assertSize2(expectedNamedTypes.length, namedTypes);
      for (MapEntry<String, Type2> entry in getMapEntrySet(expectedNamedTypes)) {
        JUnitTestCase.assertSame(entry.getValue(), namedTypes[entry.getKey()]);
      }
    }
    JUnitTestCase.assertSame(expectedReturnType, functionType.returnType);
  }
  void assertType(InterfaceTypeImpl expectedType, InterfaceTypeImpl actualType) {
    JUnitTestCase.assertEquals(expectedType.displayName, actualType.displayName);
    JUnitTestCase.assertEquals(expectedType.element, actualType.element);
    List<Type2> expectedArguments = expectedType.typeArguments;
    int length = expectedArguments.length;
    List<Type2> actualArguments = actualType.typeArguments;
    EngineTestCase.assertLength(length, actualArguments);
    for (int i = 0; i < length; i++) {
      assertType2(expectedArguments[i], actualArguments[i]);
    }
  }
  void assertType2(Type2 expectedType, Type2 actualType) {
    if (expectedType is InterfaceTypeImpl) {
      EngineTestCase.assertInstanceOf(InterfaceTypeImpl, actualType);
      assertType((expectedType as InterfaceTypeImpl), (actualType as InterfaceTypeImpl));
    }
  }

  /**
   * Create the analyzer used by the tests.
   * @return the analyzer to be used by the tests
   */
  StaticTypeAnalyzer createAnalyzer() {
    AnalysisContextImpl context = new AnalysisContextImpl();
    SourceFactory sourceFactory = new SourceFactory.con2([new DartUriResolver(DirectoryBasedDartSdk.defaultSdk)]);
    context.sourceFactory = sourceFactory;
    FileBasedSource source = new FileBasedSource.con1(sourceFactory.contentCache, FileUtilities2.createFile("/lib.dart"));
    CompilationUnitElementImpl definingCompilationUnit = new CompilationUnitElementImpl("lib.dart");
    definingCompilationUnit.source = source;
    LibraryElementImpl definingLibrary = new LibraryElementImpl(context, null);
    definingLibrary.definingCompilationUnit = definingCompilationUnit;
    Library library = new Library(context, _listener, source);
    library.libraryElement = definingLibrary;
    _visitor = new ResolverVisitor.con1(library, source, _typeProvider);
    _visitor.overrideManager.enterScope();
    try {
      return _visitor.typeAnalyzer_J2DAccessor as StaticTypeAnalyzer;
    } catch (exception) {
      throw new IllegalArgumentException("Could not create analyzer", exception);
    }
  }

  /**
   * Return an integer literal that has been resolved to the correct type.
   * @param value the value of the literal
   * @return an integer literal that has been resolved to the correct type
   */
  DoubleLiteral resolvedDouble(double value) {
    DoubleLiteral literal = ASTFactory.doubleLiteral(value);
    literal.staticType = _typeProvider.doubleType;
    return literal;
  }

  /**
   * Create a function expression that has an element associated with it, where the element has an
   * incomplete type associated with it (just like the one[ElementBuilder#visitFunctionExpression] would have built if we had
   * run it).
   * @param parameters the parameters to the function
   * @param body the body of the function
   * @return a resolved function expression
   */
  FunctionExpression resolvedFunctionExpression(FormalParameterList parameters2, FunctionBody body) {
    for (FormalParameter parameter in parameters2.parameters) {
      ParameterElementImpl element = new ParameterElementImpl(parameter.identifier);
      element.parameterKind = parameter.kind;
      element.type = _typeProvider.dynamicType;
      parameter.identifier.element = element;
    }
    FunctionExpression node = ASTFactory.functionExpression2(parameters2, body);
    FunctionElementImpl element = new FunctionElementImpl.con1(null);
    element.type = new FunctionTypeImpl.con1(element);
    node.element = element;
    return node;
  }

  /**
   * Return an integer literal that has been resolved to the correct type.
   * @param value the value of the literal
   * @return an integer literal that has been resolved to the correct type
   */
  IntegerLiteral resolvedInteger(int value) {
    IntegerLiteral literal = ASTFactory.integer(value);
    literal.staticType = _typeProvider.intType;
    return literal;
  }

  /**
   * Return a string literal that has been resolved to the correct type.
   * @param value the value of the literal
   * @return a string literal that has been resolved to the correct type
   */
  SimpleStringLiteral resolvedString(String value) {
    SimpleStringLiteral string = ASTFactory.string2(value);
    string.staticType = _typeProvider.stringType;
    return string;
  }

  /**
   * Return a simple identifier that has been resolved to a variable element with the given type.
   * @param type the type of the variable being represented
   * @param variableName the name of the variable
   * @return a simple identifier that has been resolved to a variable element with the given type
   */
  SimpleIdentifier resolvedVariable(InterfaceType type2, String variableName) {
    SimpleIdentifier identifier = ASTFactory.identifier3(variableName);
    VariableElementImpl element = ElementFactory.localVariableElement(identifier);
    element.type = type2;
    identifier.element = element;
    identifier.staticType = type2;
    return identifier;
  }

  /**
   * Sets the element for the node and remembers it as the static resolution.
   */
  void setStaticElement(BinaryExpression node, MethodElement element2) {
    node.staticElement = element2;
    node.element = element2;
  }

  /**
   * Set the type of the given parameter to the given type.
   * @param parameter the parameter whose type is to be set
   * @param type the new type of the given parameter
   */
  void setType(FormalParameter parameter, Type2 type2) {
    SimpleIdentifier identifier = parameter.identifier;
    Element element = identifier.element;
    if (element is! ParameterElement) {
      element = new ParameterElementImpl(identifier);
      identifier.element = element;
    }
    ((element as ParameterElementImpl)).type = type2;
  }
  static dartSuite() {
    _ut.group('StaticTypeAnalyzerTest', () {
      _ut.test('test_visitAdjacentStrings', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitAdjacentStrings);
      });
      _ut.test('test_visitArgumentDefinitionTest', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitArgumentDefinitionTest);
      });
      _ut.test('test_visitAsExpression', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitAsExpression);
      });
      _ut.test('test_visitAssignmentExpression_compound', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitAssignmentExpression_compound);
      });
      _ut.test('test_visitAssignmentExpression_simple', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitAssignmentExpression_simple);
      });
      _ut.test('test_visitBinaryExpression_equals', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitBinaryExpression_equals);
      });
      _ut.test('test_visitBinaryExpression_logicalAnd', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitBinaryExpression_logicalAnd);
      });
      _ut.test('test_visitBinaryExpression_logicalOr', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitBinaryExpression_logicalOr);
      });
      _ut.test('test_visitBinaryExpression_notEquals', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitBinaryExpression_notEquals);
      });
      _ut.test('test_visitBinaryExpression_plusID', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitBinaryExpression_plusID);
      });
      _ut.test('test_visitBinaryExpression_plusII', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitBinaryExpression_plusII);
      });
      _ut.test('test_visitBinaryExpression_slash', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitBinaryExpression_slash);
      });
      _ut.test('test_visitBinaryExpression_starID', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitBinaryExpression_starID);
      });
      _ut.test('test_visitBinaryExpression_star_notSpecial', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitBinaryExpression_star_notSpecial);
      });
      _ut.test('test_visitBooleanLiteral_false', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitBooleanLiteral_false);
      });
      _ut.test('test_visitBooleanLiteral_true', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitBooleanLiteral_true);
      });
      _ut.test('test_visitCascadeExpression', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitCascadeExpression);
      });
      _ut.test('test_visitConditionalExpression_differentTypes', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitConditionalExpression_differentTypes);
      });
      _ut.test('test_visitConditionalExpression_sameTypes', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitConditionalExpression_sameTypes);
      });
      _ut.test('test_visitDoubleLiteral', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitDoubleLiteral);
      });
      _ut.test('test_visitFunctionExpression_named_block', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitFunctionExpression_named_block);
      });
      _ut.test('test_visitFunctionExpression_named_expression', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitFunctionExpression_named_expression);
      });
      _ut.test('test_visitFunctionExpression_normalAndNamed_block', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitFunctionExpression_normalAndNamed_block);
      });
      _ut.test('test_visitFunctionExpression_normalAndNamed_expression', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitFunctionExpression_normalAndNamed_expression);
      });
      _ut.test('test_visitFunctionExpression_normalAndPositional_block', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitFunctionExpression_normalAndPositional_block);
      });
      _ut.test('test_visitFunctionExpression_normalAndPositional_expression', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitFunctionExpression_normalAndPositional_expression);
      });
      _ut.test('test_visitFunctionExpression_normal_block', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitFunctionExpression_normal_block);
      });
      _ut.test('test_visitFunctionExpression_normal_expression', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitFunctionExpression_normal_expression);
      });
      _ut.test('test_visitFunctionExpression_positional_block', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitFunctionExpression_positional_block);
      });
      _ut.test('test_visitFunctionExpression_positional_expression', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitFunctionExpression_positional_expression);
      });
      _ut.test('test_visitIndexExpression_getter', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitIndexExpression_getter);
      });
      _ut.test('test_visitIndexExpression_setter', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitIndexExpression_setter);
      });
      _ut.test('test_visitIndexExpression_typeParameters', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitIndexExpression_typeParameters);
      });
      _ut.test('test_visitIndexExpression_typeParameters_inSetterContext', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitIndexExpression_typeParameters_inSetterContext);
      });
      _ut.test('test_visitInstanceCreationExpression_named', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitInstanceCreationExpression_named);
      });
      _ut.test('test_visitInstanceCreationExpression_typeParameters', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitInstanceCreationExpression_typeParameters);
      });
      _ut.test('test_visitInstanceCreationExpression_unnamed', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitInstanceCreationExpression_unnamed);
      });
      _ut.test('test_visitIntegerLiteral', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitIntegerLiteral);
      });
      _ut.test('test_visitIsExpression_negated', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitIsExpression_negated);
      });
      _ut.test('test_visitIsExpression_notNegated', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitIsExpression_notNegated);
      });
      _ut.test('test_visitListLiteral_empty', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitListLiteral_empty);
      });
      _ut.test('test_visitListLiteral_nonEmpty', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitListLiteral_nonEmpty);
      });
      _ut.test('test_visitMapLiteral_empty', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitMapLiteral_empty);
      });
      _ut.test('test_visitMapLiteral_nonEmpty', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitMapLiteral_nonEmpty);
      });
      _ut.test('test_visitNamedExpression', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitNamedExpression);
      });
      _ut.test('test_visitNullLiteral', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitNullLiteral);
      });
      _ut.test('test_visitParenthesizedExpression', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitParenthesizedExpression);
      });
      _ut.test('test_visitPostfixExpression_minusMinus', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitPostfixExpression_minusMinus);
      });
      _ut.test('test_visitPostfixExpression_plusPlus', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitPostfixExpression_plusPlus);
      });
      _ut.test('test_visitPrefixExpression_bang', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitPrefixExpression_bang);
      });
      _ut.test('test_visitPrefixExpression_minus', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitPrefixExpression_minus);
      });
      _ut.test('test_visitPrefixExpression_minusMinus', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitPrefixExpression_minusMinus);
      });
      _ut.test('test_visitPrefixExpression_not', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitPrefixExpression_not);
      });
      _ut.test('test_visitPrefixExpression_plusPlus', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitPrefixExpression_plusPlus);
      });
      _ut.test('test_visitPrefixExpression_tilde', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitPrefixExpression_tilde);
      });
      _ut.test('test_visitPrefixedIdentifier_getter', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitPrefixedIdentifier_getter);
      });
      _ut.test('test_visitPrefixedIdentifier_setter', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitPrefixedIdentifier_setter);
      });
      _ut.test('test_visitPrefixedIdentifier_variable', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitPrefixedIdentifier_variable);
      });
      _ut.test('test_visitPropertyAccess_getter', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitPropertyAccess_getter);
      });
      _ut.test('test_visitPropertyAccess_setter', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitPropertyAccess_setter);
      });
      _ut.test('test_visitSimpleStringLiteral', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitSimpleStringLiteral);
      });
      _ut.test('test_visitStringInterpolation', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitStringInterpolation);
      });
      _ut.test('test_visitSuperExpression', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitSuperExpression);
      });
      _ut.test('test_visitThisExpression', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitThisExpression);
      });
      _ut.test('test_visitThrowExpression_withValue', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitThrowExpression_withValue);
      });
      _ut.test('test_visitThrowExpression_withoutValue', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitThrowExpression_withoutValue);
      });
    });
  }
}
class EnclosedScopeTest extends ResolverTestCase {
  void test_define_duplicate() {
    LibraryElement definingLibrary2 = createTestLibrary();
    GatheringErrorListener errorListener2 = new GatheringErrorListener();
    Scope rootScope = new Scope_16(definingLibrary2, errorListener2);
    EnclosedScope scope = new EnclosedScope(rootScope);
    VariableElement element1 = ElementFactory.localVariableElement(ASTFactory.identifier3("v1"));
    VariableElement element2 = ElementFactory.localVariableElement(ASTFactory.identifier3("v1"));
    scope.define(element1);
    scope.define(element2);
    errorListener2.assertErrors3([ErrorSeverity.ERROR]);
  }
  void test_define_normal() {
    LibraryElement definingLibrary3 = createTestLibrary();
    GatheringErrorListener errorListener3 = new GatheringErrorListener();
    Scope rootScope = new Scope_17(definingLibrary3, errorListener3);
    EnclosedScope outerScope = new EnclosedScope(rootScope);
    EnclosedScope innerScope = new EnclosedScope(outerScope);
    VariableElement element1 = ElementFactory.localVariableElement(ASTFactory.identifier3("v1"));
    VariableElement element2 = ElementFactory.localVariableElement(ASTFactory.identifier3("v2"));
    outerScope.define(element1);
    innerScope.define(element2);
    errorListener3.assertNoErrors();
  }
  static dartSuite() {
    _ut.group('EnclosedScopeTest', () {
      _ut.test('test_define_duplicate', () {
        final __test = new EnclosedScopeTest();
        runJUnitTest(__test, __test.test_define_duplicate);
      });
      _ut.test('test_define_normal', () {
        final __test = new EnclosedScopeTest();
        runJUnitTest(__test, __test.test_define_normal);
      });
    });
  }
}
class Scope_16 extends Scope {
  LibraryElement definingLibrary2;
  GatheringErrorListener errorListener2;
  Scope_16(this.definingLibrary2, this.errorListener2) : super();
  LibraryElement get definingLibrary => definingLibrary2;
  AnalysisErrorListener get errorListener => errorListener2;
  Element lookup3(Identifier identifier, String name, LibraryElement referencingLibrary) => null;
}
class Scope_17 extends Scope {
  LibraryElement definingLibrary3;
  GatheringErrorListener errorListener3;
  Scope_17(this.definingLibrary3, this.errorListener3) : super();
  LibraryElement get definingLibrary => definingLibrary3;
  AnalysisErrorListener get errorListener => errorListener3;
  Element lookup3(Identifier identifier, String name, LibraryElement referencingLibrary) => null;
}
class LibraryElementBuilderTest extends EngineTestCase {

  /**
   * The source factory used to create [Source sources].
   */
  SourceFactory _sourceFactory;
  void setUp() {
    _sourceFactory = new SourceFactory.con2([new FileUriResolver()]);
  }
  void test_accessorsAcrossFiles() {
    Source librarySource = addSource("/lib.dart", EngineTestCase.createSource(["library lib;", "part 'first.dart';", "part 'second.dart';"]));
    addSource("/first.dart", EngineTestCase.createSource(["part of lib;", "int get V => 0;"]));
    addSource("/second.dart", EngineTestCase.createSource(["part of lib;", "void set V(int v) {}"]));
    LibraryElement element = buildLibrary(librarySource, []);
    JUnitTestCase.assertNotNull(element);
    List<CompilationUnitElement> sourcedUnits = element.parts;
    EngineTestCase.assertLength(2, sourcedUnits);
    List<PropertyAccessorElement> firstAccessors = sourcedUnits[0].accessors;
    EngineTestCase.assertLength(1, firstAccessors);
    List<PropertyAccessorElement> secondAccessors = sourcedUnits[1].accessors;
    EngineTestCase.assertLength(1, secondAccessors);
    JUnitTestCase.assertSame(firstAccessors[0].variable, secondAccessors[0].variable);
  }
  void test_empty() {
    Source librarySource = addSource("/lib.dart", "library lib;");
    LibraryElement element = buildLibrary(librarySource, []);
    JUnitTestCase.assertNotNull(element);
    JUnitTestCase.assertEquals("lib", element.name);
    JUnitTestCase.assertNull(element.entryPoint);
    EngineTestCase.assertLength(0, element.importedLibraries);
    EngineTestCase.assertLength(0, element.imports);
    JUnitTestCase.assertSame(element, element.library);
    EngineTestCase.assertLength(0, element.prefixes);
    EngineTestCase.assertLength(0, element.parts);
    CompilationUnitElement unit = element.definingCompilationUnit;
    JUnitTestCase.assertNotNull(unit);
    JUnitTestCase.assertEquals("lib.dart", unit.name);
    JUnitTestCase.assertEquals(element, unit.library);
    EngineTestCase.assertLength(0, unit.accessors);
    EngineTestCase.assertLength(0, unit.functions);
    EngineTestCase.assertLength(0, unit.functionTypeAliases);
    EngineTestCase.assertLength(0, unit.types);
    EngineTestCase.assertLength(0, unit.topLevelVariables);
  }
  void test_invalidUri_part() {
    Source librarySource = addSource("/lib.dart", EngineTestCase.createSource(["library lib;", "", "part '\${'a'}.dart';"]));
    LibraryElement element = buildLibrary(librarySource, [CompileTimeErrorCode.URI_WITH_INTERPOLATION]);
    JUnitTestCase.assertNotNull(element);
  }
  void test_missingLibraryDirectiveWithPart() {
    addSource("/a.dart", EngineTestCase.createSource(["part of lib;"]));
    Source librarySource = addSource("/lib.dart", EngineTestCase.createSource(["part 'a.dart';"]));
    LibraryElement element = buildLibrary(librarySource, [ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART]);
    JUnitTestCase.assertNotNull(element);
  }
  void test_missingPartOfDirective() {
    addSource("/a.dart", "class A {}");
    Source librarySource = addSource("/lib.dart", EngineTestCase.createSource(["library lib;", "", "part 'a.dart';"]));
    LibraryElement element = buildLibrary(librarySource, [CompileTimeErrorCode.PART_OF_NON_PART]);
    JUnitTestCase.assertNotNull(element);
  }
  void test_multipleFiles() {
    Source librarySource = addSource("/lib.dart", EngineTestCase.createSource(["library lib;", "part 'first.dart';", "part 'second.dart';", "", "class A {}"]));
    addSource("/first.dart", EngineTestCase.createSource(["part of lib;", "class B {}"]));
    addSource("/second.dart", EngineTestCase.createSource(["part of lib;", "class C {}"]));
    LibraryElement element = buildLibrary(librarySource, []);
    JUnitTestCase.assertNotNull(element);
    List<CompilationUnitElement> sourcedUnits = element.parts;
    EngineTestCase.assertLength(2, sourcedUnits);
    assertTypes(element.definingCompilationUnit, ["A"]);
    if (sourcedUnits[0].name == "first.dart") {
      assertTypes(sourcedUnits[0], ["B"]);
      assertTypes(sourcedUnits[1], ["C"]);
    } else {
      assertTypes(sourcedUnits[0], ["C"]);
      assertTypes(sourcedUnits[1], ["B"]);
    }
  }
  void test_singleFile() {
    Source librarySource = addSource("/lib.dart", EngineTestCase.createSource(["library lib;", "", "class A {}"]));
    LibraryElement element = buildLibrary(librarySource, []);
    JUnitTestCase.assertNotNull(element);
    assertTypes(element.definingCompilationUnit, ["A"]);
  }

  /**
   * Add a source file to the content provider. The file path should be absolute.
   * @param filePath the path of the file being added
   * @param contents the contents to be returned by the content provider for the specified file
   * @return the source object representing the added file
   */
  Source addSource(String filePath, String contents) {
    Source source = new FileBasedSource.con1(_sourceFactory.contentCache, FileUtilities2.createFile(filePath));
    _sourceFactory.setContents(source, contents);
    return source;
  }

  /**
   * Ensure that there are elements representing all of the types in the given array of type names.
   * @param unit the compilation unit containing the types
   * @param typeNames the names of the types that should be found
   */
  void assertTypes(CompilationUnitElement unit, List<String> typeNames) {
    JUnitTestCase.assertNotNull(unit);
    List<ClassElement> types = unit.types;
    EngineTestCase.assertLength(typeNames.length, types);
    for (ClassElement type in types) {
      JUnitTestCase.assertNotNull(type);
      String actualTypeName = type.displayName;
      bool wasExpected = false;
      for (String expectedTypeName in typeNames) {
        if (expectedTypeName == actualTypeName) {
          wasExpected = true;
        }
      }
      if (!wasExpected) {
        JUnitTestCase.fail("Found unexpected type ${actualTypeName}");
      }
    }
  }

  /**
   * Build the element model for the library whose defining compilation unit has the given source.
   * @param librarySource the source of the defining compilation unit for the library
   * @param expectedErrorCodes the errors that are expected to be found while building the element
   * model
   * @return the element model that was built for the library
   * @throws Exception if the element model could not be built
   */
  LibraryElement buildLibrary(Source librarySource, List<ErrorCode> expectedErrorCodes) {
    AnalysisContextImpl context = new AnalysisContextImpl();
    context.sourceFactory = new SourceFactory.con2([new DartUriResolver(DirectoryBasedDartSdk.defaultSdk), new FileUriResolver()]);
    LibraryResolver resolver = new LibraryResolver(context);
    LibraryElementBuilder builder = new LibraryElementBuilder(resolver);
    Library library = resolver.createLibrary(librarySource) as Library;
    LibraryElement element = builder.buildLibrary(library);
    GatheringErrorListener listener = new GatheringErrorListener();
    listener.addAll(resolver.errorListener);
    listener.assertErrors2(expectedErrorCodes);
    return element;
  }
  static dartSuite() {
    _ut.group('LibraryElementBuilderTest', () {
      _ut.test('test_accessorsAcrossFiles', () {
        final __test = new LibraryElementBuilderTest();
        runJUnitTest(__test, __test.test_accessorsAcrossFiles);
      });
      _ut.test('test_empty', () {
        final __test = new LibraryElementBuilderTest();
        runJUnitTest(__test, __test.test_empty);
      });
      _ut.test('test_invalidUri_part', () {
        final __test = new LibraryElementBuilderTest();
        runJUnitTest(__test, __test.test_invalidUri_part);
      });
      _ut.test('test_missingLibraryDirectiveWithPart', () {
        final __test = new LibraryElementBuilderTest();
        runJUnitTest(__test, __test.test_missingLibraryDirectiveWithPart);
      });
      _ut.test('test_missingPartOfDirective', () {
        final __test = new LibraryElementBuilderTest();
        runJUnitTest(__test, __test.test_missingPartOfDirective);
      });
      _ut.test('test_multipleFiles', () {
        final __test = new LibraryElementBuilderTest();
        runJUnitTest(__test, __test.test_multipleFiles);
      });
      _ut.test('test_singleFile', () {
        final __test = new LibraryElementBuilderTest();
        runJUnitTest(__test, __test.test_singleFile);
      });
    });
  }
}
class ScopeTest extends ResolverTestCase {
  void test_define_duplicate() {
    LibraryElement definingLibrary = createTestLibrary();
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ScopeTest_TestScope scope = new ScopeTest_TestScope(definingLibrary, errorListener);
    VariableElement element1 = ElementFactory.localVariableElement(ASTFactory.identifier3("v1"));
    VariableElement element2 = ElementFactory.localVariableElement(ASTFactory.identifier3("v1"));
    scope.define(element1);
    scope.define(element2);
    errorListener.assertErrors3([ErrorSeverity.ERROR]);
  }
  void test_define_normal() {
    LibraryElement definingLibrary = createTestLibrary();
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ScopeTest_TestScope scope = new ScopeTest_TestScope(definingLibrary, errorListener);
    VariableElement element1 = ElementFactory.localVariableElement(ASTFactory.identifier3("v1"));
    VariableElement element2 = ElementFactory.localVariableElement(ASTFactory.identifier3("v2"));
    scope.define(element1);
    scope.define(element2);
    errorListener.assertNoErrors();
  }
  void test_getDefiningLibrary() {
    LibraryElement definingLibrary = createTestLibrary();
    Scope scope = new ScopeTest_TestScope(definingLibrary, null);
    JUnitTestCase.assertEquals(definingLibrary, scope.definingLibrary);
  }
  void test_getErrorListener() {
    LibraryElement definingLibrary = new LibraryElementImpl(new AnalysisContextImpl(), ASTFactory.libraryIdentifier2(["test"]));
    GatheringErrorListener errorListener = new GatheringErrorListener();
    Scope scope = new ScopeTest_TestScope(definingLibrary, errorListener);
    JUnitTestCase.assertEquals(errorListener, scope.errorListener);
  }
  void test_isPrivateName_nonPrivate() {
    JUnitTestCase.assertFalse(Scope.isPrivateName("Public"));
  }
  void test_isPrivateName_private() {
    JUnitTestCase.assertTrue(Scope.isPrivateName("_Private"));
  }
  static dartSuite() {
    _ut.group('ScopeTest', () {
      _ut.test('test_define_duplicate', () {
        final __test = new ScopeTest();
        runJUnitTest(__test, __test.test_define_duplicate);
      });
      _ut.test('test_define_normal', () {
        final __test = new ScopeTest();
        runJUnitTest(__test, __test.test_define_normal);
      });
      _ut.test('test_getDefiningLibrary', () {
        final __test = new ScopeTest();
        runJUnitTest(__test, __test.test_getDefiningLibrary);
      });
      _ut.test('test_getErrorListener', () {
        final __test = new ScopeTest();
        runJUnitTest(__test, __test.test_getErrorListener);
      });
      _ut.test('test_isPrivateName_nonPrivate', () {
        final __test = new ScopeTest();
        runJUnitTest(__test, __test.test_isPrivateName_nonPrivate);
      });
      _ut.test('test_isPrivateName_private', () {
        final __test = new ScopeTest();
        runJUnitTest(__test, __test.test_isPrivateName_private);
      });
    });
  }
}
/**
 * A non-abstract subclass that can be used for testing purposes.
 */
class ScopeTest_TestScope extends Scope {

  /**
   * The element representing the library in which this scope is enclosed.
   */
  LibraryElement _definingLibrary;

  /**
   * The listener that is to be informed when an error is encountered.
   */
  AnalysisErrorListener _errorListener;
  ScopeTest_TestScope(LibraryElement definingLibrary, AnalysisErrorListener errorListener) {
    this._definingLibrary = definingLibrary;
    this._errorListener = errorListener;
  }
  LibraryElement get definingLibrary => _definingLibrary;
  AnalysisErrorListener get errorListener => _errorListener;
  Element lookup3(Identifier identifier, String name, LibraryElement referencingLibrary) => localLookup(name, referencingLibrary);
}
class SimpleResolverTest extends ResolverTestCase {
  void fail_staticInvocation() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  static int get g => (a,b) => 0;", "}", "class B {", "  f() {", "    A.g(1,0);", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_argumentResolution_required_matching() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void f() {", "    g(1, 2, 3);", "  }", "  void g(a, b, c) {}", "}"]));
    validateArgumentResolution(source, [0, 1, 2]);
  }
  void test_argumentResolution_required_tooFew() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void f() {", "    g(1, 2);", "  }", "  void g(a, b, c) {}", "}"]));
    validateArgumentResolution(source, [0, 1]);
  }
  void test_argumentResolution_required_tooMany() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void f() {", "    g(1, 2, 3);", "  }", "  void g(a, b) {}", "}"]));
    validateArgumentResolution(source, [0, 1, -1]);
  }
  void test_argumentResolution_requiredAndNamed_extra() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void f() {", "    g(1, 2, c: 3, d: 4);", "  }", "  void g(a, b, {c}) {}", "}"]));
    validateArgumentResolution(source, [0, 1, 2, -1]);
  }
  void test_argumentResolution_requiredAndNamed_matching() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void f() {", "    g(1, 2, c: 3);", "  }", "  void g(a, b, {c}) {}", "}"]));
    validateArgumentResolution(source, [0, 1, 2]);
  }
  void test_argumentResolution_requiredAndNamed_missing() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void f() {", "    g(1, 2, d: 3);", "  }", "  void g(a, b, {c, d}) {}", "}"]));
    validateArgumentResolution(source, [0, 1, 3]);
  }
  void test_argumentResolution_requiredAndPositional_fewer() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void f() {", "    g(1, 2, 3);", "  }", "  void g(a, b, [c, d]) {}", "}"]));
    validateArgumentResolution(source, [0, 1, 2]);
  }
  void test_argumentResolution_requiredAndPositional_matching() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void f() {", "    g(1, 2, 3, 4);", "  }", "  void g(a, b, [c, d]) {}", "}"]));
    validateArgumentResolution(source, [0, 1, 2, 3]);
  }
  void test_argumentResolution_requiredAndPositional_more() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void f() {", "    g(1, 2, 3, 4);", "  }", "  void g(a, b, [c]) {}", "}"]));
    validateArgumentResolution(source, [0, 1, 2, -1]);
  }
  void test_class_definesCall() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int call(int x) { return x; }", "}", "int f(A a) {", "  return a(0);", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_class_extends_implements() {
    Source source = addSource(EngineTestCase.createSource(["class A extends B implements C {}", "class B {}", "class C {}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_commentReference_class() {
    Source source = addSource(EngineTestCase.createSource(["f() {}", "/** [A] [new A] [A.n] [new A.n] [m] [f] */", "class A {", "  A() {}", "  A.n() {}", "  m() {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_commentReference_parameter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A() {}", "  A.n() {}", "  /** [e] [f] */", "  m(e, f()) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_commentReference_singleLine() {
    Source source = addSource(EngineTestCase.createSource(["/// [A]", "class A {}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_empty() {
    Source source = addSource("");
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_extractedMethodAsConstant() {
    Source source = addSource(EngineTestCase.createSource(["abstract class Comparable<T> {", "  int compareTo(T other);", "  static int compare(Comparable a, Comparable b) => a.compareTo(b);", "}", "class A {", "  void sort([compare = Comparable.compare]) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_fieldFormalParameter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int x;", "  A(this.x) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_forEachLoops_nonConflicting() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  List list = [1,2,3];", "  for (int x in list) {}", "  for (int x in list) {}", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_forLoops_nonConflicting() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  for (int i = 0; i < 3; i++) {", "  }", "  for (int i = 0; i < 3; i++) {", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_functionTypeAlias() {
    Source source = addSource(EngineTestCase.createSource(["typedef bool P(e);", "class A {", "  P p;", "  m(e) {", "    if (p(e)) {}", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_getterAndSetterWithDifferentTypes() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int get f => 0;", "  void set f(String s) {}", "}", "g (A a) {", "  a.f = a.f.toString();", "}"]));
    resolve(source);
    assertErrors([StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES]);
    verify([source]);
  }
  void test_hasReferenceToSuper() {
    Source source = addSource(EngineTestCase.createSource(["class A {}", "class B {toString() => super.toString();}"]));
    LibraryElement library = resolve(source);
    JUnitTestCase.assertNotNull(library);
    CompilationUnitElement unit = library.definingCompilationUnit;
    JUnitTestCase.assertNotNull(unit);
    List<ClassElement> classes = unit.types;
    EngineTestCase.assertLength(2, classes);
    JUnitTestCase.assertFalse(classes[0].hasReferenceToSuper());
    JUnitTestCase.assertTrue(classes[1].hasReferenceToSuper());
    assertNoErrors();
    verify([source]);
  }
  void test_import_hide() {
    addSource2("lib1.dart", EngineTestCase.createSource(["library lib1;", "set foo(value) {}"]));
    addSource2("lib2.dart", EngineTestCase.createSource(["library lib2;", "set foo(value) {}"]));
    Source source = addSource2("lib3.dart", EngineTestCase.createSource(["import 'lib1.dart' hide foo;", "import 'lib2.dart';", "", "main() {", "  foo = 0;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_import_prefix() {
    addSource2("/two.dart", EngineTestCase.createSource(["library two;", "f(int x) {", "  return x * x;", "}"]));
    Source source = addSource2("/one.dart", EngineTestCase.createSource(["library one;", "import 'two.dart' as _two;", "main() {", "  _two.f(0);", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_indexExpression_typeParameters() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  List<int> a;", "  a[0];", "  List<List<int>> b;", "  b[0][0];", "  List<List<List<int>>> c;", "  c[0][0][0];", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_indexExpression_typeParameters_invalidAssignmentWarning() {
    Source source = addSource(EngineTestCase.createSource(["f() {", "  List<List<int>> b;", "  b[0][0] = 'hi';", "}"]));
    resolve(source);
    assertErrors([StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }
  void test_indirectOperatorThroughCall() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  B call() { return new B(); }", "}", "", "class B {", "  int operator [](int i) { return i; }", "}", "", "A f = new A();", "", "g(int x) {}", "", "main() {", "  g(f()[0]);", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_invoke_dynamicThroughGetter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  List get X => [() => 0];", "  m(A a) {", "    X.last;", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_isValidMixin_badSuperclass() {
    Source source = addSource(EngineTestCase.createSource(["class A extends B {}", "class B {}"]));
    LibraryElement library = resolve(source);
    JUnitTestCase.assertNotNull(library);
    CompilationUnitElement unit = library.definingCompilationUnit;
    JUnitTestCase.assertNotNull(unit);
    List<ClassElement> classes = unit.types;
    EngineTestCase.assertLength(2, classes);
    JUnitTestCase.assertFalse(classes[0].isValidMixin);
    assertNoErrors();
    verify([source]);
  }
  void test_isValidMixin_constructor() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  A() {}", "}"]));
    LibraryElement library = resolve(source);
    JUnitTestCase.assertNotNull(library);
    CompilationUnitElement unit = library.definingCompilationUnit;
    JUnitTestCase.assertNotNull(unit);
    List<ClassElement> classes = unit.types;
    EngineTestCase.assertLength(1, classes);
    JUnitTestCase.assertFalse(classes[0].isValidMixin);
    assertNoErrors();
    verify([source]);
  }
  void test_isValidMixin_super() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  toString() {", "    return super.toString();", "  }", "}"]));
    LibraryElement library = resolve(source);
    JUnitTestCase.assertNotNull(library);
    CompilationUnitElement unit = library.definingCompilationUnit;
    JUnitTestCase.assertNotNull(unit);
    List<ClassElement> classes = unit.types;
    EngineTestCase.assertLength(1, classes);
    JUnitTestCase.assertFalse(classes[0].isValidMixin);
    assertNoErrors();
    verify([source]);
  }
  void test_isValidMixin_valid() {
    Source source = addSource(EngineTestCase.createSource(["class A {}"]));
    LibraryElement library = resolve(source);
    JUnitTestCase.assertNotNull(library);
    CompilationUnitElement unit = library.definingCompilationUnit;
    JUnitTestCase.assertNotNull(unit);
    List<ClassElement> classes = unit.types;
    EngineTestCase.assertLength(1, classes);
    JUnitTestCase.assertTrue(classes[0].isValidMixin);
    assertNoErrors();
    verify([source]);
  }
  void test_labels_switch() {
    Source source = addSource(EngineTestCase.createSource(["void doSwitch(int target) {", "  switch (target) {", "    l0: case 0:", "      continue l1;", "    l1: case 1:", "      continue l0;", "    default:", "      continue l1;", "  }", "}"]));
    LibraryElement library = resolve(source);
    JUnitTestCase.assertNotNull(library);
    assertNoErrors();
    verify([source]);
  }
  void test_metadata_class() {
    Source source = addSource(EngineTestCase.createSource(["const A = null;", "@A class C {}"]));
    LibraryElement library = resolve(source);
    JUnitTestCase.assertNotNull(library);
    CompilationUnitElement unit = library.definingCompilationUnit;
    JUnitTestCase.assertNotNull(unit);
    List<ClassElement> classes = unit.types;
    EngineTestCase.assertLength(1, classes);
    List<ElementAnnotation> annotations = classes[0].metadata;
    EngineTestCase.assertLength(1, annotations);
    assertNoErrors();
    verify([source]);
  }
  void test_metadata_field() {
    Source source = addSource(EngineTestCase.createSource(["const A = null;", "class C {", "  @A int f;", "}"]));
    LibraryElement library = resolve(source);
    JUnitTestCase.assertNotNull(library);
    CompilationUnitElement unit = library.definingCompilationUnit;
    JUnitTestCase.assertNotNull(unit);
    List<ClassElement> classes = unit.types;
    EngineTestCase.assertLength(1, classes);
    FieldElement field = classes[0].fields[0];
    List<ElementAnnotation> annotations = field.metadata;
    EngineTestCase.assertLength(1, annotations);
    assertNoErrors();
    verify([source]);
  }
  void test_metadata_libraryDirective() {
    Source source = addSource(EngineTestCase.createSource(["@A library lib;", "const A = null;"]));
    LibraryElement library = resolve(source);
    JUnitTestCase.assertNotNull(library);
    List<ElementAnnotation> annotations = library.metadata;
    EngineTestCase.assertLength(1, annotations);
    assertNoErrors();
    verify([source]);
  }
  void test_metadata_method() {
    Source source = addSource(EngineTestCase.createSource(["const A = null;", "class C {", "  @A void m() {}", "}"]));
    LibraryElement library = resolve(source);
    JUnitTestCase.assertNotNull(library);
    CompilationUnitElement unit = library.definingCompilationUnit;
    JUnitTestCase.assertNotNull(unit);
    List<ClassElement> classes = unit.types;
    EngineTestCase.assertLength(1, classes);
    MethodElement method = classes[0].methods[0];
    List<ElementAnnotation> annotations = method.metadata;
    EngineTestCase.assertLength(1, annotations);
    assertNoErrors();
    verify([source]);
  }
  void test_method_fromMixin() {
    Source source = addSource(EngineTestCase.createSource(["class B {", "  bar() => 1;", "}", "class A {", "  foo() => 2;", "}", "", "class C extends B with A {", "  bar() => super.bar();", "  foo() => super.foo();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_method_fromSuperclassMixin() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void m1() {}", "}", "class B extends Object with A {", "}", "class C extends B {", "}", "f(C c) {", "  c.m1();", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_methodCascades() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  void m1() {}", "  void m2() {}", "  void m() {", "    A a = new A();", "    a..m1()", "     ..m2();", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_methodCascades_withSetter() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  String name;", "  void m1() {}", "  void m2() {}", "  void m() {", "    A a = new A();", "    a..m1()", "     ..name = 'name'", "     ..m2();", "  }", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_resolveAgainstNull() {
    Source source = addSource(EngineTestCase.createSource(["f(var p) {", "  return null == p;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_setter_inherited() {
    Source source = addSource(EngineTestCase.createSource(["class A {", "  int get x => 0;", "  set x(int p) {}", "}", "class B extends A {", "  int get x => super.x == null ? 0 : super.x;", "  int f() => x = 1;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }
  void test_setter_static() {
    Source source = addSource(EngineTestCase.createSource(["set s(x) {", "}", "", "main() {", "  s = 123;", "}"]));
    resolve(source);
    assertNoErrors();
    verify([source]);
  }

  /**
   * Resolve the given source and verify that the arguments in a specific method invocation were
   * correctly resolved.
   *
   * The source is expected to be source for a compilation unit, the first declaration is expected
   * to be a class, the first member of which is expected to be a method with a block body, and the
   * first statement in the body is expected to be an expression statement whose expression is a
   * method invocation. It is the arguments to that method invocation that are tested. The method
   * invocation can contain errors.
   *
   * The arguments were resolved correctly if the number of expressions in the list matches the
   * length of the array of indices and if, for each index in the array of indices, the parameter to
   * which the argument expression was resolved is the parameter in the invoked method's list of
   * parameters at that index. Arguments that should not be resolved to a parameter because of an
   * error can be denoted by including a negative index in the array of indices.
   * @param source the source to be resolved
   * @param indices the array of indices used to associate arguments with parameters
   * @throws Exception if the source could not be resolved or if the structure of the source is not
   * valid
   */
  void validateArgumentResolution(Source source, List<int> indices) {
    LibraryElement library = resolve(source);
    JUnitTestCase.assertNotNull(library);
    ClassElement classElement = library.definingCompilationUnit.types[0];
    List<ParameterElement> parameters = classElement.methods[1].parameters;
    CompilationUnit unit = resolveCompilationUnit(source, library);
    JUnitTestCase.assertNotNull(unit);
    ClassDeclaration classDeclaration = unit.declarations[0] as ClassDeclaration;
    MethodDeclaration methodDeclaration = (classDeclaration.members[0] as MethodDeclaration);
    Block block = ((methodDeclaration.body as BlockFunctionBody)).block;
    ExpressionStatement statement = block.statements[0] as ExpressionStatement;
    MethodInvocation invocation = statement.expression as MethodInvocation;
    NodeList<Expression> arguments = invocation.argumentList.arguments;
    int argumentCount = arguments.length;
    JUnitTestCase.assertEquals(indices.length, argumentCount);
    for (int i = 0; i < argumentCount; i++) {
      Expression argument = arguments[i];
      ParameterElement element = argument.staticParameterElement;
      int index = indices[i];
      if (index < 0) {
        JUnitTestCase.assertNull(element);
      } else {
        JUnitTestCase.assertSame(parameters[index], element);
      }
    }
  }
  static dartSuite() {
    _ut.group('SimpleResolverTest', () {
      _ut.test('test_argumentResolution_requiredAndNamed_extra', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_argumentResolution_requiredAndNamed_extra);
      });
      _ut.test('test_argumentResolution_requiredAndNamed_matching', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_argumentResolution_requiredAndNamed_matching);
      });
      _ut.test('test_argumentResolution_requiredAndNamed_missing', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_argumentResolution_requiredAndNamed_missing);
      });
      _ut.test('test_argumentResolution_requiredAndPositional_fewer', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_argumentResolution_requiredAndPositional_fewer);
      });
      _ut.test('test_argumentResolution_requiredAndPositional_matching', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_argumentResolution_requiredAndPositional_matching);
      });
      _ut.test('test_argumentResolution_requiredAndPositional_more', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_argumentResolution_requiredAndPositional_more);
      });
      _ut.test('test_argumentResolution_required_matching', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_argumentResolution_required_matching);
      });
      _ut.test('test_argumentResolution_required_tooFew', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_argumentResolution_required_tooFew);
      });
      _ut.test('test_argumentResolution_required_tooMany', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_argumentResolution_required_tooMany);
      });
      _ut.test('test_class_definesCall', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_class_definesCall);
      });
      _ut.test('test_class_extends_implements', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_class_extends_implements);
      });
      _ut.test('test_commentReference_class', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_commentReference_class);
      });
      _ut.test('test_commentReference_parameter', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_commentReference_parameter);
      });
      _ut.test('test_commentReference_singleLine', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_commentReference_singleLine);
      });
      _ut.test('test_empty', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_empty);
      });
      _ut.test('test_extractedMethodAsConstant', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_extractedMethodAsConstant);
      });
      _ut.test('test_fieldFormalParameter', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_fieldFormalParameter);
      });
      _ut.test('test_forEachLoops_nonConflicting', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_forEachLoops_nonConflicting);
      });
      _ut.test('test_forLoops_nonConflicting', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_forLoops_nonConflicting);
      });
      _ut.test('test_functionTypeAlias', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_functionTypeAlias);
      });
      _ut.test('test_getterAndSetterWithDifferentTypes', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_getterAndSetterWithDifferentTypes);
      });
      _ut.test('test_hasReferenceToSuper', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_hasReferenceToSuper);
      });
      _ut.test('test_import_hide', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_import_hide);
      });
      _ut.test('test_import_prefix', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_import_prefix);
      });
      _ut.test('test_indexExpression_typeParameters', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_indexExpression_typeParameters);
      });
      _ut.test('test_indexExpression_typeParameters_invalidAssignmentWarning', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_indexExpression_typeParameters_invalidAssignmentWarning);
      });
      _ut.test('test_indirectOperatorThroughCall', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_indirectOperatorThroughCall);
      });
      _ut.test('test_invoke_dynamicThroughGetter', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_invoke_dynamicThroughGetter);
      });
      _ut.test('test_isValidMixin_badSuperclass', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_isValidMixin_badSuperclass);
      });
      _ut.test('test_isValidMixin_constructor', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_isValidMixin_constructor);
      });
      _ut.test('test_isValidMixin_super', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_isValidMixin_super);
      });
      _ut.test('test_isValidMixin_valid', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_isValidMixin_valid);
      });
      _ut.test('test_labels_switch', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_labels_switch);
      });
      _ut.test('test_metadata_class', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_metadata_class);
      });
      _ut.test('test_metadata_field', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_metadata_field);
      });
      _ut.test('test_metadata_libraryDirective', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_metadata_libraryDirective);
      });
      _ut.test('test_metadata_method', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_metadata_method);
      });
      _ut.test('test_methodCascades', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_methodCascades);
      });
      _ut.test('test_methodCascades_withSetter', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_methodCascades_withSetter);
      });
      _ut.test('test_method_fromMixin', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_method_fromMixin);
      });
      _ut.test('test_method_fromSuperclassMixin', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_method_fromSuperclassMixin);
      });
      _ut.test('test_resolveAgainstNull', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_resolveAgainstNull);
      });
      _ut.test('test_setter_inherited', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_setter_inherited);
      });
      _ut.test('test_setter_static', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_setter_static);
      });
    });
  }
}
main() {
//  ElementResolverTest.dartSuite();
//  InheritanceManagerTest.dartSuite();
//  LibraryElementBuilderTest.dartSuite();
//  LibraryTest.dartSuite();
//  StaticTypeAnalyzerTest.dartSuite();
//  TypeOverrideManagerTest.dartSuite();
//  TypeProviderImplTest.dartSuite();
//  TypeResolverVisitorTest.dartSuite();
//  EnclosedScopeTest.dartSuite();
//  LibraryImportScopeTest.dartSuite();
//  LibraryScopeTest.dartSuite();
//  ScopeTest.dartSuite();
//  CompileTimeErrorCodeTest.dartSuite();
//  ErrorResolverTest.dartSuite();
//  NonErrorResolverTest.dartSuite();
//  SimpleResolverTest.dartSuite();
//  StaticTypeWarningCodeTest.dartSuite();
//  StaticWarningCodeTest.dartSuite();
//  StrictModeTest.dartSuite();
//  TypePropagationTest.dartSuite();
}