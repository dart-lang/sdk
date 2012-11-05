// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.type;

import com.google.common.collect.Iterables;
import com.google.common.collect.Sets;
import com.google.dart.compiler.CommandLineOptions.CompilerOptions;
import com.google.dart.compiler.CompilerTestCase;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilerErrorCode;
import com.google.dart.compiler.DefaultCompilerConfiguration;
import com.google.dart.compiler.ast.ASTVisitor;
import com.google.dart.compiler.ast.DartArrayAccess;
import com.google.dart.compiler.ast.DartBinaryExpression;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartDeclaration;
import com.google.dart.compiler.ast.DartExprStmt;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartFieldDefinition;
import com.google.dart.compiler.ast.DartForInStatement;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartInvocation;
import com.google.dart.compiler.ast.DartMapLiteralEntry;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartMethodInvocation;
import com.google.dart.compiler.ast.DartNewExpression;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartUnaryExpression;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.DartUnqualifiedInvocation;
import com.google.dart.compiler.parser.ParserErrorCode;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.ElementKind;
import com.google.dart.compiler.resolver.EnclosingElement;
import com.google.dart.compiler.resolver.FieldElement;
import com.google.dart.compiler.resolver.LibraryElement;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.resolver.NodeElement;
import com.google.dart.compiler.resolver.ResolverErrorCode;
import com.google.dart.compiler.resolver.TypeErrorCode;
import com.google.dart.compiler.resolver.VariableElement;

import static com.google.dart.compiler.common.ErrorExpectation.assertErrors;
import static com.google.dart.compiler.common.ErrorExpectation.errEx;
import static com.google.dart.compiler.type.TypeQuality.EXACT;
import static com.google.dart.compiler.type.TypeQuality.INFERRED;
import static com.google.dart.compiler.type.TypeQuality.INFERRED_EXACT;

import java.net.URI;
import java.util.List;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Variant of {@link TypeAnalyzerTest}, which is based on {@link CompilerTestCase}. It is probably
 * slower, not actually unit test, but easier to use if you need access to DartNode's.
 */
public class TypeAnalyzerCompilerTest extends CompilerTestCase {

