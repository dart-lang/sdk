// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.resolver;

import com.google.common.base.Joiner;
import com.google.dart.compiler.CompilerTestCase;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.ast.DartInvocation;
import com.google.dart.compiler.ast.DartNewExpression;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartNodeTraverser;
import com.google.dart.compiler.ast.DartUnit;

import java.util.List;

/**
 * Variant of {@link ResolverTest}, which is based on {@link CompilerTestCase}. It is probably
 * slower, not actually unit test, but easier to use if you need access to DartNode's.
 */
public class ResolverCompilerTest extends CompilerTestCase {
  /**
   * @return the {@link DartInvocation} with given source. This is inaccurate approach, but good
   *         enough for specific tests.
   */
  private static DartNewExpression findNewExpression(DartNode rootNode, final String sampleSource) {
    final DartNewExpression result[] = new DartNewExpression[1];
    rootNode.accept(new DartNodeTraverser<Void>() {
      @Override
      public Void visitNewExpression(DartNewExpression node) {
        if (node.toSource().equals(sampleSource)) {
          result[0] = node;
        }
        return super.visitInvocation(node);
      }
    });
    return result[0];
  }

  /**
   * We should be able to resolve implicit default constructor.
   */
  public void test_resolveConstructor_implicit() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "Test.dart",
            Joiner.on("\n").join(
                "class F {",
                "}",
                "class Test {",
                "  foo() {",
                "    new F();",
                "  }",
                "}"));
    assertErrors(libraryResult.getCompilationErrors());
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
    DartNewExpression newExpression = findNewExpression(unit, "new F()");
    ConstructorElement constructorElement = newExpression.getSymbol();
    assertNotNull(constructorElement);
    assertNull(constructorElement.getNode());
  }

  public void test_resolveConstructor_noSuchConstructor() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "Test.dart",
            Joiner.on("\n").join(
                "class A {",
                "}",
                "class Test {",
                "  foo() {",
                "    new A.foo();",
                "  }",
                "}"));
    assertErrors(
        libraryResult.getCompilationErrors(),
        errEx(ResolverErrorCode.NEW_EXPRESSION_NOT_CONSTRUCTOR, 5, 9, 5));
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
    DartNewExpression newExpression = findNewExpression(unit, "new A.foo()");
    ConstructorElement constructorElement = newExpression.getSymbol();
    assertNull(constructorElement);
  }

  /**
   * We should be able to resolve implicit default constructor.
   */
  public void test_resolveInterfaceConstructor_implicitDefault_noInterface_noFactory()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "Test.dart",
            Joiner.on("\n").join(
                "interface I factory F {",
                "}",
                "class F implements I {",
                "}",
                "class Test {",
                "  foo() {",
                "    new I();",
                "  }",
                "}"));
    assertErrors(libraryResult.getCompilationErrors());
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
    DartNewExpression newExpression = findNewExpression(unit, "new I()");
    ConstructorElement constructorElement = newExpression.getSymbol();
    assertNotNull(constructorElement);
    assertNull(constructorElement.getNode());
  }

  /**
   * We should be able to resolve implicit default constructor.
   */
  public void test_resolveInterfaceConstructor_implicitDefault_hasInterface_noFactory()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "Test.dart",
            Joiner.on("\n").join(
                "interface I factory F {",
                "}",
                "class F implements I {",
                "}",
                "class Test {",
                "  foo() {",
                "    new I();",
                "  }",
                "}"));
    assertErrors(libraryResult.getCompilationErrors());
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
    DartNewExpression newExpression = findNewExpression(unit, "new I()");
    ConstructorElement constructorElement = newExpression.getSymbol();
    assertNotNull(constructorElement);
    assertNull(constructorElement.getNode());
  }

  /**
   * We should be able to resolve implicit default constructor.
   */
  public void test_resolveInterfaceConstructor_implicitDefault_noInterface_hasFactory()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "Test.dart",
            Joiner.on("\n").join(
                "interface I factory F {",
                "}",
                "class F implements I {",
                "  F();",
                "}",
                "class Test {",
                "  foo() {",
                "    new I();",
                "  }",
                "}"));
    assertErrors(libraryResult.getCompilationErrors());
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
    DartNewExpression newExpression = findNewExpression(unit, "new I()");
    DartNode constructorNode = newExpression.getSymbol().getNode();
    assertEquals(true, constructorNode.toSource().contains("F()"));
  }

  /**
   * If "const I()" is used, then constructor should be "const".
   */
  public void test_resolveInterfaceConstructor_const() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "Test.dart",
            Joiner.on("\n").join(
                "interface I factory F {",
                "  I(int x);",
                "}",
                "class F implements I {",
                "  F(int y) {}",
                "}",
                "class Test {",
                "  foo() {",
                "    const I(0);",
                "  }",
                "}"));
    assertErrors(
        libraryResult.getCompilationErrors(),
        errEx(ResolverErrorCode.CONST_AND_NONCONST_CONSTRUCTOR, 9, 5, 10));
  }

  /**
   * From specification 0.05, 11/14/2011.
   * <p>
   * A constructor kI of I corresponds to a constructor kF of its factory class F if either
   * <ul>
   * <li>F does not implement I and kI and kF have the same name, OR
   * <li>F implements I and either
   * <ul>
   * <li>kI is named NI and kF is named NF, OR
   * <li>kI is named NI.id and kF is named NF.id.
   * </ul>
   * </ul>
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=521
   */
  public void test_resolveInterfaceConstructor_whenFactoryImplementsInterface_nameIsIdentifier()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "Test.dart",
            Joiner.on("\n").join(
                "interface I factory F {",
                "  I(int x);",
                "}",
                "class F implements I {",
                "  F(int y) {}",
                "  factory I(int y) {}",
                "}",
                "class Test {",
                "  foo() {",
                "    new I(0);",
                "  }",
                "}"));
    assertErrors(libraryResult.getCompilationErrors());
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
    DartNewExpression newExpression = findNewExpression(unit, "new I(0)");
    DartNode constructorNode = newExpression.getSymbol().getNode();
    assertEquals(true, constructorNode.toSource().contains("F(int y)"));
  }

  /**
   * From specification 0.05, 11/14/2011.
   * <p>
   * A constructor kI of I corresponds to a constructor kF of its factory class F if either
   * <ul>
   * <li>F does not implement I and kI and kF have the same name, OR
   * <li>F implements I and either
   * <ul>
   * <li>kI is named NI and kF is named NF , OR
   * <li>kI is named NI.id and kF is named NF.id.
   * </ul>
   * </ul>
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=521
   */
  public void test_resolveInterfaceConstructor_whenFactoryImplementsInterface_nameIsQualified()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "Test.dart",
            Joiner.on("\n").join(
                "interface I factory F {",
                "  I.foo(int x);",
                "}",
                "class F implements I {",
                "  F.foo(int y) {}",
                "  factory I.foo(int y) {}",
                "}",
                "class Test {",
                "  foo() {",
                "    new I.foo(0);",
                "  }",
                "}"));
    assertErrors(libraryResult.getCompilationErrors());
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
    // "new I.foo()" - good
    {
      DartNewExpression newExpression = findNewExpression(unit, "new I.foo(0)");
      DartNode constructorNode = newExpression.getSymbol().getNode();
      assertEquals(true, constructorNode.toSource().contains("F.foo(int y)"));
    }
  }

  /**
   * From specification 0.05, 11/14/2011.
   * <p>
   * A constructor kI of I corresponds to a constructor kF of its factory class F if either
   * <ul>
   * <li>F does not implement I and kI and kF have the same name, OR
   * <li>F implements I and either
   * <ul>
   * <li>kI is named NI and kF is named NF , OR
   * <li>kI is named NI.id and kF is named NF.id.
   * </ul>
   * </ul>
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=521
   */
  public void test_resolveInterfaceConstructor_whenFactoryImplementsInterface_negative()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "Test.dart",
            Joiner.on("\n").join(
                "interface I factory F {",
                "  I(int x);",
                "  I.foo(int x);",
                "}",
                "class F implements I {",
                "  factory I.foo(int x) {}",
                "}",
                "class Test {",
                "  foo() {",
                "    new I(0);",
                "    new I.foo(0);",
                "  }",
                "}"));
    // Check errors.
    {
      List<DartCompilationError> errors = libraryResult.getCompilationErrors();
      assertErrors(
          errors,
          errEx(ResolverErrorCode.NEW_EXPRESSION_FACTORY_CONSTRUCTOR, 10, 9, 1),
          errEx(ResolverErrorCode.NEW_EXPRESSION_FACTORY_CONSTRUCTOR, 11, 9, 5));
      {
        String message = errors.get(0).getMessage();
        assertTrue(message, message.contains("'F'"));
        assertTrue(message, message.contains("'F'"));
      }
      {
        String message = errors.get(1).getMessage();
        assertTrue(message, message.contains("'F.foo'"));
        assertTrue(message, message.contains("'F'"));
      }
    }
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
    // "new I()" - no such constructor, has other constructors, so no implicit default.
    {
      DartNewExpression newExpression = findNewExpression(unit, "new I(0)");
      assertEquals(null, newExpression.getSymbol());
    }
    // "new I.foo()" - would be valid, if not "F implements I", but here invalid
    {
      DartNewExpression newExpression = findNewExpression(unit, "new I.foo(0)");
      assertEquals(null, newExpression.getSymbol());
    }
  }

  /**
   * From specification 0.05, 11/14/2011.
   * <p>
   * A constructor kI of I corresponds to a constructor kF of its factory class F if either
   * <ul>
   * <li>F does not implement I and kI and kF have the same name, OR
   * <li>F implements I and either
   * <ul>
   * <li>kI is named NI and kF is named NF , OR
   * <li>kI is named NI.id and kF is named NF.id.
   * </ul>
   * </ul>
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=521
   */
  public void test_resolveInterfaceConstructor_noFactoryImplementsInterface() throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "Test.dart",
            Joiner.on("\n").join(
                "interface I factory F {",
                "  I(int x);",
                "  I.foo(int x);",
                "}",
                "class F {",
                "  F.foo(int y) {}",
                "  factory I(int y) {}",
                "  factory I.foo(int y) {}",
                "}",
                "class Test {",
                "  foo() {",
                "    new I(0);",
                "    new I.foo(0);",
                "  }",
                "}"));
    assertErrors(libraryResult.getCompilationErrors());
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
    // "new I()"
    {
      DartNewExpression newExpression = findNewExpression(unit, "new I(0)");
      DartNode constructorNode = newExpression.getSymbol().getNode();
      assertEquals(true, constructorNode.toSource().contains("I(int y)"));
    }
    // "new I.foo()"
    {
      DartNewExpression newExpression = findNewExpression(unit, "new I.foo(0)");
      DartNode constructorNode = newExpression.getSymbol().getNode();
      assertEquals(true, constructorNode.toSource().contains("I.foo(int y)"));
    }
  }

  /**
   * From specification 0.05, 11/14/2011.
   * <p>
   * A constructor kI of I corresponds to a constructor kF of its factory class F if either
   * <ul>
   * <li>F does not implement I and kI and kF have the same name, OR
   * <li>F implements I and either
   * <ul>
   * <li>kI is named NI and kF is named NF , OR
   * <li>kI is named NI.id and kF is named NF.id.
   * </ul>
   * </ul>
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=521
   */
  public void test_resolveInterfaceConstructor_noFactoryImplementsInterface_negative()
      throws Exception {
    AnalyzeLibraryResult libraryResult =
        analyzeLibrary(
            "Test.dart",
            Joiner.on("\n").join(
                "interface I factory F {",
                "  I.foo(int x);",
                "}",
                "class F {",
                "}",
                "class Test {",
                "  foo() {",
                "    new I.foo(0);",
                "  }",
                "}"));
    // Check errors.
    {
      List<DartCompilationError> errors = libraryResult.getCompilationErrors();
      assertErrors(errors, errEx(ResolverErrorCode.NEW_EXPRESSION_FACTORY_CONSTRUCTOR, 8, 9, 5));
      {
        String message = errors.get(0).getMessage();
        assertTrue(message, message.contains("'I.foo'"));
        assertTrue(message, message.contains("'F'"));
      }
    }
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
    // "new I.foo()"
    {
      DartNewExpression newExpression = findNewExpression(unit, "new I.foo(0)");
      assertEquals(null, newExpression.getSymbol());
    }
  }
}
