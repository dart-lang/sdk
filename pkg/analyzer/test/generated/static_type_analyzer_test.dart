// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart' show ResolverVisitor;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/static_type_analyzer.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'elements_types_mixin.dart';
import 'resolver_test_case.dart';
import 'test_analysis_context.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetLiteralsTest);
    defineReflectiveTests(StaticTypeAnalyzerTest);
    defineReflectiveTests(StaticTypeAnalyzer2Test);
  });
}

/// Wrapper around the test package's `fail` function.
///
/// Unlike the test package's `fail` function, this function is not annotated
/// with @alwaysThrows, so we can call it at the top of a test method without
/// causing the rest of the method to be flagged as dead code.
void _fail(String message) {
  fail(message);
}

@reflectiveTest
class SetLiteralsTest extends StaticTypeAnalyzer2TestShared {
  test_emptySetLiteral_parameter_typed() async {
    await assertNoErrorsInCode(r'''
main() {
  useSet({});
}
void useSet(Set<int> s) {
}
''');
    expectExpressionType('{}', 'Set<int>');
  }
}

/// Like [StaticTypeAnalyzerTest], but as end-to-end tests.
@reflectiveTest
class StaticTypeAnalyzer2Test extends StaticTypeAnalyzer2TestShared {
  test_emptyListLiteral_inferredFromLinkedList() async {
    await assertErrorsInCode(r'''
abstract class ListImpl<T> implements List<T> {}
ListImpl<int> f() => [];
''', [
      error(CompileTimeErrorCode.INVALID_CAST_LITERAL_LIST, 70, 2),
    ]);
    expectExpressionType('[]', 'List<dynamic>');
  }

  test_emptyMapLiteral_inferredFromLinkedHashMap() async {
    await assertErrorsInCode(r'''
import 'dart:collection';
LinkedHashMap<int, int> f() => {};
''', [
      error(CompileTimeErrorCode.INVALID_CAST_LITERAL_MAP, 57, 2),
    ]);
    expectExpressionType('{}', 'Map<dynamic, dynamic>');
  }

  test_emptyMapLiteral_initializer_var() async {
    await assertErrorsInCode(r'''
main() {
  var v = {};
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 15, 1),
    ]);
    expectExpressionType('{}', 'Map<dynamic, dynamic>');
  }

  test_emptyMapLiteral_parameter_typed() async {
    await assertNoErrorsInCode(r'''
main() {
  useMap({});
}
void useMap(Map<int, int> m) {
}
''');
    expectExpressionType('{}', 'Map<int, int>');
  }

  test_emptySetLiteral_inferredFromLinkedHashSet() async {
    await assertErrorsInCode(r'''
import 'dart:collection';
LinkedHashSet<int> f() => {};
''', [
      error(CompileTimeErrorCode.INVALID_CAST_LITERAL_SET, 52, 2),
    ]);
    expectExpressionType('{}', 'Set<dynamic>');
  }

  test_emptySetLiteral_initializer_typed_nested() async {
    await assertNoErrorsInCode(r'''
Set<Set<int>> ints = {{}};
''');
    expectExpressionType('{}', 'Set<int>');
    expectExpressionType('{{}}', 'Set<Set<int>>');
  }

  test_FunctionExpressionInvocation_block() async {
    await assertErrorsInCode(r'''
main() {
  var foo = (() { return 1; })();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 15, 3),
    ]);
    expectInitializerType('foo', 'int');
  }

  test_FunctionExpressionInvocation_curried() async {
    await assertErrorsInCode(r'''
typedef int F();
F f() => null;
main() {
  var foo = f()();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 47, 3),
    ]);
    expectInitializerType('foo', 'int');
  }

  test_FunctionExpressionInvocation_expression() async {
    await assertErrorsInCode(r'''
main() {
  var foo = (() => 1)();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 15, 3),
    ]);
    expectInitializerType('foo', 'int');
  }

  test_MethodInvocation_nameType_localVariable() async {
    await assertNoErrorsInCode(r"""
typedef Foo();
main() {
  Foo foo;
  foo();
}
""");
    // "foo" should be resolved to the "Foo" type
    expectIdentifierType("foo();", TypeMatcher<FunctionType>());
  }

  test_MethodInvocation_nameType_parameter_FunctionTypeAlias() async {
    await assertNoErrorsInCode(r"""
typedef Foo();
main(Foo foo) {
  foo();
}
""");
    // "foo" should be resolved to the "Foo" type
    expectIdentifierType("foo();", TypeMatcher<FunctionType>());
  }

  test_MethodInvocation_nameType_parameter_propagatedType() async {
    await assertNoErrorsInCode(r"""
typedef Foo();
main(p) {
  if (p is Foo) {
    p();
  }
}
""");
    expectIdentifierType("p()", 'dynamic Function()');
  }

  test_staticMethods_classTypeParameters() async {
    await assertNoErrorsInCode(r'''
class C<T> {
  static void m() => null;
}
main() {
  print(C.m);
}
''');
    assertType(findNode.simple('m);'), 'void Function()');
  }

  test_staticMethods_classTypeParameters_genericMethod() async {
    await assertNoErrorsInCode(r'''
class C<T> {
  static void m<S>(S s) {
    void f<U>(S s, U u) {}
    print(f);
  }
}
main() {
  print(C.m);
}
''');
    assertType(
      findNode.simple('f);'),
      'void Function<U>(S, U)',
    );
    assertType(
      findNode.simple('m);'),
      'void Function<S>(S)',
    );
  }
}

