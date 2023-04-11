// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';
import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDriverResolutionTest);
  });
}

final isDynamicType = TypeMatcher<DynamicTypeImpl>();

final isNeverType = TypeMatcher<NeverTypeImpl>();

final isVoidType = TypeMatcher<VoidTypeImpl>();

/// Integration tests for resolution.
@reflectiveTest
class AnalysisDriverResolutionTest extends PubPackageResolutionTest
    with ElementsTypesMixin {
  void assertDeclaredVariableType(SimpleIdentifier node, String expected) {
    var element = node.staticElement as VariableElement;
    assertType(element.type, expected);
  }

  /// Test that [argumentList] has exactly two type items `int` and `double`.
  void assertTypeArguments(
      TypeArgumentList argumentList, List<InterfaceType> expectedTypes) {
    expect(argumentList.arguments, hasLength(expectedTypes.length));
    for (int i = 0; i < expectedTypes.length; i++) {
      _assertNamedTypeSimple(argumentList.arguments[i], expectedTypes[i]);
    }
  }

  void assertUnresolvedInvokeType(DartType invokeType) {
    expect(invokeType, isDynamicType);
  }

  /// Creates a function that checks that an expression is a reference to a top
  /// level variable with the given [name].
  void Function(Expression) checkTopVarRef(String name) {
    return (Expression e) {
      TopLevelVariableElement variable = _getTopLevelVariable(result, name);
      SimpleIdentifier node = e as SimpleIdentifier;
      expect(node.staticElement, same(variable.getter));
      expect(node.staticType, variable.type);
    };
  }

  /// Creates a function that checks that an expression is a named argument
  /// that references a top level variable with the given [name], where the
  /// name of the named argument is undefined.
  void Function(Expression) checkTopVarUndefinedNamedRef(String name) {
    return (Expression e) {
      TopLevelVariableElement variable = _getTopLevelVariable(result, name);
      NamedExpression named = e as NamedExpression;
      expect(named.staticType, variable.type);

      SimpleIdentifier nameIdentifier = named.name.label;
      expect(nameIdentifier.staticElement, isNull);
      expect(nameIdentifier.staticType, isNull);

      var expression = named.expression as SimpleIdentifier;
      expect(expression.staticElement, same(variable.getter));
      expect(expression.staticType, variable.type);
    };
  }

  test_invalid_catch_parameters_3() async {
    addTestFile(r'''
main() {
  try { } catch (x, y, z) { }
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    assertType(
      findNode.catchClauseParameter('x,').declaredElement!.type,
      'Object',
    );
    assertType(
      findNode.catchClauseParameter('y,').declaredElement!.type,
      'StackTrace',
    );
  }

  test_invalid_catch_parameters_empty() async {
    addTestFile(r'''
main() {
  try { } catch () { }
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
  }

  test_invalid_catch_parameters_named_stack() async {
    addTestFile(r'''
main() {
  try { } catch (e, {s}) { }
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    assertType(
      findNode.catchClauseParameter('e,').declaredElement!.type,
      'Object',
    );
    assertType(
      findNode.catchClauseParameter('s}').declaredElement!.type,
      'StackTrace',
    );
  }

  test_invalid_catch_parameters_optional_stack() async {
    addTestFile(r'''
main() {
  try { } catch (e, [s]) { }
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    assertType(
      findNode.catchClauseParameter('e,').declaredElement!.type,
      'Object',
    );
    assertType(
      findNode.catchClauseParameter('s]').declaredElement!.type,
      'StackTrace',
    );
  }

  test_invalid_const_constructor_initializer_field_multiple() async {
    addTestFile(r'''
var a = 0;
class A {
  final x = 0;
  const A() : x = a;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x = a');
    assertElement(xRef, findElement.field('x'));

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_const_throw_local() async {
    addTestFile(r'''
main() {
  const c = throw 42;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var throwExpression = findNode.throw_('throw 42;');
    expect(throwExpression.staticType, isNeverType);
    assertType(throwExpression.expression, 'int');
  }

  test_invalid_const_throw_topLevel() async {
    addTestFile(r'''
const c = throw 42;
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var throwExpression = findNode.throw_('throw 42;');
    expect(throwExpression.staticType, isNeverType);
    assertType(throwExpression.expression, 'int');
  }

  test_invalid_constructor_initializer_field_class() async {
    addTestFile(r'''
var a = 0;
class A {
  A() : X = a;
}
class X {}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('X = ');
    assertElementNull(xRef);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_constructor_initializer_field_getter() async {
    addTestFile(r'''
var a = 0;
class A {
  A() : x = a;
  int get x => 0;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x = ');
    assertElement(xRef, findElement.field('x'));

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_constructor_initializer_field_importPrefix() async {
    addTestFile(r'''
import 'dart:async' as x;
var a = 0;
class A {
  A() : x = a;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x = ');
    assertElementNull(xRef);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_constructor_initializer_field_method() async {
    addTestFile(r'''
var a = 0;
class A {
  A() : x = a;
  void x() {}
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x = ');
    assertElementNull(xRef);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_constructor_initializer_field_setter() async {
    addTestFile(r'''
var a = 0;
class A {
  A() : x = a;
  set x(_) {}
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x = ');
    assertElement(xRef, findElement.field('x'));

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_constructor_initializer_field_topLevelFunction() async {
    addTestFile(r'''
var a = 0;
class A {
  A() : x = a;
}
void x() {}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x = ');
    assertElementNull(xRef);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_constructor_initializer_field_topLevelVar() async {
    addTestFile(r'''
var a = 0;
class A {
  A() : x = a;
}
int x;
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x = ');
    assertElementNull(xRef);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_constructor_initializer_field_typeParameter() async {
    addTestFile(r'''
var a = 0;
class A<T> {
  A() : T = a;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var tRef = findNode.simple('T = ');
    assertElementNull(tRef);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_constructor_initializer_field_unresolved() async {
    addTestFile(r'''
var a = 0;
class A {
  A() : x = a;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_fieldInitializer_field() async {
    addTestFile(r'''
class C {
  final int a = 0;
  final int b = a + 1;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('a + 1');
    assertElement(aRef, findElement.getter('a'));
    assertType(aRef, 'int');
  }

  test_invalid_fieldInitializer_getter() async {
    addTestFile(r'''
class C {
  int get a => 0;
  final int b = a + 1;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('a + 1');
    assertElement(aRef, findElement.getter('a'));
    assertType(aRef, 'int');
  }

  test_invalid_fieldInitializer_method() async {
    addTestFile(r'''
class C {
  int a() => 0;
  final int b = a + 1;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('a + 1');
    assertElement(aRef, findElement.method('a'));
    assertType(aRef, 'int Function()');
  }

  test_invalid_fieldInitializer_this() async {
    addTestFile(r'''
class C {
  final b = this;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var thisRef = findNode.this_('this');
    assertType(thisRef, 'C');
  }

  test_invalid_generator_async_return_blockBody() async {
    addTestFile(r'''
int a = 0;
f() async* {
  return a;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_generator_async_return_expressionBody() async {
    addTestFile(r'''
int a = 0;
f() async* => a;
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_generator_sync_return_blockBody() async {
    addTestFile(r'''
int a = 0;
f() sync* {
  return a;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_generator_sync_return_expressionBody() async {
    addTestFile(r'''
int a = 0;
f() sync* => a;
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_getter_parameters() async {
    addTestFile(r'''
get m(int a, double b) {
  a;
  b;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.parameter('a'));
    assertType(aRef, 'int');

    var bRef = findNode.simple('b;');
    assertElement(bRef, findElement.parameter('b'));
    assertType(bRef, 'double');
  }

  @failingTest
  test_invalid_instanceCreation_abstract() async {
    addTestFile(r'''
abstract class C<T> {
  C(T a);
  C.named(T a);
  C.named2();
}
var a = 0;
var b = true;
main() {
  new C(a);
  new C.named(b);
  new C<double>.named2();
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var c = findElement.class_('C');

    {
      var creation = findNode.instanceCreation('new C(a)');
      assertType(creation, 'C<int>');

      ConstructorName constructorName = creation.constructorName;
      expect(constructorName.name, isNull);

      NamedType type = constructorName.type;
      expect(type.typeArguments, isNull);
      assertElement(type.name, c);
      assertTypeNull(type.name);

      var aRef = creation.argumentList.arguments[0] as SimpleIdentifier;
      assertElement(aRef, findElement.topGet('a'));
      assertType(aRef, 'int');
    }

    {
      var creation = findNode.instanceCreation('new C.named(b)');
      assertType(creation, 'C<bool>');

      ConstructorName constructorName = creation.constructorName;
      expect(constructorName.name!.name, 'named');

      NamedType type = constructorName.type;
      expect(type.typeArguments, isNull);
      assertElement(type.name, c);
      assertType(type.name, 'C<bool>');

      var bRef = creation.argumentList.arguments[0] as SimpleIdentifier;
      assertElement(bRef, findElement.topGet('b'));
      assertType(bRef, 'bool');
    }

    {
      var creation = findNode.instanceCreation('new C<double>.named2()');
      assertType(creation, 'C<double>');

      ConstructorName constructorName = creation.constructorName;
      expect(constructorName.name!.name, 'named2');

      NamedType type = constructorName.type;
      assertTypeArguments(type.typeArguments!, [doubleType]);
      assertElement(type.name, c);
      assertType(type.name, 'C<double>');
    }
  }

  test_invalid_instanceCreation_arguments_named() async {
    addTestFile(r'''
class C {
  C();
}
var a = 0;
main() {
  new C(x: a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var classElement = findElement.class_('C');

    var creation = findNode.instanceCreation('new C(x: a)');
    _assertConstructorInvocation(creation, classElement);

    var argument = creation.argumentList.arguments[0] as NamedExpression;
    assertElementNull(argument.name.label);
    var aRef = argument.expression;
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_instanceCreation_arguments_required_01() async {
    addTestFile(r'''
class C {
  C();
}
var a = 0;
main() {
  new C(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var classElement = findElement.class_('C');

    var creation = findNode.instanceCreation('new C(a)');
    _assertConstructorInvocation(creation, classElement);

    var aRef = creation.argumentList.arguments[0];
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_instanceCreation_arguments_required_21() async {
    addTestFile(r'''
class C {
  C(a, b);
}
var a = 0;
main() {
  new C(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var classElement = findElement.class_('C');

    var creation = findNode.instanceCreation('new C(a)');
    _assertConstructorInvocation(creation, classElement);

    var aRef = creation.argumentList.arguments[0];
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_instanceCreation_constOfNotConst_factory() async {
    addTestFile(r'''
class C {
  factory C(x) => throw 0;
}

var a = 0;
main() {
  const C(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var classElement = findElement.class_('C');

    var creation = findNode.instanceCreation('const C(a)');
    _assertConstructorInvocation(creation, classElement);

    var aRef = creation.argumentList.arguments[0];
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_instanceCreation_constOfNotConst_generative() async {
    addTestFile(r'''
class C {
  C(x);
}

var a = 0;
main() {
  const C(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var classElement = findElement.class_('C');

    var creation = findNode.instanceCreation('const C(a)');
    _assertConstructorInvocation(creation, classElement);

    var aRef = creation.argumentList.arguments[0];
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  @failingTest
  test_invalid_instanceCreation_prefixAsType() async {
    addTestFile(r'''
import 'dart:math' as p;
int a;
main() {
  new p(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    final import = findNode.import('dart:math').element!;

    var pRef = findNode.simple('p(a)');
    assertElement(pRef, import.prefix);
    assertTypeDynamic(pRef);

    var aRef = findNode.simple('a);');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_invocation_arguments_instance_method() async {
    addTestFile(r'''
class C {
  void m() {}
}
var a = 0;
main(C c) {
  c.m(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var m = findElement.method('m');

    var invocation = findNode.methodInvocation('m(a)');
    assertElement(invocation.methodName, m);
    assertType(invocation.methodName, 'void Function()');
    assertType(invocation, 'void');

    var aRef = invocation.argumentList.arguments[0];
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_invocation_arguments_static_method() async {
    addTestFile(r'''
class C {
  static void m() {}
}
var a = 0;
main() {
  C.m(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var m = findElement.method('m');

    var invocation = findNode.methodInvocation('m(a)');
    assertElement(invocation.methodName, m);
    assertType(invocation.methodName, 'void Function()');
    assertType(invocation, 'void');

    var aRef = invocation.argumentList.arguments[0];
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_invocation_arguments_static_redirectingConstructor() async {
    addTestFile(r'''
class C {
  factory C() = C.named;
  C.named();
}

int a;
main() {
  new C(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var classElement = findElement.class_('C');

    var creation = findNode.instanceCreation('new C(a)');
    _assertConstructorInvocation(creation, classElement);

    var aRef = creation.argumentList.arguments[0];
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_invocation_arguments_static_topLevelFunction() async {
    addTestFile(r'''
void f() {}
var a = 0;
main() {
  f(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var f = findElement.function('f');

    var invocation = findNode.methodInvocation('f(a)');
    assertElement(invocation.methodName, f);
    assertType(invocation.methodName, 'void Function()');
    assertType(invocation, 'void');

    var aRef = invocation.argumentList.arguments[0];
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_invocation_prefixAsMethodName() async {
    addTestFile(r'''
import 'dart:math' as p;
int a;
main() {
  p(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    final import = findNode.import('dart:math').element!;

    var invocation = findNode.methodInvocation('p(a)');
    expect(invocation.staticType, isDynamicType);
    assertUnresolvedInvokeType(invocation.staticInvokeType!);

    var pRef = invocation.methodName;
    assertElement(pRef, import.prefix?.element);
    assertTypeDynamic(pRef);

    var aRef = findNode.simple('a);');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  @failingTest
  test_invalid_nonTypeAsType_class_constructor() async {
    addTestFile(r'''
class A {
  A.T();
}
main() {
  A.T v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('A.T v;');
    assertElement(aRef, findElement.class_('A'));
    assertTypeDynamic(aRef);

    var tRef = findNode.simple('T v;');
    assertElement(tRef, null);
    assertTypeDynamic(tRef);
  }

  @failingTest
  test_invalid_nonTypeAsType_class_instanceField() async {
    addTestFile(r'''
class A {
  int T;
}
main() {
  A.T v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('A.T v;');
    assertElement(aRef, findElement.class_('A'));
    assertTypeDynamic(aRef);

    var tRef = findNode.simple('T v;');
    assertElement(tRef, null);
    assertTypeDynamic(tRef);
  }

  @failingTest
  test_invalid_nonTypeAsType_class_instanceMethod() async {
    addTestFile(r'''
class A {
  int T() => 0;
}
main() {
  A.T v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('A.T v;');
    assertElement(aRef, findElement.class_('A'));
    assertTypeDynamic(aRef);

    var tRef = findNode.simple('T v;');
    assertElement(tRef, null);
    assertTypeDynamic(tRef);
  }

  @failingTest
  test_invalid_nonTypeAsType_class_staticField() async {
    addTestFile(r'''
class A {
  static int T;
}
main() {
  A.T v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('A.T v;');
    assertElement(aRef, findElement.class_('A'));
    assertTypeDynamic(aRef);

    var tRef = findNode.simple('T v;');
    assertElement(tRef, null);
    assertTypeDynamic(tRef);
  }

  @failingTest
  test_invalid_nonTypeAsType_class_staticMethod() async {
    addTestFile(r'''
class A {
  static int T() => 0;
}
main() {
  A.T v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('A.T v;');
    assertElement(aRef, findElement.class_('A'));
    assertTypeDynamic(aRef);

    var tRef = findNode.simple('T v;');
    assertElement(tRef, null);
    assertTypeDynamic(tRef);
  }

  @failingTest
  test_invalid_nonTypeAsType_topLevelFunction() async {
    addTestFile(r'''
int T() => 0;
main() {
  T v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var tRef = findNode.simple('T v;');
    assertElement(tRef, findElement.topFunction('T'));
    assertTypeDynamic(tRef);
  }

  @failingTest
  test_invalid_nonTypeAsType_topLevelFunction_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
int T() => 0;
''');
    addTestFile(r'''
import 'a.dart' as p;
main() {
  p.T v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    final import = findNode.import('a.dart').element!;
    var tElement = import.importedLibrary!.publicNamespace.get('T');

    var prefixedName = findNode.prefixed('p.T');
    assertTypeDynamic(prefixedName);

    var pRef = prefixedName.prefix;
    assertElement(pRef, import.prefix);
    expect(pRef.staticType, null);

    var tRef = prefixedName.identifier;
    assertElement(tRef, tElement);
    assertTypeDynamic(tRef);

    var namedType = prefixedName.parent as NamedType;
    expect(namedType.type, isDynamicType);
  }

  @failingTest
  test_invalid_nonTypeAsType_topLevelVariable() async {
    addTestFile(r'''
int T;
main() {
  T v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var tRef = findNode.simple('T v;');
    assertElement(tRef, findElement.topGet('T'));
    assertTypeDynamic(tRef);
  }

  @failingTest
  test_invalid_nonTypeAsType_topLevelVariable_name() async {
    addTestFile(r'''
int A;
main() {
  A.T v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('A.T v;');
    assertElement(aRef, findElement.topGet('A'));
    assertTypeDynamic(aRef);

    var tRef = findNode.simple('T v;');
    assertElement(tRef, null);
    assertTypeDynamic(tRef);
  }

  @failingTest
  test_invalid_nonTypeAsType_topLevelVariable_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
int T;
''');
    addTestFile(r'''
import 'a.dart' as p;
main() {
  p.T v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    final import = findNode.import('a.dart').element!;
    var tElement = import.importedLibrary!.publicNamespace.get('T');

    var prefixedName = findNode.prefixed('p.T');
    assertTypeDynamic(prefixedName);

    var pRef = prefixedName.prefix;
    assertElement(pRef, import.prefix);
    expect(pRef.staticType, null);

    var tRef = prefixedName.identifier;
    assertElement(tRef, tElement);
    assertTypeDynamic(tRef);

    var namedType = prefixedName.parent as NamedType;
    expect(namedType.type, isDynamicType);
  }

  @failingTest
  test_invalid_nonTypeAsType_typeParameter_name() async {
    addTestFile(r'''
main<T>() {
  T.U v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var tRef = findNode.simple('T.U v;');
    var tElement = findNode.typeParameter('T>()').declaredElement!;
    assertElement(tRef, tElement);
    assertTypeDynamic(tRef);
  }

  @failingTest
  test_invalid_nonTypeAsType_unresolved_name() async {
    addTestFile(r'''
main() {
  T.U v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var tRef = findNode.simple('T.U v;');
    assertElementNull(tRef);
    assertTypeDynamic(tRef);
  }

  test_invalid_rethrow() async {
    addTestFile('''
main() {
  rethrow;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var rethrowExpression = findNode.rethrow_('rethrow;');
    expect(rethrowExpression.staticType, isNeverType);
  }

  test_invalid_tryCatch_1() async {
    addTestFile(r'''
main() {
  try {}
  catch String catch (e) {}
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
  }

  test_invalid_tryCatch_2() async {
    addTestFile(r'''
main() {
  try {}
  catch catch (e) {}
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
  }

  test_isExpression() async {
    await assertNoErrorsInCode(r'''
void f(var a) {
  a is num;
}
''');

    var isExpression = findNode.isExpression('a is num');
    expect(isExpression.notOperator, isNull);
    expect(isExpression.staticType, typeProvider.boolType);

    var target = isExpression.expression as SimpleIdentifier;
    expect(target.staticElement, findElement.parameter('a'));
    expect(target.staticType, dynamicType);

    var numName = isExpression.type as NamedType;
    expect(numName.name.staticElement, typeProvider.numType.element);
    expect(numName.name.staticType, isNull);
  }

  test_isExpression_not() async {
    await assertNoErrorsInCode(r'''
void f(var a) {
  a is! num;
}
''');

    var isExpression = findNode.isExpression('a is! num');
    expect(isExpression.notOperator, isNotNull);
    expect(isExpression.staticType, typeProvider.boolType);

    var target = isExpression.expression as SimpleIdentifier;
    expect(target.staticElement, findElement.parameter('a'));
    expect(target.staticType, dynamicType);

    var numName = isExpression.type as NamedType;
    expect(numName.name.staticElement, typeProvider.numType.element);
    expect(numName.name.staticType, isNull);
  }

  test_label_while() async {
    addTestFile(r'''
main() {
  myLabel:
  while (true) {
    continue myLabel;
    break myLabel;
  }
}
''');
    await resolveTestFile();
    List<Statement> statements = _getMainStatements(result);

    var statement = statements[0] as LabeledStatement;

    Label label = statement.labels.single;
    var labelElement = label.label.staticElement as LabelElement;

    var whileStatement = statement.statement as WhileStatement;
    var whileBlock = whileStatement.body as Block;

    var continueStatement = whileBlock.statements[0] as ContinueStatement;
    expect(continueStatement.label!.staticElement, same(labelElement));
    expect(continueStatement.label!.staticType, isNull);

    var breakStatement = whileBlock.statements[1] as BreakStatement;
    expect(breakStatement.label!.staticElement, same(labelElement));
    expect(breakStatement.label!.staticType, isNull);
  }

  test_listLiteral_01() async {
    addTestFile(r'''
main() {
  var v = [];
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var literal = findNode.listLiteral('[];');
    expect(literal.typeArguments, isNull);
    assertType(literal, 'List<dynamic>');
  }

  test_listLiteral_02() async {
    addTestFile(r'''
main() {
  var v = <>[];
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var literal = findNode.listLiteral('[];');
    expect(literal.typeArguments, isNotNull);
    assertType(literal, 'List<dynamic>');
  }

  test_listLiteral_2() async {
    addTestFile(r'''
main() {
  var v = <int, double>[];
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var literal = findNode.listLiteral('<int, double>[]');
    assertType(literal, 'List<dynamic>');

    var intRef = findNode.simple('int, double');
    assertElement(intRef, intElement);
    assertTypeNull(intRef);

    var doubleRef = findNode.simple('double>[]');
    assertElement(doubleRef, doubleElement);
    assertTypeNull(doubleRef);
  }

  test_local_parameter() async {
    await assertNoErrorsInCode(r'''
void main(List<String> p) {
  p;
}
''');

    var main = result.unit.declarations[0] as FunctionDeclaration;
    List<Statement> statements = _getMainStatements(result);

    // (int p)
    VariableElement pElement = main.declaredElement!.parameters[0];
    expect(pElement.type, listNone(typeProvider.stringType));

    // p;
    {
      var statement = statements[0] as ExpressionStatement;
      var identifier = statement.expression as SimpleIdentifier;
      expect(identifier.staticElement, pElement);
      expect(identifier.staticType, listNone(typeProvider.stringType));
    }
  }

  test_local_parameter_ofLocalFunction() async {
    addTestFile(r'''
void main() {
  void f(int a) {
    a;
    void g(double b) {
      b;
    }
  }
}
''');
    await resolveTestFile();

    List<Statement> mainStatements = _getMainStatements(result);

    // f(int a) {}
    var fStatement = mainStatements[0] as FunctionDeclarationStatement;
    FunctionDeclaration fNode = fStatement.functionDeclaration;
    FunctionExpression fExpression = fNode.functionExpression;
    var fElement = fNode.declaredElement as FunctionElement;
    ParameterElement aElement = fElement.parameters[0];
    _assertSimpleParameter(
        fExpression.parameters!.parameters[0] as SimpleFormalParameter,
        aElement,
        name: 'a',
        offset: 27,
        kind: ParameterKind.REQUIRED,
        type: typeProvider.intType);

    var fBody = fExpression.body as BlockFunctionBody;
    List<Statement> fStatements = fBody.block.statements;

    // a;
    var aStatement = fStatements[0] as ExpressionStatement;
    var aNode = aStatement.expression as SimpleIdentifier;
    expect(aNode.staticElement, same(aElement));
    expect(aNode.staticType, typeProvider.intType);

    // g(double b) {}
    var gStatement = fStatements[1] as FunctionDeclarationStatement;
    FunctionDeclaration gNode = gStatement.functionDeclaration;
    FunctionExpression gExpression = gNode.functionExpression;
    var gElement = gNode.declaredElement as FunctionElement;
    ParameterElement bElement = gElement.parameters[0];
    _assertSimpleParameter(
        gExpression.parameters!.parameters[0] as SimpleFormalParameter,
        bElement,
        name: 'b',
        offset: 57,
        kind: ParameterKind.REQUIRED,
        type: typeProvider.doubleType);

    var gBody = gExpression.body as BlockFunctionBody;
    List<Statement> gStatements = gBody.block.statements;

    // b;
    var bStatement = gStatements[0] as ExpressionStatement;
    var bNode = bStatement.expression as SimpleIdentifier;
    expect(bNode.staticElement, same(bElement));
    expect(bNode.staticType, typeProvider.doubleType);
  }

  test_local_type_parameter_reference_as_expression() async {
    addTestFile('''
void main() {
  void f<T>(T x) {
    T;
  }
  f(1);
}
''');
    await resolveTestFile();

    var mainStatements = _getMainStatements(result);
    var fDeclaration = mainStatements[0] as FunctionDeclarationStatement;
    var fElement = fDeclaration.functionDeclaration.declaredElement!;
    var tElement = fElement.typeParameters[0];
    var body = fDeclaration.functionDeclaration.functionExpression.body
        as BlockFunctionBody;
    var bodyStatement = body.block.statements[0] as ExpressionStatement;
    var tReference = bodyStatement.expression as SimpleIdentifier;
    assertElement(tReference, tElement);
    assertType(tReference, 'Type');
  }

  test_local_type_parameter_reference_function_named_parameter_type() async {
    addTestFile('''
void main() {
  void f<T>(T x) {
    void Function({T t}) g = null;
  }
  f(1);
}
''');
    await resolveTestFile();

    var mainStatements = _getMainStatements(result);
    var fDeclaration = mainStatements[0] as FunctionDeclarationStatement;
    var fElement = fDeclaration.functionDeclaration.declaredElement!;
    var tElement = fElement.typeParameters[0];
    var body = fDeclaration.functionDeclaration.functionExpression.body
        as BlockFunctionBody;
    var gDeclaration = body.block.statements[0] as VariableDeclarationStatement;
    var gType = gDeclaration.variables.type as GenericFunctionType;
    var gTypeType = gType.type as FunctionType;
    var gTypeParameterType =
        gTypeType.namedParameterTypes['t'] as TypeParameterType;
    expect(gTypeParameterType.element, same(tElement));
    var gParameterType =
        ((gType.parameters.parameters[0] as DefaultFormalParameter).parameter
                as SimpleFormalParameter)
            .type as NamedType;
    var tReference = gParameterType.name;
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_local_type_parameter_reference_function_normal_parameter_type() async {
    addTestFile('''
void main() {
  void f<T>(T x) {
    void Function(T) g = null;
  }
  f(1);
}
''');
    await resolveTestFile();

    var mainStatements = _getMainStatements(result);
    var fDeclaration = mainStatements[0] as FunctionDeclarationStatement;
    var fElement = fDeclaration.functionDeclaration.declaredElement!;
    var tElement = fElement.typeParameters[0];
    var body = fDeclaration.functionDeclaration.functionExpression.body
        as BlockFunctionBody;
    var gDeclaration = body.block.statements[0] as VariableDeclarationStatement;
    var gType = gDeclaration.variables.type as GenericFunctionType;
    var gTypeType = gType.type as FunctionType;
    var gTypeParameterType =
        gTypeType.normalParameterTypes[0] as TypeParameterType;
    expect(gTypeParameterType.element, same(tElement));
    var gParameterType =
        (gType.parameters.parameters[0] as SimpleFormalParameter).type
            as NamedType;
    var tReference = gParameterType.name;
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_local_type_parameter_reference_function_optional_parameter_type() async {
    addTestFile('''
void main() {
  void f<T>(T x) {
    void Function([T]) g = null;
  }
  f(1);
}
''');
    await resolveTestFile();

    var mainStatements = _getMainStatements(result);
    var fDeclaration = mainStatements[0] as FunctionDeclarationStatement;
    var fElement = fDeclaration.functionDeclaration.declaredElement!;
    var tElement = fElement.typeParameters[0];
    var body = fDeclaration.functionDeclaration.functionExpression.body
        as BlockFunctionBody;
    var gDeclaration = body.block.statements[0] as VariableDeclarationStatement;
    var gType = gDeclaration.variables.type as GenericFunctionType;
    var gTypeType = gType.type as FunctionType;
    var gTypeParameterType =
        gTypeType.optionalParameterTypes[0] as TypeParameterType;
    expect(gTypeParameterType.element, same(tElement));
    var gParameterType =
        ((gType.parameters.parameters[0] as DefaultFormalParameter).parameter
                as SimpleFormalParameter)
            .type as NamedType;
    var tReference = gParameterType.name;
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_local_type_parameter_reference_function_return_type() async {
    addTestFile('''
void main() {
  void f<T>(T x) {
    T Function() g = () => x;
  }
  f(1);
}
''');
    await resolveTestFile();

    var mainStatements = _getMainStatements(result);
    var fDeclaration = mainStatements[0] as FunctionDeclarationStatement;
    var fElement = fDeclaration.functionDeclaration.declaredElement!;
    var tElement = fElement.typeParameters[0];
    var body = fDeclaration.functionDeclaration.functionExpression.body
        as BlockFunctionBody;
    var gDeclaration = body.block.statements[0] as VariableDeclarationStatement;
    var gType = gDeclaration.variables.type as GenericFunctionType;
    var gTypeType = gType.type as FunctionType;
    var gTypeReturnType = gTypeType.returnType as TypeParameterType;
    expect(gTypeReturnType.element, same(tElement));
    var gReturnType = gType.returnType as NamedType;
    var tReference = gReturnType.name;
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_local_type_parameter_reference_interface_type_parameter() async {
    addTestFile('''
void main() {
  void f<T>(T x) {
    List<T> y = [x];
  }
  f(1);
}
''');
    await resolveTestFile();

    var mainStatements = _getMainStatements(result);
    var fDeclaration = mainStatements[0] as FunctionDeclarationStatement;
    var fElement = fDeclaration.functionDeclaration.declaredElement!;
    var tElement = fElement.typeParameters[0];
    var body = fDeclaration.functionDeclaration.functionExpression.body
        as BlockFunctionBody;
    var yDeclaration = body.block.statements[0] as VariableDeclarationStatement;
    var yType = yDeclaration.variables.type as NamedType;
    var yTypeType = yType.type as InterfaceType;
    var yTypeTypeArgument = yTypeType.typeArguments[0] as TypeParameterType;
    expect(yTypeTypeArgument.element, same(tElement));
    var yElementType = yType.typeArguments!.arguments[0] as NamedType;
    var tReference = yElementType.name;
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_local_type_parameter_reference_simple() async {
    addTestFile('''
void main() {
  void f<T>(T x) {
    T y = x;
  }
  f(1);
}
''');
    await resolveTestFile();

    var mainStatements = _getMainStatements(result);
    var fDeclaration = mainStatements[0] as FunctionDeclarationStatement;
    var fElement = fDeclaration.functionDeclaration.declaredElement!;
    var tElement = fElement.typeParameters[0];
    var body = fDeclaration.functionDeclaration.functionExpression.body
        as BlockFunctionBody;
    var yDeclaration = body.block.statements[0] as VariableDeclarationStatement;
    var yType = yDeclaration.variables.type as NamedType;
    var tReference = yType.name;
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_local_type_parameter_reference_typedef_named_parameter_type() async {
    addTestFile('''
typedef void Consumer<U>({U u});
void main() {
  void f<T>(T x) {
    Consumer<T> g = null;
  }
  f(1);
}
''');
    await resolveTestFile();

    var tElement = findNode.typeParameter('T>(T x)').declaredElement!;

    var gType = findNode.namedType('Consumer<T>');
    var gTypeType = gType.type as FunctionType;

    var gTypeParameterType =
        gTypeType.namedParameterTypes['u'] as TypeParameterType;
    expect(gTypeParameterType.element, same(tElement));

    var gArgumentType = gType.typeArguments!.arguments[0] as NamedType;
    var tReference = gArgumentType.name;
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_local_type_parameter_reference_typedef_normal_parameter_type() async {
    addTestFile('''
typedef void Consumer<U>(U u);
void main() {
  void f<T>(T x) {
    Consumer<T> g = null;
  }
  f(1);
}
''');
    await resolveTestFile();

    var tElement = findNode.typeParameter('T>(T x)').declaredElement!;

    var gType = findNode.namedType('Consumer<T>');
    var gTypeType = gType.type as FunctionType;

    var gTypeParameterType =
        gTypeType.normalParameterTypes[0] as TypeParameterType;
    expect(gTypeParameterType.element, same(tElement));

    var gArgumentType = gType.typeArguments!.arguments[0] as NamedType;
    var tReference = gArgumentType.name;
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_local_type_parameter_reference_typedef_optional_parameter_type() async {
    addTestFile('''
typedef void Consumer<U>([U u]);
void main() {
  void f<T>(T x) {
    Consumer<T> g = null;
  }
  f(1);
}
''');
    await resolveTestFile();

    var tElement = findNode.typeParameter('T>(T x)').declaredElement!;

    var gType = findNode.namedType('Consumer<T>');
    var gTypeType = gType.type as FunctionType;

    var gTypeParameterType =
        gTypeType.optionalParameterTypes[0] as TypeParameterType;
    expect(gTypeParameterType.element, same(tElement));

    var gArgumentType = gType.typeArguments!.arguments[0] as NamedType;
    var tReference = gArgumentType.name;
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_local_type_parameter_reference_typedef_return_type() async {
    addTestFile('''
typedef U Producer<U>();
void main() {
  void f<T>(T x) {
    Producer<T> g = () => x;
  }
  f(1);
}
''');
    await resolveTestFile();

    var tElement = findNode.typeParameter('T>(T x)').declaredElement!;

    var gType = findNode.namedType('Producer<T>');
    var gTypeType = gType.type as FunctionType;

    var gTypeReturnType = gTypeType.returnType as TypeParameterType;
    expect(gTypeReturnType.element, same(tElement));

    var gArgumentType = gType.typeArguments!.arguments[0] as NamedType;
    var tReference = gArgumentType.name;
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_local_variable() async {
    await assertNoErrorsInCode(r'''
void main() {
  var v = 42;
  v;
}
''');

    InterfaceType intType = typeProvider.intType;

    var main = result.unit.declarations[0] as FunctionDeclaration;
    expect(main.declaredElement, isNotNull);

    var body = main.functionExpression.body as BlockFunctionBody;
    NodeList<Statement> statements = body.block.statements;

    // var v = 42;
    VariableElement vElement;
    {
      var statement = statements[0] as VariableDeclarationStatement;
      VariableDeclaration vNode = statement.variables.variables[0];
      expect(vNode.initializer!.staticType, intType);

      vElement = vNode.declaredElement!;
      expect(vElement, isNotNull);
      expect(vElement.type, isNotNull);
      expect(vElement.type, intType);
    }

    // v;
    {
      var statement = statements[1] as ExpressionStatement;
      var identifier = statement.expression as SimpleIdentifier;
      expect(identifier.staticElement, same(vElement));
      expect(identifier.staticType, intType);
    }
  }

  test_local_variable_forIn_identifier_field() async {
    addTestFile(r'''
class C {
  num v;
  void foo() {
    for (v in <int>[]) {
      v;
    }
  }
}
''');
    await resolveTestFile();
    CompilationUnit unit = result.unit;

    var cDeclaration = unit.declarations[0] as ClassDeclaration;

    var vDeclaration = cDeclaration.members[0] as FieldDeclaration;
    VariableDeclaration vNode = vDeclaration.fields.variables[0];
    var vElement = vNode.declaredElement as FieldElement;
    expect(vElement.type, typeProvider.numType);

    var fooDeclaration = cDeclaration.members[1] as MethodDeclaration;
    var fooBody = fooDeclaration.body as BlockFunctionBody;
    List<Statement> statements = fooBody.block.statements;

    var forEachStatement = statements[0] as ForStatement;
    var forBlock = forEachStatement.body as Block;
    var forEachParts =
        forEachStatement.forLoopParts as ForEachPartsWithIdentifier;

    SimpleIdentifier vInFor = forEachParts.identifier;
    expect(vInFor.staticElement, same(vElement.setter));
    expect(vInFor.staticType, typeProvider.numType);

    var statement = forBlock.statements[0] as ExpressionStatement;
    var identifier = statement.expression as SimpleIdentifier;
    expect(identifier.staticElement, same(vElement.getter));
    expect(identifier.staticType, typeProvider.numType);
  }

  test_local_variable_forIn_identifier_localVariable() async {
    addTestFile(r'''
void main() {
  num v;
  for (v in <int>[]) {
    v;
  }
}
''');
    await resolveTestFile();

    List<Statement> statements = _getMainStatements(result);

    var vStatement = statements[0] as VariableDeclarationStatement;
    VariableDeclaration vNode = vStatement.variables.variables[0];
    var vElement = vNode.declaredElement as LocalVariableElement;
    expect(vElement.type, typeProvider.numType);

    var forEachStatement = statements[1] as ForStatement;
    var forBlock = forEachStatement.body as Block;
    var forEachParts =
        forEachStatement.forLoopParts as ForEachPartsWithIdentifier;

    SimpleIdentifier vInFor = forEachParts.identifier;
    expect(vInFor.staticElement, vElement);
    expect(vInFor.staticType, typeProvider.numType);

    var statement = forBlock.statements[0] as ExpressionStatement;
    var identifier = statement.expression as SimpleIdentifier;
    expect(identifier.staticElement, same(vElement));
    expect(identifier.staticType, typeProvider.numType);
  }

  test_local_variable_forIn_identifier_topLevelVariable() async {
    addTestFile(r'''
void main() {
  for (v in <int>[]) {
    v;
  }
}
num v;
''');
    await resolveTestFile();
    CompilationUnit unit = result.unit;

    List<Statement> statements = _getMainStatements(result);

    var vDeclaration = unit.declarations[1] as TopLevelVariableDeclaration;
    VariableDeclaration vNode = vDeclaration.variables.variables[0];
    var vElement = vNode.declaredElement as TopLevelVariableElement;
    expect(vElement.type, typeProvider.numType);

    var forEachStatement = statements[0] as ForStatement;
    var forBlock = forEachStatement.body as Block;
    var forEachParts =
        forEachStatement.forLoopParts as ForEachPartsWithIdentifier;

    SimpleIdentifier vInFor = forEachParts.identifier;
    expect(vInFor.staticElement, same(vElement.setter));
    expect(vInFor.staticType, typeProvider.numType);

    var statement = forBlock.statements[0] as ExpressionStatement;
    var identifier = statement.expression as SimpleIdentifier;
    expect(identifier.staticElement, same(vElement.getter));
    expect(identifier.staticType, typeProvider.numType);
  }

  test_local_variable_forIn_loopVariable() async {
    addTestFile(r'''
void main() {
  for (var v in <int>[]) {
    v;
  }
}
''');
    await resolveTestFile();

    List<Statement> statements = _getMainStatements(result);

    var forEachStatement = statements[0] as ForStatement;
    var forBlock = forEachStatement.body as Block;
    var forEachParts =
        forEachStatement.forLoopParts as ForEachPartsWithDeclaration;

    DeclaredIdentifier vNode = forEachParts.loopVariable;
    LocalVariableElement vElement = vNode.declaredElement!;
    expect(vElement.type, typeProvider.intType);

    var statement = forBlock.statements[0] as ExpressionStatement;
    var identifier = statement.expression as SimpleIdentifier;
    expect(identifier.staticElement, vElement);
    expect(identifier.staticType, typeProvider.intType);
  }

  test_local_variable_forIn_loopVariable_explicitType() async {
    addTestFile(r'''
void main() {
  for (num v in <int>[]) {
    v;
  }
}
''');
    await resolveTestFile();

    List<Statement> statements = _getMainStatements(result);

    var forEachStatement = statements[0] as ForStatement;
    var forBlock = forEachStatement.body as Block;
    var forEachParts =
        forEachStatement.forLoopParts as ForEachPartsWithDeclaration;

    DeclaredIdentifier vNode = forEachParts.loopVariable;
    LocalVariableElement vElement = vNode.declaredElement!;
    expect(vElement.type, typeProvider.numType);

    var vNamedType = vNode.type as NamedType;
    expect(vNamedType.type, typeProvider.numType);

    var vTypeIdentifier = vNamedType.name as SimpleIdentifier;
    expect(vTypeIdentifier.staticElement, typeProvider.numType.element);
    expect(vTypeIdentifier.staticType, isNull);

    var statement = forBlock.statements[0] as ExpressionStatement;
    var identifier = statement.expression as SimpleIdentifier;
    expect(identifier.staticElement, vElement);
    expect(identifier.staticType, typeProvider.numType);
  }

  test_local_variable_multiple() async {
    addTestFile(r'''
void main() {
  var a = 1, b = 2.3;
}
''');
    await resolveTestFile();

    List<Statement> statements = _getMainStatements(result);

    var declarationStatement = statements[0] as VariableDeclarationStatement;

    VariableDeclaration aNode = declarationStatement.variables.variables[0];
    var aElement = aNode.declaredElement as LocalVariableElement;
    expect(aElement.type, typeProvider.intType);

    VariableDeclaration bNode = declarationStatement.variables.variables[1];
    var bElement = bNode.declaredElement as LocalVariableElement;
    expect(bElement.type, typeProvider.doubleType);
  }

  test_local_variable_ofLocalFunction() async {
    addTestFile(r'''
void main() {
  void f() {
    int a;
    a;
    void g() {
      double b;
      a;
      b;
    }
  }
}
''');
    await resolveTestFile();

    List<Statement> mainStatements = _getMainStatements(result);

    // f() {}
    var fStatement = mainStatements[0] as FunctionDeclarationStatement;
    FunctionDeclaration fNode = fStatement.functionDeclaration;
    var fBody = fNode.functionExpression.body as BlockFunctionBody;
    List<Statement> fStatements = fBody.block.statements;

    // int a;
    var aDeclaration = fStatements[0] as VariableDeclarationStatement;
    VariableElement aElement =
        aDeclaration.variables.variables[0].declaredElement!;

    // a;
    {
      var aStatement = fStatements[1] as ExpressionStatement;
      var aNode = aStatement.expression as SimpleIdentifier;
      expect(aNode.staticElement, same(aElement));
      expect(aNode.staticType, typeProvider.intType);
    }

    // g(double b) {}
    var gStatement = fStatements[2] as FunctionDeclarationStatement;
    FunctionDeclaration gNode = gStatement.functionDeclaration;
    var gBody = gNode.functionExpression.body as BlockFunctionBody;
    List<Statement> gStatements = gBody.block.statements;

    // double b;
    var bDeclaration = gStatements[0] as VariableDeclarationStatement;
    VariableElement bElement =
        bDeclaration.variables.variables[0].declaredElement!;

    // a;
    {
      var aStatement = gStatements[1] as ExpressionStatement;
      var aNode = aStatement.expression as SimpleIdentifier;
      expect(aNode.staticElement, same(aElement));
      expect(aNode.staticType, typeProvider.intType);
    }

    // b;
    {
      var bStatement = gStatements[2] as ExpressionStatement;
      var bNode = bStatement.expression as SimpleIdentifier;
      expect(bNode.staticElement, same(bElement));
      expect(bNode.staticType, typeProvider.doubleType);
    }
  }

  test_mapLiteral() async {
    addTestFile(r'''
void main() {
  <int, double>{};
  const <bool, String>{};
}
''');
    await resolveTestFile();

    var statements = _getMainStatements(result);

    {
      var statement = statements[0] as ExpressionStatement;
      var mapLiteral = statement.expression as SetOrMapLiteral;
      expect(mapLiteral.staticType,
          typeProvider.mapType(typeProvider.intType, typeProvider.doubleType));
    }

    {
      var statement = statements[1] as ExpressionStatement;
      var mapLiteral = statement.expression as SetOrMapLiteral;
      expect(mapLiteral.staticType,
          typeProvider.mapType(typeProvider.boolType, typeProvider.stringType));
    }
  }

  test_mapLiteral_3() async {
    addTestFile(r'''
main() {
  var v = <bool, int, double>{};
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var literal = findNode.setOrMapLiteral('<bool, int, double>{}');
    assertType(literal, 'Map<dynamic, dynamic>');

    var boolRef = findNode.simple('bool, ');
    assertElement(boolRef, boolElement);
    assertTypeNull(boolRef);

    var intRef = findNode.simple('int, ');
    assertElement(intRef, intElement);
    assertTypeNull(intRef);

    var doubleRef = findNode.simple('double>');
    assertElement(doubleRef, doubleElement);
    assertTypeNull(doubleRef);
  }

  test_method_namedParameters() async {
    addTestFile(r'''
class C {
  double f(int a, {String b, bool c: false}) {}
}
void g(C c) {
  c.f(1, b: '2', c: true);
}
''');
    String fTypeString = 'double Function(int, {String b, bool c})';

    await resolveTestFile();
    var classDeclaration = result.unit.declarations[0] as ClassDeclaration;
    var methodDeclaration = classDeclaration.members[0] as MethodDeclaration;
    var methodElement = methodDeclaration.declaredElement as MethodElement;

    InterfaceType doubleType = typeProvider.doubleType;

    expect(methodElement, isNotNull);
    assertType(methodElement.type, fTypeString);

    var fReturnTypeNode = methodDeclaration.returnType as NamedType;
    expect(fReturnTypeNode.name.staticElement, same(doubleType.element));
    expect(fReturnTypeNode.type, doubleType);
    //
    // Validate the parameters at the declaration site.
    //
    List<ParameterElement> elements = methodElement.parameters;
    expect(elements, hasLength(3));

    List<FormalParameter> nodes = methodDeclaration.parameters!.parameters;
    expect(nodes, hasLength(3));

    _assertSimpleParameter(nodes[0] as SimpleFormalParameter, elements[0],
        name: 'a',
        offset: 25,
        kind: ParameterKind.REQUIRED,
        type: typeProvider.intType);

    _assertDefaultParameter(nodes[1] as DefaultFormalParameter, elements[1],
        name: 'b',
        offset: 36,
        kind: ParameterKind.NAMED,
        type: typeProvider.stringType);

    _assertDefaultParameter(nodes[2] as DefaultFormalParameter, elements[2],
        name: 'c',
        offset: 44,
        kind: ParameterKind.NAMED,
        type: typeProvider.boolType);
    //
    // Validate the arguments at the call site.
    //
    var functionDeclaration =
        result.unit.declarations[1] as FunctionDeclaration;
    var body = functionDeclaration.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var invocation = statement.expression as MethodInvocation;

    List<Expression> arguments = invocation.argumentList.arguments;
    _assertArgumentToParameter(arguments[0], methodElement.parameters[0]);
    _assertArgumentToParameter(arguments[1], methodElement.parameters[1]);
    _assertArgumentToParameter(arguments[2], methodElement.parameters[2]);
  }

  test_postfix_increment_of_non_generator() async {
    addTestFile('''
void f(int g()) {
  g()++;
}
''');
    await resolveTestFile();

    var gRef = findNode.simple('g()++');
    assertType(gRef, 'int Function()');
    assertElement(gRef, findElement.parameter('g'));
  }

  test_prefix_increment_of_non_generator() async {
    addTestFile('''
void f(bool x) {
  ++!x;
}
''');
    await resolveTestFile();

    var xRef = findNode.simple('x;');
    assertType(xRef, 'bool');
    assertElement(xRef, findElement.parameter('x'));
  }

  test_prefixedIdentifier_classInstance_instanceField() async {
    String content = r'''
main() {
  var c = new C();
  c.f;
}
class C {
  int f;
}
''';
    addTestFile(content);

    await resolveTestFile();

    List<Statement> statements = _getMainStatements(result);

    var cDeclaration = result.unit.declarations[1] as ClassDeclaration;
    ClassElement cElement = cDeclaration.declaredElement!;
    FieldElement fElement = cElement.fields[0];

    var cStatement = statements[0] as VariableDeclarationStatement;
    VariableElement vElement =
        cStatement.variables.variables[0].declaredElement!;

    var statement = statements[1] as ExpressionStatement;
    var prefixed = statement.expression as PrefixedIdentifier;

    SimpleIdentifier prefix = prefixed.prefix;
    expect(prefix.staticElement, same(vElement));
    expect(prefix.staticType, interfaceTypeNone(cElement));

    SimpleIdentifier identifier = prefixed.identifier;
    expect(identifier.staticElement, same(fElement.getter));
    expect(identifier.staticType, typeProvider.intType);
  }

  test_prefixedIdentifier_className_staticField() async {
    String content = r'''
main() {
  C.f;
}
class C {
  static f = 0;
}
''';
    addTestFile(content);

    await resolveTestFile();

    List<Statement> statements = _getMainStatements(result);

    var cDeclaration = result.unit.declarations[1] as ClassDeclaration;
    ClassElement cElement = cDeclaration.declaredElement!;
    FieldElement fElement = cElement.fields[0];

    var statement = statements[0] as ExpressionStatement;
    var prefixed = statement.expression as PrefixedIdentifier;

    SimpleIdentifier prefix = prefixed.prefix;
    expect(prefix.staticElement, same(cElement));
    assertTypeNull(prefix);

    SimpleIdentifier identifier = prefixed.identifier;
    expect(identifier.staticElement, same(fElement.getter));
    expect(identifier.staticType, typeProvider.intType);
  }

  test_prefixedIdentifier_explicitCall() async {
    addTestFile(r'''
f(double computation(int p)) {
  computation.call;
}
''');
    await resolveTestFile();
    expect(result.errors, isEmpty);

    var main = result.unit.declarations[0] as FunctionDeclaration;
    var mainElement = main.declaredElement as FunctionElement;
    ParameterElement parameter = mainElement.parameters[0];

    var mainBody = main.functionExpression.body as BlockFunctionBody;
    List<Statement> statements = mainBody.block.statements;

    var statement = statements[0] as ExpressionStatement;
    var prefixed = statement.expression as PrefixedIdentifier;

    expect(prefixed.prefix.staticElement, same(parameter));
    assertType(prefixed.prefix.staticType, 'double Function(int)');

    SimpleIdentifier methodName = prefixed.identifier;
    expect(methodName.staticElement, isNull);
    assertType(methodName.staticType, 'double Function(int)');
  }

  test_propertyAccess_field() async {
    String content = r'''
main() {
  new C().f;
}
class C {
  int f;
}
''';
    addTestFile(content);

    await resolveTestFile();
    CompilationUnit unit = result.unit;

    var cClassDeclaration = unit.declarations[1] as ClassDeclaration;
    ClassElement cClassElement = cClassDeclaration.declaredElement!;
    FieldElement fElement = cClassElement.getField('f')!;

    List<Statement> mainStatements = _getMainStatements(result);

    {
      var statement = mainStatements[0] as ExpressionStatement;
      var access = statement.expression as PropertyAccess;
      expect(access.staticType, typeProvider.intType);

      var newC = access.target as InstanceCreationExpression;
      expect(
        newC.constructorName.staticElement,
        cClassElement.unnamedConstructor,
      );
      expect(newC.staticType, interfaceTypeNone(cClassElement));

      expect(access.propertyName.staticElement, same(fElement.getter));
      expect(access.propertyName.staticType, typeProvider.intType);
    }
  }

  test_propertyAccess_getter() async {
    String content = r'''
main() {
  new C().f;
}
class C {
  int get f => 0;
}
''';
    addTestFile(content);

    await resolveTestFile();
    CompilationUnit unit = result.unit;

    var cClassDeclaration = unit.declarations[1] as ClassDeclaration;
    ClassElement cClassElement = cClassDeclaration.declaredElement!;
    FieldElement fElement = cClassElement.getField('f')!;

    List<Statement> mainStatements = _getMainStatements(result);

    {
      var statement = mainStatements[0] as ExpressionStatement;
      var access = statement.expression as PropertyAccess;
      expect(access.staticType, typeProvider.intType);

      var newC = access.target as InstanceCreationExpression;
      expect(
        newC.constructorName.staticElement,
        cClassElement.unnamedConstructor,
      );
      expect(newC.staticType, interfaceTypeNone(cClassElement));

      expect(access.propertyName.staticElement, same(fElement.getter));
      expect(access.propertyName.staticType, typeProvider.intType);
    }
  }

  test_reference_to_class_type_parameter() async {
    addTestFile('''
class C<T> {
  void f() {
    T x;
  }
}
''');
    await resolveTestFile();
    var tElement = findElement.class_('C').typeParameters[0];
    var tReference = findNode.simple('T x');
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_setLiteral() async {
    addTestFile(r'''
main() {
  var v = <int>{};
  print(v);
}
''');
    await resolveTestFile();
    expect(result.errors, isEmpty);

    var literal = findNode.setOrMapLiteral('<int>{}');
    assertType(literal, 'Set<int>');

    var intRef = findNode.simple('int>{}');
    assertElement(intRef, intElement);
    assertTypeNull(intRef);
  }

  test_stringInterpolation() async {
    await assertNoErrorsInCode(r'''
void main() {
  var v = 42;
  '$v$v $v';
  ' ${v + 1} ';
}
''');

    var main = result.unit.declarations[0] as FunctionDeclaration;
    expect(main.declaredElement, isNotNull);

    var body = main.functionExpression.body as BlockFunctionBody;
    NodeList<Statement> statements = body.block.statements;

    // var v = 42;
    VariableElement vElement;
    {
      var statement = statements[0] as VariableDeclarationStatement;
      vElement = statement.variables.variables[0].declaredElement!;
    }

    {
      var statement = statements[1] as ExpressionStatement;
      var interpolation = statement.expression as StringInterpolation;

      var element_1 = interpolation.elements[1] as InterpolationExpression;
      var expression_1 = element_1.expression as SimpleIdentifier;
      expect(expression_1.staticElement, same(vElement));
      expect(expression_1.staticType, typeProvider.intType);

      var element_3 = interpolation.elements[3] as InterpolationExpression;
      var expression_3 = element_3.expression as SimpleIdentifier;
      expect(expression_3.staticElement, same(vElement));
      expect(expression_3.staticType, typeProvider.intType);

      var element_5 = interpolation.elements[5] as InterpolationExpression;
      var expression_5 = element_5.expression as SimpleIdentifier;
      expect(expression_5.staticElement, same(vElement));
      expect(expression_5.staticType, typeProvider.intType);
    }

    {
      var statement = statements[2] as ExpressionStatement;
      var interpolation = statement.expression as StringInterpolation;

      var element_1 = interpolation.elements[1] as InterpolationExpression;
      var expression = element_1.expression as BinaryExpression;
      expect(expression.staticType, typeProvider.intType);

      var left = expression.leftOperand as SimpleIdentifier;
      expect(left.staticElement, same(vElement));
      expect(left.staticType, typeProvider.intType);
    }
  }

  test_stringInterpolation_multiLine_emptyBeforeAfter() async {
    addTestFile(r"""
void main() {
  var v = 42;
  '''$v''';
}
""");
    await resolveTestFile();
    expect(result.errors, isEmpty);
  }

  test_top_class_constructor_parameter_defaultValue() async {
    String content = r'''
class C {
  double f;
  C([int a: 1 + 2]) : f = 3.4;
}
''';
    addTestFile(content);
    await resolveTestFile();

    var cNode = result.unit.declarations[0] as ClassDeclaration;
    ClassElement cElement = cNode.declaredElement!;

    var constructorNode = cNode.members[1] as ConstructorDeclaration;

    var aNode =
        constructorNode.parameters.parameters[0] as DefaultFormalParameter;
    _assertDefaultParameter(aNode, cElement.unnamedConstructor!.parameters[0],
        name: 'a',
        offset: 31,
        kind: ParameterKind.POSITIONAL,
        type: typeProvider.intType);

    var binary = aNode.defaultValue as BinaryExpression;
    expect(binary.staticElement, isNotNull);
    expect(binary.staticType, typeProvider.intType);
    expect(binary.leftOperand.staticType, typeProvider.intType);
    expect(binary.rightOperand.staticType, typeProvider.intType);
  }

  test_top_class_full() async {
    String content = r'''
class A<T> {}
class B<T> {}
class C<T> {}
class D extends A<bool> with B<int> implements C<double> {}
''';
    addTestFile(content);
    await resolveTestFile();

    var aNode = result.unit.declarations[0] as ClassDeclaration;
    ClassElement aElement = aNode.declaredElement!;

    var bNode = result.unit.declarations[1] as ClassDeclaration;
    ClassElement bElement = bNode.declaredElement!;

    var cNode = result.unit.declarations[2] as ClassDeclaration;
    ClassElement cElement = cNode.declaredElement!;

    var dNode = result.unit.declarations[3] as ClassDeclaration;

    {
      var expectedType = aElement.instantiate(
        typeArguments: [typeProvider.boolType],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      NamedType superClass = dNode.extendsClause!.superclass;
      expect(superClass.type, expectedType);

      var identifier = superClass.name as SimpleIdentifier;
      expect(identifier.staticElement, aElement);
      expect(identifier.staticType, isNull);
    }

    {
      var expectedType = bElement.instantiate(
        typeArguments: [typeProvider.intType],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      NamedType mixinType = dNode.withClause!.mixinTypes[0];
      expect(mixinType.type, expectedType);

      var identifier = mixinType.name as SimpleIdentifier;
      expect(identifier.staticElement, bElement);
      expect(identifier.staticType, isNull);
    }

    {
      var expectedType = cElement.instantiate(
        typeArguments: [typeProvider.doubleType],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      NamedType implementedType = dNode.implementsClause!.interfaces[0];
      expect(implementedType.type, expectedType);

      var identifier = implementedType.name as SimpleIdentifier;
      expect(identifier.staticElement, cElement);
      expect(identifier.staticType, isNull);
    }
  }

  test_top_classTypeAlias() async {
    String content = r'''
class A<T> {}
class B<T> {}
class C<T> {}
class D = A<bool> with B<int> implements C<double>;
''';
    addTestFile(content);
    await resolveTestFile();

    var aNode = result.unit.declarations[0] as ClassDeclaration;
    ClassElement aElement = aNode.declaredElement!;

    var bNode = result.unit.declarations[1] as ClassDeclaration;
    ClassElement bElement = bNode.declaredElement!;

    var cNode = result.unit.declarations[2] as ClassDeclaration;
    ClassElement cElement = cNode.declaredElement!;

    var dNode = result.unit.declarations[3] as ClassTypeAlias;

    {
      var expectedType = aElement.instantiate(
        typeArguments: [typeProvider.boolType],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      NamedType superClass = dNode.superclass;
      expect(superClass.type, expectedType);

      var identifier = superClass.name as SimpleIdentifier;
      expect(identifier.staticElement, same(aElement));
      expect(identifier.staticType, isNull);
    }

    {
      var expectedType = bElement.instantiate(
        typeArguments: [typeProvider.intType],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      NamedType mixinType = dNode.withClause.mixinTypes[0];
      expect(mixinType.type, expectedType);

      var identifier = mixinType.name as SimpleIdentifier;
      expect(identifier.staticElement, same(bElement));
      expect(identifier.staticType, isNull);
    }

    {
      var expectedType = cElement.instantiate(
        typeArguments: [typeProvider.doubleType],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      NamedType interfaceType = dNode.implementsClause!.interfaces[0];
      expect(interfaceType.type, expectedType);

      var identifier = interfaceType.name as SimpleIdentifier;
      expect(identifier.staticElement, same(cElement));
      expect(identifier.staticType, isNull);
    }
  }

  test_top_enum() async {
    String content = r'''
enum MyEnum {
  A, B
}
''';
    addTestFile(content);
    await resolveTestFile();

    var enumNode = result.unit.declarations[0] as EnumDeclaration;
    final enumElement = enumNode.declaredElement!;

    {
      var aElement = enumElement.getField('A');
      var aNode = enumNode.constants[0];
      expect(aNode.declaredElement, same(aElement));
    }

    {
      var bElement = enumElement.getField('B');
      var bNode = enumNode.constants[1];
      expect(bNode.declaredElement, same(bElement));
    }
  }

  test_top_executables_class() async {
    await assertNoErrorsInCode(r'''
class C {
  C(int p);
  C.named(int p);

  int publicMethod(double p) => 0;
  int get publicGetter => 0;
  void set publicSetter(double p) {}
}
''');

    InterfaceType doubleType = typeProvider.doubleType;
    InterfaceType intType = typeProvider.intType;
    final doubleElement = doubleType.element;
    final intElement = intType.element;

    var cNode = result.unit.declarations[0] as ClassDeclaration;
    ClassElement cElement = cNode.declaredElement!;

    // unnamed constructor
    {
      var node = cNode.members[0] as ConstructorDeclaration;
      expect(node.declaredElement, isNotNull);
      assertType(node.declaredElement!.type, 'C Function(int)');
      expect(node.returnType.staticElement, same(cElement));
      expect(node.returnType.staticType, isNull);
      expect(node.name, isNull);
    }

    // named constructor
    {
      var node = cNode.members[1] as ConstructorDeclaration;
      expect(node.declaredElement, isNotNull);
      assertType(node.declaredElement!.type, 'C Function(int)');
      expect(node.returnType.staticElement, same(cElement));
      expect(node.returnType.staticType, isNull);
    }

    // publicMethod()
    {
      var node = cNode.members[2] as MethodDeclaration;
      expect(node.declaredElement, isNotNull);
      assertType(node.declaredElement!.type, 'int Function(double)');

      // method return type
      var returnType = node.returnType as NamedType;
      var returnTypeName = returnType.name as SimpleIdentifier;
      expect(returnType.type, intType);
      expect(returnTypeName.staticElement, intElement);
      expect(returnTypeName.staticType, isNull);

      // method parameter
      {
        var pNode = node.parameters!.parameters[0] as SimpleFormalParameter;
        expect(pNode.declaredElement, isNotNull);
        expect(pNode.declaredElement!.type, doubleType);

        var pType = pNode.type as NamedType;
        expect(pType.name.staticElement, doubleElement);
        expect(pType.name.staticType, isNull);
      }
    }

    // publicGetter()
    {
      var node = cNode.members[3] as MethodDeclaration;
      expect(node.declaredElement, isNotNull);
      assertType(node.declaredElement!.type, 'int Function()');

      // getter return type
      var returnType = node.returnType as NamedType;
      var returnTypeName = returnType.name as SimpleIdentifier;
      expect(returnType.type, intType);
      expect(returnTypeName.staticElement, intElement);
      expect(returnTypeName.staticType, isNull);
    }

    // publicSetter()
    {
      var node = cNode.members[4] as MethodDeclaration;
      expect(node.declaredElement, isNotNull);
      assertType(node.declaredElement!.type, 'void Function(double)');

      // setter return type
      var returnType = node.returnType as NamedType;
      var returnTypeName = returnType.name as SimpleIdentifier;
      expect(returnType.type, VoidTypeImpl.instance);
      expect(returnTypeName.staticElement, isNull);
      expect(returnTypeName.staticType, isNull);

      // setter parameter
      {
        var pNode = node.parameters!.parameters[0] as SimpleFormalParameter;
        expect(pNode.declaredElement, isNotNull);
        expect(pNode.declaredElement!.type, doubleType);

        var pType = pNode.type as NamedType;
        expect(pType.name.staticElement, doubleElement);
        expect(pType.name.staticType, isNull);
      }
    }
  }

  test_top_executables_top() async {
    await assertNoErrorsInCode(r'''
int topFunction(double p) => 0;
int get topGetter => 0;
void set topSetter(double p) {}
''');

    InterfaceType doubleType = typeProvider.doubleType;
    InterfaceType intType = typeProvider.intType;
    final doubleElement = doubleType.element;
    final intElement = intType.element;

    // topFunction()
    {
      var node = result.unit.declarations[0] as FunctionDeclaration;
      expect(node.declaredElement, isNotNull);
      assertType(node.declaredElement!.type, 'int Function(double)');

      // function return type
      var returnType = node.returnType as NamedType;
      var returnTypeName = returnType.name as SimpleIdentifier;
      expect(returnType.type, intType);
      expect(returnTypeName.staticElement, intElement);
      expect(returnTypeName.staticType, isNull);

      // function parameter
      {
        var pNode = node.functionExpression.parameters!.parameters[0]
            as SimpleFormalParameter;
        expect(pNode.declaredElement, isNotNull);
        expect(pNode.declaredElement!.type, doubleType);

        var pType = pNode.type as NamedType;
        expect(pType.name.staticElement, doubleElement);
        expect(pType.name.staticType, isNull);
      }
    }

    // topGetter()
    {
      var node = result.unit.declarations[1] as FunctionDeclaration;
      expect(node.declaredElement, isNotNull);
      assertType(node.declaredElement!.type, 'int Function()');

      // getter return type
      var returnType = node.returnType as NamedType;
      var returnTypeName = returnType.name as SimpleIdentifier;
      expect(returnType.type, intType);
      expect(returnTypeName.staticElement, intElement);
      expect(returnTypeName.staticType, isNull);
    }

    // topSetter()
    {
      var node = result.unit.declarations[2] as FunctionDeclaration;
      expect(node.declaredElement, isNotNull);
      assertType(node.declaredElement!.type, 'void Function(double)');

      // setter return type
      var returnType = node.returnType as NamedType;
      var returnTypeName = returnType.name as SimpleIdentifier;
      expect(returnType.type, VoidTypeImpl.instance);
      expect(returnTypeName.staticElement, isNull);
      expect(returnTypeName.staticType, isNull);

      // setter parameter
      {
        var pNode = node.functionExpression.parameters!.parameters[0]
            as SimpleFormalParameter;
        expect(pNode.declaredElement, isNotNull);
        expect(pNode.declaredElement!.type, doubleType);

        var pType = pNode.type as NamedType;
        expect(pType.name.staticElement, doubleElement);
        expect(pType.name.staticType, isNull);
      }
    }
  }

  test_top_field_class() async {
    String content = r'''
class C<T> {
  var a = 1;
  T b;
}
''';
    addTestFile(content);

    await resolveTestFile();
    CompilationUnit unit = result.unit;
    CompilationUnitElement unitElement = unit.declaredElement!;

    var cNode = unit.declarations[0] as ClassDeclaration;
    ClassElement cElement = cNode.declaredElement!;
    TypeParameterElement tElement = cElement.typeParameters[0];
    expect(cElement, same(unitElement.classes[0]));

    {
      FieldElement aElement = cElement.getField('a')!;
      var aDeclaration = cNode.members[0] as FieldDeclaration;
      VariableDeclaration aNode = aDeclaration.fields.variables[0];
      expect(aNode.declaredElement, same(aElement));
      expect(aElement.type, typeProvider.intType);

      var aValue = aNode.initializer as Expression;
      expect(aValue.staticType, typeProvider.intType);
    }

    {
      FieldElement bElement = cElement.getField('b')!;
      var bDeclaration = cNode.members[1] as FieldDeclaration;

      var namedType = bDeclaration.fields.type as NamedType;
      var typeIdentifier = namedType.name as SimpleIdentifier;
      expect(typeIdentifier.staticElement, same(tElement));
      expect(typeIdentifier.staticType, isNull);

      VariableDeclaration bNode = bDeclaration.fields.variables[0];
      expect(bNode.declaredElement, same(bElement));
      expect(bElement.type, typeParameterTypeNone(tElement));
    }
  }

  test_top_field_class_multiple() async {
    String content = r'''
class C {
  var a = 1, b = 2.3;
}
''';
    addTestFile(content);

    await resolveTestFile();
    CompilationUnit unit = result.unit;

    var cNode = unit.declarations[0] as ClassDeclaration;
    ClassElement cElement = cNode.declaredElement!;

    var fieldDeclaration = cNode.members[0] as FieldDeclaration;

    {
      FieldElement aElement = cElement.getField('a')!;

      VariableDeclaration aNode = fieldDeclaration.fields.variables[0];
      expect(aNode.declaredElement, same(aElement));
      expect(aElement.type, typeProvider.intType);

      Expression aValue = aNode.initializer!;
      expect(aValue.staticType, typeProvider.intType);
    }

    {
      FieldElement bElement = cElement.getField('b')!;

      VariableDeclaration bNode = fieldDeclaration.fields.variables[1];
      expect(bNode.declaredElement, same(bElement));
      expect(bElement.type, typeProvider.doubleType);

      Expression aValue = bNode.initializer!;
      expect(aValue.staticType, typeProvider.doubleType);
    }
  }

  test_top_field_top() async {
    String content = r'''
var a = 1;
double b = 2.3;
''';
    addTestFile(content);

    await resolveTestFile();
    CompilationUnit unit = result.unit;
    CompilationUnitElement unitElement = unit.declaredElement!;

    {
      var aDeclaration = unit.declarations[0] as TopLevelVariableDeclaration;
      VariableDeclaration aNode = aDeclaration.variables.variables[0];
      var aElement = aNode.declaredElement as TopLevelVariableElement;
      expect(aElement, same(unitElement.topLevelVariables[0]));
      expect(aElement.type, typeProvider.intType);

      Expression aValue = aNode.initializer!;
      expect(aValue.staticType, typeProvider.intType);
    }

    {
      var bDeclaration = unit.declarations[1] as TopLevelVariableDeclaration;

      VariableDeclaration bNode = bDeclaration.variables.variables[0];
      var bElement = bNode.declaredElement as TopLevelVariableElement;
      expect(bElement, same(unitElement.topLevelVariables[1]));
      expect(bElement.type, typeProvider.doubleType);

      var namedType = bDeclaration.variables.type as NamedType;
      _assertNamedTypeSimple(namedType, typeProvider.doubleType);

      Expression aValue = bNode.initializer!;
      expect(aValue.staticType, typeProvider.doubleType);
    }
  }

  test_top_field_top_multiple() async {
    String content = r'''
var a = 1, b = 2.3;
''';
    addTestFile(content);

    await resolveTestFile();
    CompilationUnit unit = result.unit;
    CompilationUnitElement unitElement = unit.declaredElement!;

    var variableDeclaration =
        unit.declarations[0] as TopLevelVariableDeclaration;
    expect(variableDeclaration.variables.type, isNull);

    {
      VariableDeclaration aNode = variableDeclaration.variables.variables[0];
      var aElement = aNode.declaredElement as TopLevelVariableElement;
      expect(aElement, same(unitElement.topLevelVariables[0]));
      expect(aElement.type, typeProvider.intType);

      Expression aValue = aNode.initializer!;
      expect(aValue.staticType, typeProvider.intType);
    }

    {
      VariableDeclaration bNode = variableDeclaration.variables.variables[1];
      var bElement = bNode.declaredElement as TopLevelVariableElement;
      expect(bElement, same(unitElement.topLevelVariables[1]));
      expect(bElement.type, typeProvider.doubleType);

      Expression aValue = bNode.initializer!;
      expect(aValue.staticType, typeProvider.doubleType);
    }
  }

  test_top_function_namedParameters() async {
    addTestFile(r'''
double f(int a, {String b, bool c: 1 == 2}) {}
void main() {
  f(1, b: '2', c: true);
}
''');
    String fTypeString = 'double Function(int, {String b, bool c})';

    await resolveTestFile();
    var fDeclaration = result.unit.declarations[0] as FunctionDeclaration;
    var fElement = fDeclaration.declaredElement as FunctionElement;

    InterfaceType doubleType = typeProvider.doubleType;

    expect(fElement, isNotNull);
    assertType(fElement.type, fTypeString);

    var fReturnTypeNode = fDeclaration.returnType as NamedType;
    expect(fReturnTypeNode.name.staticElement, same(doubleType.element));
    expect(fReturnTypeNode.type, doubleType);
    //
    // Validate the parameters at the declaration site.
    //
    List<ParameterElement> elements = fElement.parameters;
    expect(elements, hasLength(3));

    List<FormalParameter> nodes =
        fDeclaration.functionExpression.parameters!.parameters;
    expect(nodes, hasLength(3));

    _assertSimpleParameter(nodes[0] as SimpleFormalParameter, elements[0],
        name: 'a',
        offset: 13,
        kind: ParameterKind.REQUIRED,
        type: typeProvider.intType);

    var bNode = nodes[1] as DefaultFormalParameter;
    _assertDefaultParameter(bNode, elements[1],
        name: 'b',
        offset: 24,
        kind: ParameterKind.NAMED,
        type: typeProvider.stringType);
    expect(bNode.defaultValue, isNull);

    var cNode = nodes[2] as DefaultFormalParameter;
    _assertDefaultParameter(cNode, elements[2],
        name: 'c',
        offset: 32,
        kind: ParameterKind.NAMED,
        type: typeProvider.boolType);
    {
      var defaultValue = cNode.defaultValue as BinaryExpression;
      expect(defaultValue.staticElement, isNotNull);
      expect(defaultValue.staticType, typeProvider.boolType);
    }

    //
    // Validate the arguments at the call site.
    //
    var mainDeclaration = result.unit.declarations[1] as FunctionDeclaration;
    var body = mainDeclaration.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var invocation = statement.expression as MethodInvocation;
    List<Expression> arguments = invocation.argumentList.arguments;

    _assertArgumentToParameter(arguments[0], fElement.parameters[0]);
    _assertArgumentToParameter(arguments[1], fElement.parameters[1]);
    _assertArgumentToParameter(arguments[2], fElement.parameters[2]);
  }

  test_top_functionTypeAlias() async {
    String content = r'''
typedef int F<T>(bool a, T b);
''';
    addTestFile(content);

    await resolveTestFile();
    CompilationUnit unit = result.unit;

    var alias = unit.declarations[0] as FunctionTypeAlias;
    TypeAliasElement aliasElement = alias.declaredElement!;
    var function = aliasElement.aliasedElement as GenericFunctionTypeElement;
    expect(aliasElement, same(findElement.typeAlias('F')));
    expect(function.returnType, typeProvider.intType);

    _assertNamedTypeSimple(alias.returnType as NamedType, typeProvider.intType);

    _assertSimpleParameter(
        alias.parameters.parameters[0] as SimpleFormalParameter,
        function.parameters[0],
        name: 'a',
        offset: 22,
        kind: ParameterKind.REQUIRED,
        type: typeProvider.boolType);

    _assertSimpleParameter(
        alias.parameters.parameters[1] as SimpleFormalParameter,
        function.parameters[1],
        name: 'b',
        offset: 27,
        kind: ParameterKind.REQUIRED,
        type: typeParameterTypeNone(aliasElement.typeParameters[0]));
  }

  test_top_typeParameter() async {
    String content = r'''
class A {}
class C<T extends A, U extends List<A>, V> {}
''';
    addTestFile(content);
    await resolveTestFile();
    CompilationUnit unit = result.unit;
    CompilationUnitElement unitElement = unit.declaredElement!;

    var aNode = unit.declarations[0] as ClassDeclaration;
    ClassElement aElement = aNode.declaredElement!;
    expect(aElement, same(unitElement.classes[0]));

    var cNode = unit.declarations[1] as ClassDeclaration;
    ClassElement cElement = cNode.declaredElement!;
    expect(cElement, same(unitElement.classes[1]));

    {
      TypeParameter tNode = cNode.typeParameters!.typeParameters[0];
      expect(tNode.declaredElement, same(cElement.typeParameters[0]));

      var bound = tNode.bound as NamedType;
      expect(bound.type, interfaceTypeNone(aElement));

      var boundIdentifier = bound.name as SimpleIdentifier;
      expect(boundIdentifier.staticElement, same(aElement));
      expect(boundIdentifier.staticType, isNull);
    }

    {
      var listElement = typeProvider.listElement;
      var listOfA = listElement.instantiate(
        typeArguments: [interfaceTypeNone(aElement)],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      TypeParameter uNode = cNode.typeParameters!.typeParameters[1];
      expect(uNode.declaredElement, same(cElement.typeParameters[1]));

      var bound = uNode.bound as NamedType;
      expect(bound.type, listOfA);

      var listIdentifier = bound.name as SimpleIdentifier;
      expect(listIdentifier.staticElement, same(listElement));
      expect(listIdentifier.staticType, isNull);

      var aNamedType = bound.typeArguments!.arguments[0] as NamedType;
      expect(aNamedType.type, interfaceTypeNone(aElement));

      var aIdentifier = aNamedType.name as SimpleIdentifier;
      expect(aIdentifier.staticElement, same(aElement));
      expect(aIdentifier.staticType, isNull);
    }

    {
      TypeParameter vNode = cNode.typeParameters!.typeParameters[2];
      expect(vNode.declaredElement, same(cElement.typeParameters[2]));
      expect(vNode.bound, isNull);
    }
  }

  test_tryCatch() async {
    addTestFile(r'''
void main() {
  try {} catch (e, st) {
    e;
    st;
  }
  try {} on int catch (e, st) {
    e;
    st;
  }
  try {} catch (e) {
    e;
  }
  try {} on int catch (e) {
    e;
  }
  try {} on int {}
}
''');
    await resolveTestFile();

    List<Statement> statements = _getMainStatements(result);

    // catch (e, st)
    {
      var statement = statements[0] as TryStatement;
      CatchClause catchClause = statement.catchClauses[0];
      expect(catchClause.exceptionType, isNull);

      var exceptionNode = catchClause.exceptionParameter!;
      var exceptionElement = exceptionNode.declaredElement!;
      expect(exceptionElement.type, typeProvider.objectType);

      var stackNode = catchClause.stackTraceParameter!;
      var stackElement = stackNode.declaredElement!;
      expect(stackElement.type, typeProvider.stackTraceType);

      List<Statement> catchStatements = catchClause.body.statements;

      var exceptionStatement = catchStatements[0] as ExpressionStatement;
      var exceptionIdentifier =
          exceptionStatement.expression as SimpleIdentifier;
      expect(exceptionIdentifier.staticElement, same(exceptionElement));
      expect(exceptionIdentifier.staticType, typeProvider.objectType);

      var stackStatement = catchStatements[1] as ExpressionStatement;
      var stackIdentifier = stackStatement.expression as SimpleIdentifier;
      expect(stackIdentifier.staticElement, same(stackElement));
      expect(stackIdentifier.staticType, typeProvider.stackTraceType);
    }

    // on int catch (e, st)
    {
      var statement = statements[1] as TryStatement;
      CatchClause catchClause = statement.catchClauses[0];
      _assertNamedTypeSimple(
          catchClause.exceptionType as NamedType, typeProvider.intType);

      var exceptionNode = catchClause.exceptionParameter!;
      var exceptionElement = exceptionNode.declaredElement!;
      expect(exceptionElement.type, typeProvider.intType);

      var stackNode = catchClause.stackTraceParameter!;
      var stackElement = stackNode.declaredElement!;
      expect(stackElement.type, typeProvider.stackTraceType);

      List<Statement> catchStatements = catchClause.body.statements;

      var exceptionStatement = catchStatements[0] as ExpressionStatement;
      var exceptionIdentifier =
          exceptionStatement.expression as SimpleIdentifier;
      expect(exceptionIdentifier.staticElement, same(exceptionElement));
      expect(exceptionIdentifier.staticType, typeProvider.intType);

      var stackStatement = catchStatements[1] as ExpressionStatement;
      var stackIdentifier = stackStatement.expression as SimpleIdentifier;
      expect(stackIdentifier.staticElement, same(stackElement));
      expect(stackIdentifier.staticType, typeProvider.stackTraceType);
    }

    // catch (e)
    {
      var statement = statements[2] as TryStatement;
      CatchClause catchClause = statement.catchClauses[0];
      expect(catchClause.exceptionType, isNull);
      expect(catchClause.stackTraceParameter, isNull);

      var exceptionNode = catchClause.exceptionParameter!;
      var exceptionElement = exceptionNode.declaredElement!;
      expect(exceptionElement.type, typeProvider.objectType);
    }

    // on int catch (e)
    {
      var statement = statements[3] as TryStatement;
      CatchClause catchClause = statement.catchClauses[0];
      _assertNamedTypeSimple(catchClause.exceptionType!, typeProvider.intType);
      expect(catchClause.stackTraceParameter, isNull);

      var exceptionNode = catchClause.exceptionParameter!;
      var exceptionElement = exceptionNode.declaredElement!;
      expect(exceptionElement.type, typeProvider.intType);
    }

    // on int catch (e)
    {
      var statement = statements[4] as TryStatement;
      CatchClause catchClause = statement.catchClauses[0];
      _assertNamedTypeSimple(
          catchClause.exceptionType as NamedType, typeProvider.intType);
      expect(catchClause.exceptionParameter, isNull);
      expect(catchClause.stackTraceParameter, isNull);
    }
  }

  test_type_dynamic() async {
    addTestFile('''
main() {
  dynamic d;
}
''');
    await resolveTestFile();
    var statements = _getMainStatements(result);
    var variableDeclarationStatement =
        statements[0] as VariableDeclarationStatement;
    var type = variableDeclarationStatement.variables.type as NamedType;
    expect(type.type, isDynamicType);
    var namedType = type.name;
    assertTypeNull(namedType);
  }

  test_type_functionTypeAlias() async {
    addTestFile(r'''
typedef T F<T>(bool a);
class C {
  F<int> f;
}
''');

    await resolveTestFile();

    FunctionTypeAlias alias = findNode.functionTypeAlias('F<T>');
    TypeAliasElement aliasElement = alias.declaredElement!;

    FieldDeclaration fDeclaration = findNode.fieldDeclaration('F<int> f');

    var namedType = fDeclaration.fields.type as NamedType;
    assertType(namedType, 'int Function(bool)');

    var typeIdentifier = namedType.name as SimpleIdentifier;
    expect(typeIdentifier.staticElement, same(aliasElement));
    expect(typeIdentifier.staticType, isNull);

    List<TypeAnnotation> typeArguments = namedType.typeArguments!.arguments;
    expect(typeArguments, hasLength(1));
    _assertNamedTypeSimple(typeArguments[0], typeProvider.intType);
  }

  test_type_void() async {
    addTestFile('''
main() {
  void v;
}
''');
    await resolveTestFile();
    var statements = _getMainStatements(result);
    var variableDeclarationStatement =
        statements[0] as VariableDeclarationStatement;
    var type = variableDeclarationStatement.variables.type as NamedType;
    expect(type.type, isVoidType);
    var namedType = type.name;
    expect(namedType.staticType, isNull);
    expect(namedType.staticElement, isNull);
  }

  test_typeAnnotation_prefixed() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newFile('$testPackageLibPath/b.dart', "export 'a.dart';");
    newFile('$testPackageLibPath/c.dart', "export 'a.dart';");
    addTestFile(r'''
import 'b.dart' as b;
import 'c.dart' as c;
b.A a1;
c.A a2;
''');
    await resolveTestFile();
    CompilationUnit unit = result.unit;

    final bImport = unit.declaredElement!.library.libraryImports[0];
    final cImport = unit.declaredElement!.library.libraryImports[1];

    LibraryElement bLibrary = bImport.importedLibrary!;
    LibraryElement aLibrary = bLibrary.libraryExports[0].exportedLibrary!;
    ClassElement aClass = aLibrary.getClass('A')!;

    {
      var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
      var namedType = declaration.variables.type as NamedType;

      var typeIdentifier = namedType.name as PrefixedIdentifier;
      expect(typeIdentifier.staticElement, aClass);

      expect(typeIdentifier.prefix.name, 'b');
      expect(
        typeIdentifier.prefix.staticElement,
        same(bImport.prefix?.element),
      );

      expect(typeIdentifier.identifier.staticElement, aClass);
    }

    {
      var declaration = unit.declarations[1] as TopLevelVariableDeclaration;
      var namedType = declaration.variables.type as NamedType;

      var typeIdentifier = namedType.name as PrefixedIdentifier;
      expect(typeIdentifier.staticElement, aClass);

      expect(typeIdentifier.prefix.name, 'c');
      expect(
        typeIdentifier.prefix.staticElement,
        same(cImport.prefix?.element),
      );

      expect(typeIdentifier.identifier.staticElement, aClass);
    }
  }

  test_typeLiteral() async {
    addTestFile(r'''
void main() {
  int;
  F;
}
typedef void F(int p);
''');
    await resolveTestFile();
    CompilationUnit unit = result.unit;

    var fNode = unit.declarations[1] as FunctionTypeAlias;
    TypeAliasElement fElement = fNode.declaredElement!;

    var statements = _getMainStatements(result);

    {
      var statement = statements[0] as ExpressionStatement;
      var identifier = statement.expression as SimpleIdentifier;
      expect(identifier.staticElement, same(typeProvider.intType.element));
      expect(identifier.staticType, typeProvider.typeType);
    }

    {
      var statement = statements[1] as ExpressionStatement;
      var identifier = statement.expression as SimpleIdentifier;
      expect(identifier.staticElement, same(fElement));
      expect(identifier.staticType, typeProvider.typeType);
    }
  }

  test_typeParameter() async {
    addTestFile(r'''
class C<T> {
  get t => T;
}
''');
    await resolveTestFile();

    var identifier = findNode.simple('T;');
    assertElement(identifier, findElement.typeParameter('T'));
    assertType(identifier, 'Type');
  }

  test_unresolved_methodInvocation_noTarget() async {
    addTestFile(r'''
int arg1, arg2;
main() {
  bar<int, double>(arg1, p2: arg2);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;

    var invocation = statement.expression as MethodInvocation;
    expect(invocation.target, isNull);
    expect(invocation.staticType, isDynamicType);
    assertUnresolvedInvokeType(invocation.staticInvokeType!);

    SimpleIdentifier name = invocation.methodName;
    expect(name.staticElement, isNull);
    expect(name.staticType, isDynamicType);

    assertTypeArguments(invocation.typeArguments!, [intType, doubleType]);
    _assertInvocationArguments(invocation.argumentList,
        [checkTopVarRef('arg1'), checkTopVarUndefinedNamedRef('arg2')]);
  }

  test_unresolved_methodInvocation_target_resolved() async {
    addTestFile(r'''
Object foo;
int arg1, arg2;
main() {
  foo.bar<int, double>(arg1, p2: arg2);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    TopLevelVariableElement foo = _getTopLevelVariable(result, 'foo');

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;

    var invocation = statement.expression as MethodInvocation;
    expect(invocation.staticType, isDynamicType);
    assertUnresolvedInvokeType(invocation.staticInvokeType!);

    var target = invocation.target as SimpleIdentifier;
    expect(target.staticElement, same(foo.getter));
    expect(target.staticType, typeProvider.objectType);

    SimpleIdentifier name = invocation.methodName;
    expect(name.staticElement, isNull);
    assertUnresolvedInvokeType(name.typeOrThrow);

    assertTypeArguments(invocation.typeArguments!, [intType, doubleType]);
    _assertInvocationArguments(invocation.argumentList,
        [checkTopVarRef('arg1'), checkTopVarUndefinedNamedRef('arg2')]);
  }

  test_unresolved_methodInvocation_target_unresolved() async {
    addTestFile(r'''
int arg1, arg2;
main() {
  foo.bar<int, double>(arg1, p2: arg2);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var invocation = findNode.methodInvocation('foo.bar');
    assertTypeDynamic(invocation);
    assertUnresolvedInvokeType(invocation.staticInvokeType!);

    var target = invocation.target as SimpleIdentifier;
    assertElementNull(target);
    assertTypeDynamic(target);

    SimpleIdentifier name = invocation.methodName;
    assertElementNull(name);
    assertUnresolvedInvokeType(name.typeOrThrow);

    assertTypeArguments(invocation.typeArguments!, [intType, doubleType]);
    _assertInvocationArguments(invocation.argumentList,
        [checkTopVarRef('arg1'), checkTopVarUndefinedNamedRef('arg2')]);
  }

  test_unresolved_prefixedIdentifier_identifier() async {
    addTestFile(r'''
Object foo;
main() {
  foo.bar;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    TopLevelVariableElement foo = _getTopLevelVariable(result, 'foo');

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;

    var prefixed = statement.expression as PrefixedIdentifier;
    expect(prefixed.staticElement, isNull);
    expect(prefixed.staticType, isDynamicType);

    SimpleIdentifier prefix = prefixed.prefix;
    expect(prefix.staticElement, same(foo.getter));
    expect(prefix.staticType, typeProvider.objectType);

    SimpleIdentifier identifier = prefixed.identifier;
    expect(identifier.staticElement, isNull);
    expect(identifier.staticType, isDynamicType);
  }

  test_unresolved_prefixedIdentifier_prefix() async {
    addTestFile(r'''
main() {
  foo.bar;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;

    var prefixed = statement.expression as PrefixedIdentifier;
    expect(prefixed.staticElement, isNull);
    expect(prefixed.staticType, isDynamicType);

    SimpleIdentifier prefix = prefixed.prefix;
    expect(prefix.staticElement, isNull);
    expect(prefix.staticType, isDynamicType);

    SimpleIdentifier identifier = prefixed.identifier;
    expect(identifier.staticElement, isNull);
    expect(identifier.staticType, isDynamicType);
  }

  test_unresolved_propertyAccess_1() async {
    addTestFile(r'''
main() {
  foo.bar.baz;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;

    var propertyAccess = statement.expression as PropertyAccess;
    expect(propertyAccess.staticType, isDynamicType);

    {
      var prefixed = propertyAccess.target as PrefixedIdentifier;
      expect(prefixed.staticElement, isNull);
      expect(prefixed.staticType, isDynamicType);

      SimpleIdentifier prefix = prefixed.prefix;
      expect(prefix.staticElement, isNull);
      expect(prefix.staticType, isDynamicType);

      SimpleIdentifier identifier = prefixed.identifier;
      expect(identifier.staticElement, isNull);
      expect(identifier.staticType, isDynamicType);
    }

    SimpleIdentifier property = propertyAccess.propertyName;
    expect(property.staticElement, isNull);
    expect(property.staticType, isDynamicType);
  }

  test_unresolved_propertyAccess_2() async {
    addTestFile(r'''
Object foo;
main() {
  foo.bar.baz;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    TopLevelVariableElement foo = _getTopLevelVariable(result, 'foo');

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;

    var propertyAccess = statement.expression as PropertyAccess;
    expect(propertyAccess.staticType, isDynamicType);

    {
      var prefixed = propertyAccess.target as PrefixedIdentifier;
      expect(prefixed.staticElement, isNull);
      expect(prefixed.staticType, isDynamicType);

      SimpleIdentifier prefix = prefixed.prefix;
      expect(prefix.staticElement, same(foo.getter));
      expect(prefix.staticType, typeProvider.objectType);

      SimpleIdentifier identifier = prefixed.identifier;
      expect(identifier.staticElement, isNull);
      expect(identifier.staticType, isDynamicType);
    }

    SimpleIdentifier property = propertyAccess.propertyName;
    expect(property.staticElement, isNull);
    expect(property.staticType, isDynamicType);
  }

  test_unresolved_redirectingFactory_1() async {
    addTestFile(r'''
class A {
  factory A() = B;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
  }

  test_unresolved_redirectingFactory_22() async {
    addTestFile(r'''
class A {
  factory A() = B.named;
}
class B {}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var bRef = findNode.simple('B.');
    assertElement(bRef, findElement.class_('B'));
    assertTypeNull(bRef);

    var namedRef = findNode.simple('named;');
    assertElementNull(namedRef);
    assertTypeNull(namedRef);
  }

  test_unresolved_simpleIdentifier() async {
    addTestFile(r'''
main() {
  foo;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;
    var identifier = statement.expression as SimpleIdentifier;
    expect(identifier.staticElement, isNull);
    expect(identifier.staticType, isDynamicType);
  }

  /// Assert that the [argument] is associated with the [expected]. If the
  /// [argument] is a [NamedExpression], the name must be resolved to the
  /// parameter.
  void _assertArgumentToParameter(
      Expression argument, ParameterElement expected,
      {DartType? memberType}) {
    ParameterElement actual = argument.staticParameterElement!;
    if (memberType != null) {
      expect(actual.type, memberType);
    }

    expect(actual.declaration, same(expected));

    if (argument is NamedExpression) {
      SimpleIdentifier name = argument.name.label;
      expect(name.staticElement, same(actual));
      expect(name.staticType, isNull);
    }
  }

  /// Assert that the given [creation] creates instance of the [classElement].
  /// Limitations: no import prefix, no type arguments, unnamed constructor.
  void _assertConstructorInvocation(
      InstanceCreationExpression creation, ClassElement classElement) {
    assertType(creation, classElement.name);

    var constructorName = creation.constructorName;
    var constructorElement = classElement.unnamedConstructor;
    expect(constructorName.staticElement, constructorElement);

    var namedType = constructorName.type;
    expect(namedType.typeArguments, isNull);

    var typeIdentifier = namedType.name as SimpleIdentifier;
    assertElement(typeIdentifier, classElement);
    assertTypeNull(typeIdentifier);

    // Only unnamed constructors are supported now.
    expect(constructorName.name, isNull);
  }

  void _assertDefaultParameter(
      DefaultFormalParameter node, ParameterElement element,
      {String? name, int? offset, ParameterKind? kind, DartType? type}) {
    expect(node, isNotNull);
    var normalNode = node.parameter as SimpleFormalParameter;
    _assertSimpleParameter(normalNode, element,
        name: name, offset: offset, kind: kind, type: type);
  }

  /// Test that [argumentList] has exactly two arguments - required `arg1`, and
  /// unresolved named `arg2`, both are the reference to top-level variables.
  void _assertInvocationArguments(ArgumentList argumentList,
      List<void Function(Expression)> argumentCheckers) {
    expect(argumentList.arguments, hasLength(argumentCheckers.length));
    for (int i = 0; i < argumentCheckers.length; i++) {
      argumentCheckers[i](argumentList.arguments[i]);
    }
  }

  void _assertNamedTypeSimple(TypeAnnotation namedType, InterfaceType type) {
    namedType as NamedType;
    expect(namedType.type, type);

    var identifier = namedType.name as SimpleIdentifier;
    expect(identifier.staticElement, same(type.element));
    expect(identifier.staticType, isNull);
  }

  void _assertParameterElement(ParameterElement element,
      {String? name, int? offset, ParameterKind? kind, DartType? type}) {
    expect(element, isNotNull);
    expect(name, isNotNull);
    expect(offset, isNotNull);
    expect(kind, isNotNull);
    expect(type, isNotNull);
    expect(element.name, name);
    expect(element.nameOffset, offset);
    // ignore: deprecated_member_use_from_same_package
    expect(element.parameterKind, kind);
    expect(element.type, type);
  }

  void _assertSimpleParameter(
      SimpleFormalParameter node, ParameterElement element,
      {String? name, int? offset, ParameterKind? kind, DartType? type}) {
    _assertParameterElement(element,
        name: name, offset: offset, kind: kind, type: type);

    expect(node, isNotNull);
    expect(node.declaredElement, same(element));

    var namedType = node.type as NamedType?;
    if (namedType != null) {
      expect(namedType.type, type);
      if (type is InterfaceType) {
        expect(namedType.name.staticElement, same(type.element));
      } else if (type is TypeParameterType) {
        expect(namedType.name.staticElement, same(type.element));
      } else {
        throw UnimplementedError();
      }
    }
  }

  List<Statement> _getMainStatements(ResolvedUnitResult result) {
    for (var declaration in result.unit.declarations) {
      if (declaration is FunctionDeclaration &&
          declaration.name.lexeme == 'main') {
        var body = declaration.functionExpression.body as BlockFunctionBody;
        return body.block.statements;
      }
    }
    fail('Not found main() in ${result.unit}');
  }

  TopLevelVariableElement _getTopLevelVariable(
      ResolvedUnitResult result, String name) {
    for (var variable in result.unit.declaredElement!.topLevelVariables) {
      if (variable.name == name) {
        return variable;
      }
    }
    fail('Not found $name');
  }
}
