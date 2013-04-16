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
import 'package:analyzer_experimental/src/generated/ast.dart' hide Annotation;
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
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  bool get g => true;", "}", "A f(var p) {", "  if ((p as A).g) {", "    return p;", "  } else {", "    return null;", "  }", "}"]));
    LibraryElement library = resolve(source, []);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body6 = function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body6.block.statements[0] as IfStatement;
    ReturnStatement statement = ((ifStatement.thenStatement as Block)).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.staticType);
  }
  void test_assert() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "A f(var p) {", "  assert (p is A);", "  return p;", "}"]));
    LibraryElement library = resolve(source, []);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body7 = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body7.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.staticType);
  }
  void test_assignment() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  var v;", "  v = 0;", "  return v;", "}"]));
    LibraryElement library = resolve(source, []);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body8 = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body8.block.statements[2] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeProvider.intType, variableName.staticType);
  }
  void test_assignment_afterInitializer() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  var v = 0;", "  v = 1.0;", "  return v;", "}"]));
    LibraryElement library = resolve(source, []);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body9 = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body9.block.statements[2] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeProvider.doubleType, variableName.staticType);
  }
  void test_initializer() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  var v = 0;", "  return v;", "}"]));
    LibraryElement library = resolve(source, []);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body10 = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body10.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeProvider.intType, variableName.staticType);
  }
  void test_is_conditional() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "A f(var p) {", "  return (p is A) ? p : null;", "}"]));
    LibraryElement library = resolve(source, []);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body11 = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body11.block.statements[0] as ReturnStatement;
    ConditionalExpression conditional = statement.expression as ConditionalExpression;
    SimpleIdentifier variableName = conditional.thenExpression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.staticType);
  }
  void test_is_if() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "A f(var p) {", "  if (p is A) {", "    return p;", "  } else {", "    return null;", "  }", "}"]));
    LibraryElement library = resolve(source, []);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body12 = function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body12.block.statements[0] as IfStatement;
    ReturnStatement statement = ((ifStatement.thenStatement as Block)).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.staticType);
  }
  void test_is_if_logicalAnd() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "A f(var p) {", "  if (p is A && p != null) {", "    return p;", "  } else {", "    return null;", "  }", "}"]));
    LibraryElement library = resolve(source, []);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body13 = function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body13.block.statements[0] as IfStatement;
    ReturnStatement statement = ((ifStatement.thenStatement as Block)).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.staticType);
  }
  void test_is_postConditional() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "A f(var p) {", "  A a = (p is A) ? p : throw null;", "  return p;", "}"]));
    LibraryElement library = resolve(source, []);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body14 = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body14.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.staticType);
  }
  void test_is_postIf() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "A f(var p) {", "  if (p is A) {", "    A a = p;", "  } else {", "    return null;", "  }", "  return p;", "}"]));
    LibraryElement library = resolve(source, []);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body15 = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body15.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.staticType);
  }
  void test_is_subclass() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "class B extends A {", "  B m() => this;", "}", "A f(A p) {", "  if (p is B) {", "    return p.m();", "  }", "}"]));
    LibraryElement library = resolve(source, []);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[2] as FunctionDeclaration;
    BlockFunctionBody body16 = function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body16.block.statements[0] as IfStatement;
    ReturnStatement statement = ((ifStatement.thenStatement as Block)).statements[0] as ReturnStatement;
    MethodInvocation invocation = statement.expression as MethodInvocation;
    JUnitTestCase.assertNotNull(invocation.methodName.element);
  }
  void test_isNot_conditional() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "A f(var p) {", "  return (p is! A) ? null : p;", "}"]));
    LibraryElement library = resolve(source, []);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body17 = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body17.block.statements[0] as ReturnStatement;
    ConditionalExpression conditional = statement.expression as ConditionalExpression;
    SimpleIdentifier variableName = conditional.elseExpression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.staticType);
  }
  void test_isNot_if() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "A f(var p) {", "  if (p is! A) {", "    return null;", "  } else {", "    return p;", "  }", "}"]));
    LibraryElement library = resolve(source, []);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body18 = function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body18.block.statements[0] as IfStatement;
    ReturnStatement statement = ((ifStatement.elseStatement as Block)).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.staticType);
  }
  void test_isNot_if_logicalOr() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "A f(var p) {", "  if (p is! A || null == p) {", "    return null;", "  } else {", "    return p;", "  }", "}"]));
    LibraryElement library = resolve(source, []);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body19 = function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body19.block.statements[0] as IfStatement;
    ReturnStatement statement = ((ifStatement.elseStatement as Block)).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.staticType);
  }
  void test_isNot_postConditional() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "A f(var p) {", "  A a = (p is! A) ? throw null : p;", "  return p;", "}"]));
    LibraryElement library = resolve(source, []);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body20 = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body20.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.staticType);
  }
  void test_isNot_postIf() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "A f(var p) {", "  if (p is! A) {", "    return null;", "  }", "  return p;", "}"]));
    LibraryElement library = resolve(source, []);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body21 = function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body21.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    JUnitTestCase.assertSame(typeA, variableName.staticType);
  }
  void test_query() {
    addSource("/html.dart", EngineTestCase.createSource(["library dart.dom.html;", "", "class Element {}", "class AnchorElement extends Element {}", "class BodyElement extends Element {}", "class ButtonElement extends Element {}", "class DivElement extends Element {}", "class Document extends Element {}", "class HtmlDocument extends Document {", "  Element query(String selector) { return null; }", "}", "class InputElement extends Element {}", "class SelectElement extends Element {}", "", "HtmlDocument document = null;", "", "Element query(String selector) { return null; }"]));
    Source source = addSource("/test.dart", EngineTestCase.createSource(["import 'html.dart';", "", "main() {", "  var v1 = query('a');", "  var v2 = query('A');", "  var v3 = query('body:active');", "  var v4 = query('button[foo=\"bar\"]');", "  var v5 = query('div.class');", "  var v6 = query('input#id');", "  var v7 = query('select#id');", "  // invocation of method", "  var m1 = document.query('div');", " // unsupported currently", "  var b1 = query('noSuchTag');", "  var b2 = query('DART_EDITOR_NO_SUCH_TYPE');", "  var b3 = query('body div');", "  return [v1, v2, v3, v4, v5, v6, v7, m1, b1, b2, b3];", "}"]));
    LibraryElement library = resolve(source, []);
    assertNoErrors();
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration main = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body22 = main.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body22.block.statements[11] as ReturnStatement;
    NodeList<Expression> elements3 = ((statement.expression as ListLiteral)).elements;
    JUnitTestCase.assertEquals("AnchorElement", elements3[0].staticType.name);
    JUnitTestCase.assertEquals("AnchorElement", elements3[1].staticType.name);
    JUnitTestCase.assertEquals("BodyElement", elements3[2].staticType.name);
    JUnitTestCase.assertEquals("ButtonElement", elements3[3].staticType.name);
    JUnitTestCase.assertEquals("DivElement", elements3[4].staticType.name);
    JUnitTestCase.assertEquals("InputElement", elements3[5].staticType.name);
    JUnitTestCase.assertEquals("SelectElement", elements3[6].staticType.name);
    JUnitTestCase.assertEquals("DivElement", elements3[7].staticType.name);
    JUnitTestCase.assertEquals("Element", elements3[8].staticType.name);
    JUnitTestCase.assertEquals("Element", elements3[9].staticType.name);
    JUnitTestCase.assertEquals("Element", elements3[10].staticType.name);
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
      _ut.test('test_initializer', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_initializer);
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
      _ut.test('test_query', () {
        final __test = new TypePropagationTest();
        runJUnitTest(__test, __test.test_query);
      });
    });
  }
}
class NonErrorResolverTest extends ResolverTestCase {
  void test_argumentDefinitionTestNonParameter_formalParameter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f(var v) {", "  return ?v;", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_argumentDefinitionTestNonParameter_namedParameter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f({var v : 0}) {", "  return ?v;", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_argumentDefinitionTestNonParameter_optionalParameter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f([var v]) {", "  return ?v;", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_breakWithoutLabelInSwitch() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  void m(int i) {", "    switch (i) {", "      case 0:", "        break;", "    }", "  }", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_builtInIdentifierAsType_dynamic() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  dynamic x;", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_caseExpressionTypeImplementsEquals_int() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f(int i) {", "  switch(i) {", "    case(1) : return 1;", "    default: return 0;", "  }", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_caseExpressionTypeImplementsEquals_Object() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class IntWrapper {", "  final int value;", "  const IntWrapper(this.value);", "}", "", "f(IntWrapper intWrapper) {", "  switch(intWrapper) {", "    case(const IntWrapper(1)) : return 1;", "    default: return 0;", "  }", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_caseExpressionTypeImplementsEquals_String() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f(String s) {", "  switch(s) {", "    case('1') : return 1;", "    default: return 0;", "  }", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_constConstructorWithNonFinalField_constInstanceVar() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  const int x = 0;", "  const A() {}", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_constConstructorWithNonFinalField_finalInstanceVar() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  final int x = 0;", "  const A() {}", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_constConstructorWithNonFinalField_static() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  static int x;", "  const A() {}", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_constConstructorWithNonFinalField_syntheticField() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  const A();", "  set x(value) {}", "  get x {return 0;}", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_defaultValueInFunctionTypeAlias() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["typedef F([x]);"]));
    resolve(source, []);
    assertErrors([]);
    verify([source]);
  }
  void test_duplicateDefinition_emptyName() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["Map _globalMap = {", "  'a' : () {},", "  'b' : () {}", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_duplicateDefinition_getter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["bool get a => true;"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_exportOfNonLibrary_libraryDeclared() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["library L;", "export 'lib1.dart';"]));
    addSource("/lib1.dart", EngineTestCase.createSource(["library lib1;"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_exportOfNonLibrary_libraryNotDeclared() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["library L;", "export 'lib1.dart';"]));
    addSource("/lib1.dart", EngineTestCase.createSource([""]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_fieldInitializedByMultipleInitializers() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int x;", "  int y;", "  A() : x = 0, y = 0 {}", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_fieldInitializedInInitializerAndDeclaration_fieldNotFinal() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int x = 0;", "  A() : x = 1 {}", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_fieldInitializedInInitializerAndDeclaration_finalFieldNotSet() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  final int x;", "  A() : x = 1 {}", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_fieldInitializerOutsideConstructor() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int x;", "  A(this.x) {}", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_fieldInitializerOutsideConstructor_defaultParameters() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int x;", "  A([this.x]) {}", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_finalInitializedInDeclarationAndConstructor_initializer() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  final x;", "  A() : x = 1 {}", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_finalInitializedInDeclarationAndConstructor_initializingFormal() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  final x;", "  A(this.x) {}", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_finalNotInitialized_atDeclaration() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  final int x = 0;", "  A() {}", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_finalNotInitialized_fieldFormal() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  final int x = 0;", "  A() {}", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_finalNotInitialized_initializer() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  final int x;", "  A() : x = 0 {}", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_importOfNonLibrary_libraryDeclared() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["library lib;", "import 'part.dart';"]));
    addSource("/part.dart", EngineTestCase.createSource(["library lib1;"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_importOfNonLibrary_libraryNotDeclared() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["library lib;", "import 'part.dart';"]));
    addSource("/part.dart", EngineTestCase.createSource([""]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_initializingFormalForNonExistantField() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int x;", "  A(this.x) {}", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidAssignment() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  var x;", "  var y;", "  x = y;", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_invalidAssignment_toDynamic() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  var g;", "  g = () => 0;", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_invocationOfNonFunction_dynamic() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  var f;", "}", "class B extends A {", "  g() {", "    f();", "  }", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_invocationOfNonFunction_getter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  var g;", "}", "f() {", "  A a;", "  a.g();", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_invocationOfNonFunction_localVariable() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  var g;", "  g();", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_newWithAbstractClass_factory() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["abstract class A {", "  factory A() { return new B(); }", "}", "class B implements A {", "  B() {}", "}", "A f() {", "  return new A();", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_nonBoolExpression_assert_bool() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  assert(true);", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_nonBoolExpression_assert_functionType() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["bool makeAssertion() => true;", "f() {", "  assert(makeAssertion);", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_rethrowOutsideCatch() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  void m() {", "    try {} catch (e) {rethrow;}", "  }", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_returnOfInvalidType_dynamic() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class TypeError {}", "class A {", "  static void testLogicalOp() {", "    testOr(a, b, onTypeError) {", "      try {", "        return a || b;", "      } on TypeError catch (t) {", "        return onTypeError;", "      }", "    }", "  }", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_returnOfInvalidType_subtype() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "class B extends A {}", "A f(B b) { return b; }"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_returnOfInvalidType_supertype() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "class B extends A {}", "B f(A a) { return a; }"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_typeArgumentNotMatchingBounds_const() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "class B extends A {}", "class G<E extends A> {", "  const G() {}", "}", "f() { return const G<B>(); }"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_typeArgumentNotMatchingBounds_new() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "class B extends A {}", "class G<E extends A> {}", "f() { return new G<B>(); }"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_undefinedGetter_typeSubstitution() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A<E> {", "  E element;", "}", "class B extends A<List> {", "  m() {", "    element.last;", "  }", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_undefinedIdentifier_hide() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["library L;", "export 'lib1.dart' hide a;"]));
    addSource("/lib1.dart", EngineTestCase.createSource(["library lib1;"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_undefinedIdentifier_show() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["library L;", "export 'lib1.dart' show a;"]));
    addSource("/lib1.dart", EngineTestCase.createSource(["library lib1;"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_undefinedOperator_tilde() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["const A = 3;", "const B = ~((1 << A) - 1);"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  static dartSuite() {
    _ut.group('NonErrorResolverTest', () {
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
      _ut.test('test_breakWithoutLabelInSwitch', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_breakWithoutLabelInSwitch);
      });
      _ut.test('test_builtInIdentifierAsType_dynamic', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_builtInIdentifierAsType_dynamic);
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
      _ut.test('test_constConstructorWithNonFinalField_constInstanceVar', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_constConstructorWithNonFinalField_constInstanceVar);
      });
      _ut.test('test_constConstructorWithNonFinalField_finalInstanceVar', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_constConstructorWithNonFinalField_finalInstanceVar);
      });
      _ut.test('test_constConstructorWithNonFinalField_static', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_constConstructorWithNonFinalField_static);
      });
      _ut.test('test_constConstructorWithNonFinalField_syntheticField', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_constConstructorWithNonFinalField_syntheticField);
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
      _ut.test('test_importOfNonLibrary_libraryDeclared', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_importOfNonLibrary_libraryDeclared);
      });
      _ut.test('test_importOfNonLibrary_libraryNotDeclared', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_importOfNonLibrary_libraryNotDeclared);
      });
      _ut.test('test_initializingFormalForNonExistantField', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_initializingFormalForNonExistantField);
      });
      _ut.test('test_invalidAssignment', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidAssignment);
      });
      _ut.test('test_invalidAssignment_toDynamic', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_invalidAssignment_toDynamic);
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
      _ut.test('test_newWithAbstractClass_factory', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_newWithAbstractClass_factory);
      });
      _ut.test('test_nonBoolExpression_assert_bool', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonBoolExpression_assert_bool);
      });
      _ut.test('test_nonBoolExpression_assert_functionType', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_nonBoolExpression_assert_functionType);
      });
      _ut.test('test_rethrowOutsideCatch', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_rethrowOutsideCatch);
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
      _ut.test('test_typeArgumentNotMatchingBounds_const', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_typeArgumentNotMatchingBounds_const);
      });
      _ut.test('test_typeArgumentNotMatchingBounds_new', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_typeArgumentNotMatchingBounds_new);
      });
      _ut.test('test_undefinedGetter_typeSubstitution', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_undefinedGetter_typeSubstitution);
      });
      _ut.test('test_undefinedIdentifier_hide', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_undefinedIdentifier_hide);
      });
      _ut.test('test_undefinedIdentifier_show', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_undefinedIdentifier_show);
      });
      _ut.test('test_undefinedOperator_tilde', () {
        final __test = new NonErrorResolverTest();
        runJUnitTest(__test, __test.test_undefinedOperator_tilde);
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
    List<Library> exports3 = _library5.exports;
    EngineTestCase.assertLength(1, exports3);
    JUnitTestCase.assertSame(exportLibrary, exports3[0]);
    _errorListener.assertNoErrors();
  }
  void test_addImport() {
    Library importLibrary = library("/imported.dart");
    _library5.addImport(ASTFactory.importDirective2("imported.dart", null, []), importLibrary);
    List<Library> imports3 = _library5.imports;
    EngineTestCase.assertLength(1, imports3);
    JUnitTestCase.assertSame(importLibrary, imports3[0]);
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
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.INACCESSIBLE_SETTER]);
    verify([source]);
  }
  void fail_inconsistentMethodInheritance() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE]);
    verify([source]);
  }
  void fail_nonTypeAsTypeArgument() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["int A;", "class B<E> {}", "f(B<A> b) {}"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT]);
    verify([source]);
  }
  void fail_redirectWithInvalidTypeParameters() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.REDIRECT_WITH_INVALID_TYPE_PARAMETERS]);
    verify([source]);
  }
  void fail_typeArgumentViolatesBounds() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.TYPE_ARGUMENT_VIOLATES_BOUNDS]);
    verify([source]);
  }
  void test_invalidAssignment_instanceVariable() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int x;", "}", "f() {", "  A a;", "  a.x = '0';", "}"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }
  void test_invalidAssignment_localVariable() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  int x;", "  x = '0';", "}"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }
  void test_invalidAssignment_staticVariable() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  static int x;", "}", "f() {", "  A.x = '0';", "}"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }
  void test_invocationOfNonFunction_class() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  void m() {", "    A();", "  }", "}"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION]);
  }
  void test_invocationOfNonFunction_localVariable() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  int x;", "  return x();", "}"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION]);
    verify([source]);
  }
  void test_invocationOfNonFunction_ordinaryInvocation() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int x;", "}", "class B {", "  m() {", "    A.x();", "  }", "}"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION]);
  }
  void test_invocationOfNonFunction_staticInvocation() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  static int get g => 0;", "  f() {", "    A.g();", "  }", "}"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION]);
  }
  void test_nonBoolCondition_conditional() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() { return 3 ? 2 : 1; }"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.NON_BOOL_CONDITION]);
    verify([source]);
  }
  void test_nonBoolCondition_do() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  do {} while (3);", "}"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.NON_BOOL_CONDITION]);
    verify([source]);
  }
  void test_nonBoolCondition_if() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  if (3) return 2; else return 1;", "}"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.NON_BOOL_CONDITION]);
    verify([source]);
  }
  void test_nonBoolCondition_while() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  while (3) {}", "}"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.NON_BOOL_CONDITION]);
    verify([source]);
  }
  void test_nonBoolExpression() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  assert(0);", "}"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.NON_BOOL_EXPRESSION]);
    verify([source]);
  }
  void test_returnOfInvalidType_function() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["int f() { return '0'; }"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }
  void test_returnOfInvalidType_localFunction() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  String m() {", "    int f() { return '0'; }", "  }", "}"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }
  void test_returnOfInvalidType_method() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int f() { return '0'; }", "}"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }
  void test_typeArgumentNotMatchingBounds_const() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "class B {}", "class G<E extends A> {", "  const G() {}", "}", "f() { return const G<B>(); }"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }
  void test_typeArgumentNotMatchingBounds_new() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "class B {}", "class G<E extends A> {}", "f() { return new G<B>(); }"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }
  void test_undefinedFunction() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["void f() {", "  g();", "}"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.UNDEFINED_FUNCTION]);
  }
  void test_undefinedGetter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class T {}", "f(T e) { return e.m; }"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.UNDEFINED_GETTER]);
  }
  void test_undefinedGetter_static() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "var a = A.B;"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.UNDEFINED_GETTER]);
  }
  void test_undefinedMethod() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  void m() {", "    n();", "  }", "}"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.UNDEFINED_METHOD]);
  }
  void test_undefinedSetter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class T {}", "f(T e1) { e1.m = 0; }"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.UNDEFINED_SETTER]);
  }
  void test_undefinedSetter_static() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "f() { A.B = 0;}"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.UNDEFINED_SETTER]);
  }
  void test_undefinedSuperMethod() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "class B extends A {", "  m() { return super.m(); }", "}"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.UNDEFINED_SUPER_METHOD]);
  }
  void test_wrongNumberOfTypeArguments_tooFew() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A<E, F> {}", "A<A> a = null;"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }
  void test_wrongNumberOfTypeArguments_tooMany() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A<E> {}", "A<A, A> a = null;"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }
  static dartSuite() {
    _ut.group('StaticTypeWarningCodeTest', () {
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
      _ut.test('test_returnOfInvalidType_function', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_returnOfInvalidType_function);
      });
      _ut.test('test_returnOfInvalidType_localFunction', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_returnOfInvalidType_localFunction);
      });
      _ut.test('test_returnOfInvalidType_method', () {
        final __test = new StaticTypeWarningCodeTest();
        runJUnitTest(__test, __test.test_returnOfInvalidType_method);
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
    JUnitTestCase.assertSame(_typeProvider.dynamicType, resolve5(node, []));
    _listener.assertNoErrors();
  }
  void fail_visitFieldFormalParameter_type() {
    FormalParameter node = ASTFactory.fieldFormalParameter(null, ASTFactory.typeName4("int", []), "p");
    JUnitTestCase.assertSame(_typeProvider.intType, resolve5(node, []));
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
    SimpleIdentifier exceptionParameter4 = clause.exceptionParameter;
    exceptionParameter4.element = new LocalVariableElementImpl(exceptionParameter4);
    resolve(clause, _typeProvider.objectType, null, []);
    _listener.assertNoErrors();
  }
  void test_visitCatchClause_exception_stackTrace() {
    CatchClause clause = ASTFactory.catchClause2("e", "s", []);
    SimpleIdentifier exceptionParameter5 = clause.exceptionParameter;
    exceptionParameter5.element = new LocalVariableElementImpl(exceptionParameter5);
    SimpleIdentifier stackTraceParameter4 = clause.stackTraceParameter;
    stackTraceParameter4.element = new LocalVariableElementImpl(stackTraceParameter4);
    resolve(clause, _typeProvider.objectType, _typeProvider.stackTraceType, []);
    _listener.assertNoErrors();
  }
  void test_visitCatchClause_on_exception() {
    ClassElement exceptionElement = ElementFactory.classElement2("E", []);
    TypeName exceptionType = ASTFactory.typeName(exceptionElement, []);
    CatchClause clause = ASTFactory.catchClause4(exceptionType, "e", []);
    SimpleIdentifier exceptionParameter6 = clause.exceptionParameter;
    exceptionParameter6.element = new LocalVariableElementImpl(exceptionParameter6);
    resolve(clause, exceptionElement.type, null, [exceptionElement]);
    _listener.assertNoErrors();
  }
  void test_visitCatchClause_on_exception_stackTrace() {
    ClassElement exceptionElement = ElementFactory.classElement2("E", []);
    TypeName exceptionType = ASTFactory.typeName(exceptionElement, []);
    ((exceptionType.name as SimpleIdentifier)).element = exceptionElement;
    CatchClause clause = ASTFactory.catchClause5(exceptionType, "e", "s", []);
    SimpleIdentifier exceptionParameter7 = clause.exceptionParameter;
    exceptionParameter7.element = new LocalVariableElementImpl(exceptionParameter7);
    SimpleIdentifier stackTraceParameter5 = clause.stackTraceParameter;
    stackTraceParameter5.element = new LocalVariableElementImpl(stackTraceParameter5);
    resolve(clause, exceptionElement.type, _typeProvider.stackTraceType, [exceptionElement]);
    _listener.assertNoErrors();
  }
  void test_visitClassDeclaration() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement2("B", []);
    ClassElement elementC = ElementFactory.classElement2("C", []);
    ClassElement elementD = ElementFactory.classElement2("D", []);
    ExtendsClause extendsClause2 = ASTFactory.extendsClause(ASTFactory.typeName(elementB, []));
    WithClause withClause2 = ASTFactory.withClause([ASTFactory.typeName(elementC, [])]);
    ImplementsClause implementsClause2 = ASTFactory.implementsClause([ASTFactory.typeName(elementD, [])]);
    ClassDeclaration declaration = ASTFactory.classDeclaration(null, "A", null, extendsClause2, withClause2, implementsClause2, []);
    declaration.name.element = elementA;
    resolveNode(declaration, [elementA, elementB, elementC, elementD]);
    JUnitTestCase.assertSame(elementB.type, elementA.supertype);
    List<InterfaceType> mixins4 = elementA.mixins;
    EngineTestCase.assertLength(1, mixins4);
    JUnitTestCase.assertSame(elementC.type, mixins4[0]);
    List<InterfaceType> interfaces5 = elementA.interfaces;
    EngineTestCase.assertLength(1, interfaces5);
    JUnitTestCase.assertSame(elementD.type, interfaces5[0]);
    _listener.assertNoErrors();
  }
  void test_visitClassTypeAlias() {
    ClassElement elementA = ElementFactory.classElement2("A", []);
    ClassElement elementB = ElementFactory.classElement2("B", []);
    ClassElement elementC = ElementFactory.classElement2("C", []);
    ClassElement elementD = ElementFactory.classElement2("D", []);
    WithClause withClause3 = ASTFactory.withClause([ASTFactory.typeName(elementC, [])]);
    ImplementsClause implementsClause3 = ASTFactory.implementsClause([ASTFactory.typeName(elementD, [])]);
    ClassTypeAlias alias = ASTFactory.classTypeAlias("A", null, null, ASTFactory.typeName(elementB, []), withClause3, implementsClause3);
    alias.name.element = elementA;
    resolveNode(alias, [elementA, elementB, elementC, elementD]);
    JUnitTestCase.assertSame(elementB.type, elementA.supertype);
    List<InterfaceType> mixins5 = elementA.mixins;
    EngineTestCase.assertLength(1, mixins5);
    JUnitTestCase.assertSame(elementC.type, mixins5[0]);
    List<InterfaceType> interfaces6 = elementA.interfaces;
    EngineTestCase.assertLength(1, interfaces6);
    JUnitTestCase.assertSame(elementD.type, interfaces6[0]);
    _listener.assertNoErrors();
  }
  void test_visitSimpleFormalParameter_noType() {
    FormalParameter node = ASTFactory.simpleFormalParameter3("p");
    node.identifier.element = new ParameterElementImpl(ASTFactory.identifier3("p"));
    JUnitTestCase.assertSame(_typeProvider.dynamicType, resolve5(node, []));
    _listener.assertNoErrors();
  }
  void test_visitSimpleFormalParameter_type() {
    InterfaceType intType10 = _typeProvider.intType;
    ClassElement intElement = intType10.element;
    FormalParameter node = ASTFactory.simpleFormalParameter4(ASTFactory.typeName(intElement, []), "p");
    SimpleIdentifier identifier20 = node.identifier;
    ParameterElementImpl element = new ParameterElementImpl(identifier20);
    identifier20.element = element;
    JUnitTestCase.assertSame(intType10, resolve5(node, [intElement]));
    _listener.assertNoErrors();
  }
  void test_visitTypeName_noParameters_noArguments() {
    ClassElement classA = ElementFactory.classElement2("A", []);
    TypeName typeName6 = ASTFactory.typeName(classA, []);
    typeName6.type = null;
    resolveNode(typeName6, [classA]);
    JUnitTestCase.assertSame(classA.type, typeName6.type);
    _listener.assertNoErrors();
  }
  void test_visitTypeName_parameters_arguments() {
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    ClassElement classB = ElementFactory.classElement2("B", []);
    TypeName typeName7 = ASTFactory.typeName(classA, [ASTFactory.typeName(classB, [])]);
    typeName7.type = null;
    resolveNode(typeName7, [classA, classB]);
    InterfaceType resultType = typeName7.type as InterfaceType;
    JUnitTestCase.assertSame(classA, resultType.element);
    List<Type2> resultArguments = resultType.typeArguments;
    EngineTestCase.assertLength(1, resultArguments);
    JUnitTestCase.assertSame(classB.type, resultArguments[0]);
    _listener.assertNoErrors();
  }
  void test_visitTypeName_parameters_noArguments() {
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    TypeName typeName8 = ASTFactory.typeName(classA, []);
    typeName8.type = null;
    resolveNode(typeName8, [classA]);
    InterfaceType resultType = typeName8.type as InterfaceType;
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
    SimpleIdentifier exceptionParameter8 = node.exceptionParameter;
    if (exceptionParameter8 != null) {
      JUnitTestCase.assertSame(exceptionType, exceptionParameter8.staticType);
    }
    SimpleIdentifier stackTraceParameter6 = node.stackTraceParameter;
    if (stackTraceParameter6 != null) {
      JUnitTestCase.assertSame(stackTraceType, stackTraceParameter6.staticType);
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
  Type2 resolve5(FormalParameter node, List<Element> definedElements) {
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
   * The source factory used to create {@link Source sources}.
   */
  SourceFactory _sourceFactory;
  /**
   * The error listener used during resolution.
   */
  GatheringErrorListener _errorListener;
  /**
   * The analysis context used to parse the compilation units being resolved.
   */
  AnalysisContextImpl _analysisContext;
  /**
   * Assert that the number of errors that have been gathered matches the number of errors that are
   * given and that they have the expected error codes. The order in which the errors were gathered
   * is ignored.
   * @param expectedErrorCodes the error codes of the errors that should have been gathered
   * @throws AssertionFailedError if a different number of errors have been gathered than were
   * expected
   */
  void assertErrors(List<ErrorCode> expectedErrorCodes) {
    _errorListener.assertErrors2(expectedErrorCodes);
  }
  void setUp() {
    _errorListener = new GatheringErrorListener();
    _analysisContext = AnalysisContextFactory.contextWithCore();
    _sourceFactory = _analysisContext.sourceFactory;
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
    ChangeSet changeSet = new ChangeSet();
    changeSet.added(source);
    _analysisContext.applyChanges(changeSet);
    return source;
  }
  /**
   * Assert that no errors have been gathered.
   * @throws AssertionFailedError if any errors have been gathered
   */
  void assertNoErrors() {
    _errorListener.assertNoErrors();
  }
  /**
   * Create a library element that represents a library named {@code "test"} containing a single
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
  GatheringErrorListener get errorListener => _errorListener;
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
   * Given a library and all of its parts, resolve the contents of the library and the contents of
   * the parts. This assumes that the sources for the library and its parts have already been added
   * to the content provider using the method {@link #addSource(String,String)}.
   * @param librarySource the source for the compilation unit that defines the library
   * @param unitSources the sources for the compilation units that are part of the library
   * @return the element representing the resolved library
   * @throws AnalysisException if the analysis could not be performed
   */
  LibraryElement resolve(Source librarySource, List<Source> unitSources) {
    LibraryResolver resolver = new LibraryResolver.con2(_analysisContext, _errorListener);
    return resolver.resolveLibrary(librarySource, true);
  }
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
class CompileTimeErrorCodeTest extends ResolverTestCase {
  void fail_ambiguousExport() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["library L;", "export 'lib1.dart';", "export 'lib2.dart';"]));
    addSource("/lib1.dart", EngineTestCase.createSource(["class N {}"]));
    addSource("/lib2.dart", EngineTestCase.createSource(["class N {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.AMBIGUOUS_EXPORT]);
    verify([source]);
  }
  void fail_ambiguousImport_function() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["library L;", "import 'lib1.dart';", "import 'lib2.dart';", "g() { return f(); }"]));
    addSource("/lib1.dart", EngineTestCase.createSource(["f() {}"]));
    addSource("/lib2.dart", EngineTestCase.createSource(["f() {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.AMBIGUOUS_IMPORT]);
    verify([source]);
  }
  void fail_ambiguousImport_typeAnnotation() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["library L;", "import 'lib1.dart';", "import 'lib2.dart';", "class A extends N {}"]));
    addSource("/lib1.dart", EngineTestCase.createSource(["class N {}"]));
    addSource("/lib2.dart", EngineTestCase.createSource(["class N {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.AMBIGUOUS_IMPORT]);
    verify([source]);
  }
  void fail_compileTimeConstantRaisesException() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.COMPILE_TIME_CONSTANT_RAISES_EXCEPTION]);
    verify([source]);
  }
  void fail_constWithNonConstantArgument() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class T {", "  T(a) {};", "}", "f(p) { return const T(p); }"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT]);
    verify([source]);
  }
  void fail_constWithNonType() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["int A;", "f() {", "  return const A();", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.CONST_WITH_NON_TYPE]);
    verify([source]);
  }
  void fail_constWithTypeParameters() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS]);
    verify([source]);
  }
  void fail_constWithUndefinedConstructor() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  A(x) {}", "}", "f() {", "  return const A(0);", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR]);
    verify([source]);
  }
  void fail_duplicateDefinition() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  int m = 0;", "  m(a) {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }
  void fail_duplicateMemberName() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int x = 0;", "  int x() {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.DUPLICATE_MEMBER_NAME]);
    verify([source]);
  }
  void fail_duplicateMemberNameInstanceStatic() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int x;", "  static int x;", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.DUPLICATE_MEMBER_NAME_INSTANCE_STATIC]);
    verify([source]);
  }
  void fail_duplicateNamedArgument() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f({a, a}) {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT]);
    verify([source]);
  }
  void fail_extendsOrImplementsDisallowedClass_extends_null() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A extends Null {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
    verify([source]);
  }
  void fail_extendsOrImplementsDisallowedClass_implements_null() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A implements Null {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }
  void fail_finalNotInitialized_inConstructor() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  final int x;", "  A() {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }
  void fail_getterAndMethodWithSameName() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  get x -> 0;", "  x(y) {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.GETTER_AND_METHOD_WITH_SAME_NAME]);
    verify([source]);
  }
  void fail_importDuplicatedLibraryName() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["library test;", "import 'lib1.dart';", "import 'lib2.dart';"]));
    addSource("/lib1.dart", EngineTestCase.createSource(["library lib;"]));
    addSource("/lib2.dart", EngineTestCase.createSource(["library lib;"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.IMPORT_DUPLICATED_LIBRARY_NAME]);
    verify([source]);
  }
  void fail_inconsistentCaseExpressionTypes() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f(var p) {", "  switch (p) {", "    case 3:", "      break;", "    case 'a':", "      break;", "  }", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INCONSITENT_CASE_EXPRESSION_TYPES]);
    verify([source]);
  }
  void fail_initializerForNonExistant_initializer() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  A() : x = 0 {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTANT_FIELD]);
    verify([source]);
  }
  void fail_initializerForStaticField() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  static x;", "  A() : x = 0 {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD]);
    verify([source]);
  }
  void fail_invalidConstructorName() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME]);
    verify([source]);
  }
  void fail_invalidFactoryNameNotAClass() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS]);
    verify([source]);
  }
  void fail_invalidOverrideDefaultValue() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  m([a = 0]) {}", "}", "class B extends A {", "  m([a = 1]) {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INVALID_OVERRIDE_DEFAULT_VALUE]);
    verify([source]);
  }
  void fail_invalidOverrideNamed() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  m({a, b}) {}", "}", "class B extends A {", "  m({a}) {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INVALID_OVERRIDE_NAMED]);
    verify([source]);
  }
  void fail_invalidOverridePositional() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  m([a, b]) {}", "}", "class B extends A {", "  m([a]) {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INVALID_OVERRIDE_POSITIONAL]);
    verify([source]);
  }
  void fail_invalidOverrideRequired() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  m(a) {}", "}", "class B extends A {", "  m(a, b) {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INVALID_OVERRIDE_REQUIRED]);
    verify([source]);
  }
  void fail_invalidReferenceToThis_staticMethod() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  static m() { return this; }", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }
  void fail_invalidReferenceToThis_topLevelFunction() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() { return this; }"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }
  void fail_invalidReferenceToThis_variableInitializer() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["int x = this;"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }
  void fail_invalidTypeArgumentForKey() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  m() {", "    return const <int, int>{}", "  }", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_FOR_KEY]);
    verify([source]);
  }
  void fail_invalidTypeArgumentInConstList() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A<E> {", "  m() {", "    return const <E>[]", "  }", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_LIST]);
    verify([source]);
  }
  void fail_invalidTypeArgumentInConstMap() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A<E> {", "  m() {", "    return const <String, E>{}", "  }", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP]);
    verify([source]);
  }
  void fail_memberWithClassName() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int A = 0;", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
    verify([source]);
  }
  void fail_mixinDeclaresConstructor() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  A() {}", "}", "class B extends Object mixin A {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR]);
    verify([source]);
  }
  void fail_mixinInheritsFromNotObject() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "class B extends A {}", "class C extends Object mixin B {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT]);
    verify([source]);
  }
  void fail_mixinOfNonClass() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["var A;", "class B extends Object mixin A {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.MIXIN_OF_NON_CLASS]);
    verify([source]);
  }
  void fail_mixinOfNonMixin() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.MIXIN_OF_NON_MIXIN]);
    verify([source]);
  }
  void fail_mixinReferencesSuper() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  toString() -> super.toString();", "}", "class B extends Object mixin A {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.MIXIN_REFERENCES_SUPER]);
    verify([source]);
  }
  void fail_mixinWithNonClassSuperclass() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["int A;", "class B extends Object mixin A {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS]);
    verify([source]);
  }
  void fail_multipleSuperInitializers() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "class B extends A {", "  B() : super(), super() {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.MULTIPLE_SUPER_INITIALIZERS]);
    verify([source]);
  }
  void fail_nonConstantDefaultValue_named() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f({x : 2 + 3}) {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }
  void fail_nonConstantDefaultValue_positional() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f([x = 2 + 3]) {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }
  void fail_nonConstMapAsExpressionStatement() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  {'a' : 0, 'b' : 1};", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT]);
    verify([source]);
  }
  void fail_nonConstMapKey() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f(a) {", "  return const {a : 0};", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_MAP_KEY]);
    verify([source]);
  }
  void fail_nonConstValueInInitializer() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  static C;", "  int a;", "  A() : a = C {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER]);
    verify([source]);
  }
  void fail_objectCannotExtendAnotherClass() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.OBJECT_CANNOT_EXTEND_ANOTHER_CLASS]);
    verify([source]);
  }
  void fail_optionalParameterInOperator() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  operator +([p]) {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR]);
    verify([source]);
  }
  void fail_overrideMissingNamedParameters() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  m(a, {b}) {}", "}", "class B extends A {", "  m(a) {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.OVERRIDE_MISSING_NAMED_PARAMETERS]);
    verify([source]);
  }
  void fail_overrideMissingRequiredParameters() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  m(a) {}", "}", "class B extends A {", "  m(a, b) {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.OVERRIDE_MISSING_REQUIRED_PARAMETERS]);
    verify([source]);
  }
  void fail_prefixCollidesWithTopLevelMembers() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["import 'dart:uri' as uri;", "var uri = null;"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER]);
    verify([source]);
  }
  void fail_privateOptionalParameter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f({_p : 0}) {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER]);
    verify([source]);
  }
  void fail_recursiveCompileTimeConstant() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["const x = y + 1;", "const y = x + 1;"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT]);
    verify([source]);
  }
  void fail_recursiveFactoryRedirect() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT]);
    verify([source]);
  }
  void fail_recursiveFunctionTypeAlias_direct() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["typedef F(F f);"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.RECURSIVE_FUNCTION_TYPE_ALIAS]);
    verify([source]);
  }
  void fail_recursiveFunctionTypeAlias_indirect() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["typedef F(G g);", "typedef G(F f);"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.RECURSIVE_FUNCTION_TYPE_ALIAS]);
    verify([source]);
  }
  void fail_recursiveInterfaceInheritance_direct() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A implements A {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }
  void fail_recursiveInterfaceInheritance_indirect() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A implements B {}", "class B implements A {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }
  void fail_redirectToNonConstConstructor() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.REDIRECT_TO_NON_CONST_CONSTRUCTOR]);
    verify([source]);
  }
  void fail_referenceToDeclaredVariableInInitializer_getter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  int x = x + 1;", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.REFERENCE_TO_DECLARED_VARIABLE_IN_INITIALIZER]);
    verify([source]);
  }
  void fail_referenceToDeclaredVariableInInitializer_setter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  int x = x++;", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.REFERENCE_TO_DECLARED_VARIABLE_IN_INITIALIZER]);
    verify([source]);
  }
  void fail_reservedWordAsIdentifier() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["int class = 2;"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.RESERVED_WORD_AS_IDENTIFIER]);
    verify([source]);
  }
  void fail_returnInGenerativeConstructor() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  A() { return 0; }", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR]);
    verify([source]);
  }
  void fail_staticTopLevelFunction_topLevel() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["static f() {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.STATIC_TOP_LEVEL_FUNCTION]);
    verify([source]);
  }
  void fail_staticTopLevelVariable() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["static int x;"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.STATIC_TOP_LEVEL_VARIABLE]);
    verify([source]);
  }
  void fail_superInInvalidContext_factoryConstructor() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    verify([source]);
  }
  void fail_superInInvalidContext_instanceVariableInitializer() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  var a;", "}", "class B extends A {", " var b = super.a;", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    verify([source]);
  }
  void fail_superInInvalidContext_staticMethod() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  static m() {}", "}", "class B extends A {", "  static n() { return super.m(); }", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    verify([source]);
  }
  void fail_superInInvalidContext_staticVariableInitializer() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  static a = 0;", "}", "class B extends A {", "  static b = super.a;", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    verify([source]);
  }
  void fail_superInInvalidContext_topLevelFunction() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  super.f();", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    verify([source]);
  }
  void fail_superInInvalidContext_variableInitializer() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["var v = super.v;"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    verify([source]);
  }
  void fail_superInitializerInObject() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.SUPER_INITIALIZER_IN_OBJECT]);
    verify([source]);
  }
  void fail_typeArgumentsForNonGenericClass_creation_const() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "f(p) {", "  return const A<int>();", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.TYPE_ARGUMENTS_FOR_NON_GENERIC_CLASS]);
    verify([source]);
  }
  void fail_typeArgumentsForNonGenericClass_creation_new() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "f(p) {", "  return new A<int>();", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.TYPE_ARGUMENTS_FOR_NON_GENERIC_CLASS]);
    verify([source]);
  }
  void fail_typeArgumentsForNonGenericClass_typeCast() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "f(p) {", "  return p as A<int>;", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.TYPE_ARGUMENTS_FOR_NON_GENERIC_CLASS]);
    verify([source]);
  }
  void fail_undefinedConstructorInInitializer() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER]);
    verify([source]);
  }
  void fail_uninitializedFinalField() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  final int i;", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.UNINITIALIZED_FINAL_FIELD]);
    verify([source]);
  }
  void fail_wrongNumberOfParametersForOperator() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  operator []=(i) {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR]);
    verify([source]);
  }
  void fail_wrongNumberOfParametersForSetter_tooFew() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["set x() {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }
  void fail_wrongNumberOfParametersForSetter_tooMany() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["set x(a, b) {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }
  void fail_wrongNumberOfTypeArguments_creation_const_tooFew() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "class C<K, V> {}", "f(p) {", "  return const C<A>();", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }
  void fail_wrongNumberOfTypeArguments_creation_const_tooMany() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "class C<E> {}", "f(p) {", "  return const C<A, A>();", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }
  void fail_wrongNumberOfTypeArguments_creation_new_tooFew() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "class C<K, V> {}", "f(p) {", "  return new C<A>();", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }
  void fail_wrongNumberOfTypeArguments_creation_new_tooMany() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "class C<E> {}", "f(p) {", "  return new C<A, A>();", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }
  void fail_wrongNumberOfTypeArguments_typeTest_tooFew() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "class C<K, V> {}", "f(p) {", "  return p is C<A>;", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }
  void fail_wrongNumberOfTypeArguments_typeTest_tooMany() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "class C<E> {}", "f(p) {", "  return p is C<A, A>;", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }
  void test_argumentDefinitionTestNonParameter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", " var v = 0;", " return ?v;", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.ARGUMENT_DEFINITION_TEST_NON_PARAMETER]);
    verify([source]);
  }
  void test_builtInIdentifierAsType() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  typedef x;", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, StaticWarningCode.UNDEFINED_CLASS]);
    verify([source]);
  }
  void test_builtInIdentifierAsTypedefName_classTypeAlias() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "class B {}", "typedef as = A with B;"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME]);
    verify([source]);
  }
  void test_builtInIdentifierAsTypedefName_functionTypeAlias() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["typedef bool as();"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME]);
    verify([source]);
  }
  void test_builtInIdentifierAsTypeName() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class as {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME]);
    verify([source]);
  }
  void test_builtInIdentifierAsTypeVariableName() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A<as> {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME]);
    verify([source]);
  }
  void test_caseExpressionTypeImplementsEquals() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class IntWrapper {", "  final int value;", "  const IntWrapper(this.value);", "  bool operator ==(IntWrapper x) {", "    return value == x.value;", "  }", "}", "", "f(IntWrapper a) {", "  switch(a) {", "    case(const IntWrapper(1)) : return 1;", "    default: return 0;", "  }", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }
  void test_conflictingConstructorNameAndMember_field() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int x;", "  A.x() {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD]);
    verify([source]);
  }
  void test_conflictingConstructorNameAndMember_method() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  const A.x() {}", "  void x() {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD]);
    verify([source]);
  }
  void test_constConstructorWithNonFinalField() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int x;", "  const A() {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD]);
    verify([source]);
  }
  void test_constEvalThrowsException() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class C {", "  const C() { throw null; }", "}", "f() { return const C(); }"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
    verify([source]);
  }
  void test_constFormalParameter_fieldFormalParameter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  var x;", "  A(const this.x) {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.CONST_FORMAL_PARAMETER]);
    verify([source]);
  }
  void test_constFormalParameter_simpleFormalParameter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f(const x) {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.CONST_FORMAL_PARAMETER]);
    verify([source]);
  }
  void test_constInitializedWithNonConstValue() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f(p) {", "  const C = p;", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
    verify([source]);
  }
  void test_constWithInvalidTypeParameters() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  const A() {}", "}", "f() { return const A<A>(); }"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS]);
    verify([source]);
  }
  void test_constWithNonConst() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class T {", "  T(a, b, {c, d}) {}", "}", "f() { return const T(0, 1, c: 2, d: 3); }"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.CONST_WITH_NON_CONST]);
    verify([source]);
  }
  void test_defaultValueInFunctionTypeAlias() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["typedef F([x = 0]);"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS]);
    verify([source]);
  }
  void test_duplicateMemberError() {
    Source librarySource = addSource("/lib.dart", EngineTestCase.createSource(["library lib;", "", "part 'a.dart';", "part 'b.dart';"]));
    Source sourceA = addSource("/a.dart", EngineTestCase.createSource(["part of lib;", "", "class A {}"]));
    Source sourceB = addSource("/b.dart", EngineTestCase.createSource(["part of lib;", "", "class A {}"]));
    resolve(librarySource, [sourceA, sourceB]);
    assertErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([librarySource, sourceA, sourceB]);
  }
  void test_exportOfNonLibrary() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["library L;", "export 'lib1.dart';"]));
    addSource("/lib1.dart", EngineTestCase.createSource(["part of lib;"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY]);
    verify([source]);
  }
  void test_extendsNonClass_class() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["int A;", "class B extends A {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.EXTENDS_NON_CLASS]);
    verify([source]);
  }
  void test_extendsOrImplementsDisallowedClass_extends_bool() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A extends bool {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
    verify([source]);
  }
  void test_extendsOrImplementsDisallowedClass_extends_double() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A extends double {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
    verify([source]);
  }
  void test_extendsOrImplementsDisallowedClass_extends_int() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A extends int {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
    verify([source]);
  }
  void test_extendsOrImplementsDisallowedClass_extends_num() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A extends num {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
    verify([source]);
  }
  void test_extendsOrImplementsDisallowedClass_extends_String() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A extends String {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
    verify([source]);
  }
  void test_extendsOrImplementsDisallowedClass_implements_bool() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A implements bool {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }
  void test_extendsOrImplementsDisallowedClass_implements_double() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A implements double {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }
  void test_extendsOrImplementsDisallowedClass_implements_int() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A implements int {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }
  void test_extendsOrImplementsDisallowedClass_implements_num() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A implements num {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }
  void test_extendsOrImplementsDisallowedClass_implements_String() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A implements String {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }
  void test_fieldInitializedByMultipleInitializers() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int x;", "  A() : x = 0, x = 1 {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS]);
    verify([source]);
  }
  void test_fieldInitializedByMultipleInitializers_multipleInits() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int x;", "  A() : x = 0, x = 1, x = 2 {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS, CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS]);
    verify([source]);
  }
  void test_fieldInitializedByMultipleInitializers_multipleNames() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int x;", "  int y;", "  A() : x = 0, x = 1, y = 0, y = 1 {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS, CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS]);
    verify([source]);
  }
  void test_fieldInitializedInInitializerAndDeclaration_const() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  const int x = 0;", "  A() : x = 1 {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION]);
    verify([source]);
  }
  void test_fieldInitializedInInitializerAndDeclaration_final() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  final int x = 0;", "  A() : x = 1 {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION]);
    verify([source]);
  }
  void test_fieldInitializedInParameterAndInitializer() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int x;", "  A(this.x) : x = 1 {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER]);
    verify([source]);
  }
  void test_fieldInitializerOutsideConstructor() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int x;", "  m(this.x) {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR]);
    verify([source]);
  }
  void test_fieldInitializerOutsideConstructor_defaultParameter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int x;", "  m([this.x]) {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR]);
    verify([source]);
  }
  /**
   * This test doesn't test the FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR code, but tests the
   * FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION code instead. It is provided here to show
   * coverage over all of the permutations of initializers in constructor declarations.
   * <p>
   * Note: FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION covers a subset of
   * FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR, since it more specific, we use it instead of
   * the broader code
   */
  void test_finalInitializedInDeclarationAndConstructor_initializers() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  final x = 0;", "  A() : x = 0 {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION]);
    verify([source]);
  }
  void test_finalInitializedInDeclarationAndConstructor_initializingFormal() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  final x = 0;", "  A(this.x) {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR]);
    verify([source]);
  }
  void test_finalInitializedMultipleTimes_initializers() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  final x;", "  A() : x = 0, x = 0 {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS]);
    verify([source]);
  }
  /**
   * This test doesn't test the FINAL_INITIALIZED_MULTIPLE_TIMES code, but tests the
   * FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER code instead. It is provided here to show
   * coverage over all of the permutations of initializers in constructor declarations.
   * <p>
   * Note: FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER covers a subset of
   * FINAL_INITIALIZED_MULTIPLE_TIMES, since it more specific, we use it instead of the broader code
   */
  void test_finalInitializedMultipleTimes_initializingFormal_initializer() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  final x;", "  A(this.x) : x = 0 {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER]);
    verify([source]);
  }
  void test_finalInitializedMultipleTimes_initializingFormals() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  final x;", "  A(this.x, this.x) {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FINAL_INITIALIZED_MULTIPLE_TIMES]);
    verify([source]);
  }
  void test_finalNotInitialized_instanceField_const() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  const F;", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }
  void test_finalNotInitialized_instanceField_const_static() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  static const F;", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }
  void test_finalNotInitialized_instanceField_final() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  final F;", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }
  void test_finalNotInitialized_instanceField_final_static() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  static final F;", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }
  void test_finalNotInitialized_library_const() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["const F;"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }
  void test_finalNotInitialized_library_final() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["final F;"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }
  void test_finalNotInitialized_local_const() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  const int x;", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }
  void test_finalNotInitialized_local_final() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  final int x;", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.FINAL_NOT_INITIALIZED]);
    verify([source]);
  }
  void test_implementsDynamic() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A implements dynamic {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_DYNAMIC]);
    verify([source]);
  }
  void test_implementsNonClass_class() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["int A;", "class B implements A {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_NON_CLASS]);
    verify([source]);
  }
  void test_implementsNonClass_typedef() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "int B;", "typedef C = A implements B;"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_NON_CLASS]);
    verify([source]);
  }
  void test_implementsRepeated() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "class B implements A, A {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_REPEATED]);
    verify([source]);
  }
  void test_implementsRepeated_3times() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {} class C{}", "class B implements A, A, A, A {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_REPEATED, CompileTimeErrorCode.IMPLEMENTS_REPEATED, CompileTimeErrorCode.IMPLEMENTS_REPEATED]);
    verify([source]);
  }
  void test_implementsSelf() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A implements A {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.IMPLEMENTS_SELF]);
    verify([source]);
  }
  void test_importOfNonLibrary() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["library lib;", "import 'part.dart';"]));
    addSource("/part.dart", EngineTestCase.createSource(["part of lib;"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY]);
    verify([source]);
  }
  void test_initializingFormalForNonExistantField() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  A(this.x) {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTANT_FIELD]);
    verify([source]);
  }
  void test_initializingFormalForNonExistantField_notInEnclosingClass() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "int x;", "}", "class B extends A {", "  B(this.x) {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTANT_FIELD]);
    verify([source]);
  }
  void test_initializingFormalForNonExistantField_optional() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  A([this.x]) {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTANT_FIELD]);
    verify([source]);
  }
  void test_initializingFormalForNonExistantField_static() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  static x;", "  A([this.x]) {}", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_STATIC_FIELD]);
    verify([source]);
  }
  void test_invalidUri_export() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["library L;", "export 'unknown.dart';"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INVALID_URI]);
  }
  void test_invalidUri_import() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["library L;", "import 'unknown.dart';"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INVALID_URI]);
  }
  void test_invalidUri_part() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["library L;", "part 'unknown.dart';"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.INVALID_URI]);
  }
  void test_labelInOuterScope() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class int {}", "", "class A {", "  void m(int i) {", "    l: while (i > 0) {", "      void f() {", "        break l;", "      };", "    }", "  }", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.LABEL_IN_OUTER_SCOPE, StaticWarningCode.UNDEFINED_OPERATOR]);
  }
  void test_labelUndefined_break() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  x: while (true) {", "    break y;", "  }", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.LABEL_UNDEFINED]);
  }
  void test_labelUndefined_continue() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  x: while (true) {", "    continue y;", "  }", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.LABEL_UNDEFINED]);
  }
  void test_mixinOfNonClass_class() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["int A;", "class B with A {}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.MIXIN_OF_NON_CLASS]);
    verify([source]);
  }
  void test_mixinOfNonClass_typedef() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "int B;", "typedef C = A with B;"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.MIXIN_OF_NON_CLASS]);
    verify([source]);
  }
  void test_nativeFunctionBodyInNonSDKCode_function() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["int m(a) native 'string';"]));
    resolve(source, []);
    assertErrors([ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE]);
    verify([source]);
  }
  void test_nativeFunctionBodyInNonSDKCode_method() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A{", "  static int m(a) native 'string';", "}"]));
    resolve(source, []);
    assertErrors([ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE]);
    verify([source]);
  }
  void test_newWithInvalidTypeParameters() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}", "f() { return new A<A>(); }"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.NEW_WITH_INVALID_TYPE_PARAMETERS]);
    verify([source]);
  }
  void test_nonConstCaseExpression() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f(int p, int q) {", "  switch (p) {", "    case 3 + q:", "      break;", "  }", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION]);
    verify([source]);
  }
  void test_nonConstListElement() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f(a) {", "  return const [a];", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT]);
    verify([source]);
  }
  void test_nonConstMapValue() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f(a) {", "  return const {'a' : a};", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE]);
    verify([source]);
  }
  void test_partOfNonPart() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["library l1;", "part 'l2.dart';"]));
    addSource("/l2.dart", EngineTestCase.createSource(["library l2;"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.PART_OF_NON_PART]);
    verify([source]);
  }
  void test_rethrowOutsideCatch() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  rethrow;", "}"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.RETHROW_OUTSIDE_CATCH]);
    verify([source]);
  }
  void test_uriWithInterpolation_constant() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["import 'stuff_\$platform.dart';"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.URI_WITH_INTERPOLATION, StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }
  void test_uriWithInterpolation_nonConstant() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["library lib;", "part '\${'a'}.dart';"]));
    resolve(source, []);
    assertErrors([CompileTimeErrorCode.URI_WITH_INTERPOLATION]);
  }
  static dartSuite() {
    _ut.group('CompileTimeErrorCodeTest', () {
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
      _ut.test('test_constConstructorWithNonFinalField', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constConstructorWithNonFinalField);
      });
      _ut.test('test_constEvalThrowsException', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constEvalThrowsException);
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
      _ut.test('test_constWithInvalidTypeParameters', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constWithInvalidTypeParameters);
      });
      _ut.test('test_constWithNonConst', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_constWithNonConst);
      });
      _ut.test('test_defaultValueInFunctionTypeAlias', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_defaultValueInFunctionTypeAlias);
      });
      _ut.test('test_duplicateMemberError', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_duplicateMemberError);
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
      _ut.test('test_fieldInitializedInInitializerAndDeclaration_const', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_fieldInitializedInInitializerAndDeclaration_const);
      });
      _ut.test('test_fieldInitializedInInitializerAndDeclaration_final', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_fieldInitializedInInitializerAndDeclaration_final);
      });
      _ut.test('test_fieldInitializedInParameterAndInitializer', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_fieldInitializedInParameterAndInitializer);
      });
      _ut.test('test_fieldInitializerOutsideConstructor', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_fieldInitializerOutsideConstructor);
      });
      _ut.test('test_fieldInitializerOutsideConstructor_defaultParameter', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_fieldInitializerOutsideConstructor_defaultParameter);
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
      _ut.test('test_finalNotInitialized_instanceField_const', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_finalNotInitialized_instanceField_const);
      });
      _ut.test('test_finalNotInitialized_instanceField_const_static', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_finalNotInitialized_instanceField_const_static);
      });
      _ut.test('test_finalNotInitialized_instanceField_final', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_finalNotInitialized_instanceField_final);
      });
      _ut.test('test_finalNotInitialized_instanceField_final_static', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_finalNotInitialized_instanceField_final_static);
      });
      _ut.test('test_finalNotInitialized_library_const', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_finalNotInitialized_library_const);
      });
      _ut.test('test_finalNotInitialized_library_final', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_finalNotInitialized_library_final);
      });
      _ut.test('test_finalNotInitialized_local_const', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_finalNotInitialized_local_const);
      });
      _ut.test('test_finalNotInitialized_local_final', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_finalNotInitialized_local_final);
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
      _ut.test('test_implementsSelf', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_implementsSelf);
      });
      _ut.test('test_importOfNonLibrary', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_importOfNonLibrary);
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
      _ut.test('test_mixinOfNonClass_class', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_mixinOfNonClass_class);
      });
      _ut.test('test_mixinOfNonClass_typedef', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_mixinOfNonClass_typedef);
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
      _ut.test('test_nonConstMapValue', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_nonConstMapValue);
      });
      _ut.test('test_partOfNonPart', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_partOfNonPart);
      });
      _ut.test('test_rethrowOutsideCatch', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_rethrowOutsideCatch);
      });
      _ut.test('test_uriWithInterpolation_constant', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_uriWithInterpolation_constant);
      });
      _ut.test('test_uriWithInterpolation_nonConstant', () {
        final __test = new CompileTimeErrorCodeTest();
        runJUnitTest(__test, __test.test_uriWithInterpolation_nonConstant);
      });
    });
  }
}
/**
 * Instances of the class {@code StaticTypeVerifier} verify that all of the nodes in an AST
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
   * Initialize a newly created verifier to verify that all of the nodes in an AST structure that
   * should have a static type associated with them do have a static type.
   */
  StaticTypeVerifier() : super() {
  }
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
      writer.printlnObject(" TypeNames.");
      if (unresolvedTypeCount > 0) {
        writer.printlnObject("TypeNames:");
        for (TypeName identifier in _unresolvedTypes) {
          writer.print("  ");
          writer.print(identifier.toString());
          writer.print(" (");
          writer.print(getFileName(identifier));
          writer.print(" : ");
          writer.print(identifier.offset);
          writer.printlnObject(")");
        }
      }
      if (unresolvedExpressionCount > 0) {
        writer.printlnObject("Expressions:");
        for (Expression identifier in _unresolvedExpressions) {
          writer.print("  ");
          writer.print(identifier.toString());
          writer.print(" (");
          writer.print(getFileName(identifier));
          writer.print(" : ");
          writer.print(identifier.offset);
          writer.printlnObject(")");
        }
      }
      JUnitTestCase.fail(writer.toString());
    }
  }
  Object visitCommentReference(CommentReference node) => null;
  Object visitExpression(Expression node) {
    node.visitChildren(this);
    if (node.staticType == null) {
      _unresolvedExpressions.add(node);
    } else {
      _resolvedExpressionCount++;
    }
    return null;
  }
  Object visitLibraryIdentifier(LibraryIdentifier node) => null;
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.staticType == null && identical(node.prefix.staticType, DynamicTypeImpl.instance)) {
      return null;
    }
    return super.visitPrefixedIdentifier(node);
  }
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    ASTNode parent20 = node.parent;
    if (parent20 is MethodInvocation && identical(node, ((parent20 as MethodInvocation)).methodName)) {
      return null;
    } else if (parent20 is RedirectingConstructorInvocation && identical(node, ((parent20 as RedirectingConstructorInvocation)).constructorName)) {
      return null;
    } else if (parent20 is SuperConstructorInvocation && identical(node, ((parent20 as SuperConstructorInvocation)).constructorName)) {
      return null;
    } else if (parent20 is ConstructorName && identical(node, ((parent20 as ConstructorName)).name)) {
      return null;
    } else if (parent20 is Label && identical(node, ((parent20 as Label)).label)) {
      return null;
    } else if (parent20 is ImportDirective && identical(node, ((parent20 as ImportDirective)).prefix)) {
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
      ASTNode root3 = node.root;
      if (root3 is CompilationUnit) {
        CompilationUnit rootCU = (root3 as CompilationUnit);
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
  void test_visitAssignmentExpression_compound() {
    InterfaceType intType3 = _typeProvider.intType;
    SimpleIdentifier leftHandSide = ASTFactory.identifier3("a");
    leftHandSide.staticType = intType3;
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
    InterfaceType numType2 = _typeProvider.numType;
    SimpleIdentifier left = ASTFactory.identifier3("i");
    left.staticType = numType2;
    BinaryExpression expression = ASTFactory.binaryExpression(left, TokenType.PLUS, ASTFactory.identifier3("j"));
    resolveNode(expression, []);
    JUnitTestCase.assertEquals(getMethod(numType2, "+"), expression.element);
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
    ConstructorElement constructor = ElementFactory.constructorElement(constructorName);
    classA.constructors = <ConstructorElement> [constructor];
    ConstructorName name = ASTFactory.constructorName(ASTFactory.typeName(classA, []), constructorName);
    resolveNode(name, []);
    JUnitTestCase.assertSame(constructor, name.element);
    _listener.assertNoErrors();
  }
  void test_visitConstructorName_unnamed() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String constructorName = null;
    ConstructorElement constructor = ElementFactory.constructorElement(constructorName);
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
    JUnitTestCase.assertSame(labelElement, resolve2(statement, labelElement));
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
    InterfaceType intType4 = _typeProvider.intType;
    MethodElement getter = ElementFactory.methodElement("[]", intType4, [intType4]);
    classA.methods = <MethodElement> [getter];
    SimpleIdentifier array = ASTFactory.identifier3("a");
    array.staticType = classA.type;
    IndexExpression expression = ASTFactory.indexExpression(array, ASTFactory.identifier3("i"));
    JUnitTestCase.assertSame(getter, resolve4(expression, []));
    _listener.assertNoErrors();
  }
  void test_visitIndexExpression_set() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    InterfaceType intType5 = _typeProvider.intType;
    MethodElement setter = ElementFactory.methodElement("[]=", intType5, [intType5]);
    classA.methods = <MethodElement> [setter];
    SimpleIdentifier array = ASTFactory.identifier3("a");
    array.staticType = classA.type;
    IndexExpression expression = ASTFactory.indexExpression(array, ASTFactory.identifier3("i"));
    ASTFactory.assignmentExpression(expression, TokenType.EQ, ASTFactory.integer(0));
    JUnitTestCase.assertSame(setter, resolve4(expression, []));
    _listener.assertNoErrors();
  }
  void test_visitInstanceCreationExpression_named() {
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String constructorName = "a";
    ConstructorElement constructor = ElementFactory.constructorElement(constructorName);
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
    ConstructorElement constructor = ElementFactory.constructorElement(constructorName);
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
    ConstructorElementImpl constructor = ElementFactory.constructorElement(constructorName);
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
    InterfaceType numType3 = _typeProvider.numType;
    SimpleIdentifier left = ASTFactory.identifier3("i");
    left.staticType = numType3;
    String methodName = "abs";
    MethodInvocation invocation = ASTFactory.methodInvocation(left, methodName, []);
    resolveNode(invocation, []);
    JUnitTestCase.assertSame(getMethod(numType3, methodName), invocation.methodName.element);
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
    InterfaceType numType4 = _typeProvider.numType;
    SimpleIdentifier operand = ASTFactory.identifier3("i");
    operand.staticType = numType4;
    PostfixExpression expression = ASTFactory.postfixExpression(operand, TokenType.PLUS_PLUS);
    resolveNode(expression, []);
    JUnitTestCase.assertEquals(getMethod(numType4, "+"), expression.element);
    _listener.assertNoErrors();
  }
  void test_visitPrefixedIdentifier_dynamic() {
    Type2 dynamicType2 = _typeProvider.dynamicType;
    SimpleIdentifier target = ASTFactory.identifier3("a");
    VariableElementImpl variable = ElementFactory.localVariableElement(target);
    variable.type = dynamicType2;
    target.element = variable;
    target.staticType = dynamicType2;
    PrefixedIdentifier identifier6 = ASTFactory.identifier(target, ASTFactory.identifier3("b"));
    resolveNode(identifier6, []);
    JUnitTestCase.assertNull(identifier6.element);
    JUnitTestCase.assertNull(identifier6.identifier.element);
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
    PrefixedIdentifier identifier7 = ASTFactory.identifier(target, ASTFactory.identifier3(getterName));
    resolveNode(identifier7, []);
    JUnitTestCase.assertSame(getter, identifier7.element);
    JUnitTestCase.assertSame(getter, identifier7.identifier.element);
    _listener.assertNoErrors();
  }
  void test_visitPrefixExpression() {
    InterfaceType numType5 = _typeProvider.numType;
    SimpleIdentifier operand = ASTFactory.identifier3("i");
    operand.staticType = numType5;
    PrefixExpression expression = ASTFactory.prefixExpression(TokenType.PLUS_PLUS, operand);
    resolveNode(expression, []);
    JUnitTestCase.assertEquals(getMethod(numType5, "+"), expression.element);
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
    target.staticType = classA.type;
    PropertyAccess access = ASTFactory.propertyAccess2(target, getterName);
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
    InterfaceType doubleType3 = _typeProvider.doubleType;
    String fieldName = "NAN";
    SimpleIdentifier node = ASTFactory.identifier3(fieldName);
    resolveInClass(node, doubleType3.element);
    JUnitTestCase.assertEquals(getGetter(doubleType3, fieldName), node.element);
    _listener.assertNoErrors();
  }
  void test_visitSimpleIdentifier_lexicalScope() {
    SimpleIdentifier node = ASTFactory.identifier3("i");
    VariableElementImpl element = ElementFactory.localVariableElement(node);
    JUnitTestCase.assertSame(element, resolve3(node, [element]));
    _listener.assertNoErrors();
  }
  void test_visitSimpleIdentifier_lexicalScope_field_setter() {
    InterfaceType intType6 = _typeProvider.intType;
    ClassElementImpl classA = ElementFactory.classElement2("A", []);
    String fieldName = "a";
    FieldElement field = ElementFactory.fieldElement(fieldName, false, false, false, intType6);
    classA.fields = <FieldElement> [field];
    classA.accessors = <PropertyAccessorElement> [field.getter, field.setter];
    SimpleIdentifier node = ASTFactory.identifier3(fieldName);
    ASTFactory.assignmentExpression(node, TokenType.EQ, ASTFactory.integer(0));
    resolveInClass(node, classA);
    Element element65 = node.element;
    EngineTestCase.assertInstanceOf(PropertyAccessorElement, element65);
    JUnitTestCase.assertTrue(((element65 as PropertyAccessorElement)).isSetter());
    _listener.assertNoErrors();
  }
  void test_visitSuperConstructorInvocation() {
    ClassElementImpl superclass = ElementFactory.classElement2("A", []);
    ConstructorElementImpl superConstructor = ElementFactory.constructorElement(null);
    superclass.constructors = <ConstructorElement> [superConstructor];
    ClassElementImpl subclass = ElementFactory.classElement("B", superclass.type, []);
    ConstructorElementImpl subConstructor = ElementFactory.constructorElement(null);
    subclass.constructors = <ConstructorElement> [subConstructor];
    SuperConstructorInvocation invocation = ASTFactory.superConstructorInvocation([]);
    resolveInClass(invocation, subclass);
    JUnitTestCase.assertEquals(superConstructor, invocation.element);
    _listener.assertNoErrors();
  }
  void test_visitSuperConstructorInvocation_namedParameter() {
    ClassElementImpl superclass = ElementFactory.classElement2("A", []);
    ConstructorElementImpl superConstructor = ElementFactory.constructorElement(null);
    String parameterName = "p";
    ParameterElement parameter = ElementFactory.namedParameter(parameterName);
    superConstructor.parameters = <ParameterElement> [parameter];
    superclass.constructors = <ConstructorElement> [superConstructor];
    ClassElementImpl subclass = ElementFactory.classElement("B", superclass.type, []);
    ConstructorElementImpl subConstructor = ElementFactory.constructorElement(null);
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
  Element resolve2(ContinueStatement statement, LabelElementImpl labelElement) {
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
  Element resolve3(Identifier node, List<Element> definedElements) {
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
  Element resolve4(IndexExpression node, List<Element> definedElements) {
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
    InterfaceType type30 = ElementFactory.classElement2("C", []).type;
    manager.enterScope();
    manager.setType(element, type30);
    manager.enterScope();
    JUnitTestCase.assertSame(type30, manager.getType(element));
  }
  void test_getType_immediateOverride() {
    TypeOverrideManager manager = new TypeOverrideManager();
    LocalVariableElementImpl element = ElementFactory.localVariableElement2("v");
    InterfaceType type31 = ElementFactory.classElement2("C", []).type;
    manager.enterScope();
    manager.setType(element, type31);
    JUnitTestCase.assertSame(type31, manager.getType(element));
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
class StaticWarningCodeTest extends ResolverTestCase {
  void fail_argumentTypeNotAssignable() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void fail_assignmentToFinal() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["final x = 0;", "f() { x = 1; }"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.ASSIGNMENT_TO_FINAL]);
    verify([source]);
  }
  void fail_caseBlockNotTerminated() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f(int p) {", "  switch (p) {", "    case 0:", "      f(p);", "    case 1:", "      break;", "  }", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.CASE_BLOCK_NOT_TERMINATED]);
    verify([source]);
  }
  void fail_castToNonType() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["var A = 0;", "f(String s) { var x = s as A; }"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.CAST_TO_NON_TYPE]);
    verify([source]);
  }
  void fail_commentReferenceConstructorNotVisible() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([StaticWarningCode.COMMENT_REFERENCE_CONSTRUCTOR_NOT_VISIBLE]);
    verify([source]);
  }
  void fail_commentReferenceIdentifierNotVisible() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([StaticWarningCode.COMMENT_REFERENCE_IDENTIFIER_NOT_VISIBLE]);
    verify([source]);
  }
  void fail_commentReferenceUndeclaredConstructor() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([StaticWarningCode.COMMENT_REFERENCE_UNDECLARED_CONSTRUCTOR]);
    verify([source]);
  }
  void fail_commentReferenceUndeclaredIdentifier() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([StaticWarningCode.COMMENT_REFERENCE_UNDECLARED_IDENTIFIER]);
    verify([source]);
  }
  void fail_commentReferenceUriNotLibrary() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([StaticWarningCode.COMMENT_REFERENCE_URI_NOT_LIBRARY]);
    verify([source]);
  }
  void fail_concreteClassWithAbstractMember() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  m();", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER]);
    verify([source]);
  }
  void fail_conflictingInstanceGetterAndSuperclassMember() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER]);
    verify([source]);
  }
  void fail_conflictingInstanceSetterAndSuperclassMember() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([StaticWarningCode.CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER]);
    verify([source]);
  }
  void fail_conflictingStaticGetterAndInstanceSetter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  static get x -> 0;", "  set x(int p) {}", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER]);
    verify([source]);
  }
  void fail_conflictingStaticSetterAndInstanceGetter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  get x -> 0;", "  static set x(int p) {}", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.CONFLICTING_STATIC_SETTER_AND_INSTANCE_GETTER]);
    verify([source]);
  }
  void fail_fieldInitializerWithInvalidType() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int x;", "  A(String this.x) {}", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.FIELD_INITIALIZER_WITH_INVALID_TYPE]);
    verify([source]);
  }
  void fail_incorrectNumberOfArguments_tooFew() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f(a, b) -> 0;", "g() {", "  f(2);", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.INCORRECT_NUMBER_OF_ARGUMENTS]);
    verify([source]);
  }
  void fail_incorrectNumberOfArguments_tooMany() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f(a, b) -> 0;", "g() {", "  f(2, 3, 4);", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.INCORRECT_NUMBER_OF_ARGUMENTS]);
    verify([source]);
  }
  void fail_instanceMethodNameCollidesWithSuperclassStatic() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  static n", "}", "class C extends A {", "  void n() {}", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC]);
    verify([source]);
  }
  void fail_invalidFactoryName() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([StaticWarningCode.INVALID_FACTORY_NAME]);
    verify([source]);
  }
  void fail_invalidOverrideGetterType() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int get g -> 0", "}", "class B extends A {", "  String get g { return 'a'; }", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.INVALID_OVERRIDE_GETTER_TYPE]);
    verify([source]);
  }
  void fail_invalidOverrideReturnType() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int m() { return 0; }", "}", "class B extends A {", "  String m() { return 'a'; }", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.INVALID_OVERRIDE_RETURN_TYPE]);
    verify([source]);
  }
  void fail_invalidOverrideSetterReturnType() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  void set s(int v) {}", "}", "class B extends A {", "  void set s(String v) {}", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.INVALID_OVERRIDE_SETTER_RETURN_TYPE]);
    verify([source]);
  }
  void fail_invocationOfNonFunction() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([StaticWarningCode.INVOCATION_OF_NON_FUNCTION]);
    verify([source]);
  }
  void fail_mismatchedGetterAndSetterTypes() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int get g { return 0; }", "  set g(String v) {}", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES]);
    verify([source]);
  }
  void fail_newWithNonType() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["var A = 0;", "void f() {", "  A a = new A();", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.NEW_WITH_NON_TYPE]);
    verify([source]);
  }
  void fail_newWithUndefinedConstructor() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  A(int p) {}", "}", "A f() {", "  return new A();", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR]);
    verify([source]);
  }
  void fail_nonAbstractClassInheritsAbstractMember() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class I {", "  m(p) {}", "}", "class C implements I {", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER]);
    verify([source]);
  }
  void fail_nonAbstractClassInheritsAbstractMethod() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["abstract class A {", "  m(p);", "}", "class C extends A {", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_METHOD]);
    verify([source]);
  }
  void fail_nonType() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["var A = 0;", "f(var p) {", "  if (p is A) {", "  }", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.NON_TYPE]);
    verify([source]);
  }
  void fail_nonTypeInCatchClause() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["var T = 0;", "f(var p) {", "  try {", "  } on T catch e {", "  }", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE]);
    verify([source]);
  }
  void fail_nonVoidReturnForOperator() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int operator []=() {}", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.NON_VOID_RETURN_FOR_OPERATOR]);
    verify([source]);
  }
  void fail_nonVoidReturnForSetter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["int set x(int v) {", "  var s = x;", "  x = v;", "  return s;", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.NON_VOID_RETURN_FOR_SETTER]);
    verify([source]);
  }
  void fail_overrideNotSubtype() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int m() {}", "}", "class B extends A {", "  String m() {}", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.OVERRIDE_NOT_SUBTYPE]);
    verify([source]);
  }
  void fail_overrideWithDifferentDefault() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  m([int p = 0]) {}", "}", "class B extends A {", "  m([int p = 1]) {}", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.OVERRIDE_WITH_DIFFERENT_DEFAULT]);
    verify([source]);
  }
  void fail_redirectToInvalidReturnType() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([StaticWarningCode.REDIRECT_TO_INVALID_RETURN_TYPE]);
    verify([source]);
  }
  void fail_redirectToMissingConstructor() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([StaticWarningCode.REDIRECT_TO_MISSING_CONSTRUCTOR]);
    verify([source]);
  }
  void fail_redirectToNonClass() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([StaticWarningCode.REDIRECT_TO_NON_CLASS]);
    verify([source]);
  }
  void fail_returnWithoutValue() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["int f() { return; }"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.RETURN_WITHOUT_VALUE]);
    verify([source]);
  }
  void fail_switchExpressionNotAssignable() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f(int p) {", "  switch (p) {", "    case 'a': break;", "  }", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.SWITCH_EXPRESSION_NOT_ASSIGNABLE]);
    verify([source]);
  }
  void fail_undefinedGetter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource([]));
    resolve(source, []);
    assertErrors([StaticWarningCode.UNDEFINED_GETTER]);
    verify([source]);
  }
  void fail_undefinedIdentifier_function() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["int a() -> b;"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.UNDEFINED_IDENTIFIER]);
    verify([source]);
  }
  void fail_undefinedSetter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class C {}", "f(var p) {", "  C.m = 0;", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.UNDEFINED_SETTER]);
    verify([source]);
  }
  void fail_undefinedStaticMethodOrGetter_getter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class C {}", "f(var p) {", "  f(C.m);", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.UNDEFINED_STATIC_METHOD_OR_GETTER]);
    verify([source]);
  }
  void fail_undefinedStaticMethodOrGetter_method() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class C {}", "f(var p) {", "  f(C.m());", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.UNDEFINED_STATIC_METHOD_OR_GETTER]);
    verify([source]);
  }
  void test_constWithAbstractClass() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["abstract class A {", "  const A() {}", "}", "void f() {", "  A a = const A();", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.CONST_WITH_ABSTRACT_CLASS]);
    verify([source]);
  }
  void test_equalKeysInMap() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["var m = {'a' : 0, 'b' : 1, 'a' : 2};"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.EQUAL_KEYS_IN_MAP]);
    verify([source]);
  }
  void test_newWithAbstractClass() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["abstract class A {}", "void f() {", "  A a = new A();", "}"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.NEW_WITH_ABSTRACT_CLASS]);
    verify([source]);
  }
  void test_partOfDifferentLibrary() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["library lib;", "part 'part.dart';"]));
    addSource("/part.dart", EngineTestCase.createSource(["part of lub;"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.PART_OF_DIFFERENT_LIBRARY]);
    verify([source]);
  }
  void test_undefinedClass_instanceCreation() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() { new C(); }"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.UNDEFINED_CLASS]);
  }
  void test_undefinedClass_variableDeclaration() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() { C c; }"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.UNDEFINED_CLASS]);
  }
  void test_undefinedIdentifier_initializer() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["var a = b;"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }
  void test_undefinedIdentifier_methodInvocation() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() { C.m(); }"]));
    resolve(source, []);
    assertErrors([StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }
  static dartSuite() {
    _ut.group('StaticWarningCodeTest', () {
      _ut.test('test_constWithAbstractClass', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_constWithAbstractClass);
      });
      _ut.test('test_equalKeysInMap', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_equalKeysInMap);
      });
      _ut.test('test_newWithAbstractClass', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_newWithAbstractClass);
      });
      _ut.test('test_partOfDifferentLibrary', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_partOfDifferentLibrary);
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
      _ut.test('test_undefinedIdentifier_methodInvocation', () {
        final __test = new StaticWarningCodeTest();
        runJUnitTest(__test, __test.test_undefinedIdentifier_methodInvocation);
      });
    });
  }
}
class ErrorResolverTest extends ResolverTestCase {
  void test_breakLabelOnSwitchMember() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  void m(int i) {", "    switch (i) {", "      l: case 0:", "        break;", "      case 1:", "        break l;", "    }", "  }", "}"]));
    resolve(source, []);
    assertErrors([ResolverErrorCode.BREAK_LABEL_ON_SWITCH_MEMBER]);
    verify([source]);
  }
  void test_continueLabelOnSwitch() {
    Source source = addSource("/a.dart", EngineTestCase.createSource(["class A {", "  void m(int i) {", "    l: switch (i) {", "      case 0:", "        continue l;", "    }", "  }", "}"]));
    resolve(source, []);
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
 * Instances of the class {@code TestTypeProvider} implement a type provider that can be used by
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
  /**
   * Initialize a newly created type provider to provide stand-ins for the types defined in the core
   * library.
   */
  TestTypeProvider() : super() {
  }
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
  InterfaceType get listType {
    if (_listType == null) {
      ClassElementImpl listElement = ElementFactory.classElement2("List", ["E"]);
      _listType = listElement.type;
      Type2 eType = listElement.typeVariables[0].type;
      listElement.accessors = <PropertyAccessorElement> [ElementFactory.getterElement("last", false, eType)];
      listElement.methods = <MethodElement> [ElementFactory.methodElement("[]", eType, [_intType]), ElementFactory.methodElement("[]=", VoidTypeImpl.instance, [_intType, eType])];
    }
    return _listType;
  }
  InterfaceType get mapType {
    if (_mapType == null) {
      _mapType = ElementFactory.classElement2("Map", ["K", "V"]).type;
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
        objectElement.methods = <MethodElement> [ElementFactory.methodElement("toString", stringType, []), ElementFactory.methodElement("==", _boolType, [_objectType])];
        objectElement.accessors = <PropertyAccessorElement> [ElementFactory.getterElement("hashCode", false, intType)];
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
      stringElement.accessors = <PropertyAccessorElement> [ElementFactory.getterElement("length", false, intType)];
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
}
/**
 * The class {@code AnalysisContextFactory} defines utility methods used to create analysis contexts
 * for testing purposes.
 */
class AnalysisContextFactory {
  /**
   * Create an analysis context that has a fake core library already resolved.
   * @return the analysis context that was created
   */
  static AnalysisContextImpl contextWithCore() {
    AnalysisContextImpl context = new AnalysisContextImpl();
    SourceFactory sourceFactory = new SourceFactory.con2([new DartUriResolver(DirectoryBasedDartSdk.defaultSdk), new FileUriResolver()]);
    context.sourceFactory = sourceFactory;
    TestTypeProvider provider = new TestTypeProvider();
    CompilationUnitElementImpl coreUnit = new CompilationUnitElementImpl("core.dart");
    Source coreSource = sourceFactory.forUri(DartSdk.DART_CORE);
    coreUnit.source = coreSource;
    coreUnit.types = <ClassElement> [provider.boolType.element, provider.doubleType.element, provider.functionType.element, provider.intType.element, provider.listType.element, provider.mapType.element, provider.numType.element, provider.objectType.element, provider.stackTraceType.element, provider.stringType.element, provider.typeType.element];
    LibraryElementImpl coreLibrary = new LibraryElementImpl(context, ASTFactory.libraryIdentifier2(["dart", "core"]));
    coreLibrary.definingCompilationUnit = coreUnit;
    CompilationUnitElementImpl htmlUnit = new CompilationUnitElementImpl("html_dartium.dart");
    Source htmlSource = sourceFactory.forUri(DartSdk.DART_HTML);
    htmlUnit.source = htmlSource;
    LibraryElementImpl htmlLibrary = new LibraryElementImpl(context, ASTFactory.libraryIdentifier2(["dart", "dom", "html"]));
    htmlLibrary.definingCompilationUnit = htmlUnit;
    Map<Source, LibraryElement> elementMap = new Map<Source, LibraryElement>();
    elementMap[coreSource] = coreLibrary;
    elementMap[htmlSource] = htmlLibrary;
    context.setContents(coreSource, "");
    context.setContents(htmlSource, "");
    context.recordLibraryElements(elementMap);
    return context;
  }
  /**
   * Prevent the creation of instances of this class.
   */
  AnalysisContextFactory() {
  }
}
class LibraryImportScopeTest extends ResolverTestCase {
  void test_conflictingImports() {
    AnalysisContext context = new AnalysisContextImpl();
    String typeNameA = "A";
    String typeNameB = "B";
    String typeNameC = "C";
    ClassElement typeA = new ClassElementImpl(ASTFactory.identifier3(typeNameA));
    ClassElement typeB1 = new ClassElementImpl(ASTFactory.identifier3(typeNameB));
    ClassElement typeB2 = new ClassElementImpl(ASTFactory.identifier3(typeNameB));
    ClassElement typeC = new ClassElementImpl(ASTFactory.identifier3(typeNameC));
    LibraryElement importedLibrary1 = createTestLibrary2(context, "imported1", []);
    ((importedLibrary1.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [typeA, typeB1];
    ImportElementImpl import1 = new ImportElementImpl();
    import1.importedLibrary = importedLibrary1;
    LibraryElement importedLibrary2 = createTestLibrary2(context, "imported2", []);
    ((importedLibrary2.definingCompilationUnit as CompilationUnitElementImpl)).types = <ClassElement> [typeB2, typeC];
    ImportElementImpl import2 = new ImportElementImpl();
    import2.importedLibrary = importedLibrary2;
    LibraryElementImpl importingLibrary = createTestLibrary2(context, "importing", []);
    importingLibrary.imports = <ImportElement> [import1, import2];
    GatheringErrorListener errorListener = new GatheringErrorListener();
    Scope scope = new LibraryImportScope(importingLibrary, errorListener);
    JUnitTestCase.assertEquals(typeA, scope.lookup3(typeNameA, importingLibrary));
    errorListener.assertNoErrors();
    JUnitTestCase.assertEquals(typeC, scope.lookup3(typeNameC, importingLibrary));
    errorListener.assertNoErrors();
    Element element = scope.lookup3(typeNameB, importingLibrary);
    errorListener.assertNoErrors();
    EngineTestCase.assertInstanceOf(MultiplyDefinedElement, element);
    List<Element> conflictingElements2 = ((element as MultiplyDefinedElement)).conflictingElements;
    JUnitTestCase.assertEquals(typeB1, conflictingElements2[0]);
    JUnitTestCase.assertEquals(typeB2, conflictingElements2[1]);
    JUnitTestCase.assertEquals(2, conflictingElements2.length);
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
    JUnitTestCase.assertEquals(importedType, scope.lookup3(importedTypeName, definingLibrary));
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
    });
  }
}
/**
 * Instances of the class {@code ResolutionVerifier} verify that all of the nodes in an AST
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
    _jtd_constructor_349_impl();
  }
  _jtd_constructor_349_impl() {
    _jtd_constructor_350_impl(null);
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
    _jtd_constructor_350_impl(knownExceptions2);
  }
  _jtd_constructor_350_impl(Set<ASTNode> knownExceptions2) {
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
        writer.printlnObject(" nodes:");
        printNodes(writer, _unresolvedNodes);
      }
      if (!_wrongTypedNodes.isEmpty) {
        writer.print("Resolved ");
        writer.print(_wrongTypedNodes.length);
        writer.printlnObject(" to the wrong type of element:");
        printNodes(writer, _wrongTypedNodes);
      }
      JUnitTestCase.fail(writer.toString());
    }
  }
  Object visitBinaryExpression(BinaryExpression node) {
    node.visitChildren(this);
    if (!node.operator.isUserDefinableOperator()) {
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
    SimpleIdentifier prefix9 = node.prefix;
    if (prefix9 == null) {
      return null;
    }
    return checkResolved2(prefix9, prefix9.element, PrefixElement);
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
    if (!node.operator.isUserDefinableOperator()) {
      return null;
    }
    return checkResolved2(node, node.element, MethodElement);
  }
  Object visitPrefixExpression(PrefixExpression node) {
    node.visitChildren(this);
    if (!node.operator.isUserDefinableOperator()) {
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
      ASTNode root2 = node.root;
      if (root2 is CompilationUnit) {
        CompilationUnit rootCU = (root2 as CompilationUnit);
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
      writer.printlnObject(")");
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
    JUnitTestCase.assertEquals(importedType, scope.lookup3(importedTypeName, definingLibrary));
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
    InterfaceType numType6 = _typeProvider.numType;
    SimpleIdentifier identifier = resolvedVariable(_typeProvider.intType, "i");
    AssignmentExpression node = ASTFactory.assignmentExpression(identifier, TokenType.PLUS_EQ, resolvedInteger(1));
    node.element = getMethod(numType6, "+");
    JUnitTestCase.assertSame(numType6, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitAssignmentExpression_simple() {
    InterfaceType intType7 = _typeProvider.intType;
    Expression node = ASTFactory.assignmentExpression(resolvedVariable(intType7, "i"), TokenType.EQ, resolvedInteger(0));
    JUnitTestCase.assertSame(intType7, analyze(node));
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
  void test_visitBinaryExpression_plus() {
    BinaryExpression node = ASTFactory.binaryExpression(resolvedInteger(2), TokenType.PLUS, resolvedInteger(2));
    node.element = getMethod(_typeProvider.numType, "+");
    JUnitTestCase.assertSame(_typeProvider.intType, analyze(node));
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
    Type2 dynamicType3 = _typeProvider.dynamicType;
    FormalParameter p1 = ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("p1"), resolvedInteger(0));
    setType(p1, dynamicType3);
    FormalParameter p2 = ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("p2"), resolvedInteger(0));
    setType(p2, dynamicType3);
    FunctionExpression node = resolvedFunctionExpression(ASTFactory.formalParameterList([p1, p2]), ASTFactory.blockFunctionBody([]));
    analyze3(p1);
    analyze3(p2);
    Type2 resultType = analyze(node);
    Map<String, Type2> expectedNamedTypes = new Map<String, Type2>();
    expectedNamedTypes["p1"] = dynamicType3;
    expectedNamedTypes["p2"] = dynamicType3;
    assertFunctionType(dynamicType3, null, null, expectedNamedTypes, resultType);
    _listener.assertNoErrors();
  }
  void test_visitFunctionExpression_named_expression() {
    Type2 dynamicType4 = _typeProvider.dynamicType;
    FormalParameter p = ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("p"), resolvedInteger(0));
    setType(p, dynamicType4);
    FunctionExpression node = resolvedFunctionExpression(ASTFactory.formalParameterList([p]), ASTFactory.expressionFunctionBody(resolvedInteger(0)));
    analyze3(p);
    Type2 resultType = analyze(node);
    Map<String, Type2> expectedNamedTypes = new Map<String, Type2>();
    expectedNamedTypes["p"] = dynamicType4;
    assertFunctionType(_typeProvider.intType, null, null, expectedNamedTypes, resultType);
    _listener.assertNoErrors();
  }
  void test_visitFunctionExpression_normal_block() {
    Type2 dynamicType5 = _typeProvider.dynamicType;
    FormalParameter p1 = ASTFactory.simpleFormalParameter3("p1");
    setType(p1, dynamicType5);
    FormalParameter p2 = ASTFactory.simpleFormalParameter3("p2");
    setType(p2, dynamicType5);
    FunctionExpression node = resolvedFunctionExpression(ASTFactory.formalParameterList([p1, p2]), ASTFactory.blockFunctionBody([]));
    analyze3(p1);
    analyze3(p2);
    Type2 resultType = analyze(node);
    assertFunctionType(dynamicType5, <Type2> [dynamicType5, dynamicType5], null, null, resultType);
    _listener.assertNoErrors();
  }
  void test_visitFunctionExpression_normal_expression() {
    Type2 dynamicType6 = _typeProvider.dynamicType;
    FormalParameter p = ASTFactory.simpleFormalParameter3("p");
    setType(p, dynamicType6);
    FunctionExpression node = resolvedFunctionExpression(ASTFactory.formalParameterList([p]), ASTFactory.expressionFunctionBody(resolvedInteger(0)));
    analyze3(p);
    Type2 resultType = analyze(node);
    assertFunctionType(_typeProvider.intType, <Type2> [dynamicType6], null, null, resultType);
    _listener.assertNoErrors();
  }
  void test_visitFunctionExpression_normalAndNamed_block() {
    Type2 dynamicType7 = _typeProvider.dynamicType;
    FormalParameter p1 = ASTFactory.simpleFormalParameter3("p1");
    setType(p1, dynamicType7);
    FormalParameter p2 = ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("p2"), resolvedInteger(0));
    setType(p2, dynamicType7);
    FunctionExpression node = resolvedFunctionExpression(ASTFactory.formalParameterList([p1, p2]), ASTFactory.blockFunctionBody([]));
    analyze3(p2);
    Type2 resultType = analyze(node);
    Map<String, Type2> expectedNamedTypes = new Map<String, Type2>();
    expectedNamedTypes["p2"] = dynamicType7;
    assertFunctionType(dynamicType7, <Type2> [dynamicType7], null, expectedNamedTypes, resultType);
    _listener.assertNoErrors();
  }
  void test_visitFunctionExpression_normalAndNamed_expression() {
    Type2 dynamicType8 = _typeProvider.dynamicType;
    FormalParameter p1 = ASTFactory.simpleFormalParameter3("p1");
    setType(p1, dynamicType8);
    FormalParameter p2 = ASTFactory.namedFormalParameter(ASTFactory.simpleFormalParameter3("p2"), resolvedInteger(0));
    setType(p2, dynamicType8);
    FunctionExpression node = resolvedFunctionExpression(ASTFactory.formalParameterList([p1, p2]), ASTFactory.expressionFunctionBody(resolvedInteger(0)));
    analyze3(p2);
    Type2 resultType = analyze(node);
    Map<String, Type2> expectedNamedTypes = new Map<String, Type2>();
    expectedNamedTypes["p2"] = dynamicType8;
    assertFunctionType(_typeProvider.intType, <Type2> [dynamicType8], null, expectedNamedTypes, resultType);
    _listener.assertNoErrors();
  }
  void test_visitFunctionExpression_normalAndPositional_block() {
    Type2 dynamicType9 = _typeProvider.dynamicType;
    FormalParameter p1 = ASTFactory.simpleFormalParameter3("p1");
    setType(p1, dynamicType9);
    FormalParameter p2 = ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("p2"), resolvedInteger(0));
    setType(p2, dynamicType9);
    FunctionExpression node = resolvedFunctionExpression(ASTFactory.formalParameterList([p1, p2]), ASTFactory.blockFunctionBody([]));
    analyze3(p1);
    analyze3(p2);
    Type2 resultType = analyze(node);
    assertFunctionType(dynamicType9, <Type2> [dynamicType9], <Type2> [dynamicType9], null, resultType);
    _listener.assertNoErrors();
  }
  void test_visitFunctionExpression_normalAndPositional_expression() {
    Type2 dynamicType10 = _typeProvider.dynamicType;
    FormalParameter p1 = ASTFactory.simpleFormalParameter3("p1");
    setType(p1, dynamicType10);
    FormalParameter p2 = ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("p2"), resolvedInteger(0));
    setType(p2, dynamicType10);
    FunctionExpression node = resolvedFunctionExpression(ASTFactory.formalParameterList([p1, p2]), ASTFactory.expressionFunctionBody(resolvedInteger(0)));
    analyze3(p1);
    analyze3(p2);
    Type2 resultType = analyze(node);
    assertFunctionType(_typeProvider.intType, <Type2> [dynamicType10], <Type2> [dynamicType10], null, resultType);
    _listener.assertNoErrors();
  }
  void test_visitFunctionExpression_positional_block() {
    Type2 dynamicType11 = _typeProvider.dynamicType;
    FormalParameter p1 = ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("p1"), resolvedInteger(0));
    setType(p1, dynamicType11);
    FormalParameter p2 = ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("p2"), resolvedInteger(0));
    setType(p2, dynamicType11);
    FunctionExpression node = resolvedFunctionExpression(ASTFactory.formalParameterList([p1, p2]), ASTFactory.blockFunctionBody([]));
    analyze3(p1);
    analyze3(p2);
    Type2 resultType = analyze(node);
    assertFunctionType(dynamicType11, null, <Type2> [dynamicType11, dynamicType11], null, resultType);
    _listener.assertNoErrors();
  }
  void test_visitFunctionExpression_positional_expression() {
    Type2 dynamicType12 = _typeProvider.dynamicType;
    FormalParameter p = ASTFactory.positionalFormalParameter(ASTFactory.simpleFormalParameter3("p"), resolvedInteger(0));
    setType(p, dynamicType12);
    FunctionExpression node = resolvedFunctionExpression(ASTFactory.formalParameterList([p]), ASTFactory.expressionFunctionBody(resolvedInteger(0)));
    analyze3(p);
    Type2 resultType = analyze(node);
    assertFunctionType(_typeProvider.intType, null, <Type2> [dynamicType12], null, resultType);
    _listener.assertNoErrors();
  }
  void test_visitIndexExpression_getter() {
    InterfaceType listType2 = _typeProvider.listType;
    SimpleIdentifier identifier = resolvedVariable(listType2, "a");
    IndexExpression node = ASTFactory.indexExpression(identifier, resolvedInteger(2));
    node.element = listType2.element.methods[0];
    JUnitTestCase.assertSame(listType2.typeArguments[0], analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitIndexExpression_setter() {
    InterfaceType listType3 = _typeProvider.listType;
    SimpleIdentifier identifier = resolvedVariable(listType3, "a");
    IndexExpression node = ASTFactory.indexExpression(identifier, resolvedInteger(2));
    node.element = listType3.element.methods[1];
    ASTFactory.assignmentExpression(node, TokenType.EQ, ASTFactory.integer(0));
    JUnitTestCase.assertSame(listType3.typeArguments[0], analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitIndexExpression_typeParameters() {
    InterfaceType intType8 = _typeProvider.intType;
    InterfaceType listType4 = _typeProvider.listType;
    MethodElement methodElement = getMethod(listType4, "[]");
    SimpleIdentifier identifier = ASTFactory.identifier3("list");
    InterfaceType listOfIntType = listType4.substitute5(<Type2> [intType8]);
    identifier.staticType = listOfIntType;
    IndexExpression indexExpression2 = ASTFactory.indexExpression(identifier, ASTFactory.integer(0));
    indexExpression2.element = MethodMember.from(methodElement, listOfIntType);
    JUnitTestCase.assertSame(intType8, analyze(indexExpression2));
    _listener.assertNoErrors();
  }
  void test_visitIndexExpression_typeParameters_inSetterContext() {
    InterfaceType intType9 = _typeProvider.intType;
    InterfaceType listType5 = _typeProvider.listType;
    MethodElement methodElement = getMethod(listType5, "[]=");
    SimpleIdentifier identifier = ASTFactory.identifier3("list");
    InterfaceType listOfIntType = listType5.substitute5(<Type2> [intType9]);
    identifier.staticType = listOfIntType;
    IndexExpression indexExpression3 = ASTFactory.indexExpression(identifier, ASTFactory.integer(0));
    indexExpression3.element = MethodMember.from(methodElement, listOfIntType);
    ASTFactory.assignmentExpression(indexExpression3, TokenType.EQ, ASTFactory.integer(0));
    JUnitTestCase.assertSame(intType9, analyze(indexExpression3));
    _listener.assertNoErrors();
  }
  void test_visitInstanceCreationExpression_named() {
    ClassElementImpl classElement = ElementFactory.classElement2("C", []);
    String constructorName = "m";
    ConstructorElementImpl constructor = ElementFactory.constructorElement(constructorName);
    FunctionTypeImpl constructorType = new FunctionTypeImpl.con1(constructor);
    constructorType.returnType = classElement.type;
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
    ConstructorElementImpl constructor = ElementFactory.constructorElement(null);
    elementC.constructors = <ConstructorElement> [constructor];
    FunctionTypeImpl constructorType = new FunctionTypeImpl.con1(constructor);
    constructorType.returnType = elementC.type;
    constructor.type = constructorType;
    TypeName typeName5 = ASTFactory.typeName(elementC, [ASTFactory.typeName(elementI, [])]);
    typeName5.type = elementC.type.substitute5(<Type2> [elementI.type]);
    InstanceCreationExpression node = ASTFactory.instanceCreationExpression2(null, typeName5, []);
    node.element = constructor;
    InterfaceType interfaceType = analyze(node) as InterfaceType;
    List<Type2> typeArgs = interfaceType.typeArguments;
    JUnitTestCase.assertEquals(1, typeArgs.length);
    JUnitTestCase.assertEquals(elementI.type, typeArgs[0]);
    _listener.assertNoErrors();
  }
  void test_visitInstanceCreationExpression_unnamed() {
    ClassElementImpl classElement = ElementFactory.classElement2("C", []);
    ConstructorElementImpl constructor = ElementFactory.constructorElement(null);
    FunctionTypeImpl constructorType = new FunctionTypeImpl.con1(constructor);
    constructorType.returnType = classElement.type;
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
    assertType2(_typeProvider.mapType.substitute5(<Type2> [_typeProvider.stringType, _typeProvider.dynamicType]), resultType);
    _listener.assertNoErrors();
  }
  void test_visitMapLiteral_nonEmpty() {
    Expression node = ASTFactory.mapLiteral2([ASTFactory.mapLiteralEntry("k", resolvedInteger(0))]);
    Type2 resultType = analyze(node);
    assertType2(_typeProvider.mapType.substitute5(<Type2> [_typeProvider.stringType, _typeProvider.dynamicType]), resultType);
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
    Type2 boolType2 = _typeProvider.boolType;
    PropertyAccessorElementImpl getter = ElementFactory.getterElement("b", false, boolType2);
    PrefixedIdentifier node = ASTFactory.identifier5("a", "b");
    node.identifier.element = getter;
    JUnitTestCase.assertSame(boolType2, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitPrefixedIdentifier_setter() {
    Type2 boolType3 = _typeProvider.boolType;
    FieldElementImpl field = ElementFactory.fieldElement("b", false, false, false, boolType3);
    PropertyAccessorElement setter5 = field.setter;
    PrefixedIdentifier node = ASTFactory.identifier5("a", "b");
    node.identifier.element = setter5;
    JUnitTestCase.assertSame(boolType3, analyze(node));
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
    node.element = getMethod(_typeProvider.numType, "-");
    JUnitTestCase.assertSame(_typeProvider.numType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitPrefixExpression_minusMinus() {
    PrefixExpression node = ASTFactory.prefixExpression(TokenType.MINUS_MINUS, resolvedInteger(0));
    node.element = getMethod(_typeProvider.numType, "-");
    JUnitTestCase.assertSame(_typeProvider.numType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitPrefixExpression_not() {
    Expression node = ASTFactory.prefixExpression(TokenType.BANG, ASTFactory.booleanLiteral(true));
    JUnitTestCase.assertSame(_typeProvider.boolType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitPrefixExpression_plusPlus() {
    PrefixExpression node = ASTFactory.prefixExpression(TokenType.PLUS_PLUS, resolvedInteger(0));
    node.element = getMethod(_typeProvider.numType, "+");
    JUnitTestCase.assertSame(_typeProvider.numType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitPrefixExpression_tilde() {
    PrefixExpression node = ASTFactory.prefixExpression(TokenType.TILDE, resolvedInteger(0));
    node.element = getMethod(_typeProvider.intType, "~");
    JUnitTestCase.assertSame(_typeProvider.intType, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitPropertyAccess_getter() {
    Type2 boolType4 = _typeProvider.boolType;
    PropertyAccessorElementImpl getter = ElementFactory.getterElement("b", false, boolType4);
    PropertyAccess node = ASTFactory.propertyAccess2(ASTFactory.identifier3("a"), "b");
    node.propertyName.element = getter;
    JUnitTestCase.assertSame(boolType4, analyze(node));
    _listener.assertNoErrors();
  }
  void test_visitPropertyAccess_setter() {
    Type2 boolType5 = _typeProvider.boolType;
    FieldElementImpl field = ElementFactory.fieldElement("b", false, false, false, boolType5);
    PropertyAccessorElement setter6 = field.setter;
    PropertyAccess node = ASTFactory.propertyAccess2(ASTFactory.identifier3("a"), "b");
    node.propertyName.element = setter6;
    JUnitTestCase.assertSame(boolType5, analyze(node));
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
    JUnitTestCase.assertSame(superType, analyze2(node, thisType));
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
    JUnitTestCase.assertEquals(expectedType.name, actualType.name);
    JUnitTestCase.assertEquals(expectedType.element, actualType.element);
    List<Type2> expectedArguments = expectedType.typeArguments;
    int length9 = expectedArguments.length;
    List<Type2> actualArguments = actualType.typeArguments;
    EngineTestCase.assertLength(length9, actualArguments);
    for (int i = 0; i < length9; i++) {
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
    ResolverVisitor visitor = new ResolverVisitor.con1(library, source, _typeProvider);
    visitor.overrideManager.enterScope();
    try {
      return visitor.typeAnalyzer_J2DAccessor as StaticTypeAnalyzer;
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
   * incomplete type associated with it (just like the one{@link ElementBuilder#visitFunctionExpression(FunctionExpression)} would have built if we had
   * run it).
   * @param parameters the parameters to the function
   * @param body the body of the function
   * @return a resolved function expression
   */
  FunctionExpression resolvedFunctionExpression(FormalParameterList parameters18, FunctionBody body) {
    for (FormalParameter parameter in parameters18.parameters) {
      ParameterElementImpl element = new ParameterElementImpl(parameter.identifier);
      element.parameterKind = parameter.kind;
      element.type = _typeProvider.dynamicType;
      parameter.identifier.element = element;
    }
    FunctionExpression node = ASTFactory.functionExpression2(parameters18, body);
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
  SimpleIdentifier resolvedVariable(InterfaceType type46, String variableName) {
    SimpleIdentifier identifier = ASTFactory.identifier3(variableName);
    VariableElementImpl element = ElementFactory.localVariableElement(identifier);
    element.type = type46;
    identifier.element = element;
    identifier.staticType = type46;
    return identifier;
  }
  /**
   * Set the type of the given parameter to the given type.
   * @param parameter the parameter whose type is to be set
   * @param type the new type of the given parameter
   */
  void setType(FormalParameter parameter, Type2 type47) {
    SimpleIdentifier identifier19 = parameter.identifier;
    Element element66 = identifier19.element;
    if (element66 is! ParameterElement) {
      element66 = new ParameterElementImpl(identifier19);
      identifier19.element = element66;
    }
    ((element66 as ParameterElementImpl)).type = type47;
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
      _ut.test('test_visitBinaryExpression_plus', () {
        final __test = new StaticTypeAnalyzerTest();
        runJUnitTest(__test, __test.test_visitBinaryExpression_plus);
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
    LibraryElement definingLibrary3 = createTestLibrary();
    GatheringErrorListener errorListener3 = new GatheringErrorListener();
    Scope rootScope = new Scope_16(definingLibrary3, errorListener3);
    EnclosedScope scope = new EnclosedScope(rootScope);
    VariableElement element1 = ElementFactory.localVariableElement(ASTFactory.identifier3("v1"));
    VariableElement element2 = ElementFactory.localVariableElement(ASTFactory.identifier3("v1"));
    scope.define(element1);
    scope.define(element2);
    errorListener3.assertErrors3([ErrorSeverity.ERROR]);
  }
  void test_define_normal() {
    LibraryElement definingLibrary4 = createTestLibrary();
    GatheringErrorListener errorListener4 = new GatheringErrorListener();
    Scope rootScope = new Scope_17(definingLibrary4, errorListener4);
    EnclosedScope outerScope = new EnclosedScope(rootScope);
    EnclosedScope innerScope = new EnclosedScope(outerScope);
    VariableElement element1 = ElementFactory.localVariableElement(ASTFactory.identifier3("v1"));
    VariableElement element2 = ElementFactory.localVariableElement(ASTFactory.identifier3("v2"));
    outerScope.define(element1);
    innerScope.define(element2);
    errorListener4.assertNoErrors();
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
  LibraryElement definingLibrary3;
  GatheringErrorListener errorListener3;
  Scope_16(this.definingLibrary3, this.errorListener3) : super();
  LibraryElement get definingLibrary => definingLibrary3;
  AnalysisErrorListener get errorListener => errorListener3;
  Element lookup3(String name, LibraryElement referencingLibrary) => null;
}
class Scope_17 extends Scope {
  LibraryElement definingLibrary4;
  GatheringErrorListener errorListener4;
  Scope_17(this.definingLibrary4, this.errorListener4) : super();
  LibraryElement get definingLibrary => definingLibrary4;
  AnalysisErrorListener get errorListener => errorListener4;
  Element lookup3(String name, LibraryElement referencingLibrary) => null;
}
class LibraryElementBuilderTest extends EngineTestCase {
  /**
   * The source factory used to create {@link Source sources}.
   */
  SourceFactory _sourceFactory;
  void setUp() {
    _sourceFactory = new SourceFactory.con2([new FileUriResolver()]);
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
    List<ClassElement> types3 = unit.types;
    EngineTestCase.assertLength(typeNames.length, types3);
    for (ClassElement type in types3) {
      JUnitTestCase.assertNotNull(type);
      String actualTypeName = type.name;
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
    GatheringErrorListener listener = new GatheringErrorListener();
    LibraryResolver resolver = new LibraryResolver.con2(context, listener);
    LibraryElementBuilder builder = new LibraryElementBuilder(resolver);
    Library library = resolver.createLibrary(librarySource) as Library;
    LibraryElement element = builder.buildLibrary(library);
    listener.assertErrors2(expectedErrorCodes);
    return element;
  }
  static dartSuite() {
    _ut.group('LibraryElementBuilderTest', () {
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
  Element lookup3(String name, LibraryElement referencingLibrary) => localLookup(name, referencingLibrary);
}
class SimpleResolverTest extends ResolverTestCase {
  void fail_staticInvocation() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  static int get g => (a,b) => 0;", "}", "class B {", "  f() {", "    A.g(1,0);", "  }", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_class_definesCall() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int call(int x) { return x; }", "}", "int f(A a) {", "  return a(0);", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_class_extends_implements() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A extends B implements C {}", "class B {}", "class C {}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_empty() {
    Source source = addSource("/test.dart", "");
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_extractedMethodAsConstant() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["abstract class Comparable<T> {", "  int compareTo(T other);", "  static int compare(Comparable a, Comparable b) => a.compareTo(b);", "}", "class A {", "  void sort([compare = Comparable.compare]) {}", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_forEachLoops_nonConflicting() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  List list = [1,2,3];", "  for (int x in list) {}", "  for (int x in list) {}", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_forLoops_nonConflicting() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  for (int i = 0; i < 3; i++) {", "  }", "  for (int i = 0; i < 3; i++) {", "  }", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_functionTypeAlias() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["typedef bool P(e);", "class A {", "  P p;", "  m(e) {", "    if (p(e)) {}", "  }", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_getterAndSetterWithDifferentTypes() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  int get f => 0;", "  void set f(String s) {}", "}", "g (A a) {", "  a.f = a.f.toString();", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_importWithPrefix() {
    addSource("/two.dart", EngineTestCase.createSource(["library two;", "f(int x) {", "  return x * x;", "}"]));
    Source source = addSource("/one.dart", EngineTestCase.createSource(["library one;", "import 'two.dart' as _two;", "main() {", "  _two.f(0);", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_indexExpression_typeParameters() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  List<int> a;", "  a[0];", "  List<List<int>> b;", "  b[0][0];", "  List<List<List<int>>> c;", "  c[0][0][0];", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_indexExpression_typeParameters_invalidAssignmentWarning() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f() {", "  List<List<int>> b;", "  b[0][0] = 'hi';", "}"]));
    resolve(source, []);
    assertErrors([StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }
  void test_invoke_dynamicThroughGetter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  List get X => [() => 0];", "  m(A a) {", "    X.last();", "  }", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_isValidMixin_badSuperclass() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A extends B {}", "class B {}"]));
    LibraryElement library = resolve(source, []);
    JUnitTestCase.assertNotNull(library);
    CompilationUnitElement unit = library.definingCompilationUnit;
    JUnitTestCase.assertNotNull(unit);
    List<ClassElement> classes = unit.types;
    EngineTestCase.assertLength(2, classes);
    JUnitTestCase.assertFalse(classes[0].isValidMixin());
    assertNoErrors();
    verify([source]);
  }
  void test_isValidMixin_constructor() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  A() {}", "}"]));
    LibraryElement library = resolve(source, []);
    JUnitTestCase.assertNotNull(library);
    CompilationUnitElement unit = library.definingCompilationUnit;
    JUnitTestCase.assertNotNull(unit);
    List<ClassElement> classes = unit.types;
    EngineTestCase.assertLength(1, classes);
    JUnitTestCase.assertFalse(classes[0].isValidMixin());
    assertNoErrors();
    verify([source]);
  }
  void test_isValidMixin_super() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  toString() {", "    return super.toString();", "  }", "}"]));
    LibraryElement library = resolve(source, []);
    JUnitTestCase.assertNotNull(library);
    CompilationUnitElement unit = library.definingCompilationUnit;
    JUnitTestCase.assertNotNull(unit);
    List<ClassElement> classes = unit.types;
    EngineTestCase.assertLength(1, classes);
    JUnitTestCase.assertFalse(classes[0].isValidMixin());
    assertNoErrors();
    verify([source]);
  }
  void test_isValidMixin_valid() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {}"]));
    LibraryElement library = resolve(source, []);
    JUnitTestCase.assertNotNull(library);
    CompilationUnitElement unit = library.definingCompilationUnit;
    JUnitTestCase.assertNotNull(unit);
    List<ClassElement> classes = unit.types;
    EngineTestCase.assertLength(1, classes);
    JUnitTestCase.assertTrue(classes[0].isValidMixin());
    assertNoErrors();
    verify([source]);
  }
  void test_methodCascades() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  void m1() {}", "  void m2() {}", "  void m() {", "    A a = new A();", "    a..m1()", "     ..m2();", "  }", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_methodCascades_withSetter() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["class A {", "  String name;", "  void m1() {}", "  void m2() {}", "  void m() {", "    A a = new A();", "    a..m1()", "     ..name = 'name'", "     ..m2();", "  }", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  void test_resolveAgainstNull() {
    Source source = addSource("/test.dart", EngineTestCase.createSource(["f(var p) {", "  return null == p;", "}"]));
    resolve(source, []);
    assertNoErrors();
    verify([source]);
  }
  static dartSuite() {
    _ut.group('SimpleResolverTest', () {
      _ut.test('test_class_definesCall', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_class_definesCall);
      });
      _ut.test('test_class_extends_implements', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_class_extends_implements);
      });
      _ut.test('test_empty', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_empty);
      });
      _ut.test('test_extractedMethodAsConstant', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_extractedMethodAsConstant);
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
      _ut.test('test_importWithPrefix', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_importWithPrefix);
      });
      _ut.test('test_indexExpression_typeParameters', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_indexExpression_typeParameters);
      });
      _ut.test('test_indexExpression_typeParameters_invalidAssignmentWarning', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_indexExpression_typeParameters_invalidAssignmentWarning);
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
      _ut.test('test_methodCascades', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_methodCascades);
      });
      _ut.test('test_methodCascades_withSetter', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_methodCascades_withSetter);
      });
      _ut.test('test_resolveAgainstNull', () {
        final __test = new SimpleResolverTest();
        runJUnitTest(__test, __test.test_resolveAgainstNull);
      });
    });
  }
}
main() {
//  ElementResolverTest.dartSuite();
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
//  TypePropagationTest.dartSuite();
}