// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.common;

import com.google.common.collect.Sets;
import com.google.common.io.Files;
import com.google.dart.compiler.CompilerTestCase;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompiler;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DartSourceTest;
import com.google.dart.compiler.DefaultCompilerConfiguration;
import com.google.dart.compiler.DefaultDartArtifactProvider;
import com.google.dart.compiler.MockLibrarySource;
import com.google.dart.compiler.ast.DartBinaryExpression;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartExprStmt;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartMethodInvocation;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.ast.DartStatement;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.backend.common.TypeHeuristic.FieldKind;
import com.google.dart.compiler.resolver.CoreTypeProvider;
import com.google.dart.compiler.resolver.CoreTypeProviderImplementation;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.ElementKind;
import com.google.dart.compiler.resolver.FieldElement;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.type.Type;

import java.io.IOException;
import java.net.URI;
import java.net.URL;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

public class TypeHeuristicImplementationTest extends CompilerTestCase {

  CoreTypeProvider typeProvider;
  private static final String NumberImpl = "NumberImplementation";
  private static final String StringImpl = "StringImplementation";
  private static final String BoolImpl = "BoolImplementation";
  private static final String Dynamic = "<dynamic>";
  private static final FieldKind AS_GETTER = FieldKind.GETTER;
  private static final FieldKind AS_SETTER = FieldKind.SETTER;

  DartUnit compileUnit(final String filePath) throws IOException {
    URL url = inputUrlFor(getClass(), filePath + ".dart");
    String source = readUrl(url);
    return compileUnitFromSource(source, filePath);
  }

  DartUnit compileUnitFromSource(final CodeBuilder source) throws IOException {
    return compileUnitFromSource(source.toString(), getName());
  }

  DartUnit compileUnitFromSource(final String source, final String name) throws IOException {
    MockLibrarySource lib = new MockLibrarySource();
    DartSourceTest src = new DartSourceTest(name, source, lib);
    lib.addSource(src);
    Map<URI, DartUnit> parsedUnits = new HashMap<URI, DartUnit>();
    DefaultCompilerConfiguration config = new DefaultCompilerConfiguration();
    DefaultDartArtifactProvider provider = new DefaultDartArtifactProvider(Files.createTempDir());
    DartCompilerListener listener = new DartCompilerListener() {
      @Override
      public void typeError(DartCompilationError event) {
      }

      @Override
      public void compilationWarning(DartCompilationError event) {
      }

      @Override      
      public void compilationError(DartCompilationError event) {
      }

      @Override
      public void unitCompiled(DartUnit unit) {
      }
    };
    LibraryUnit libUnit = DartCompiler.analyzeLibrary(lib, parsedUnits, config, provider,
        listener);
    LibraryUnit corelibUnit = libUnit.getImports().iterator().next();
    typeProvider = new CoreTypeProviderImplementation(corelibUnit.getElement().getScope(),
                                                      listener);
    return libUnit.getUnit(name);
  }

  /**
   * Check conflicting generic list operator return types.
   */
  public void testListIncompatibleListOperator() throws IOException {

    CodeBuilder code = CodeBuilder.Create()
    .l("class MyList<T> implements List<T> {")
      .l("MyList() { }")
      .l("String operator[](int index) { }")
    .l("}")
    .l()
    .l("class MainClass {")
      .l("static main() {")
        .l("List<int> xx = new MyList<int>();")
        .l("xx[0] = 123;")
      .l("}")
    .l("}");

    DartUnit unit = compileUnitFromSource(code);

    TypeHeuristic th = getTypeHeuristics(unit);

    DartMethodDefinition m = getMethod(unit, "MainClass", "main");
    DartExpression arrayIndex = getLHS(getStatementUnderTest(m));
    assertTypesOf(th.getTypesOf(arrayIndex), Dynamic);

    assertMethodImplementations(th.getImplementationsOf(arrayIndex), 2, "[]");
  }

