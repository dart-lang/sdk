// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/constant/potentially_constant.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IsConstantTypeExpressionTest);
    defineReflectiveTests(IsPotentiallyConstantTypeExpressionTest);
    defineReflectiveTests(PotentiallyConstantTest);
    defineReflectiveTests(PotentiallyConstantWithNullSafetyTest);
  });
}

@reflectiveTest
class IsConstantTypeExpressionTest extends PubPackageResolutionTest {
  test_class() async {
    await _assertConst(r'''
int x;
''');
  }

  test_class_prefix() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {}
''');
    await _assertConst(r'''
import 'a.dart' as p;
p.A x;
''');
  }

  test_class_prefix_deferred() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {}
''');
    await _assertNeverConst(r'''
import 'a.dart' deferred as p;
p.A x;
''');
  }

  test_class_typeArguments() async {
    await _assertConst(r'''
List<int> x;
''');
  }

  test_class_typeArguments_notConst() async {
    await _assertPotentiallyConst(r'''
class A<T> {
  m() {
    List<T> x;
  }
}
''');
  }

  test_dynamic() async {
    await _assertConst(r'''
dynamic x;
''');
  }

  test_genericFunctionType() async {
    await _assertConst(r'''
int Function<T extends num, U>(int, bool) x;
''');
  }

  test_genericFunctionType_formalParameterType() async {
    await _assertPotentiallyConst(r'''
class A<T> {
  m() {
    Function(T) x;
  }
}
''');
  }

  test_genericFunctionType_returnType() async {
    await _assertPotentiallyConst(r'''
class A<T> {
  m() {
    T Function() x;
  }
}
''');
  }

  test_genericFunctionType_typeParameterBound() async {
    await _assertPotentiallyConst(r'''
class A<T> {
  m() {
    Function<U extends T>() x;
  }
}
''');
  }

  test_typeParameter() async {
    await _assertPotentiallyConst(r'''
class A<T> {
  m() {
    T x;
  }
}
''');
  }

  test_void() async {
    await _assertConst(r'''
void x;
''');
  }

  Future<void> _assertConst(String code) async {
    await resolveTestCode(code);
    var type = findNode.variableDeclarationList('x;').type;
    expect(isConstantTypeExpression(type), isTrue);
  }

  Future<void> _assertNeverConst(String code) async {
    await resolveTestCode(code);
    var type = findNode.variableDeclarationList('x;').type;
    expect(isConstantTypeExpression(type), isFalse);
  }

  Future<void> _assertPotentiallyConst(String code) async {
    await resolveTestCode(code);
    var type = findNode.variableDeclarationList('x;').type;
    expect(isConstantTypeExpression(type), isFalse);
  }
}

@reflectiveTest
class IsPotentiallyConstantTypeExpressionTest
    extends IsConstantTypeExpressionTest {
  @override
  test_typeParameter() async {
    await _assertConst(r'''
class A<T> {
  m() {
    T x;
  }
}
''');
  }

  test_typeParameter_nested() async {
    await _assertConst(r'''
class A<T> {
  m() {
    List<T> x;
  }
}
''');
  }

  @override
  Future<void> _assertConst(String code) async {
    await resolveTestCode(code);
    var type = findNode.variableDeclarationList('x;').type;
    expect(isPotentiallyConstantTypeExpression(type), isTrue);
  }

  @override
  Future<void> _assertPotentiallyConst(String code) async {
    await resolveTestCode(code);
    var type = findNode.variableDeclarationList('x;').type;
    expect(isPotentiallyConstantTypeExpression(type), isTrue);
  }
}

@reflectiveTest
class PotentiallyConstantTest extends PubPackageResolutionTest {
  test_adjacentStrings() async {
    await _assertConst(r'''
var x = 'a' 'b';
''', () => _xInitializer());
  }

  test_asExpression() async {
    await _assertConst(r'''
const a = 0;
var x = a as int;
''', () => _xInitializer());
  }

  test_asExpression_final() async {
    await _assertNotConst(r'''
final a = 0;
var x = a as int;
''', () => _xInitializer(), () => [findNode.simple('a as')]);
  }

  test_asExpression_typeParameter() async {
    await _assertNotConst(r'''
const a = 0;
class A<T> {
  m() {
    var x = a as T;
  }
}
''', () => _xInitializer(), () => [findNode.typeName('T;')]);
  }