@reflectiveTest
class StaticTypeAnalyzerTest with ResourceProviderMixin, ElementsTypesMixin {
  /// The error listener to which errors will be reported.
  GatheringErrorListener _listener;

  /// The resolver visitor used to create the analyzer.
  ResolverVisitor _visitor;

  /// The library containing the code being resolved.
  LibraryElementImpl _definingLibrary;

  /// The analyzer being used to analyze the test cases.
  StaticTypeAnalyzer _analyzer;

  /// The type provider used to access the types.
  TypeProvider _typeProvider;

  @override
  TypeProvider get typeProvider => _definingLibrary.typeProvider;

  /// The type system used to analyze the test cases.
  TypeSystemImpl get _typeSystem => _definingLibrary.typeSystem;

  void fail_visitFunctionExpressionInvocation() {
    _fail("Not yet tested");
    _listener.assertNoErrors();
  }

  void fail_visitMethodInvocation() {
    _fail("Not yet tested");
    _listener.assertNoErrors();
  }

  void fail_visitSimpleIdentifier() {
    _fail("Not yet tested");
    _listener.assertNoErrors();
  }

  void setUp() {
    _listener = GatheringErrorListener();
    _createAnalyzer();
  }

  void test_flatten_derived() {
    // class Derived<T> extends Future<T> { ... }
    ClassElementImpl derivedClass =
        ElementFactory.classElement2('Derived', ['T']);
    derivedClass.supertype =
        futureType(typeParameterTypeStar(derivedClass.typeParameters[0]));
    InterfaceType intType = _typeProvider.intType;
    DartType dynamicType = _typeProvider.dynamicType;
    InterfaceType derivedIntType =
        interfaceTypeStar(derivedClass, typeArguments: [intType]);
    // flatten(Derived) = dynamic
    InterfaceType derivedDynamicType =
        interfaceTypeStar(derivedClass, typeArguments: [dynamicType]);
    expect(_flatten(derivedDynamicType), dynamicType);
    // flatten(Derived<int>) = int
    expect(_flatten(derivedIntType), intType);
    // flatten(Derived<Derived>) = Derived
    expect(
        _flatten(interfaceTypeStar(derivedClass,
            typeArguments: [derivedDynamicType])),
        derivedDynamicType);
    // flatten(Derived<Derived<int>>) = Derived<int>
    expect(
        _flatten(
            interfaceTypeStar(derivedClass, typeArguments: [derivedIntType])),
        derivedIntType);
  }