  /**
   * Check compatible generic list operator return types.
   */
  public void testListCompatibleListOperator() throws IOException {

    CodeBuilder code = CodeBuilder.Create()
    .l("class MyList<T> implements List<T> {")
      .l("MyList() { }")
      .l("int operator[](int index) { }")
    .l("}")
    .l()
    .l("class MainClass {")
      .l("static main() {")
        .l("List<int> xx = new MyList<int>();")
        .l("xx[0] = 123;")
      .l("}")
    .l("}");

    DartUnit unit = compileUnitFromSource(code);

    DartMethodDefinition method = getMethodUnderTest(unit);

    TypeHeuristic th = getTypeHeuristics(unit);

    assertTypesOf(th.getTypesOf(getLHS(getStatementUnderTest(method))), NumberImpl);
  }

  /**
   * Check compatible binary op;
   */
  public void testCompatibleBinaryOp() throws IOException {

    CodeBuilder code = CodeBuilder.Create()
    .l("class MainClass {")
      .l("static final int b = 2;")
      .l("static main() {")
        .l("int a;")
        .l("a = 1 + b;")
      .l("}")
    .l("}");

    DartUnit unit = compileUnitFromSource(code);

    DartMethodDefinition method = getMethodUnderTest(unit);

    TypeHeuristic th = getTypeHeuristics(unit);

    DartStatement stmt = getStatementUnderTest(method);
    DartExpression plusExpr = getRHS(stmt);
    assertTypesOf(th.getTypesOf(getLHS(plusExpr)), NumberImpl);
    assertTypesOf(th.getTypesOf(getRHS(plusExpr)), NumberImpl);
    assertTypesOf(th.getTypesOf(plusExpr), NumberImpl);
  }

  /**
   * Check compatible binary op (2 operands).
   */
  public void testIncompatibleBinaryOp1() throws IOException {

    CodeBuilder code = CodeBuilder.Create()
    .l("class MainClass {")
      .l("static final String b = '2';")
      .l("static main() {")
        .l("int a;")
        .l("a = 1 + b;")
      .l("}")
    .l("}");

    DartUnit unit = compileUnitFromSource(code);

    DartMethodDefinition method = getMethodUnderTest(unit);

    TypeHeuristic th = getTypeHeuristics(unit);

    DartStatement stmt = getStatementUnderTest(method);
    DartExpression expr = getRHS(stmt);
    assertTypesOf(th.getTypesOf(getLHS(expr)), NumberImpl);
    assertTypesOf(th.getTypesOf(getRHS(expr)), StringImpl);
    assertTypesOf(th.getTypesOf(expr), NumberImpl);
  }

  /**
   * Check compatible binary op (3 operands).
   */
  public void testIncompatibleBinaryOp2() throws IOException {

    CodeBuilder code = CodeBuilder.Create()
    .l("class MainClass {")
      .l("static final int b = 2;")
      .l("static main() {")
        .l("int a;")
        .l("a = b * 'A' + 3;")
      .l("}")
    .l("}");

    DartUnit unit = compileUnitFromSource(code);

    DartMethodDefinition method = getMethodUnderTest(unit);

    TypeHeuristic th = getTypeHeuristics(unit);

    DartStatement stmt = getStatementUnderTest(method);
    DartExpression expr = getRHS(stmt);
    DartExpression intPlusString = getLHS(expr);
    assertTypesOf(th.getTypesOf(getLHS(intPlusString)), NumberImpl);
    assertTypesOf(th.getTypesOf(getRHS(intPlusString)), StringImpl);
    assertTypesOf(th.getTypesOf(expr), NumberImpl);
  }

  /**
   * Check mixed binary op (4 operands). b == 1 && "A" + 3;
   */
  public void testIncompatibleLogicalOp() throws IOException {

    CodeBuilder code = CodeBuilder.Create()
    .l("class MainClass {")
      .l("static final int b = 2;")
      .l("static main() {")
        .l("int a;")
        .l("a = b == 1 && 'A' + 3;")
      .l("}")
    .l("}");

    DartUnit unit = compileUnitFromSource(code);

    DartMethodDefinition method = getMethodUnderTest(unit);

    TypeHeuristic th = getTypeHeuristics(unit);

    DartStatement stmt = getStatementUnderTest(method);
    DartExpression andExpr = getRHS(stmt);
    DartExpression eqExpr = getLHS(andExpr);
    DartExpression plusExpr = getRHS(andExpr);

    assertTypesOf(th.getTypesOf(getLHS(eqExpr)), NumberImpl);
    assertTypesOf(th.getTypesOf(getRHS(eqExpr)), NumberImpl);
    assertTypesOf(th.getTypesOf(eqExpr), BoolImpl);

    assertTypesOf(th.getTypesOf(getLHS(plusExpr)), StringImpl);
    assertTypesOf(th.getTypesOf(getRHS(plusExpr)), NumberImpl);
    assertTypesOf(th.getTypesOf(plusExpr), StringImpl);

    assertTypesOf(th.getTypesOf(andExpr), BoolImpl);
  }

