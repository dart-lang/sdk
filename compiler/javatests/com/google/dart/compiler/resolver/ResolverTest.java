// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.base.Joiner;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.common.ErrorExpectation;
import com.google.dart.compiler.type.DynamicType;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.Types;

import static com.google.dart.compiler.common.ErrorExpectation.errEx;

import junit.framework.Assert;

import java.util.List;

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
  @SuppressWarnings("unused")
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
  }

  /**
   * interface IA extends ID default B {}
   * interface IB extends IA {}
   * interface IC extends IA, IB {}
   * interface ID extends IB {}
   * class A extends IA {}
   * class B {}
   */
  @SuppressWarnings("unused")
  public void testGetSubtypesWithInterfaceCycles() {
    DartClass ia = makeInterface("IA", makeTypes("ID"), makeDefault("B"));
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

    assert(elementIA.getDefaultClass().getElement().getName().equals("B"));
  }

  /**
   * interface IA extends IB {}
   * interface IB extends IA {}
   */
  @SuppressWarnings("unused")
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
  }

  /**
   * class A<T> {}
   * class B extends A<C> {}
   * class C {}
   */
  @SuppressWarnings("unused")
  public void testGetSubtypesWithParemeterizedSupertypes() {
    DartClass a = makeClass("A", null, "T");
    DartClass b = makeClass("B", makeType("A", "C"));
    DartClass c = makeClass("C", null);

    Scope libScope = resolve(makeUnit(object, a, b, c), getContext());

    ClassElement elementA = findElementOrFail(libScope, "A");
    ClassElement elementB = findElementOrFail(libScope, "B");
    ClassElement elementC = findElementOrFail(libScope, "C");

  }

  public void testDuplicatedInterfaces() {
    // The analyzer used to catch inheriting from two different variations of the same interface
    // but the spec mentions no such error
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "class bool {}",
        "abstract class I<X> {",
        "}",
        "class A extends C implements I<int> {}",
        "class B extends C implements I<bool> {}",
        "class C implements I<int> {}"));
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

  public void testImplicitSuperCall_NonExistentSuper2() {
    // Check that we generate an error if the implicit constructor would call a non-existent super.
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class B { B.foo() {} }",
        "class C extends B {}",
        "class D { main() { new C(); } }"),
        ResolverErrorCode.CANNOT_RESOLVE_IMPLICIT_CALL_TO_SUPER_CONSTRUCTOR);
  }

  public void testCyclicSupertype() {

    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "class bool {}",
        "class Cyclic extends Cyclic {",
        "}",
        "class A extends B {",
        "}",
        "class B extends A {",
        "}",
        "class C implements C {",
        "}"),
        ResolverErrorCode.CYCLIC_CLASS,
        ResolverErrorCode.CYCLIC_CLASS,
        ResolverErrorCode.CYCLIC_CLASS,
        ResolverErrorCode.CYCLIC_CLASS
    );
  }

  public void testBadFactory() {
    // Another interface should be in scope to name 'foo' as a constructor
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class Zebra {",
        "  factory foo() {}",
        "}"),
        ResolverErrorCode.NO_SUCH_TYPE_CONSTRUCTOR);
  }

  public void test_constFactory() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  const factory A() { }",
        "}"),
        errEx(ResolverErrorCode.FACTORY_CANNOT_BE_CONST, 3, 17, 1));
  }

  public void testBadGenerativeConstructor1() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object { }",
        "class B { }",
        "class A {",
        "  var val; ",
        "  B.foo() : this.val = 1;",
        "}"),
        ResolverErrorCode.CANNOT_DECLARE_NON_FACTORY_CONSTRUCTOR);
  }

  public void testBadGenerativeConstructor2() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object { }",
        "class A {",
        "  var val; ",
        "  A.foo.bar() : this.val = 1;",
        "}"),
        ResolverErrorCode.TOO_MANY_QUALIFIERS_FOR_METHOD);
  }

  public void testGenerativeConstructor() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  var val; ",
        "  A.foo(arg) : this.val = arg;",
        "}"));
  }

  /**
   * Test that a class may implement the implied interface of another class and that interfaces may
   * extend the implied interface of a class.
   */
  @SuppressWarnings("unused")
  public void testImpliedInterfaces() throws Exception {
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
  }

  public void testUnresolvedSuper() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class Foo {",
        "  foo() { super.foo(); }",
        "}"));
  }

  /**
   * Tests for the 'new' keyword
   */
  public void testNewExpression1() {
    // A very ordinary new expression is OK
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class Foo {",
        "  Foo create() {",
        "    return new Foo();",
        "  }",
        "}"));
  }

  public void testNewExpression2() {
    // A  new expression with generic type argument is OK
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class Foo<T> {",
        "  Foo<T> create() {",
        "    return new Foo<T>();",
        "  }",
        "}"));
  }

  public void testNewExpression3() {
    // Trying new on a variable name shouldn't work.
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class Foo {",
        "  var Bar;",
        "  create() { return new Bar();}",
        "}"),
        TypeErrorCode.NOT_A_TYPE);
  }

  public void testNewExpression4() {
    // New expression tied to an unbound type variable is not allowed.
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class Foo<T> {",
        "  T create() {",
        "    return new T();",
        "  }",
        "}"),
        ResolverErrorCode.NEW_EXPRESSION_CANT_USE_TYPE_VAR);
  }

  public void testNewExpression5() {
    // More cowbell. (Foo<T> isn't a type yet)
    resolveAndTest(Joiner.on("\n").join(
      "class Object {}",
      "class Foo<T> { }",
      "class B {",
      "  foo() { return new Foo<T>(); }",
      "}"),
      TypeErrorCode.NO_SUCH_TYPE);
  }

  public void test_noSuchType_field() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class MyClass {",
        "  Unknown field;",
        "}"),
        TypeErrorCode.NO_SUCH_TYPE);
  }

  public void test_variableStatement_noSuchType() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class MyClass {",
        "  foo() {",
        "    Unknown bar;",
        "  }",
        "}"),
        TypeErrorCode.NO_SUCH_TYPE);
  }

  public void test_variableStatement_noSuchType_typeArgument() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class Foo<T> {}",
        "class MyClass {",
        "  bar() {",
        "    Foo<Unknown> foo;",
        "  }",
        "}"),
        TypeErrorCode.NO_SUCH_TYPE);
  }

  public void test_variableStatement_wrongTypeArgumentsNumber() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class Foo<T> {}",
        "class MyClass {",
        "  bar() {",
        "    Foo<Object, Object> foo;",
        "  }",
        "}"),
        TypeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS);
  }

  public void test_variableStatement_typeArgumentsForNonGeneric() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class Foo {}",
        "class MyClass {",
        "  bar() {",
        "    Foo<Object> foo;",
        "  }",
        "}"),
        TypeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS);
  }

  public void test_noSuchType_classExtends() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class MyClass extends Unknown {",
        "}"),
        ResolverErrorCode.NO_SUCH_TYPE);
  }

  public void test_noSuchType_classExtendsTypeVariable() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class MyClass<E> extends E {",
        "}"),
        ResolverErrorCode.NOT_A_CLASS);
  }

  public void test_noSuchType_superClass_typeArgument() throws Exception {
    String source =
        Joiner.on("\n").join(
            "class Object {}",
            "class Base<T> {}",
            "class MyClass extends Base<Unknown> {",
            "}");
    List<DartCompilationError> errors = resolveAndTest(source, ResolverErrorCode.NO_SUCH_TYPE);
    assertEquals(1, errors.size());
    {
      DartCompilationError error = errors.get(0);
      assertEquals(3, error.getLineNumber());
      assertEquals(28, error.getColumnNumber());
      assertEquals("Unknown".length(), error.getLength());
      assertEquals(source.indexOf("Unknown"), error.getStartPosition());
    }
  }

  public void test_noSuchType_superInterface_typeArgument() throws Exception {
    String source =
        Joiner.on("\n").join(
            "class Object {}",
            "abstract class Base<T> {}",
            "class MyClass implements Base<Unknown> {",
            "}");
    List<DartCompilationError> errors = resolveAndTest(source, ResolverErrorCode.NO_SUCH_TYPE);
    assertEquals(1, errors.size());
    {
      DartCompilationError error = errors.get(0);
      assertEquals(3, error.getLineNumber());
      assertEquals(31, error.getColumnNumber());
      assertEquals("Unknown".length(), error.getLength());
      assertEquals(source.indexOf("Unknown"), error.getStartPosition());
    }
  }

  public void test_noSuchType_methodParameterType() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class MyClass {",
        "  Object foo(Unknown p) {",
        "    return null;",
        "  }",
        "}"),
        TypeErrorCode.NO_SUCH_TYPE);
  }

  public void test_noSuchType_methodParameterType_noQualifier() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class MyClass {",
        "  Object foo(lib.Unknown p) {",
        "    return null;",
        "  }",
        "}"),
        TypeErrorCode.NO_SUCH_TYPE);
  }

  public void test_noSuchType_returnType() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class MyClass {",
        "  Unknown foo() {",
        "    return null;",
        "  }",
        "}"),
        TypeErrorCode.NO_SUCH_TYPE);
  }

  public void test_noSuchType_inExpression() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class MyClass {",
        "  foo() {",
        "    var bar;",
        "    if (bar is Bar) {",
        "    }",
        "  }",
        "}"),
        TypeErrorCode.NO_SUCH_TYPE);
  }

  public void test_noSuchType_inCatch() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class MyClass {",
        "  foo() {",
        "    try {",
        "    } on Unknown catch (e) {",
        "    }",
        "  }",
        "}"),
        ResolverErrorCode.NO_SUCH_TYPE);
  }

  public void test_const_array() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "class MyClass<E> {",
        "  var a1 = <int>[];",
        "  var a2 = <E>[];",
        "  var a3 = const <int>[];",
        "  var a4 = const <E>[];",
        "}"),
        ErrorExpectation.errEx(ResolverErrorCode.CONST_ARRAY_WITH_TYPE_VARIABLE, 7, 19, 1));
  }

  public void test_const_map() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class String {}",
        "class int {}",
        "class MyClass<E> {",
        "  var a1 = <int>{};",
        "  var a2 = <E>{};",
        "  var a3 = const <int>{};",
        "  var a4 = const <E>{};",
        "}"),
        ErrorExpectation.errEx(ResolverErrorCode.CONST_MAP_WITH_TYPE_VARIABLE, 8, 19, 1));
  }

  public void test_multipleLabels() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class MyClass<E> {",
        "  foo() {",
        "    a: b: while (true) { break a; } // ok",
        "    a: b: while (true) { break b; } // ok",
        "    a: b: while (true) { break c; } // error, no such label",
        "  }",
        "}"),
        ErrorExpectation.errEx(ResolverErrorCode.CANNOT_RESOLVE_LABEL, 6, 32, 1));
  }

  public void test_multipleLabelsSwitch() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "foo() {",
        "  switch(1) {",
        "  a: case (0): break;",
        "  a: case (1): break;",
        "  }",
        "}"),
        ErrorExpectation.errEx(ResolverErrorCode.DUPLICATE_LABEL_IN_SWITCH_STATEMENT, 5, 3, 2));
  }

  public void test_breakInSwitch() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "foo() {",
        "  switch(1) {",
        "    a: case 0:",
        "       break a;",
        "  }",
        "}"),
        ErrorExpectation.errEx(ResolverErrorCode.BREAK_LABEL_RESOLVES_TO_CASE_OR_DEFAULT, 5, 14, 1));
  }

  public void test_continueInSwitch1() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "foo() {",
        "  switch(1) {",
        "    a: case 0:",
        "       continue a;",
        "  }",
        "}"));
  }

  public void test_continueInSwitch2() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "foo() {",
        "  switch(1) {",
        "    case 0:",
        "       continue a;",
        "    a: case 1:",
        "      break;",
        "  }",
        "}"));
  }

  public void test_continueInSwitch3() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "foo() {",
        "  a: switch(1) {",
        "    case 0:",
        "       continue a;",
        "  }",
        "}"),
        ErrorExpectation.errEx(ResolverErrorCode.CONTINUE_LABEL_RESOLVES_TO_SWITCH, 5, 17, 1));
  }

  public void test_new_noSuchType() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class MyClass {",
        "  foo() {",
        "    new Unknown();",
        "  }",
        "}"),
        TypeErrorCode.NO_SUCH_TYPE);
  }

  public void test_new_noSuchType_typeArgument() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class Foo<T> {}",
        "class MyClass {",
        "  foo() {",
        "    new Foo<T>();",
        "  }",
        "}"),
        TypeErrorCode.NO_SUCH_TYPE);
  }

  public void test_new_wrongTypeArgumentsNumber() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class Foo<T> {}",
        "class MyClass {",
        "  foo() {",
        "    new Foo<Object, Object>();",
        "  }",
        "}"),
        ResolverErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS);
  }

  public void test_noSuchType_mapLiteral_typeArgument() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class String {}",
        "class MyClass {",
        "  foo() {",
        "    var map = <T>{};",
        "  }",
        "}"),
        ResolverErrorCode.NO_SUCH_TYPE);
  }

  public void test_noSuchType_mapLiteral_num_type_args() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "class String {}",
        "class MyClass {",
        "  foo() {",
        "    var map0 = {};",
        "    var map1 = <int>{'foo': 1};",
        "    var map2 = <String, int>{'foo' : 1};",
        "    var map3 = <String, int, int>{'foo' : 1};",
        "  }",
        "}"),