  void test_flatten_inhibit_recursion() {
    // class A extends B
    // class B extends A
    ClassElementImpl classA = ElementFactory.classElement2('A', []);
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    classA.supertype = interfaceTypeStar(classB);
    classB.supertype = interfaceTypeStar(classA);
    // flatten(A) = A and flatten(B) = B, since neither class contains Future
    // in its class hierarchy.  Even though there is a loop in the class
    // hierarchy, flatten() should terminate.
    expect(_flatten(interfaceTypeStar(classA)), interfaceTypeStar(classA));
    expect(_flatten(interfaceTypeStar(classB)), interfaceTypeStar(classB));
  }

  void test_flatten_related_derived_types() {
    InterfaceType intType = _typeProvider.intType;
    InterfaceType numType = _typeProvider.numType;
    // class Derived<T> extends Future<T>
    ClassElementImpl derivedClass =
        ElementFactory.classElement2('Derived', ['T']);
    derivedClass.supertype =
        futureType(typeParameterTypeStar(derivedClass.typeParameters[0]));
    // class A extends Derived<int> implements Derived<num> { ... }
    ClassElementImpl classA = ElementFactory.classElement(
        'A', interfaceTypeStar(derivedClass, typeArguments: [intType]));
    classA.interfaces = <InterfaceType>[
      interfaceTypeStar(derivedClass, typeArguments: [numType]),
    ];
    // class B extends Future<num> implements Future<int> { ... }
    ClassElementImpl classB = ElementFactory.classElement(
        'B', interfaceTypeStar(derivedClass, typeArguments: [numType]));
    classB.interfaces = <InterfaceType>[
      interfaceTypeStar(derivedClass, typeArguments: [intType])
    ];
    // flatten(A) = flatten(B) = int, since int is more specific than num.
    // The code in flatten() that inhibits infinite recursion shouldn't be
    // fooled by the fact that Derived appears twice in the type hierarchy.
    expect(_flatten(interfaceTypeStar(classA)), intType);
    expect(_flatten(interfaceTypeStar(classB)), intType);
  }

  void test_flatten_related_types() {
    InterfaceType intType = _typeProvider.intType;
    InterfaceType numType = _typeProvider.numType;
    // class A extends Future<int> implements Future<num> { ... }
    ClassElementImpl classA =
        ElementFactory.classElement('A', _typeProvider.futureType2(intType));
    classA.interfaces = <InterfaceType>[_typeProvider.futureType2(numType)];
    // class B extends Future<num> implements Future<int> { ... }
    ClassElementImpl classB =
        ElementFactory.classElement('B', _typeProvider.futureType2(numType));
    classB.interfaces = <InterfaceType>[_typeProvider.futureType2(intType)];
    // flatten(A) = flatten(B) = int, since int is more specific than num.
    expect(_flatten(interfaceTypeStar(classA)), intType);
    expect(_flatten(interfaceTypeStar(classB)), intType);
  }

  void test_flatten_simple() {
    InterfaceType intType = _typeProvider.intType;
    DartType dynamicType = _typeProvider.dynamicType;
    InterfaceType futureDynamicType = _typeProvider.futureDynamicType;
    InterfaceType futureIntType = _typeProvider.futureType2(intType);
    InterfaceType futureFutureDynamicType =
        _typeProvider.futureType2(futureDynamicType);
    InterfaceType futureFutureIntType =
        _typeProvider.futureType2(futureIntType);
    // flatten(int) = int
    expect(_flatten(intType), intType);
    // flatten(dynamic) = dynamic
    expect(_flatten(dynamicType), dynamicType);
    // flatten(Future) = dynamic
    expect(_flatten(futureDynamicType), dynamicType);
    // flatten(Future<int>) = int
    expect(_flatten(futureIntType), intType);
    // flatten(Future<Future>) = Future<dynamic>
    expect(_flatten(futureFutureDynamicType), futureDynamicType);
    // flatten(Future<Future<int>>) = Future<int>
    expect(_flatten(futureFutureIntType), futureIntType);
  }