  /**
   * see dart source testCombinedExpressions.dart
   *
   * a.foo() - myInt + a.myField * a.bar();
   */
  public void testCombinedExpressions() throws IOException {

    CodeBuilder code = CodeBuilder.Create()
    .l("interface A {")
      .l("String foo();")
      .l("int myField;")
    .l("}")
    .l()
    .l("class B implements A {")
    .   l("B() { }")
      .l("String foo() { }")
    .l("}")
    .l()
    .l("class C extends  B {")
      .l("C() : super() { }")
      .l("double bar() { }")
      .l("String myField;")
    .l("}")
    .l()
    .l("class MainClass {")
      .l("static final double myInt = 999;")
      .l("static main() {")
        .l("A a = new C();")
        .l("s = myInt - a.foo() + a.myField * a.bar();")
      .l("}")
    .l("}");

    DartUnit unit = compileUnitFromSource(code);

    DartMethodDefinition method = getMethodUnderTest(unit);

    TypeHeuristic th = getTypeHeuristics(unit);

    DartStatement stmt = getStatementUnderTest(method);
    DartExpression plus = getRHS(stmt);
    DartExpression minus = getLHS(plus);
    DartExpression times = getRHS(plus);

    assertTypesOf(th.getTypesOf(plus), NumberImpl);

    assertTypesOf(th.getTypesOf(minus), NumberImpl);
    assertTypesOf(th.getTypesOf(getLHS(minus)), NumberImpl);
    assertTypesOf(th.getTypesOf(getRHS(minus)), StringImpl);

    assertTypesOf(th.getTypesOf(times), Dynamic);
    assertTypesOf(th.getTypesOf(getLHS(times)), Dynamic);
    assertTypesOf(th.getTypesOf(getRHS(times)), NumberImpl);
  }

  /**
   * Check compatible methods.
   */
  public void testCompatibleMethods() throws IOException {

    CodeBuilder code = CodeBuilder.Create()
    .l("class A {")
      .l("A() { }")
      .l("double foo() { }")
    .l("}")
    .l()
    .l("class B extends A {")
      .l("B() : super() {}")
      .l("int foo() { }")
    .l("}")
    .l()
    .l("class MainClass {")
      .l("static main() {")
        .l("A a = new B();")
        .l("test = a.foo();")
      .l("}")
    .l("}");

    DartUnit unit = compileUnitFromSource(code);

    DartMethodDefinition method = getMethodUnderTest(unit);

    TypeHeuristic th = getTypeHeuristics(unit);

    DartStatement assignStmt = getStatementUnderTest(method);
    DartExpression mInvocation = getRHS(assignStmt);
    assertTypesOf(th.getTypesOf(mInvocation), NumberImpl);
    DartExpression qualifier = getQualifier(mInvocation);
    assertTypesOf(th.getTypesOf(qualifier), "A", "B");

    assertMethodImplementations(th.getImplementationsOf(mInvocation), 2, "foo");
  }

  /**
   * Check incompatible methods.
   */
  public void testIncompatibleMethods() throws IOException {

    CodeBuilder code = CodeBuilder.Create()
    .l("class A {")
      .l("A() { }")
      .l("int foo() { }")
    .l("}")
    .l()
    .l("class B extends A {")
      .l("B() : super() {}")
      .l("String foo() { }")
    .l("}")
    .l()
    .l("class MainClass {")
      .l("static main() {")
        .l("A a = new B();")
        .l("test = a.foo();")
      .l("}")
    .l("}");

    DartUnit unit = compileUnitFromSource(code);

    DartMethodDefinition method = getMethodUnderTest(unit);

    TypeHeuristic th = getTypeHeuristics(unit);

    DartStatement assignStmt = getStatementUnderTest(method);
    DartExpression mInvocation = getRHS(assignStmt);
    assertTypesOf(th.getTypesOf(mInvocation), Dynamic);
    DartExpression qualifier = getQualifier(mInvocation);
    assertTypesOf(th.getTypesOf(qualifier), "A", "B");

    assertMethodImplementations(th.getImplementationsOf(mInvocation), 2, "foo");
  }

