// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.resolver;

import com.google.common.base.Joiner;
import com.google.common.collect.Lists;
import com.google.common.io.CharStreams;
import com.google.dart.compiler.CompilerTestCase;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.ast.ASTVisitor;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartDeclaration;
import com.google.dart.compiler.ast.DartExprStmt;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartFieldDefinition;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartFunctionTypeAlias;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartLabel;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNewExpression;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartStatement;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartTypeParameter;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.DartVariableStatement;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.type.FunctionAliasType;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeVariable;

import static com.google.dart.compiler.common.ErrorExpectation.assertErrors;
import static com.google.dart.compiler.common.ErrorExpectation.errEx;

import java.io.Reader;
import java.util.LinkedList;
import java.util.List;

/**
 * Variant of {@link ResolverTest}, which is based on {@link CompilerTestCase}. It is probably
 * slower, not actually unit test, but easier to use if you need access to DartNode's.
 */
public class ResolverCompilerTest extends CompilerTestCase {

  public void test_parameters_withFunctionAlias() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "Test.dart",
        "typedef List<T> TypeAlias<T, U extends List<T>>(List<T> arg, U u);");
    assertErrors(libraryResult.getCompilationErrors());
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
    DartFunctionTypeAlias typeAlias = findTypedef(unit, "TypeAlias");
    assertNotNull(typeAlias);
    FunctionAliasElement element = typeAlias.getElement();
    FunctionAliasType ftype = element.getType();
    Type returnType = ftype.getElement().getFunctionType().getReturnType();
    assertEquals("List<TypeAlias.T>", returnType.toString());
    List<? extends Type> arguments = ftype.getArguments();
    assertEquals(2, arguments.size());
    TypeVariable arg0 = (TypeVariable) arguments.get(0);
    assertEquals("T", arg0.getTypeVariableElement().getName());
    Type bound0 = arg0.getTypeVariableElement().getBound();
    assertEquals("Object", bound0.toString());
    TypeVariable arg1 = (TypeVariable) arguments.get(1);
    assertEquals("U", arg1.getTypeVariableElement().getName());
    Type bound1 = arg1.getTypeVariableElement().getBound();
    assertEquals("List<TypeAlias.T>", bound1.toString());
  }

  /**
   * This test succeeds if no exceptions are thrown.
   */
  public void test_recursiveTypes() throws Exception {
    analyzeLibrary("test.dart", Joiner.on("\n").join(
        "class A extends A implements A {}",
        "class B extends C {}",
        "class C extends B {}"));
  }

  /**
   * This test checks the class declarations to make sure that elements are set for all identifiers.
   * This is useful to the editor and other consumers of the AST.
   */
  public void test_resolution_on_class_decls() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "Test.dart",
        Joiner.on("\n").join(
            "class A {}",
            "abstract class B<T> {}",
            "class C<T> extends A implements B<T> {}",
            "class D extends C<int> {}",
            "class E implements C<int> {}",
            "class F<T extends A> {}",
            "class G extends F<C<int>> {}"));
    assertErrors(libraryResult.getCompilationErrors());
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
    List<DartNode> nodes = unit.getTopLevelNodes();
    DartClass A = (DartClass) nodes.get(0);
    assertEquals("A", A.getClassName());
    DartClass B = (DartClass) nodes.get(1);
    assertEquals("B", B.getClassName());
    DartClass C = (DartClass) nodes.get(2);
    assertEquals("C", C.getClassName());
    DartClass D = (DartClass) nodes.get(3);
    assertEquals("D", D.getClassName());
    DartClass E = (DartClass) nodes.get(4);
    assertEquals("E", E.getClassName());
    DartClass F = (DartClass) nodes.get(5);
    assertEquals("F", F.getClassName());
    DartClass G = (DartClass) nodes.get(6);
    assertEquals("G", G.getClassName());

    // class A
    assertNotNull(A.getName().getElement());
    assertSame(A.getElement(), A.getName().getElement());

    // interface B<T> default C
    assertNotNull(B.getName().getElement());
    assertSame(B.getName().getElement(), B.getElement());
    assertEquals(1, B.getTypeParameters().size());
    DartTypeParameter T;
    T = B.getTypeParameters().get(0);
    assertNotNull(T);
    assertNotNull(T.getName().getElement());
    assertTrue(T.getName().getElement() instanceof TypeVariableElement);
    assertEquals("T", T.getName().getName());

    // class C<T> extends A implements B<T> {}
    assertNotNull(C.getName().getElement());
    assertSame(C.getElement(), C.getName().getElement());
    assertEquals(1, C.getTypeParameters().size());
    T = C.getTypeParameters().get(0);
    assertNotNull(T);
    assertNotNull(T.getName().getElement());
    assertTrue(T.getName().getElement() instanceof TypeVariableElement);
    assertEquals("T", T.getName().getName());
    assertSame(A.getElement(), C.getSuperclass().getIdentifier().getElement());
    assertEquals(1, C.getInterfaces().size());
    DartTypeNode iface = C.getInterfaces().get(0);
    assertNotNull(iface);
    assertSame(B.getElement(), iface.getIdentifier().getElement());
    assertSame(
        T.getName().getElement(),
        iface.getTypeArguments().get(0).getIdentifier().getElement());

    // class D extends C<int> {}
    assertNotNull(D.getName().getElement());
    assertSame(D.getElement(), D.getName().getElement());
    assertEquals(0, D.getTypeParameters().size());
    assertSame(C.getElement(), D.getSuperclass().getIdentifier().getElement());
    DartTypeNode typeArg;
    typeArg = D.getSuperclass().getTypeArguments().get(0);
    assertNotNull(typeArg.getIdentifier());
    assertEquals("int", typeArg.getIdentifier().getElement().getOriginalName());

    // class E implements C<int> {}
    assertNotNull(E.getName().getElement());
    assertSame(E.getElement(), E.getName().getElement());
    assertEquals(0, E.getTypeParameters().size());
    assertSame(C.getElement(), E.getInterfaces().get(0).getIdentifier().getElement());
    typeArg = E.getInterfaces().get(0).getTypeArguments().get(0);
    assertNotNull(typeArg.getIdentifier());
    assertEquals("int", typeArg.getIdentifier().getElement().getOriginalName());

    // class F<T extends A> {}",
    assertNotNull(F.getName().getElement());
    assertSame(F.getElement(), F.getName().getElement());
    assertEquals(1, F.getTypeParameters().size());
    T = F.getTypeParameters().get(0);
    assertNotNull(T);
    assertNotNull(T.getName().getElement());
    assertTrue(T.getName().getElement() instanceof TypeVariableElement);
    assertEquals("T", T.getName().getName());
    assertSame(A.getElement(), T.getBound().getIdentifier().getElement());

    // class G extends F<C<int>> {}
    assertNotNull(G.getName().getElement());
    assertSame(G.getElement(), G.getName().getElement());
    assertEquals(0, G.getTypeParameters().size());
    assertNotNull(G.getSuperclass());
    assertSame(F.getElement(), G.getSuperclass().getIdentifier().getElement());
    typeArg = G.getSuperclass().getTypeArguments().get(0);
    assertSame(C.getElement(), typeArg.getIdentifier().getElement());
    assertEquals(
        "int",
        typeArg.getTypeArguments().get(0).getIdentifier().getElement().getOriginalName());
  }

  /**
   * We should be able to resolve implicit default constructor.
   */
  public void test_resolveConstructor_implicit() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
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
    DartNewExpression newExpression = findNodeBySource(unit, "new F()");
    ConstructorElement constructorElement = newExpression.getElement();
    assertNotNull(constructorElement);
    assertEquals("", getElementSource(constructorElement));
  }

  public void test_resolveConstructor_noSuchConstructor() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
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
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.NEW_EXPRESSION_NOT_CONSTRUCTOR, 5, 11, 3));
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
    DartNewExpression newExpression = findNodeBySource(unit, "new A.foo()");
    ConstructorElement constructorElement = newExpression.getElement();
    assertNull(constructorElement);
  }

  public void test_resolveConstructor_super_implicitDefault() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "Test.dart",
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class A {",
            "}",
            "class B extends A {",
            "  B() : super() {}",
            "}",
            ""));
    assertErrors(libraryResult.getErrors());
  }

  public void test_superMethodInvocation_inConstructorInitializer() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "Test.dart",
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class A {",
            "  foo() {}",
            "}",
            "class B extends A {",
            "  var x;",
            "  B() : x = super.foo() {}",
            "}",
            ""));
    assertErrors(
        libraryResult.getErrors(),
        errEx(ResolverErrorCode.SUPER_METHOD_INVOCATION_IN_CONSTRUCTOR_INITIALIZER, 7, 13, 11));
  }

  private static String getElementSource(Element element) throws Exception {
    SourceInfo sourceInfo = element.getSourceInfo();
    // TODO(scheglov) When we will remove Source.getNode(), this null check may be removed
    Source source = sourceInfo.getSource();
    if (source == null) {
      return "";
    }
    Reader reader = sourceInfo.getSource().getSourceReader();
    try {
      String code = CharStreams.toString(reader);
      int offset = sourceInfo.getOffset();
      return code.substring(offset, offset + sourceInfo.getLength());
    } finally {
      reader.close();
    }
  }

  /**
   * Each name in {@link DartNode}, such as all names in {@link DartDeclaration}s should have same
   * {@link Element} as the {@link Element} of enclosing {@link DartNode}.
   */
  public void test_setElement_forName_inDeclarations() throws Exception {
    AnalyzeLibraryResult libraryResult = analyzeLibrary(
        "Test.dart",
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class A<B extends A> {",
            "  var a1;",
            "  get a2 {}",
            "  A() {}",
            "}",
            "var c;",
            "d(e) {",
            "  var f;",
            "  g() {};",
            "  () {} ();",
            "  h: d(0);",
            "}",
            "typedef i();",
            ""));
    assertErrors(libraryResult.getErrors());
    DartUnit unit = libraryResult.getLibraryUnitResult().getUnits().iterator().next();
    // in class A
    {
      DartClass classA = (DartClass) unit.getTopLevelNodes().get(0);
      assertDeclarationNameElement(classA, "A");
      {
        DartTypeParameter typeParameter = classA.getTypeParameters().get(0);
        assertDeclarationNameElement(typeParameter, "B");
      }
      {
        DartFieldDefinition fieldDef = (DartFieldDefinition) classA.getMembers().get(0);
        assertDeclarationNameElement(fieldDef.getFields().get(0), "a1");
      }
      {
        DartFieldDefinition fieldDef = (DartFieldDefinition) classA.getMembers().get(1);
        // since this is a getter, its actually a method element different from the original.
        DartField f = fieldDef.getFields().get(0);
        assertNotNull(f);
        Element e = f.getElement();
        assertNotNull(e);
        assertTrue(f.getName().getName().equals("a2"));
        assertTrue(e.getName().equals("a2"));
      }
      {
        DartMethodDefinition constructor = (DartMethodDefinition) classA.getMembers().get(2);
        assertDeclarationNameElement(constructor, "");
      }
    }
    // top level "c"
    {
      DartFieldDefinition fieldDef = (DartFieldDefinition) unit.getTopLevelNodes().get(1);
      assertDeclarationNameElement(fieldDef.getFields().get(0), "c");
    }
    // top level "d"
    {
      DartMethodDefinition method = (DartMethodDefinition) unit.getTopLevelNodes().get(2);
      assertDeclarationNameElement(method, "d");
      {
        DartParameter parameter = method.getFunction().getParameters().get(0);
        assertDeclarationNameElement(parameter, "e");
      }
      {
        List<DartStatement> statements = method.getFunction().getBody().getStatements();
        {
          DartVariableStatement variableStatement = (DartVariableStatement) statements.get(0);
          assertDeclarationNameElement(variableStatement.getVariables().get(0), "f");
        }
        {
          DartExprStmt statement = (DartExprStmt) statements.get(1);
          DartFunctionExpression functionExpression = (DartFunctionExpression) statement.getExpression();
          assertNameHasSameElement(functionExpression, functionExpression.getName(), "g");
        }
        {
          DartLabel label = (DartLabel) statements.get(4);
          assertNameHasSameElement(label, label.getLabel(), "h");
        }
      }
    }
    // top level "i"
    {
      DartFunctionTypeAlias functionType = (DartFunctionTypeAlias) unit.getTopLevelNodes().get(3);
      assertDeclarationNameElement(functionType, "i");
    }
    // assert that all DartIdentifiers are visited
    final LinkedList<String> visitedIdentifiers = Lists.newLinkedList();
    unit.accept(new ASTVisitor<Void>() {
      @Override
      public Void visitIdentifier(DartIdentifier node) {
        visitedIdentifiers.addLast(node.getName());
        return null;
      }
    });
    assertEquals("A", visitedIdentifiers.removeFirst());
    assertEquals("B", visitedIdentifiers.removeFirst());
    assertEquals("A", visitedIdentifiers.removeFirst());
    assertEquals("a1", visitedIdentifiers.removeFirst());
    assertEquals("a2", visitedIdentifiers.removeFirst());
    assertEquals("a2", visitedIdentifiers.removeFirst());
    assertEquals("A", visitedIdentifiers.removeFirst());
    assertEquals("c", visitedIdentifiers.removeFirst());
    assertEquals("d", visitedIdentifiers.removeFirst());
    assertEquals("e", visitedIdentifiers.removeFirst());
    assertEquals("f", visitedIdentifiers.removeFirst());
    assertEquals("g", visitedIdentifiers.removeFirst());
    assertEquals("h", visitedIdentifiers.removeFirst());
    assertEquals("d", visitedIdentifiers.removeFirst());
    assertEquals("i", visitedIdentifiers.removeFirst());
  }

  /**
   * Asserts that given nodes have same not <code>null</code> {@link Element}.
   */
  private static void assertDeclarationNameElement(
      DartDeclaration<? extends DartExpression> declaration,
      String name) {
    assertNameHasSameElement(declaration, declaration.getName(), name);
  }

  /**
   * Asserts that given nodes have same not <code>null</code> {@link Element}.
   */
  private static void assertNameHasSameElement(DartNode node, DartExpression nameNode, String name) {
    Element expectedElement = node.getElement();
    assertNotNull(expectedElement);
    assertEquals(name, expectedElement.getName());
    assertSame(expectedElement, nameNode.getElement());
  }
}
