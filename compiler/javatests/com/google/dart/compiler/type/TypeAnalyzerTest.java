// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.dart.compiler.parser.Token;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.ClassNodeElement;
import com.google.dart.compiler.resolver.CyclicDeclarationException;
import com.google.dart.compiler.resolver.TypeErrorCode;

import java.util.EnumSet;
import java.util.Map;

/**
 * Test of static type analysis. This is mostly a test of {@link TypeAnalyzer}, but this test also
 * exercises code in com.google.dart.compiler.resolver.
 */
public class TypeAnalyzerTest extends TypeAnalyzerTestCase {

  /**
   * There  was problem that cyclic class declaration caused infinite loop.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=348
   */
  public void test_cyclicDeclaration() {
    Map<String, ClassNodeElement> source = loadSource(
        "class Foo extends Bar {",
        "}",
        "class Bar extends Foo {",
        "}");
    analyzeClasses(source);
    // Foo and Bar have cyclic declaration
    ClassElement classFoo = source.get("Foo");
    ClassElement classBar = source.get("Bar");
    assertEquals(classFoo, classBar.getSupertype().getElement());
    assertEquals(classBar, classFoo.getSupertype().getElement());
  }

  public void test_operator_indexAssign() {
    Map<String, ClassNodeElement> source = loadSource(
        "class A {",
        "int operator []=(int index, var value) {}",
        "}");
    analyzeClasses(source, TypeErrorCode.OPERATOR_INDEX_ASSIGN_VOID_RETURN_TYPE);
  }

