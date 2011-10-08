// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.base.Joiner;
import com.google.common.collect.Lists;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilerErrorCode;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.parser.DartParser;
import com.google.dart.compiler.parser.DartScannerParserContext;
import com.google.dart.compiler.testing.TestCompilerContext;
import com.google.dart.compiler.testing.TestCompilerContext.EventKind;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.Types;
import com.google.dart.compiler.util.DartSourceString;

import junit.framework.Assert;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Basic tests of the resolver.
 */
public class ResolverTest extends ResolverTestCase {
  private final DartClass object = makeClass("Object", null);
  private final DartClass array = makeClass("Array", makeType("Object"), "E");
  private final DartClass growableArray = makeClass("GrowableArray", makeType("Array", "S"), "S");
  private final Types types = Types.getInstance(null);
  private List<DartCompilationError> encounteredErrors = Lists.newArrayList();

  @Override
  public void setUp() {
    encounteredErrors = Lists.newArrayList();
  }

  @Override
  public void tearDown() {
    encounteredErrors = null;
  }

  private ClassElement findElementOrFail(Scope libScope, String elementName) {
    Element element = libScope.findElement(elementName);
    assertEquals(ElementKind.CLASS, ElementKind.of(element));
    return (ClassElement) element;
  }

  private void assertHasSubtypes(ClassElement superElement, ClassElement...expectedSubtypes) {
    Set<InterfaceType> expectedInterfaceTypes = new LinkedHashSet<InterfaceType>();
    for (ClassElement expectedSubtype : expectedSubtypes) {
      expectedInterfaceTypes.add(expectedSubtype.getType());
    }

    Set<InterfaceType> actualSubtypes = superElement.getSubtypes();
    assertEquals(expectedInterfaceTypes, actualSubtypes);
  }

  public void testToString() {
    Assert.assertEquals("class Object {\n}", object.toString().trim());
    Assert.assertEquals("class Array<E> extends Object {\n}", array.toString().trim());
  }

  public void testResolve() {
    Scope libScope = resolve(makeUnit(object, array, growableArray), getContext());
    ClassElement objectElement = (ClassElement) libScope.findElement("Object");
    Assert.assertNotNull(objectElement);
    ClassElement arrayElement = (ClassElement) libScope.findElement("Array");
    Assert.assertNotNull(arrayElement);
    ClassElement growableArrayElement = (ClassElement) libScope.findElement("GrowableArray");
    Assert.assertNotNull(growableArrayElement);

    Type objectType = objectElement.getType();
    Type arrayType = arrayElement.getType();
    Type growableArrayType = growableArrayElement.getType();
    Assert.assertNotNull(objectType);
    Assert.assertNotNull(arrayType);
    Assert.assertNotNull(growableArrayType);

    Assert.assertTrue(types.isSubtype(arrayType, objectType));
    Assert.assertFalse(types.isSubtype(objectType, arrayType));

    Assert.assertTrue(types.isSubtype(growableArrayType, objectType));

    // GrowableArray<S> is not a subtype of Array<E> because S and E aren't
    // related.
    Assert.assertFalse(types.isSubtype(growableArrayType, arrayType));
    Assert.assertFalse(types.isSubtype(objectType, growableArrayType));
    Assert.assertFalse(types.isSubtype(arrayType, growableArrayType));
  }

  /**
   * class A {}
   * class B extends A {}
   * class C extends A {}
   * class E extends C {}
   * class D extends C {}
   */
  public void testGetSubtypes() {
    DartClass a = makeClass("A", makeType("Object"));
    DartClass b = makeClass("B", makeType("A"));
    DartClass c = makeClass("C", makeType("A"));
    DartClass e = makeClass("E", makeType("C"));
    DartClass d = makeClass("D", makeType("C"));

    Scope libScope = resolve(makeUnit(object, a, b, c, d, e), getContext());

    ClassElement elementA = findElementOrFail(libScope, "A");
    ClassElement elementB = findElementOrFail(libScope, "B");
    ClassElement elementC = findElementOrFail(libScope, "C");
    ClassElement elementD = findElementOrFail(libScope, "D");
    ClassElement elementE = findElementOrFail(libScope, "E");

    assertHasSubtypes(elementA, elementA, elementB, elementC, elementD, elementE);
    assertHasSubtypes(elementB, elementB);
    assertHasSubtypes(elementC, elementC, elementD, elementE);
    assertHasSubtypes(elementD, elementD);
    assertHasSubtypes(elementE, elementE);
  }