  /**
   * Check compatible types with multiple implementations.
   */
  public void testIncompatibleMethods2() throws IOException {

    CodeBuilder code = CodeBuilder.Create()
    .l("class A {")
      .l("A() { }")
      .l("int foo() { }")
    .l("}")
    .l()
    .l("class B extends A {")
      .l("B() : super() {}")
      .l("int foo() { }")
    .l("}")
    .l()
    .l("class MainClass {")
      .l("static main() {")
        .l("A a = new B();")
        .l("test = a.foo();")
      .l("}")
    .l("}");

    DartUnit unit = compileUnitFromSource(code);

    DartMethodDefinition method = getMethodUnderTest(unit);

    TypeHeuristic th = getTypeHeuristics(unit);

    DartStatement assignStmt = getStatementUnderTest(method);
    DartExpression mInvocation = getRHS(assignStmt);
    assertTypesOf(th.getTypesOf(mInvocation), NumberImpl);
    DartExpression qualifier = getQualifier(mInvocation);
    assertTypesOf(th.getTypesOf(qualifier), "A", "B");

    assertMethodImplementations(th.getImplementationsOf(mInvocation), 2, "foo");
  }

  /**
   * Check compatible fields.
   */
  public void testCompatibleFields() throws IOException {

    CodeBuilder code = CodeBuilder.Create()
    .l("class A { ")
      .l("A() { } ")
      .l("int iField;")
    .l("}")
    .l()
    .l("class B extends A {")
      .l("B() : super() {}")
    .l("}")
    .l()
    .l("class MainClass {")
      .l("static main() {")
        .l("A a = new B();")
        .l("test = a.iField;")
      .l("}")
    .l("}");

    DartUnit unit = compileUnitFromSource(code);

    DartMethodDefinition method = getMethodUnderTest(unit);

    TypeHeuristic th = getTypeHeuristics(unit);

    DartStatement assignStmt = getStatementUnderTest(method);
    DartExpression field = getRHS(assignStmt);
    assertTypesOf(th.getTypesOf(field), NumberImpl);
    DartExpression qualifier = getQualifier(field);
    assertTypesOf(th.getTypesOf(qualifier), "A", "B");

    assertFields(th.getFieldImplementationsOf(field, AS_GETTER), 1, "iField", AS_GETTER);
    assertFields(th.getFieldImplementationsOf(field, AS_SETTER), 1, "iField", AS_SETTER);
  }

  /**
   * Check compatible field types with 2 implementations.
   * implementation type of iField is NumberImplementation with two possible implementations.
   */
  public void testIncompatibleFields() throws IOException {

    CodeBuilder code = CodeBuilder.Create()
    .l("class A { ")
      .l("A() { } ")
      .l("int iField;")
    .l("}")
    .l()
    .l("class B extends A {")
      .l("B() : super() {}")
      .l("int iField;")
    .l("}")
    .l()
    .l("class MainClass {")
      .l("static main() {")
        .l("A a = new B();")
        .l("test = a.iField;")
      .l("}")
    .l("}");

    DartUnit unit = compileUnitFromSource(code);

    DartMethodDefinition method = getMethodUnderTest(unit);

    TypeHeuristic th = getTypeHeuristics(unit);

    DartStatement assignStmt = getStatementUnderTest(method);
    DartExpression field = getRHS(assignStmt);
    assertTypesOf(th.getTypesOf(field), NumberImpl);
    DartExpression qualifier = getQualifier(field);
    assertTypesOf(th.getTypesOf(qualifier), "A", "B");

    assertFields(th.getFieldImplementationsOf(field, AS_GETTER), 2, "iField", AS_GETTER);
    assertFields(th.getFieldImplementationsOf(field, AS_SETTER), 2, "iField", AS_SETTER);
  }