  void test_flatten_unrelated_types() {
    InterfaceType intType = _typeProvider.intType;
    InterfaceType stringType = _typeProvider.stringType;
    // class A extends Future<int> implements Future<String> { ... }
    ClassElementImpl classA =
        ElementFactory.classElement('A', _typeProvider.futureType2(intType));
    classA.interfaces = <InterfaceType>[_typeProvider.futureType2(stringType)];
    // class B extends Future<String> implements Future<int> { ... }
    ClassElementImpl classB =
        ElementFactory.classElement('B', _typeProvider.futureType2(stringType));
    classB.interfaces = <InterfaceType>[_typeProvider.futureType2(intType)];
    // flatten(A) = A and flatten(B) = B, since neither string nor int is more
    // specific than the other.
    expect(_flatten(interfaceTypeStar(classA)), interfaceTypeStar(classA));
    expect(_flatten(interfaceTypeStar(classB)), interfaceTypeStar(classB));
  }

  void test_visitAdjacentStrings() {
    // "a" "b"
    Expression node = AstTestFactory.adjacentStrings(
        [_resolvedString("a"), _resolvedString("b")]);
    expect(_analyze(node), same(_typeProvider.stringType));
    _listener.assertNoErrors();
  }

  void test_visitAsExpression() {
    // class A { ... this as B ... }
    // class B extends A {}
    ClassElement superclass = ElementFactory.classElement2("A");
    InterfaceType superclassType = interfaceTypeStar(superclass);
    ClassElement subclass = ElementFactory.classElement("B", superclassType);
    Expression node = AstTestFactory.asExpression(
        AstTestFactory.thisExpression(), AstTestFactory.typeName(subclass));
    expect(_analyze(node, superclassType), interfaceTypeStar(subclass));
    _listener.assertNoErrors();
  }

  void test_visitAwaitExpression_flattened() {
    // await e, where e has type Future<Future<int>>
    InterfaceType intType = _typeProvider.intType;
    InterfaceType futureIntType = _typeProvider.futureType2(intType);
    InterfaceType futureFutureIntType =
        _typeProvider.futureType2(futureIntType);
    Expression node = AstTestFactory.awaitExpression(
        _resolvedVariable(futureFutureIntType, 'e'));
    expect(_analyze(node), same(futureIntType));
    _listener.assertNoErrors();
  }

  void test_visitAwaitExpression_simple() {
    // await e, where e has type Future<int>
    InterfaceType intType = _typeProvider.intType;
    InterfaceType futureIntType = _typeProvider.futureType2(intType);
    Expression node =
        AstTestFactory.awaitExpression(_resolvedVariable(futureIntType, 'e'));
    expect(_analyze(node), same(intType));
    _listener.assertNoErrors();
  }

  void test_visitBooleanLiteral_false() {
    // false
    Expression node = AstTestFactory.booleanLiteral(false);
    expect(_analyze(node), same(_typeProvider.boolType));
    _listener.assertNoErrors();
  }

  void test_visitBooleanLiteral_true() {
    // true
    Expression node = AstTestFactory.booleanLiteral(true);
    expect(_analyze(node), same(_typeProvider.boolType));
    _listener.assertNoErrors();
  }

  void test_visitCascadeExpression() {
    // a..length
    Expression node = AstTestFactory.cascadeExpression(
        _resolvedString("a"), [AstTestFactory.propertyAccess2(null, "length")]);
    expect(_analyze(node), same(_typeProvider.stringType));
    _listener.assertNoErrors();
  }

  void test_visitConditionalExpression_differentTypes() {
    // true ? 1.0 : 0
    Expression node = AstTestFactory.conditionalExpression(
        AstTestFactory.booleanLiteral(true),
        _resolvedDouble(1.0),
        _resolvedInteger(0));
    expect(_analyze(node), _typeProvider.numType);
    _listener.assertNoErrors();
  }

  void test_visitConditionalExpression_sameTypes() {
    // true ? 1 : 0
    Expression node = AstTestFactory.conditionalExpression(
        AstTestFactory.booleanLiteral(true),
        _resolvedInteger(1),
        _resolvedInteger(0));
    expect(_analyze(node), same(_typeProvider.intType));
    _listener.assertNoErrors();
  }

  void test_visitDoubleLiteral() {
    // 4.33
    Expression node = AstTestFactory.doubleLiteral(4.33);
    expect(_analyze(node), same(_typeProvider.doubleType));
    _listener.assertNoErrors();
  }