  test_conditional() async {
    await _assertConst(r'''
const a = 0;
const b = 0;
const c = 0;
var x = a ? b : c;
''', () => _xInitializer());
  }

  test_conditional_final() async {
    await _assertNotConst(
        r'''
final a = 0;
final b = 0;
final c = 0;
var x = a ? b : c;
''',
        () => _xInitializer(),
        () => [
              findNode.simple('a ?'),
              findNode.simple('b :'),
              findNode.simple('c;')
            ]);
  }

  test_ifElement_then() async {
    await _assertConst(r'''
const a = 0;
const b = 0;
var x = const [if (a) b];
''', () => _xInitializer());
  }

  test_ifElement_then_final() async {
    await _assertNotConst(r'''
final a = 0;
final b = 0;
var x = const [if (a) b];
''', () => _xInitializer(),
        () => [findNode.simple('a)'), findNode.simple('b]')]);
  }

  test_ifElement_thenElse() async {
    await _assertConst(r'''
const a = 0;
const b = 0;
const c = 0;
var x = const [if (a) b else c];
''', () => _xInitializer());
  }

  test_instanceCreation() async {
    await _assertNotConst(r'''
class A {
  const A();
}

var x = new A(); // x
''', () => _xInitializer(), () => [findNode.instanceCreation('A(); // x')]);
  }

  test_instanceCreation_const() async {
    await _assertConst(r'''
class A {
  const A();
}

var x = const A();
''', () => _xInitializer());
  }

  test_isExpression() async {
    await _assertConst(r'''
const a = 0;
var x = a is int;
''', () => _xInitializer());
  }

  test_isExpression_final() async {
    await _assertNotConst(r'''
final a = 0;
var x = a is int;
''', () => _xInitializer(), () => [findNode.simple('a is')]);
  }

  test_isExpression_typeParameter() async {
    await _assertNotConst(r'''
const a = 0;
class A<T> {
  m() {
    var x = a is T;
  }
}
''', () => _xInitializer(), () => [findNode.typeName('T;')]);
  }

  test_listLiteral() async {
    await _assertConst(r'''
var x = const [0, 1, 2];
''', () => _xInitializer());
  }

  test_listLiteral_notConst() async {
    await _assertNotConst(r'''
var x = [0, 1, 2];
''', () => _xInitializer(), () => [findNode.listLiteral('0,')]);
  }

  test_listLiteral_notConst_element() async {
    await _assertNotConst(r'''
final a = 0;
final b = 1;
var x = const [a, b, 2];
''', () => _xInitializer(),
        () => [findNode.simple('a,'), findNode.simple('b,')]);
  }

  test_listLiteral_typeArgument() async {
    await _assertConst(r'''
var x = const <int>[0, 1, 2];
''', () => _xInitializer());
  }

  test_listLiteral_typeArgument_notConstType() async {
    await _assertNotConst(r'''
class A<T> {
  m() {
    var x = const <T>[0, 1, 2];
  }
}
''', () => _xInitializer(), () => [findNode.typeName('T>[0')]);
  }

  test_literal_bool() async {
    await _assertConst(r'''
var x = true;
''', () => _xInitializer());
  }

  test_literal_double() async {
    await _assertConst(r'''
var x = 1.2;
''', () => _xInitializer());
  }

  test_literal_int() async {
    await _assertConst(r'''
var x = 0;
''', () => _xInitializer());
  }

  test_literal_null() async {
    await _assertConst(r'''
var x = null;
''', () => _xInitializer());
  }

  test_literal_simpleString() async {
    await _assertConst(r'''
var x = '123';
''', () => _xInitializer());
  }

  test_literal_symbol() async {
    await _assertConst(r'''
var x = #a.b.c;
''', () => _xInitializer());
  }

  test_mapLiteral() async {
    await _assertConst(r'''
var x = const {0: 1};
''', () => _xInitializer());
  }

  test_mapLiteral_notConst() async {
    await _assertNotConst(r'''
var x = {0: 1};
''', () => _xInitializer(), () => [findNode.setOrMapLiteral('0: 1')]);
  }

  test_mapLiteral_notConst_key() async {
    await _assertNotConst(r'''
final a = 1;
final b = 2;
var x = const {0: 0, a: 1, b: 2};
''', () => _xInitializer(),
        () => [findNode.simple('a:'), findNode.simple('b:')]);
  }