  /**
   * interface IA extends ID factory B {}
   * interface IB extends IA {}
   * interface IC extends IA, IB {}
   * interface ID extends IB {}
   * class A extends IA {}
   * class B {}
   */
  public void testGetSubtypesWithInterfaceCycles() {
    DartClass ia = makeInterface("IA", makeTypes("ID"), makeType("B"));
    DartClass ib = makeInterface("IB", makeTypes("IA"), null);
    DartClass ic = makeInterface("IC", makeTypes("IA", "IB"), null);
    DartClass id = makeInterface("ID", makeTypes("IB"), null);

    DartClass a = makeClass("A", null, makeTypes("IA"));
    DartClass b = makeClass("B", null);

    Scope libScope = resolve(makeUnit(object, ia, ib, ic, id, a, b), getContext());
    ErrorCode[] expected = {
        DartCompilerErrorCode.CYCLIC_CLASS,
        DartCompilerErrorCode.CYCLIC_CLASS,
        DartCompilerErrorCode.CYCLIC_CLASS,
        DartCompilerErrorCode.CYCLIC_CLASS,
        DartCompilerErrorCode.CYCLIC_CLASS,
    };
    checkExpectedErrors(expected);

    ClassElement elementIA = findElementOrFail(libScope, "IA");
    ClassElement elementIB = findElementOrFail(libScope, "IB");
    ClassElement elementIC = findElementOrFail(libScope, "IC");
    ClassElement elementID = findElementOrFail(libScope, "ID");
    ClassElement elementA = findElementOrFail(libScope, "A");
    ClassElement elementB = findElementOrFail(libScope, "B");

    assertHasSubtypes(elementIA, elementIA, elementIB, elementIC, elementID, elementA);
    assertHasSubtypes(elementIB, elementIA, elementIB, elementIC, elementID, elementA);
    assertHasSubtypes(elementIC, elementIC);
    assertHasSubtypes(elementID, elementIA, elementIB, elementIC, elementID, elementA);
    assertHasSubtypes(elementA, elementA);
    assertHasSubtypes(elementB, elementB);
  }

  /**
   * interface IA extends IB {}
   * interface IB extends IA {}
   */
  public void testGetSubtypesWithSimpleInterfaceCycle() {
    DartClass ia = makeInterface("IA", makeTypes("IB"), null);
    DartClass ib = makeInterface("IB", makeTypes("IA"), null);


    Scope libScope = resolve(makeUnit(object, ia, ib), getContext());
    ErrorCode[] expected = {
        DartCompilerErrorCode.CYCLIC_CLASS,
        DartCompilerErrorCode.CYCLIC_CLASS,
    };
    checkExpectedErrors(expected);

    ClassElement elementIA = findElementOrFail(libScope, "IA");
    ClassElement elementIB = findElementOrFail(libScope, "IB");
    assertHasSubtypes(elementIA, elementIA, elementIB);
    assertHasSubtypes(elementIB, elementIA, elementIB);
  }

  /**
   * class A<T> {}
   * class B extends A<C> {}
   * class C {}
   */
  public void testGetSubtypesWithParemeterizedSupertypes() {
    DartClass a = makeClass("A", null, "T");
    DartClass b = makeClass("B", makeType("A", "C"));
    DartClass c = makeClass("C", null);

    Scope libScope = resolve(makeUnit(object, a, b, c), getContext());

    ClassElement elementA = findElementOrFail(libScope, "A");
    ClassElement elementB = findElementOrFail(libScope, "B");
    ClassElement elementC = findElementOrFail(libScope, "C");

    assertHasSubtypes(elementA, elementA, elementB);
    assertHasSubtypes(elementC, elementC);
  }

  public void testDuplicatedInterfaces() {
    resolve(parseUnit(
        "class Object {}",
        "interface int {}",
        "interface bool {}",
        "interface I<X> {",
        "}",
        "class A extends C implements I<int> {",
        "}",
        "class B extends C implements I<bool> {",
        "}",
        "class C implements I<int> {",
        "}"), getContext());
    ErrorCode[] expected = { DartCompilerErrorCode.DUPLICATED_INTERFACE };
    checkExpectedErrors(expected);
  }

  public void testImplicitDefaultConstructor() {
    // Check that the implicit constructor is resolved correctly
    resolve(parseUnit(
        "class Object {}",
        "class B {}",
        "class C { main() { new B(); } }"), getContext());
    {
      ErrorCode[] expected = {};
      checkExpectedErrors(expected);
    }
    /*
     * We should check for signature mismatch but that is a TypeAnalyzer issue.
     */
  }