  /**
   * Check incompatible fields.
   */
  public void testIncompatibleFields2() throws IOException {

    CodeBuilder code = CodeBuilder.Create()
    .l("class A { ")
      .l("A() { } ")
      .l("int iField;")
    .l("}")
    .l()
    .l("class B extends A {")
      .l("B() : super() {}")
      .l("String iField;")
    .l("}")
    .l()
    .l("class MainClass {")
      .l("static main() {")
        .l("A a = new B();")
        .l("test = a.iField;")
      .l("}")
    .l("}");

    DartUnit unit = compileUnitFromSource(code);

    DartMethodDefinition method = getMethodUnderTest(unit);

    TypeHeuristic th = getTypeHeuristics(unit);

    DartStatement assignStmt = getStatementUnderTest(method);
    DartExpression field = getRHS(assignStmt);
    assertTypesOf(th.getTypesOf(field), Dynamic);
    DartExpression qualifier = getQualifier(field);
    assertTypesOf(th.getTypesOf(qualifier), "A", "B");

    assertFields(th.getFieldImplementationsOf(field, AS_GETTER), 2, "iField", AS_GETTER);
    assertFields(th.getFieldImplementationsOf(field, AS_SETTER), 2, "iField", AS_SETTER);
  }

  /**
   * Check incompatible fields.
   */
  public void testIncompatibleFieldsWithGetter() throws IOException {

    CodeBuilder code = CodeBuilder.Create()
    .l("class A { ")
      .l("A() { } ")
      .l("int iField;")
    .l("}")
    .l()
    .l("class B extends A {")
      .l("B() : super() {}")
      .l("int get iField() { }")
    .l("}")
    .l()
    .l("class MainClass {")
      .l("static main() {")
        .l("A a = new B();")
        .l("test = a.iField;")
      .l("}")
    .l("}");

    DartUnit unit = compileUnitFromSource(code);

    DartMethodDefinition method = getMethodUnderTest(unit);

    TypeHeuristic th = getTypeHeuristics(unit);

    DartStatement assignStmt = getStatementUnderTest(method);
    DartExpression field = getRHS(assignStmt);
    assertTypesOf(th.getTypesOf(field), NumberImpl);
    DartExpression qualifier = getQualifier(field);
    assertTypesOf(th.getTypesOf(qualifier), "A", "B");

    assertFields(th.getFieldImplementationsOf(field, AS_GETTER), 2, "iField", AS_GETTER);
    assertFields(th.getFieldImplementationsOf(field, AS_SETTER), 1, "iField", AS_SETTER);
  }

  /**
   * Check incompatible fields.
   */
  public void testIncompatibleFieldsWithSetter() throws IOException {

    CodeBuilder code = CodeBuilder.Create()
    .l("class A { ")
      .l("A() { } ")
      .l("int iField;")
    .l("}")
    .l()
    .l("class B extends A {")
      .l("B() : super() {}")
      .l("set iField(x) { }")
    .l("}")
    .l()
    .l("class MainClass {")
      .l("static main() {")
        .l("A a = new B();")
        .l("test = a.iField;")
      .l("}")
    .l("}");

    DartUnit unit = compileUnitFromSource(code);

    DartMethodDefinition method = getMethodUnderTest(unit);

    TypeHeuristic th = getTypeHeuristics(unit);

    DartStatement assignStmt = getStatementUnderTest(method);
    DartExpression field = getRHS(assignStmt);
    assertTypesOf(th.getTypesOf(field), NumberImpl);
    DartExpression qualifier = getQualifier(field);
    assertTypesOf(th.getTypesOf(qualifier), "A", "B");

    assertFields(th.getFieldImplementationsOf(field, AS_GETTER), 1, "iField", AS_GETTER);
    assertFields(th.getFieldImplementationsOf(field, AS_SETTER), 2, "iField", AS_SETTER);
  }