  test_mapLiteral_notConst_value() async {
    await _assertNotConst(r'''
final a = 1;
final b = 2;
var x = const {0: 0, 1: a, 2: b};
''', () => _xInitializer(),
        () => [findNode.simple('a,'), findNode.simple('b}')]);
  }

  test_mapLiteral_typeArgument() async {
    await _assertConst(r'''
var x = const <int, int>{0: 0};
''', () => _xInitializer());
  }

  test_mapLiteral_typeArgument_notConstType() async {
    await _assertNotConst(r'''
class A<T> {
  m() {
    var x = const <T, T>{};
  }
}
''', () => _xInitializer(),
        () => [findNode.typeName('T,'), findNode.typeName('T>{')]);
  }

  test_methodInvocation_identical() async {
    await _assertConst(r'''
const a = 0;
const b = 0;
var x = identical(a, b);
''', () => _xInitializer());
  }

  test_methodInvocation_identical_final() async {
    await _assertNotConst(r'''
final a = 0;
final b = 0;
var x = identical(a, b);
''', () => _xInitializer(),
        () => [findNode.simple('a,'), findNode.simple('b)')]);
  }

  test_methodInvocation_name() async {
    await _assertNotConst(r'''
const a = 0;
const b = 0;
var x = foo(a, b);
''', () => _xInitializer(), () => [findNode.methodInvocation('foo')]);
  }

  test_methodInvocation_target() async {
    await _assertNotConst(r'''
var x = a.foo();
''', () => _xInitializer(), () => [findNode.methodInvocation('a.foo()')]);
  }

  test_namedExpression() async {
    await _assertConst(r'''
void f({a}) {}

var x = f(a: 0);
''', () => findNode.namedExpression('a: 0'));
  }

  test_parenthesizedExpression_const() async {
    await _assertConst(r'''
const a = 0;
var x = (a);
''', () => _xInitializer());
  }

  test_parenthesizedExpression_final() async {
    await _assertNotConst(r'''
final a = 0;
var x = (a);
''', () => _xInitializer(), () => [findNode.simple('a);')]);
  }

  test_postfixExpression() async {
    await _assertNotConst(r'''
const a = 0;
var x = a++;
''', () => _xInitializer(), () => [findNode.postfix('a++')]);
  }

  test_prefixedIdentifier_importPrefix_deferred() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
const a = 0;
''');
    await _assertNotConst(r'''
import 'a.dart' deferred as p;
var x = p.a + 1;
''', () => _xInitializer(), () => [findNode.prefixed('p.a')]);
  }

  test_prefixedIdentifier_importPrefix_function() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
void f() {}
''');
    await _assertConst(r'''
import 'a.dart' as p;
var x = p.f;
''', () => _xInitializer());
  }

  test_prefixedIdentifier_importPrefix_topVar() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
const a = 0;
''');
    await _assertConst(r'''
import 'a.dart' as p;
var x = p.a + 1;
''', () => _xInitializer());
  }

  test_prefixedIdentifier_length_const() async {
    await _assertConst(r'''
const a = 'abc';
var x = a.length;
''', () => _xInitializer());
  }

  test_prefixedIdentifier_length_final() async {
    await _assertNotConst(r'''
final a = 'abc';
var x = a.length;
''', () => _xInitializer(), () => [findNode.simple('a.')]);
  }

  test_prefixedIdentifier_method_instance() async {
    await _assertNotConst(r'''
class A {
  const A();
  m() {};
}

const a = const A();

var x = a.m;
''', () => _xInitializer(), () => [findNode.prefixed('a.m')]);
  }

  test_prefixedIdentifier_method_static() async {
    await _assertConst(r'''
class A {
  static m() {};
}

var x = A.m;
''', () => _xInitializer());
  }

  test_prefixedIdentifier_method_static_viaInstance() async {
    await _assertNotConst(r'''
class A {
  const A();
  static m() {};
}

const a = const A();

var x = a.m;
''', () => _xInitializer(), () => [findNode.prefixed('a.m')]);
  }

  test_prefixedIdentifier_prefix_variable() async {
    await _assertNotConst(r'''
class A {
  final a = 0;
  const A();
}

const a = const A();

var x = a.b + 1;
''', () => _xInitializer(), () => [findNode.prefixed('a.b + 1')]);
  }

  test_prefixedIdentifier_staticField_const() async {
    await _assertConst(r'''