  public void testImplicitDefaultConstructor_ThroughFactories() {
    // Check that we generate implicit constructors through factories also.
    resolve(parseUnit(
        "class Object {}",
        "interface B factory C {}",
        "class C {}",
        "class D { main() { new B(); } }"), getContext());
    {
      ErrorCode[] expected = {};
      checkExpectedErrors(expected);
    }
  }

  public void testImplicitDefaultConstructor_WithConstCtor() {
    // Check that we generate an error if the implicit constructor would violate const.
    resolve(parseUnit(
        "class Object {}",
        "class B { const B() {} }",
        "class C extends B {}",
        "class D { main() { new C(); } }"), getContext());
    {
      ErrorCode[] expected = {
          DartCompilerErrorCode.CONST_CONSTRUCTOR_CANNOT_HAVE_BODY,
      };
      checkExpectedErrors(expected);
    }
  }

  public void testImplicitSuperCall_ImplicitCtor() {
    // Check that we can properly resolve the super ctor that exists.
    resolve(parseUnit(
        "class Object {}",
        "class B { B() {} }",
        "class C extends B {}",
        "class D { main() { new C(); } }"), getContext());
    {
      ErrorCode[] expected = {};
      checkExpectedErrors(expected);
    }
  }

  public void testImplicitSuperCall_OnExistingCtor() {
    // Check that we can properly resolve the super ctor that exists.
    resolve(parseUnit(
        "class Object {}",
        "class B { B() {} }",
        "class C extends B { C(){} }",
        "class D { main() { new C(); } }"), getContext());
    {
      ErrorCode[] expected = {};
      checkExpectedErrors(expected);
    }
  }

  public void testImplicitSuperCall_NonExistentSuper() {
    // Check that we generate an error if the implicit constructor would call a non-existent super.
    resolve(parseUnit(
        "class Object {}",
        "class B { B(Object o) {} }",
        "class C extends B {}",
        "class D { main() { new C(); } }"), getContext());
    {
      ErrorCode[] expected = {
          DartCompilerErrorCode.CANNOT_RESOLVE_IMPLICIT_CALL_TO_SUPER_CONSTRUCTOR
      };
      checkExpectedErrors(expected);
    }
  }

  public void testCyclicSupertype() {

    resolve(parseUnit(
        "class Object {}",
        "interface int {}",
        "interface bool {}",
        "class Cyclic extends Cyclic {",
        "}",
        "class A extends B {",
        "}",
        "class B extends A {",
        "}",
        "interface I extends I {",
        "}",
        "class C implements I1, I {",
        "}",
        "interface I1 {",
        "}",
        "class D implements I1, I2 {",
        "}",
        "interface I2 extends I3 {",
        "}",
        "interface I3 extends I2 {",
        "}"), getContext());
    ErrorCode[] expected = {
        DartCompilerErrorCode.CYCLIC_CLASS,
        DartCompilerErrorCode.CYCLIC_CLASS,
        DartCompilerErrorCode.CYCLIC_CLASS,
        DartCompilerErrorCode.CYCLIC_CLASS,
        DartCompilerErrorCode.CYCLIC_CLASS,
        DartCompilerErrorCode.CYCLIC_CLASS,
        DartCompilerErrorCode.CYCLIC_CLASS,
        DartCompilerErrorCode.CYCLIC_CLASS,
    };
    checkExpectedErrors(expected);

  }

  public void testBadFactory() {
    encounteredErrors = Lists.newArrayList();

    TestCompilerContext context1 =  new TestCompilerContext(EventKind.TYPE_ERROR) {
      @Override
      public void compilationError(DartCompilationError event) {
        encounteredErrors.add(event);
      }
      @Override
      public boolean shouldWarnOnNoSuchType() {
        return false;
      }
    };
    resolve(parseUnit("class Object {}",
                      "class Zebra {",
                      "  factory foo() {}",
                      "}"), context1);
    {
      ErrorCode[] expected = {
          DartCompilerErrorCode.NO_SUCH_TYPE
      };
      checkExpectedErrors(expected);
    }

    encounteredErrors = Lists.newArrayList();
    TestCompilerContext context2 =  new TestCompilerContext(EventKind.TYPE_ERROR) {
      @Override
      public void compilationError(DartCompilationError event) {
        encounteredErrors.add(event);
      }
      @Override
      public boolean shouldWarnOnNoSuchType() {
        return true;
      }
    };
    resolve(parseUnit("class Object {}",
                      "class Zebra {",
                      "  factory foo() {}",
                      "}"), context2);
    {
      ErrorCode[] expected = {
      };
      checkExpectedErrors(expected);
    }
  }