//        ResolverErrorCode.DEPRECATED_MAP_LITERAL_SYNTAX,
        ResolverErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS);
  }

  public void test_noSuchType_arrayLiteral_typeArgument() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class MyClass {",
        "  foo() {",
        "    var map = <T>[null];",
        "  }",
        "}"),
        ResolverErrorCode.NO_SUCH_TYPE);
  }

  /**
   * When {@link SupertypeResolver} can not find "UnknownA", it uses {@link DynamicType}, which
   * returns {@link DynamicElement}. By itself, this is OK. However when we later try to resolve
   * second unknown type "UnknownB", we expect in {@link Elements#findElement()} specific
   * {@link ClassElement} implementation and {@link DynamicElement} is not valid.
   */
  public void test_classExtendsUnknown_fieldUnknownType() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class MyClass extends UnknownA {",
        "  UnknownB field;",
        "}"),
        ResolverErrorCode.NO_SUCH_TYPE,
        TypeErrorCode.NO_SUCH_TYPE);
  }

  public void test_cascadeWithTypeVariable() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class C<T> {",
        "  test() {",
        "    this..T;",
        "  }",
        "}"),
        ResolverErrorCode.TYPE_VARIABLE_NOT_ALLOWED_IN_IDENTIFIER);
  }

  public void test_cascade_complex() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class Spline {",
        "  Spline a() {",
        "    return this;",
        "  }",
        "  Line b() {",
        "    return null;",
        "  }",
        "  Spline f() {",
        "    Line x = new Line();",
        "    x.h()..a()..b().g();",
        "  }",
        "}",
        "class Line {",
        "  Line g() {",
        "    return this;",
        "  }",
        "  Spline h() {",
        "    return null;",
        "  }",
        "}"
    ));
  }

  /**
   * When {@link SupertypeResolver} can not find "UnknownA", it uses {@link DynamicType}, which
   * returns {@link DynamicElement}. By itself, this is OK. However when we later try to resolve
   * super() constructor invocation, this should not cause exception.
   */
  public void test_classExtendsUnknown_callSuperConstructor() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class MyClass extends UnknownA {",
        "  MyClass() : super() {",
        "  }",
        "}"),
        ResolverErrorCode.NO_SUCH_TYPE);
  }

  public void test_typedefUsedAsExpression() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "typedef f();",
        "main() {",
        "  try {",
        "    0.25 - f;",
        "  } catch(e) {}",
        "}"));
  }

  public void test_classUsedAsExpression() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "main() {",
        "    0.25 - Object;",
        "}"));
  }

  public void test_typeVariableUsedAsExpression() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A<B> {",
        "  var field = B;",
        "  f() {",
        "    process(x);",
        "  }",
        "}",
        "process(x) {}",
        ""));
  }

  public void test_shadowType_withVariable() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class Foo<T> {}",
        "class Param {}",
        "class MyClass {",
        "  foo() {",
        "    var Param;",
        "    new Foo<Param>();",
        "  }",
        "}"),
        TypeErrorCode.NOT_A_TYPE);
  }

  public void test_operatorIs_withFunctionAlias() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "typedef dynamic F1<T>(dynamic x, T y);",
        "class MyClass {",
        "  main() {",
        "    F1<int> f1 = (Object o, int i) => null;",
        "    if (f1 is F1<int>) {",
        "    }",
        "  }",
        "}"));
  }

  public void testTypeVariableInStatic() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A<T> {",
        "  static foo() { new T(); }", // can't ref type variable in method
        "  static bar() { T variable = 1; }",
        "}"),
        errEx(ResolverErrorCode.TYPE_VARIABLE_IN_STATIC_CONTEXT, 3, 22 , 1),
        errEx(ResolverErrorCode.TYPE_VARIABLE_IN_STATIC_CONTEXT, 4, 18, 1));
  }

  public void testConstClass() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "class GoodBase {",
        "  const GoodBase() : foo = 1;",
        "  final foo;",
        "}",
        "class BadBase {",
        "  BadBase() {}",
        "  var foo;",
        "}",                                       // line 10
        "class Bad {",
        "  const Bad() : bar = 1;",
        "  var bar;", // error: non-final field in const class
        "}",
        "class BadSub1 extends BadBase {",
        "  const BadSub1() : super(),  bar = 1;", // error2: inherits non-final field, super !const
        "  final bar;",
        "}",
        "class BadSub2 extends GoodBase {",
        "  const BadSub2() : super(),  bar = 1;", // line 20
        "  var bar;",                             // error: non-final field in constant class
        "}",
        "class GoodSub1 extends GoodBase {",
        "  const GoodSub1() : super(),  bar = 1;",
        "  final bar;",
        "}",
        "class GoodSub2 extends GoodBase {",
        "  const GoodSub2() : super();",
        "  static int bar;",                      // OK, non-final but it is static
        "}"),
        errEx(ResolverErrorCode.CONST_CLASS_WITH_NONFINAL_FIELDS, 13, 7, 3),
        errEx(ResolverErrorCode.CONST_CONSTRUCTOR_MUST_CALL_CONST_SUPER, 16, 9, 7),
        errEx(ResolverErrorCode.CONST_CLASS_WITH_INHERITED_NONFINAL_FIELDS, 9, 7, 3),
        errEx(ResolverErrorCode.CONST_CLASS_WITH_NONFINAL_FIELDS, 21, 7, 3));
  }

  public void testFinalInit1() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "final f1 = 1;",
        "final f2;",  // error
        "class A {",
        "  final f3 = 1;",
        "  final f4;",  // should be initialized in constructor
        "  static final f5 = 1;",
        "  static final f6;",    // error
        "  method() {",
        "    final f7 = 1;",
        "    final f8;",  // error
        "  }",
        "}"),
        errEx(ResolverErrorCode.TOPLEVEL_FINAL_REQUIRES_VALUE, 4, 7 , 2),
        errEx(ResolverErrorCode.STATIC_FINAL_REQUIRES_VALUE, 9, 16, 2),
        errEx(ResolverErrorCode.CONSTANTS_MUST_BE_INITIALIZED, 12, 11, 2),
        errEx(ResolverErrorCode.FINAL_FIELD_MUST_BE_INITIALIZED, 7, 9, 2));
  }

  public void testFinalInit2() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class C {",
        "  final a;",
        "  C() {}",   // explicit constructor does not initialize
        "}"),
        errEx(ResolverErrorCode.FINAL_FIELD_MUST_BE_INITIALIZED, 3, 9, 1));
  }

  public void testFinalInit3() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class C {",
        "  final a;",  // implicit constructor does not initialize
        "}"),
        errEx(ResolverErrorCode.FINAL_FIELD_MUST_BE_INITIALIZED, 3, 9, 1));
  }

  public void testFinalInit4() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class C {",
        "  final a;",
        "  C(this.a);", // no error if initialized in initializer list
        "}"));
  }

  public void testFinalInit5() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class C {",
        "  final a;",
        "  C() : this.named(1);",  // no error on redirect
        "  C.named(this.a) {}",
        "}"));
  }

  public void testFinalInit7() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class C {",
        "  final a = 1;",
        "}"));
  }

  public void testFinalInit8() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class C {",
        "  final a;",
        "  C() : this.a = 1;",
        "}"));
  }

  public void test_const_requiresValue() {
    resolveAndTest(Joiner.on("\n").join(
        "// filler filler filler filler filler filler filler filler filler filler",
        "class Object {}",
        "class int {}",
        "const f;",
        ""),
        errEx(ResolverErrorCode.CONST_REQUIRES_VALUE, 4, 7, 1));
  }

  public void test_const_requiresConstValue() {
    resolveAndTestCtConstExpectErrors(Joiner.on("\n").join(
        "class Object {}",
        "f() {",
        "  const id = 1.toString();",
        "}"),
        errEx(ResolverErrorCode.EXPECTED_CONSTANT_EXPRESSION, 3, 14, 12));
  }

  public void test_const_undefinedClass() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "main() {",
        " const A();",
        "}"),
        errEx(ResolverErrorCode.NO_SUCH_TYPE_CONST, 3, 8, 1));
  }

  public void testNoGetterOrSetter() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "get getter1 {}",
        "set setter1(arg) {}",
        "class A {",
        "  static get getter2 {}",
        "  static set setter2(arg) {}",
        "  get getter3 {}",
        "  set setter3(arg) {}",
        "}",
        "method() {",
        "  var result;",
        "  result = getter1;",
        "  getter1 = 1;",
        "  result = setter1;",
        "  setter1 = 1;",
        "  result = A.getter2;",
        "  A.getter2 = 1;",
        "  result = A.setter2;",
        "  A.setter2 = 1;",
        "  var instance = new A();",
        "  result = instance.getter3;",
        "  instance.getter3 = 1;",
        "  result = instance.setter3;",
        "  instance.setter3 = 1;",
        "}"),
        errEx(ResolverErrorCode.FIELD_DOES_NOT_HAVE_A_SETTER, 13, 3, 7),
        errEx(ResolverErrorCode.FIELD_DOES_NOT_HAVE_A_GETTER, 14, 12, 7),
        errEx(ResolverErrorCode.FIELD_DOES_NOT_HAVE_A_SETTER, 17, 5, 7),
        errEx(ResolverErrorCode.FIELD_DOES_NOT_HAVE_A_GETTER, 18, 14, 7));
  }

  public void testErrorInUnqualifiedInvocation1() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "class Foo {",
        "  Foo() {}",
        "}",
        "method() {",
        " Foo();",
        "}"),
        errEx(ResolverErrorCode.DID_YOU_MEAN_NEW, 7, 2, 5));
  }

  public void testErrorInUnqualifiedInvocation2() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "class Foo {}",
        "method() {",
        " Foo();",
        "}"),
        errEx(ResolverErrorCode.DID_YOU_MEAN_NEW, 5, 2, 5));
  }

  public void testErrorInUnqualifiedInvocation3() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "class Foo<T> {",
        "  method() {",
        "   T();",
        "  }",
        "}"),
        errEx(ResolverErrorCode.DID_YOU_MEAN_NEW, 5, 4, 3));
  }


  public void testErrorInUnqualifiedInvocation4() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "typedef int foo();",
        "method() {",
        " foo();",
        "}"),
        errEx(ResolverErrorCode.CANNOT_CALL_FUNCTION_TYPE_ALIAS, 5, 2, 5));
  }

  public void testErrorInUnqualifiedInvocation5() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "method() {",
        "  outer: for(int i = 0; i < 1; i++) {",
        "    outer();",
        "  }",
        "}"),
        errEx(ResolverErrorCode.CANNOT_RESOLVE_METHOD, 5, 5, 5));
  }

  public void testUndercoreInNamedParameterMethodDefinition() {
    // TODO(scheglov)
    // Language change 4288 adds new syntax for optional named parameters.
    // However before "remove old optional parameter syntax" we have to support old syntax too.
    // And this conflicts with "_" handling in optional named parameters.
    // 
    // http://code.google.com/p/dart/issues/detail?id=4539
    // requested to disable this
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "method({_foo}) {}",
        "class Foo {",
        "  var _bar;",
        "  //Foo({this._bar}){}",
        "  method({_foo}){}",
        "}"),
        errEx(ResolverErrorCode.NAMED_PARAMETERS_CANNOT_START_WITH_UNDER, 2, 9, 4),