  void test_visitInstanceCreationExpression_named() {
    // new C.m()
    ClassElementImpl classElement = ElementFactory.classElement2("C");
    String constructorName = "m";
    ConstructorElementImpl constructor =
        ElementFactory.constructorElement2(classElement, constructorName);
    classElement.constructors = <ConstructorElement>[constructor];
    InstanceCreationExpression node =
        AstTestFactory.instanceCreationExpression2(
            null,
            AstTestFactory.typeName(classElement),
            [AstTestFactory.identifier3(constructorName)]);
    expect(_analyze(node), interfaceTypeStar(classElement));
    _listener.assertNoErrors();
  }

  void test_visitInstanceCreationExpression_typeParameters() {
    // new C<I>()
    ClassElementImpl elementC = ElementFactory.classElement2("C", ["E"]);
    ClassElementImpl elementI = ElementFactory.classElement2("I");
    ConstructorElementImpl constructor =
        ElementFactory.constructorElement2(elementC, null);
    elementC.constructors = <ConstructorElement>[constructor];
    TypeName typeName =
        AstTestFactory.typeName(elementC, [AstTestFactory.typeName(elementI)]);
    typeName.type = interfaceTypeStar(elementC,
        typeArguments: [interfaceTypeStar(elementI)]);
    InstanceCreationExpression node =
        AstTestFactory.instanceCreationExpression2(null, typeName);
    InterfaceType type = _analyze(node) as InterfaceType;
    List<DartType> typeArgs = type.typeArguments;
    expect(typeArgs.length, 1);
    expect(typeArgs[0], interfaceTypeStar(elementI));
    _listener.assertNoErrors();
  }

  void test_visitInstanceCreationExpression_unnamed() {
    // new C()
    ClassElementImpl classElement = ElementFactory.classElement2("C");
    ConstructorElementImpl constructor =
        ElementFactory.constructorElement2(classElement, null);
    classElement.constructors = <ConstructorElement>[constructor];
    InstanceCreationExpression node =
        AstTestFactory.instanceCreationExpression2(
            null, AstTestFactory.typeName(classElement));
    expect(_analyze(node), interfaceTypeStar(classElement));
    _listener.assertNoErrors();
  }

  void test_visitIntegerLiteral() {
    // 42
    Expression node = _resolvedInteger(42);
    expect(_analyze(node), same(_typeProvider.intType));
    _listener.assertNoErrors();
  }

  void test_visitIsExpression_negated() {
    // a is! String
    Expression node = AstTestFactory.isExpression(
        _resolvedString("a"), true, AstTestFactory.typeName4("String"));
    expect(_analyze(node), same(_typeProvider.boolType));
    _listener.assertNoErrors();
  }

  void test_visitIsExpression_notNegated() {
    // a is String
    Expression node = AstTestFactory.isExpression(
        _resolvedString("a"), false, AstTestFactory.typeName4("String"));
    expect(_analyze(node), same(_typeProvider.boolType));
    _listener.assertNoErrors();
  }

  @FailingTest(reason: 'This is an old unit test, port and remove')
  void test_visitMethodInvocation_then() {
    // then()
    Expression node = AstTestFactory.methodInvocation(null, "then");
    _analyze(node);
    _listener.assertNoErrors();
  }

  void test_visitNamedExpression() {
    // n: a
    Expression node =
        AstTestFactory.namedExpression2("n", _resolvedString("a"));
    expect(_analyze(node), same(_typeProvider.stringType));
    _listener.assertNoErrors();
  }

  void test_visitNullLiteral() {
    // null
    Expression node = AstTestFactory.nullLiteral();
    expect(_analyze(node), same(_typeProvider.nullType));
    _listener.assertNoErrors();
  }

  void test_visitParenthesizedExpression() {
    // (0)
    Expression node =
        AstTestFactory.parenthesizedExpression(_resolvedInteger(0));
    expect(_analyze(node), same(_typeProvider.intType));
    _listener.assertNoErrors();
  }