  /**
   * Check array of generic type.
   */
  public void testGenericTypeInList() throws IOException {

    CodeBuilder code = CodeBuilder.Create()
    .l("class A { ")
      .l("A() { } ")
      .l("int x;")
    .l("}")
    .l()
    .l("class B { ")
      .l("B() { } ")
      .l("A field;")
    .l("}")
    .l()
    .l("class MyList<T> implements List<T> {")
      .l("MyList() {}")
      .l("T operator[](int index) { }")
    .l("}")
    .l()
    .l("class MainClass {")
      .l("static main() {")
        .l("List<B> b = new MyList<B>();")
        .l("test = b[0].field.x;")
      .l("}")
    .l("}");

    DartUnit unit = compileUnitFromSource(code);

    DartMethodDefinition method = getMethodUnderTest(unit);

    TypeHeuristic th = getTypeHeuristics(unit);

    DartStatement assignStmt = getStatementUnderTest(method);

    // b[0].field.x => NumberImpl
    DartExpression expr = getRHS(assignStmt);
    assertTypesOf(th.getTypesOf(expr), NumberImpl);
    assertFields(th.getFieldImplementationsOf(expr, AS_GETTER), 1, "x", AS_GETTER);
    assertFields(th.getFieldImplementationsOf(expr, AS_SETTER), 1, "x", AS_SETTER);

    // b[0].field => A
    DartExpression b_zeroIndex_field = getQualifier(expr);
    assertTypesOf(th.getTypesOf(b_zeroIndex_field), "A");
    assertFields(th.getFieldImplementationsOf(b_zeroIndex_field, AS_GETTER), 1, "field", AS_GETTER);
    assertFields(th.getFieldImplementationsOf(b_zeroIndex_field, AS_SETTER), 1, "field", AS_SETTER);

    // b[0] => B
    DartExpression b_zeroIndex = getQualifier(b_zeroIndex_field);
    assertTypesOf(th.getTypesOf(b_zeroIndex), "B");
  }


  /**
   * Check ref equality.
   */
  public void testRefEquality() throws IOException {

    CodeBuilder code = CodeBuilder.Create()
    .l("class A { ")
      .l("A() { } ")
    .l("}")
    .l()
    .l("class B { ")
      .l("B() { } ")
    .l("}")
    .l()
    .l("class MainClass {")
      .l("static main() {")
        .l("A a = new A();")
        .l("B b = new B();")
        .l("test = a == b;")
      .l("}")
    .l("}");

    DartUnit unit = compileUnitFromSource(code);

    DartMethodDefinition method = getMethodUnderTest(unit);

    TypeHeuristic th = getTypeHeuristics(unit);

    DartStatement assignStmt = getStatementUnderTest(method, 2);
    DartExpression equals = getRHS(assignStmt);
    assertTypesOf(th.getTypesOf(equals), BoolImpl);

    DartExpression lhs = getLHS(equals);
    assertTypesOf(th.getTypesOf(lhs), "A");
    DartExpression rhs = getRHS(equals);
    assertTypesOf(th.getTypesOf(rhs), "B");

    assertMethodImplementations(th.getImplementationsOf(equals), 1, "==");
  }

  /**
   * Check override ref equality.
   */
  public void testOverrideRefEquality() throws IOException {

    CodeBuilder code = CodeBuilder.Create()
    .l("class A { ")
      .l("A() { } ")
      .l("bool operator ==(other) { }")
    .l("}")
    .l()
    .l("class B { ")
      .l("B() { } ")
    .l("}")
    .l()
    .l("class MainClass {")
      .l("static main() {")
        .l("A a = new A();")
        .l("B b = new B();")
        .l("test = a == b;")
      .l("}")
    .l("}");

    DartUnit unit = compileUnitFromSource(code);

    DartMethodDefinition method = getMethodUnderTest(unit);

    TypeHeuristic th = getTypeHeuristics(unit);

    DartStatement assignStmt = getStatementUnderTest(method, 2);
    DartExpression equals = getRHS(assignStmt);
    assertTypesOf(th.getTypesOf(equals), BoolImpl);

    DartExpression lhs = getLHS(equals);
    assertTypesOf(th.getTypesOf(lhs), "A");
    DartExpression rhs = getRHS(equals);
    assertTypesOf(th.getTypesOf(rhs), "B");

    assertMethodImplementations(th.getImplementationsOf(equals), 2, "==");
  }

  // Helpers //////////////////////////////////////////////////////////////////////////////////////

  private DartExpression getQualifier(DartExpression expr) {
    if (expr instanceof DartMethodInvocation) {
      return ((DartMethodInvocation) expr).getTarget();
    } else if (expr instanceof DartPropertyAccess) {
      return (DartExpression) ((DartPropertyAccess) expr).getQualifier();
    }
    return null;
  }

  private DartMethodDefinition getMethodUnderTest(DartUnit unit) {
    return getMethod(unit, "MainClass", "main");
  }