//        errEx(ResolverErrorCode.NAMED_PARAMETERS_CANNOT_START_WITH_UNDER, 5, 8, 9),
        errEx(ResolverErrorCode.NAMED_PARAMETERS_CANNOT_START_WITH_UNDER, 6, 11, 4));
  }
  
  public void testUndercoreInOptionalParameterMethodDefinition() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "method([_foo]) {}",
        "typedef myFuncType([_foo]);",
        "class Foo {",
        "  var _bar;",
        "  method([_foo]){}",
        "}"),
        errEx(ResolverErrorCode.OPTIONAL_PARAMETERS_CANNOT_START_WITH_UNDER, 2, 9, 4),
        errEx(ResolverErrorCode.OPTIONAL_PARAMETERS_CANNOT_START_WITH_UNDER, 6, 11, 4),
        errEx(ResolverErrorCode.OPTIONAL_PARAMETERS_CANNOT_START_WITH_UNDER, 3, 21, 4));
  }

  public void testUndercoreInNamedParameterFunctionDefinition() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "var f = func({_foo}) {};"),
        errEx(ResolverErrorCode.NAMED_PARAMETERS_CANNOT_START_WITH_UNDER, 2, 15, 4));
  }

  public void testUndercoreInNamedParameterFunctionAlias() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "typedef Object func({_foo});"),
        errEx(ResolverErrorCode.NAMED_PARAMETERS_CANNOT_START_WITH_UNDER, 2, 22, 4));
  }

  /**
   * "this" is not accessible to initializers, so invocation of instance method is error.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=2477
   */
  public void test_callInstanceMethod_fromInitializer() throws Exception {
    resolveAndTest(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class Object {}",
            "class A {",
            "  var x;",
            "  A() : x = foo() {}",
            "  foo() {}",
            "}",
            ""),
        errEx(ResolverErrorCode.INSTANCE_METHOD_FROM_INITIALIZER, 5, 13, 5));
  }

  /**
   * "this" is not accessible to initializers, so reference of instance method is error.
   * <p>
   * http://code.google.com/p/dart/issues/detail?id=2477
   */
  public void test_referenceInstanceMethod_fromInitializer() throws Exception {
    resolveAndTest(
        Joiner.on("\n").join(
            "// filler filler filler filler filler filler filler filler filler filler",
            "class Object {}",
            "class A {",
            "  var x;",
            "  A() : x = foo {}",
            "  foo() {}",
            "}",
            ""),
            errEx(ResolverErrorCode.INSTANCE_METHOD_FROM_INITIALIZER, 5, 13, 3));
  }

  public void test_redirectConstructor() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "int topLevel() {}",
        "class A {",
        "  method() {}",
        "}",
        "class C {",
        "  C(arg){}",
        "  C.named1() : this(topLevel());", // ok
        "  C.named2() : this(method());", // error, not a static method
        "  C.named3() : this(new A().method());", // ok
        "  method() {}",
        "}"),
        errEx(ResolverErrorCode.INSTANCE_METHOD_FROM_REDIRECT, 10, 21, 8));
  }

  public void test_unresolvedRedirectConstructor() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  A() : this.named();",
        "}"),
        errEx(ResolverErrorCode.CANNOT_RESOLVE_CONSTRUCTOR, 3, 9, 12));
  }

  public void test_unresolvedSuperConstructor() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  A() : super.named() {}",
        "}"),
        errEx(ResolverErrorCode.CANNOT_RESOLVE_SUPER_CONSTRUCTOR, 3, 9, 13));
  }

  public void test_unresolvedFieldInInitializer() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  const A() : this.field = 1;",
        "}"),
        errEx(ResolverErrorCode.CANNOT_RESOLVE_FIELD, 3, 20, 5));
  }

  public void test_illegalConstructorModifiers() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static A() {}",
        "  static A.named() {}",
        "}"),
        errEx(ResolverErrorCode.CONSTRUCTOR_CANNOT_BE_STATIC, 3, 10, 1),
        errEx(ResolverErrorCode.CONSTRUCTOR_CANNOT_BE_STATIC, 4, 10, 7));
  }

  public void test_illegalConstructorReturnType() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class int {}",
        "class A {",
        "  void A();",
        "  void A.named();",
        "}",
        "class B {",
        "  int B();",
        "  int B.named();",
        "}"),
        errEx(ResolverErrorCode.CONSTRUCTOR_CANNOT_HAVE_RETURN_TYPE, 4, 3, 4),
        errEx(ResolverErrorCode.CONSTRUCTOR_CANNOT_HAVE_RETURN_TYPE, 5, 3, 4),
        errEx(ResolverErrorCode.CONSTRUCTOR_CANNOT_HAVE_RETURN_TYPE, 8, 3, 3),
        errEx(ResolverErrorCode.CONSTRUCTOR_CANNOT_HAVE_RETURN_TYPE, 9, 3, 3));
  }

  public void test_fieldAccessInInitializer() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  var f1;",
        "  var f2;",
        "  A() : this.f2 = f1;",
        "}"),
        errEx(ResolverErrorCode.CANNOT_ACCESS_FIELD_IN_INIT, 5, 19, 2));
  }

  public void test_cannotBeResolved() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  static var field = B;",
        " }",
        "method() {",
        "  A.noField = 1;",
        "}"),
        errEx(TypeErrorCode.CANNOT_BE_RESOLVED, 3, 22, 1),
        errEx(TypeErrorCode.CANNOT_BE_RESOLVED, 6, 5, 7));
  }

  public void test_invokeTypeAlias() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "typedef Object func();",
        "method() {",
        "  func();",
        "}"),
        errEx(ResolverErrorCode.CANNOT_CALL_FUNCTION_TYPE_ALIAS, 4, 3, 6));
  }

  public void test_initializerErrors() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A { }",
        "class B<T> {",
        "  method() { }",
        "  B(arg) : A = 1, ",
        "           method = 2,",
        "           arg = 3,",
        "           T = 4 {}",
        "}"),
        errEx(ResolverErrorCode.EXPECTED_FIELD_NOT_CLASS, 5, 12, 1),
        errEx(ResolverErrorCode.EXPECTED_FIELD_NOT_METHOD, 6, 12, 6),
        errEx(ResolverErrorCode.EXPECTED_FIELD_NOT_PARAMETER, 7, 12, 3),
        errEx(ResolverErrorCode.EXPECTED_FIELD_NOT_TYPE_VAR, 8, 12, 1));
  }

  public void test_illegalAccessFromStatic() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class C {",
        "  var f;",
        "  m() {}",
        "  static method () {",
        "    f = 1;",
        "    m();",
        "    var func = m;",
        "  }",
        "}"),
        errEx(ResolverErrorCode.ILLEGAL_FIELD_ACCESS_FROM_STATIC, 6, 5, 1),
        errEx(ResolverErrorCode.INSTANCE_METHOD_FROM_STATIC, 7, 5, 3),
        errEx(ResolverErrorCode.ILLEGAL_METHOD_ACCESS_FROM_STATIC, 8, 16, 1));
  }

  public void test_invalidGenerativeConstructorReturn() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class C {",
        "  C() { return 5 + 7; }",
        "}"),
        errEx(ResolverErrorCode.INVALID_RETURN_IN_CONSTRUCTOR, 3, 9, 13));
  }

  public void test_isAClass() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "method () {",
        "  var a = Object;",
        "}"));
  }

  public void test_isAnInstanceMethod() {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class C {",
        "  method() {}",
        "}",
        "method () {",
        "  var a = C.method();",
        "}"),
        errEx(ResolverErrorCode.IS_AN_INSTANCE_METHOD, 6, 13, 6));
  }

  public void test_staticAccess() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class C {",
        "  var field;",
        "  method() {}",
        "}",
        "method() {",
        "  C.method = 1;",
        "  C.field();",
        "  var a = C.field;",
        "}"),
        errEx(ResolverErrorCode.NOT_A_STATIC_METHOD, 7, 5, 6),
        errEx(ResolverErrorCode.CANNOT_ASSIGN_TO_METHOD, 7, 3, 8),
        errEx(ResolverErrorCode.IS_AN_INSTANCE_FIELD, 8, 5, 5),
        errEx(ResolverErrorCode.NOT_A_STATIC_FIELD, 9, 13, 5));
  }

  public void test_redirectedConstructor() throws Exception {
  resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  A() : this.named1();",
        "  A.named1() : this.named2();",
        "  A.named2() : this.named1();",
        "}"),
        errEx(ResolverErrorCode.REDIRECTED_CONSTRUCTOR_CYCLE, 3, 3, 20),
        errEx(ResolverErrorCode.REDIRECTED_CONSTRUCTOR_CYCLE, 4, 3, 27),
        errEx(ResolverErrorCode.REDIRECTED_CONSTRUCTOR_CYCLE, 5, 3, 27));
  }

  public void test_tooFewArgumentsInImplicitSuper() throws Exception {
    resolveAndTest(Joiner.on("\n").join(
        "class Object {}",
        "class A {",
        "  A(arg) {}",
        "}",
        "class B extends A {",
        "  B() { }",
        "}"),
        errEx(ResolverErrorCode.TOO_FEW_ARGUMENTS_IN_IMPLICIT_SUPER, 6, 3, 7));
  }
}
