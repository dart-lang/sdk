// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.common.base.Joiner;
import com.google.common.io.CharStreams;
import com.google.dart.compiler.DartCompilerErrorCode;
import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartExprStmt;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartFunctionTypeAlias;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartStatement;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.parser.DartParser;
import com.google.dart.compiler.parser.DartScannerParserContext;
import com.google.dart.compiler.parser.Token;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.CoreTypeProvider;
import com.google.dart.compiler.resolver.CyclicDeclarationException;
import com.google.dart.compiler.resolver.DuplicatedInterfaceException;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.Elements;
import com.google.dart.compiler.resolver.FunctionAliasElement;
import com.google.dart.compiler.resolver.MemberBuilder;
import com.google.dart.compiler.resolver.ResolutionContext;
import com.google.dart.compiler.resolver.Resolver;
import com.google.dart.compiler.resolver.Resolver.ResolveElementsVisitor;
import com.google.dart.compiler.resolver.Scope;
import com.google.dart.compiler.resolver.SupertypeResolver;
import com.google.dart.compiler.resolver.TopLevelElementBuilder;
import com.google.dart.compiler.util.DartSourceString;

import java.io.IOError;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.Arrays;
import java.util.EnumSet;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Test of static type analysis. This is mostly a test of {@link TypeAnalyzer}, but this test also
 * exercises code in com.google.dart.compiler.resolver.
 */
public class TypeAnalyzerTest extends TypeTestCase {
  private final CoreTypeProvider typeProvider = new MockCoreTypeProvider();
  private Resolver resolver = new Resolver(context, getMockScope("<test toplevel>"), typeProvider);
  private final Types types = Types.getInstance(typeProvider);
  private HashSet<ClassElement> diagnosedAbstractClasses = new HashSet<ClassElement>();

  @Override
  protected void tearDown() {
    resolver = null;
    diagnosedAbstractClasses = null;
  }

  @Override
  Types getTypes() {
    return types;
  }

  private TypeAnalyzer.Analyzer makeTypeAnalyzer(ClassElement element) {
    TypeAnalyzer.Analyzer analyzer =
        new TypeAnalyzer.Analyzer(context, typeProvider,
                                  new ConcurrentHashMap<ClassElement, List<Element>>(),
                                  diagnosedAbstractClasses);
    analyzer.setCurrentClass(element.getType());
    return analyzer;
  }

  public void testLabels() {
    // Labels should be inside a function or method to be used

    // break
    analyze("foo() { L: for (;true;) { break L; } }");
    analyze("foo() { int x; Array<int> c; L: for (x  in c) { break L; } }");
    analyze("foo() { Array<int> c; L: for (var x  in c) { break L; } }");
    analyze("foo() { L: while (true) { break L; } }");
    analyze("foo() { L: do { break L; } while (true); }");

    analyze("foo() { L: for (;true;) { for (;true;) { break L; } } }");
    analyze("foo() { int x; Array<int> c; L: for (x  in c) { for (;true;) { break L; } } }");
    analyze("foo() { Array<int> c; L: for (var x  in c) { for (;true;) { break L; } } }");
    analyze("foo() { L: while (true) { for (;true;) { break L; } } }");
    analyze("foo() { L: do { for (;true;) { break L; } } while (true); }");

    // continue
    analyze("foo() { L: for (;true;) { continue L; } }");
    analyze("foo() { int x; Array<int> c; L: for (x  in c) { continue L; } }");
    analyze("foo() { Array<int> c; L: for (var x  in c)  { continue L; } }");
    analyze("foo() { L: do { continue L; } while (true); }");

    analyze("foo() { L: for (;true;) { for (;true;) { continue L; } } }");
    analyze(
      "foo() { int x; Array<int> c; L: for (x  in c) { for (;true;) { continue L; } } }");
    analyze("foo() { Array<int> c; L: for (var x  in c)  { for (;true;) { continue L; } } }");
    analyze("foo() { L: while (true) { for (;true;) { continue L; } } }");
    analyze("foo() { L: do { for (;true;) { continue L; } } while (true); }");

    // corner cases
    analyze("foo() { L: break L; }");

    // TODO(zundel): Not type errors, but warnings.
    analyze("foo() { L: for (;true;) { } }");
    analyze("foo() { while (true) { L: var a; } }");
  }

  public void testLiterals() {
    checkSimpleType(intElement.getType(), "1");
    checkSimpleType(doubleElement.getType(), ".0");
    checkSimpleType(doubleElement.getType(), "1.0");
    checkSimpleType(bool.getType(), "true");
    checkSimpleType(bool.getType(), "false");
    checkSimpleType(string.getType(), "'fisk'");
    checkSimpleType(string.getType(), "'f${null}sk'");
  }

  public void testUnresolvedIdentifier() {
    setExpectedTypeErrorCount(3);
    checkType(typeProvider.getDynamicType(), "y");
    checkExpectedTypeErrorCount();
  }

  public void testInitializers() {
    analyze("int i = 1;");
    analyze("double d1 = .0;");
    analyze("double d2 = 1.0;");
    analyze("int x = null;");
  }

