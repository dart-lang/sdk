// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.base.Joiner;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.ErrorSeverity;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.testing.TestCompilerContext;
import com.google.dart.compiler.testing.TestCompilerContext.EventKind;
import com.google.dart.compiler.type.DynamicType;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.Types;

import junit.framework.Assert;

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


  private ClassElement findElementOrFail(Scope libScope, String elementName) {
    Element element = libScope.findElement(libScope.getLibrary(), elementName);
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
    LibraryElement library = libScope.getLibrary();
    ClassElement objectElement = (ClassElement) libScope.findElement(library, "Object");
    Assert.assertNotNull(objectElement);
    ClassElement arrayElement = (ClassElement) libScope.findElement(library, "Array");
    Assert.assertNotNull(arrayElement);
    ClassElement growableArrayElement = (ClassElement) libScope.findElement(library,
                                                                            "GrowableArray");
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
        ResolverErrorCode.CYCLIC_CLASS,
        ResolverErrorCode.CYCLIC_CLASS,
        ResolverErrorCode.CYCLIC_CLASS,
        ResolverErrorCode.CYCLIC_CLASS,
        ResolverErrorCode.CYCLIC_CLASS,
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
        ResolverErrorCode.CYCLIC_CLASS,
        ResolverErrorCode.CYCLIC_CLASS,
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
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "interface int {}",
        "interface bool {}",
        "interface I<X> {",
        "}",
        "class A extends C implements I<int> {}",
        "class B extends C implements I<bool> {}",
        "class C implements I<int> {}"),
        ResolverErrorCode.DUPLICATED_INTERFACE);
  }

  public void testImplicitDefaultConstructor() {
    // Check that the implicit constructor is resolved correctly
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class B {}",
        "class C { main() { new B(); } }"));

    /*
     * We should check for signature mismatch but that is a TypeAnalyzer issue.
     */
  }

  public void testImplicitDefaultConstructor_ThroughFactories() {
    // Check that we generate implicit constructors through factories also.
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "interface B factory C {}",
        "class C {}",
        "class D { main() { new B(); } }"));
  }

  public void testImplicitDefaultConstructor_WithConstCtor() {
    // Check that we generate an error if the implicit constructor would violate const.
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class B { const B() {} }",
        "class C extends B {}",
        "class D { main() { new C(); } }"),
          ResolverErrorCode.CONST_CONSTRUCTOR_CANNOT_HAVE_BODY);
  }

  public void testImplicitSuperCall_ImplicitCtor() {
    // Check that we can properly resolve the super ctor that exists.
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class B { B() {} }",
        "class C extends B {}",
        "class D { main() { new C(); } }"));
  }

  public void testImplicitSuperCall_OnExistingCtor() {
    // Check that we can properly resolve the super ctor that exists.
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class B { B() {} }",
        "class C extends B { C(){} }",
        "class D { main() { new C(); } }"));
  }

  public void testImplicitSuperCall_NonExistentSuper() {
    // Check that we generate an error if the implicit constructor would call a non-existent super.
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class B { B(Object o) {} }",
        "class C extends B {}",
        "class D { main() { new C(); } }"),
        ResolverErrorCode.CANNOT_RESOLVE_IMPLICIT_CALL_TO_SUPER_CONSTRUCTOR);
  }

  public void testCyclicSupertype() {

    resolveAndTest(Joiner.on("\n").join(
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
        "}"),
        ResolverErrorCode.CYCLIC_CLASS,
        ResolverErrorCode.CYCLIC_CLASS,
        ResolverErrorCode.CYCLIC_CLASS,
        ResolverErrorCode.CYCLIC_CLASS,
        ResolverErrorCode.CYCLIC_CLASS,
        ResolverErrorCode.CYCLIC_CLASS,
        ResolverErrorCode.CYCLIC_CLASS,
        ResolverErrorCode.CYCLIC_CLASS
    );


  }

  public void testBadFactory() {

    TestCompilerContext context1 =  new TestCompilerContext(EventKind.TYPE_ERROR) {
      @Override
      public void onError(DartCompilationError event) {
        recordError(event);
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
          ResolverErrorCode.NO_SUCH_TYPE
      };
      checkExpectedErrors(expected);
    }

    resetExpectedErrors();
    TestCompilerContext context2 =  new TestCompilerContext(EventKind.TYPE_ERROR) {
      @Override
      public void onError(DartCompilationError event) {
        if (event.getErrorCode().getErrorSeverity() == ErrorSeverity.ERROR) {
          recordError(event);
        }
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
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class Foo {",
        "  foo() { super.foo(); }",
        "}"));
  }

  public void testNameConflict() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  var foo;",
        "  var foo;",
        "}"),
        ResolverErrorCode.NAME_CLASHES_EXISTING_MEMBER);

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  foo() {}",
        "  set foo(x) {}",
        "}"),
        ResolverErrorCode.NAME_CLASHES_EXISTING_MEMBER);

    // Same test, but reverse the order of setter and method
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  set foo(x) {}",
        "  foo() {}",
        "}"),
        ResolverErrorCode.NAME_CLASHES_EXISTING_MEMBER);

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  var foo;",
        "  set foo(x) {}",
        "}"),
        ResolverErrorCode.NAME_CLASHES_EXISTING_MEMBER);

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  get foo() {}",
        "  var foo;",
        "}"),
        ResolverErrorCode.NAME_CLASHES_EXISTING_MEMBER);


    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  var foo;",
        "  get foo() {}",
        "}"),
        ResolverErrorCode.NAME_CLASHES_EXISTING_MEMBER);

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  set foo(x) {}",
        "  var foo;",
        "}"),
        ResolverErrorCode.NAME_CLASHES_EXISTING_MEMBER);

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "get foo() {}",
        "class foo {}",
        "set bar(x) {}",
        "class bar {}"),
        ResolverErrorCode.DUPLICATE_DEFINITION,
        ResolverErrorCode.DUPLICATE_DEFINITION,
        ResolverErrorCode.DUPLICATE_DEFINITION,
        ResolverErrorCode.DUPLICATE_DEFINITION);

    // Same test but in different order
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class foo {}",
        "get foo() {}",
        "class bar {}",
        "set bar(x) {}"),
        ResolverErrorCode.DUPLICATE_DEFINITION,
        ResolverErrorCode.DUPLICATE_DEFINITION,
        ResolverErrorCode.DUPLICATE_DEFINITION,
        ResolverErrorCode.DUPLICATE_DEFINITION);


    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "set bar(x) {}",
        "set bar(x) {}"),
        ResolverErrorCode.DUPLICATE_DEFINITION,
        ResolverErrorCode.DUPLICATE_DEFINITION,
        ResolverErrorCode.FIELD_CONFLICTS);

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "get bar() {}",
        "get bar() {}"),
        ResolverErrorCode.DUPLICATE_DEFINITION,
        ResolverErrorCode.DUPLICATE_DEFINITION,
        ResolverErrorCode.FIELD_CONFLICTS);
  }

  /**
   * Tests for the 'new' keyword
   */
  public void testNewExpression() {
    // A very ordinary new expression is OK
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class Foo {",
        "  Foo create() {",
        "    return new Foo();",
        "  }",
        "}"));

    // A  new expression with generic type argument is OK
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class Foo<T> {",
        "  Foo<T> create() {",
        "    return new Foo<T>();",
        "  }",
        "}"));

    // Trying new on a variable name shouldn't work.
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class Foo {",
        "  var Bar;",
        "  create() { return new Bar();}",
        "}"),
        ResolverErrorCode.NO_SUCH_TYPE,
        ResolverErrorCode.NEW_EXPRESSION_NOT_CONSTRUCTOR);

    // New expression tied to an unbound type variable is not allowed.
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class Foo<T> {",
        "  T create() {",
        "    return new T();",
        "  }",
        "}"),
        ResolverErrorCode.NEW_EXPRESSION_CANT_USE_TYPE_VAR);


    // More cowbell. (Foo<T> isn't a type yet)
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class Foo<T> { }",
        "class B {",
        "  foo() { return new Foo<T>(); }",
        "}"),
        ResolverErrorCode.NO_SUCH_TYPE);
  }

  /**
   * When {@link SupertypeResolver} can not find "UnknownA", it uses {@link DynamicType}, which
   * returns {@link DynamicElement}. By itself, this is OK. However when we later try to resolve
   * second unknown type "UnknownB", we expect in {@link Elements#findElement()} specific
   * {@link ClassElement} implementation and {@link DynamicElement} is not valid.
   */
  public void test_classDynamicElement_fieldDynamicElement() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class MyClass implements UnknownA {",
        "  UnknownB field;",
        "}"),
        ResolverErrorCode.NO_SUCH_TYPE,
        ResolverErrorCode.NOT_A_CLASS_OR_INTERFACE,
        ResolverErrorCode.NO_SUCH_TYPE);
  }
}
