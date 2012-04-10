// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartExprStmt;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.ast.DartReturnStatement;
import com.google.dart.compiler.ast.DartStatement;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.DartUnqualifiedInvocation;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.CoreTypeProvider;
import com.google.dart.compiler.resolver.CoreTypeProviderImplementation;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.FieldElement;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.resolver.Scope;
import com.google.dart.compiler.testing.TestCompilerConfiguration;
import com.google.dart.compiler.testing.TestCompilerContext;
import com.google.dart.compiler.testing.TestCompilerContext.EventKind;
import com.google.dart.compiler.testing.TestDartArtifactProvider;
import com.google.dart.compiler.testing.TestLibrarySource;
import com.google.dart.compiler.type.FunctionType;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeAnalyzer;

import junit.framework.TestCase;

import java.io.IOException;

/**
 * Test of the IDE API in DartCompiler.
 */
public class IdeTest extends TestCase {

  private final TestCompilerContext context = new TestCompilerContext(EventKind.ERROR,
      EventKind.TYPE_ERROR) {
    @Override
    protected void handleEvent(DartCompilationError event, EventKind kind) {
      super.handleEvent(event, kind);
      // For debugging:
      // System.err.println(event);
    }
  };

  private final DartCompilerListener listener = context;

  private final DartArtifactProvider provider = new TestDartArtifactProvider();

  private final CompilerConfiguration config = new TestCompilerConfiguration();

  public void testAnalyseNoSemicolonPropertyAccess() {
    DartUnit unit =
        analyzeUnit(
            "no_semicolon_property_access",
            "class Foo {",
            "  int i;",
            "  void foo() {",
            "    i.y", // Missing semicolon.
            "  }",
            "}");
    assertEquals("errorCount", 1, context.getErrorCount()); // Missing semicolon.
    assertEquals("typeErrorCount", 1, context.getTypeErrorCount()); // No member named "y".
    DartExprStmt statement = (DartExprStmt) firstStatementOfMethod(unit, "Foo", "foo");
    FieldElement element = (FieldElement) qualifierElement(statement.getExpression());
    assertEquals("int", element.getType().getElement().getName());
  }

  public void testAnalyseNoSemicolonBrokenPropertyAccess() {
    DartUnit unit =
        analyzeUnit(
            "no_semicolon_broken_property_access",
            "class Foo {",
            "  int i;",
            "  void foo() {",
            "    i.", // Syntax error and missing semicolon.
            "  }",
            "}");
    // Expected identifier and missing semicolon
    assertEquals("errorCount", 2, context.getErrorCount());
    assertEquals("typeErrorCount", 1, context.getTypeErrorCount()); // No member named "".
    DartExprStmt statement = (DartExprStmt) firstStatementOfMethod(unit, "Foo", "foo");
    FieldElement element = (FieldElement) qualifierElement(statement.getExpression());
    assertEquals("int", element.getType().getElement().getName());
  }

  public void testAnalyseBrokenPropertyAccess() {
    DartUnit unit =
        analyzeUnit(
            "broken_property_access",
            "class Foo {",
            "  int i;",
            "  void foo() {",
            "    i.;", // Syntax error here.
            "  }",
            "}");
    assertEquals("errorCount", 1, context.getErrorCount()); // Expected identifier.
    assertEquals("typeErrorCount", 1, context.getTypeErrorCount()); // No member named "".
    DartExprStmt statement = (DartExprStmt) firstStatementOfMethod(unit, "Foo", "foo");
    FieldElement element = (FieldElement) qualifierElement(statement.getExpression());
    assertEquals("int", element.getType().getElement().getName());
  }

  public void testAnalyseNoSemicolonIdentifier() {
    DartUnit unit =
        analyzeUnit(
            "no_semicolon_identifier",
            "class Foo {",
            "  int i;",
            "  void foo() {",
            "    i", // Missing semicolon.
            "  }",
            "}");
    assertEquals("errorCount", 1, context.getErrorCount()); // Missing semicolon.
    assertEquals("typeErrorCount", 0, context.getTypeErrorCount());
    DartExprStmt statement = (DartExprStmt) firstStatementOfMethod(unit, "Foo", "foo");
    FieldElement field = (FieldElement) targetElement(statement.getExpression());
    assertEquals("int", field.getType().getElement().getName());
  }

  public void testAnalyseNoSemicolonMethodCall() {
    DartUnit unit =
        analyzeUnit(
            "no_semicolon_method_call",
            "class Foo {",
            "  int i () { return 0; }",
            "  void foo() {",
            "    i()", // Missing semicolon.
            "  }",
            "}");
    assertEquals("errorCount", 1, context.getErrorCount()); // Missing semicolon.
    assertEquals("typeErrorCount", 0, context.getTypeErrorCount());
    DartExprStmt statement = (DartExprStmt) firstStatementOfMethod(unit, "Foo", "foo");
    DartExpression expression = statement.getExpression();
    DartUnqualifiedInvocation invocation = (DartUnqualifiedInvocation) expression;
    MethodElement method = (MethodElement) targetElement(invocation.getTarget());
    assertEquals("i", method.getName());
    FunctionType type = (FunctionType) method.getType();
    assertEquals("int", type.getReturnType().getElement().getName());
  }