  void test_visitPrefixedIdentifier_getter() {
    DartType boolType = _typeProvider.boolType;
    PropertyAccessorElementImpl getter =
        ElementFactory.getterElement("b", false, boolType);
    PrefixedIdentifier node = AstTestFactory.identifier5("a", "b");
    node.identifier.staticElement = getter;
    expect(_analyze(node), same(boolType));
    _listener.assertNoErrors();
  }

  void test_visitPrefixedIdentifier_setter() {
    DartType boolType = _typeProvider.boolType;
    FieldElementImpl field =
        ElementFactory.fieldElement("b", false, false, false, boolType);
    PropertyAccessorElement setter = field.setter;
    PrefixedIdentifier node = AstTestFactory.identifier5("a", "b");
    node.identifier.staticElement = setter;
    expect(_analyze(node), same(boolType));
    _listener.assertNoErrors();
  }

  void test_visitPrefixedIdentifier_variable() {
    VariableElementImpl variable = ElementFactory.localVariableElement2("b");
    variable.type = _typeProvider.boolType;
    PrefixedIdentifier node = AstTestFactory.identifier5("a", "b");
    node.identifier.staticElement = variable;
    expect(_analyze(node), same(_typeProvider.boolType));
    _listener.assertNoErrors();
  }

  void test_visitPropertyAccess_static_getter() {
    DartType boolType = _typeProvider.boolType;
    PropertyAccessorElementImpl getter =
        ElementFactory.getterElement("b", false, boolType);
    PropertyAccess node =
        AstTestFactory.propertyAccess2(AstTestFactory.identifier3("a"), "b");
    node.propertyName.staticElement = getter;
    expect(_analyze(node), same(boolType));
    _listener.assertNoErrors();
  }

  void test_visitPropertyAccess_static_setter() {
    DartType boolType = _typeProvider.boolType;
    FieldElementImpl field =
        ElementFactory.fieldElement("b", false, false, false, boolType);
    PropertyAccessorElement setter = field.setter;
    PropertyAccess node =
        AstTestFactory.propertyAccess2(AstTestFactory.identifier3("a"), "b");
    node.propertyName.staticElement = setter;
    expect(_analyze(node), same(boolType));
    _listener.assertNoErrors();
  }

  void test_visitSimpleStringLiteral() {
    // "a"
    Expression node = _resolvedString("a");
    expect(_analyze(node), same(_typeProvider.stringType));
    _listener.assertNoErrors();
  }

  void test_visitStringInterpolation() {
    // "a${'b'}c"
    Expression node = AstTestFactory.string([
      AstTestFactory.interpolationString("a", "a"),
      AstTestFactory.interpolationExpression(_resolvedString("b")),
      AstTestFactory.interpolationString("c", "c")
    ]);
    expect(_analyze(node), same(_typeProvider.stringType));
    _listener.assertNoErrors();
  }

  void test_visitSuperExpression() {
    // super
    InterfaceType superType =
        interfaceTypeStar(ElementFactory.classElement2("A"));
    InterfaceType thisType =
        interfaceTypeStar(ElementFactory.classElement("B", superType));
    Expression node = AstTestFactory.superExpression();
    expect(_analyze(node, thisType), same(thisType));
    _listener.assertNoErrors();
  }

  void test_visitSymbolLiteral() {
    expect(_analyze(AstTestFactory.symbolLiteral(["a"])),
        same(_typeProvider.symbolType));
  }

  void test_visitThisExpression() {
    // this
    InterfaceType thisType = interfaceTypeStar(ElementFactory.classElement(
        "B", interfaceTypeStar(ElementFactory.classElement2("A"))));
    Expression node = AstTestFactory.thisExpression();
    expect(_analyze(node, thisType), same(thisType));
    _listener.assertNoErrors();
  }

  void test_visitThrowExpression_withoutValue() {
    // throw
    Expression node = AstTestFactory.throwExpression();
    expect(_analyze(node), same(_typeProvider.bottomType));
    _listener.assertNoErrors();
  }

  void test_visitThrowExpression_withValue() {
    // throw 0
    Expression node = AstTestFactory.throwExpression2(_resolvedInteger(0));
    expect(_analyze(node), same(_typeProvider.bottomType));
    _listener.assertNoErrors();
  }