  /**
   * Test that a class may implement the implied interface of another class and that interfaces may
   * extend the implied interface of a class.
   *
   * @throws DuplicatedInterfaceException
   * @throws CyclicDeclarationException
   */
  public void testImpliedInterfaces() throws CyclicDeclarationException,
      DuplicatedInterfaceException {
    DartClass a = makeClass("A", null);
    DartClass b = makeClass("B", null, makeTypes("A"));
    DartClass ia = makeInterface("IA", makeTypes("B"), null);
    Scope libScope = resolve(makeUnit(object, a, b, ia), getContext());
    ErrorCode[] expected = {};
    checkExpectedErrors(expected);

    ClassElement elementA = findElementOrFail(libScope, "A");
    ClassElement elementB = findElementOrFail(libScope, "B");
    ClassElement elementIA = findElementOrFail(libScope, "IA");
    List<InterfaceType> superTypes = elementB.getAllSupertypes();
    assertEquals(2, superTypes.size()); // Object and A
    superTypes = elementIA.getAllSupertypes();
    assertEquals(3, superTypes.size()); // Object, A, and B
    assertHasSubtypes(elementA, elementA, elementB, elementIA);
  }

  public void testUnresolvedSuper() {
    resolve(parseUnit(
        "class Object {}",
        "class Foo {",
        "  foo() { super.foo(); }",
        "}"), getContext());
    ErrorCode[] expected = {};
    checkExpectedErrors(expected);
  }

  public void testNameConflict() {
    resolve(parseUnit("class Object {}",
                      "class A {",
                      "  var foo;",
                      "  var foo;",
                      "}"),
                      getContext());
    ErrorCode[] expected1 = {
        DartCompilerErrorCode.NAME_CLASHES_EXISTING_MEMBER
    };
    checkExpectedErrors(expected1);

    encounteredErrors = Lists.newArrayList();
    resolve(parseUnit("class Object {}",
                      "class A {",
                      "  foo() {}",
                      "  set foo(x) {}",
                      "}"),
                      getContext());
    {
      ErrorCode[] expected = {
          DartCompilerErrorCode.NAME_CLASHES_EXISTING_MEMBER
      };
      checkExpectedErrors(expected);
    }

    // Same test, but reverse the order of setter and method
    encounteredErrors = Lists.newArrayList();
    resolve(parseUnit("class Object {}",
                      "class A {",
                      "  set foo(x) {}",
                      "  foo() {}",
                      "}"),
                      getContext());
    {
      ErrorCode[] expected = {
          DartCompilerErrorCode.NAME_CLASHES_EXISTING_MEMBER
      };
      checkExpectedErrors(expected);
    }

    encounteredErrors = Lists.newArrayList();
    resolve(parseUnit("class Object {}",
                      "class A {",
                      "  var foo;",
                      "  set foo(x) {}",
                      "}"),
                      getContext());
    {
      ErrorCode[] expected = {
          DartCompilerErrorCode.NAME_CLASHES_EXISTING_MEMBER
      };
      checkExpectedErrors(expected);
    }

    encounteredErrors = Lists.newArrayList();
    resolve(parseUnit("class Object {}",
                      "class A {",
                      "  get foo() {}",
                      "  var foo;",
                      "}"),
                      getContext());
    {
      ErrorCode[] expected = {
          DartCompilerErrorCode.NAME_CLASHES_EXISTING_MEMBER
      };
      checkExpectedErrors(expected);
    }

    encounteredErrors = Lists.newArrayList();
    resolve(parseUnit("class Object {}",
                      "class A {",
                      "  var foo;",
                      "  get foo() {}",
                      "}"),
                      getContext());
    {
      ErrorCode[] expected = {
          DartCompilerErrorCode.NAME_CLASHES_EXISTING_MEMBER
      };
      checkExpectedErrors(expected);
    }

    encounteredErrors = Lists.newArrayList();
    resolve(parseUnit("class Object {}",
                      "class A {",
                      "  set foo(x) {}",
                      "  var foo;",
                      "}"),
                      getContext());
    {
      ErrorCode[] expected = {
          DartCompilerErrorCode.NAME_CLASHES_EXISTING_MEMBER
      };
      checkExpectedErrors(expected);
    }

    encounteredErrors = Lists.newArrayList();
    resolve(parseUnit("class Object {}",
                      "get foo() {}",
                      "class foo {}",
                      "set bar(x) {}",
                      "class bar {}"),
                      getContext());
    {
      ErrorCode[] expected = {
          DartCompilerErrorCode.DUPLICATE_DEFINITION,
          DartCompilerErrorCode.DUPLICATE_DEFINITION,
          DartCompilerErrorCode.DUPLICATE_DEFINITION,
          DartCompilerErrorCode.DUPLICATE_DEFINITION,
      };
      checkExpectedErrors(expected);
    }

    // Same test but in different order
    encounteredErrors = Lists.newArrayList();
    resolve(parseUnit("class Object {}",
                      "class foo {}",
                      "get foo() {}",
                      "class bar {}",
                      "set bar(x) {}"),
                      getContext());
    {
      ErrorCode[] expected = {
          DartCompilerErrorCode.DUPLICATE_DEFINITION,
          DartCompilerErrorCode.DUPLICATE_DEFINITION,
          DartCompilerErrorCode.DUPLICATE_DEFINITION,
          DartCompilerErrorCode.DUPLICATE_DEFINITION,
      };
      checkExpectedErrors(expected);
    }


    encounteredErrors = Lists.newArrayList();
    resolve(parseUnit("class Object {}",
                      "set bar(x) {}",
                      "set bar(x) {}"),
                      getContext());
    {
      ErrorCode[] expected = {
          DartCompilerErrorCode.DUPLICATE_DEFINITION,
          DartCompilerErrorCode.DUPLICATE_DEFINITION,
          DartCompilerErrorCode.FIELD_CONFLICTS,
      };
      checkExpectedErrors(expected);
    }

    encounteredErrors = Lists.newArrayList();
    resolve(parseUnit("class Object {}",
                      "get bar() {}",
                      "get bar() {}"),
                      getContext());
    {
      ErrorCode[] expected = {
        DartCompilerErrorCode.DUPLICATE_DEFINITION,
        DartCompilerErrorCode.DUPLICATE_DEFINITION,
        DartCompilerErrorCode.FIELD_CONFLICTS,
      };
      checkExpectedErrors(expected);
    }
  }

