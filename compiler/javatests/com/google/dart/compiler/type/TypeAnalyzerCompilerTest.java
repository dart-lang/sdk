// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.type;

import static com.google.dart.compiler.common.ErrorExpectation.assertErrors;
import static com.google.dart.compiler.common.ErrorExpectation.errEx;

import com.google.common.base.Joiner;
import com.google.common.collect.Iterables;
import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.google.dart.compiler.CommandLineOptions.CompilerOptions;
import com.google.dart.compiler.CompilerTestCase;
import com.google.dart.compiler.DartArtifactProvider;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompiler;
import com.google.dart.compiler.DartCompilerErrorCode;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DefaultCompilerConfiguration;
import com.google.dart.compiler.MockArtifactProvider;
import com.google.dart.compiler.MockLibrarySource;
import com.google.dart.compiler.ast.ASTVisitor;
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
import com.google.dart.compiler.ast.DartNewExpression;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.DartUnqualifiedInvocation;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.parser.ParserErrorCode;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.ElementKind;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.resolver.NodeElement;
import com.google.dart.compiler.resolver.ResolverErrorCode;
import com.google.dart.compiler.resolver.TypeErrorCode;

import java.io.Reader;
import java.io.StringReader;
import java.net.URI;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

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
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4785
   */
  public void test_labelForBlockInSWitchCase() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  switch (0) {",
        "    case 0: qwerty: {",
        "      break qwerty;",
        "    }",
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
        "typedef D<T extends D>();",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 2, 1, 14),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 3, 1, 15),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 4, 1, 17),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 5, 1, 25));
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
        "typedef A4<T extends B4>();",
        "typedef B4(A4 a);",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 2, 1, 16),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 3, 1, 16),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 4, 1, 16),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 5, 1, 17),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 6, 1, 16),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 7, 1, 19),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 8, 1, 27),
        errEx(TypeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 9, 1, 17));
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
            "Test.dart",
            Joiner.on("\n").join(
                "class Object {}",
                "class Test {",
                "  foo() {",
                "    f();",
                "  }",
                "  f() {",
                "  }",
                "}"));
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
            "Test.dart",
            Joiner.on("\n").join(
                "class Object {}",
                "class Test {",
                "  foo() {",
                "    f() {",
                "    }",
                "    f();",
                "  }",
                "}"));
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
        "final A CONST_1 = const A();",
        "final A CONST_2 = const A();",
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
        "  operator equals(other) => false;",
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
  
  public void test_switchExpression_case_finalLocalVariable() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "foo(var v) {",
        "  final int VALUE = 0;",
        "  switch (v) {",
        "    case VALUE: break;",
        "  }",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
  }

  /**
   * Language specification requires that factory should be declared in class. However declaring
   * factory on top level should not cause exceptions in compiler.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=345
   */
  public void test_badTopLevelFactory() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary("Test.dart", "factory foo() {}");
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
   * From specification 0.05, 11/14/2011.
   * <p>
   * It is a static type warning if the type of the nth required formal parameter of kI is not
   * identical to the type of the nth required formal parameter of kF.
   * <p>
   * It is a static type warning if the types of named optional parameters with the same name differ
   * between kI and kF .
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=521
   */
  public void test_resolveInterfaceConstructor_hasByName_negative_notSameParametersType()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "Test.dart",
            Joiner.on("\n").join(
                "interface I default F {",
                "  I.foo(int a, [int b, int c]);",
                "}",
                "class F implements I {",
                "  factory F.foo(num any, [bool b, Object c]) {}",
                "}",
                "class Test {",
                "  foo() {",
                "    new I.foo(0);",
                "  }",
                "}"));
    // No compilation errors.
    assertErrors(libraryResult.getCompilationErrors());
    // Check type warnings.
    {
      List<DartCompilationError> errors = libraryResult.getTypeErrors();
      assertErrors(errors, errEx(TypeErrorCode.DEFAULT_CONSTRUCTOR_TYPES, 2, 3, 29));
      assertEquals(
          "Constructor 'I.foo' in 'I' has parameters types (int,int,int), doesn't match 'F.foo' in 'F' with (num,bool,Object)",
          errors.get(0).getMessage());
    }
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
    // "new I.foo()" - resolved, but we produce error.
    {
      DartNewExpression newExpression = findExpression(unit, "new I.foo(0)");
      DartNode constructorNode = newExpression.getElement().getNode();
      assertEquals(true, constructorNode.toSource().contains("F.foo("));
    }
  }

  /**
   * There was problem that <code>this.fieldName</code> constructor parameter had no type, so we
   * produced incompatible interface/default class warning.
   */
  public void test_resolveInterfaceConstructor_sameParametersType_thisFieldParameter()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "Test.dart",
            Joiner.on("\n").join(
                "interface I default F {",
                "  I(int a);",
                "}",
                "class F implements I {",
                "  int a;",
                "  F(this.a) {}",
                "}"));
    // Check that parameter has resolved type.
    {
      DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
      DartClass classF = (DartClass) unit.getTopLevelNodes().get(1);
      DartMethodDefinition methodF = (DartMethodDefinition) classF.getMembers().get(1);
      DartParameter parameter = methodF.getFunction().getParameters().get(0);
      assertEquals("int", parameter.getElement().getType().toString());
    }
    // No errors or type warnings.
    assertErrors(libraryResult.getCompilationErrors());
    assertErrors(libraryResult.getTypeErrors());
  }

  /**
   * In contrast, if A is intended to be concrete, the checker should warn about all unimplemented
   * methods, but allow clients to instantiate it freely.
   */
  public void test_warnAbstract_onConcreteClassDeclaration_whenHasUnimplementedMethods()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            getName(),
            makeCode(
                "interface Foo {",
                "  int fooA;",
                "  void fooB();",
                "}",
                "interface Bar {",
                "  void barA();",
                "}",
                "class A implements Foo, Bar {",
                "}",
                "class C {",
                "  foo() {",
                "    return new A();",
                "  }",
                "}"));
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.INSTANTIATION_OF_CLASS_WITH_UNIMPLEMENTED_MEMBERS, 12, 16, 1));
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
   * From specification 0.05, 11/14/2011.
   * <p>
   * In contrast, if A is intended to be concrete, the checker should warn about all unimplemented
   * methods, but allow clients to instantiate it freely.
   */
  public void test_warnAbstract_onConcreteClassDeclaration_whenHasInheritedUnimplementedMethod()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            getName(),
            makeCode(
                "class A {",
                "  abstract void foo();",
                "}",
                "class B extends A {",
                "}",
                "class C {",
                "  foo() {",
                "    return new B();",
                "  }",
                "}"));
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.INSTANTIATION_OF_CLASS_WITH_UNIMPLEMENTED_MEMBERS, 8, 16, 1));
    {
      DartCompilationError typeError = libraryResult.getTypeErrors().get(0);
      String message = typeError.getMessage();
      assertTrue(message.contains("# From A:"));
      assertTrue(message.contains("void foo()"));
    }
  }

  /**
   * From specification 0.05, 11/14/2011.
   * <p>
   * If A is intended to be abstract, we want the static checker to warn about any attempt to
   * instantiate A, and we do not want the checker to complain about unimplemented methods in A.
   * <p>
   * Here:
   * <ul>
   * <li>"A" has unimplemented methods, but we don't show warnings, because it is explicitly marked
   * as abstract.</li>
   * <li>When we try to create instance of "A", we show warning that it is abstract.</li>
   * </ul>
   */
  public void test_warnAbstract_onAbstractClass_whenInstantiate_normalConstructor()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            getName(),
            makeCode(
                "interface Foo {",
                "  int fooA;",
                "  void fooB();",
                "}",
                "abstract class A implements Foo {",
                "}",
                "class C {",
                "  foo() {",
                "    return new A();",
                "  }",
                "}"));
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.INSTANTIATION_OF_ABSTRACT_CLASS, 9, 16, 1));
  }

  /**
   * Variant of {@link #test_warnAbstract_onAbstractClass_whenInstantiate_normalConstructor()}.
   * <p>
   * An abstract class is either a class that is explicitly declared with the abstract modifier, or
   * a class that declares at least one abstract method (7.1.1).
   */
  public void test_warnAbstract_onClassWithAbstractMethod_whenInstantiate_normalConstructor()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            getName(),
            makeCode(
                "interface Foo {",
                "  void foo();",
                "}",
                "class A implements Foo {",
                "  abstract void bar();",
                "}",
                "class C {",
                "  foo() {",
                "    return new A();",
                "  }",
                "}"));
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.INSTANTIATION_OF_ABSTRACT_CLASS, 9, 16, 1));
  }

  /**
   * Variant of {@link #test_warnAbstract_onAbstractClass_whenInstantiate_normalConstructor()}.
   * <p>
   * An abstract class is either a class that is explicitly declared with the abstract modifier, or
   * a class that declares at least one abstract method (7.1.1).
   */
  public void test_warnAbstract_onClassWithAbstractGetter_whenInstantiate_normalConstructor()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            getName(),
            makeCode(
                "interface Foo {",
                "  void foo();",
                "}",
                "class A implements Foo {",
                "  abstract get x();",
                "}",
                "class C {",
                "  foo() {",
                "    return new A();",
                "  }",
                "}"));
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.INSTANTIATION_OF_ABSTRACT_CLASS, 9, 16, 1));
  }

  /**
   * Factory constructor can instantiate any class and return it non-abstract class instance, Even
   * thought this is an abstract class, there should be no warnings for the invocation of the
   * factory constructor.
   */
  public void test_abstractClass_whenInstantiate_factoryConstructor()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            getName(),
            makeCode(
                "abstract class A {",  // explicitly abstract
                "  factory A() {",
                "    return null;",
                "  }",
                "}",
                "class C {",
                "  foo() {",
                "    return new A();",  // no error - factory constructor
                "  }",
                "}"));
    assertErrors(
        libraryResult.getTypeErrors());
  }

  /**
   * Factory constructor can instantiate any class and return it non-abstract class instance, Even
   * thought this is an abstract class, there should be no warnings for the invocation of the
   * factory constructor.
   */
  public void test_abstractClass_whenInstantiate_factoryConstructor2()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            getName(),
            makeCode(
                "class A extends B {",  // class doesn't implement all abstract methods
                "  factory A() {",
                "    return null;",
                "  }",
                "}",
                "class B {",
                "  abstract method();",
                "}",
                "class C {",
                "  foo() {",
                "    return new A();",  // no error, factory constructor
                "  }",
                "}"));
    assertErrors(
        libraryResult.getTypeErrors());
  }

  /**
   * Spec 7.3 It is a static warning if a setter declares a return type other than void.
   */
  public void testWarnOnNonVoidSetter() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            getName(),
            makeCode(
                "class A {",
                "  void set foo(bool a) {}",
                "  set bar(bool a) {}",
                "  Dynamic set baz(bool a) {}",
                "  bool set bob(bool a) {}",
                "}"));
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
            getName(),
            makeCode(
                "class WorkElement {",
                "  Function run;",
                "}",
                "foo(WorkElement e) {",
                "  e.run();",
                "}"));
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
        getName(),
        makeCode(
            "class Test {",
            "  Iterable get iter() {}",
            "}",
            "Test get test() {}",
            "f() {",
            "  for (var v in test.iter) {}",
            "}",
            ""));
    assertErrors(libraryResult.getTypeErrors());
  }

  /**
   * Test for errors and warnings related to positional and named arguments for required and
   * optional parameters.
   */
  public void test_invocationArguments() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            getName(),
            makeCode(
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
                "/* 17 */",
                "/* 18 */   f_1_3(-1, 1, n3: 2);",
                "/* 19 */   f_1_3(-1, 1, n1: 1);",
                "}",
                "",
                "f_0_0() {}",
                "f_1_0(r1) {}",
                "f_2_0(r1, r2) {}",
                "f_0_1([n1]) {}",
                "f_0_2([n1, n2]) {}",
                "f_1_3(r1, [n1, n2, n3]) {}",
                ""));
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.EXTRA_ARGUMENT, 3, 18, 2),
        errEx(TypeErrorCode.MISSING_ARGUMENT, 5, 12, 5),
        errEx(TypeErrorCode.EXTRA_ARGUMENT, 7, 22, 2),
        errEx(TypeErrorCode.EXTRA_ARGUMENT, 7, 26, 2),
        errEx(TypeErrorCode.MISSING_ARGUMENT, 9, 12, 5),
        errEx(TypeErrorCode.EXTRA_ARGUMENT, 13, 21, 1),
        errEx(TypeErrorCode.NO_SUCH_NAMED_PARAMETER, 15, 18, 4),
        errEx(TypeErrorCode.DUPLICATE_NAMED_ARGUMENT, 19, 25, 5));
    assertErrors(
        libraryResult.getCompilationErrors(),
        errEx(ResolverErrorCode.DUPLICATE_NAMED_ARGUMENT, 16, 25, 5));
  }

  /**
   * We should return correct {@link Type} for {@link DartNewExpression}.
   */
  public void test_DartNewExpression_getType() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            getName(),
            makeCode(
                "// filler filler filler filler filler filler filler filler filler filler",
                "class A {",
                "  A() {}",
                "  A.foo() {}",
                "}",
                "var a1 = new A();",
                "var a2 = new A.foo();",
                ""));
    assertErrors(libraryResult.getErrors());
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnit(getName());
    // new A()
    {
      DartNewExpression newExpression = (DartNewExpression) getTopLevelFieldInitializer(unit, 1);
      Type newType = newExpression.getType();
      assertEquals("A", newType.getElement().getName());
    }
    // new A.foo()
    {
      DartNewExpression newExpression = (DartNewExpression) getTopLevelFieldInitializer(unit, 2);
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
            getName(),
            makeCode(
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
                "}"));
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
            getName(),
            makeCode(
                "class A {",
                "  var foo;",
                "}",
                "",
                "main() {",
                "  A a = new A();",
                "  a.foo = 1;",
                "  a.foo += 2;",
                "  print(a.foo);",
                "}"));
    assertErrors(libraryResult.getTypeErrors());
  }

  public void test_setterOnlyProperty_getterInSuper() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            getName(),
            makeCode(
                "class A {",
                "  get foo() {}",
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
                "}"));
    assertErrors(libraryResult.getTypeErrors());
  }

  public void test_setterOnlyProperty_getterInInterface() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            getName(),
            makeCode(
                "interface A {",
                "  get foo() {}",
                "}",
                "class B implements A {",
                "  set foo(arg) {}",
                "}",
                "",
                "main() {",
                "  B b = new B();",
                "  b.foo = 1;",
                "  b.foo += 2;",
                "  print(b.foo);",
                "}"));
    assertErrors(libraryResult.getTypeErrors());
  }

  public void test_getterOnlyProperty_noSetter() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            getName(),
            makeCode(
                "class GetOnly {",
                "  get foo() {}",
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
                "}"));
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.FIELD_HAS_NO_SETTER, 11, 11, 3),
        errEx(TypeErrorCode.FIELD_HAS_NO_SETTER, 12, 11, 3),
        errEx(TypeErrorCode.FIELD_HAS_NO_SETTER, 15, 32, 3));
  }

  public void test_getterOnlyProperty_setterInSuper() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            getName(),
            makeCode(
                "class A {",
                "  set foo(arg) {}",
                "}",
                "class B extends A {",
                "  get foo() {}",
                "}",
                "",
                "main() {",
                "  B b = new B();",
                "  b.foo = 1;",
                "  b.foo += 2;",
                "  print(b.foo);",
                "}"));
    assertErrors(libraryResult.getTypeErrors());
  }

  public void test_getterOnlyProperty_setterInInterface() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            getName(),
            makeCode(
                "interface A {",
                "  set foo(arg) {}",
                "}",
                "class B implements A {",
                "  get foo() {}",
                "}",
                "",
                "main() {",
                "  B b = new B();",
                "  b.foo = 1;",
                "  b.foo += 2;",
                "  print(b.foo);",
                "}"));
    assertErrors(libraryResult.getTypeErrors());
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
        "  assert(f() {});", // OK, Dynamic
        "  assert(bool f() {});", // OK, '() -> bool'
        "  assert(Object f() {});", // OK, 'Object' compatible with 'bool'
        "  assert(String f() {});", // not '() -> bool', return type
        "  assert(bool f(x) {});", // not '() -> bool', parameter
        "  assert(true, false);", // not single argument
        "  assert;", // incomplete
        "}",
        "foo() => assert(true);", // 'assert' is statement, not expression
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.ASSERT_BOOL, 5, 10, 9),
        errEx(TypeErrorCode.ASSERT_BOOL, 6, 10, 6),
        errEx(TypeErrorCode.ASSERT_BOOL, 7, 10, 1),
        errEx(TypeErrorCode.ASSERT_BOOL, 11, 10, 13),
        errEx(TypeErrorCode.ASSERT_BOOL, 12, 10, 12),
        errEx(TypeErrorCode.ASSERT_NUMBER_ARGUMENTS, 13, 3, 19),
        errEx(TypeErrorCode.ASSERT_NUMBER_ARGUMENTS, 14, 3, 7),
        errEx(TypeErrorCode.ASSERT_IS_STATEMENT, 16, 10, 12));
  }

  public void test_assert_isUserFunction() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "assert(x) {}",
        "main() {",
        "  assert(true);",
        "  assert(false);",
        "  assert('message');",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
  }

  public void test_assert_asLocalVariable() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  bool assert;",
        "  assert;",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
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
        "  A.useDynamic(Dynamic this.f);",
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
        getName(),
        makeCode(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class A {",
            "  final f;",
            "}",
            "main() {",
            "  A a = new A();",
            "  a.f = 0;", // 6: ERR, is final
            "  a.f += 1;", // 7: ERR, is final
            "  print(a.f);", // 8: OK, can read
            "}"));
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.FIELD_IS_FINAL, 7, 5, 1),
        errEx(TypeErrorCode.FIELD_IS_FINAL, 8, 5, 1));
  }

  public void test_finalField_inInterface() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        getName(),
        makeCode(
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
            "}"));
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.FIELD_IS_FINAL, 10, 5, 1),
        errEx(TypeErrorCode.FIELD_IS_FINAL, 11, 5, 1));
  }

  public void test_notFinalField() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        getName(),
        makeCode(
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
            "}"));
    assertErrors(libraryResult.getTypeErrors());
  }

  public void test_constField() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        getName(),
        makeCode(
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
            ""));
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.CANNOT_ASSIGN_TO_FINAL, 6, 5, 1),
        errEx(ResolverErrorCode.CANNOT_ASSIGN_TO_FINAL, 7, 5, 6),
        errEx(ResolverErrorCode.CANNOT_ASSIGN_TO_FINAL, 11, 3, 1),
        errEx(TypeErrorCode.FIELD_IS_FINAL, 13, 5, 1));
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

  /**
   * Test for variants of {@link DartMethodDefinition} return types.
   */
  public void test_methodReturnTypes() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            getName(),
            makeCode(
                "// filler filler filler filler filler filler filler filler filler filler",
                "int fA() {}",
                "Dynamic fB() {}",
                "void fC() {}",
                "fD() {}",
                ""));
    assertErrors(libraryResult.getTypeErrors());
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnit(getName());
    {
      DartMethodDefinition fA = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
      assertEquals("int", fA.getElement().getReturnType().getElement().getName());
    }
    {
      DartMethodDefinition fB = (DartMethodDefinition) unit.getTopLevelNodes().get(1);
      assertEquals("<dynamic>", fB.getElement().getReturnType().getElement().getName());
    }
    {
      DartMethodDefinition fC = (DartMethodDefinition) unit.getTopLevelNodes().get(2);
      assertEquals("void", fC.getElement().getReturnType().getElement().getName());
    }
    {
      DartMethodDefinition fD = (DartMethodDefinition) unit.getTopLevelNodes().get(3);
      assertEquals("<dynamic>", fD.getElement().getReturnType().getElement().getName());
    }
  }

  public void test_bindToLibraryFunctionFirst() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            getName(),
            makeCode(
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
                ""));
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnit(getName());
    // Find foo() invocation.
    DartUnqualifiedInvocation invocation;
    {
      DartClass classB = (DartClass) unit.getTopLevelNodes().get(2);
      DartMethodDefinition methodBar = (DartMethodDefinition) classB.getMembers().get(0);
      DartExprStmt stmt = (DartExprStmt) methodBar.getFunction().getBody().getStatements().get(0);
      invocation = (DartUnqualifiedInvocation) stmt.getExpression();
    }
    // Check that unqualified foo() invocation is resolved to the top-level (library) function.
    NodeElement element = invocation.getTarget().getElement();
    assertNotNull(element);
    assertSame(unit, element.getNode().getParent());
  }

  /**
   * If there was <code>import</code> with invalid {@link URI}, it should be reported as error, not
   * as an exception.
   */
  public void test_invalidImportUri() throws Exception {
    List<DartCompilationError> errors =
        analyzeLibrarySourceErrors(makeCode(
            "// filler filler filler filler filler filler filler filler filler filler",
            "library test;",
            "import 'badURI';",
            ""));
    assertErrors(errors, errEx(DartCompilerErrorCode.MISSING_SOURCE, 3, 1, 16));
  }

  /**
   * If there was <code>part</code> with invalid {@link URI}, it should be reported as error, not
   * as an exception.
   */
  public void test_invalidSourceUri() throws Exception {
    List<DartCompilationError> errors =
        analyzeLibrarySourceErrors(makeCode(
            "// filler filler filler filler filler filler filler filler filler filler",
            "library test;",
            "part 'badURI';",
            ""));
    assertErrors(errors, errEx(DartCompilerErrorCode.MISSING_SOURCE, 3, 1, 14));
  }

  /**
   * Analyzes source for given library and returns {@link DartCompilationError}s.
   */
  private static List<DartCompilationError> analyzeLibrarySourceErrors(final String code)
      throws Exception {
    MockLibrarySource lib = new MockLibrarySource() {
      @Override
      public Reader getSourceReader() {
        return new StringReader(code);
      }
    };
    DartArtifactProvider provider = new MockArtifactProvider();
    final List<DartCompilationError> errors = Lists.newArrayList();
    DartCompiler.analyzeLibrary(
        lib,
        Maps.<URI, DartUnit>newHashMap(),
        CHECK_ONLY_CONFIGURATION,
        provider,
        new DartCompilerListener.Empty() {
          @Override
          public void onError(DartCompilationError event) {
            errors.add(event);
          }
        });
    return errors;
  }

  public void test_mapLiteralKeysUnique() throws Exception {
    List<DartCompilationError> errors =
        analyzeLibrarySourceErrors(makeCode(
            "// filler filler filler filler filler filler filler filler filler filler",
            "var m = {'a' : 0, 'b': 1, 'a': 2};",
            ""));
    assertErrors(errors, errEx(TypeErrorCode.MAP_LITERAL_KEY_UNIQUE, 2, 27, 3));
  }

  /**
   * No required parameter "x".
   */
  public void test_implementsAndOverrides_noRequiredParameter() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "interface I {",
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
            "interface I {",
            "  foo([x]);",
            "}",
            "class C implements I {",
            "  foo([x,y]) {}",
            "}");
    assertErrors(result.getErrors());
  }

  /**
   * We override "foo" with method that has named parameter. So, this method is not abstract and
   * class is not abstract too, so no warning.
   */
  public void test_implementsAndOverrides_additionalNamedParameter_notAbstract() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "class A {",
            "  abstract foo();",
            "}",
            "class B extends A {",
            "  foo([x]) {}",
            "}",
            "bar() {",
            "  new B();",
            "}",
            "");
    assertErrors(result.getErrors());
  }

  /**
   * No required parameter "x". Named parameter "x" is not enough.
   */
  public void test_implementsAndOverrides_extraRequiredParameter() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "interface I {",
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
  public void test_implementsAndOverrides_differentDefaultValue() throws Exception {
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
   * It is a compile-time error if an instance method m1 overrides an instance member m2 and m1 does
   * not declare all the named parameters declared by m2 in the same order.
   * <p>
   * Here: no "y" parameter.
   */
  public void test_implementsAndOverrides_noNamedParameter() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "interface I {",
            "  foo([x,y]);",
            "}",
            "class C implements I {",
            "  foo([x]) {}",
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

  /**
   * It is a compile-time error if an instance method m1 overrides an instance member m2 and m1 does
   * not declare all the named parameters declared by m2 in the same order.
   * <p>
   * Here: wrong order.
   */
  public void testImplementsAndOverrides5() throws Exception {
    AnalyzeLibraryResult result =
        analyzeLibrary(
            "interface I {",
            "  foo([y,x]);",
            "}",
            "class C implements I {",
            "  foo([x,y]) {}",
            "}");
    assertErrors(
        result.getErrors(),
        errEx(ResolverErrorCode.CANNOT_OVERRIDE_METHOD_NAMED_PARAMS, 5, 3, 3));
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
            "  static get field() => 0;",
            "         set field(var v) {}",
            "}",
            "class B {",
            "         get field() => 0;",
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
            "  A get field() { return getterField; }",
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
            "A get topField() { return topGetterField; }",
            "void set topField(arg) { topSetterField = arg; }",
            "class C {",
            "  A getterField; ",
            "  var setterField; ",
            "  A get field() { return getterField; }",
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
            "get topField() { return topGetterField; }",
            "void set topField(A arg) { topSetterField = arg; }",
            "class C {",
            "  var getterField; ",
            "  A setterField; ",
            "  get field() { return getterField; }",
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
            "A get topField() { return topGetterField; }",
            "void set topField(B arg) { topSetterField = arg; }",
            "class C {",
            "  A getterField; ",
            "  B setterField; ",
            "  A get field() { return getterField; }",
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
            "interface I<T extends num> { }",
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
            "  T1 get val() {}",
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
          errEx(TypeErrorCode.NOT_A_MEMBER_OF, 9, 5, 1),
          errEx(TypeErrorCode.INTERFACE_HAS_NO_METHOD_NAMED, 10, 5, 1));
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
          errEx(TypeErrorCode.TYPE_NOT_ASSIGNMENT_COMPATIBLE, 7, 7, 1));
    }
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
    // prepare expected results
    List<String> expectedList = Lists.newArrayList();
    expectedList.add("bool");
    expectedList.add("bool");
    expectedList.add("int");
    expectedList.add("int");
    expectedList.add("double");
    expectedList.add("double");
    expectedList.add("Map<String, int>");
    expectedList.add("int");
    // check each "v" type
    for (int i = 0; i < expectedList.size(); i++) {
      String expectedTypeString = expectedList.get(i);
      assertInferredElementTypeString(testUnit, "v" + i, expectedTypeString);
    }
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
    assertInferredElementTypeString(testUnit, "v1", "bool");
    assertInferredElementTypeString(testUnit, "v2", "int");
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
    assertInferredElementTypeString(testUnit, "v1", "int");
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
    assertInferredElementTypeString(testUnit, "v1", "bool");
    assertInferredElementTypeString(testUnit, "v2", "int");
    assertInferredElementTypeString(testUnit, "v3", "Object");
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
    assertInferredElementTypeString(testUnit, "a1", "int");
    assertInferredElementTypeString(testUnit, "b1", "Object");
    assertInferredElementTypeString(testUnit, "c1", "Object");
    assertInferredElementTypeString(testUnit, "d1", "bool");
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
    assertInferredElementTypeString(testUnit, "v1", "String");
    assertInferredElementTypeString(testUnit, "v2", "Dynamic");
    assertInferredElementTypeString(testUnit, "v3", "Dynamic");
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
    assertInferredElementTypeString(testUnit, "v1", "bool");
    assertInferredElementTypeString(testUnit, "v2", "bool");
    assertInferredElementTypeString(testUnit, "v3", "int");
    assertInferredElementTypeString(testUnit, "v4", "Object");
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
    assertInferredElementTypeString(testUnit, "v1", "bool");
    assertInferredElementTypeString(testUnit, "v2", "bool");
    assertInferredElementTypeString(testUnit, "v3", "int");
    assertInferredElementTypeString(testUnit, "v4", "int");
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
    assertInferredElementTypeString(testUnit, "v1", "bool");
    assertInferredElementTypeString(testUnit, "v2", "bool");
    assertInferredElementTypeString(testUnit, "v3", "int");
    assertInferredElementTypeString(testUnit, "v4", "Object");
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
    assertInferredElementTypeString(testUnit, "v1", "bool");
    assertInferredElementTypeString(testUnit, "v2", "bool");
    assertInferredElementTypeString(testUnit, "v3", "int");
    assertInferredElementTypeString(testUnit, "v4", "Object");
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
    assertInferredElementTypeString(testUnit, "a1", "List<Object>");
    assertInferredElementTypeString(testUnit, "b1", "List<Object>");
  }
  
  /**
   * Prefer specific type, not Dynamic type argument.
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
    assertInferredElementTypeString(testUnit, "a1", "List<String>");
    assertInferredElementTypeString(testUnit, "b1", "List<String>");
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
    assertInferredElementTypeString(testUnit, "v1", "Dynamic");
    assertInferredElementTypeString(testUnit, "v2", "String");
    assertInferredElementTypeString(testUnit, "v3", "String");
  }

  /**
   * When we can not identify type of assigned value we should keep "Dynamic" as type of variable.
   */
  public void test_typesPropagation_assign_newUnknownType() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f() {",
        "  var v1 = new Unknown();",
        "  var v2 = new Unknown.name();",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "Dynamic");
    assertInferredElementTypeString(testUnit, "v2", "Dynamic");
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
    assertInferredElementTypeString(testUnit, "v1", "String");
    assertInferredElementTypeString(testUnit, "v2", "Dynamic");
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
    assertInferredElementTypeString(testUnit, "v1", "String");
    assertInferredElementTypeString(testUnit, "v2", "Dynamic");
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
    assertInferredElementTypeString(testUnit, "v1", "List<String>");
    assertInferredElementTypeString(testUnit, "v2", "Map<int, String>");
    assertInferredElementTypeString(testUnit, "v3", "Dynamic");
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
        "  if (a is Dynamic) {",
        "    var a2 = a;",
        "  }",
        "  if (b is int) {",
        "    var b1 = b;",
        "  }",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "a1", "int");
    assertInferredElementTypeString(testUnit, "a2", "int");
    assertInferredElementTypeString(testUnit, "b1", "int");
  }

  /**
   * When single variable has conflicting type constraints, right now we don't try to unify them,
   * instead we fall back to "Dynamic".
   */
  public void test_typesPropagation_ifIsType_conflictingTypes() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "f(int v) {",
        "  if (v is String) {",
        "    var v1 = v;",
        "  }",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "Dynamic");
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
    assertInferredElementTypeString(testUnit, "v1", "Dynamic");
    assertInferredElementTypeString(testUnit, "v2", "Dynamic");
    assertInferredElementTypeString(testUnit, "v3", "String");
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
    assertInferredElementTypeString(testUnit, "a1", "String");
    assertInferredElementTypeString(testUnit, "b1", "List<String>");
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
    assertInferredElementTypeString(testUnit, "v1", "Dynamic");
    assertInferredElementTypeString(testUnit, "v2", "Dynamic");
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
    assertInferredElementTypeString(testUnit, "v1", "String");
    assertInferredElementTypeString(testUnit, "v2", "Dynamic");
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
    assertInferredElementTypeString(testUnit, "v1", "String");
    assertInferredElementTypeString(testUnit, "v2", "String");
    assertInferredElementTypeString(testUnit, "v3", "Dynamic");
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
    assertInferredElementTypeString(testUnit, "v1", "String");
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
    assertInferredElementTypeString(testUnit, "v1", "Dynamic");
    // we know that String
    assertInferredElementTypeString(testUnit, "v2", "String");
    // again, we don't know after "if"
    assertInferredElementTypeString(testUnit, "v3", "Dynamic");
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
    assertInferredElementTypeString(testUnit, "v1", "Dynamic");
    assertInferredElementTypeString(testUnit, "v2", "String");
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
    assertInferredElementTypeString(testUnit, "v1", "String");
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
    assertInferredElementTypeString(testUnit, "v1", "Dynamic");
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
    assertInferredElementTypeString(testUnit, "v1", "Dynamic");
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
    assertInferredElementTypeString(testUnit, "v1", "Dynamic");
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
    assertInferredElementTypeString(testUnit, "v1", "int");
    assertInferredElementTypeString(testUnit, "v2", "String");
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
    assertInferredElementTypeString(testUnit, "v1", "Dynamic");
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
    assertInferredElementTypeString(testUnit, "v1", "Dynamic");
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
    assertInferredElementTypeString(testUnit, "v1", "String");
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
    assertInferredElementTypeString(testUnit, "v1", "String");
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
    assertInferredElementTypeString(testUnit, "v1", "Dynamic");
    // after "assert" all next statements know type
    assertInferredElementTypeString(testUnit, "v2", "String");
    assertInferredElementTypeString(testUnit, "v3", "String");
    // type is set to unknown only when we exit control Block, not just any Block
    assertInferredElementTypeString(testUnit, "v4", "String");
    // we exited "if" Block, so "assert" may be was not executed, so we don't know type
    assertInferredElementTypeString(testUnit, "v5", "Dynamic");
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
    assertInferredElementTypeString(testUnit, "a1", "Dynamic");
    assertInferredElementTypeString(testUnit, "b1", "Dynamic");
    // after "assert" all next statements know type
    assertInferredElementTypeString(testUnit, "a2", "String");
    assertInferredElementTypeString(testUnit, "b2", "String");
    // we exited "if" Block, so "assert" may be was not executed, so we don't know type
    assertInferredElementTypeString(testUnit, "a3", "Dynamic");
    assertInferredElementTypeString(testUnit, "b3", "Dynamic");
  }

  public void test_typesPropagation_field_inClass_final() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  final v1 = 123;",
        "  final v2 = 1 + 2.0;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "int");
    assertInferredElementTypeString(testUnit, "v2", "double");
  }

  public void test_typesPropagation_field_inClass_const() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  const v1 = 123;",
        "  final v2 = 1 + 2.0;",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v1", "int");
    assertInferredElementTypeString(testUnit, "v2", "double");
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
    assertInferredElementTypeString(testUnit, "v1", "Dynamic");
  }

  public void test_typesPropagation_field_topLevel_final() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "final v1 = 123;",
        "final v2 = 1 + 2.0;",
        "");
    assertInferredElementTypeString(testUnit, "v1", "int");
    assertInferredElementTypeString(testUnit, "v2", "double");
  }

  public void test_typesPropagation_field_topLevel_const() throws Exception {
    analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "const v1 = 123;",
        "const v2 = 1 + 2.0;",
        "");
    assertInferredElementTypeString(testUnit, "v1", "int");
    assertInferredElementTypeString(testUnit, "v2", "double");
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
    assertInferredElementTypeString(testUnit, "v1", "Dynamic");
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
    assertInferredElementTypeString(testUnit, "v", "F");
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
    assertInferredElementTypeString(testUnit, "v", "Event");
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
    assertInferredElementTypeString(testUnit, "v", "Event");
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
        "foo([EventListener listener]) {",
        "}",
        "main() {",
        "  foo(listener: (e) {",
        "    var v = e;",
        "  });",
        "}",
        "");
    assertInferredElementTypeString(testUnit, "v", "Event");
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
    assertInferredElementTypeString(testUnit, "v", "Event");
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
    assertInferredElementTypeString(testUnit, "v", "Event");
  }
  
  /**
   * Helpful (but not perfectly satisfying Specification) type of "conditional" is intersection of
   * then/else types, not just their "least upper bounds". And this corresponds runtime behavior.
   */
  public void test_typesPropagation_conditional() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "interface I1 {",
        "  f1();",
        "}",
        "interface I2 {",
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
      DartExpression expression = findExpression(testUnit, "v.f1()");
      assertNotNull(expression);
      assertNotNull(expression.getElement());
    }
    // v.f2() was resolved
    {
      DartExpression expression = findExpression(testUnit, "v.f1()");
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
    assertInferredElementTypeString(testUnit, "v1", "int");
    assertInferredElementTypeString(testUnit, "v2", "int");
    assertInferredElementTypeString(testUnit, "v3", "int");
    assertInferredElementTypeString(testUnit, "v4", "int");
    assertInferredElementTypeString(testUnit, "v5", "int");
    assertInferredElementTypeString(testUnit, "v6", "double");
    assertInferredElementTypeString(testUnit, "v7", "double");
    assertInferredElementTypeString(testUnit, "v8", "double");
    assertInferredElementTypeString(testUnit, "v9", "double");
    assertInferredElementTypeString(testUnit, "v10", "double");
    assertInferredElementTypeString(testUnit, "v11", "double");
    assertInferredElementTypeString(testUnit, "v12", "double");
    assertInferredElementTypeString(testUnit, "v13", "double");
    assertInferredElementTypeString(testUnit, "v14", "double");
    assertInferredElementTypeString(testUnit, "v15", "double");
    assertInferredElementTypeString(testUnit, "v16", "double");
    assertInferredElementTypeString(testUnit, "v17", "int");
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
        "  int get intProperty() => 42;",
        "  bool get boolProperty() => true;",
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
    assertInferredElementTypeString(testUnit, "v1", "int");
    assertInferredElementTypeString(testUnit, "v2", "bool");
  }

  public void test_getType_getterInNegation_generic() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "class A<T> {",
        "  T field;",
        "  T get prop() => null;",
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
    assertInferredElementTypeString(testUnit, "v1", "bool");
    assertInferredElementTypeString(testUnit, "v2", "bool");
  }

  public void test_getType_getterInSwitch_default() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "int get foo() {}",
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
        "int get foo() => 42;",
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
        "  T get foo() => null;",
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
   * It is a static warning if the return type of the user-declared operator negate is explicitly
   * declared and not a numerical type.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3224
   */
  public void test_negateOperatorType() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  num operator negate() {}",
        "}",
        "class B {",
        "  int operator negate() {}",
        "}",
        "class C {",
        "  double operator negate() {}",
        "}",
        "class D {",
        "  String operator negate() {}",
        "}",
        "class E {",
        "  Object operator negate() {}",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.OPERATOR_NEGATE_NUM_RETURN_TYPE, 12, 3, 6),
        errEx(TypeErrorCode.OPERATOR_NEGATE_NUM_RETURN_TYPE, 15, 3, 6));
  }

  /**
   * It is a static warning if the return type of the user-declared operator equals is explicitly
   * declared and not bool.
   */
  public void test_equalsOperator_type() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  bool operator equals(other) {}",
        "}",
        "class B {",
        "  String operator equals(other) {}",
        "}",
        "class C {",
        "  Object operator equals(other) {}",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
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
            "  operator equals(other) => false;",
            "}",
            "main() {",
            "  new C() == new C();",
            "}",
            "");
    assertErrors(libraryResult.getErrors());
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnit(getName());
    // find == expression
    DartExpression expression = findExpression(unit, "new C() == new C()");
    assertNotNull(expression);
    // validate == element
    MethodElement equalsElement = (MethodElement) expression.getElement();
    assertNotNull(equalsElement);
  }

  public void test_supertypeHasMethod() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class A {}",
            "interface I {",
            "  foo();",
            "  bar();",
            "}",
            "interface J extends I {",
            "  get foo();",
            "  set bar();",
            "}");
      assertErrors(libraryResult.getTypeErrors(),
          errEx(TypeErrorCode.SUPERTYPE_HAS_METHOD, 8, 7, 3),
          errEx(TypeErrorCode.SUPERTYPE_HAS_METHOD, 9, 7, 3));
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
   * "It is a compile-time error to use a built-in identifier other than Dynamic as a type annotation."
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3307
   */
  public void test_builtInIdentifier_asTypeAnnotation() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "main() {",
        "  abstract   v01;",
        "  assert     v02;",
        "  Dynamic    v03;",
        "  equals     v04;",
        "  factory    v05;",
        "  get        v06;",
        "  implements v07;",
        "//  interface  v08;",
        "  negate     v09;",
        "  operator   v10;",
        "  set        v11;",
        "  static     v12;",
        "//  typedef    v13;",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 3, 3, 8),
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 4, 3, 6),
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 6, 3, 6),
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 7, 3, 7),
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 8, 3, 3),
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 9, 3, 10),
//        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 10, 3, 8),
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 11, 3, 6),
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 12, 3, 8),
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 13, 3, 3),
        errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 14, 3, 6)
