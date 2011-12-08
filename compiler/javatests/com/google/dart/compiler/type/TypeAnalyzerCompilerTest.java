// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.type;

import com.google.common.base.Joiner;
import com.google.common.collect.Iterables;
import com.google.dart.compiler.CompilerTestCase;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartInvocation;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNewExpression;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartNodeTraverser;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.parser.ParserErrorCode;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.ElementKind;
import com.google.dart.compiler.resolver.EnclosingElement;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.resolver.TypeErrorCode;

import java.util.List;

/**
 * Variant of {@link TypeAnalyzerTest}, which is based on {@link CompilerTestCase}. It is probably
 * slower, not actually unit test, but easier to use if you need access to DartNode's.
 */
public class TypeAnalyzerCompilerTest extends CompilerTestCase {
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
    Element methodElement = invocation.getReferencedElement();
    assertNotNull(methodElement);
    assertSame(ElementKind.METHOD, methodElement.getKind());
    assertEquals("f", ((MethodElement) methodElement).getOriginalSymbolName());
    // enclosing Element of MethodElement is ClassElement
    EnclosingElement classElement = methodElement.getEnclosingElement();
    assertNotNull(classElement);
    assertSame(ElementKind.CLASS, classElement.getKind());
    assertEquals("Test", ((ClassElement) classElement).getOriginalSymbolName());
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
    Element functionElement = invocation.getReferencedElement();
    assertNotNull(functionElement);
    assertSame(ElementKind.FUNCTION_OBJECT, functionElement.getKind());
    assertEquals("f", ((MethodElement) functionElement).getOriginalSymbolName());
    // enclosing Element of this FUNCTION_OBJECT is enclosing method
    EnclosingElement enclosingMethodElement = functionElement.getEnclosingElement();
    assertNotNull(enclosingMethodElement);
    assertSame(ElementKind.METHOD, enclosingMethodElement.getKind());
    assertEquals("foo", ((MethodElement) enclosingMethodElement).getName());
    // use EnclosingElement methods implementations in MethodElement
    assertEquals(false, enclosingMethodElement.isInterface());
    assertEquals(true, Iterables.isEmpty(enclosingMethodElement.getMembers()));
    assertEquals(null, enclosingMethodElement.lookupLocalElement("f"));
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
    assertEquals("foo", ((DartIdentifier) factory.getName()).getTargetName());
    // compilation error expected
    assertBadTopLevelFactoryError(libraryResult);
  }

  /**
   * Language specification requires that factory should be declared in class. However declaring
   * factory on top level should not cause exceptions in compiler. Even if type parameters are used.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=345
   */
  public void test_badTopLevelFactory_withTypeParameters() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary("Test.dart", "factory foo<T>() {}");
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
    DartMethodDefinition factory = (DartMethodDefinition) unit.getTopLevelNodes().get(0);
    assertNotNull(factory);
    // normal method requires name, so we provide some name
    assertEquals(true, factory.getName() instanceof DartIdentifier);
    assertEquals("foo<T>", ((DartIdentifier) factory.getName()).getTargetName());
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
    assertEquals(ParserErrorCode.DISALLOWED_FACTORY_KEYWORD, compilationError.getErrorCode());
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
    rootNode.accept(new DartNodeTraverser<Void>() {
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
                "interface I factory F {",
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
      assertErrors(errors, errEx(TypeErrorCode.FACTORY_CONSTRUCTOR_TYPES, 2, 3, 29));
      assertEquals(
          "Constructor 'I.foo' in 'I' has parameters types (int,int,int), doesn't match 'F.foo' in 'F' with (num,bool,Object)",
          errors.get(0).getMessage());
    }
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
    // "new I.foo()" - resolved, but we produce error.
    {
      DartNewExpression newExpression = findNewExpression(unit, "new I.foo(0)");
      DartNode constructorNode = newExpression.getSymbol().getNode();
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
                "interface I factory F {",
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
      DartParameter parameter = methodF.getFunction().getParams().get(0);
      assertEquals("int", parameter.getSymbol().getType().toString());
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
        errEx(TypeErrorCode.ABSTRACT_CLASS_WITHOUT_ABSTRACT_MODIFIER, 8, 7, 1),
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
        errEx(TypeErrorCode.ABSTRACT_CLASS_WITHOUT_ABSTRACT_MODIFIER, 4, 7, 1),
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
   * Factory constructor can instantiate any class and return it non-abstract class instance, but
   * spec requires warnings, so we provide it, but using different constant.
   */
  public void test_warnAbstract_onAbstractClass_whenInstantiate_factoryConstructor()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            getName(),
            makeCode(
                "abstract class A {",
                "  factory A() {",
                "    return null;",
                "  }",
                "}",
                "class C {",
                "  foo() {",
                "    return new A();",
                "  }",
                "}"));
    assertErrors(
        libraryResult.getTypeErrors(),
        errEx(TypeErrorCode.INSTANTIATION_OF_ABSTRACT_CLASS_USING_FACTORY, 8, 16, 1));
  }
}