  private static DartUnit makeUnit(DartNode... topLevelElements) {
    DartUnit unit = new DartUnit(null);
    for (DartNode topLevelElement : topLevelElements) {
      unit.addTopLevelNode(topLevelElement);
    }
    return unit;
  }

  private static DartTypeNode makeType(String name, String... arguments) {
    List<DartTypeNode> argumentNodes = makeTypes(arguments);
    return new DartTypeNode(new DartIdentifier(name), argumentNodes);
  }

  static List<DartTypeNode> makeTypes(String... typeNames) {
    List<DartTypeNode> types = new ArrayList<DartTypeNode>();
    for (String typeName : typeNames) {
      types.add(makeType(typeName));
    }
    return types;
  }

  private DartUnit parseUnit(String firstLine, String secondLine, String... rest) {
    return parseUnit(Joiner.on('\n').join(firstLine, secondLine, (Object[]) rest).toString());
  }

  private DartUnit parseUnit(String string) {
    DartSourceString source = new DartSourceString("<source string>", string);
    return getParser(string).parseUnit(source);
  }

  private DartParser getParser(String string) {
    return new DartParser(new DartScannerParserContext(null, string, getListener()));
  }

  private DartCompilerListener getListener() {
    return new DartCompilerListener() {
      @Override
      public void compilationError(DartCompilationError event) {
        encounteredErrors.add(event);
      }

      @Override
      public void compilationWarning(DartCompilationError event) {
        compilationError(event);
      }

      @Override
      public void typeError(DartCompilationError event) {
        compilationError(event);
      }
    };
  }

  private TestCompilerContext getContext() {
    return new TestCompilerContext() {
      @Override
      public void compilationError(DartCompilationError event) {
        encounteredErrors.add(event);
      }
    };
  }

  private boolean checkExpectedErrors(ErrorCode[] errorCodes) {
    if (errorCodes.length != encounteredErrors.size()) {
      printEncountered();
      assertEquals(errorCodes.length, encounteredErrors.size());
    }
    int index = 0;
    for (ErrorCode errorCode : errorCodes) {
      ErrorCode found = encounteredErrors.get(index).getErrorCode();
      if (!found.equals(errorCode)) {
        printEncountered();
        assertEquals("Unexpected Error Code: ", errorCode, found);
      }
      index++;
    }
    return true;
  }

  /**
   * For debugging.
   */
  private void printEncountered() {
    for (DartCompilationError error : encounteredErrors) {
      DartCompilerErrorCode errorCode = (DartCompilerErrorCode) error
          .getErrorCode();
      String msg = String.format("%s > %s (%d:%d)", errorCode.name(), error
          .getMessage(), error.getLineNumber(), error.getColumnNumber());
      System.out.println(msg);
    }
  }
}