  public void testArrayLiteral() {
    analyze("['x'];");
    analyze("<String>['x'];");
    analyzeFail("<int>['x'];", TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("<String>['x', 1];", TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze("List<String> strings = ['x'];");
    analyze("List<String> strings = <String>['x'];");
    analyze("List array = ['x'];");
    analyze("List array = <String>['x'];");
    analyzeFail("List<int> ints = ['x'];", TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("List<int> ints = <String>['x'];", TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testBadInitializers() {
    analyzeFail("int i = .0;", TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("int j = 1.0;", TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
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

    EnumSet<Token> userOperators = EnumSet.of(Token.ADD,
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
      if (!op.equals(Token.ADD)) {
        expression = String.format("o %s s", op.getSyntax());
        analyzeIn(cls, expression, 1);
      }
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
                   Token.ASSIGN_TRUNC);

    for (Token op : compoundAssignmentOperators) {
      String expression;
      expression = String.format("o %s untyped", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("o %s null", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("o %s o", op.getSyntax());
      analyzeIn(cls, expression, 0);
      expression = String.format("o %s i", op.getSyntax());
      analyzeIn(cls, expression, 1);
      if (!op.equals(Token.ASSIGN_ADD)) {
        expression = String.format("s %s untyped", op.getSyntax());
        analyzeIn(cls, expression, 1);
        expression = String.format("s %s null", op.getSyntax());
        analyzeIn(cls, expression, 1);
        expression = String.format("s %s o", op.getSyntax());
        analyzeIn(cls, expression, 1);
      }
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

    analyzeFail("1 == !'s';", TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testBitOperators() {
    Map<String, ClassNodeElement> source = loadSource(
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

  public void testConditionalExpression() {
    analyze("true ? 1 : 2;");
    analyze("null ? 1 : 2;");
    analyzeFail("0 ? 1 : 2;",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("'' ? 1 : 2;",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("{ int i; true ? i = 2.7 : 2; }",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("{ int i; true ? 2 : i = 2.7; }",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze("{ int i; i = true ? 2.7 : 2; }");
  }

  public void testConstructorForwarding() {
    Map<String, ClassNodeElement> classes = loadSource(
        "class MissingArgument {",
        "  MissingArgument() : this.bar();",
        "  MissingArgument.bar(int i) {}",
        "}",
        "class IntArgument {",
        "  IntArgument() : this.bar(1);",
        "  IntArgument.bar(int i) {}",
        "}",
        "class ExtraIntArgument {",
        "  ExtraIntArgument() : this.bar(1, 1);",
        "  ExtraIntArgument.bar(int i) {}",
        "}",
        "class StringArgument {",
        "  StringArgument() : this.bar('');",
        "  StringArgument.bar(int i) {}",
        "}",
        "class NullArgument {",
        "  NullArgument() : this.bar(null);",
        "  NullArgument.bar(int i) {}",
        "}",
        "class OptionalParameter {",
        "  OptionalParameter() : this.bar();",
        "  OptionalParameter.bar([int i = null]) {}",
        "  OptionalParameter.foo() : this.bar('');",
        "}");
    analyzeClass(classes.get("MissingArgument"), 1);
    analyzeClass(classes.get("IntArgument"), 0);
    analyzeClass(classes.get("ExtraIntArgument"), 1);
    analyzeClass(classes.get("StringArgument"), 1);
    analyzeClass(classes.get("NullArgument"), 0);
    analyzeClass(classes.get("OptionalParameter"), 1);
  }

  public void testCyclicTypeVariable() {
    Map<String, ClassNodeElement> classes = loadSource(
        "interface A<T> { }",
        "typedef funcType<T>(T arg);",
        "class B<T extends T> {}",
        "class C<T extends A<T>> {}",
        "class D<T extends funcType<T>> {}");
    analyzeClasses(classes,
        TypeErrorCode.CYCLIC_REFERENCE_TO_TYPE_VARIABLE);
    ClassNodeElement B = classes.get("B");
    analyzeClass(B, 1);
    assertEquals(1, B.getType().getArguments().size());
    ClassNodeElement C = classes.get("C");
    analyzeClass(C, 0);
    assertEquals(1, C.getType().getArguments().size());
    ClassNodeElement D = classes.get("D");
    analyzeClass(D, 0);
    assertEquals(1, D.getType().getArguments().size());

  }

  public void testDoWhileStatement() {
    analyze("do {} while (true);");
    analyze("do {} while (null);");
    analyzeFail("do {} while (0);",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("do {} while ('');",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("do { int i = 0.5; } while (true);",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("do { int i = 0.5; } while (null);",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testFactory() {
    analyzeClasses(loadSource(
        "interface Foo default Bar {",
        "  Foo(String argument);",
        "}",
        "interface Baz {}",
        "class Bar implements Foo, Baz {",
        "  Bar(String argument) {}",
        "}"));
    analyzeFail("Baz x = new Foo('');", TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
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

    analyzeIn(element, "new ClassWithSupertypes()", 1); // Abstract class.
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

  public void testFieldInitializers() {
    Map<String, ClassNodeElement> classes = loadSource(
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

  public void testForEachStatement() {
    Map<String, ClassNodeElement> invalidReturnType = loadSource(
        "class A {",
        "  Iterator<int> iterator() {}",
        "}",
        "class B {",
        "  main() { for (int i in new A()) {}}",
        "}");
    analyzeClasses(invalidReturnType);
  }

  public void testForEachStatement_Negative1() {
    Map<String, ClassNodeElement> fieldNotMethod = loadSource(
        "class A {",
        "  int iterator;",
        "}",
        "class B {",
        "  main() { for (int i in new A()) {}}",
        "}");
    analyzeClasses(fieldNotMethod, TypeErrorCode.FOR_IN_WITH_ITERATOR_FIELD);
  }

  public void testForEachStatement_Negative2() {
    Map<String, ClassNodeElement> invalidReturnType = loadSource(
        "class A {",
        "  int iterator() {}",
        "}",
        "class B {",
        "  main() { for (int i in new A()) {}}",
        "}");
    analyzeClasses(invalidReturnType, TypeErrorCode.FOR_IN_WITH_INVALID_ITERATOR_RETURN_TYPE);
  }


  public void testForStatement() {
    analyze("for (;true;) {}");
    analyze("for (;null;) {}");
    analyzeFail("for (;0;) {}",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("for (;'';) {}",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);

    // Foreach tests
    analyze("{ List<String> strings = ['1','2','3']; for (String s in strings) {} }");
    analyzeFail("{ List<int> ints = [1,2,3]; for (String s in ints) {} }",
        TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("for (String s in true) {}", TypeErrorCode.INTERFACE_HAS_NO_METHOD_NAMED);
  }

  public void testFunctionObjectLiterals() {
    analyze("{ bool b = foo() {}(); }");
    analyze("{ int i = foo() {}(); }");
    analyze("{ bool b = bool foo() { return null; }(); }");
    analyze("{ int i = int foo() { return null; }(); }");
    analyzeFail("{ int i = bool foo() { return null; }(); }",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze("{ int i = Object _(Object x) { return x; }('fisk'); }");
    analyzeFail("{ int i = String _(Object x) { return x; }(1); }",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze("Function f = foo() {};");
  }

  public void testFunctionTypeAlias() {
    Map<String, ClassNodeElement> classes = loadSource(
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

  public void testFunctionTypes() {
    checkFunctionStatement("String foo() {};", "() -> String");
    checkFunctionStatement("Object foo() {};", "() -> Object");
    checkFunctionStatement("String foo(int i, bool b) {};", "(int, bool) -> String");
  }

  public void testGetAllSupertypes()
      throws CyclicDeclarationException {
    Map<String, ClassNodeElement> classes = loadSource(
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

  public void testIdentifiers() {
    analyze("{ int i; i = 2; }");
    analyze("{ int j, k; j = 1; k = 3; }");
    analyzeFail("{ int i; i = 'string'; }", TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("{ int j, k; k = 'string'; }",
        TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("{ int j, k; j = 'string'; }",
        TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testIfStatement() {
    analyze("if (true) {}");
    analyze("if (null) {}");
    analyzeFail("if (0) {}",
    TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("if ('') {}",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("{ int i = 27; if (true) { i = 2.7; } else {} }",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("{ int i = 27; if (true) {} else { i = 2.7; } }",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testImplementsAndOverrides() {
    analyzeClasses(loadSource(
        "interface Interface {",
        "  void foo(int x);",
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
        "  num bar() { return null; }", // CANNOT_OVERRIDE_METHOD_NOT_SUBTYPE
        "  void foo(String x) {}", // CANNOT_OVERRIDE_METHOD_NOT_SUBTYPE
        "}",
        "class Usage {",
        "  m() {",
        "  }",
        "}"),
        TypeErrorCode.CANNOT_OVERRIDE_METHOD_NOT_SUBTYPE,
        TypeErrorCode.CANNOT_OVERRIDE_METHOD_NOT_SUBTYPE);
  }

  public void testImplementsAndOverrides2() {
    analyzeClasses(loadSource(
        "interface Interface {",
        "  void foo(int x);",
        "}",
        // Abstract class not reported until first instantiation.
        "class Class implements Interface {",
        "  Class() {}",
        "  void foo(String x) {}", // CANNOT_OVERRIDE_METHOD_NOT_SUBTYPE
        "}"),
        TypeErrorCode.CANNOT_OVERRIDE_METHOD_NOT_SUBTYPE);
  }

  public void testInitializedFields() {
    Map<String, ClassNodeElement> classes = loadSource(
        "class GoodField {",
        "  static final int i = 1;",
        "}");
    analyzeClass(classes.get("GoodField"), 0);

    // Note, the TypeAnalyzer doesn't get a chance
    // to get its hands on bad initializers anymore
    // due to type checking in CompileTimeConstVisitor.
  }

  public void testInitializedLocals() {
    analyze("void f([int x = 1]) {}");
    analyzeFail("void f([int x = '']) {}", TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);

    analyze("{ int x = 1; }");
    analyzeFail("{ int x = ''; }", TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testInitializers() {
    analyze("int i = 1;");
    analyze("double d1 = .0;");
    analyze("double d2 = 1.0;");
    analyze("int x = null;");
  }

  public void testLabels() {
    // Labels should be inside a function or method to be used

    // break
    analyze("foo() { L: for (;true;) { break L; } }");
    analyze("foo() { int x; List<int> c; L: for (x  in c) { break L; } }");
    analyze("foo() { List<int> c; L: for (var x  in c) { break L; } }");
    analyze("foo() { L: while (true) { break L; } }");
    analyze("foo() { L: do { break L; } while (true); }");

    analyze("foo() { L: for (;true;) { for (;true;) { break L; } } }");
    analyze("foo() { int x; List<int> c; L: for (x  in c) { for (;true;) { break L; } } }");
    analyze("foo() { List<int> c; L: for (var x  in c) { for (;true;) { break L; } } }");
    analyze("foo() { L: while (true) { for (;true;) { break L; } } }");
    analyze("foo() { L: do { for (;true;) { break L; } } while (true); }");

    // continue
    analyze("foo() { L: for (;true;) { continue L; } }");
    analyze("foo() { int x; List<int> c; L: for (x  in c) { continue L; } }");
    analyze("foo() { List<int> c; L: for (var x  in c)  { continue L; } }");
    analyze("foo() { L: do { continue L; } while (true); }");

    analyze("foo() { L: for (;true;) { for (;true;) { continue L; } } }");
    analyze(
      "foo() { int x; List<int> c; L: for (x  in c) { for (;true;) { continue L; } } }");
    analyze("foo() { List<int> c; L: for (var x  in c)  { for (;true;) { continue L; } } }");
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

  public void testLoadInterfaces() {
    loadFile("interfaces.dart");
    ClassElement superElement = (ClassElement)coreElements.get("Super");
    assertNotNull("no element for Super", superElement);
    assertEquals(object.getType(), superElement.getSupertype());
    assertEquals(0, superElement.getInterfaces().size());
    ClassElement sub = (ClassElement)coreElements.get("Sub");
    assertNotNull("no element for Sub", sub);
    assertEquals(object.getType(), sub.getSupertype());
    assertEquals(1, sub.getInterfaces().size());
    assertEquals(superElement, sub.getInterfaces().get(0).getElement());
    InterfaceType superString = itype(superElement, itype(string));
    InterfaceType subString = itype(sub, itype(string));
    Types types = getTypes();
    assertEquals("Super<String>", String.valueOf(types.asInstanceOf(superString, superElement)));
    assertEquals("Super<String>", String.valueOf(types.asInstanceOf(subString, superElement)));
    assertEquals("Sub<String>", String.valueOf(types.asInstanceOf(subString, sub)));
    assertNull(types.asInstanceOf(superString, sub));
  }


  public void testMapLiteral() {
    analyze("{ var x = {\"key\": 42}; }");
    analyze("{ var x = {'key': 42}; }");
    analyze("{ var x = <num>{'key': 42}; }");
    analyze("{ var x = <int>{'key': 42}; }");
    analyze("{ var x = <num>{'key': 0.42}; }");
    analyze("{ var x = <num>{'key': 42}; }");
    analyzeFail("{ var x = <int>{'key': 0.42}; }",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("{ int i; var x = {'key': i = 0.42}; }",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze("{ var x = const {\"key\": 42}; }");
    analyze("{ var x = const {'key': 42}; }");
    analyze("{ var x = const <num>{'key': 42}; }");
    analyze("{ var x = const <int>{'key': 42}; }");
    analyze("{ var x = const <num>{'key': 0.42}; }");
    analyze("{ var x = const <num>{'key': 42}; }");
    analyzeFail("{ var x = const <int>{'key': 0.42}; }",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("{ int i; var x = const {'key': i = 0.42}; }",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("{Map<num, num> x = const <num>{}; }",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testMethodInvocationArgumentCount() {
    loadFile("class_with_methods.dart");
    final String header = "{ ClassWithMethods c; ";

    analyzeFail(header + "c.untypedNoArgumentMethod(1); }",
      TypeErrorCode.EXTRA_ARGUMENT);
    analyzeFail(header + "c.untypedOneArgumentMethod(); }",
      TypeErrorCode.MISSING_ARGUMENT);
    analyzeFail(header + "c.untypedOneArgumentMethod(1, 1); }",
      TypeErrorCode.EXTRA_ARGUMENT);
    analyzeFail(header + "c.untypedTwoArgumentMethod(); }",
        TypeErrorCode.MISSING_ARGUMENT);
    analyzeFail(header + "c.untypedTwoArgumentMethod(1, 2, 3); }",
      TypeErrorCode.EXTRA_ARGUMENT);
    analyzeFail(header + "c.intNoArgumentMethod(1); }",
      TypeErrorCode.EXTRA_ARGUMENT);
    analyzeFail(header + "c.intOneArgumentMethod(); }",
        TypeErrorCode.MISSING_ARGUMENT);
    analyzeFail(header + "c.intOneArgumentMethod(1, 1); }",
      TypeErrorCode.EXTRA_ARGUMENT);
    analyzeFail(header + "c.intTwoArgumentMethod(); }",
        TypeErrorCode.MISSING_ARGUMENT);
    analyzeFail(header + "c.intTwoArgumentMethod(1, 2, 3); }",
      TypeErrorCode.EXTRA_ARGUMENT);
    analyze(header + "c.untypedField(); }");
  }

  public void testMethodInvocations() {
    loadFile("class_with_methods.dart");
    final String header = "{ ClassWithMethods c; int i, j; ";

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
        TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);

    analyzeFail(header + "int k = c.intOneArgumentMethod(c); }",
        TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail(header + "ClassWithMethods x = c.intOneArgumentMethod(1); }",
        TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail(header + "int k = c.intOneArgumentMethod('string'); }",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze(header + "int k = c.intOneArgumentMethod(i); }");

    analyzeFail(header + "int k = c.intTwoArgumentMethod(1, 'string'); }",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze(header + "int k = c.intTwoArgumentMethod(i, j); }");
    analyzeFail(header + "ClassWithMethods x = c.intTwoArgumentMethod(i, j); }",
        TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testNamedFunctionTypeAlias() {
    loadFile("named_function_type_alias.dart");
    analyze("VoidFunction f = foo() {};");
  }

  public void testNewExpression() {
    analyzeClasses(loadSource(
        "class Foo {",
        "  Foo(int x) {}",
        "  Foo.foo() {}",
        "  Foo.bar([int i = null]) {}",
        "}",
        "interface Bar<T> default Baz<T> {",
        "  Bar.make();",
        "}",
        "class Baz<T> {",
        "  factory Bar.make(T x) { return null; }",
        "}",
        "class Foobar<T extends String> {",
        "}"));

    analyze("Foo x = new Foo(0);");
    analyzeFail("Foo x = new Foo();", TypeErrorCode.MISSING_ARGUMENT);
    analyzeFail("Foo x = new Foo('');", TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("Foo x = new Foo(0, null);", TypeErrorCode.EXTRA_ARGUMENT);

    analyze("Foo x = new Foo.foo();");
    analyzeFail("Foo x = new Foo.foo(null);", TypeErrorCode.EXTRA_ARGUMENT);

    analyze("Foo x = new Foo.bar();");
    analyze("Foo x = new Foo.bar(0);");
    analyzeFail("Foo x = new Foo.bar('');", TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("Foo x = new Foo.bar(0, null);", TypeErrorCode.EXTRA_ARGUMENT);
    analyzeFail("var x = new Foobar<num>();", TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze("Bar<String> x = new Bar.make('');");
  }

  public void testAssignableTypeArg() {
      analyzeClasses(loadSource(
          "interface Bar<T> default Baz<T> {",
          "  Bar.make();",
          "}",
          "class Baz<T> {",
          "  Baz(T x) { return null; }",
          "  factory Bar.make(T x) { return null; }",
          "}"));
      analyze("Baz<String> x = new Baz<String>('');");
      analyze("Bar<String> x = new Bar.make('');");
      analyze("Bar<String> x = new Bar<String>.make('');");
  }

  public void testOddStuff() {
    Map<String, ClassNodeElement> classes = analyzeClasses(loadSource(
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
    analyzeFail("fisk: while (true) fisk++;", TypeErrorCode.CANNOT_BE_RESOLVED);
    analyzeFail("new Class().m().x;", TypeErrorCode.VOID);
    analyzeFail("(new Class().m)().x;", TypeErrorCode.VOID);
  }

  public void testParameterAccess() {
    analyze("{ f(int x) { x = 1; } }");
    analyzeFail("{ f(String x) { x = 1; } }",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze("{ f(int x, int y) { x = y; } }");
    analyzeFail("{ f(String x, int y) { x = y; } }",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze("{ f(x, int y) { x = y; } }");
    analyze("{ f(x, int y) { x = y; } }");
    analyzeFail("{ f(String x) { x = 1;} }",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testParameterInitializers() {
    Map<String, ClassNodeElement> classes = loadSource(
        "class C1 { int i; C1(this.i) {} }",
        "class C2 { String s; C2(int this.s) {} }",
        "class C3 { int i; C3(double this.i) {} }",
        "class C4 { int i; C4(num this.i) {} }");
    analyzeClass(classes.get("C1"), 0);
    analyzeClass(classes.get("C2"), 1);
    analyzeClass(classes.get("C3"), 1);
    analyzeClass(classes.get("C4"), 0);
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
  }

  public void testReturn() {
    analyzeFail(returnWithType("int", "'string'"),
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze(returnWithType("", "'string'"));
    analyze(returnWithType("Object", "'string'"));
    analyze(returnWithType("String", "'string'"));
    analyze(returnWithType("String", null));
    analyze(returnWithType("int", null));
    analyze(returnWithType("void", ""));
    analyzeFail(returnWithType("void", 1), TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze(returnWithType("void", null));
    analyzeFail(returnWithType("String", ""), TypeErrorCode.MISSING_RETURN_VALUE);
    analyze("String foo() {};"); // Should probably fail, http://b/4484060.
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

  public void testSuperConstructorInvocation() {
    Map<String, ClassNodeElement> classes = loadSource(
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

  public void testSuperInterfaces() {
    // If this test is failing, first debug any failures in testLoadInterfaces.
    loadFile("interfaces.dart");
    analyze("Super<String> s = new Sub<String>();");
    analyze("Super<Object> o = new Sub<String>();");
    analyzeFail("Super<String> f1 = new Sub<int>();",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("Sub<String> f2 = new Sub<int>();",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testSwitch() {
    analyze("{ int i = 27; switch(i) { case i: break; } }");
    analyzeFail(
        "{ switch(true) { case 1: break; case 'foo': break; }}",
        TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail(
        "{ int i = 27; switch(true) { case false: i = 2.7; }}",
        TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testThis() {
    Map<String, ClassNodeElement> classes = loadFile("class_with_supertypes.dart");
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

  public void testTryCatchFinally() {
    analyze("try { } catch (var _) { } finally { }");
    analyzeFail("try { int i = 4.2; } catch (var _) { } finally { }",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("try { } catch (var _) { int i = 4.2; } finally { }",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("try { } catch (var _) { } finally { int i = 4.2; }",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
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

  public void testDefaultTypeArgs() {
    Map<String, ClassNodeElement> source = loadSource(
        "class Object{}",
        "interface List<T> {}",
        "interface A<K,V> default B<K, V extends List<K>> {}",
        "class B<K, V extends List<K>> {",
        "}");
        analyzeClasses(source);
  }

  public void testUnaryOperators() {
    Map<String, ClassNodeElement> source = loadSource(
        "class Foo {",
        "  Foo foo;",
        "  bool b;",
        "  int i;",
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
    for (Token op : EnumSet.of(Token.DEC, Token.INC)) {
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

  public void testUnresolved() {
    ClassElement element = loadClass("class_with_supertypes.dart", "ClassWithSupertypes");
    analyzeIn(element, "this.field", 0);
    analyzeIn(element, "null", 0);
    analyzeIn(element, "noSuchField", 1);
    analyzeIn(element, "noSuchMethod()", 1);
    analyzeIn(element, "method()", 0);
    analyzeIn(element, "field", 0);
    analyzeIn(element, "this.noSuchField", 1);
    analyzeIn(element, "this.noSuchMethod()", 1);
    analyzeIn(element, "this.method()", 0);
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

  public void testUnresolvedIdentifier() {
    setExpectedTypeErrorCount(3);
    checkType(typeProvider.getDynamicType(), "y");
    checkExpectedTypeErrorCount();
  }

  public void testVoid() {
    // Return a value from a void function.
    analyze("void f() { return; }");
    analyze("void f() { return null; }");
    analyze("void f() { return f(); }");
    analyzeFail("void f() { return 1; }", TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyze("void f() { var x; return x; }");

    // No-arg return from non-void function.
    analyzeFail("int f() { return; }", TypeErrorCode.MISSING_RETURN_VALUE);
    analyze("f() { return; }");

    // Calling a method on a void expression, property access.
    analyzeFail("void f() { f().m(); }", TypeErrorCode.VOID);
    analyzeFail("void f() { f().x; }", TypeErrorCode.VOID);

    // Passing a void argument to a method.
    analyzeFail("{ void f() {} m(x) {} m(f()); }", TypeErrorCode.VOID);

    // Assigning a void expression to a variable.
    analyzeFail("{ void f() {} int x = f(); }", TypeErrorCode.VOID);
    analyzeFail("{ void f() {} int x; x = f(); }", TypeErrorCode.VOID);
    analyzeFail("{ void f() {} int x; x += f(); }", TypeErrorCode.VOID);

    // Misc.
    analyzeFail("{ void f() {} 1 + f(); }", TypeErrorCode.VOID);
    analyzeFail("{ void f() {} f() + 1; }", TypeErrorCode.VOID);
    analyzeFail("{ void f() {} var x; x && f(); }", TypeErrorCode.VOID);
    analyzeFail("{ void f() {} !f(); }", TypeErrorCode.VOID);
    analyzeFail("{ void f() {} -f(); }", TypeErrorCode.VOID);
    // We seem to throw away prefix-plus in the parser:
    // analyzeFail("{ void f() {} +f(); }", TypeErrorCode.VOID);
    analyzeFail("{ void f() {} var x; x == f(); }", TypeErrorCode.VOID);
    analyzeFail("{ void f() {} while (f()); }", TypeErrorCode.VOID);
    analyzeFail("{ void f() {}; ({ 'x': f() }); }", TypeErrorCode.VOID);
  }

  public void testWhileStatement() {
    analyze("while (true) {}");
    analyze("while (null) {}");
    analyzeFail("while (0) {}",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
    analyzeFail("while ('') {}",
      TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testValidateFactoryBounds() {
    Map<String, ClassNodeElement> source = loadSource(
        "class Object {}",
        "interface Foo {}",
        "interface Bar extends Foo {}",
        "interface IA<T> default A<T extends Foo> { IA(); }",
        "class A<T extends Foo> implements IA<T> {",
        "  factory A() {}",
        "}");
    analyzeClasses(source);
    analyze("{ var val1 = new IA<Foo>(); }");
    analyze("{ var val1 = new IA<Bar>(); }");
    analyzeFail("{ var val1 = new IA<String>(); }",TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE);
  }

  public void testStringConcat() {
    Map<String, ClassNodeElement> source = loadSource(
        "class Object {}",
        "interface Foo {",
        "  operator +(arg1);" +
        "}",
        "Foo a = new Foo();",
        "Foo b = new Foo();",
        "String s = 'foo';");
    analyzeClasses(source);
    analyze("{ var c = a + b; }");
    analyzeFail("{ var c = s + b; }",
        TypeErrorCode.PLUS_CANNOT_BE_USED_FOR_STRING_CONCAT);
    analyzeFail("var c = 'foo' + 1;",
        TypeErrorCode.PLUS_CANNOT_BE_USED_FOR_STRING_CONCAT);
    analyzeFail("var c = 'foo' + 'bar';",
        TypeErrorCode.PLUS_CANNOT_BE_USED_FOR_STRING_CONCAT);
  }
}