  public void testAnalyseVoidKeyword() {
    DartUnit unit =
        analyzeUnit(
            "void_keyword",
            "class Foo {",
            "  Function voidFunction;",
            "  void foo() {",
            "    void", // Missing semicolon and keyword
            "  }",
            "}");
    // Expected identifier and missing semicolon.
    assertEquals("errorCount", 2, context.getErrorCount());
    // You can't use 'void' as a member name.  It might be the beginning of a variable declaration
    // so it isn't an error in and of itself.
    assertEquals("typeErrorCount", 0, context.getTypeErrorCount());
    DartExprStmt statement = (DartExprStmt) firstStatementOfMethod(unit, "Foo", "foo");
    DartIdentifier expression = (DartIdentifier) statement.getExpression();
    assertEquals("", expression.getName());
  }

  public void testAnalyseVoidKeywordPropertyAccess() {
    DartUnit unit =
        analyzeUnit(
            "void_keyword_property_access",
            "class Foo {",
            "  Function voidFunction;",
            "  void foo() {",
            "    this.void", // Missing semicolon and keyword
            "  }",
            "}");
    // Expected identifier and missing semicolon.
    assertEquals("errorCount", 2, context.getErrorCount());
    assertEquals("typeErrorCount", 1, context.getTypeErrorCount());
    DartExprStmt statement = (DartExprStmt) firstStatementOfMethod(unit, "Foo", "foo");
    DartPropertyAccess expression = (DartPropertyAccess) statement.getExpression();
    assertEquals("", expression.getPropertyName());
  }

  public void testReturnIntTypeAnalysis() {
    DartUnit unit =
        analyzeUnit(
            "return_int_type_analysis",
            "class Foo {",
            "  int i;",
            "  int foo() {",
            "    return i;",
            "  }",
            "}");
    Scope unitScope = unit.getLibrary().getElement().getScope();
    CoreTypeProvider typeProvider = new CoreTypeProviderImplementation(unitScope, context);
    DartClass classNode = getClassOfUnit(unit, "Foo");
    DartReturnStatement rtnStmt = (DartReturnStatement) firstStatementOfMethod(unit, "Foo", "foo");
    ClassElement classElement = classNode.getElement();
    InterfaceType definingType = classElement.getType();
    Type type = TypeAnalyzer.analyze(rtnStmt.getValue(), typeProvider, context, definingType);
    assertNotNull(type);
    assertEquals("int", type.getElement().getName());
  }

  private Element targetElement(DartExpression expression) {
    DartIdentifier identifier = (DartIdentifier) expression;
    Element element = identifier.getElement();
    assertNotNull(element);
    return element;
  }

  private Element qualifierElement(DartExpression node) {
    DartPropertyAccess propertyAccess = (DartPropertyAccess) node;
    DartIdentifier identifier = (DartIdentifier) propertyAccess.getQualifier();
    Element element = identifier.getElement();
    assertNotNull(element);
    return element;
  }

  private DartClass getClassOfUnit(DartUnit unit, String cls) {
    DartClass dartClass = null;
    for (DartNode node : unit.getTopLevelNodes()) {
      DartClass classNode = (DartClass) node;
      if (node instanceof DartClass) {
        if (classNode.getName().getName().equals(cls)) {
          dartClass = classNode;
        }
      }
    }
    assertNotNull(dartClass);
    return dartClass;
  }

  private DartStatement firstStatementOfMethod(DartUnit unit, String cls, String member) {
    DartClass classNode = getClassOfUnit(unit, cls);
    for (DartNode memberNode : classNode.getMembers()) {
      if (memberNode instanceof DartMethodDefinition) {
        DartMethodDefinition methodNode = (DartMethodDefinition) memberNode;
        if (methodNode.getName() instanceof DartIdentifier) {
          DartIdentifier methodName = (DartIdentifier) methodNode.getName();
          if (methodName.getName().equals(member)) {
            return methodNode.getFunction().getBody().getStatements().get(0);
          }
        }
      }
    }
    fail();
    return null;
  }

  private DartUnit analyzeUnit(String name, String... sourceLines) throws AssertionError {
    TestLibrarySource lib = new TestLibrarySource(name);
    lib.addSource(name + ".dart", sourceLines);
    LibraryUnit libraryUnit;
    try {
      libraryUnit = DartCompiler.analyzeLibrary(lib, null, config, provider, listener);
      assertNotNull("libraryUnit == null", libraryUnit);
    } catch (IOException e) {
      throw new AssertionError(e);
    }
    DartUnit unit = libraryUnit.getUnit(name + ".dart");
    assertNotNull("unit == null", unit);
    return unit;
  }
}