  public void testBadInitializers() {
    analyzeFail("int i = .0;", DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("int j = 1.0;", DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testFunctionTypes() {
    checkFunctionStatement("String foo() {};", "() -> String");
    checkFunctionStatement("Object foo() {};", "() -> Object");
    checkFunctionStatement("String foo(int i, bool b) {};", "(int, bool) -> String");
  }

  private void checkFunctionStatement(String statement, String printString) {
    DartExprStmt node = (DartExprStmt) analyze(statement);
    DartFunctionExpression expression = (DartFunctionExpression) node.getExpression();
    Element element = expression.getSymbol();
    FunctionType type = (FunctionType) element.getType();
    assertEquals(printString, type.toString());
  }

  public void testIdentifiers() {
    analyze("{ int i; i = 2; }");
    analyze("{ int j, k; j = 1; k = 3; }");
    analyzeFail("{ int i; i = 'string'; }", DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("{ int j, k; k = 'string'; }",
        DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("{ int j, k; j = 'string'; }",
        DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testRawTypes() {
    loadFile("interfaces.dart");

    analyze("{ Sub s; }");
    analyze("{ var s = new Sub(); }");
    analyze("{ Sub s = new Sub(); }");
    analyze("{ Sub<String> s = new Sub(); }");
    analyze("{ Sub<String> s; }");
    analyze("{ var s = new Sub<String>(); }");
    analyze("{ Sub s = new Sub<String>(); }");
    analyze("{ Sub<String> s = new Sub<String>(); }");

    // FYI, this is detected in the resolver, not TypeAnalyzer
    analyzeFail("{ Sub<String, String> s = new Sub(); }",
        DartCompilerErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS);
    analyzeFail("{ Sub<String, String> s = new Sub<String>(); }",
        DartCompilerErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS);
    analyzeFail("{ Sub<String, String> s; }", DartCompilerErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS);
    analyzeFail("{ String<String> s; }", DartCompilerErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS);
  }

  public void testMethodInvocations() {
    loadFile("class_with_methods.dart");
    final String header = "{ ClassWithMethods c; int i, j; Array array; ";

    analyze(header + "int k = c.untypedNoArgumentMethod(); }");
    analyze(header + "ClassWithMethods x = c.untypedNoArgumentMethod(); }");

    analyze(header + "int k = c.untypedOneArgumentMethod(c); }");
    analyze(header + "ClassWithMethods x = c.untypedOneArgumentMethod(1); }");
    analyze(header + "int k = c.untypedOneArgumentMethod('string'); }");
    analyze(header + "int k = c.untypedOneArgumentMethod(i); }");

    analyze(header + "int k = c.untypedTwoArgumentMethod(1, 'string'); }");
    analyze(header + "int k = c.untypedTwoArgumentMethod(i, j); }");
    analyze(header + "ClassWithMethods x = c.untypedTwoArgumentMethod(i, c); }");

    analyze(header + "int k = c.intNoArgumentMethod(); }");
    analyzeFail(header + "ClassWithMethods x = c.intNoArgumentMethod(); }",
        DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);

    analyzeFail(header + "int k = c.intOneArgumentMethod(c); }",
        DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail(header + "ClassWithMethods x = c.intOneArgumentMethod(1); }",
        DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail(header + "int k = c.intOneArgumentMethod('string'); }",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze(header + "int k = c.intOneArgumentMethod(i); }");

    analyzeFail(header + "int k = c.intTwoArgumentMethod(1, 'string'); }",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze(header + "int k = c.intTwoArgumentMethod(i, j); }");
    analyzeFail(header + "ClassWithMethods x = c.intTwoArgumentMethod(i, j); }",
        DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testMethodInvocationArgumentCount() {
    loadFile("class_with_methods.dart");
    final String header = "{ ClassWithMethods c; Array array; ";

    analyzeFail(header + "c.untypedNoArgumentMethod(1); }",
      DartCompilerErrorCode.EXTRA_ARGUMENT);
    analyzeFail(header + "c.untypedOneArgumentMethod(); }",
      DartCompilerErrorCode.MISSING_ARGUMENT);
    analyzeFail(header + "c.untypedOneArgumentMethod(1, 1); }",
      DartCompilerErrorCode.EXTRA_ARGUMENT);
    analyzeFail(header + "c.untypedTwoArgumentMethod(); }",
      DartCompilerErrorCode.MISSING_ARGUMENT);
    analyzeFail(header + "c.untypedTwoArgumentMethod(1, 2, 3); }",
      DartCompilerErrorCode.EXTRA_ARGUMENT);
    analyzeFail(header + "c.intNoArgumentMethod(1); }",
      DartCompilerErrorCode.EXTRA_ARGUMENT);
    analyzeFail(header + "c.intOneArgumentMethod(); }",
      DartCompilerErrorCode.MISSING_ARGUMENT);
    analyzeFail(header + "c.intOneArgumentMethod(1, 1); }",
      DartCompilerErrorCode.EXTRA_ARGUMENT);
    analyzeFail(header + "c.intTwoArgumentMethod(); }",
      DartCompilerErrorCode.MISSING_ARGUMENT);
    analyzeFail(header + "c.intTwoArgumentMethod(1, 2, 3); }",
      DartCompilerErrorCode.EXTRA_ARGUMENT);
    analyze(header + "c.untypedField(); }");
  }

  public void testLoadInterfaces() {
    loadFile("interfaces.dart");
    ClassElement superElement = coreElements.get("Super");
    assertNotNull("no element for Super", superElement);
    assertEquals(object.getType(), superElement.getSupertype());
    assertEquals(0, superElement.getInterfaces().size());
    ClassElement sub = coreElements.get("Sub");
    assertNotNull("no element for Sub", sub);
    assertEquals(object.getType(), sub.getSupertype());
    assertEquals(1, sub.getInterfaces().size());
    assertEquals(superElement, sub.getInterfaces().get(0).getElement());
    InterfaceType superString = itype(superElement, itype(string));
    InterfaceType subString = itype(sub, itype(string));
    assertEquals("Super<String>", String.valueOf(types.asInstanceOf(superString, superElement)));
    assertEquals("Super<String>", String.valueOf(types.asInstanceOf(subString, superElement)));
    assertEquals("Sub<String>", String.valueOf(types.asInstanceOf(subString, sub)));
    assertNull(types.asInstanceOf(superString, sub));
  }

  public void testSuperInterfaces() {
    // If this test is failing, first debug any failures in testLoadInterfaces.
    loadFile("interfaces.dart");
    analyze("Super<String> s = new Sub<String>();");
    analyze("Super<Object> o = new Sub<String>();");
    analyzeFail("Super<String> f1 = new Sub<int>();",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("Sub<String> f2 = new Sub<int>();",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testUnaryOperators() {
    Map<String, ClassElement> source = loadSource(
        "class Foo {",
        "  Foo foo;",
        "  bool b;",
        "  int i;",
        "  Foo operator negate() { return this; }",
        "  Foo operator +(int operand) { return this; }",
        "  Foo operator -(int operand) { return this; }",
        "}",
        "class Bar {",
        "  Bar bar;",
        "  Bar operator +(Bar operand) { return this; }",
        "  Bar operator -(Bar operand) { return this; }",
        "}",
        "class Baz<T extends Foo> {",
        "  T baz;",
        "}",
        "class Qux<T> { ",
        "  T qux; ",
        "  void x() { }",
        "  y() { }",
        "}",
        "class X {",
        "  X x;",
        "  Z operator negate() { return null; }",
        "  Z operator +(int operand) { return null; }",
        "  Z operator -(int operand) { return null; }",
        "}",
        "class Y extends X { Y y; }",
        "class Z extends X { Z z; }"
        );
    analyzeClasses(source);
    ClassElement foo = source.get("Foo");
    ClassElement bar = source.get("Bar");
    ClassElement baz = source.get("Baz");
    ClassElement qux = source.get("Qux");
    ClassElement y = source.get("Y");
    ClassElement z = source.get("Z");
    for (Token op : EnumSet.of(Token.DEC, Token.INC, Token.SUB)) {
      analyzeIn(foo, String.format("%sfoo", op), 0);
      analyzeIn(foo, String.format("i = %sfoo", op), 1);
      analyzeIn(bar, String.format("%sbar", op), 1);
      analyzeIn(baz, String.format("%sbaz", op), 0);
      analyzeIn(qux, String.format("%squx", op), 1);
    }
    analyzeIn(z, "z = x++", 0);
    analyzeIn(z, "z = ++x", 0);
    analyzeIn(z, "z = x--", 0);
    analyzeIn(z, "z = --x", 0);
    analyzeIn(y, "y = x++", 0);
    analyzeIn(y, "y = ++x", 1);
    analyzeIn(y, "y = x--", 0);
    analyzeIn(y, "y = --x", 1);

    analyzeIn(foo, "b = !b", 0);
    analyzeIn(foo, "foo = !foo", 2);
    analyzeIn(foo, "b = !i", 1);
    analyzeIn(foo, "foo = !b", 1);
    analyzeIn(qux, "-x()", 1);
    analyzeIn(qux, "-y()", 0);
  }

  public void testBinaryOperators() {
    ClassElement cls = loadClass("class_with_operators.dart", "ClassWithOperators");
    analyzeIn(cls, "i = o[0]", 0);
    analyzeIn(cls, "s = o[0]", 1);
    analyzeIn(cls, "o['fisk']", 1);
    analyzeIn(cls, "i && o", 2);
    analyzeIn(cls, "b && o", 1);
    analyzeIn(cls, "i && b", 1);
    analyzeIn(cls, "b && b", 0);
    analyzeIn(cls, "i || o", 2);
    analyzeIn(cls, "b || o", 1);
    analyzeIn(cls, "i || b", 1);
    analyzeIn(cls, "b || b", 0);

    EnumSet<Token> userOperators = EnumSet.of(Token.SHR,
                                              Token.ADD,
                                              Token.SUB,
                                              Token.MUL,
                                              Token.DIV,
                                              Token.TRUNC,
                                              Token.MOD,
                                              Token.LT,
                                              Token.GT,
                                              Token.LTE,
                                              Token.GTE);
    for (Token op : userOperators) {
      String expression;
      expression = String.format("untyped %s untyped", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("o = untyped %s untyped", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("s = untyped %s untyped", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("o %s untyped", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("o = o %s untyped", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("s = o %s untyped", op.getSyntax());
      analyzeIn(cls, expression, 1);
      expression = String.format("o %s null", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("o = o %s null", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("s = o %s null", op.getSyntax());
      analyzeIn(cls, expression, 1);
      expression = String.format("o %s o", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("o = o %s o", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("s = o %s o", op.getSyntax());
      analyzeIn(cls, expression, 1);
      expression = String.format("o %s s", op.getSyntax());
      analyzeIn(cls, expression, 1);
      expression = String.format("o %s i", op.getSyntax());
      analyzeIn(cls, expression, 1);
    }

    EnumSet<Token> equalityOperators = EnumSet.of(Token.EQ,
                                                  Token.NE,
                                                  Token.EQ_STRICT,
                                                  Token.NE_STRICT);
    for (Token op : equalityOperators) {
      String expression;
      expression = String.format("untyped %s untyped", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("b = untyped %s untyped", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("s = untyped %s untyped", op.getSyntax());
      analyzeIn(cls, expression, 1);
      expression = String.format("i = untyped %s untyped", op.getSyntax());
      analyzeIn(cls, expression, 1);

      expression = String.format("o %s o", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("b = o %s o", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("s = o %s o", op.getSyntax());
      analyzeIn(cls, expression, 1);
      expression = String.format("i = o %s o", op.getSyntax());
      analyzeIn(cls, expression, 1);

      expression = String.format("o %s s", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("b = o %s s", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("s = o %s s", op.getSyntax());
      analyzeIn(cls, expression, 1);
      expression = String.format("i = o %s s", op.getSyntax());
      analyzeIn(cls, expression, 1);
    }

    EnumSet<Token> compoundAssignmentOperators =
        EnumSet.of(Token.ASSIGN_ADD,
                   Token.ASSIGN_SUB,
                   Token.ASSIGN_MUL,
                   Token.ASSIGN_DIV,
                   Token.ASSIGN_MOD,
                   Token.ASSIGN_TRUNC,
                   Token.ASSIGN_SHR);

    for (Token op : compoundAssignmentOperators) {
      String expression;
      expression = String.format("o %s untyped", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("s %s untyped", op.getSyntax());
      analyzeIn(cls, expression, 1);
      expression = String.format("o %s null", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("s %s null", op.getSyntax());
      analyzeIn(cls, expression, 1);
      expression = String.format("o %s o", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("s %s o", op.getSyntax());
      analyzeIn(cls, expression, 1);
      expression = String.format("o %s i", op.getSyntax());
      analyzeIn(cls, expression, 1);
    }

    analyzeIn(cls, "untyped is String", 0);
    analyzeIn(cls, "b = untyped is String", 0);
    analyzeIn(cls, "s = untyped is String", 1);
    analyzeIn(cls, "s is String", 0);
    analyzeIn(cls, "b = s is String", 0);
    analyzeIn(cls, "s = s is String", 1);

    analyzeIn(cls, "untyped is !String", 0);
    analyzeIn(cls, "b = untyped is !String", 0);
    analyzeIn(cls, "s = untyped is !String", 1);
    analyzeIn(cls, "s is !String", 0);
    analyzeIn(cls, "b = s is !String", 0);
    analyzeIn(cls, "s = s is !String", 1);

    analyzeFail("1 == !'s';", DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testBitOperators() {
    Map<String, ClassElement> source = loadSource(
        "class ClassWithBitops {",
        "  num n;",
        "  int i;",
        "  double d;",
        "  ClassWithBitops o;",
        "  num foo() { return 42; }",
        "  int operator |(int arg) { return arg; }",
        "  int operator &(int arg) { return arg; }",
        "  int operator ^(int arg) { return arg; }",
        "  int operator >>(int arg) { return arg; }",
        "  int operator >>>(int arg) { return arg; }",
        "  int operator <<(int arg) { return arg; }",
        "  int operator ~() { return 1; }",
        "}");
    ClassElement cls = source.get("ClassWithBitops");
    analyzeClasses(source);

    EnumSet<Token> operators = EnumSet.of(Token.BIT_AND,
                                          Token.BIT_OR,
                                          Token.BIT_XOR,
                                          Token.SHL,
                                          Token.SAR);
    for (Token operator : operators) {
      analyzeIn(cls, String.format("n %s n" , operator), 0);
      analyzeIn(cls, String.format("foo() %s i" , operator), 0);
      analyzeIn(cls, String.format("o %s i" , operator), 0);
      analyzeIn(cls, String.format("n = d %s i", operator), 1);
      analyzeIn(cls, String.format("d = o %s i", operator), 1);
      analyzeIn(cls, String.format("d = n %s i", operator), 1);
      analyzeIn(cls, String.format("n %s o" , operator), 1);
    }

    EnumSet<Token> assignOperators = EnumSet.of(Token.ASSIGN_BIT_AND,
                                                Token.ASSIGN_BIT_OR,
                                                Token.ASSIGN_BIT_XOR,
                                                Token.ASSIGN_SHL,
                                                Token.ASSIGN_SAR);
    for (Token operator : assignOperators) {
      analyzeIn(cls, String.format("n %s n" , operator), 0);
      analyzeIn(cls, String.format("n %s i" , operator), 0);
      analyzeIn(cls, String.format("d %s i", operator), 1);
      analyzeIn(cls, String.format("o %s i", operator), 1);
      analyzeIn(cls, String.format("n %s o" , operator), 1);
    }

    analyzeIn(cls, "i = ~o", 0);
    analyzeIn(cls, "i = ~n", 0);
    analyzeIn(cls, "d = ~n", 1);
  }


  public void testFunctionObjectLiterals() {
    analyze("{ bool b = foo() {}(); }");
    analyze("{ int i = foo() {}(); }");
    analyze("{ bool b = bool foo() { return null; }(); }");
    analyze("{ int i = int foo() { return null; }(); }");
    analyzeFail("{ int i = bool foo() { return null; }(); }",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze("{ int i = Object _(Object x) { return x; }('fisk'); }");
    analyzeFail("{ int i = String _(Object x) { return x; }(1); }",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze("Function f = foo() {};");
  }

  public void testAssert() {
    analyze("assert(true);");
    analyze("assert(false);");
    analyzeFail("assert('message');",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze("assert(null);");
    analyzeFail("assert(1);",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze("assert(foo() {});");
    analyze("assert(bool foo() {});");
    analyze("assert(Object foo() {});");
    analyzeFail("assert(String foo() {});",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testReturn() {
    analyzeFail(returnWithType("int", "'string'"),
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze(returnWithType("", "'string'"));
    analyze(returnWithType("Object", "'string'"));
    analyze(returnWithType("String", "'string'"));
    analyze(returnWithType("String", null));
    analyze(returnWithType("int", null));
    analyze(returnWithType("void", ""));
    analyzeFail(returnWithType("void", 1), DartCompilerErrorCode.VOID_CANNOT_RETURN_VALUE);
    analyzeFail(returnWithType("void", null), DartCompilerErrorCode.VOID_CANNOT_RETURN_VALUE);
    analyzeFail(returnWithType("String", ""), DartCompilerErrorCode.MISSING_RETURN_VALUE);
    analyze("String foo() {};"); // Should probably fail, http://b/4484060.
  }

  public void testNamedFunctionTypeAlias() {
    loadFile("named_function_type_alias.dart");
    analyze("VoidFunction f = foo() {};");
  }

  public void testUnresolved() {
    ClassElement element = loadClass("class_with_supertypes.dart", "ClassWithSupertypes");
    analyzeIn(element, "null", 0);
    analyzeIn(element, "noSuchField", 1);
    analyzeIn(element, "noSuchMethod()", 1);
    analyzeIn(element, "method()", 0);
    analyzeIn(element, "field", 0);
    analyzeIn(element, "this.noSuchField", 1);
    analyzeIn(element, "this.noSuchMethod()", 1);
    analyzeIn(element, "this.method()", 0);
    analyzeIn(element, "this.field", 0);
    analyzeIn(element, "staticMethod()", 0);
    analyzeIn(element, "staticField", 0);
    analyzeIn(element, "this.staticMethod()", 1);
    analyzeIn(element, "this.staticField", 1);
    analyzeIn(element, "ClassWithSupertypes.staticMethod()", 0);
    analyzeIn(element, "ClassWithSupertypes.staticField", 0);
    analyzeIn(element, "methodInSuperclass()", 0);
    analyzeIn(element, "fieldInSuperclass", 0);
    analyzeIn(element, "staticMethodInSuperclass()", 0);
    analyzeIn(element, "staticFieldInSuperclass", 0);
    analyzeIn(element, "this.methodInSuperclass()", 0);
    analyzeIn(element, "this.fieldInSuperclass", 0);
    analyzeIn(element, "this.staticMethodInSuperclass()", 1);
    analyzeIn(element, "this.staticFieldInSuperclass", 1);
    analyzeIn(element, "Superclass.staticMethodInSuperclass()", 0);
    analyzeIn(element, "Superclass.staticFieldInSuperclass", 0);
    analyzeIn(element, "methodInInterface()", 0);
    analyzeIn(element, "fieldInInterface", 0);
    analyzeIn(element, "this.methodInInterface()", 0);
    analyzeIn(element, "this.fieldInInterface", 0);
    analyzeIn(element, "staticFieldInInterface", 0);
    analyzeIn(element, "Interface.staticFieldInInterface", 0);
    analyzeIn(element, "this.staticFieldInInterface", 1);
  }

  public void testTypeVariables() {
    ClassElement cls = loadFile("class_with_type_parameter.dart").get("ClassWithTypeParameter");
    assertNotNull("unable to locate ClassWithTypeParameter", cls);
    analyzeIn(cls, "aField = tField", 0);
    analyzeIn(cls, "bField = tField", 0);
    analyzeIn(cls, "tField = aField", 0);
    analyzeIn(cls, "tField = bField", 0);
    analyzeIn(cls, "tField = null", 0);
    analyzeIn(cls, "tField = 1", 1);
    analyzeIn(cls, "tField = ''", 1);
    analyzeIn(cls, "tField = true", 1);

    analyzeIn(cls, "foo() { A a = null; T t = a; }()", 0);
    analyzeIn(cls, "foo() { B b = null; T t = b; }()", 0);
    analyzeIn(cls, "foo() { T t = null; A a = t; }()", 0);
    analyzeIn(cls, "foo() { T t = null; B b = t; }()", 0);
    analyzeIn(cls, "foo() { T t = 1; }()", 1);
    analyzeIn(cls, "foo() { T t = ''; }()", 1);
    analyzeIn(cls, "foo() { T t = true; }()", 1);
  }

  public void testFieldAccess() {
    ClassElement element = loadFile("class_with_supertypes.dart").get("ClassWithSupertypes");
    assertNotNull("unable to locate ClassWithSupertypes", element);
    analyzeIn(element, "field = 1", 0);
    analyzeIn(element, "staticField = 1", 0);
    analyzeIn(element, "fieldInSuperclass = 1", 0);
    analyzeIn(element, "staticFieldInSuperclass = 1", 0);

    analyzeIn(element, "field = field", 0);
    analyzeIn(element, "field = staticField", 0);
    analyzeIn(element, "field = fieldInSuperclass", 0);
    analyzeIn(element, "field = staticFieldInSuperclass", 0);
    analyzeIn(element, "field = fieldInInterface", 0);
    analyzeIn(element, "field = staticFieldInInterface", 0);

    analyzeIn(element, "field = 1", 0);
    analyzeIn(element, "staticField = 1", 0);
    analyzeIn(element, "fieldInSuperclass = 1", 0);
    analyzeIn(element, "staticFieldInSuperclass = 1", 0);

    analyzeIn(element, "field = ''", 1);
    analyzeIn(element, "staticField = ''", 1);
    analyzeIn(element, "fieldInSuperclass = ''", 1);
    analyzeIn(element, "staticFieldInSuperclass = ''", 1);

    analyzeIn(element, "field.noSuchField", 1);
    analyzeIn(element, "staticField.noSuchField", 1);
    analyzeIn(element, "fieldInSuperclass.noSuchField", 1);
    analyzeIn(element, "staticFieldInSuperclass.noSuchField", 1);
    analyzeIn(element, "fieldInInterface.noSuchField", 1);
    analyzeIn(element, "staticFieldInInterface.noSuchField", 1);

    analyzeIn(element, "new ClassWithSupertypes()", 2); // Abstract class.
    analyzeIn(element, "field = new ClassWithSupertypes().field", 1);
    analyzeIn(element, "field = new ClassWithSupertypes().staticField", 2);
    analyzeIn(element, "field = new ClassWithSupertypes().fieldInSuperclass", 1);
    analyzeIn(element, "field = new ClassWithSupertypes().staticFieldInSuperclass", 2);
    analyzeIn(element, "field = new ClassWithSupertypes().fieldInInterface", 1);
    analyzeIn(element, "field = new ClassWithSupertypes().staticFieldInInterface", 2);

    analyzeIn(element, "new ClassWithSupertypes().field = 1", 1);
    analyzeIn(element, "new ClassWithSupertypes().staticField = 1", 2);
    analyzeIn(element, "new ClassWithSupertypes().fieldInSuperclass = 1", 1);
    analyzeIn(element, "new ClassWithSupertypes().staticFieldInSuperclass = 1", 2);
    // Enable this test when constness is propagated:
    // analyzeIn(element, "new ClassWithSupertypes().fieldInInterface = 1", 1);
    analyzeIn(element, "new ClassWithSupertypes().staticFieldInInterface = 1", 2);
  }

  public void testPropertyAccess() {
    ClassElement cls = loadClass("classes_with_properties.dart", "ClassWithProperties");
    analyzeIn(cls, "null", 0);
    analyzeIn(cls, "noSuchField", 1);
    analyzeIn(cls, "noSuchMethod()", 1);
    analyzeIn(cls, "x.noSuchField", 0);
    analyzeIn(cls, "x.noSuchMethod()", 0);
    analyzeIn(cls, "x.x.noSuchField", 0);
    analyzeIn(cls, "x.x.noSuchMethod()", 0);
    analyzeIn(cls, "x.a.noSuchField", 0);
    analyzeIn(cls, "x.a.noSuchMethod()", 0);
    String[] typedFields = { "a", "b", "c"};
    for (String field : typedFields) {
      analyzeIn(cls, field + ".noSuchField", 1);
      analyzeIn(cls, field + ".noSuchMethod()", 1);
      analyzeIn(cls, field + ".a", 0);
      analyzeIn(cls, field + ".a()", 1);
    }
  }

  public void testParameterAccess() {
    analyze("{ f(int x) { x = 1; } }");
    analyzeFail("{ f(String x) { x = 1; } }",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze("{ f(int x, int y) { x = y; } }");
    analyzeFail("{ f(String x, int y) { x = y; } }",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze("{ f(x, int y) { x = y; } }");
    analyze("{ f(x, int y) { x = y; } }");
    analyzeFail("{ f(String x) { x = 1;} }",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testConditionalExpression() {
    analyze("true ? 1 : 2;");
    analyze("null ? 1 : 2;");
    analyzeFail("0 ? 1 : 2;",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("'' ? 1 : 2;",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("{ int i; true ? i = 2.7 : 2; }",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("{ int i; true ? 2 : i = 2.7; }",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze("{ int i; i = true ? 2.7 : 2; }");
  }

  public void testDoWhileStatement() {
    analyze("do {} while (true);");
    analyze("do {} while (null);");
    analyzeFail("do {} while (0);",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("do {} while ('');",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("do { int i = 0.5; } while (true);",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("do { int i = 0.5; } while (null);",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testForStatement() {
    analyze("for (;true;) {}");
    analyze("for (;null;) {}");
    analyzeFail("for (;0;) {}",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("for (;'';) {}",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testIfStatement() {
    analyze("if (true) {}");
    analyze("if (null) {}");
    analyzeFail("if (0) {}",
    DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("if ('') {}",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("{ int i = 27; if (true) { i = 2.7; } else {} }",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("{ int i = 27; if (true) {} else { i = 2.7; } }",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testWhileStatement() {
    analyze("while (true) {}");
    analyze("while (null) {}");
    analyzeFail("while (0) {}",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("while ('') {}",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testThis() {
    Map<String, ClassElement> classes = loadFile("class_with_supertypes.dart");
    ClassElement superclass = classes.get("Superclass");
    assertNotNull("unable to locate Superclass", superclass);
    ClassElement subclass = classes.get("ClassWithSupertypes");
    assertNotNull("unable to locate ClassWithSupertypes", subclass);
    analyzeIn(superclass, "() { String x = this; }", 1);
    analyzeIn(superclass, "() { var x = this; }", 0);
    analyzeIn(superclass, "() { ClassWithSupertypes x = this; }", 0);
    analyzeIn(superclass, "() { Superclass x = this; }", 0);
    analyzeIn(superclass, "() { Interface x = this; }", 1);
    analyzeIn(subclass, "() { Interface x = this; }", 0);
  }

  public void testMapLiteral() {
    analyze("{ var x = {\"key\": 42}; }");
    analyze("{ var x = {'key': 42}; }");
    analyze("{ var x = <String, num>{'key': 42}; }");
    analyze("{ var x = <String, int>{'key': 42}; }");
    analyze("{ var x = <String, num>{'key': 0.42}; }");
    analyze("{ var x = <Object, num>{'key': 42}; }");
    analyzeFail("{ var x = <String, int>{'key': 0.42}; }",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("{ int i; var x = {'key': i = 0.42}; }",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze("{ var x = const {\"key\": 42}; }");
    analyze("{ var x = const {'key': 42}; }");
    analyze("{ var x = const <String, num>{'key': 42}; }");
    analyze("{ var x = const <String, int>{'key': 42}; }");
    analyze("{ var x = const <String, num>{'key': 0.42}; }");
    analyze("{ var x = const <Object, num>{'key': 42}; }");
    analyzeFail("{ var x = const <String, int>{'key': 0.42}; }",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("{ int i; var x = const {'key': i = 0.42}; }",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("Map<String, int, int> map = {'foo':1};",
      DartCompilerErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS);
    analyzeFail("{var x = const <num, num>{}; }",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testTryCatchFinally() {
    analyze("try { } catch (var _) { } finally { }");
    analyzeFail("try { int i = 4.2; } catch (var _) { } finally { }",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("try { } catch (var _) { int i = 4.2; } finally { }",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("try { } catch (var _) { } finally { int i = 4.2; }",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testUnqualified() {
    ClassElement element = loadClass("class_with_methods.dart", "ClassWithMethods");
    checkAssignIn(element, "var", "intNoArgumentMethod()", 0);
    checkAssignIn(element, "var", "intOneArgumentMethod(1)", 0);
    checkAssignIn(element, "var", "intOneArgumentMethod('')", 1);
    checkAssignIn(element, "int", "intNoArgumentMethod()", 0);
    checkAssignIn(element, "int", "intOneArgumentMethod(1)", 0);
    checkAssignIn(element, "int", "intOneArgumentMethod('')", 1);
    checkAssignIn(element, "String", "intNoArgumentMethod()", 1);
    checkAssignIn(element, "String", "intOneArgumentMethod(1)", 1);
    checkAssignIn(element, "String", "intOneArgumentMethod('')", 2);

    checkAssignIn(element, "var", "functionField()", 0);
    checkAssignIn(element, "int", "functionField()", 0);
    checkAssignIn(element, "String", "functionField()", 0);

    checkAssignIn(element, "var", "functionField(1)", 0);
    checkAssignIn(element, "int", "functionField('x')", 0);
    checkAssignIn(element, "String", "functionField(2.2)", 0);


    checkAssignIn(element, "var", "untypedField()", 0);
    checkAssignIn(element, "int", "untypedField()", 0);
    checkAssignIn(element, "String", "untypedField()", 0);

    checkAssignIn(element, "var", "untypedField(1)", 0);
    checkAssignIn(element, "int", "untypedField('x')", 0);
    checkAssignIn(element, "String", "untypedField(2.2)", 0);

    checkAssignIn(element, "var", "intField()", 1);
    checkAssignIn(element, "int", "intField()", 1);
    checkAssignIn(element, "String", "intField()", 1);

    checkAssignIn(element, "var", "intField(1)", 1);
    checkAssignIn(element, "int", "intField('x')", 1);
    checkAssignIn(element, "String", "intField(2.2)", 1);

    analyzeIn(element, "f(x) { x(); }", 0);
    analyzeIn(element, "f(int x) { x(); }", 1);
    analyzeIn(element, "f(int x()) { int i = x(); }", 0);
    analyzeIn(element, "f(int x(String s)) { int i = x(1); }", 1);
    analyzeIn(element, "f(int x(String s)) { int i = x(''); }", 0);
  }

  public void testUnqualifiedGeneric() {
    ClassElement element = loadClass("generic_class_with_supertypes.dart",
                                     "GenericClassWithSupertypes");

    checkAssignIn(element, "var", "localField", 0);
    checkAssignIn(element, "T1", "localField", 0);
    checkAssignIn(element, "T2", "localField", 1);

    checkAssignIn(element, "var", "superField", 0);
    checkAssignIn(element, "T1", "superField", 1);
    checkAssignIn(element, "T2", "superField", 0);

    checkAssignIn(element, "var", "interfaceField", 0);
    checkAssignIn(element, "T1", "interfaceField", 0);
    checkAssignIn(element, "T2", "interfaceField", 1);

    checkAssignIn(element, "var", "localMethod(t2)", 0);
    checkAssignIn(element, "T1", "localMethod(t2)", 0);
    checkAssignIn(element, "T2", "localMethod(t2)", 1);

    checkAssignIn(element, "var", "superMethod(t1)", 0);
    checkAssignIn(element, "T1", "superMethod(t1)", 1);
    checkAssignIn(element, "T2", "superMethod(t1)", 0);

    checkAssignIn(element, "var", "interfaceMethod(t1)", 0);
    checkAssignIn(element, "T1", "interfaceMethod(t1)", 0);
    checkAssignIn(element, "T2", "interfaceMethod(t1)", 1);
  }

  public void testSuper() {
    ClassElement sub = loadClass("covariant_class.dart", "Sub");
    checkAssignIn(sub, "B", "field", 0);
    checkAssignIn(sub, "C", "field", 1);
    checkAssignIn(sub, "D", "field", 1);

    checkAssignIn(sub, "B", "super.field", 0);
    checkAssignIn(sub, "C", "super.field", 0);
    checkAssignIn(sub, "D", "super.field", 1);

    checkAssignIn(sub, "B", "accessor", 0);
    checkAssignIn(sub, "C", "accessor", 1);
    checkAssignIn(sub, "D", "accessor", 1);

    checkAssignIn(sub, "B", "super.accessor", 0);
    checkAssignIn(sub, "C", "super.accessor", 0);
    checkAssignIn(sub, "D", "super.accessor", 1);

    analyzeIn(sub, "accessor = b", 0);
    analyzeIn(sub, "accessor = c", 1);
    analyzeIn(sub, "accessor = d", 1);

    analyzeIn(sub, "super.accessor = b", 0);
    analyzeIn(sub, "super.accessor = c", 0);
    analyzeIn(sub, "super.accessor = d", 1);

    checkAssignIn(sub, "B", "method()", 0);
    checkAssignIn(sub, "C", "method()", 1);
    checkAssignIn(sub, "D", "method()", 1);

    checkAssignIn(sub, "B", "super.untypedMethod()", 0);
    checkAssignIn(sub, "C", "super.untypedMethod()", 0);
    checkAssignIn(sub, "D", "super.untypedMethod()", 0);

    checkAssignIn(sub, "B", "super.untypedField", 0);
    checkAssignIn(sub, "C", "super.untypedField", 0);
    checkAssignIn(sub, "D", "super.untypedField", 0);

    checkAssignIn(sub, "B", "super.untypedAccessor", 0);
    checkAssignIn(sub, "C", "super.untypedAccessor", 0);
    checkAssignIn(sub, "D", "super.untypedAccessor", 0);

    analyzeIn(sub, "super.untypedAccessor = b", 0);
    analyzeIn(sub, "super.untypedAccessor = c", 0);
    analyzeIn(sub, "super.untypedAccessor = d", 0);

    checkAssignIn(sub, "B", "super.untypedMethod()", 0);
    checkAssignIn(sub, "C", "super.untypedMethod()", 0);
    checkAssignIn(sub, "D", "super.untypedMethod()", 0);
  }

  public void testSwitch() {
    analyze("{ int i = 27; switch(i) { case i: break; } }");
    analyze("{ num i = 27; switch(i) { case i: break; } }");
    analyze("{ switch(true) { case 1: break; case 'foo': break; }}");
    analyzeFail("{ int i = 27; switch(true) { case false: i = 2.7; }}",
      DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testConstructorForwarding() {
    Map<String, ClassElement> classes = loadSource(
        "class MissingArgument {",
        "  MissingArgument() : this.bar() {}",
        "  MissingArgument.bar(int i) {}",
        "}",
        "class IntArgument {",
        "  IntArgument() : this.bar(1) {}",
        "  IntArgument.bar(int i) {}",
        "}",
        "class ExtraIntArgument {",
        "  ExtraIntArgument() : this.bar(1, 1) {}",
        "  ExtraIntArgument.bar(int i) {}",
        "}",
        "class StringArgument {",
        "  StringArgument() : this.bar('') {}",
        "  StringArgument.bar(int i) {}",
        "}",
        "class NullArgument {",
        "  NullArgument() : this.bar(null) {}",
        "  NullArgument.bar(int i) {}",
        "}",
        "class OptionalParameter {",
        "  OptionalParameter() : this.bar() {}",
        "  OptionalParameter.bar([int i = null]) {}",
        "  OptionalParameter.foo() : this.bar('') {}",
        "}");
    analyzeClass(classes.get("MissingArgument"), 1);
    analyzeClass(classes.get("IntArgument"), 0);
    analyzeClass(classes.get("ExtraIntArgument"), 1);
    analyzeClass(classes.get("StringArgument"), 1);
    analyzeClass(classes.get("NullArgument"), 0);
    analyzeClass(classes.get("OptionalParameter"), 1);
  }

  public void testSuperConstructorInvocation() {
    Map<String, ClassElement> classes = loadSource(
        "class Super {",
        "  Super(int x) {}",
        "  Super.foo() {}",
        "  Super.bar([int i = null]) {}",
        "}",
        "class BadSub extends Super {",
        "  BadSub() : super('x') {}",
        "  BadSub.foo() : super.foo('x') {}",
        "  BadSub.bar() : super() {}",
        "  BadSub.baz() : super.foo(null) {}",
        "  BadSub.fisk() : super.bar('') {}",
        "  BadSub.hest() : super.bar(1, 2) {}",
        "}",
        "class NullSub extends Super {",
        "  NullSub() : super(null) {}",
        "  NullSub.foo() : super.bar(null) {}",
        "  NullSub.bar() : super.bar() {}",
        "}",
        "class IntSub extends Super {",
        "  IntSub() : super(1) {}",
        "  IntSub.foo() : super.bar(1) {}",
        "}",
        // The following works fine, but was claimed to be a bug:
        "class A {",
        "  int value;",
        "  A([this.value = 3]) {}",
        "}",
        "class B extends A {",
        "  B() : super() {}",
        "}");
    analyzeClass(classes.get("Super"), 0);
    analyzeClass(classes.get("BadSub"), 6);
    analyzeClass(classes.get("NullSub"), 0);
    analyzeClass(classes.get("IntSub"), 0);
    analyzeClass(classes.get("A"), 0);
    analyzeClass(classes.get("B"), 0);
  }

  public void testNewExpression() {
    analyzeClasses(loadSource(
        "class Foo {",
        "  Foo(int x) {}",
        "  Foo.foo() {}",
        "  Foo.bar([int i = null]) {}",
        "}",
        "interface Bar<T> factory Baz {",
        "  Bar.make();",
        "}",
        "class Baz {",
        "  factory Bar<S>.make(S x) { return null; }",
        "}"));

    analyze("Foo x = new Foo(0);");
    analyzeFail("Foo x = new Foo();", DartCompilerErrorCode.MISSING_ARGUMENT);
    analyzeFail("Foo x = new Foo('');", DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("Foo x = new Foo(0, null);", DartCompilerErrorCode.EXTRA_ARGUMENT);

    analyze("Foo x = new Foo.foo();");
    analyzeFail("Foo x = new Foo.foo(null);", DartCompilerErrorCode.EXTRA_ARGUMENT);

    analyze("Foo x = new Foo.bar();");
    analyze("Foo x = new Foo.bar(0);");
    analyzeFail("Foo x = new Foo.bar('');", DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("Foo x = new Foo.bar(0, null);", DartCompilerErrorCode.EXTRA_ARGUMENT);

    analyze("Bar<String> x = new Bar<String>.make('');");
  }

  public void testFactory() {
    analyzeClasses(loadSource(
        "interface Foo factory Bar {",
        "  Foo(argument);",
        "}",
        "interface Baz {}",
        "class Bar implements Foo, Baz {",
        "  Bar(String argument) {}",
        "}"));

    analyzeFail("Baz x = new Foo('');", DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testFunctionTypeAlias() {
    Map<String, ClassElement> classes = loadSource(
        "typedef void VoidFunction();",
        "typedef String StringFunction();",
        "typedef String IntToStringFunction(int i);",
        "class Foo {",
        "  VoidFunction voidFunction;",
        "  StringFunction stringFunction;",
        "  IntToStringFunction intToStringFunction;",
        "  Foo foo;",
        "  String string;",
        "  int i;",
        "}");
    analyzeClasses(classes);
    ClassElement foo = classes.get("Foo");
    analyzeIn(foo, "voidFunction()", 0);
    analyzeIn(foo, "voidFunction(1)", 1);
    analyzeIn(foo, "this.voidFunction()", 0);
    analyzeIn(foo, "this.voidFunction(1)", 1);
    analyzeIn(foo, "foo.voidFunction()", 0);
    analyzeIn(foo, "foo.voidFunction(1)", 1);
    analyzeIn(foo, "(voidFunction)()", 0);
    analyzeIn(foo, "(voidFunction)(1)", 1);
    analyzeIn(foo, "(this.voidFunction)()", 0);
    analyzeIn(foo, "(this.voidFunction)(1)", 1);
    analyzeIn(foo, "(foo.voidFunction)()", 0);
    analyzeIn(foo, "(foo.voidFunction)(1)", 1);

    analyzeIn(foo, "string = stringFunction()", 0);
    analyzeIn(foo, "i = stringFunction()", 1);
    analyzeIn(foo, "string = this.stringFunction()", 0);
    analyzeIn(foo, "i = this.stringFunction()", 1);
    analyzeIn(foo, "string = foo.stringFunction()", 0);
    analyzeIn(foo, "i = foo.stringFunction()", 1);
    analyzeIn(foo, "string = (stringFunction)()", 0);
    analyzeIn(foo, "i = (stringFunction)()", 1);
    analyzeIn(foo, "string = (this.stringFunction)()", 0);
    analyzeIn(foo, "i = (this.stringFunction)()", 1);
    analyzeIn(foo, "string = (foo.stringFunction)()", 0);
    analyzeIn(foo, "i = (foo.stringFunction)()", 1);

    analyzeIn(foo, "voidFunction = stringFunction", 0);
    analyzeIn(foo, "stringFunction = intToStringFunction", 1);
    analyzeIn(foo, "stringFunction = String foo() { return ''; }", 0);
    analyzeIn(foo, "intToStringFunction = String foo() { return ''; }", 1);
  }

  public void testVoid() {
    // Return a value from a void function.
    analyze("void f() { return; }");
    analyzeFail("void f() { return null; }", DartCompilerErrorCode.VOID_CANNOT_RETURN_VALUE);
    analyzeFail("void f() { return f(); }", DartCompilerErrorCode.VOID_CANNOT_RETURN_VALUE);
    analyzeFail("void f() { return 1; }", DartCompilerErrorCode.VOID_CANNOT_RETURN_VALUE);
    analyzeFail("void f() { var x; return x; }", DartCompilerErrorCode.VOID_CANNOT_RETURN_VALUE);

    // No-arg return from non-void function.
    analyzeFail("int f() { return; }", DartCompilerErrorCode.MISSING_RETURN_VALUE);
    analyze("f() { return; }");

    // Calling a method on a void expression, property access.
    analyzeFail("void f() { f().m(); }", DartCompilerErrorCode.VOID);
    analyzeFail("void f() { f().x; }", DartCompilerErrorCode.VOID);

    // Passing a void argument to a method.
    analyzeFail("{ void f() {} m(x) {} m(f()); }", DartCompilerErrorCode.VOID);

    // Assigning a void expression to a variable.
    analyzeFail("{ void f() {} String x = f(); }", DartCompilerErrorCode.VOID);
    analyzeFail("{ void f() {} String x; x = f(); }", DartCompilerErrorCode.VOID);
    analyzeFail("{ void f() {} String x; x += f(); }", DartCompilerErrorCode.VOID);

    // Misc.
    analyzeFail("{ void f() {} 1 + f(); }", DartCompilerErrorCode.VOID);
    analyzeFail("{ void f() {} f() + 1; }", DartCompilerErrorCode.VOID);
    analyzeFail("{ void f() {} var x; x && f(); }", DartCompilerErrorCode.VOID);
    analyzeFail("{ void f() {} !f(); }", DartCompilerErrorCode.VOID);
    analyzeFail("{ void f() {} -f(); }", DartCompilerErrorCode.VOID);
    // We seem to throw away prefix-plus in the parser:
    // analyzeFail("{ void f() {} +f(); }", DartCompilerErrorCode.VOID);
    analyzeFail("{ void f() {} var x; x == f(); }", DartCompilerErrorCode.VOID);
    analyzeFail("{ void f() {} assert(f()); }", DartCompilerErrorCode.VOID);
    analyzeFail("{ void f() {} assert(f); }", DartCompilerErrorCode.VOID);
    analyzeFail("{ void f() {} while (f()); }", DartCompilerErrorCode.VOID);
    analyzeFail("{ void f() {} ({ 'x': f() }); }", DartCompilerErrorCode.VOID);
  }

  public void testFieldInitializers() {
    Map<String, ClassElement> classes = loadSource(
        "class Good {",
        "  String string;",
        "  int i;",
        "  Good() : string = '', i = 1;",
        "  Good.name() : string = null, i = null;",
        "  Good.untyped(x) : string = x, i = x;",
        "  Good.string(String s) : string = s, i = 0;",
        "}",
        "class Bad {",
        "  String string;",
        "  int i;",
        "  Bad() : string = 1, i = '';",
        "  Bad.string(String s) : string = s, i = s;",
        "}");
    analyzeClass(classes.get("Good"), 0);
    analyzeClass(classes.get("Bad"), 3);
  }

  public void testArrayLiteral() {
    analyze("['x'];");
    analyze("<String>['x'];");
    analyzeFail("<int>['x'];", DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("<String>['x', 1];", DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze("Array<String> strings = ['x'];");
    analyze("Array<String> strings = <String>['x'];");
    analyze("Array array = ['x'];");
    analyze("Array array = <String>['x'];");
    analyze("Array<int> ints = ['x'];");
    analyzeFail("Array<int> ints = <String>['x'];",
                DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("Array<int, int> ints = [1];",
      DartCompilerErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS);
  }

  public void testInitializedLocals() {
    analyze("void f([int x = 1]) {}");
    analyzeFail("void f([int x = '']) {}", DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);

    analyze("{ int x = 1; }");
    analyzeFail("{ int x = ''; }", DartCompilerErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testInitializedFields() {
    Map<String, ClassElement> classes = loadSource(
        "class GoodField {",
        "  static final int i = 1;",
        "}",
        "class BadField {",
        "  static final int i = '';",
        "}");
    analyzeClass(classes.get("GoodField"), 0);
    analyzeClass(classes.get("BadField"), 1);
  }

  public void testGetAllSupertypes()
      throws CyclicDeclarationException, DuplicatedInterfaceException {
    Map<String, ClassElement> classes = loadSource(
        "class A extends B<String> {",
        "}",
        "class B<T> extends C<G<T>> implements I<int>, I1<T> {",
        "}",
        "class C<U> {",
        "}",
        "interface I<S> extends I2<bool> {",
        "}",
        "class G<V> {",
        "}",
        "interface I1<W> {",
        "}",
        "interface I2<X> {",
        "}",
        "class D implements I2<int> {",
        "}",
        "class E extends D implements I2<int> {",
        "}");
    analyzeClasses(classes);
    assertEquals("[]", object.getAllSupertypes().toString());
    assertEquals("[I<int>, I1<String>, I2<bool>, B<String>, C<G<String>>, Object]",
                 classes.get("A").getAllSupertypes().toString());
    assertEquals("[I<int>, I1<B.T>, I2<bool>, C<G<B.T>>, Object]",
                 classes.get("B").getAllSupertypes().toString());
    assertEquals("[Object]", classes.get("C").getAllSupertypes().toString());
    assertEquals("[I2<bool>, Object]", classes.get("I").getAllSupertypes().toString());
    assertEquals("[Object]", classes.get("G").getAllSupertypes().toString());
    assertEquals("[Object]", classes.get("I1").getAllSupertypes().toString());
    assertEquals("[Object]", classes.get("I2").getAllSupertypes().toString());
    assertEquals("[I2<int>, Object]", classes.get("D").getAllSupertypes().toString());
    assertEquals("[I2<int>, D, Object]", classes.get("E").getAllSupertypes().toString());
  }

  public void testParameterInitializers() {
    Map<String, ClassElement> classes = loadSource(
        "class C1 { int i; C1(this.i) {} }",
        "class C2 { String s; C2(int this.s) {} }",
        "class C3 { int i; C3(double this.i) {} }",
        "class C4 { int i; C4(num this.i) {} }");
    analyzeClass(classes.get("C1"), 0);
    analyzeClass(classes.get("C2"), 1);
    analyzeClass(classes.get("C3"), 1);
    analyzeClass(classes.get("C4"), 0);
  }

  public void testImplementsAndOverrides() {
    analyzeClasses(loadSource(
        "interface Interface {",
        "  void foo();",
        "  void bar();",
        "}",
        // Abstract class not reported until first instantiation.
        "class Class implements Interface {",
        "  Class() {}",
        "  String bar() { return null; }",
        "}",
        // Abstract class not reported until first instantiation.
        "class SubClass extends Class {",
        "  SubClass() : super() {}",
        "  Object bar() { return null; }",
        "}",
        "class SubSubClass extends Class {",
        "  num bar() { return null; }", // TYPE_NOT_ASSIGNMENT_COMPATIBLE.
        "  void foo([x = null]) {}", // TYPE_NOT_ASSIGNMENT_COMPATIBLE.
        "}",
        "class Usage {",
        "  m() {",
        "    new Class();", // CANNOT_INSTATIATE_ABSTRACT_CLASS
                            // ABSTRACT_CLASS.
        "    new Class();", // CANNOT_INSTATIATE_ABSTRACT_CLASS.
        "    new SubClass();", // CANNOT_INSTATIATE_ABSTRACT_CLASS
                               //ABSTRACT_CLASS.
        "  }",
        "}"),
        DartCompilerErrorCode.CANNOT_OVERRIDE_TYPED_MEMBER,
        DartCompilerErrorCode.CANNOT_OVERRIDE_TYPED_MEMBER,
        DartCompilerErrorCode.CANNOT_INSTATIATE_ABSTRACT_CLASS,
        DartCompilerErrorCode.ABSTRACT_CLASS,
        DartCompilerErrorCode.CANNOT_INSTATIATE_ABSTRACT_CLASS,
        DartCompilerErrorCode.CANNOT_INSTATIATE_ABSTRACT_CLASS,
        DartCompilerErrorCode.ABSTRACT_CLASS);
  }

  public void testOddStuff() {
    Map<String, ClassElement> classes = analyzeClasses(loadSource(
        "class Class {",
        "  Class() {}",
        "  var field;",
        "  void m() {}",
        "  static void f() {}",
        "  static g(int i) {}",
        "}"));
    ClassElement cls = classes.get("Class");
    analyzeIn(cls, "m().foo()", 1);
    analyzeIn(cls, "m().x", 1);
    analyzeIn(cls, "m()", 0);
    analyzeIn(cls, "(m)().foo()", 1);
    analyzeIn(cls, "(m)().x", 1);
    analyzeIn(cls, "(m)()", 0);
    analyzeIn(cls, "field = m()", 1);
    analyzeIn(cls, "field = Class.f()", 1);
    analyzeIn(cls, "field = (Class.f)()", 1);
    analyzeIn(cls, "Class.f()", 0);
    analyzeIn(cls, "(Class.f)()", 0);
    analyzeIn(cls, "field = Class.g('x')", 1);
    analyzeIn(cls, "field = (Class.g)('x')", 1);
    analyzeIn(cls, "field = Class.g(0)", 0);
    analyzeIn(cls, "field = (Class.g)(0)", 0);
    analyzeFail("fisk: while (true) fisk++;", DartCompilerErrorCode.CANNOT_BE_RESOLVED);
    analyzeFail("new Class().m().x;", DartCompilerErrorCode.VOID);
    analyzeFail("(new Class().m)().x;", DartCompilerErrorCode.VOID);
  }

  private Map<String, ClassElement> analyzeClasses(Map<String, ClassElement> classes,
                                                   ErrorCode... codes) {
    setExpectedTypeErrorCount(codes.length);
    for (ClassElement cls : classes.values()) {
      analyzeToplevel(cls.getNode());
    }
    List<ErrorCode> errorCodes = context.getErrorCodes();
    assertEquals(Arrays.toString(codes), errorCodes.toString());
    errorCodes.clear();
    checkExpectedTypeErrorCount();
    return classes;
  }

  private Type checkAssignIn(ClassElement element, String type, String expression, int errorCount) {
    return analyzeIn(element, assign(type, expression), errorCount);
  }

  private String assign(String type, String expression) {
    return String.format("void foo() { %s x = %s; }", type, expression);
  }

  private ClassElement loadClass(String file, String name) {
    ClassElement cls = loadFile(file).get(name);
    assertNotNull("unable to locate " + name, cls);
    return cls;
  }

  private String returnWithType(String type, Object expression) {
    return String.format("%s foo() { return %s; }", type, String.valueOf(expression));
  }

  private Map<String, ClassElement> loadFile(final String name) {
    String source = getResource(name);
    return loadSource(source);
  }

  private Map<String, ClassElement> loadSource(String firstLine, String secondLine,
                                               String... rest) {
    return loadSource(Joiner.on('\n').join(firstLine, secondLine, (Object[]) rest).toString());
  }

  private Map<String, ClassElement> loadSource(String source) {
    Map<String, ClassElement> classes = new LinkedHashMap<String, ClassElement>();
    DartUnit unit = parseUnit(source);
    TopLevelElementBuilder elementBuilder = new TopLevelElementBuilder();
    elementBuilder.exec(unit, context);
    for (DartNode node : unit.getTopLevelNodes()) {
      if (node instanceof DartClass) {
        DartClass classNode = (DartClass) node;
        final ClassElement classElement = classNode.getSymbol();
        String className = classElement.getName();
        coreElements.put(className, classElement);
        classes.put(className, classElement);
      } else {
        DartFunctionTypeAlias alias = (DartFunctionTypeAlias) node;
        FunctionAliasElement element = alias.getSymbol();
        coreElements.put(element.getName(), element);
      }
    }
    Scope scope = getMockScope("<test toplevel>");
    SupertypeResolver supertypeResolver = new SupertypeResolver();
    supertypeResolver.exec(unit, context, scope, typeProvider);
    MemberBuilder memberBuilder = new MemberBuilder();
    memberBuilder.exec(unit, context, scope, typeProvider);
    resolver.exec(unit);
    return classes;
  }

  private String getResource(String name) {
    String packageName = getClass().getPackage().getName().replace('.', '/');
    String resouceName = packageName + "/" + name;
    InputStream stream = getClass().getClassLoader().getResourceAsStream(resouceName);
    if (stream == null) {
      throw new AssertionError("Missing resource: " + resouceName);
    }
    InputStreamReader reader = new InputStreamReader(stream);
    try {
      return CharStreams.toString(reader); // Also closes the reader.
    } catch (IOException e) {
      throw new IOError(e);
    }
  }

  private void analyzeFail(String statement, DartCompilerErrorCode errorCode) {
    try {
      analyze(statement);
      fail("Test unexpectedly passed.  Expected ErrorCode: " + errorCode.name());
    } catch (TestTypeError error) {
      assertEquals(errorCode, error.getErrorCode());
    }
  }

  private void checkSimpleType(Type type, String expression) {
    assertSame(type, typeOf(expression));
    setExpectedTypeErrorCount(1); // x is unresolved.
    assertSame(type, typeOf("x = " + expression));
    checkExpectedTypeErrorCount();
  }

  private void checkType(Type type, String expression) {
    assertEquals(type, typeOf(expression));
    assertEquals(type, typeOf("x = " + expression));
  }

  private Type typeOf(String expression) {
    return analyzeNode(parseExpression(expression));
  }

  private DartStatement analyze(String statement) {
    DartStatement node = parseStatement(statement);
    analyzeNode(node);
    return node;
  }

  private Type analyzeIn(ClassElement element, String expression, int expectedErrorCount) {
    DartExpression node = parseExpression(expression);
    ResolutionContext resolutionContext =
        new ResolutionContext(getMockScope("<test expression>"), context,
                              typeProvider).extend(element);
    ResolveElementsVisitor visitor =
        resolver.new ResolveElementsVisitor(resolutionContext, element,
                                            Elements.methodElement(null, null));
    setExpectedTypeErrorCount(expectedErrorCount);
    node.accept(visitor);
    Type type = node.accept(makeTypeAnalyzer(element));
    checkExpectedTypeErrorCount(expression);
    return type;
  }

  private Type analyzeNode(DartNode node) {
    ResolutionContext resolutionContext =
        new ResolutionContext(getMockScope("<test node>"), context, typeProvider);
    ResolveElementsVisitor visitor =
        resolver.new ResolveElementsVisitor(resolutionContext, null,
                                            Elements.methodElement(null, null));
    node.accept(visitor);
    return node.accept(makeTypeAnalyzer(Elements.dynamicElement()));
  }

  private Type analyzeToplevel(DartNode node) {
    return node.accept(makeTypeAnalyzer(Elements.dynamicElement()));
  }

  private ClassElement analyzeClass(ClassElement cls, int count) {
    setExpectedTypeErrorCount(count);
    analyzeToplevel(cls.getNode());
    checkExpectedTypeErrorCount(cls.getName());
    return cls;
  }

  private DartParser getParser(String string) {
    return new DartParser(new DartScannerParserContext(null, string, listener));
  }

  private DartExpression parseExpression(String source) {
    return getParser(source).parseExpression();
  }

  private DartStatement parseStatement(String source) {
    return getParser(source).parseStatement();
  }

  private DartUnit parseUnit(String string) {
    DartSourceString source = new DartSourceString("<source string>", string);
    return getParser(string).parseUnit(source);
  }

  private class MockScope extends Scope {
    private MockScope() {
      super("test mock scope", null);
    }

    @Override
    public Element findLocalElement(String name) {
      return coreElements.get(name);
    }

  }

  private Scope getMockScope(String name) {
    return new Scope(name, null, new MockScope());
  }

  private class MockCoreTypeProvider implements CoreTypeProvider {
    private final Type voidType = Types.newVoidType();
    private final DynamicType dynamicType = Types.newDynamicType();

    @Override
    public InterfaceType getIntType() {
      return intElement.getType();
    }

    @Override
    public InterfaceType getDoubleType() {
      return doubleElement.getType();
    }

    @Override
    public InterfaceType getBoolType() {
      return bool.getType();
    }

    @Override
    public InterfaceType getStringType() {
      return string.getType();
    }

    @Override
    public InterfaceType getFunctionType() {
      return function.getType();
    }

    @Override
    public InterfaceType getArrayType(Type elementType) {
      return array.getType().subst(Arrays.asList(elementType), array.getTypeParameters());
    }

    @Override
    public Type getNullType() {
      return getDynamicType();
    }

    @Override
    public Type getVoidType() {
      return voidType;
    }

    @Override
    public DynamicType getDynamicType() {
      return dynamicType;
    }

    @Override
    public InterfaceType getFallThroughError() {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getMapType(Type key, Type value) {
      InterfaceType mapType = map.getType();
      return mapType.subst(Arrays.asList(key, value),
                           mapType.getElement().getTypeParameters());
    }

    @Override
    public InterfaceType getObjectArrayType() {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getObjectType() {
      return object.getType();
    }

    @Override
    public InterfaceType getNumType() {
      return number.getType();
    }

    @Override
    public InterfaceType getArrayLiteralType(Type value) {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getMapLiteralType(Type key, Type value) {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getStringImplementationType() {
      throw new AssertionError();
    }

    @Override
    public InterfaceType getIsolateType() {
      throw new AssertionError();
    }
  }
}