//        ,errEx(ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 15, 3, 7)
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

  public void test_supertypeHasGetterSetter() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {}",
        "interface I {",
        "  get foo();",
        "  set bar();",
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
        "interface Interface<T> {",
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
        "interface Interface<T> {",
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
        "  get method() { }",
        "}",
        "main () {",
        "  new C().method = _() {};",
        "}");
    assertErrors(
        libraryResult.getErrors(),
        errEx(TypeErrorCode.FIELD_HAS_NO_SETTER, 5, 11, 6));
  }

  public void test_assignArrayElement() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class C {" +
        "  get method() { }",
        "  operator [](arg) {}",
        "}",
        "main () {",
        "  new C()[0] = 1;",
        "}");
    assertErrors(
        libraryResult.getErrors());
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
        errEx(ResolverErrorCode.RETHROW_NOT_IN_CATCH, 3, 3, 6));
  }

  public void test_externalKeyword_OK() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "external topFunction();",
        "external get topGetter();",
        "external set topSetter(var v);",
        "class A {",
        "  external const A.con();",
        "  external A();",
        "  external factory A.named();",
        "  external classMethod();",
        "  external static classMethodStatic();",
        "  external get classGetter();",
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
        "class A {",
        "  external A() {}",
        "  external factory A.named() {}",
        "  external classMethod() {}",
        "  external abstract classMethodAbstract();",
        "}",
        "");
    assertErrors(
        libraryResult.getErrors(),
        errEx(ParserErrorCode.EXTERNAL_METHOD_BODY, 2, 24, 2),
        errEx(ParserErrorCode.EXTERNAL_METHOD_BODY, 4, 16, 2),
        errEx(ParserErrorCode.EXTERNAL_METHOD_BODY, 5, 30, 2),
        errEx(ParserErrorCode.EXTERNAL_METHOD_BODY, 6, 26, 2),
        errEx(ParserErrorCode.EXTERNAL_ABSTRACT, 7, 12, 8));
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
  }
  
  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4315
   */
  public void test_cascade_methodInvocation() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  int m() {}",
        "}",
        "main() {",
        "  A a = new A();",
        "  a",
        "    ..m()",
        "    ..m();",
        "}",
        "");
    assertErrors(libraryResult.getErrors());
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
    AnalyzeLibraryResult libraryResult = analyzeLibrary(makeCode(
        "// filler filler filler filler filler filler filler filler filler filler",
        "process(x) {}",
        "main() {",
        "  unknown = 0;",
        "  process(unknown);",
        "}"));
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
    AnalyzeLibraryResult libraryResult = analyzeLibrary(makeCode(
        "// filler filler filler filler filler filler filler filler filler filler",
        "process(x) {}",
        "class A {",
        "  foo() {",
        "    unknown = 0;",
        "    process(unknown);",
        "  }",
        "}"));
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
    AnalyzeLibraryResult libraryResult = analyzeLibrary(makeCode(
        "// filler filler filler filler filler filler filler filler filler filler",
        "process(x) {}",
        "main() {",
        "  Unknown.foo = 0;",
        "  process(Unknown.foo);",
        "}"));
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
    AnalyzeLibraryResult libraryResult = analyzeLibrary(makeCode(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {}",
        "main() {",
        "  new A(); // OK",
        "  new A.noSuchConstructor(); // warning",
        "  new B(); // warning",
        "  new B.noSuchConstructor(); // warning",
        "}"));
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.NEW_EXPRESSION_NOT_CONSTRUCTOR, 5, 7, 19),
        errEx(TypeErrorCode.NO_SUCH_TYPE, 6, 7, 1),
        errEx(TypeErrorCode.NO_SUCH_TYPE, 7, 7, 1),
        errEx(ResolverErrorCode.NEW_EXPRESSION_NOT_CONSTRUCTOR, 7, 7, 19));
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
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {}",
        "process(x) {}",
        "main() {",
        "  A aaa = new A();",
        "  process(aaa);",
        "}");
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnit(getName());
    unit.accept(new ASTVisitor<Void>() {
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
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class AAA {",
        "  static foo() {}",
        "}",
        "main() {",
        "  AAA.foo();",
        "}");
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnit(getName());
    unit.accept(new ASTVisitor<Void>() {
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
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnit(getName());
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
    }.doTest(unit);
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
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnit(getName());
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
    }.doTest(unit);
  }

  /**
   * A constructor name always begins with the name of its immediately enclosing class, and may
   * optionally be followed by a dot and an identifier id. It is a compile-time error if id is the
   * name of a member declared in the immediately enclosing class.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3989
   */
  public void test_constructorName_sameAsMemberName() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(makeCode(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  A.foo() {}",
        "  foo() {}",
        "}"));
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.CONSTRUCTOR_WITH_NAME_OF_MEMBER, 3, 3, 5));
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3904
   */
  public void test_reifiedClasses() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(makeCode(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {}",
        "process(x) {}",
        "main() {",
        "  process(A);",
        "}"));
    assertErrors(libraryResult.getErrors());
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=3968
   */
  public void test_redirectingFactoryConstructor() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(makeCode(
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
        ""));
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
  
  public void test_redirectingFactoryConstructor_notConst_fromConst() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(makeCode(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class A {",
        "  A.named() {}",
        "}",
        "",
        "class B {",
        "  const factory B.bar() = A.named;",
        "}",
        ""));
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.REDIRECTION_CONSTRUCTOR_TARGET_MUST_BE_CONST, 7, 29, 5));
  }

  /**
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=4778
   */
  public void test_unqualifiedAccessToGenericTypeField() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(makeCode(
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
        ""));
    assertErrors(libraryResult.getErrors());
  }

  private <T extends DartNode> T findNode(final Class<T> clazz, String pattern) {
    final int index = testSource.indexOf(pattern);
    assertTrue(index != -1);
    final AtomicReference<T> result = new AtomicReference<T>();
    testUnit.accept(new ASTVisitor<Void>() {
      @Override
      @SuppressWarnings("unchecked")
      public Void visitNode(DartNode node) {
        SourceInfo sourceInfo = node.getSourceInfo();
        if (sourceInfo.getOffset() <= index
            && index < sourceInfo.getEnd()
            && clazz.isInstance(node)) {
          result.set((T) node);
        }
        return super.visitNode(node);
      }
    });
    return result.get();
  }
}