  /// Return the type associated with the given [node] after the static type
  /// analyzer has computed a type for it. If [thisType] is provided, it is the
  /// type of 'this'.
  DartType _analyze(Expression node, [InterfaceType thisType]) {
    _visitor.setThisInterfaceType(thisType);
    node.accept(_analyzer);
    return node.staticType;
  }

  void _assertType(
      InterfaceTypeImpl expectedType, InterfaceTypeImpl actualType) {
    expect(
      actualType.getDisplayString(withNullability: false),
      expectedType.getDisplayString(withNullability: false),
    );
    expect(actualType.element, expectedType.element);
    List<DartType> expectedArguments = expectedType.typeArguments;
    int length = expectedArguments.length;
    List<DartType> actualArguments = actualType.typeArguments;
    expect(actualArguments, hasLength(length));
    for (int i = 0; i < length; i++) {
      _assertType2(expectedArguments[i], actualArguments[i]);
    }
  }

  void _assertType2(DartType expectedType, DartType actualType) {
    if (expectedType is InterfaceTypeImpl) {
      _assertType(expectedType, actualType as InterfaceTypeImpl);
    }
    // TODO(brianwilkerson) Compare other kinds of types then make this a shared
    // utility method.
  }

  /// Create the analyzer used by the tests.
  void _createAnalyzer() {
    var context = TestAnalysisContext();
    var inheritance = InheritanceManager3();
    Source source = FileSource(getFile("/lib.dart"));
    CompilationUnitElementImpl definingCompilationUnit =
        CompilationUnitElementImpl();
    definingCompilationUnit.librarySource =
        definingCompilationUnit.source = source;
    var featureSet = FeatureSet.forTesting();

    _definingLibrary =
        LibraryElementImpl(context, null, null, -1, 0, featureSet);
    _definingLibrary.definingCompilationUnit = definingCompilationUnit;

    _definingLibrary.typeProvider = context.typeProviderLegacy;
    _definingLibrary.typeSystem = context.typeSystemLegacy;
    _typeProvider = context.typeProviderLegacy;

    _visitor = ResolverVisitor(
        inheritance, _definingLibrary, source, _typeProvider, _listener,
        featureSet: featureSet, nameScope: _definingLibrary.scope);
    _analyzer = _visitor.typeAnalyzer;
  }

  DartType _flatten(DartType type) => _typeSystem.flatten(type);

  /// Return an integer literal that has been resolved to the correct type.
  ///
  /// @param value the value of the literal
  /// @return an integer literal that has been resolved to the correct type
  DoubleLiteral _resolvedDouble(double value) {
    DoubleLiteral literal = AstTestFactory.doubleLiteral(value);
    literal.staticType = _typeProvider.doubleType;
    return literal;
  }

  /// Return an integer literal that has been resolved to the correct type.
  ///
  /// @param value the value of the literal
  /// @return an integer literal that has been resolved to the correct type
  IntegerLiteral _resolvedInteger(int value) {
    IntegerLiteral literal = AstTestFactory.integer(value);
    literal.staticType = _typeProvider.intType;
    return literal;
  }

  /// Return a string literal that has been resolved to the correct type.
  ///
  /// @param value the value of the literal
  /// @return a string literal that has been resolved to the correct type
  SimpleStringLiteral _resolvedString(String value) {
    SimpleStringLiteral string = AstTestFactory.string2(value);
    string.staticType = _typeProvider.stringType;
    return string;
  }

  /// Return a simple identifier that has been resolved to a variable element
  /// with the given type.
  ///
  /// @param type the type of the variable being represented
  /// @param variableName the name of the variable
  /// @return a simple identifier that has been resolved to a variable element
  ///           with the given type
  SimpleIdentifier _resolvedVariable(InterfaceType type, String variableName) {
    SimpleIdentifier identifier = AstTestFactory.identifier3(variableName);
    VariableElementImpl element =
        ElementFactory.localVariableElement(identifier);
    element.type = type;
    identifier.staticElement = element;
    identifier.staticType = type;
    return identifier;
  }
}