  private TypeHeuristic getTypeHeuristics(DartUnit unit) {
    return new TypeHeuristicImplementation(unit, typeProvider);
  }

  private void assertTypesOf(Set<Type> actual, String... expectedTypes) {
    Set<String> types = new HashSet<String>();
    for (Type t : actual) {
      types.add(t.toString());
    }
    assertEquals(Sets.newHashSet(expectedTypes), types);
  }

  private void assertMethodImplementations(Set<MethodElement> actual, int nImplementations,
                                           String name) {
    assertEquals(actual.size(), nImplementations);
    for (MethodElement e : actual) {
      assertEquals(name, e.getName());
    }
  }

  private void assertFields(Set<FieldElement> actual, int nImplementations,
                                          String name, FieldKind fieldKind) {
    assertEquals(actual.size(), nImplementations);
    for (FieldElement e : actual) {
      assertEquals(name, e.getName());
      Modifiers modifiers = e.getModifiers();
      if (modifiers.isAbstractField()) {
        if (fieldKind == FieldKind.GETTER) {
          assertTrue(modifiers.isGetter());
        } else {
          assertTrue(modifiers.isSetter());
        }
      }
    }
  }

  private DartExpression getLHS(DartStatement stmt) {
    DartBinaryExpression expr = (DartBinaryExpression) getExpression(stmt);
    return expr.getArg1();
  }

  private DartExpression getLHS(DartExpression expr) {
    DartBinaryExpression e = (DartBinaryExpression) expr;
    return e.getArg1();
  }

  private DartExpression getRHS(DartStatement stmt) {
    DartBinaryExpression expr = (DartBinaryExpression) getExpression(stmt);
    return expr.getArg2();
  }

  private DartExpression getRHS(DartExpression expr) {
    DartBinaryExpression e = (DartBinaryExpression) expr;
    return e.getArg2();
  }

  private DartExpression getExpression(DartStatement stmt) {
    if (stmt instanceof DartExprStmt) {
      return ((DartExprStmt) stmt).getExpression();
    }
    return ((DartExprStmt) stmt).getExpression();
  }

  private DartStatement getStatementUnderTest(DartMethodDefinition m) {
    return getStatementUnderTest(m, 1);
  }

  private DartStatement getStatementUnderTest(DartMethodDefinition m, int n) {
    DartStatement stmt = m.getFunction().getBody().getStatements().get(n);
    return stmt;
  }

  private DartClass getClass(DartUnit unit, String name) {
    DartNode node = unit.getLibrary().getTopLevelNode(name);
    if (node instanceof DartClass) {
      return (DartClass) node;
    }
    return null;
  }

  private DartMethodDefinition getMethod(DartUnit unit, String className, String name) {
    DartClass cls = getClass(unit, className);
    Element e = cls.getSymbol().lookupLocalElement(name);
    if (e != null && ElementKind.of(e) == ElementKind.METHOD) {
      return (DartMethodDefinition) e.getNode();

    }
    return null;
  }

  static class CodeBuilder {
    StringBuffer sb = new StringBuffer(512);
    static final String IDENT = " ";
    static final int IDENT_SIZE = 2;
    int identSize;

    public static CodeBuilder Create() {
      return new CodeBuilder();
    }

    public CodeBuilder() {
    }

    public CodeBuilder pnl(String src) {
      maybeOutIdent(src);
      for (int i = 0; i < identSize; i++) {
        sb.append(IDENT);
      }
      sb.append(src);
      return this;
    }

    public CodeBuilder l(String src) {
      pnl(src);
      pnl("\n");
      maybeIndent(src);
      return this;
    }

    public CodeBuilder l() {
      pnl("\n");
      return this;
    }

    public CodeBuilder i() {
      identSize += IDENT_SIZE;
      return this;
    }

    public CodeBuilder o() {
      identSize -= IDENT_SIZE;
      assert (identSize >= 0);
      return this;
    }

    private void maybeIndent(String src) {
      String line = src.trim();
      int last = line.length() - 1;
      if (line.length() > 0 && line.charAt(last) == '{') {
        i();
      }
    }

    private void maybeOutIdent(String src) {
      String line = src.trim();
      if (line.length() > 0 && line.charAt(0) == '}') {
        o();
      }
    }

    @Override
    public final String toString() {
      return sb.toString();
    }
  }
}