class A {
  static const a = 0;
}
var x = A.a + 1;
''', () => _xInitializer());
  }

  test_prefixedIdentifier_staticField_final() async {
    await _assertNotConst(
      r'''
class A {
  static final a = 0;
}
var x = A.a + 1;
''',
      () => _xInitializer(),
      () => [findNode.prefixed('A.a')],
    );
  }

  test_prefixExpression_bang() async {
    await _assertConst(r'''
const a = 0;
var x = !a;
''', () => _xInitializer());
  }

  test_prefixExpression_minus() async {
    await _assertConst(r'''
const a = 0;
var x = -a;
''', () => _xInitializer());
  }

  test_prefixExpression_minus_final() async {
    await _assertNotConst(r'''
final a = 0;
var x = -a;
''', () => _xInitializer(), () => [findNode.simple('a;')]);
  }

  test_prefixExpression_plusPlus() async {
    await _assertNotConst(r'''
const a = 0;
var x = ++a;
''', () => _xInitializer(), () => [findNode.prefix('++a')]);
  }

  test_prefixExpression_tilde() async {
    await _assertConst(r'''
const a = 0;
var x = ~a;
''', () => _xInitializer());
  }

  test_propertyAccess_length_final() async {
    await _assertNotConst(r'''
final a = 'abc';
var x = (a).length;
''', () => _xInitializer(), () => [findNode.simple('a).')]);
  }

  test_propertyAccess_length_stringLiteral() async {
    await _assertConst(r'''
var x = 'abc'.length;
''', () => _xInitializer());
  }

  test_propertyAccess_staticField_withPrefix_const() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  static const a = 0;
}
''');
    await _assertConst(r'''
import 'a.dart' as p;
var x = p.A.a + 1;
''', () => _xInitializer());
  }

  test_propertyAccess_staticField_withPrefix_deferred() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  static const a = 0;
}
''');
    await _assertNotConst(r'''
import 'a.dart' deferred as p;
var x = p.A.a + 1;
''', () => _xInitializer(), () => [findNode.propertyAccess('p.A.a')]);
  }

  test_propertyAccess_staticField_withPrefix_final() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  static final a = 0;
}
''');
    await _assertNotConst(r'''
import 'a.dart' as p;
var x = p.A.a + 1;
''', () => _xInitializer(), () => [findNode.simple('a + 1')]);
  }

  test_propertyAccess_target_instanceCreation() async {
    await _assertNotConst(r'''
class A {
  final a = 0;
}

var x = A().a + 1;
''', () => _xInitializer(), () => [findNode.propertyAccess('A().a')]);
  }

  test_propertyAccess_target_variable() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  final a = 0;
  const A();
}

const a = const A();
''');
    await _assertNotConst(r'''
import 'a.dart' as p;

var x = p.a.b + 1;
''', () => _xInitializer(), () => [findNode.propertyAccess('p.a.b + 1')]);
  }

  test_setLiteral() async {
    await _assertConst(r'''
var x = const {0, 1, 2};
''', () => _xInitializer());
  }

  test_setLiteral_notConst() async {
    await _assertNotConst(r'''
var x = {0, 1, 2};
''', () => _xInitializer(), () => [findNode.setOrMapLiteral('0,')]);
  }

  test_setLiteral_notConst_element() async {
    await _assertNotConst(r'''
final a = 0;
final b = 1;
var x = const {a, b, 2};
''', () => _xInitializer(),
        () => [findNode.simple('a,'), findNode.simple('b,')]);
  }

  test_setLiteral_typeArgument() async {
    await _assertConst(r'''
var x = const <int>{0, 1, 2};
''', () => _xInitializer());
  }

  test_setLiteral_typeArgument_notConstType() async {
    await _assertNotConst(r'''
class A<T> {
  m() {
    var x = const <T>{0, 1, 2};
  }
}
''', () => _xInitializer(), () => [findNode.typeName('T>{0')]);
  }

  test_simpleIdentifier_function() async {
    await _assertConst(r'''
var x = f;

void f() {}
''', () => _xInitializer());
  }

  test_simpleIdentifier_localVar_const() async {
    await _assertConst(r'''
main() {
  const a = 0;
  var x = a + 1;
}
''', () => _xInitializer());
  }

  test_simpleIdentifier_localVar_final() async {
    await _assertNotConst(
      r'''