  /**
   * Top-level "main" function should not have parameters.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3271
   */
  public void test_topLevelMainFunction() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main(var p) {}",
        "class A {",
        "  main(var p) {}",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.MAIN_FUNCTION_PARAMETERS, 2, 1, 4));
  }

  /**
   * A setter definition that is prefixed with the static modifier defines a static setter.
   * Otherwise, it defines an instance setter. The name of a setter is obtained by appending the
   * string `=' to the identifier given in its signature.
   * <p>
   * Hence, a setter name can never conflict with, override or be overridden by a getter or method.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=5153
   */
  public void test_setterNameImplicitEquals() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  set foo(x) {}",
        "  foo(x) {}",
        "}",
        "main() {",
        "  A a = new A();",
        "  a.foo = 0;",
        "  a.foo(0);",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4785
   */
  public void test_labelForBlockInSwitchCase() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  switch (0) {",
        "    case 0: qwerty: {",
        "      break qwerty;",
        "    }",
        "    break;",
        "  }",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
  }

  /**
   * We should support resolving to the method "call".
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=1355
   */
  public void test_resolveCallMethod() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  call() => 42;",
        "}",
        "main() {",
        "  A a = new A();",
        "  a();",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
    // find a()
    DartIdentifier aVar = findNode(DartIdentifier.class, "a()");
    assertNotNull(aVar);
    DartUnqualifiedInvocation invocation = (DartUnqualifiedInvocation) aVar.getParent();
    // analyze a() element
    MethodElement element = (MethodElement) invocation.getElement();
    assertNotNull(element);
    assertEquals("call", element.getName());
    assertEquals(
        libraryResult.source.indexOf("call() => 42"),
        element.getNameLocation().getOffset());
  }

  /**
   * It is a compile-time error if a typedef refers to itself via a chain of references that does
   * not include a class or interface type.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3534
   */
  public void test_functionTypeAlias_selfRerences_direct() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "typedef A A();",
        "typedef B(B b);",
        "typedef C([C c]);",
        "typedef D({D d});",
        "typedef E<T extends E>();",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 2, 1, 14),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 3, 1, 15),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 4, 1, 17),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 5, 1, 17),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 6, 1, 25));
  }

  /**
   * It is a compile-time error if a typedef refers to itself via a chain of references that does
   * not include a class or interface type.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3534
   */
  public void test_functionTypeAlias_selfRerences_indirect() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "typedef B1 A1();",
        "typedef A1 B1();",
        "typedef B2 A2();",
        "typedef B2(A2 a);",
        "typedef B3 A3();",
        "typedef B3([A3 a]);",
        "typedef B4 A4();",
        "typedef B4({A4 a});",
        "typedef A5<T extends B5>();",
        "typedef B5(A5 a);",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 2, 1, 16),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 3, 1, 16),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 4, 1, 16),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 5, 1, 17),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 6, 1, 16),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 7, 1, 19),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 8, 1, 16),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 9, 1, 19),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 10, 1, 27),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 11, 1, 17));
  }
  
  /**
   * Type parameters should not conflict with formal parameters.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=5302
   */
  public void test_functionTypeAlias_typePaarameter_scope() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "typedef f<f>(f);",
        "");
    assertErrors(libraryResult.getErrors());
  }

  /**
   * It is a compile-time error if initializer list contains an initializer for a variable that
   * is not an instance variable declared in the immediately surrounding class.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3181
   */
  public void test_initializerForNotField() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "var x;",
        "class A {",
        "  A() : x = 5 {}",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.INIT_FIELD_ONLY_IMMEDIATELY_SURROUNDING_CLASS, 4, 9, 1));
  }

  /**
   * Tests that we correctly provide {@link Element#getEnclosingElement()} for method of class.
   */
  public void test_resolveClassMethod() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
                "class Object {}",
                "class Test {",
                "  foo() {",
                "    f();",
                "  }",
                "  f() {",
                "  }",
                "}");
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
    // find f() invocation
    DartInvocation invocation = findInvocationSimple(unit, "f()");
    assertNotNull(invocation);
    // referenced Element should be resolved to MethodElement
    Element methodElement = invocation.getElement();
    assertNotNull(methodElement);
    assertSame(ElementKind.METHOD, methodElement.getKind());
    assertEquals("f", ((MethodElement) methodElement).getOriginalName());
    // enclosing Element of MethodElement is ClassElement
    Element classElement = methodElement.getEnclosingElement();
    assertNotNull(classElement);
    assertSame(ElementKind.CLASS, classElement.getKind());
    assertEquals("Test", ((ClassElement) classElement).getOriginalName());
  }

  /**
   * Test that local {@link DartFunctionExpression} has {@link Element} with enclosing
   * {@link Element}.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=145
   */
  public void test_resolveLocalFunction() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "class Object {}",
            "class Test {",
            "  foo() {",
            "    f() {",
            "    }",
            "    f();",
            "  }",
            "}");
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
    // find f() invocation
    DartInvocation invocation = findInvocationSimple(unit, "f()");
    assertNotNull(invocation);
    // referenced Element should be resolved to MethodElement
    Element functionElement = invocation.getElement();
    assertNotNull(functionElement);
    assertSame(ElementKind.FUNCTION_OBJECT, functionElement.getKind());
    assertEquals("f", ((MethodElement) functionElement).getOriginalName());
    // enclosing Element of this FUNCTION_OBJECT is enclosing method
    MethodElement methodElement = (MethodElement) functionElement.getEnclosingElement();
    assertNotNull(methodElement);
    assertSame(ElementKind.METHOD, methodElement.getKind());
    assertEquals("foo", methodElement.getName());
    // use EnclosingElement methods implementations in MethodElement
    assertEquals(false, methodElement.isInterface());
    assertEquals(true, Iterables.isEmpty(methodElement.getMembers()));
    assertEquals(null, methodElement.lookupLocalElement("f"));
  }

  /**
   * It is a static warning if the type of "switch expression" may not be assigned to the type of
   * "case expression".
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3269
   */
  public void test_switchExpression_case_switchTypeMismatch() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  int v = 1;",
        "  switch (v) {",
        "    case 0: break;",
        "  }",
        "  switch (v) {",
        "    case 'a': break;",
        "  }",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE, 8, 10, 3));
  }

  /**
   * It is a compile-time error if the values of the case expressions are not compile-time
   * constants.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4553
   */
  public void test_switchExpression_case_anyConst() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  const A();",
        "}",
        "const A CONST_1 = const A();",
        "const A CONST_2 = const A();",
        "foo(var v) {",
        "  switch (v) {",
        "    case 0: break;",
        "  }",
        "  switch (v) {",
        "    case '0': break;",
        "  }",
        "  switch (v) {",
        "    case 0.0: break;",
        "  }",
        "  switch (v) {",
        "    case CONST_1: break;",
        "    case CONST_2: break;",
        "  }",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
  }

  /**
   * It is a compile-time error if the values of the case expressions are not compile-time
   * constants.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4553
   */
  public void test_switchExpression_case_notConst() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {}",
        "foo(var v) {",
        "  A notConst = new A();",
        "  switch (v) {",
        "    case notConst: break;",
        "  }",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION, 6, 10, 8));
  }
  
  /**
   * It is a compile-time error if the class C implements the operator ==.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4553
   */
  public void test_switchExpression_case_hasOperatorEquals() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class C {",
        "  const C();",
        "  operator ==(other) => false;",
        "}",
        "const C CONST = const C();",
        "foo(var v) {",
        "  switch (v) {",
        "    case CONST: break;",
        "  }",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.CASE_EXPRESSION_TYPE_SHOULD_NOT_HAVE_EQUALS, 9, 10, 5));
  }

  /**
   * It is a compile-time error if the values of the case expressions do not all have the same type.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3528
   */
  public void test_switchExpression_case_differentTypes() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "foo(var v) {",
        "  switch (v) {",
        "    case 0: break;",
        "    case 'a': break;",
        "  }",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.CASE_EXPRESSIONS_SHOULD_BE_SAME_TYPE, 5, 10, 3));
  }
  
  public void test_switchExpression_case_constLocalVariable() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "foo(var v) {",
        "  const int VALUE = 0;",
        "  switch (v) {",
        "    case VALUE: break;",
        "  }",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
  }
  
  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=2862
   */
  public void test_switchCase_fallThrough() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "foo(int x) {",
        "  while (true) {",
        "    switch (x) {",
        "      case 0:",
        "        break;",
        "      case 1:",
        "        continue;",
        "      case 2:",
        "        return;",
        "      case 3:",
        "        throw new Exception();",
        "      case 4:",
        "        bar();",
        "    }",
        "  }",
        "}",
        "bar() {}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.SWITCH_CASE_FALL_THROUGH, 14, 9, 6));
  }

  /**
   * Language specification requires that factory should be declared in class. However declaring
   * factory on top level should not cause exceptions in compiler.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=345
   */
  public void test_badTopLevelFactory() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary("factory foo() {}");
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
    DartMethodDefinition factory = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    assertNotNull(factory);
    // this factory has name, which is allowed for normal method
    assertEquals(true, factory.getName() instanceof DartIdentifier);
    assertEquals("foo", ((DartIdentifier) factory.getName()).getName());
    // compilation error expected
    assertBadTopLevelFactoryError(libraryResult);
  }

  /**
   * Asserts that given {@link AnalyzeLibraryResult} contains {@link DartCompilationError} for
   * invalid factory on top level.
   */
  private void assertBadTopLevelFactoryError(AnalyzeLibraryResult libraryResult) {
    List<DartCompilationError> compilationErrors = libraryResult.getCompilationErrors();
    assertEquals(1, compilationErrors.size());
    DartCompilationError compilationError = compilationErrors.get(0);
    assertEquals(ParserErrorCode.FACTORY_CANNOT_BE_TOP_LEVEL, compilationError.getErrorCode());
    assertEquals(1, compilationError.getLineNumber());
    assertEquals(1, compilationError.getColumnNumber());
    assertEquals("factory".length(), compilationError.getLength());
  }

  /**
   * @return the {@link DartInvocation} with given source. This is inaccurate approach, but good
   *         enough for specific tests.
   */
  private static DartInvocation findInvocationSimple(DartNode rootNode,
      final String invocationString) {
    final DartInvocation invocationRef[] = new DartInvocation[1];
    rootNode.accept(new ASTVisitor<Void>() {
      @Override
      public Void visitInvocation(DartInvocation node) {
        if (node.toSource().equals(invocationString)) {
          invocationRef[0] = node;
        }
        return super.visitInvocation(node);
      }
    });
    return invocationRef[0];
  }

  /**
   * In contrast, if A is intended to be concrete, the checker should warn about all unimplemented
   * methods, but allow clients to instantiate it freely.
   */
  public void test_warnAbstract_onConcreteClassDeclaration_hasUnimplemented_method_fromInterface()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "interface Foo {",
            "  int fooA;",
            "  void fooB();",
            "}",
            "interface Bar {",
            "  void barA();",
            "}",
            "class A implements Foo, Bar {",
            "}",
            "main() {",
            "  new A();",
            "}");
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.CONTRETE_CLASS_WITH_UNIMPLEMENTED_MEMBERS, 8, 7, 1));
    {
      DartCompilationError typeError = libraryResult.getTypeErrors().get(0);
      String message = typeError.getMessage();
      assertTrue(message.contains("# From Foo:"));
      assertTrue(message.contains("int fooA"));
      assertTrue(message.contains("void fooB()"));
      assertTrue(message.contains("# From Bar:"));
      assertTrue(message.contains("void barA()"));
    }
  }

  /**
   * In contrast, if A is intended to be concrete, the checker should warn about all unimplemented
   * methods, but allow clients to instantiate it freely.
   */
  public void test_warnAbstract_onConcreteClassDeclaration_hasUnimplemented_method_inherited()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
                "abstract class A {",
                "  abstract void foo();",
                "}",
                "class B extends A {",
                "}",
                "main() {",
                "  new B();",
                "}");
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.CONTRETE_CLASS_WITH_UNIMPLEMENTED_MEMBERS, 4, 7, 1));
    {
      DartCompilationError typeError = libraryResult.getTypeErrors().get(0);
      String message = typeError.getMessage();
      assertTrue(message.contains("# From A:"));
      assertTrue(message.contains("void foo()"));
    }
  }
  
  /**
   * In contrast, if A is intended to be concrete, the checker should warn about all unimplemented
   * methods, but allow clients to instantiate it freely.
   */
  public void test_warnAbstract_onConcreteClassDeclaration_hasUnimplemented_method_self()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "class A {",
            "  abstract void foo();",
            "}",
            "main() {",
            "  new A();",
            "}");
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.CONTRETE_CLASS_WITH_UNIMPLEMENTED_MEMBERS, 1, 7, 1));
    {
      DartCompilationError typeError = libraryResult.getTypeErrors().get(0);
      String message = typeError.getMessage();
      assertTrue(message.contains("# From A:"));
      assertTrue(message.contains("void foo()"));
    }
  }

  public void test_warnAbstract_onConcreteClassDeclaration_hasUnimplemented_getter()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
                "class A {",
                "  abstract get x;",
                "}",
                "main() {",
                "  new A();",
                "}");
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.CONTRETE_CLASS_WITH_UNIMPLEMENTED_MEMBERS, 1, 7, 1));
  }

  /**
   * There was bug that implementing setter still caused warning.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=5327
   */
  public void test_warnAbstract_whenInstantiate_implementSetter() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "interface I {",
        "  set foo(x);",
        "}",
        "class A implements I {",
        "  set foo(x) {}",
        "}",
        "main() {",
        "  new A();",
        "}");
    assertErrors(libraryResult.getTypeErrors());
  }

  /**
   * When both getter and setter were abstract and only getter implemented, we should report error.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=5327
   */
  public void test_warnAbstract_whenInstantiate_implementsOnlyGetter() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "interface I {",
        "  get foo;",
        "  set foo(x);",
        "}",
        "class A implements I {",
        "  get foo => 0;",
        "}",
        "main() {",
        "  new A();",
        "}");
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.CONTRETE_CLASS_WITH_UNIMPLEMENTED_MEMBERS, 5, 7, 1));
  }
  
  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=5327
   */
  public void test_warnAbstract_whenInstantiate_implementsSetter_inSuperClass() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "interface I {",
        "  get foo;",
        "  set foo(x);",
        "}",
        "abstract class A implements I {",
        "  abstract get foo;",
        "  set foo(x) {}",
        "}",
        "class B extends A {",
        "  get foo => 0;",
        "}",
        "main() {",
        "  new B();",
        "}");
    assertErrors(libraryResult.getTypeErrors());
  }

  public void test_warnAbstract_onAbstractClass_whenInstantiate_normalConstructor()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "abstract class A {",
            "  abstract void bar();",
            "}",
            "main() {",
            "  new A();",
            "}");
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.INSTANTIATION_OF_ABSTRACT_CLASS, 5, 7, 1));
  }

  /**
   * Factory constructor can instantiate any class and return it non-abstract class instance, Even
   * thought this is an abstract class, there should be no warnings for the invocation of the
   * factory constructor.
   */
  public void test_warnAbstract_onAbstractClass_whenInstantiate_factoryConstructor()
      throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "abstract class A {", // explicitly abstract
        "  factory A() {",
        "    return null;",
        "  }",
        "}",
        "class C {",
        "  foo() {",
        "    return new A();", // no error - factory constructor
        "  }",
        "}");
    assertErrors(libraryResult.getTypeErrors());
  }

  /**
   * Factory constructor can instantiate any class and return it non-abstract class instance, Even
   * thought this is an abstract class, there should be no warnings for the invocation of the
   * factory constructor.
   */
  public void test_wanrAbstract_onAbstractClass_whenInstantiate_factoryConstructor2()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "abstract class A {", // class is abstract
            "  factory A() {",
            "    return null;",
            "  }",
            "  abstract method();",
            "}",
            "class C {",
            "  foo() {",
            "    return new A();",  // no error, factory constructor
            "  }",
            "}");
    assertErrors(libraryResult.getTypeErrors());
  }

  /**
   * Spec 7.3 It is a static warning if a setter declares a return type other than void.
   */
  public void testWarnOnNonVoidSetter() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
                "class A {",
                "  void set foo(bool a) {}",
                "  set bar(bool a) {}",
                "  dynamic set baz(bool a) {}",
                "  bool set bob(bool a) {}",
                "}");
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.SETTER_RETURN_TYPE, 4, 3, 7),
        errEx(TypeErrorCode.SETTER_RETURN_TYPE, 5, 3, 4));
  }

  public void test_callUnknownFunction() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  foo();",
        "}",
        "");
    assertErrors(libraryResult.getErrors(), errEx(ResolverErrorCode.CANNOT_RESOLVE_METHOD, 3, 3, 3));
  }

  /**
   * We should be able to call <code>Function</code> even if it is in the field.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=933
   */
  public void test_callFunctionFromField() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "class WorkElement {",
            "  Function run;",
            "}",
            "foo(WorkElement e) {",
            "  e.run();",
            "}");
    assertErrors(libraryResult.getTypeErrors());
  }

  /**
   * When we attempt to use function as type, we should report only one error.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3309
   */
  public void test_useFunctionAsType() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "func() {}",
        "main() {",
        "  new func();",
        "}",
        "");
    assertErrors(libraryResult.getErrors(), errEx(TypeErrorCode.NOT_A_TYPE, 4, 7, 4));
  }

  /**
   * There was problem that {@link DartForInStatement} visits "iterable" two times. At first time we
   * set {@link MethodElement}, because we resolve it to getter. However because of this at second
   * time we can not resolve. Solution - don't try to resolve second time, we already done at first
   * time. Note: double getter is important.
   */
  public void test_doubleGetterAccess_inForEach() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
            "class Test {",
            "  Iterable get iter {}",
            "}",
            "Test get test {}",
            "f() {",
            "  for (var v in test.iter) {}",
            "}",
            "");
    assertErrors(libraryResult.getTypeErrors());
  }

  /**
   * Test for errors and warnings related to positional and named arguments for required and
   * optional parameters.
   */
  public void test_invocationArguments() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
                "/* 01 */ foo() {",
                "/* 02 */   f_0_0();",
                "/* 03 */   f_0_0(-1);",
                "/* 04 */",
                "/* 05 */   f_1_0();",
                "/* 06 */   f_1_0(-1);",
                "/* 07 */   f_1_0(-1, -2, -3);",
                "/* 08 */",
                "/* 09 */   f_2_0();",
                "/* 10 */",
                "/* 11 */   f_0_1();",
                "/* 12 */   f_0_1(1);",
                "/* 13 */   f_0_1(0, 0);",
                "/* 14 */   f_0_1(n1: 1);",
                "/* 15 */   f_0_1(x: 1);",
                "/* 16 */   f_0_1(n1: 1, n1: 2);",
                "}",
                "",
                "f_0_0() {}",
                "f_1_0(r1) {}",
                "f_2_0(r1, r2) {}",
                "f_0_1({n1}) {}",
                "f_0_2({n1, n2}) {}",
                "");
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.EXTRA_ARGUMENT, 3, 18, 2),
        errEx(TypeErrorCode.MISSING_ARGUMENT, 5, 12, 5),
        errEx(TypeErrorCode.EXTRA_ARGUMENT, 7, 22, 2),
        errEx(TypeErrorCode.EXTRA_ARGUMENT, 7, 26, 2),
        errEx(TypeErrorCode.MISSING_ARGUMENT, 9, 12, 5),
        errEx(TypeErrorCode.EXTRA_ARGUMENT, 12, 18, 1),
        errEx(TypeErrorCode.EXTRA_ARGUMENT, 13, 18, 1),
        errEx(TypeErrorCode.EXTRA_ARGUMENT, 13, 21, 1),
        errEx(TypeErrorCode.NO_SUCH_NAMED_PARAMETER, 15, 18, 4));
    assertErrors(
        libraryResult.getCompilationErrors(),
        errEx(ResolverErrorCode.DUPLICATE_NAMED_ARGUMENT, 16, 25, 5));
  }
  
  /**
   * Test that optional positional and named parameters are handled separately.
   */
  public void test_invocationArguments2() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "func([int np1, int np2, int np3]) {}",
        "main() {",
        "  func(np1: 1, np2: 2, np3: 2);",
        "}",
        "");
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.NO_SUCH_NAMED_PARAMETER, 4, 8, 6),
        errEx(TypeErrorCode.NO_SUCH_NAMED_PARAMETER, 4, 16, 6),
        errEx(TypeErrorCode.NO_SUCH_NAMED_PARAMETER, 4, 24, 6));
  }

  /**
   * We should return correct {@link Type} for {@link DartNewExpression}.
   */
  public void test_DartNewExpression_getType() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class A {",
            "  A() {}",
            "  A.foo() {}",
            "}",
            "var a1 = new A();",
            "var a2 = new A.foo();",
            "");
    assertErrors(libraryResult.getErrors());
    // new A()
    {
      DartNewExpression newExpression = (DartNewExpression) getTopLevelFieldInitializer(testUnit, 1);
      Type newType = newExpression.getType();
      assertEquals("A", newType.getElement().getName());
    }
    // new A.foo()
    {
      DartNewExpression newExpression = (DartNewExpression) getTopLevelFieldInitializer(testUnit, 2);
      Type newType = newExpression.getType();
      assertEquals("A", newType.getElement().getName());
    }
  }

  /**
   * Expects that given {@link DartUnit} has {@link DartFieldDefinition} as <code>index</code> top
   * level node and return initializer of first {@link DartField}.
   */
  private static DartExpression getTopLevelFieldInitializer(DartUnit unit, int index) {
    DartFieldDefinition fieldDefinition = (DartFieldDefinition) unit.getTopLevelNodes().get(index);
    DartField field = fieldDefinition.getFields().get(0);
    return field.getValue();
  }

  /**
   * If property has only setter, no getter, then attempt to use getter should cause static type
   * warning.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=1251
   */
  public void test_setterOnlyProperty_noGetter() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "class SetOnly {",
            "  set foo(arg) {}",
            "}",
            "class SetOnlyWrapper {",
            "  SetOnly setOnly;",
            "}",
            "",
            "main() {",
            "  SetOnly setOnly = new SetOnly();",
            "  setOnly.foo = 1;", // 10: OK, use setter
            "  setOnly.foo += 2;", // 11: ERR, no getter
            "  print(setOnly.foo);", // 12: ERR, no getter
            "  var bar;",
            "  bar = setOnly.foo;", // 14: ERR, assignment, but we are not LHS
            "  bar = new SetOnlyWrapper().setOnly.foo;", // 15: ERR, even in chained expression
            "  new SetOnlyWrapper().setOnly.foo = 3;", // 16: OK
            "}");
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.FIELD_HAS_NO_GETTER, 11, 11, 3),
        errEx(TypeErrorCode.FIELD_HAS_NO_GETTER, 12, 17, 3),
        errEx(TypeErrorCode.FIELD_HAS_NO_GETTER, 14, 17, 3),
        errEx(TypeErrorCode.FIELD_HAS_NO_GETTER, 15, 38, 3));
  }

  public void test_setterOnlyProperty_normalField() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "class A {",
            "  var foo;",
            "}",
            "",
            "main() {",
            "  A a = new A();",
            "  a.foo = 1;",
            "  a.foo += 2;",
            "  print(a.foo);",
            "}");
    assertErrors(libraryResult.getTypeErrors());
  }

  public void test_setterOnlyProperty_getterInSuper() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
                "class A {",
                "  get foo {}",
                "}",
                "class B extends A {",
                "  set foo(arg) {}",
                "}",
                "",
                "main() {",
                "  B b = new B();",
                "  b.foo = 1;",
                "  b.foo += 2;",
                "  print(b.foo);",
                "}");
    assertErrors(libraryResult.getTypeErrors());
  }

  public void test_setterOnlyProperty_getterInInterface() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
                "interface A {",
                "  get foo {}",
                "}",
                "abstract class B implements A {",
                "  set foo(arg) {}",
                "}",
                "",
                "main() {",
                "  B b = new B();",
                "  b.foo = 1;",
                "  b.foo += 2;",
                "  print(b.foo);",
                "}");
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.INSTANTIATION_OF_ABSTRACT_CLASS, 9, 13, 1));
  }

  public void test_getterOnlyProperty_noSetter() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
                "class GetOnly {",
                "  get foo {}",
                "}",
                "class GetOnlyWrapper {",
                "  GetOnly getOnly;",
                "}",
                "",
                "main() {",
                "  GetOnly getOnly = new GetOnly();",
                "  print(getOnly.foo);", // 10: OK, use getter
                "  getOnly.foo = 1;", // 11: ERR, no setter
                "  getOnly.foo += 2;", // 12: ERR, no setter
                "  var bar;",
                "  bar = getOnly.foo;", // 14: OK, use getter
                "  new GetOnlyWrapper().getOnly.foo = 3;", // 15: ERR, no setter
                "  bar = new GetOnlyWrapper().getOnly.foo;", // 16: OK, use getter
                "}");
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.FIELD_HAS_NO_SETTER, 11, 11, 3),
        errEx(TypeErrorCode.FIELD_HAS_NO_SETTER, 12, 11, 3),
        errEx(TypeErrorCode.FIELD_HAS_NO_SETTER, 15, 32, 3));
  }

  public void test_getterOnlyProperty_setterInSuper() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
                "class A {",
                "  set foo(arg) {}",
                "}",
                "class B extends A {",
                "  get foo {}",
                "}",
                "",
                "main() {",
                "  B b = new B();",
                "  b.foo = 1;",
                "  b.foo += 2;",
                "  print(b.foo);",
                "}");
    assertErrors(libraryResult.getTypeErrors());
  }

  public void test_getterOnlyProperty_setterInInterface() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
                "interface A {",
                "  set foo(arg) {}",
                "}",
                "abstract class B implements A {",
                "  get foo {}",
                "}",
                "",
                "main() {",
                "  B b = new B();",
                "  b.foo = 1;",
                "  b.foo += 2;",
                "  print(b.foo);",
                "}");
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.INSTANTIATION_OF_ABSTRACT_CLASS, 9, 13, 1));
  }

  public void test_assert_notUserFunction() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  assert(true);",
        "  assert(false);",
        "  assert('message');", // not 'bool'
        "  assert('null');", // not 'bool'
        "  assert(0);", // not 'bool'
        "  assert(f() {});", // OK, dynamic
        "  assert(bool f() {});", // OK, '() -> bool'
        "  assert(Object f() {});", // OK, 'Object' compatible with 'bool'
        "  assert(String f() {});", // not '() -> bool', return type
        "  assert(bool f(x) {});", // not '() -> bool', parameter
        "  assert(true, false);", // not single argument
        "  assert;", // incomplete
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ParserErrorCode.EXPECTED_TOKEN, 13, 10, 4),
        errEx(ParserErrorCode.EXPECTED_TOKEN, 14, 9, 1),
        errEx(TypeErrorCode.ASSERT_BOOL, 5, 10, 9),
        errEx(TypeErrorCode.ASSERT_BOOL, 6, 10, 6),
        errEx(TypeErrorCode.ASSERT_BOOL, 7, 10, 1),
        errEx(TypeErrorCode.ASSERT_BOOL, 11, 10, 13),
        errEx(TypeErrorCode.ASSERT_BOOL, 12, 10, 12));
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3264
   */
  public void test_initializingFormalType_useFieldType() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  final double f;",
        "  A(this.f);",
        "}",
        "class B {",
        "  B(this.f);",
        "  final double f;",
        "}",
        "",
        "main() {",
        "  new A('0');",
        "  new B('0');",
        "}",
        "");
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE, 12, 9, 3),
        errEx(TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE, 13, 9, 3));
  }

  /**
   * If "this.field" parameter has declared type, it should be assignable to the field.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3264
   */
  public void test_initializingFormalType_compatilityWithFieldType() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  final double f;",
        "  A.useDynamic(dynamic this.f);",
        "  A.useNum(num this.f);",
        "  A.useString(String this.f);",
        "}",
        "");
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE, 6, 15, 13));
  }

  public void test_finalField_inClass() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  final f;",
        "}",
        "main() {",
        "  A a = new A();",
        "  a.f = 0;", // 6: ERR, is final
        "  a.f += 1;", // 7: ERR, is final
        "  print(a.f);", // 8: OK, can read
        "}");
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.FIELD_IS_FINAL, 7, 5, 1),
        errEx(TypeErrorCode.FIELD_IS_FINAL, 8, 5, 1));
  }

  public void test_finalField_inInterface() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "interface I default A {",
        "  final f;",
        "}",
        "class A implements I {",
        "  var f;",
        "}",
        "main() {",
        "  I a = new I();",
        "  a.f = 0;", // 6: ERR, is final
        "  a.f += 1;", // 7: ERR, is final
        "  print(a.f);", // 8: OK, can read
        "}");
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.FIELD_IS_FINAL, 10, 5, 1),
        errEx(TypeErrorCode.FIELD_IS_FINAL, 11, 5, 1));
  }

  public void test_notFinalField() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "interface I default A {",
        "  var f;",
        "}",
        "class A implements I {",
        "  var f;",
        "}",
        "main() {",
        "  I a = new I();",
        "  a.f = 0;", // 6: OK, field "f" is not final
        "  a.f += 1;", // 7: OK, field "f" is not final
        "  print(a.f);", // 8: OK, can read
        "}");
    assertErrors(libraryResult.getTypeErrors());
  }

  public void test_constField() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "const f = 1;",
        "class A {",
        "  const f = 1;",
        "  method() {",
        "    f = 2;",
        "    this.f = 2;",
        "  }",
        "}",
        "main() {",
        "  f = 2;",
        "  A a = new A();",
        "  a.f = 2;",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.CANNOT_ASSIGN_TO_FINAL, 6, 5, 1),
        errEx(ResolverErrorCode.CANNOT_ASSIGN_TO_FINAL, 7, 5, 6),
        errEx(ResolverErrorCode.CANNOT_ASSIGN_TO_FINAL, 11, 3, 1),
        errEx(TypeErrorCode.FIELD_IS_FINAL, 13, 5, 1));
  }
  
  public void test_identicalFunction() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "const A = 1;",
        "const B = 2;",
        "const C = identical(A, B);",
        "");
    assertErrors(libraryResult.getErrors());
  }

  /**
   * It is a compile-time error to use type variables in "const" instance creation.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=2379
   */
  public void test_constInstantiation_withTypeVariable() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A<T> {",
        "  const A();",
        "  const A.name();",
        "}",
        "class B<U> {",
        "  test() {",
        "    const A<U>();",
        "    const A<U>.name();",
        "  }",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.CONST_WITH_TYPE_VARIABLE, 8, 13, 1),
        errEx(ResolverErrorCode.CONST_WITH_TYPE_VARIABLE, 9, 13, 1));
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3182
   */
  public void test_extendNotType() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "int A;",
        "class B extends A {",
        "}",
        "",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.NOT_A_TYPE, 3, 17, 1));
  }

  public void test_constInstanceCreation_noSuchType() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  const NoSuchType();",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.NO_SUCH_TYPE_CONST, 3, 9, 10));
  }
  
  public void test_constInstanceCreation_noSuchConstructor() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {}",
        "main() {",
        "  const A.noSuchName();",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.NEW_EXPRESSION_NOT_CONST_CONSTRUCTOR, 4, 11, 10));
  }
  
  public void test_constInstanceCreation_notType() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "var notType;",
        "main() {",
        "  const notType();",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.NOT_A_TYPE, 4, 9, 7));
  }

  /**
   * Test for variants of {@link DartMethodDefinition} return types.
   */
  public void test_methodReturnTypes() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
                "// filler filler filler filler filler filler filler filler filler filler",
                "int fA() {}",
                "dynamic fB() {}",
                "void fC() {}",
                "fD() {}",
                "");
    assertErrors(libraryResult.getTypeErrors());
    {
      DartMethodDefinition fA = (DartMethodDefinition) testUnit.getTopLevelNodes().get(0);
      assertEquals("int", fA.getElement().getReturnType().getElement().getName());
    }
    {
      DartMethodDefinition fB = (DartMethodDefinition) testUnit.getTopLevelNodes().get(1);
      assertEquals("dynamic", fB.getElement().getReturnType().getElement().getName());
    }
    {
      DartMethodDefinition fC = (DartMethodDefinition) testUnit.getTopLevelNodes().get(2);
      assertEquals("void", fC.getElement().getReturnType().getElement().getName());
    }
    {
      DartMethodDefinition fD = (DartMethodDefinition) testUnit.getTopLevelNodes().get(3);
      assertEquals("dynamic", fD.getElement().getReturnType().getElement().getName());
    }
  }

  public void test_bindToLibraryFunctionFirst() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "foo() {}",
        "class A {",
        " foo() {}",
        "}",
        "class B extends A {",
        "  bar() {",
        "    foo();",
        "  }",
        "}",
        "");
    // Find foo() invocation.
    DartUnqualifiedInvocation invocation;
    {
      DartClass classB = (DartClass) testUnit.getTopLevelNodes().get(2);
      DartMethodDefinition methodBar = (DartMethodDefinition) classB.getMembers().get(0);
      DartExprStmt stmt = (DartExprStmt) methodBar.getFunction().getBody().getStatements().get(0);
      invocation = (DartUnqualifiedInvocation) stmt.getExpression();
    }
    // Check that unqualified foo() invocation is resolved to the top-level (library) function.
    NodeElement element = invocation.getTarget().getElement();
    assertNotNull(element);
    assertSame(testUnit, element.getNode().getParent());
  }

  /**
   * If there was <code>import</code> with invalid {@link URI}, it should be reported as error, not
   * as an exception.
   */
  public void test_invalidImportUri() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "library test;",
        "import 'badURI';",
        "");
    assertErrors(libraryResult.getErrors(), errEx(DartCompilerErrorCode.MISSING_SOURCE, 3, 1, 16));
  }

  /**
   * If there was <code>part</code> with invalid {@link URI}, it should be reported as error, not
   * as an exception.
   */
  public void test_invalidSourceUri() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "library test;",
        "part 'badURI';",
        "");
    assertErrors(libraryResult.getErrors(), errEx(DartCompilerErrorCode.MISSING_SOURCE, 3, 1, 14));
  }

  public void test_mapLiteralKeysUnique() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "var m = {'a' : 0, 'b': 1, 'a': 2};",
        "");
    assertErrors(libraryResult.getErrors(), errEx(TypeErrorCode.MAP_LITERAL_KEY_UNIQUE, 2, 27, 3));
  }

  /**
   * No required parameter "x".
   */
  public void test_implementsAndOverrides_noRequiredParameter() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "abstract class I {",
            "  foo(x);",
            "}",
            "class C implements I {",
            "  foo() {}",
            "}");
    assertErrors(
        result.getErrors(),
        errEx(ResolverErrorCode.CANNOT_OVERRIDE_METHOD_NUM_REQUIRED_PARAMS, 5, 3, 3));
  }

  /**
   * It is OK to add more named parameters, if list prefix is same as in "super".
   */
  public void test_implementsAndOverrides_additionalNamedParameter() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "abstract class I {",
            "  foo({x});",
            "}",
            "class C implements I {",
            "  foo({x,y}) {}",
            "}");
    assertErrors(result.getErrors());
  }

  public void test_implementsAndOverrides_lessNamedParameter() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "abstract class A {",
        "  foo({x, y});",
        "}",
        "abstract class B extends A {",
        "  foo({x});",
        "}");
    assertErrors(
        result.getErrors(),
        errEx(ResolverErrorCode.CANNOT_OVERRIDE_METHOD_NAMED_PARAMS, 5, 3, 3));
  }

  /**
   * We override "foo" with method that has named parameter. So, this method is not abstract and
   * class is not abstract too, so no warning.
   */
  public void test_implementsAndOverrides_additionalNamedParameter_notAbstract() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "abstract class A {",
            "  foo();",
            "}",
            "class B extends A {",
            "  foo({x}) {}",
            "}",
            "bar() {",
            "  new B();",
            "}",
            "");
    assertErrors(result.getErrors());
  }

  public void test_implementsAndOverrides_lessOptionalPositionalParameter() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "abstract class A {",
        "  foo([x, y]);",
        "}",
        "abstract class B extends A {",
        "  foo([x]);",
        "}");
    assertErrors(
        result.getErrors(),
        errEx(ResolverErrorCode.CANNOT_OVERRIDE_METHOD_OPTIONAL_PARAMS, 5, 3, 3));
  }
  
  public void test_implementsAndOverrides_moreOptionalPositionalParameter() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "abstract class A {",
        "  foo([x]);",
        "}",
        "abstract class B extends A {",
        "  foo([a, b]);",
        "}");
    assertErrors(result.getErrors());
  }

  /**
   * No required parameter "x". Named parameter "x" is not enough.
   */
  public void test_implementsAndOverrides_extraRequiredParameter() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "abstract class I {",
            "  foo();",
            "}",
            "class C implements I {",
            "  foo(x) {}",
            "}");
    assertErrors(
        result.getErrors(),
        errEx(ResolverErrorCode.CANNOT_OVERRIDE_METHOD_NUM_REQUIRED_PARAMS, 5, 3, 3));
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3183
   */
  public void test_implementsAndOverrides_differentDefaultValue_optional() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class A {",
            "  f1([x]) {}",
            "  f2([x = 1]) {}",
            "  f3([x = 1]) {}",
            "  f4([x = 1]) {}",
            "}",
            "class B extends A {",
            "  f1([x = 2]) {}",
            "  f2([x]) {}",
            "  f3([x = 2]) {}",
            "  f4([x = '2']) {}",
            "}",
            "");
    assertErrors(
        result.getErrors(),
        errEx(TypeErrorCode.CANNOT_OVERRIDE_METHOD_DEFAULT_VALUE, 10, 7, 1),
        errEx(TypeErrorCode.CANNOT_OVERRIDE_METHOD_DEFAULT_VALUE, 11, 7, 5),
        errEx(TypeErrorCode.CANNOT_OVERRIDE_METHOD_DEFAULT_VALUE, 12, 7, 7));
  }
  
  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3183
   */
  public void test_implementsAndOverrides_differentDefaultValue_named() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class A {",
            "  f1({x}) {}",
            "  f2({x: 1}) {}",
            "  f3({x: 1}) {}",
            "  f4({x: 1}) {}",
            "}",
            "class B extends A {",
            "  f1({x: 2}) {}",
            "  f2({x]) {}",
            "  f3({x: 2}) {}",
            "  f4({x: '2'}) {}",
            "}",
            "");
    assertErrors(
        result.getErrors(),
        errEx(TypeErrorCode.CANNOT_OVERRIDE_METHOD_DEFAULT_VALUE, 10, 7, 1),
        errEx(TypeErrorCode.CANNOT_OVERRIDE_METHOD_DEFAULT_VALUE, 11, 7, 4),
        errEx(TypeErrorCode.CANNOT_OVERRIDE_METHOD_DEFAULT_VALUE, 12, 7, 6));
  }

  /**
   * It is a compile-time error if an instance method m1 overrides an instance member m2 and m1 does
   * not declare all the named parameters declared by m2 in the same order.
   * <p>
   * Here: no "y" parameter.
   */
  public void test_implementsAndOverrides_noNamedParameter() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "abstract class I {",
            "  foo({x,y});",
            "}",
            "class C implements I {",
            "  foo({x}) {}",
            "}");
    assertErrors(
        result.getErrors(),
        errEx(ResolverErrorCode.CANNOT_OVERRIDE_METHOD_NAMED_PARAMS, 5, 3, 3));
  }

  public void test_metadataCommentOverride_OK_method() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  foo() {}",
        "}",
        "class B extends A {",
        "  // @override",
        "  foo() {}",
        "}",
        "");
    assertErrors(result.getErrors());
  }

  public void test_metadataCommentOverride_Bad_method() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "}",
        "class B extends A {",
        "  // @override",
        "  foo() {}",
        "}",
        "");
    assertErrors(
        result.getErrors(),
        errEx(ResolverErrorCode.INVALID_OVERRIDE_METADATA, 6, 3, 3));
  }

  public void testImplementsAndOverrides5() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "abstract class I {",
            "  foo({y,x});",
            "}",
            "class C implements I {",
            "  foo({x,y}) {}",
            "}");
    assertErrors(result.getErrors());
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=1936
   */
  public void test_propertyAccess_whenExtendsUnknown() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class C extends Unknown {",
            "  foo() {",
            "    this.elements;",
            "  }",
            "}");
    assertErrors(result.getErrors(), errEx(ResolverErrorCode.NO_SUCH_TYPE, 2, 17, 7));
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3860
   */
  public void test_setterGetterDifferentStatic() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class A {",
            "  static get field => 0;",
            "         set field(var v) {}",
            "}",
            "class B {",
            "         get field => 0;",
            "  static set field(var v) {}",
            "}",
            "");
    assertErrors(result.getErrors(),
        errEx(ResolverErrorCode.FIELD_GETTER_SETTER_SAME_STATIC, 4, 14, 5),
        errEx(ResolverErrorCode.FIELD_GETTER_SETTER_SAME_STATIC, 8, 14, 5));
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=380
   */
  public void test_setterGetterDifferentType() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class A {} ",
            "class B extends A {}",
            "class C {",
            "  A getterField; ",
            "  B setterField; ",
            "  A get field { return getterField; }",
            "  void set field(B arg) { setterField = arg; }",
            "}",
            "main() {",
            "  C instance = new C();",
            "  instance.field = new B();",
            "  A resultA = instance.field;",
            "  instance.field = new A();",
            "  B resultB = instance.field;",
            "}");
    assertErrors(result.getErrors());
  }


  public void test_setterGetterAssignable1() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class A {} ",
            "A topGetterField; ",
            "var topSetterField; ",
            "A get topField { return topGetterField; }",
            "void set topField(arg) { topSetterField = arg; }",
            "class C {",
            "  A getterField; ",
            "  var setterField; ",
            "  A get field { return getterField; }",
            "  void set field(arg) { setterField = arg; }",
            "}");
    assertErrors(result.getErrors());
  }

  public void test_setterGetterAssignable2() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class A {} ",
            "var topGetterField; ",
            "A topSetterField; ",
            "get topField { return topGetterField; }",
            "void set topField(A arg) { topSetterField = arg; }",
            "class C {",
            "  var getterField; ",
            "  A setterField; ",
            "  get field { return getterField; }",
            "  void set field(A arg) { setterField = arg; }",
            "}");
    assertErrors(result.getErrors());
  }

  public void test_setterGetterNotAssignable() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class A {} ",
            "class B {}",
            "A topGetterField; ",
            "B topSetterField; ",
            "A get topField { return topGetterField; }",
            "void set topField(B arg) { topSetterField = arg; }",
            "class C {",
            "  A getterField; ",
            "  B setterField; ",
            "  A get field { return getterField; }",
            "  void set field(B arg) { setterField = arg; }",
            "}");
    assertErrors(result.getErrors(),
        errEx(TypeErrorCode.SETTER_TYPE_MUST_BE_ASSIGNABLE, 7, 19, 5),
        errEx(TypeErrorCode.SETTER_TYPE_MUST_BE_ASSIGNABLE, 12, 18, 5));
  }

  public void test_setterInvokedAsMethod() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class C {",
            "  void set foo(String arg) {}",
            "} ",
            "method() {",
            " C c = new C();",
            " c.foo(1);",
            "}");
    /* This could probably use a better error message.  The user likely intends
     * to set the property foo, but it is invoking foo as a getter and
     * invoking the result.
     */
    assertErrors(result.getErrors(),
        errEx(TypeErrorCode.USE_ASSIGNMENT_ON_SETTER, 7, 4, 3));
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3221
   */
  public void test_conditionalExpressionType() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "// filler filler filler filler filler filler filler filler filler filler",
            "main() {",
            "  bool x = (true ? 1 : 2.0);",
            "}", "");
    List<DartCompilationError> errors = result.getErrors();
    assertErrors(errors, errEx(TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE, 3, 12, 16));
    {
      String message = errors.get(0).getMessage();
      assertTrue(message.contains("'num'"));
      assertTrue(message.contains("'bool'"));
    }
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4394
   */
  public void test_conditionalExpressionType_genericInterface() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  Collection<int> test = true ? new Set<int>() : const [null];",
        "}",
        "");
    assertErrors(result.getErrors());
  }

  public void test_typeVariableBoundsMismatch() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "// filler filler filler filler filler filler filler filler filler filler",
            "abstract class I<T extends num> { }",
            "class A<T extends num> implements I<T> { }",
            "class B<T> implements I<T> { }"); // static type error B.T not assignable to num
    assertErrors(result.getErrors(), errEx(TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE, 4, 25, 1));
  }

  public void test_typeVariableBoundsMismatch2() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class C<T extends num> { }",
            "class A<T extends num> extends C<T> { }",
            "class B<T> extends C<T> { }"); // static type error B.T not assignable to num
    assertErrors(result.getErrors(), errEx(TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE, 4, 22, 1));
  }

  public void test_typeVariableBoundsCheckNew() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "class Object {}",
        "class A { }",
        "class B { }",
        "class C<T extends A> { }",
        "method() {",
        "  new C<B>();", // B not assignable to A
        "}");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE, 6, 9, 1));
  }

  /**
   * When we check getter/setter compatibility, we should compare propagated type variables.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3067
   */
  public void test_typeVariables_getterSetter() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class Base1<T1> {",
            "  T1 get val {}",
            "}",
            "class Base2<T2> extends Base1<T2> {",
            "}",
            "class Sub<T3> extends Base2<T3> {",
            "  void set val(T3 value) {}",
            "}",
            "");
    assertErrors(result.getErrors());
  }

  public void test_inferredTypes_noMemberWarnings() throws Exception {
    // disabled by default
    {
      AnalyzeLibraryResult result = analyzeLibrary(
          "// filler filler filler filler filler filler filler filler filler filler",
          "class A {}",
          "class B extends A {",
          "  var f;",
          "  m() {}",
          "}",
          "foo(A a) {",
          "  var v = a;",
          "  v.f = 0;",
          "  v.m();",
          "}",
          "");
      assertErrors(result.getErrors());
    }
    // use CompilerConfiguration to enable
    {
      compilerConfiguration = new DefaultCompilerConfiguration(new CompilerOptions() {
        @Override
        public boolean typeChecksForInferredTypes() {
          return true;
        }
      });
      AnalyzeLibraryResult result = analyzeLibrary(
          "// filler filler filler filler filler filler filler filler filler filler",
          "class A {}",
          "class B extends A {",
          "  var f;",
          "  m() {}",
          "}",
          "foo(A a) {",
          "  var v = a;",
          "  v.f = 0;",
          "  v.m();",
          "}",
          "");
      assertErrors(
          result.getErrors(),
          errEx(TypeErrorCode.NOT_A_MEMBER_OF_INFERRED, 9, 5, 1),
          errEx(TypeErrorCode.INTERFACE_HAS_NO_METHOD_NAMED_INFERRED, 10, 5, 1));
    }
  }

  /**
   * There was bug that for-in loop did not mark type of variable as inferred, so we produced
   * warnings even when this is disabled.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4460
   */
  public void test_inferredTypes_noMemberWarnings_forInLoop() throws Exception {
    compilerConfiguration = new DefaultCompilerConfiguration(new CompilerOptions() {
      @Override
      public boolean typeChecksForInferredTypes() {
        return false;
      }
    });
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {}",
        "foo() {",
        "  List<A> values;",
        "  for (var v in values) {",
        "    v.bar();",
        "  }",
        "}",
        "");
    assertErrors(result.getErrors());
  }

  public void test_inferredTypes_whenInvocationArgument_checkAssignable() throws Exception {
    // disabled by default
    {
      AnalyzeLibraryResult result = analyzeLibrary(
          "// filler filler filler filler filler filler filler filler filler filler",
          "class A {}",
          "class B {}",
          "foo(A a) {}",
          "main() {",
          "  var v = new B();",
          "  foo(v);",
          "}",
          "");
      assertErrors(result.getErrors());
    }
    // use CompilerConfiguration to enable
    {
      compilerConfiguration = new DefaultCompilerConfiguration(new CompilerOptions() {
        @Override
        public boolean typeChecksForInferredTypes() {
          return true;
        }
      });
      AnalyzeLibraryResult result = analyzeLibrary(
          "// filler filler filler filler filler filler filler filler filler filler",
          "class A {}",
          "class B {}",
          "foo(A a) {}",
          "main() {",
          "  var v = new B();",
          "  foo(v);",
          "}",
          "");
      assertErrors(
          result.getErrors(),
          errEx(TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE_INFERRED, 7, 7, 1));
    }
  }

  /**
   * When we resolved method from inferred type, it is possible that arguments of invocation
   * don't is not assignable to the parameters. So, we report warning. But if we would not infer
   * types, there would be no warnings.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4849
   */
  public void test_inferredTypes_invocationOfMethodFromInferredType_arguments() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  foo(int p) {}",
        "}",
        "main() {",
        "  var a = new A();",
        "  a.foo('');",
        "}",
        "");
    assertErrors(result.getErrors());
  }

  public void test_typesPropagation_assignAtDeclaration() throws Exception {
    analyzeLibrary(
        "f() {",
        "  var v0 = true;",
        "  var v1 = true && false;",
        "  var v2 = 1;",
        "  var v3 = 1 + 2;",
        "  var v4 = 1.0;",
        "  var v5 = 1.0 + 2.0;",
        "  var v6 = new Map<String, int>();",
        "  var v7 = new Map().length;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v0", "bool", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v1", "bool", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v2", "int", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v3", "int", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v4", "double", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v5", "double", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v6", "Map<String, int>", INFERRED);
    assertInferredElementTypeString(testUnit, "v7", "int", INFERRED_EXACT);
  }

  /**
   * We should infer types only if variable declared without type.
   */
  public void test_typesPropagation_dontChangeDeclaredType() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {}",
        "class B extends A {}",
        "main() {",
        "  B v = new B();",
        "  var v1 = v;",
        "  v = new A();",
        "  var v2 = v;",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
    assertInferredElementTypeString(testUnit, "v1", "B", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v2", "B", INFERRED_EXACT);
  }

  public void test_typesPropagation_multiAssign() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  var v = true;",
        "  var v1 = v;",
        "  v = 0;",
        "  var v2 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "bool", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v2", "int", INFERRED_EXACT);
  }

  public void test_typesPropagation_multiAssign_noInitialValue() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  var v;",
        "  v = 0;",
        "  var v1 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "int", INFERRED_EXACT);
  }

  public void test_typesPropagation_multiAssign_IfThen() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  var v = true;",
        "  var v1 = v;",
        "  if (true) {",
        "    v = 0;",
        "    var v2 = v;",
        "  }",
        "  var v3 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "bool", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v2", "int", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v3", "Object", INFERRED);
  }

  public void test_typesPropagation_multiAssign_IfThenElse() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  var a = true;",
        "  var b = true;",
        "  var c = true;",
        "  var d = true;",
        "  if (true) {",
        "    a = 0;",
        "    b = 0;",
        "  } else {",
        "    a = 0;",
        "    c = 0;",
        "  }",
        "  var a1 = a;",
        "  var b1 = b;",
        "  var c1 = c;",
        "  var d1 = d;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "a1", "int", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "b1", "Object", INFERRED);
    assertInferredElementTypeString(testUnit, "c1", "Object", INFERRED);
    assertInferredElementTypeString(testUnit, "d1", "bool", INFERRED_EXACT);
  }

  public void test_typesPropagation_multiAssign_IfThenElse_whenAsTypeCondition() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(var v) {",
        "  if (v is String) {",
        "    var v1 = v;",
        "    v = null;",
        "  } else {",
        "    var v2 = v;",
        "  }",
        "  var v3 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "String", INFERRED);
    assertInferredElementTypeString(testUnit, "v2", "dynamic", EXACT);
    assertInferredElementTypeString(testUnit, "v3", "dynamic", EXACT);
  }

  public void test_typesPropagation_multiAssign_While() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  var v = true;",
        "  var v1 = v;",
        "  while (true) {",
        "    var v2 = v;",
        "    v = 0;",
        "    var v3 = v;",
        "  }",
        "  var v4 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "bool", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v2", "bool", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v3", "int", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v4", "Object", INFERRED);
  }
  
  public void test_typesPropagation_multiAssign_DoWhile() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  var v = true;",
        "  var v1 = v;",
        "  do {",
        "    var v2 = v;",
        "    v = 0;",
        "    var v3 = v;",
        "  } while (true);",
        "  var v4 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "bool", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v2", "bool", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v3", "int", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v4", "int", INFERRED_EXACT);
  }

  public void test_typesPropagation_multiAssign_For() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  var v = true;",
        "  var v1 = v;",
        "  for (int i = 0; i < 10; i++) {",
        "    var v2 = v;",
        "    v = 0;",
        "    var v3 = v;",
        "  }",
        "  var v4 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "bool", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v2", "bool", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v3", "int", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v4", "Object", INFERRED);
  }

  public void test_typesPropagation_multiAssign_ForIn() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  var v = true;",
        "  var v1 = v;",
        "  List<String> names = [];",
        "  for (var name in names) {",
        "    var v2 = v;",
        "    v = 0;",
        "    var v3 = v;",
        "  }",
        "  var v4 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "bool", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v2", "bool", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v3", "int", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v4", "Object", INFERRED);
  }

  /**
   * We should understand type with type arguments and choose the most generic version.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4792
   */
  public void test_typesPropagation_multiAssign_withGenerics_type_type() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  var a = new List<String>();",
        "  var b = <Object>[];",
        "  if (true) {",
        "    a = <Object>[];",
        "    b = new List<String>();",
        "  }",
        "  var a1 = a;",
        "  var b1 = b;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "a1", "List<Object>", INFERRED);
    assertInferredElementTypeString(testUnit, "b1", "List<Object>", INFERRED);
  }
  
  /**
   * Prefer specific type, not "dynamic" type argument.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4792
   */
  public void test_typesPropagation_multiAssign_withGenerics_type_dynamic() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  var a = new List<String>();",
        "  var b = [];",
        "  if (true) {",
        "    a = [];",
        "    b = new List<String>();",
        "  }",
        "  var a1 = a;",
        "  var b1 = b;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "a1", "List<String>", INFERRED);
    assertInferredElementTypeString(testUnit, "b1", "List<String>", INFERRED);
  }
  
  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4791
   */
  public void test_typesPropagation_multiAssign_type_null() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  var v = null;",
        "  var v1 = v;",
        "  if (true) {",
        "    v = '';",
        "    var v2 = v;",
        "  }",
        "  var v3 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "dynamic", EXACT);
    assertInferredElementTypeString(testUnit, "v2", "String", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v3", "String", INFERRED);
  }

  /**
   * There was bug that when we analyze assignment in initializer, we don't have context.
   */
  public void test_typesPropagation_multiAssign_assignmentOutsideFunction() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  A(p) {}",
        "}",
        "class B extends A {",
        "  B(p) : super(p = 0) {}",
        "}",
        "");
    // no exceptions
  }

  /**
   * When we can not identify type of assigned value we should keep "dynamic" as type of variable.
   */
  public void test_typesPropagation_assign_newUnknownType() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  var v1 = new Unknown();",
        "  var v2 = new Unknown.name();",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "dynamic", EXACT);
    assertInferredElementTypeString(testUnit, "v2", "dynamic", EXACT);
  }

  public void test_typesPropagation_ifAsType() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(var v) {",
        "  if ((v as String).length != 0) {",
        "    var v1 = v;",
        "  }",
        "  var v2 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "String", INFERRED);
    assertInferredElementTypeString(testUnit, "v2", "dynamic", EXACT);
  }

  /**
   * Even if there is negation, we still apply "as" cast, so visit "then" statement only if cast was
   * successful.
   */
  public void test_typesPropagation_ifAsType_negation() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(var v) {",
        "  if (!(v as String).isEmpty()) {",
        "    var v1 = v;",
        "  }",
        "  var v2 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "String", INFERRED);
    assertInferredElementTypeString(testUnit, "v2", "dynamic", EXACT);
  }

  public void test_typesPropagation_ifIsType() throws Exception {
    analyzeLibrary(
        "f(var v) {",
        "  if (v is List<String>) {",
        "    var v1 = v;",
        "  }",
        "  if (v is Map<int, String>) {",
        "    var v2 = v;",
        "  }",
        "  var v3 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "List<String>", INFERRED);
    assertInferredElementTypeString(testUnit, "v2", "Map<int, String>", INFERRED);
    assertInferredElementTypeString(testUnit, "v3", "dynamic", EXACT);
  }

  /**
   * We should not make variable type less specific, even if there is such (useless) user code.
   */
  public void test_typesPropagation_ifIsType_mostSpecific() throws Exception {
    analyzeLibrary(
        "f() {",
        "  int a;",
        "  num b;",
        "  if (a is num) {",
        "    var a1 = a;",
        "  }",
        "  if (a is dynamic) {",
        "    var a2 = a;",
        "  }",
        "  if (b is int) {",
        "    var b1 = b;",
        "  }",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "a1", "int", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "a2", "int", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "b1", "int", INFERRED);
  }

  /**
   * When single variable has conflicting type constraints, we use union of types.
   */
  public void test_typesPropagation_ifIsType_conflictingTypes() throws Exception {
    compilerConfiguration = new DefaultCompilerConfiguration(new CompilerOptions() {
      @Override
      public boolean typeChecksForInferredTypes() {
        return true;
      }
    });
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(int v) {",
        "  if (v is String) {",
        "    var v1 = v;",
        "    // should be OK because 'v' is String",
        "    v.abs; // from num",
        "    v.length; // from String",
        "    processInt(v);",
        "    processString(v);",
        "  }",
        "}",
        "processInt(int p) {}",
        "processString(String p) {}",
        "");
    // should be no errors, we because "v" is String
    assertErrors(result.getErrors());
    assertInferredElementTypeString(testUnit, "v1", "[int, String]", INFERRED);
  }

  public void test_typesPropagation_ifIsType_negation() throws Exception {
    analyzeLibrary(
        "f(var v) {",
        "  if (v is! String) {",
        "    var v1 = v;",
        "  }",
        "  if (!(v is String)) {",
        "    var v2 = v;",
        "  }",
        "  if (!!(v is String)) {",
        "    var v3 = v;",
        "  }",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "dynamic", EXACT);
    assertInferredElementTypeString(testUnit, "v2", "dynamic", EXACT);
    assertInferredElementTypeString(testUnit, "v3", "String", INFERRED);
  }

  public void test_typesPropagation_ifIsType_and() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(var a, var b) {",
        "  if (a is String && b is List<String>) {",
        "    var a1 = a;",
        "    var b1 = b;",
        "  }",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "a1", "String", INFERRED);
    assertInferredElementTypeString(testUnit, "b1", "List<String>", INFERRED);
  }

  public void test_typesPropagation_ifIsType_or() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(var v) {",
        "  if (true || v is String) {",
        "    var v1 = v;",
        "  }",
        "  if (v is String || true) {",
        "    var v2 = v;",
        "  }",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "dynamic", EXACT);
    assertInferredElementTypeString(testUnit, "v2", "dynamic", EXACT);
  }

  public void test_typesPropagation_whileIsType() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(var v) {",
        "  var v = null;",
        "  while (v is String) {",
        "    var v1 = v;",
        "  }",
        "  var v2 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "String", INFERRED);
    assertInferredElementTypeString(testUnit, "v2", "dynamic", EXACT);
  }

  public void test_typesPropagation_forIsType() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(var v) {",
        "  var v = null;",
        "  for (; v is String; () {var v2 = v;} ()) {",
        "    var v1 = v;",
        "  }",
        "  var v3 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "String", INFERRED);
    assertInferredElementTypeString(testUnit, "v2", "String", INFERRED);
    assertInferredElementTypeString(testUnit, "v3", "dynamic", EXACT);
  }

  public void test_typesPropagation_forEach() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(var v) {",
        "  List<String> values = [];",
        "  for (var v in values) {",
        "    var v1 = v;",
        "  }",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "String", INFERRED);
  }

  public void test_typesPropagation_ifIsNotType_withElse() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(var v) {",
        "  if (v is! String) {",
        "    var v1 = v;",
        "  } else {",
        "    var v2 = v;",
        "  }",
        "  var v3 = v;",
        "}",
        "");
    // we don't know type, but not String
    assertInferredElementTypeString(testUnit, "v1", "dynamic", EXACT);
    // we know that String
    assertInferredElementTypeString(testUnit, "v2", "String", INFERRED);
    // again, we don't know after "if"
    assertInferredElementTypeString(testUnit, "v3", "dynamic", EXACT);
  }

  public void test_typesPropagation_ifIsNotType_hasThenReturn() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(var v) {",
        "  var v1 = v;",
        "  if (v is! String) {",
        "    return;",
        "  }",
        "  var v2 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "dynamic", EXACT);
    assertInferredElementTypeString(testUnit, "v2", "String", INFERRED);
  }

  public void test_typesPropagation_ifIsNotType_hasThenThrow() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(var v) {",
        "  if (v is! String) {",
        "    throw new Exception();",
        "  }",
        "  var v1 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "String", INFERRED);
  }

  public void test_typesPropagation_ifIsNotType_emptyThen() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(var v) {",
        "  if (v is! String) {",
        "  }",
        "  var v1 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "dynamic", EXACT);
  }

  public void test_typesPropagation_ifIsNotType_otherThen() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(var v) {",
        "  if (v is! String) {",
        "    ;",
        "  }",
        "  var v1 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "dynamic", EXACT);
  }

  public void test_typesPropagation_ifIsNotType_hasThenThrow_withCatch() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(var v) {",
        "  try {",
        "    if (v is! String) {",
        "      throw new Exception();",
        "    }",
        "  } catch (var e) {",
        "  }",
        "  var v1 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "dynamic", EXACT);
  }

  public void test_typesPropagation_ifIsNotType_hasThenContinue() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  for (var v in <Object>[1, 'two', 3]) {",
        "    var v1 = v;",
        "    if (v is! String) {",
        "      continue;",
        "    }",
        "    var v2 = v;",
        "  }",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
    assertInferredElementTypeString(testUnit, "v1", "Object", INFERRED);
    assertInferredElementTypeString(testUnit, "v2", "String", INFERRED);
  }

  public void test_typesPropagation_ifIsNotType_hasThenBreak() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  for (var v in <Object>[1, 'two', 3]) {",
        "    var v1 = v;",
        "    if (v is! String) {",
        "      break;",
        "    }",
        "    var v2 = v;",
        "  }",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
    assertInferredElementTypeString(testUnit, "v1", "Object", INFERRED);
    assertInferredElementTypeString(testUnit, "v2", "String", INFERRED);
  }

  public void test_typesPropagation_ifIsNotType_or() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(var p1, var p2) {",
        "  if (p1 is! int || p2 is! String) {",
        "    return;",
        "  }",
        "  var v1 = p1;",
        "  var v2 = p2;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "int", INFERRED);
    assertInferredElementTypeString(testUnit, "v2", "String", INFERRED);
  }

  public void test_typesPropagation_ifIsNotType_and() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(var v) {",
        "  if (v is! String && true) {",
        "    return;",
        "  }",
        "  var v1 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "dynamic", EXACT);
  }

  public void test_typesPropagation_ifIsNotType_not() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(var v) {",
        "  if (!(v is! String)) {",
        "    return;",
        "  }",
        "  var v1 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "dynamic", EXACT);
  }

  public void test_typesPropagation_ifIsNotType_not2() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(var v) {",
        "  if (!!(v is! String)) {",
        "    return;",
        "  }",
        "  var v1 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "String", INFERRED);
  }

  public void test_typesPropagation_ifNotIsType() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(var v) {",
        "  if (!(v is String)) {",
        "    return;",
        "  }",
        "  var v1 = v;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "String", INFERRED);
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4410
   */
  public void test_typesPropagation_assertIsType() throws Exception {
    analyzeLibrary(
        "f(var v) {",
        "  if (true) {",
        "    var v1 = v;",
        "    assert(v is String);",
        "    var v2 = v;",
        "    {",
        "      var v3 = v;",
        "    }",
        "    var v4 = v;",
        "  }",
        "  var v5 = v;",
        "}",
        "");
    // we don't know type initially
    assertInferredElementTypeString(testUnit, "v1", "dynamic", EXACT);
    // after "assert" all next statements know type
    assertInferredElementTypeString(testUnit, "v2", "String", INFERRED);
    assertInferredElementTypeString(testUnit, "v3", "String", INFERRED);
    // type is set to unknown only when we exit control Block, not just any Block
    assertInferredElementTypeString(testUnit, "v4", "String", INFERRED);
    // we exited "if" Block, so "assert" may be was not executed, so we don't know type
    assertInferredElementTypeString(testUnit, "v5", "dynamic", EXACT);
  }
  
  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4410
   */
  public void test_typesPropagation_assertIsType_twoVariables() throws Exception {
    analyzeLibrary(
        "f(a, b) {",
        "  while (true) {",
        "    var a1 = a;",
        "    var b1 = b;",
        "    assert(a is String);",
        "    assert(b is String);",
        "    var a2 = a;",
        "    var b2 = b;",
        "  }",
        "  var a3 = a;",
        "  var b3 = b;",
        "}",
        "");
    // we don't know type initially
    assertInferredElementTypeString(testUnit, "a1", "dynamic", EXACT);
    assertInferredElementTypeString(testUnit, "b1", "dynamic", EXACT);
    // after "assert" all next statements know type
    assertInferredElementTypeString(testUnit, "a2", "String", INFERRED);
    assertInferredElementTypeString(testUnit, "b2", "String", INFERRED);
    // we exited "if" Block, so "assert" may be was not executed, so we don't know type
    assertInferredElementTypeString(testUnit, "a3", "dynamic", EXACT);
    assertInferredElementTypeString(testUnit, "b3", "dynamic", EXACT);
  }

  /**
   * When variable has explicit type, we should not fall to 'dynamic', we need to keep this type.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=6399
   */
  public void test_typesPropagation_assertIsType_hasExplicitType() throws Exception {
    analyzeLibrary(
        "class A {}",
        "class B extends A {}",
        "class C extends B {}",
        "main() {",
        "  B v;",
        "  if (v is A) {",
        "    var v1 = v;",
        "  }",
        "  if (v is B) {",
        "    var v2 = v;",
        "  }",
        "  if (v is C) {",
        "    var v3 = v;",
        "  }",
        "  if (v is String) {",
        "    var v4 = v;",
        "  }",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "B", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v2", "B", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v3", "C", INFERRED);
    assertInferredElementTypeString(testUnit, "v4", "[B, String]", INFERRED);
  }

  public void test_typesPropagation_field_inClass_final() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  final v1 = 123;",
        "  final v2 = 1 + 2.0;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "int", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v2", "double", INFERRED_EXACT);
  }

  public void test_typesPropagation_field_inClass_const() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  const v1 = 123;",
        "  final v2 = 1 + 2.0;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "int", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v2", "double", INFERRED_EXACT);
  }
  
  /**
   * If field is not final, we don't know if is will be assigned somewhere else, may be even not in
   * there same unit, so we cannot be sure about its type.
   */
  public void test_typesPropagation_field_inClass_notFinal() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  var v1 = 123;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "dynamic", EXACT);
  }

  public void test_typesPropagation_field_topLevel_final() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "final v1 = 123;",
        "final v2 = 1 + 2.0;",
        "");
    assertInferredElementTypeString(testUnit, "v1", "int", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v2", "double", INFERRED_EXACT);
  }

  public void test_typesPropagation_field_topLevel_const() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "const v1 = 123;",
        "const v2 = 1 + 2.0;",
        "");
    assertInferredElementTypeString(testUnit, "v1", "int", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v2", "double", INFERRED_EXACT);
  }
  
  /**
   * If field is not final, we don't know if is will be assigned somewhere else, may be even not in
   * there same unit, so we cannot be sure about its type.
   */
  public void test_typesPropagation_field_topLevel_notFinal() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "var v1 = 123;",
        "");
    assertInferredElementTypeString(testUnit, "v1", "dynamic", EXACT);
  }

  public void test_typesPropagation_FunctionAliasType() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "typedef F();",
        "foo(F f) {",
        "  var v = f;",
        "  v();",
        "}",
        "",
        "");
    assertInferredElementTypeString(testUnit, "v", "F", INFERRED_EXACT);
  }

  /**
   * When we pass "function literal" into invocation on some method, we may know exact
   * <code>Function</code> type expected by this method, so we know types of "function literal"
   * parameters. So, if these types are not specified in "function literal", we can use "expected"
   * types.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3712
   */
  public void test_typesPropagation_parameterOfClosure_invocationNormalParameter() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Event {}",
        "typedef void EventListener(Event event);",
        "foo(EventListener listener) {",
        "}",
        "main() {",
        "  foo((e) {",
        "    var v = e;",
        "  });",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v", "Event", INFERRED);
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3712
   */
  public void test_typesPropagation_parameterOfClosure_invocationNamedPositionalParameter() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Event {}",
        "typedef void EventListener(Event event);",
        "foo([EventListener listener]) {",
        "}",
        "main() {",
        "  foo((e) {",
        "    var v = e;",
        "  });",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v", "Event", INFERRED);
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3712
   */
  public void test_typesPropagation_parameterOfClosure_invocationNamedParameter() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Event {}",
        "typedef void EventListener(Event event);",
        "foo({EventListener listener}) {",
        "}",
        "main() {",
        "  foo(listener: (e) {",
        "    var v = e;",
        "  });",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v", "Event", INFERRED);
  }

  /**
   * http://code.google.com/p/dart/issues/detail?id=3712
   */
  public void test_typesPropagation_parameterOfClosure_invocationOfMethod() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Event {}",
        "typedef void EventListener(Event event);",
        "class Button {",
        "  onClick(EventListener listener) {",
        "  }",
        "}",
        "main() {",
        "  Button button = new Button();",
        "  button.onClick((e) {",
        "    var v = e;",
        "  });",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v", "Event", INFERRED);
  }

  /**
   * We should infer closure parameter types even in {@link FunctionType} is specified directly,
   * without using {@link FunctionAliasType}.
   */
  public void test_typesPropagation_parameterOfClosure_functionType() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Event {}",
        "class Button<T> {",
        "  onClick(listener(T e)) {",
        "  }",
        "}",
        "main() {",
        "  var button = new Button<Event>();",
        "  button.onClick((e) {",
        "    var v = e;",
        "  });",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v", "Event", INFERRED);
  }

  public void test_typesPropagation_parameterOfClosure_assignVariable() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Event {}",
        "typedef void EventListener(Event event);",
        "main() {",
        "  // local variable assign",
        "  {",
        "    EventListener listener;",
        "    listener = (e) {",
        "      var v1 = e;",
        "    };",
        "  }",
        "  // local variable declare",
        "  {",
        "    EventListener listener = (e) {",
        "      var v2 = e;",
        "    };",
        "  }",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "Event", INFERRED);
    assertInferredElementTypeString(testUnit, "v2", "Event", INFERRED);
  }

  public void test_typesPropagation_parameterOfClosure_assignField() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Event {}",
        "typedef void EventListener(Event event);",
        "class Button {",
        "  EventListener listener;",
        "}",
        "EventListener topLevelListener;",
        "main() {",
        "  // top-level field",
        "  {",
        "    topLevelListener = (e) {",
        "      var v1 = e;",
        "    };",
        "  }",
        "  // member field",
        "  {",
        "    Button button = new Button();",
        "    button.listener = (e) {",
        "      var v2 = e;",
        "    };",
        "  }",
        "}",
        "EventListener topLevelListener2 = (e) {",
        "  var v3 = e;",
        "};",
        "");
    assertInferredElementTypeString(testUnit, "v1", "Event", INFERRED);
    assertInferredElementTypeString(testUnit, "v2", "Event", INFERRED);
    assertInferredElementTypeString(testUnit, "v3", "Event", INFERRED);
  }

  /**
   * Helpful (but not perfectly satisfying Specification) type of "conditional" is intersection of
   * then/else types, not just their "least upper bounds". And this corresponds runtime behavior.
   */
  public void test_typesPropagation_conditional() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "abstract class I1 {",
        "  f1();",
        "}",
        "abstract class I2 {",
        "  f2();",
        "}",
        "class A implements I1, I2 {",
        "  f1() => 11;",
        "  f2() => 12;",
        "}",
        "class B implements I1, I2 {",
        "  f1() => 21;",
        "  f2() => 22;",
        "}",
        "main() {",
        "  var v = true ? new A() : new B();",
        "  v.f1();",
        "  v.f2();",
        "}",
        "");
    // no errors, because both f1() and f2() invocations were resolved
    assertErrors(libraryResult.getErrors());
    // v.f1() was resolved
    {
      DartExpression expression = findNodeBySource(testUnit, "v.f1()");
      assertNotNull(expression);
      assertNotNull(expression.getElement());
    }
    // v.f2() was resolved
    {
      DartExpression expression = findNodeBySource(testUnit, "v.f1()");
      assertNotNull(expression);
      assertNotNull(expression.getElement());
    }
  }

  public void test_getType_binaryExpression() throws Exception {
    analyzeLibrary(
        "f(var arg) {",
        "  var v1 = 1 + 2;",
        "  var v2 = 1 - 2;",
        "  var v3 = 1 * 2;",
        "  var v4 = 1 ~/ 2;",
        "  var v5 = 1 % 2;",
        "  var v6 = 1 / 2;",
        "  var v7 = 1.0 + 2;",
        "  var v8 = 1 + 2.0;",
        "  var v9 = 1 - 2.0;",
        "  var v10 = 1.0 - 2;",
        "  var v11 = 1 * 2.0;",
        "  var v12 = 1.0 * 2;",
        "  var v13 = 1.0 / 2;",
        "  var v14 = 1 / 2.0;",
        "  var v15 = 1.0 ~/ 2.0;",
        "  var v16 = 1.0 ~/ 2;",
        "  var v17 = arg as int",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "int", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v2", "int", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v3", "int", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v4", "int", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v5", "int", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v6", "double", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v7", "double", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v8", "double", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v9", "double", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v10", "double", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v11", "double", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v12", "double", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v13", "double", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v14", "double", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v15", "double", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v16", "double", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v17", "int", INFERRED);
  }

  /**
   * It was requested that even if Editor can be helpful and warn about types incompatibility, it
   * should not do this to completely satisfy specification.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3223
   * <p>
   * This feature was requested by users, so we introduce it again, but disabled to command line.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4518
   */
  public void test_typesPropagation_noExtraWarnings() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(int v) {}",
        "f1() {",
        "  var v = true;",
        "  f(v);",
        "}",
        "f2(var v) {",
        "  if (v is bool) {",
        "    f(v);",
        "  }",
        "}",
        "f3(var v) {",
        "  while (v is bool) {",
        "    f(v);",
        "  }",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
  }

  /**
   * There was problem that using <code>() -> bool</code> getter in negation ('!') caused assignment
   * warnings. Actual reason was that with negation getter access is visited twice and on the second
   * time type of getter method, instead of return type, was returned.
   */
  public void test_getType_getterInNegation() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "class A {",
        "  int get intProperty => 42;",
        "  bool get boolProperty => true;",
        "}",
        "f() {",
        "  var a = new A();",
        "  var v1 = a.intProperty;",
        "  var v2 = a.boolProperty;",
        "  if (a.boolProperty) {",
        "  }",
        "  if (!a.boolProperty) {",
        "  }",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
    assertInferredElementTypeString(testUnit, "v1", "int", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v2", "bool", INFERRED_EXACT);
  }

  public void test_getType_getterInNegation_generic() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "class A<T> {",
        "  T field;",
        "  T get prop => null;",
        "}",
        "f() {",
        "  var a = new A<bool>();",
        "  var v1 = a.field;",
        "  var v2 = a.prop;",
        "  if (a.field) {",
        "  }",
        "  if (!a.field) {",
        "  }",
        "  if (a.prop) {",
        "  }",
        "  if (!a.prop) {",
        "  }",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
    assertInferredElementTypeString(testUnit, "v1", "bool", INFERRED_EXACT);
    assertInferredElementTypeString(testUnit, "v2", "bool", INFERRED_EXACT);
  }

  public void test_getType_getterInSwitch_default() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "int get foo {}",
        "f() {",
        "  switch (true) {",
        "    default:",
        "      int v = foo;",
        "  }",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3515
   */
  public void test_getType_getterInSwitchExpression_topLevel() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "int get foo => 42;",
        "f() {",
        "  switch (foo) {",
        "    case 2:",
        "      break;",
        "  }",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3515
   */
  public void test_getType_getterInSwitchExpression_inClass() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A<T> {",
        "  T get foo => null;",
        "}",
        "f() {",
        "  A<int> a = new A<int>();",
        "  switch (a.foo) {",
        "    case 2:",
        "      break;",
        "  }",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3272
   */
  public void test_assignVoidToDynamic() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "void foo() {}",
        "main() {",
        "  var v = foo();",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=5114
   */
  public void test_lowerCaseDynamicType() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  dynamic v = null;",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
  }

  /**
   * It is a static warning if the return type of the user-declared operator == is explicitly
   * declared and not bool.
   */
  public void test_equalsOperator_type() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  bool operator ==(other) {}",
        "}",
        "class B {",
        "  String operator ==(other) {}",
        "}",
        "class C {",
        "  Object operator ==(other) {}",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.CANNOT_OVERRIDE_METHOD_NOT_SUBTYPE, 6, 19, 2),
        errEx(TypeErrorCode.OPERATOR_EQUALS_BOOL_RETURN_TYPE, 6, 3, 6),
        errEx(TypeErrorCode.OPERATOR_EQUALS_BOOL_RETURN_TYPE, 9, 3, 6));
  }

  /**
   * We should be able to resolve "a == b" to the "equals" operator.
   */
  public void test_equalsOperator_resolving() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class C {",
            "  operator ==(other) => false;",
            "}",
            "main() {",
            "  new C() == new C();",
            "}",
            "");
    assertErrors(libraryResult.getErrors());
    // find == expression
    DartExpression expression = findNodeBySource(testUnit, "new C() == new C()");
    assertNotNull(expression);
    // validate == element
    MethodElement equalsElement = (MethodElement) expression.getElement();
    assertNotNull(equalsElement);
  }

  /**
   * We can not override getter. But setter has name "setter=", so there are no conflict.
   */
  public void test_supertypeHasMethod() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class A {}",
            "interface I {",
            "  foo();",
            "  bar();",
            "}",
            "interface J extends I {",
            "  get foo;",
            "  set bar();",
            "}");
      assertErrors(libraryResult.getTypeErrors(),
          errEx(TypeErrorCode.SUPERTYPE_HAS_METHOD, 8, 7, 3));
  }

  /**
   * Ensure that "operator call()" is parsed, and "operator" is not considered as return type. This
   * too weak test, but for now we are interested only in parsing.
   */
  public void test_callOperator_parsing() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  operator call() => 42;",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
  }

  /**
   * The spec in the section 10.28 says:
   * "It is a compile-time error to use a built-in identifier other than dynamic as a type annotation."
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3307
   */
  public void test_builtInIdentifier_asTypeAnnotation() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  abstract   v01;",
        "  as         v02;",
        "  dynamic    v03;",
        "  export     v04;",
        "  external   v05;",
        "  factory    v06;",
        "  get        v07;",
        "  implements v08;",
        "  import     v09;",
        "  library    v10;",
        "  operator   v11;",
        "  part       v12;",
        "  set        v13;",
        "  static     v14;",
        "//  typedef    v15;",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 3, 3, 8),   // abstract
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 4, 3, 2),   // as
                                                                         // dynamic
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 6, 3, 6),   // export
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 7, 3, 8),   // external
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 8, 3, 7),   // factory
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 9, 3, 3),   // get
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 10, 3, 10), // implements
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 11, 3, 6),  // import
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 12, 3, 7),  // library
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 13, 3, 8),  // operator
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 14, 3, 4),  // part
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 15, 3, 3),  // set
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 16, 3, 6)  // static
//        ,errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 17, 3, 7)   // typedef
    );
  }

  public void test_supertypeHasField() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {}",
        "interface I {",
        "  var foo;",
        "  var bar;",
        "}",
        "interface J extends I {",
        "  foo();",
        "  bar();",
        "}");
    assertErrors(libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.SUPERTYPE_HAS_FIELD, 8, 3, 3),
        errEx(TypeErrorCode.SUPERTYPE_HAS_FIELD, 9, 3, 3));
  }

  /**
   * We can not override getter. But setter has name "setter=", so there are no conflict.
   */
  public void test_supertypeHasGetterSetter() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {}",
        "interface I {",
        "  get foo;",
        "  set bar();",
        "}",
        "interface J extends I {",
        "  foo();",
        "  bar();",
        "}");
    assertErrors(libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.SUPERTYPE_HAS_FIELD, 8, 3, 3));
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3280
   */
  public void test_typeVariableExtendsFunctionAliasType() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "typedef void F();",
        "class C<T extends F> {",
        "  test() {",
        "    new C<T>();",
        "  }",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3344
   */
  public void test_typeVariableExtendsTypeVariable() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A<T, U extends T> {",
        "  f1(U u) {",
        "    T t = u;",
        "  }",
        "  f2(T t) {",
        "    U u = t;",
        "  }",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
  }

  public void test_staticMemberAccessThroughInstance() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  static var x;",
        "  static y() {}",
        "  static method() {",
        "    var a = new A();",
        "    a.x = 1;",
        "    var foo = a.x;",
        "    a.y();",
        "    a.y = 1;",
        "  }",
        "}",
        "");
    assertErrors(libraryResult.getErrors(),
        errEx(TypeErrorCode.STATIC_MEMBER_ACCESSED_THROUGH_INSTANCE, 7, 7, 1),
        errEx(TypeErrorCode.STATIC_MEMBER_ACCESSED_THROUGH_INSTANCE, 8, 17, 1),
        errEx(TypeErrorCode.IS_STATIC_METHOD_IN, 9, 7, 1),
        errEx(TypeErrorCode.STATIC_MEMBER_ACCESSED_THROUGH_INSTANCE, 10, 7, 1),
        errEx(TypeErrorCode.CANNOT_ASSIGN_TO, 10, 5, 3));
  }

  public void testExpectedPositionalArgument() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "method1(a, [b]) {}",
        "method2() {",
        "  method1(b:1);",
        "}");
    assertErrors(libraryResult.getErrors(),
        errEx(TypeErrorCode.EXPECTED_POSITIONAL_ARGUMENT, 4, 11, 3));
  }

  public void test_cannotResolveMethod_unqualified() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  f() {",
        "    foo();",
        "  }",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.INTERFACE_HAS_NO_METHOD_NAMED, 4, 5, 3));
  }

  public void test_canNotResolveMethod_qualified() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "}",
        "main() {",
        "  A a = new A();",
        "  a.foo();",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.INTERFACE_HAS_NO_METHOD_NAMED, 6, 5, 3));
  }

  public void test_operatorLocation() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "}",
        "main() {",
        "  A a = new A();",
        "  a + 0;",
        "  -a;",
        "  a--;",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.INTERFACE_HAS_NO_METHOD_NAMED, 6, 5, 1),
        errEx(TypeErrorCode.CANNOT_BE_RESOLVED, 7, 3, 1),
        errEx(TypeErrorCode.CANNOT_BE_RESOLVED, 8, 4, 2));
  }

  /**
   * It is a static warning if T does not denote a type available in the current lexical scope.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=2373
   */
  public void test_asType_unknown() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  null as T;",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.NO_SUCH_TYPE, 3, 11, 1));
  }

  /**
   * It is a compile-time error if T is a parameterized type of the form G < T1; : : : ; Tn > and G
   * is not a generic type with n type parameters.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=2373
   */
  public void test_asType_wrongNumberOfTypeArguments() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {}",
        "main() {",
        "  null as A<int, bool>;",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 4, 11, 12));
  }

  /**
   * It is a static warning if T does not denote a type available in the current lexical scope.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=2373
   */
  public void test_isType_unknown() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  null is T;",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.NO_SUCH_TYPE, 3, 11, 1));
  }

  public void test_incompatibleTypesInHierarchy1() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "abstract class Interface<T> {",
        "  T m();",
        "}",
        "abstract class A implements Interface {",
        "}",
        "class C extends A implements Interface<int> {",
        "  int m() => 0;",
        "}");
    assertErrors(
        libraryResult.getErrors());
  }

  public void test_incompatibleTypesInHierarchy2() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "abstract class Interface<T> {",
        "  T m();",
        "}",
        "abstract class A implements Interface<String> {",
        "}",
        "class C extends A implements Interface<int> {",
        "  int m() => 0;",
        "}");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.CANNOT_OVERRIDE_METHOD_NOT_SUBTYPE, 8, 7, 1),
        errEx(TypeErrorCode.INCOMPATIBLE_TYPES_IN_HIERARCHY, 7, 7, 1));
  }

  public void test_variableUsedAsType() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "var func;",
        "func i;");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.NOT_A_TYPE, 3, 1, 4));
  }

  public void test_metadataComment_deprecated_1() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "// @deprecated",
        "ttt() {}",
        "class A {",
        "  // @deprecated",
        "  var fff;",
        "  // @deprecated",
        "  mmmm() {}",
        "  // @deprecated",
        "  operator + (other) {}",
        "}",
        "method() {",
        "  ttt();",
        "  A a = new A();",
        "  a.fff = 0;",
        "  a.mmmm();",
        "  a + 0;",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.DEPRECATED_ELEMENT, 13, 3, 3),
        errEx(TypeErrorCode.DEPRECATED_ELEMENT, 15, 5, 3),
        errEx(TypeErrorCode.DEPRECATED_ELEMENT, 16, 5, 4),
        errEx(TypeErrorCode.DEPRECATED_ELEMENT, 17, 5, 1));
  }

  public void test_metadataComment_deprecated_2() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "// @deprecated",
        "class A {",
        "  A.named() {}",
        "  // @deprecated",
        "  A.depreca() {}",
        "}",
        "method() {",
        "  new A.named();",
        "  new A.depreca();",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.DEPRECATED_ELEMENT, 9, 7, 1),
        errEx(TypeErrorCode.DEPRECATED_ELEMENT, 10, 7, 1),
        errEx(TypeErrorCode.DEPRECATED_ELEMENT, 10, 9, 7));
  }
  
  public void test_metadata_resolving() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "const test = 0;",
        "",
        "@test",
        "class A {",
        "  @test",
        "  m(@test p) {",
        "    @test var v = 0;",
        "  }",
        "}",
        "",
        "f(@test p) {}",
        "",
        "@test typedef F();",
        "",
        "");
    // @deprecated should be resolved at every place, so no errors
    assertErrors(libraryResult.getErrors());
  }

  public void test_assignMethod() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class C {" +
        "  method() { }",
        "}",
        "main () {",
        "  new C().method = _() {};",
        "}");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.CANNOT_ASSIGN_TO, 5, 3, 14));
  }

  public void test_assignSetter() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class C {" +
        "  set method(arg) { }",
        "}",
        "main () {",
        "  new C().method = _() {};",
        "}");
    assertErrors(
        libraryResult.getErrors());
  }

  public void test_assignGetter() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class C {" +
        "  get method { }",
        "}",
        "main () {",
        "  new C().method = _() {};",
        "}");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.FIELD_HAS_NO_SETTER, 5, 11, 6));
  }

  /**
   * Test for "operator []=".
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4881
   */
  public void test_assignArrayElement() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class C {" +
        "  get method { }",
        "  operator []=(k, v) {}",
        "}",
        "main () {",
        "  new C()[0] = 1;",
        "}");
    assertErrors(
        libraryResult.getErrors());
  }

  /**
   * Test for resolving variants of array access and unary/binary expressions.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=5042
   */
  public void test_opAssignArrayElement() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  B operator [](k) => new B();",
        "    operator []=(k, v) { }",
        "}",
        "class B {",
        "  B operator +(x) => new B();",
        "}",
        "main () {",
        "  var a = new A();",
        "  process( a[2] );",
        "  a[0]++;",
        "  ++a[0];",
        "  a[0] += 1;",
        "  a[0] = 1;",
        "}",
        "process(x) {}",
        "");
    assertErrors(libraryResult.getErrors());
    // print( a[2] )
    {
      DartArrayAccess access = findNode(DartArrayAccess.class, "a[2]");
      // a[2] is invocation of method "[]"
      assertHasMethodElement(access, "A", "[]");
    }
    // a[0]++
    {
      DartUnaryExpression unary = findNode(DartUnaryExpression.class, "a[0]++");
      // a[0]++ is invocation of method "+"
      assertHasMethodElement(unary, "B", "+");
      // a[0] is invocation of method []
      assertHasMethodElement(unary.getArg(), "A", "[]");
    }
    // ++a[0]
    {
      DartUnaryExpression unary = findNode(DartUnaryExpression.class, "++a[0]");
      // ++a[0] is invocation of method "+"
      assertHasMethodElement(unary, "B", "+");
      // a[0] is invocation of method []
      assertHasMethodElement(unary.getArg(), "A", "[]");
    }
    // a[0] += 1
    {
      DartBinaryExpression binary = findNode(DartBinaryExpression.class, "a[0] += 1");
      // a[0] += 1 is invocation of method "+"
      assertHasMethodElement(binary, "B", "+");
      // a[0] is invocation of method []
      assertHasMethodElement(binary.getArg1(), "A", "[]");
    }
    // a[0] = 1
    {
      DartBinaryExpression binary = findNode(DartBinaryExpression.class, "a[0] = 1");
      // a[0] = 1 is invocation of method "[]="
      assertHasMethodElement(binary, "A", "[]=");
      // a[0] is invocation of method []=
      assertHasMethodElement(binary.getArg1(), "A", "[]=");
    }
  }

  /**
   * Test for resolving variants of property access and unary/binary expressions.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=5049
   */
  public void test_opAssignPropertyAccess_instance() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  B get b => new B();",
        "    set b(B x) {}",
        "}",
        "class B {",
        "  B operator +(x) => new B();",
        "}",
        "main () {",
        "  A a = new A();",
        "  process( a.b );",
        "  a.b++;",
        "  ++a.b;",
        "  a.b += 1;",
        "  a.b = null;",
        "}",
        "process(x) {}",
        "");
    assertErrors(libraryResult.getErrors());
    // print( a.b )
    {
      DartPropertyAccess access = findNode(DartPropertyAccess.class, "a.b");
      // a.b is field "A.b"
      assertHasFieldElement(access, "A", "b");
    }
    // a.b++
    {
      DartUnaryExpression unary = findNode(DartUnaryExpression.class, "a.b++");
      // a.b++ is invocation of method "+"
      assertHasMethodElement(unary, "B", "+");
      // a.b is field "A.b"
      assertHasFieldElement(unary.getArg(), "A", "b");
    }
    // ++a.b
    {
      DartUnaryExpression unary = findNode(DartUnaryExpression.class, "++a.b");
      // ++a.b is invocation of method "+"
      assertHasMethodElement(unary, "B", "+");
      // a.b is field "A.b"
      assertHasFieldElement(unary.getArg(), "A", "b");
    }
    // a.b += 1
    {
      DartBinaryExpression binary = findNode(DartBinaryExpression.class, "a.b += 1");
      // a.b += 1 is invocation of method "+"
      assertHasMethodElement(binary, "B", "+");
      // a.b is field "A.b"
      assertHasFieldElement(binary.getArg1(), "A", "b");
    }
    // a.b = null
    {
      DartBinaryExpression binary = findNode(DartBinaryExpression.class, "a.b = null");
      // a.b = null has no Element
      assertSame(null, binary.getElement());
      // a.b is field "A.b"
      assertHasFieldElement(binary.getArg1(), "A", "b");
    }
  }

  /**
   * Test for resolving variants of static property access and unary/binary expressions.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=5049
   */
  public void test_opAssignPropertyAccess_static() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  static B get b => new B();",
        "  static   set b(B x) {}",
        "}",
        "class B {",
        "  B operator +(x) => new B();",
        "}",
        "main () {",
        "  process( A.b );",
        "  A.b++;",
        "  ++A.b;",
        "  A.b += 1;",
        "  A.b = null;",
        "}",
        "process(x) {}",
        "");
    assertErrors(libraryResult.getErrors());
    // print( A.b )
    {
      DartPropertyAccess access = findNode(DartPropertyAccess.class, "A.b");
      // A.b is field "A.b"
      assertHasFieldElement(access, "A", "b");
    }
    // A.b++
    {
      DartUnaryExpression unary = findNode(DartUnaryExpression.class, "A.b++");
      // A.b++ is invocation of method "+"
      assertHasMethodElement(unary, "B", "+");
      // A.b is field "A.b"
      assertHasFieldElement(unary.getArg(), "A", "b");
    }
    // ++A.b
    {
      DartUnaryExpression unary = findNode(DartUnaryExpression.class, "++A.b");
      // ++A.b is invocation of method "+"
      assertHasMethodElement(unary, "B", "+");
      // A.b is field "A.b"
      assertHasFieldElement(unary.getArg(), "A", "b");
    }
    // A.b += 1
    {
      DartBinaryExpression binary = findNode(DartBinaryExpression.class, "A.b += 1");
      // A.b += 1 is invocation of method "+"
      assertHasMethodElement(binary, "B", "+");
      // A.b is field "A.b"
      assertHasFieldElement(binary.getArg1(), "A", "b");
    }
    // A.b = null
    {
      DartBinaryExpression binary = findNode(DartBinaryExpression.class, "A.b = null");
      // A.b = null has no Element
      assertSame(null, binary.getElement());
      // A.b is field "A.b"
      assertHasFieldElement(binary.getArg1(), "A", "b");
    }
  }
  
  /**
   * Test for resolving variants of top-level property access and unary/binary expressions.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=5049
   */
  public void test_opAssignPropertyAccess_topLevel() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "B get field => new B();",
        "  set field(B x) {}",
        "class B {",
        "  B operator +(x) => new B();",
        "}",
        "main () {",
        "  process( field );",
        "  field++;",
        "  ++field;",
        "  field += 1;",
        "  field = null;",
        "}",
        "process(x) {}",
        "");
    assertErrors(libraryResult.getErrors());
    // print( field )
    {
      DartIdentifier access = findNode(DartIdentifier.class, "field );");
      // "field" is top-level field
      assertHasFieldElement(access, "<library>", "field");
    }
    // field++
    {
      DartUnaryExpression unary = findNode(DartUnaryExpression.class, "field++");
      // field++ is invocation of method "+"
      assertHasMethodElement(unary, "B", "+");
      // "field" is top-level field
      assertHasFieldElement(unary.getArg(), "<library>", "field");
    }
    // ++field
    {
      DartUnaryExpression unary = findNode(DartUnaryExpression.class, "++field");
      // ++field is invocation of method "+"
      assertHasMethodElement(unary, "B", "+");
      // "field" is top-level field
      assertHasFieldElement(unary.getArg(), "<library>", "field");
    }
    // field += 1
    {
      DartBinaryExpression binary = findNode(DartBinaryExpression.class, "field += 1");
      // field += 1 is invocation of method "+"
      assertHasMethodElement(binary, "B", "+");
      // "field" is top-level field
      assertHasFieldElement(binary.getArg1(), "<library>", "field");
    }
    // field = null
    {
      DartBinaryExpression binary = findNode(DartBinaryExpression.class, "field = null");
      // field = null is no Element
      assertSame(null, binary.getElement());
      // "field" is top-level field
      assertHasFieldElement(binary.getArg1(), "<library>", "field");
    }
  }

  private static void assertHasFieldElement(DartNode node, String className, String fieldName) {
    Element element = node.getElement();
    assertTrue("" + node + " " + element, element instanceof FieldElement);
    FieldElement fieldElement = (FieldElement) element;
    assertHasFieldElement(fieldElement, className, fieldName);
  }
  
  private static void assertHasFieldElement(FieldElement element, String className, String fieldName) {
    EnclosingElement enclosingElement = element.getEnclosingElement();
    String enclosingName;
    if (enclosingElement instanceof LibraryElement) {
      enclosingName = "<library>";
    } else {
      enclosingName = enclosingElement.getName();
    }
    assertEquals(className, enclosingName);
    //
    String elementName = element.getName();
    assertEquals(fieldName, elementName);
  }
  
  private static void assertHasMethodElement(DartNode node, String className, String methodName) {
    Element element = node.getElement();
    assertTrue("" + node + " " + element, element instanceof MethodElement);
    MethodElement methodElement = (MethodElement) element;
    assertMethodElement(methodElement, className, methodName);
  }
  
  private static void assertMethodElement(MethodElement element, String className, String methodName) {
    EnclosingElement enclosingElement = element.getEnclosingElement();
    String enclosingName;
    if (enclosingElement instanceof LibraryElement) {
      enclosingName = "<library>";
    } else {
      enclosingName = enclosingElement.getName();
    }
    assertEquals(className, enclosingName);
    //
    String elementName = element.getName();
    if (element.getModifiers().isGetter()) {
      elementName = "get " + elementName;
    }
    if (element.getModifiers().isSetter()) {
      elementName = "set " + elementName;
    }
    assertEquals(methodName, elementName);
  }

  public void test_invokeStaticFieldAsMethod() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class C {",
        "  static foo() { }",
        "}",
        "main () {",
        "  var a = new C().foo();",
        "}");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.IS_STATIC_METHOD_IN, 6, 19, 3));
  }

  public void test_invokeNonFunction() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class C {",
        "  String foo;",
        "  method() {",
        "    foo();",
        "  }",
        "}",
        "method() {",
        "  String foo;",
        "  foo();",
        "  (1 + 5)();",
        "}");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.NOT_A_METHOD_IN, 5, 5, 3),
        errEx(TypeErrorCode.NOT_A_FUNCTION_TYPE, 10, 3, 3),
        errEx(TypeErrorCode.NOT_A_FUNCTION_TYPE, 11, 3, 9));
  }
  
  public void test_invokeNonFunction_getter() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  int get foo => 0;",
        "}",
        "main() {",
        "  A a = new A();",
        "  a.foo();",
        "}");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.NOT_A_FUNCTION_TYPE_FIELD, 7, 5, 3));
  }

  public void test_wrongOperandTypeForUnaryExpression() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class C {",
        "  operator -(String arg) {}",
        "  operator +(String arg) {}",
        "}",
        "method1(arg) {}",
        "method2() {",
        "  C foo = new C();",
        "  method1(++foo);",
        "  method1(--foo);",
        "}");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.OPERATOR_WRONG_OPERAND_TYPE, 9, 11, 5),
        errEx(TypeErrorCode.OPERATOR_WRONG_OPERAND_TYPE, 10, 11, 5));
  }

  /**
   * Missing value in {@link DartMapLiteralEntry} is parsing error, but should not cause exception.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3931
   */
  public void test_mapLiteralEntry_noValue() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  var v = {'key' : /*no value*/};",
        "}",
        "");
    // has some errors
    assertTrue(libraryResult.getErrors().size() != 0);
  }

  public void test_fieldOverrideWrongType() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  int foo;",
        "}",
        "class B extends A {",
        "  String foo;",
        "}");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.CANNOT_OVERRIDE_TYPED_MEMBER, 6, 10, 3));
  }

  public void test_overrideInstanceMember() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "class A {",
        "  var field;",
        "  method() {}",
        "}",
        "class B extends A {",
        "  static var field;",
        "  static method() {}",
        "}");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.CANNOT_OVERRIDE_INSTANCE_MEMBER, 6, 14, 5),
        errEx(ResolverErrorCode.CANNOT_OVERRIDE_INSTANCE_MEMBER, 7, 10, 6));
  }

  public void test_overrideStaticMember() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  static var foo;",
        "  static bar() {}",
        "}",
        "class B extends A {",
        "  var foo;",
        "  bar() {}",
        "}");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.OVERRIDING_STATIC_MEMBER, 7, 7, 3),
        errEx(TypeErrorCode.OVERRIDING_STATIC_MEMBER, 8, 3, 3));
  }

  public void test_rethrowNotInCatch() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "class Object {}",
        "method() {",
        "  throw;",
        "}");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.RETHROW_NOT_IN_CATCH, 3, 3, 5));
  }

  public void test_externalKeyword_OK() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "external topFunction();",
        "external get topGetter;",
        "external set topSetter(var v);",
        "class A {",
        "  external const A.con();",
        "  external A();",
        "  external factory A.named();",
        "  external classMethod();",
        "  external static classMethodStatic();",
        "  external get classGetter;",
        "  external set classSetter(var v);",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
    // all method-like nodes here are "external"
    final AtomicInteger methodCounter = new AtomicInteger();
    testUnit.accept(new ASTVisitor<Void>() {
      @Override
      public Void visitMethodDefinition(DartMethodDefinition node) {
        methodCounter.incrementAndGet();
        assertTrue(node.getModifiers().isExternal());
        return null;
      }
    });
    assertEquals(10, methodCounter.get());
  }

  /**
   * Modifier "external" can be applied only to method-like elements.
   */
  public void test_externalKeyword_bad_field() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "external var topVar1;",
        "external int topVar2;",
        "class A {",
        "  external var field1;",
        "  external int field2;",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ParserErrorCode.EXTERNAL_ONLY_METHOD, 2, 14, 7),
        errEx(ParserErrorCode.EXTERNAL_ONLY_METHOD, 3, 14, 7),
        errEx(ParserErrorCode.EXTERNAL_ONLY_METHOD, 5, 16, 6),
        errEx(ParserErrorCode.EXTERNAL_ONLY_METHOD, 6, 16, 6));
  }

  /**
   * Methods with "external" cannot have body.
   */
  public void test_externalKeyword_bad_body() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "external topFunction() {}",
        "abstract class A {",
        "  external A() {}",
        "  external factory A.named() {}",
        "  external classMethod() {}",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ParserErrorCode.EXTERNAL_METHOD_BODY, 2, 24, 2),
        errEx(ParserErrorCode.EXTERNAL_METHOD_BODY, 4, 16, 2),
        errEx(ParserErrorCode.EXTERNAL_METHOD_BODY, 5, 30, 2),
        errEx(ParserErrorCode.EXTERNAL_METHOD_BODY, 6, 26, 2));
  }

  public void test_cascade_type() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  String s = '';",
        "  var v = s..length;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v", "String", INFERRED_EXACT);
  }

  /**
   * There should be no problem reported, because assignment of "a" cascade to "b" with type "B"
   * implicitly set type of "a" to "B".
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=6107
   */
  public void test_cascade_inferType_varDeclaration() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {}",
        "class B extends A {",
        "  bMethod() {}",
        "}",
        "main() {",
        "  A a = new B();",
        "  B b = a..bMethod();",
        "}",
        "");
    assertErrors(result.getErrors());
  }
  
  /**
   * There should be no problem reported, because assignment of "a" cascade to "b" with type "B"
   * implicitly set type of "a" to "B".
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=6107
   */
  public void test_cascade_inferType_varAssignment() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {}",
        "class B extends A {",
        "  bMethod() {}",
        "}",
        "main() {",
        "  A a = new B();",
        "  B b = null;",
        "  b = a..bMethod();",
        "}",
        "");
    assertErrors(result.getErrors());
  }

  /**
   * We assign "a" to field "Holder.b" of type "B", so implicitly set type of "a" to "B".
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=6107
   */
  public void test_cascade_inferType_fieldDeclaration() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Holder {",
        "  B b = getA()..bMethod();",
        "}",
        "class A {}",
        "class B extends A {",
        "  bMethod() {}",
        "}",
        "A getA() => new B();",
        "");
    assertErrors(result.getErrors());
  }
  
  /**
   * We assign "a" to field "Holder.b" of type "B", so implicitly set type of "a" to "B".
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=6107
   */
  public void test_cascade_inferType_fieldAssignment() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Holder {",
        "  B b;",
        "}",
        "class A {}",
        "class B extends A {",
        "  bMethod() {}",
        "}",
        "main() {",
        "  A a = new B();",
        "  Holder holder = new Holder();",
        "  holder.b = a..bMethod();",
        "}",
        "");
    assertErrors(result.getErrors());
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4315
   */
  public void test_cascade_propertyAccess() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  int f;",
        "}",
        "main() {",
        "  A a = new A();",
        "  a",
        "    ..f = 1",
        "    ..f = 2;",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
    {
      DartPropertyAccess access = findNode(DartPropertyAccess.class, "..f = 1");
      assertNotNull(access.getElement());
    }
    {
      DartPropertyAccess access = findNode(DartPropertyAccess.class, "..f = 2");
      assertNotNull(access.getElement());
    }
  }
  
  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4315
   */
  public void test_cascade_methodInvocation() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  int m(p) {}",
        "}",
        "main() {",
        "  A a = new A();",
        "  a",
        "    ..m(1)",
        "    ..m(2);",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
    {
      DartMethodInvocation invocation = findNode(DartMethodInvocation.class, "..m(1)");
      assertNotNull(invocation.getElement());
    }
    {
      DartMethodInvocation invocation = findNode(DartMethodInvocation.class, "..m(2)");
      assertNotNull(invocation.getElement());
    }
  }

  /**
   * Source is invalid, but should not cause {@link NullPointerException}.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4354
   */
  public void test_switchCase_withoutExpression() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  switch (0) {",
        "    case }",
        "  }",
        "}",
        "");
    // has some errors, no exception
    assertTrue(libraryResult.getErrors().size() != 0);
  }

  /**
   * If "unknown" is separate identifier, it is handled as "this.unknown", but "this" is not
   * accessible in static context.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3084
   */
  public void test_unresolvedIdentifier_inStatic_notPropertyAccess() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "process(x) {}",
        "main() {",
        "  unknown = 0;",
        "  process(unknown);",
        "}");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.CANNOT_BE_RESOLVED, 4, 3, 7),
        errEx(ResolverErrorCode.CANNOT_BE_RESOLVED, 5, 11, 7));
  }
  
  /**
   * If "unknown" is separate identifier, it is handled as "this.unknown", but "this" is not
   * accessible in static context.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3084
   */
  public void test_unresolvedIdentifier_inInstance_notPropertyAccess() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "process(x) {}",
        "class A {",
        "  foo() {",
        "    unknown = 0;",
        "    process(unknown);",
        "  }",
        "}");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.CANNOT_BE_RESOLVED, 5, 5, 7),
        errEx(TypeErrorCode.CANNOT_BE_RESOLVED, 6, 13, 7));
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3084
   */
  public void test_unresolvedIdentifier_inStatic_inPropertyAccess() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "process(x) {}",
        "main() {",
        "  Unknown.foo = 0;",
        "  process(Unknown.foo);",
        "}");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.CANNOT_BE_RESOLVED, 4, 3, 7),
        errEx(TypeErrorCode.CANNOT_BE_RESOLVED, 5, 11, 7));
  }
  
  /**
   * Unresolved constructor is warning.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3800
   */
  public void test_unresolvedConstructor() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {}",
        "main() {",
        "  new A(); // OK",
        "  new A.noSuchConstructor(); // warning",
        "  new B(); // warning",
        "  new B.noSuchConstructor(); // warning",
        "}");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.NEW_EXPRESSION_NOT_CONSTRUCTOR, 5, 9, 17),
        errEx(TypeErrorCode.NO_SUCH_TYPE, 6, 7, 1),
        errEx(TypeErrorCode.NO_SUCH_TYPE, 7, 7, 1),
        errEx(ResolverErrorCode.NEW_EXPRESSION_NOT_CONSTRUCTOR, 7, 9, 17));
  }
  
  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4383
   */
  public void test_callFieldWithoutGetter_topLevel() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "set setOnlyField(v) {}",
        "main() {",
        "  setOnlyField(0);",
        "}");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.USE_ASSIGNMENT_ON_SETTER, 4, 3, 12));
  }
  
  /**
   * Every {@link DartExpression} should have {@link Type} set. Just to don't guess this type at
   * many other points in the Editor.
   */
  public void test_typeForEveryExpression_variable() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {}",
        "process(x) {}",
        "main() {",
        "  A aaa = new A();",
        "  process(aaa);",
        "}");
    testUnit.accept(new ASTVisitor<Void>() {
      public Void visitIdentifier(DartIdentifier node) {
        // ignore declaration
        if (node.getParent() instanceof DartDeclaration) {
          return null;
        }
        // check "aaa"
        if (node.toString().equals("aaa")) {
          Type type = node.getType();
          assertNotNull(type);
          assertEquals("A", type.toString());
        }
        return null;
      }
    });
  }
  
  /**
   * Every {@link DartExpression} should have {@link Type} set. Just to don't guess this type at
   * many other points in the Editor.
   */
  public void test_typeForEveryExpression_typeNode() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class AAA {",
        "  static foo() {}",
        "}",
        "main() {",
        "  AAA.foo();",
        "}");
    testUnit.accept(new ASTVisitor<Void>() {
      public Void visitIdentifier(DartIdentifier node) {
        // ignore declaration
        if (node.getParent() instanceof DartDeclaration) {
          return null;
        }
        // check "AAA"
        if (node.toString().equals("AAA")) {
          Type type = node.getType();
          assertNotNull(type);
          assertEquals("AAA", type.toString());
        }
        return null;
      }
    });
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4383
   */
  public void test_callFieldWithoutGetter_member() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  set setOnlyField(v) {}",
        "  foo() {",
        "    setOnlyField(0);",
        "  }",
        "}",
        "main() {",
        "  A a = new A();",
        "  a.setOnlyField(0);",
        "}");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.USE_ASSIGNMENT_ON_SETTER, 5, 5, 12),
        errEx(TypeErrorCode.USE_ASSIGNMENT_ON_SETTER, 10, 5, 12));
  }
  
  private abstract static class ArgumentsBindingTester {
    static List<DartExpression> arguments;
    void doTest(DartUnit unit) {
      unit.accept(new ASTVisitor<Void>() {
        int invocationIndex = 0;
        @Override
        public Void visitUnqualifiedInvocation(DartUnqualifiedInvocation node) {
          arguments = node.getArguments();
          checkArgs(invocationIndex++);
          return super.visitUnqualifiedInvocation(node);
        }
      });
    }
    abstract void checkArgs(int invocationIndex);
    void assertId(int index, String expectedParameterName) {
      DartExpression argument = arguments.get(index);
      String idString = argument.getInvocationParameterId().toString();
      assertEquals("PARAMETER " + expectedParameterName, idString);
    }
  }

  public void test_formalParameters_positional_optional() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "method(var a, var b, [var c = 3, var d = 4]) {}",
        "main() {",
        "  method(10, 20);",
        "  method(10, 20, 30);",
        "  method(10, 20, 30, 40);",
        "}");
    assertErrors(libraryResult.getErrors());
    new ArgumentsBindingTester() {
      @Override
      void checkArgs(int invocationIndex) {
        switch (invocationIndex) {
          case 0: {
            assertId(0, "a");
            assertId(1, "b");
            break;
          }
          case 1: {
            assertId(0, "a");
            assertId(1, "b");
            assertId(2, "c");
            break;
          }
          case 3: {
            assertId(0, "a");
            assertId(1, "b");
            assertId(2, "c");
            assertId(3, "d");
            break;
          }
        }
      }
    }.doTest(testUnit);
  }
  
  public void test_formalParameters_positional_named() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "method(var a, var b, {var c : 3, var d : 4}) {}",
        "main() {",
        "  method(10, 20);",
        "  method(10, 20, c: 30);",
        "  method(10, 20, d: 40);",
        "  method(10, 20, d: 40, c: 30);",
        "}");
    assertErrors(libraryResult.getErrors());
    new ArgumentsBindingTester() {
      @Override
      void checkArgs(int invocationIndex) {
        switch (invocationIndex) {
          case 0: {
            assertId(0, "a");
            assertId(1, "b");
            break;
          }
          case 1: {
            assertId(0, "a");
            assertId(1, "b");
            assertId(2, "c");
            break;
          }
          case 2: {
            assertId(0, "a");
            assertId(1, "b");
            assertId(2, "d");
            break;
          }
          case 3: {
            assertId(0, "a");
            assertId(1, "b");
            assertId(2, "d");
            assertId(3, "c");
            break;
          }
        }
      }
    }.doTest(testUnit);
  }

  /**
   * A constructor name always begins with the name of its immediately enclosing class, and may
   * optionally be followed by a dot and an identifier id. It is a compile-time error if id is the
   * name of a member declared in the immediately enclosing class.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3989
   */
  public void test_constructorName_sameAsMemberName() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  A.foo() {}",
        "  foo() {}",
        "}");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.CONSTRUCTOR_WITH_NAME_OF_MEMBER, 3, 3, 5));
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3904
   */
  public void test_reifiedClasses() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {}",
        "process(x) {}",
        "main() {",
        "  process(A);",
        "}");
    assertErrors(libraryResult.getErrors());
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3968
   */
  public void test_redirectingFactoryConstructor() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  A() {}",
        "  A.named() {}",
        "}",
        "",
        "class B {",
        "  factory B.foo() = A;",
        "  factory B.bar() = A.named;",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
    // prepare "class A"
    ClassElement elementA = findNode(DartClass.class, "class A").getElement();
    Type typeA = elementA.getType();
    // = A;
    {
      DartTypeNode typeNode = findNode(DartTypeNode.class, "A;");
      Type type = typeNode.getType();
      assertSame(typeA, type);
    }
    // = A.named;
    {
      DartTypeNode typeNode = findNode(DartTypeNode.class, "A.named;");
      Type type = typeNode.getType();
      assertSame(typeA, type);
      // .named
      DartIdentifier nameNode = findNode(DartIdentifier.class, "named;");
      NodeElement nameElement = nameNode.getElement();
      assertNotNull(nameElement);
      assertSame(elementA.lookupConstructor("named"), nameElement);
    }
  }
  
  public void test_redirectingFactoryConstructor_cycle() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  factory A.nameA() = C.nameC;",
        "}",
        "class B {",
        "  factory B.nameB() = A.nameA;",
        "}",
        "class C {",
        "  factory C.nameC() = B.nameB;",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.REDIRECTION_CONSTRUCTOR_CYCLE, 3, 11, 7),
        errEx(ResolverErrorCode.REDIRECTION_CONSTRUCTOR_CYCLE, 6, 11, 7),
        errEx(ResolverErrorCode.REDIRECTION_CONSTRUCTOR_CYCLE, 9, 11, 7));
  }
  
  public void test_redirectingFactoryConstructor_notConst_fromConst() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  A.named() {}",
        "}",
        "",
        "class B {",
        "  const factory B.bar() = A.named;",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.REDIRECTION_CONSTRUCTOR_TARGET_MUST_BE_CONST, 7, 29, 5));
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4778
   */
  public void test_unqualifiedAccessToGenericTypeField() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Game {}",
        "class GameRenderer<G extends Game> {",
        "  G get game => null;",
        "}",
        "class SpaceShooterGame extends Game {",
        "  int score;",
        "}",
        "class SpaceShooterRenderer extends GameRenderer<SpaceShooterGame> {",
        "  someMethod() {",
        "    var a = game.score;",
        "  }",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4900
   */
  public void test_forInLoop_fieldAsVariable() throws Exception {
      AnalyzeLibraryResult result = analyzeLibrary(
          "// filler filler filler filler filler filler filler filler filler filler",
          "var v;",
          "get l => v;",
          "set l(x) {v = x;}",
          "main() {",
          "  for (l in [1, 2, 3]) {",
          "    process(l);",
          "  }",
          "}",
          "process(x) {}",
          "");
      assertErrors(result.getErrors());
  }

  /**
   * Don't report "no such member" if class implements "noSuchMethod" method.
   */
  public void test_dontReport_ifHas_noSuchMember_method() throws Exception {
    String[] lines = {
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  noSuchMethod(InvocationMirror invocation) {}",
        "}",
        "class B extends A {}",
        "class C {}",
        "main() {",
        "  new A().notExistingMethod();",
        "  new B().notExistingMethod();",
        "  new C().notExistingMethod();",
        "}",
        "process(x) {}",
        ""};
    // report by default
    {
      AnalyzeLibraryResult result = analyzeLibrary(lines);
      assertErrors(
          result.getErrors(),
          errEx(TypeErrorCode.INTERFACE_HAS_NO_METHOD_NAMED, 8, 11, 17),
          errEx(TypeErrorCode.INTERFACE_HAS_NO_METHOD_NAMED, 9, 11, 17),
          errEx(TypeErrorCode.INTERFACE_HAS_NO_METHOD_NAMED, 10, 11, 17));
    }
    // don't report
    {
      compilerConfiguration = new DefaultCompilerConfiguration(new CompilerOptions() {
        @Override
        public boolean reportNoMemberWhenHasInterceptor() {
          return false;
        }
      });
      AnalyzeLibraryResult result = analyzeLibrary(lines);
      assertErrors(
          result.getErrors(),
          errEx(TypeErrorCode.INTERFACE_HAS_NO_METHOD_NAMED, 10, 11, 17));
    }
  }

  /**
   * Don't report "no such member" if class implements "noSuchMethod" method.
   */
  public void test_dontReport_ifHas_noSuchMember_getter() throws Exception {
    String[] lines = {
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  noSuchMethod(InvocationMirror invocation) {}",
        "}",
        "class B extends A {}",
        "class C {}",
        "main() {",
        "  process( new A().notExistingGetter );",
        "  process( new B().notExistingGetter );",
        "  process( new C().notExistingGetter );",
        "}",
        "process(x) {}",
        ""};
    // report by default
    {
      AnalyzeLibraryResult result = analyzeLibrary(lines);
      assertErrors(
          result.getErrors(),
          errEx(TypeErrorCode.NOT_A_MEMBER_OF, 8, 20, 17),
          errEx(TypeErrorCode.NOT_A_MEMBER_OF, 9, 20, 17),
          errEx(TypeErrorCode.NOT_A_MEMBER_OF, 10, 20, 17));
    }
    // don't report
    {
      compilerConfiguration = new DefaultCompilerConfiguration(new CompilerOptions() {
        @Override
        public boolean reportNoMemberWhenHasInterceptor() {
          return false;
        }
      });
      AnalyzeLibraryResult result = analyzeLibrary(lines);
      assertErrors(result.getErrors(), errEx(TypeErrorCode.NOT_A_MEMBER_OF, 10, 20, 17));
    }
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=5084
   */
  public void test_duplicateSuperInterface_errorInClassImplements() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {}",
        "class B implements A, A {}",
        "");
    assertErrors(result.getErrors(), errEx(ResolverErrorCode.DUPLICATE_IMPLEMENTS_TYPE, 3, 23, 1));
  }
  
  /**
   * We should report only "no such type", but not duplicate.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=5084
   */
  public void test_duplicateSuperInterface_whenNoSuchType() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class B implements X, Y {}",
        "");
    assertErrors(
        result.getErrors(),
        errEx(ResolverErrorCode.NO_SUCH_TYPE, 2, 20, 1),
        errEx(ResolverErrorCode.NO_SUCH_TYPE, 2, 23, 1));
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=5082
   */
  public void test_argumentDefinitionTest_type() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "foo(p) {",
        "  ?p;",
        "}",
        "");
    assertErrors(result.getErrors());
    DartUnaryExpression unary = findNode(DartUnaryExpression.class, "?p");
    Type type = unary.getType();
    assertNotNull(type);
    assertEquals("bool", type.toString());
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=5082
   */
  public void test_argumentDefinitionTest_shouldBeFormalParameter() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "foo(p) {",
        "  var v;",
        "  ?p;",
        "  ?v;",
        "}",
        "");
    assertErrors(
        result.getErrors(),
        errEx(ResolverErrorCode.FORMAL_PARAMETER_NAME_EXPECTED, 5, 4, 1));
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=5148
   */
  public void test_errorIfNoBodyForStaticMethod() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  static foo();",
        "}",
        "");
    assertErrors(
        result.getErrors(),
        errEx(ResolverErrorCode.STATIC_METHOD_MUST_HAVE_BODY, 3, 3, 13));
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=5162
   */
  public void test_initializeFinalInstanceVariable_atDeclaration_inInitializer() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  final f = 0;",
        "  A() : f = 1 {}",
        "}",
        "");
    assertErrors(
        result.getErrors(),
        errEx(ResolverErrorCode.DUPLICATE_INITIALIZATION, 4, 9, 5));
  }
  
  public void test_getOverridden_method() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  foo() => 1;",
        "}",
        "class B extends A {",
        "  foo() => 2;",
        "}",
        "");
    DartMethodDefinition node = findNode(DartMethodDefinition.class, "foo() => 2");
    Set<Element> superElements = node.getElement().getOverridden();
    assertClassMembers(superElements, "method A.foo");
  }

  public void test_getOverridden_field_withGetterSetter() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  var foo;",
        "}",
        "class B extends A {",
        "  get foo => 0;",
        "  set foo(x) {}",
        "}",
        "");
    // getter
    {
      DartMethodDefinition node = findNode(DartMethodDefinition.class, "get foo");
      Set<Element> superElements = node.getElement().getOverridden();
      assertClassMembers(superElements, "field A.foo");
    }
    // setter
    {
      DartMethodDefinition node = findNode(DartMethodDefinition.class, "set foo");
      Set<Element> superElements = node.getElement().getOverridden();
      assertClassMembers(superElements, "field A.foo");
    }
  }
  
  public void test_getOverridden_field_withGetter() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  var foo;",
        "}",
        "class B extends A {",
        "  get foo => 0;",
        "  set foo(x) {}",
        "}",
        "");
    // getter
    {
      DartMethodDefinition node = findNode(DartMethodDefinition.class, "get foo");
      Set<Element> superElements = node.getElement().getOverridden();
      assertClassMembers(superElements, "field A.foo");
    }
  }

  public void test_getOverridden_field_withSetter() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  var foo;",
        "}",
        "class B extends A {",
        "  set foo(x) {}",
        "}",
        "");
    // setter
    {
      DartMethodDefinition node = findNode(DartMethodDefinition.class, "set foo");
      Set<Element> superElements = node.getElement().getOverridden();
      assertClassMembers(superElements, "field A.foo");
    }
  }

  public void test_getOverridden_getterSetter_withField() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  get foo => 0;",
        "  set foo(x) {}",
        "}",
        "class B extends A {",
        "  var foo = 42;",
        "}",
        "");
    DartField node = findNode(DartField.class, "foo = 42");
    Set<Element> superElements = node.getElement().getOverridden();
    assertClassMembers(superElements, "field A.foo");
  }
  
  public void test_getOverridden_getter_withField() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  get foo => 0;",
        "}",
        "class B extends A {",
        "  var foo = 42;",
        "}",
        "");
    DartField node = findNode(DartField.class, "foo = 42");
    Set<Element> superElements = node.getElement().getOverridden();
    assertClassMembers(superElements, "field A.foo");
  }
  
  public void test_getOverridden_setter_withField() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  set foo(x) {}",
        "}",
        "class B extends A {",
        "  var foo = 42;",
        "}",
        "");
    DartField node = findNode(DartField.class, "foo = 42");
    Set<Element> superElements = node.getElement().getOverridden();
    assertClassMembers(superElements, "field A.setter foo");
  }
  
  public void test_getOverridden_setter_withSetter() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  set foo(x) {} // A",
        "}",
        "class B extends A {",
        "  set foo(x) {} // B",
        "}",
        "");
    DartField node = findNode(DartField.class, "set foo(x) {} // B");
    Set<Element> superElements = node.getElement().getOverridden();
    assertClassMembers(superElements, "field A.setter foo");
  }

  private static void assertClassMembers(Set<Element> superElements, String... expectedNames) {
    Set<String> superNames = Sets.newHashSet();
    for (Element element : superElements) {
      String name = element.getEnclosingElement().getName() + "." + element.getName();
      if (element instanceof FieldElement) {
        superNames.add("field " + name);
      }
      if (element instanceof MethodElement) {
        superNames.add("method " + name);
      }
    }
    for (String name : expectedNames) {
      assertTrue(name, superNames.remove(name));
    }
    assertTrue(superNames.toString(), superNames.isEmpty());
  }

  public void test_fieldAccess_declared_noGetter() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  static set f(x) {}",
        "}",
        "main() {",
        "  print(A.f);",
        "}",
        "");
    assertErrors(result.getErrors(), errEx(ResolverErrorCode.FIELD_DOES_NOT_HAVE_A_GETTER, 6, 11, 1));
  }
  
  public void test_fieldAccess_notDeclared() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "}",
        "main() {",
        "  print(A.f);",
        "}",
        "");
    assertErrors(result.getErrors(), errEx(TypeErrorCode.CANNOT_BE_RESOLVED, 5, 11, 1));
  }
  
  public void test_fieldAssign_declared_noSetter() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  static get f => 0;",
        "}",
        "main() {",
        "  A.f = 0;",
        "}",
        "");
    assertErrors(result.getErrors(), errEx(ResolverErrorCode.FIELD_DOES_NOT_HAVE_A_SETTER, 6, 5, 1));
  }
  
  public void test_fieldAssign_notDeclared() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "}",
        "main() {",
        "  A.f = 0;",
        "}",
        "");
    assertErrors(result.getErrors(), errEx(TypeErrorCode.CANNOT_BE_RESOLVED, 5, 5, 1));
  }

  public void test_typeVariableScope_staticField() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A<T> {",
        "  static T v;",
        "}",
        "");
    assertErrors(
        result.getErrors(),
        errEx(ResolverErrorCode.TYPE_VARIABLE_IN_STATIC_CONTEXT, 3, 10, 1));
  }

  public void test_typeVariableScope_staticMethod() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A<T> {",
        "  static foo() {",
        "    T v = null;",
        "  }",
        "}",
        "");
    assertErrors(
        result.getErrors(),
        errEx(ResolverErrorCode.TYPE_VARIABLE_IN_STATIC_CONTEXT, 4, 5, 1));
  }

  public void test_typeVariableScope_instanceField() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A<T> {",
        "  final List<T> values = new List<T>();",
        "}",
        "");
    assertErrors(result.getErrors());
  }

  public void test_unresolvedMethod_inFactoryConstructor() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  factory A() {",
        "    foo();",
        "  }",
        "}",
        "");
    assertErrors(
        result.getErrors(),
        errEx(ResolverErrorCode.CANNOT_RESOLVE_METHOD, 4, 5, 3));
  }
  
  /**
   * Developers unfamiliar with Dart frequently write (x/y).toInt() instead of x ~/ y. The editor
   * should recognize that pattern.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=5652
   */
  public void test_useEffectiveIntegerDivision_int() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  int x = 7;",
        "  int y = 2;",
        "  print( (x / y).toInt() );",
        "}",
        "");
    assertErrors(result.getErrors(), errEx(TypeErrorCode.USE_INTEGER_DIVISION, 5, 10, 15));
  }
  
  /**
   * We need to report warning only when arguments are integers.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=5652
   */
  public void test_useEffectiveIntegerDivision_num() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  num x = 7;",
        "  num y = 2;",
        "  print( (x / y).toInt() );",
        "}",
        "");
    assertErrors(result.getErrors());
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=5157
   */
  public void test_trySubTypeMember_forInferredType() throws Exception {
    compilerConfiguration = new DefaultCompilerConfiguration(new CompilerOptions() {
      @Override
      public boolean typeChecksForInferredTypes() {
        return true;
      }
    });
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Event {}",
        "class MouseEvent extends Event {",
        "  int clientX;",
        "  void stop() {}",
        "}",
        "typedef Listener(Event event);",
        "class Button {",
        "  addListener(Listener listener) {}",
        "}",
        "main() {",
        "  Button button = new Button();",
        "  button.addListener((event) {",
        "    event.clientX;",
        "    event.stop();",
        "  });",
        "}",
        "");
    assertErrors(result.getErrors());
  }
  
  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=6491
   */
  public void test_annotationOnGetter() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "const myAnnotation = 0;",
        "class A {",
        "  @myAnnotation bool get isEmpty => true;",
        "}",
        "");
    assertErrors(result.getErrors());
  }

  public void test_resolveIdentifierInComment_ofClass() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "/** This class [A] has method [foo]. */",
        "class A {",
        "  foo() {}",
        "}",
        "");
    assertErrors(result.getErrors());
    // [A]
    {
      DartIdentifier identifier = findNode(DartIdentifier.class, "A]");
      ClassElement element = (ClassElement) identifier.getElement();
      assertEquals("A", element.getName());
    }
    // [foo]
    {
      DartIdentifier identifier = findNode(DartIdentifier.class, "foo]");
      MethodElement element = (MethodElement) identifier.getElement();
      assertEquals("foo", element.getName());
    }
  }
  
  public void test_resolveIdentifierInComment_ofFunction() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {}",
        "/** This function has parameter [aaa] of type [A] ans also [bbb]. */",
        "foo(A aaa, bbb) {}",
        "");
    assertErrors(result.getErrors());
    // [aaa]
    {
      DartIdentifier identifier = findNode(DartIdentifier.class, "aaa]");
      VariableElement element = (VariableElement) identifier.getElement();
      assertSame(ElementKind.PARAMETER, ElementKind.of(element));
      assertEquals("aaa", element.getName());
    }
    // [A]
    {
      DartIdentifier identifier = findNode(DartIdentifier.class, "A]");
      ClassElement element = (ClassElement) identifier.getElement();
      assertEquals("A", element.getName());
    }
    // [bbb]
    {
      DartIdentifier identifier = findNode(DartIdentifier.class, "bbb]");
      VariableElement element = (VariableElement) identifier.getElement();
      assertSame(ElementKind.PARAMETER, ElementKind.of(element));
      assertEquals("bbb", element.getName());
    }
  }
  
  public void test_resolveIdentifierInComment_ofMethod() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  var fff;",
        "  /** Initializes [fff] and then calls [bar]. */",
        "  foo() {}",
        "  bar() {}",
        "}",
        "");
    assertErrors(result.getErrors());
    // [fff]
    {
      DartIdentifier identifier = findNode(DartIdentifier.class, "fff]");
      FieldElement element = (FieldElement) identifier.getElement();
      assertEquals("fff", element.getName());
    }
    // [bbb]
    {
      DartIdentifier identifier = findNode(DartIdentifier.class, "bar]");
      MethodElement element = (MethodElement) identifier.getElement();
      assertEquals("bar", element.getName());
    }
  }
}