main() {
  final a = 0;
  var x = a + 1;
}
''',
      () => _xInitializer(),
      () => [findNode.simple('a +')],
    );
  }

  test_simpleIdentifier_method_static() async {
    await _assertConst(r'''
class A {
  static m() {};

  final Object f;

  const A() : f = m; // ref
}
''', () => findNode.simple('m; // ref'));
  }

  test_simpleIdentifier_parameterOfConstConstructor_inBody() async {
    await _assertNotConst(
      r'''
class C {
  const C(int a) {
    var x = a + 1;
  }
}
''',
      () => _xInitializer(),
      () => [findNode.simple('a +')],
    );
  }

  test_simpleIdentifier_parameterOfConstConstructor_inInitializer() async {
    await _assertConst(r'''
class C {
  final int f;
  const C(int a) : f = a + 1;
}
''', () => findNode.constructorFieldInitializer('f =').expression);
  }

  test_simpleIdentifier_parameterOfConstConstructor_notConst() async {
    await _assertNotConst(
      r'''
class C {
  final int f;
  C(int a) : f = a + 1;
}
''',
      () => findNode.constructorFieldInitializer('f =').expression,
      () => [findNode.simple('a +')],
    );
  }

  test_simpleIdentifier_topVar_const() async {
    await _assertConst(r'''
const a = 0;
var x = a + 1;
''', () => _xInitializer());
  }

  test_simpleIdentifier_topVar_final() async {
    await _assertNotConst(
      r'''
final a = 0;
var x = a + 1;
''',
      () => _xInitializer(),
      () => [findNode.simple('a +')],
    );
  }

  test_simpleIdentifier_type_class() async {
    await _assertConst(r'''
var x = int;
''', () => _xInitializer());
  }

  test_spreadElement() async {
    await _assertConst(r'''
const a = [0, 1, 2];
var x = const [...a];
''', () => _xInitializer());
  }

  test_spreadElement_final() async {
    await _assertNotConst(r'''
final a = [0, 1, 2];
var x = const [...a];
''', () => _xInitializer(), () => [findNode.simple('a];')]);
  }

  test_stringInterpolation_topVar_const() async {
    await _assertConst(r'''
const a = 0;
var x = 'a $a b';
''', () => _xInitializer());
  }

  test_stringInterpolation_topVar_final() async {
    await _assertNotConst(
      r'''
final a = 0;
var x = 'a $a b';
''',
      () => _xInitializer(),
      () => [findNode.simple('a b')],
    );
  }

  test_stringLiteral() async {
    await _assertConst(r'''
var x = 'a';
''', () => _xInitializer());
  }

  _assertConst(String code, AstNode Function() getNode) async {
    await resolveTestCode(code);
    var node = getNode();
    var notConstList = getNotPotentiallyConstants(
      node,
      isNonNullableByDefault: typeSystem.isNonNullableByDefault,
    );
    expect(notConstList, isEmpty);
  }

  _assertNotConst(String code, AstNode Function() getNode,
      List<AstNode> Function() getNotConstList) async {
    await resolveTestCode(code);
    var node = getNode();
    var notConstList = getNotPotentiallyConstants(
      node,
      isNonNullableByDefault: typeSystem.isNonNullableByDefault,
    );

    var expectedNotConst = getNotConstList();
    expect(notConstList, unorderedEquals(expectedNotConst));
  }

  Expression _xInitializer() {
    return findNode.variableDeclaration('x = ').initializer;
  }
}

@reflectiveTest
class PotentiallyConstantWithNullSafetyTest extends PotentiallyConstantTest
    with WithNullSafetyMixin {
  @override
  test_asExpression_typeParameter() async {
    await _assertConst(r'''
const a = 0;
class A<T> {
  m() {
    var x = a as T;
  }
}
''', () => _xInitializer());
  }

  test_asExpression_typeParameter_nested() async {
    await _assertConst(r'''
const a = 0;
class A<T> {
  m() {
    var x = a as List<T>;
  }
}
''', () => _xInitializer());
  }

  @override
  test_isExpression_typeParameter() async {
    await _assertConst(r'''
const a = 0;
class A<T> {
  m() {
    var x = a is T;
  }
}
''', () => _xInitializer());
  }

  test_isExpression_typeParameter_nested() async {
    await _assertConst(r'''
const a = 0;
class A<T> {
  m() {
    var x = a is List<T>;
  }
}
''', () => _xInitializer());
  }
}
