// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'migration_visitor_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NodeBuilderTest);
  });
}

@reflectiveTest
class NodeBuilderTest extends MigrationVisitorTestBase {
  /// Gets the [DecoratedType] associated with the function declaration whose
  /// name matches [search].
  DecoratedType decoratedFunctionType(String search) =>
      variables.decoratedElementType(
          findNode.functionDeclaration(search).declaredElement);

  DecoratedType decoratedTypeParameterBound(String search) =>
      variables.decoratedTypeParameterBound(
          findNode.typeParameter(search).declaredElement);

  Future<void> test_catch_clause_with_stacktrace_with_on() async {
    await analyze('''
void f() {
  try {} on String catch (ex, st) {}
}
''');
    var exceptionType =
        variables.decoratedElementType(findNode.simple('ex').staticElement);
    expect(exceptionType.node, TypeMatcher<NullabilityNodeMutable>());
    var stackTraceType =
        variables.decoratedElementType(findNode.simple('st').staticElement);
    assertEdge(stackTraceType.node, never, hard: true, checkable: false);
  }

  Future<void> test_catch_clause_with_stacktrace_without_on() async {
    await analyze('''
void f() {
  try {} catch (ex, st) {}
}
''');
    var exceptionType =
        variables.decoratedElementType(findNode.simple('ex').staticElement);
    expect(exceptionType.node.isImmutable, false);
    var stackTraceType =
        variables.decoratedElementType(findNode.simple('st').staticElement);
    assertEdge(stackTraceType.node, never, hard: true, checkable: false);
  }

  Future<void> test_catch_clause_without_catch() async {
    await analyze('''
void f() {
  try {} on String {}
}
''');
    // No assertions, since no variables are declared; we just want to make sure
    // we don't crash.
  }

  Future<void> test_catch_clause_without_stacktrace_with_on() async {
    await analyze('''
void f() {
  try {} on String catch (ex) {}
}
''');
    var exceptionType =
        variables.decoratedElementType(findNode.simple('ex').staticElement);
    expect(exceptionType.node, TypeMatcher<NullabilityNodeMutable>());
  }

  Future<void> test_catch_clause_without_stacktrace_without_on() async {
    await analyze('''
void f() {
  try {} catch (ex) {}
}
''');
    var exceptionType =
        variables.decoratedElementType(findNode.simple('ex').staticElement);
    expect(exceptionType.node.isImmutable, false);
  }

  Future<void> test_class_alias_synthetic_constructors_no_parameters() async {
    await analyze('''
class C {
  C.a();
  C.b();
}
mixin M {}
class D = C with M;
''');
    var constructors = findElement.class_('D').constructors;
    expect(constructors, hasLength(2));
    var a = findElement.constructor('a', of: 'D');
    var aType = variables.decoratedElementType(a);
    expect(aType.type.toString(), 'D Function()');
    expect(aType.node, same(never));
    expect(aType.typeArguments, isEmpty);
    expect(aType.returnType.type.toString(), 'D');
    expect(aType.returnType.node, same(never));
    var b = findElement.constructor('b', of: 'D');
    var bType = variables.decoratedElementType(b);
    expect(bType.type.toString(), 'D Function()');
    expect(bType.node, same(never));
    expect(bType.typeArguments, isEmpty);
    expect(bType.returnType.type.toString(), 'D');
    expect(bType.returnType.node, same(never));
  }

  Future<void> test_class_alias_synthetic_constructors_with_parameters() async {
    await analyze('''
class C {
  C.a(int i);
  C.b([int i]);
  C.c({int i});
  C.d(List<int> x);
}
mixin M {}
class D = C with M;
''');
    var constructors = findElement.class_('D').constructors;
    expect(constructors, hasLength(4));
    var a = findElement.constructor('a', of: 'D');
    var aType = variables.decoratedElementType(a);
    expect(aType.type.toString(), 'D Function(int)');
    expect(aType.node, same(never));
    expect(aType.typeArguments, isEmpty);
    expect(aType.returnType.type.toString(), 'D');
    expect(aType.returnType.node, same(never));
    expect(aType.positionalParameters, hasLength(1));
    expect(aType.positionalParameters[0].type.toString(), 'int');
    expect(aType.positionalParameters[0].node,
        TypeMatcher<NullabilityNodeMutable>());
    expect(aType.namedParameters, isEmpty);
    var b = findElement.constructor('b', of: 'D');
    var bType = variables.decoratedElementType(b);
    expect(bType.type.toString(), 'D Function([int])');
    expect(bType.node, same(never));
    expect(bType.typeArguments, isEmpty);
    expect(bType.returnType.type.toString(), 'D');
    expect(bType.returnType.node, same(never));
    expect(bType.positionalParameters, hasLength(1));
    expect(bType.positionalParameters[0].type.toString(), 'int');
    expect(bType.positionalParameters[0].node,
        TypeMatcher<NullabilityNodeMutable>());
    expect(bType.namedParameters, isEmpty);
    var c = findElement.constructor('c', of: 'D');
    var cType = variables.decoratedElementType(c);
    expect(cType.type.toString(), 'D Function({int i})');
    expect(cType.node, same(never));
    expect(cType.typeArguments, isEmpty);
    expect(cType.returnType.type.toString(), 'D');
    expect(cType.returnType.node, same(never));
    expect(cType.positionalParameters, isEmpty);
    expect(cType.namedParameters, hasLength(1));
    expect(cType.namedParameters, contains('i'));
    expect(cType.namedParameters['i'].type.toString(), 'int');
    expect(
        cType.namedParameters['i'].node, TypeMatcher<NullabilityNodeMutable>());
    var d = findElement.constructor('d', of: 'D');
    var dType = variables.decoratedElementType(d);
    expect(dType.type.toString(), 'D Function(List<int>)');
    expect(dType.node, same(never));
    expect(dType.typeArguments, isEmpty);
    expect(dType.returnType.type.toString(), 'D');
    expect(dType.returnType.node, same(never));
    expect(dType.positionalParameters, hasLength(1));
    expect(dType.positionalParameters[0].type.toString(), 'List<int>');
    expect(dType.positionalParameters[0].node,
        TypeMatcher<NullabilityNodeMutable>());
    expect(dType.positionalParameters[0].typeArguments, hasLength(1));
    expect(
        dType.positionalParameters[0].typeArguments[0].type.toString(), 'int');
    expect(dType.positionalParameters[0].typeArguments[0].node,
        TypeMatcher<NullabilityNodeMutable>());
    expect(dType.namedParameters, isEmpty);
  }

  Future<void>
      test_class_alias_synthetic_constructors_with_parameters_generic() async {
    await analyze('''
class C<T> {
  C(T t);
}
mixin M {}
class D<U> = C<U> with M;
''');
    var dConstructor = findElement.unnamedConstructor('D');
    var dConstructorType = variables.decoratedElementType(dConstructor);
    expect(dConstructorType.type.toString(), 'D<U> Function(U)');
    expect(dConstructorType.node, same(never));
    expect(dConstructorType.typeFormals, isEmpty);
    expect(dConstructorType.returnType.type.toString(), 'D<U>');
    expect(dConstructorType.returnType.node, same(never));
    var typeArguments = dConstructorType.returnType.typeArguments;
    expect(typeArguments, hasLength(1));
    expect(typeArguments[0].type.toString(), 'U');
    expect(typeArguments[0].node, same(never));
    var dParams = dConstructorType.positionalParameters;
    expect(dParams, hasLength(1));
    expect(dParams[0].type.toString(), 'U');
    expect(dParams[0].node, TypeMatcher<NullabilityNodeMutable>());
  }

  Future<void> test_class_with_default_constructor() async {
    await analyze('''
class C {}
''');
    var defaultConstructor = findElement.class_('C').constructors.single;
    var decoratedConstructorType =
        variables.decoratedElementType(defaultConstructor);
    expect(decoratedConstructorType.type.toString(), 'C Function()');
    expect(decoratedConstructorType.node, same(never));
    expect(decoratedConstructorType.returnType.type.toString(), 'C');
    expect(decoratedConstructorType.returnType.node, same(never));
  }

  Future<void> test_class_with_default_constructor_generic() async {
    await analyze('''
class C<T, U> {}
''');
    var defaultConstructor = findElement.class_('C').constructors.single;
    var decoratedConstructorType =
        variables.decoratedElementType(defaultConstructor);
    expect(decoratedConstructorType.type.toString(), 'C<T, U> Function()');
    expect(decoratedConstructorType.node, same(never));
    expect(decoratedConstructorType.typeArguments, isEmpty);
    var returnType = decoratedConstructorType.returnType;
    expect(returnType.type.toString(), 'C<T, U>');
    expect(returnType.node, same(never));
    expect(returnType.typeArguments, hasLength(2));
    expect(returnType.typeArguments[0].type.toString(), 'T');
    expect(returnType.typeArguments[0].node, same(never));
    expect(returnType.typeArguments[1].type.toString(), 'U');
    expect(returnType.typeArguments[1].node, same(never));
  }

  Future<void> test_constructor_factory() async {
    await analyze('''
class C {
  C._();
  factory C() => C._();
}
''');
    var decoratedType = decoratedConstructorDeclaration('C(').returnType;
    expect(decoratedType.node, same(never));
  }

  Future<void> test_constructor_metadata() async {
    await analyze('''
class A {
  final Object x;
  const A(this.x);
}
class C {
  @A(<int>[])
  C();
}
''');
    var node = decoratedTypeAnnotation('int').node;
    expect(node, TypeMatcher<NullabilityNodeMutable>());
  }

  Future<void> test_constructor_returnType_implicit_dynamic() async {
    await analyze('''
class C {
  C();
}
''');
    var decoratedType = decoratedConstructorDeclaration('C(').returnType;
    expect(decoratedType.node, same(never));
  }

  Future<void> test_constructorFieldInitializer_visit_expression() async {
    await analyze('''
class C {
  C() : f = <int>[];
  Object f;
}
''');
    var node = decoratedTypeAnnotation('int').node;
    expect(node, TypeMatcher<NullabilityNodeMutable>());
  }

  Future<void> test_directSupertypes_class_extends() async {
    await analyze('''
class C<T, U> {}
class D<V> extends C<int, V> {}
''');
    var types = decoratedDirectSupertypes('D');
    var decorated = types[findElement.class_('C')];
    expect(decorated.type.toString(), 'C<int, V>');
    expect(decorated.node, same(never));
    expect(decorated.typeArguments, hasLength(2));
    expect(decorated.typeArguments[0].node,
        same(decoratedTypeAnnotation('int').node));
    expect(decorated.typeArguments[1].node,
        same(decoratedTypeAnnotation('V> {').node));
  }

  Future<void> test_directSupertypes_class_extends_default() async {
    await analyze('''
class C<T, U> {}
''');
    var types = decoratedDirectSupertypes('C');
    var decorated = types[typeProvider.objectType.element];
    expect(decorated.type.toString(), 'Object');
    assertEdge(decorated.node, never, hard: true, checkable: false);
    expect(decorated.typeArguments, isEmpty);
  }

  Future<void> test_directSupertypes_class_implements() async {
    await analyze('''
class C<T, U> {}
class D<V> implements C<int, V> {}
''');
    var types = decoratedDirectSupertypes('D');
    var decorated = types[findElement.class_('C')];
    expect(decorated.type.toString(), 'C<int, V>');
    expect(decorated.node, same(never));
    expect(decorated.typeArguments, hasLength(2));
    expect(decorated.typeArguments[0].node,
        same(decoratedTypeAnnotation('int').node));
    expect(decorated.typeArguments[1].node,
        same(decoratedTypeAnnotation('V> {').node));
  }

  Future<void> test_directSupertypes_class_with() async {
    await analyze('''
class C<T, U> {}
class D<V> extends Object with C<int, V> {}
''');
    var types = decoratedDirectSupertypes('D');
    var decorated = types[findElement.class_('C')];
    expect(decorated.type.toString(), 'C<int, V>');
    expect(decorated.node, same(never));
    expect(decorated.typeArguments, hasLength(2));
    expect(decorated.typeArguments[0].node,
        same(decoratedTypeAnnotation('int').node));
    expect(decorated.typeArguments[1].node,
        same(decoratedTypeAnnotation('V> {').node));
  }

  Future<void> test_directSupertypes_classAlias_extends() async {
    await analyze('''
class M {}
class C<T, U> {}
class D<V> = C<int, V> with M;
''');
    var types = decoratedDirectSupertypes('D');
    var decorated = types[findElement.class_('C')];
    expect(decorated.type.toString(), 'C<int, V>');
    expect(decorated.node, same(never));
    expect(decorated.typeArguments, hasLength(2));
    expect(decorated.typeArguments[0].node,
        same(decoratedTypeAnnotation('int').node));
    expect(decorated.typeArguments[1].node,
        same(decoratedTypeAnnotation('V> w').node));
  }

  Future<void> test_directSupertypes_classAlias_implements() async {
    await analyze('''
class M {}
class C<T, U> {}
class D<V> = Object with M implements C<int, V>;
''');
    var types = decoratedDirectSupertypes('D');
    var decorated = types[findElement.class_('C')];
    expect(decorated.type.toString(), 'C<int, V>');
    expect(decorated.node, same(never));
    expect(decorated.typeArguments, hasLength(2));
    expect(decorated.typeArguments[0].node,
        same(decoratedTypeAnnotation('int').node));
    expect(decorated.typeArguments[1].node,
        same(decoratedTypeAnnotation('V>;').node));
  }

  Future<void> test_directSupertypes_classAlias_with() async {
    await analyze('''
class C<T, U> {}
class D<V> = Object with C<int, V>;
''');
    var types = decoratedDirectSupertypes('D');
    var decorated = types[findElement.class_('C')];
    expect(decorated.type.toString(), 'C<int, V>');
    expect(decorated.node, same(never));
    expect(decorated.typeArguments, hasLength(2));
    expect(decorated.typeArguments[0].node,
        same(decoratedTypeAnnotation('int').node));
    expect(decorated.typeArguments[1].node,
        same(decoratedTypeAnnotation('V>;').node));
  }

  Future<void> test_directSupertypes_dartCoreClass() async {
    await analyze('''
abstract class D<V> extends Iterable<V> {}
''');
    var types = decoratedDirectSupertypes('D');
    var super_ = types.values.single;
    expect(super_.type.toString(), 'Iterable<V>');
    expect(super_.node, same(never));
    expect(super_.typeArguments, hasLength(1));
    expect(super_.typeArguments[0].node,
        same(decoratedTypeAnnotation('V> {').node));
  }

  Future<void> test_directSupertypes_mixin_extends_default() async {
    await analyze('''
mixin C<T, U> {}
''');
    var types = decoratedDirectSupertypes('C');
    var decorated = types[typeProvider.objectType.element];
    expect(decorated.type.toString(), 'Object');
    assertEdge(decorated.node, never, hard: true, checkable: false);
    expect(decorated.typeArguments, isEmpty);
  }

  Future<void> test_directSupertypes_mixin_implements() async {
    await analyze('''
class C<T, U> {}
mixin D<V> implements C<int, V> {}
''');
    var types = decoratedDirectSupertypes('D');
    var decorated = types[findElement.class_('C')];
    expect(decorated.type.toString(), 'C<int, V>');
    expect(decorated.node, same(never));
    expect(decorated.typeArguments, hasLength(2));
    expect(decorated.typeArguments[0].node,
        same(decoratedTypeAnnotation('int').node));
    expect(decorated.typeArguments[1].node,
        same(decoratedTypeAnnotation('V> {').node));
  }

  Future<void> test_directSupertypes_mixin_on() async {
    await analyze('''
class C<T, U> {}
mixin D<V> on C<int, V> {}
''');
    var types = decoratedDirectSupertypes('D');
    var decorated = types[findElement.class_('C')];
    expect(decorated.type.toString(), 'C<int, V>');
    expect(decorated.node, same(never));
    expect(decorated.typeArguments, hasLength(2));
    expect(decorated.typeArguments[0].node,
        same(decoratedTypeAnnotation('int').node));
    expect(decorated.typeArguments[1].node,
        same(decoratedTypeAnnotation('V> {').node));
  }

  Future<void> test_dynamic_type() async {
    await analyze('''
dynamic f() {}
''');
    var decoratedType = decoratedTypeAnnotation('dynamic');
    expect(decoratedFunctionType('f').returnType, same(decoratedType));
    assertNoEdge(always, decoratedType.node);
  }

  Future<void> test_field_type_implicit_dynamic() async {
    await analyze('''
class C {
  var x;
}
''');
    var decoratedType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedType.node.isImmutable, false);
  }

  Future<void> test_field_type_inferred() async {
    await analyze('''
class C {
  var x = 1;
}
''');
    var decoratedType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
  }

  Future<void> test_field_type_inferred_dynamic() async {
    await analyze('''
dynamic f() {}
class C {
  var x = f();
}
''');
    var decoratedType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedType.node.isImmutable, false);
  }

  Future<void> test_field_type_simple() async {
    await analyze('''
class C {
  int f = 0;
}
''');
    var decoratedType = decoratedTypeAnnotation('int');
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(
        variables.decoratedElementType(
            findNode.fieldDeclaration('f').fields.variables[0].declaredElement),
        same(decoratedType));
  }

  Future<void> test_fieldFormalParameter_function_namedParameter_typed() async {
    await analyze('''
class C {
  Object f;
  C(void this.f({int i}));
}
''');
    var ctor = findElement.unnamedConstructor('C');
    var ctorParam = ctor.parameters[0];
    var ctorType = variables.decoratedElementType(ctor);
    var ctorParamType = variables.decoratedElementType(ctorParam);
    expect(ctorType.positionalParameters[0], same(ctorParamType));
    expect(ctorParamType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(ctorParamType.namedParameters['i'],
        same(decoratedTypeAnnotation('int')));
  }

  Future<void>
      test_fieldFormalParameter_function_namedParameter_untyped() async {
    await analyze('''
class C {
  Object f;
  C(void this.f({i}));
}
''');
    var ctor = findElement.unnamedConstructor('C');
    var ctorParam = ctor.parameters[0];
    var ctorType = variables.decoratedElementType(ctor);
    var ctorParamType = variables.decoratedElementType(ctorParam);
    expect(ctorType.positionalParameters[0], same(ctorParamType));
    expect(ctorParamType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(ctorParamType.namedParameters['i'].type.toString(), 'dynamic');
    expect(ctorParamType.namedParameters['i'].node.isImmutable, false);
  }

  Future<void>
      test_fieldFormalParameter_function_positionalParameter_typed() async {
    await analyze('''
class C {
  Object f;
  C(void this.f(int i));
}
''');
    var ctor = findElement.unnamedConstructor('C');
    var ctorParam = ctor.parameters[0];
    var ctorType = variables.decoratedElementType(ctor);
    var ctorParamType = variables.decoratedElementType(ctorParam);
    expect(ctorType.positionalParameters[0], same(ctorParamType));
    expect(ctorParamType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(ctorParamType.positionalParameters[0],
        same(decoratedTypeAnnotation('int')));
  }

  Future<void>
      test_fieldFormalParameter_function_positionalParameter_untyped() async {
    await analyze('''
class C {
  Object f;
  C(void this.f(i));
}
''');
    var ctor = findElement.unnamedConstructor('C');
    var ctorParam = ctor.parameters[0];
    var ctorType = variables.decoratedElementType(ctor);
    var ctorParamType = variables.decoratedElementType(ctorParam);
    expect(ctorType.positionalParameters[0], same(ctorParamType));
    expect(ctorParamType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(ctorParamType.positionalParameters[0].type.toString(), 'dynamic');
    expect(ctorParamType.positionalParameters[0].node.isImmutable, false);
  }

  Future<void> test_fieldFormalParameter_function_return_typed() async {
    await analyze('''
class C {
  Object f;
  C(int this.f());
}
''');
    var ctor = findElement.unnamedConstructor('C');
    var ctorParam = ctor.parameters[0];
    var ctorType = variables.decoratedElementType(ctor);
    var ctorParamType = variables.decoratedElementType(ctorParam);
    expect(ctorType.positionalParameters[0], same(ctorParamType));
    expect(ctorParamType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(ctorParamType.returnType, same(decoratedTypeAnnotation('int')));
  }

  Future<void> test_fieldFormalParameter_function_return_untyped() async {
    await analyze('''
class C {
  Object f;
  C(this.f()) {}
}
''');
    var ctor = findElement.unnamedConstructor('C');
    var ctorParam = ctor.parameters[0];
    var ctorType = variables.decoratedElementType(ctor);
    var ctorParamType = variables.decoratedElementType(ctorParam);
    expect(ctorType.positionalParameters[0], same(ctorParamType));
    expect(ctorParamType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(ctorParamType.returnType.type.toString(), 'dynamic');
    expect(ctorParamType.returnType.node.isImmutable, false);
  }

  Future<void> test_fieldFormalParameter_typed() async {
    await analyze('''
class C {
  int i;
  C.named(int this.i);
}
''');
    var decoratedConstructorParamType =
        decoratedConstructorDeclaration('named').positionalParameters[0];
    expect(decoratedTypeAnnotation('int this'),
        same(decoratedConstructorParamType));
    expect(decoratedConstructorParamType.type.toString(), 'int');
    expect(decoratedConstructorParamType.node,
        TypeMatcher<NullabilityNodeMutable>());
    // Note: the edge builder will connect this node to the node for the type of
    // the field.
  }

  Future<void> test_fieldFormalParameter_untyped() async {
    await analyze('''
class C {
  int i;
  C.named(this.i);
}
''');
    var decoratedConstructorParamType =
        decoratedConstructorDeclaration('named').positionalParameters[0];
    expect(decoratedConstructorParamType.type.toString(), 'int');
    expect(decoratedConstructorParamType.node,
        TypeMatcher<NullabilityNodeMutable>());
    // Note: the edge builder will unify this implicit type with the type of the
    // field.
  }

  Future<void> test_function_generic_bounded() async {
    await analyze('''
T f<T extends Object>(T t) => t;
''');
    var decoratedType = decoratedFunctionType('f');
    var bound = decoratedTypeParameterBound('T extends');
    expect(decoratedType.typeFormalBounds[0], same(bound));
    expect(decoratedTypeAnnotation('Object'), same(bound));
    expect(bound.node, isNot(always));
    expect(bound.type, typeProvider.objectType);
  }

  Future<void> test_function_generic_implicit_bound() async {
    await analyze('''
T f<T>(T t) => t;
''');
    var decoratedType = decoratedFunctionType('f');
    var bound = decoratedTypeParameterBound('T>');
    expect(decoratedType.typeFormalBounds[0], same(bound));
    assertEdge(always, bound.node, hard: false);
    expect(bound.type, same(typeProvider.objectType));
  }

  Future<void> test_function_metadata() async {
    await analyze('''
class A {
  final Object x;
  const A(this.x);
}
@A(<int>[])
f() {}
''');
    var node = decoratedTypeAnnotation('int').node;
    expect(node, TypeMatcher<NullabilityNodeMutable>());
  }

  Future<void> test_functionExpression() async {
    await analyze('''
void f() {
  var x = (int i) => 1;
}
''');
    var functionExpressionElement =
        findNode.simpleParameter('int i').declaredElement.enclosingElement;
    var decoratedType =
        variables.decoratedElementType(functionExpressionElement);
    expect(decoratedType.positionalParameters[0],
        same(decoratedTypeAnnotation('int i')));
    expect(decoratedType.node, same(never));
    expect(
        decoratedType.returnType.node, TypeMatcher<NullabilityNodeMutable>());
  }

  Future<void> test_functionExpression_returns_bottom() async {
    await analyze('''
void f() {
  var x = (int i) => throw 'foo';
}
''');
    var functionExpressionElement =
        findNode.simpleParameter('int i').declaredElement.enclosingElement;
    var decoratedType =
        variables.decoratedElementType(functionExpressionElement);
    expect(
        decoratedType.returnType.node, TypeMatcher<NullabilityNodeMutable>());
  }

  Future<void> test_functionTypeAlias_generic() async {
    await analyze('''
typedef T F<T, U>(U u);
''');
    var element = findElement.functionTypeAlias('F');
    var decoratedType = variables.decoratedElementType(element);
    var t = element.typeParameters[0];
    var u = element.typeParameters[1];
    // typeFormals should be empty because this is not a generic function type,
    // it's a generic typedef that defines an ordinary (non-generic) function
    // type.
    expect(decoratedType.typeFormals, isEmpty);
    expect(decoratedType.returnType, same(decoratedTypeAnnotation('T F')));
    expect(
        (decoratedType.returnType.type as TypeParameterType).element, same(t));
    expect(
        decoratedType.returnType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(
        (decoratedType.positionalParameters[0].type as TypeParameterType)
            .element,
        same(u));
    expect(decoratedType.positionalParameters[0].node,
        TypeMatcher<NullabilityNodeMutable>());
  }

  Future<void> test_functionTypeAlias_implicit_return_type() async {
    await analyze('''
typedef F();
''');
    var decoratedType =
        variables.decoratedElementType(findElement.functionTypeAlias('F'));
    expect(decoratedType.returnType.type.isDynamic, isTrue);
    expect(decoratedType.returnType.node.isImmutable, false);
    expect(decoratedType.typeFormals, isEmpty);
  }

  Future<void> test_functionTypeAlias_simple() async {
    await analyze('''
typedef int F(String s);
''');
    var decoratedType =
        variables.decoratedElementType(findElement.functionTypeAlias('F'));
    expect(decoratedType.returnType, same(decoratedTypeAnnotation('int')));
    expect(decoratedType.typeFormals, isEmpty);
    expect(decoratedType.positionalParameters[0],
        same(decoratedTypeAnnotation('String')));
  }

  Future<void> test_functionTypedFormalParameter_namedParameter_typed() async {
    await analyze('''
void f(void g({int i})) {}
''');
    var f = findElement.function('f');
    var g = f.parameters[0];
    var fType = variables.decoratedElementType(f);
    var gType = variables.decoratedElementType(g);
    expect(fType.positionalParameters[0], same(gType));
    expect(gType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(gType.namedParameters['i'], same(decoratedTypeAnnotation('int')));
  }

  Future<void>
      test_functionTypedFormalParameter_namedParameter_untyped() async {
    await analyze('''
void f(void g({i})) {}
''');
    var f = findElement.function('f');
    var g = f.parameters[0];
    var fType = variables.decoratedElementType(f);
    var gType = variables.decoratedElementType(g);
    expect(fType.positionalParameters[0], same(gType));
    expect(gType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(gType.namedParameters['i'].type.toString(), 'dynamic');
    expect(gType.namedParameters['i'].node.isImmutable, false);
  }

  Future<void>
      test_functionTypedFormalParameter_positionalParameter_typed() async {
    await analyze('''
void f(void g(int i)) {}
''');
    var f = findElement.function('f');
    var g = f.parameters[0];
    var fType = variables.decoratedElementType(f);
    var gType = variables.decoratedElementType(g);
    expect(fType.positionalParameters[0], same(gType));
    expect(gType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(gType.positionalParameters[0], same(decoratedTypeAnnotation('int')));
  }

  Future<void>
      test_functionTypedFormalParameter_positionalParameter_untyped() async {
    await analyze('''
void f(void g(i)) {}
''');
    var f = findElement.function('f');
    var g = f.parameters[0];
    var fType = variables.decoratedElementType(f);
    var gType = variables.decoratedElementType(g);
    expect(fType.positionalParameters[0], same(gType));
    expect(gType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(gType.positionalParameters[0].type.toString(), 'dynamic');
    expect(gType.positionalParameters[0].node.isImmutable, false);
  }

  Future<void> test_functionTypedFormalParameter_return_typed() async {
    await analyze('''
void f(int g()) {}
''');
    var f = findElement.function('f');
    var g = f.parameters[0];
    var fType = variables.decoratedElementType(f);
    var gType = variables.decoratedElementType(g);
    expect(fType.positionalParameters[0], same(gType));
    expect(gType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(gType.returnType, same(decoratedTypeAnnotation('int')));
  }

  Future<void> test_functionTypedFormalParameter_return_untyped() async {
    await analyze('''
void f(g()) {}
''');
    var f = findElement.function('f');
    var g = f.parameters[0];
    var fType = variables.decoratedElementType(f);
    var gType = variables.decoratedElementType(g);
    expect(fType.positionalParameters[0], same(gType));
    expect(gType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(gType.returnType.type.toString(), 'dynamic');
    expect(gType.returnType.node.isImmutable, false);
  }

  Future<void>
      test_generic_function_type_syntax_inferred_dynamic_return() async {
    await analyze('''
abstract class C {
  Function() f();
}
''');
    var decoratedFType = decoratedMethodType('f');
    var decoratedFReturnType = decoratedFType.returnType;
    var decoratedFReturnReturnType = decoratedFReturnType.returnType;
    expect(decoratedFReturnReturnType.type.toString(), 'dynamic');
    expect(decoratedFReturnReturnType.node.isImmutable, false);
  }

  Future<void> test_genericFunctionType_formal_bounds() async {
    await analyze('''
void f(T Function<T extends num>() x) {}
''');
    var decoratedType = decoratedGenericFunctionTypeAnnotation('T Function');
    expect(decoratedType.typeFormalBounds[0].type.toString(), 'num');
  }

  Future<void> test_genericFunctionType_formals() async {
    await analyze('''
void f(T Function<T, U>(U) x) {}
''');
    var decoratedType = decoratedGenericFunctionTypeAnnotation('T Function');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedType));
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedType.type.toString(), 'T Function<T, U>(U)');
    expect(decoratedType.typeFormals, hasLength(2));
    var t = decoratedType.typeFormals[0];
    var u = decoratedType.typeFormals[1];
    expect(
        (decoratedType.returnType.type as TypeParameterType).element, same(t));
    expect(
        (decoratedType.positionalParameters[0].type as TypeParameterType)
            .element,
        same(u));
  }

  Future<void> test_genericFunctionType_namedParameterType() async {
    await analyze('''
void f(void Function({int y}) x) {}
''');
    var decoratedType =
        decoratedGenericFunctionTypeAnnotation('void Function({int y})');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedType));
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
    var decoratedIntType = decoratedTypeAnnotation('int');
    expect(decoratedType.namedParameters['y'], same(decoratedIntType));
    expect(decoratedIntType.node, isNotNull);
    expect(decoratedIntType.node, isNot(never));
  }

  Future<void> test_genericFunctionType_returnType() async {
    await analyze('''
void f(int Function() x) {}
''');
    var decoratedType =
        decoratedGenericFunctionTypeAnnotation('int Function()');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedType));
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
    var decoratedIntType = decoratedTypeAnnotation('int');
    expect(decoratedType.returnType, same(decoratedIntType));
    expect(decoratedIntType.node, isNotNull);
    expect(decoratedIntType.node, isNot(never));
  }

  Future<void> test_genericFunctionType_unnamedParameterType() async {
    await analyze('''
void f(void Function(int) x) {}
''');
    var decoratedType =
        decoratedGenericFunctionTypeAnnotation('void Function(int)');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedType));
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
    var decoratedIntType = decoratedTypeAnnotation('int');
    expect(decoratedType.positionalParameters[0], same(decoratedIntType));
    expect(decoratedIntType.node, isNotNull);
    expect(decoratedIntType.node, isNot(never));
  }

  Future<void> test_genericTypeAlias_generic_inner() async {
    await analyze('''
typedef F = T Function<T, U>(U u);
''');
    var element = findElement.functionTypeAlias('F');
    var decoratedType = variables.decoratedElementType(element);
    expect(decoratedType,
        same(decoratedGenericFunctionTypeAnnotation('T Function')));
    expect(decoratedType.typeFormals, hasLength(2));
    var t = decoratedType.typeFormals[0];
    var u = decoratedType.typeFormals[1];
    expect(decoratedType.returnType, same(decoratedTypeAnnotation('T F')));
    expect(
        (decoratedType.returnType.type as TypeParameterType).element, same(t));
    expect(
        decoratedType.returnType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(
        (decoratedType.positionalParameters[0].type as TypeParameterType)
            .element,
        same(u));
    expect(decoratedType.positionalParameters[0].node,
        TypeMatcher<NullabilityNodeMutable>());
  }

  Future<void> test_genericTypeAlias_generic_outer() async {
    await analyze('''
typedef F<T, U> = T Function(U u);
''');
    var element = findElement.functionTypeAlias('F');
    var decoratedType = variables.decoratedElementType(element);
    expect(decoratedType,
        same(decoratedGenericFunctionTypeAnnotation('T Function')));
    var t = element.typeParameters[0];
    var u = element.typeParameters[1];
    // typeFormals should be empty because this is not a generic function type,
    // it's a generic typedef that defines an ordinary (non-generic) function
    // type.
    expect(decoratedType.typeFormals, isEmpty);
    expect(decoratedType.returnType, same(decoratedTypeAnnotation('T F')));
    expect(
        (decoratedType.returnType.type as TypeParameterType).element, same(t));
    expect(
        decoratedType.returnType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(
        (decoratedType.positionalParameters[0].type as TypeParameterType)
            .element,
        same(u));
    expect(decoratedType.positionalParameters[0].node,
        TypeMatcher<NullabilityNodeMutable>());
  }

  Future<void> test_genericTypeAlias_implicit_return_type() async {
    await analyze('''
typedef F = Function();
''');
    var decoratedType =
        variables.decoratedElementType(findElement.functionTypeAlias('F'));
    expect(decoratedType,
        same(decoratedGenericFunctionTypeAnnotation('Function')));
    expect(decoratedType.returnType.type.isDynamic, isTrue);
    expect(decoratedType.returnType.node.isImmutable, false);
    expect(decoratedType.typeFormals, isEmpty);
  }

  Future<void> test_genericTypeAlias_simple() async {
    await analyze('''
typedef F = int Function(String s);
''');
    var decoratedType =
        variables.decoratedElementType(findElement.functionTypeAlias('F'));
    expect(decoratedType,
        same(decoratedGenericFunctionTypeAnnotation('int Function')));
    expect(decoratedType.returnType, same(decoratedTypeAnnotation('int')));
    expect(decoratedType.typeFormals, isEmpty);
    expect(decoratedType.positionalParameters[0],
        same(decoratedTypeAnnotation('String')));
  }

  Future<void> test_interfaceType_generic_instantiate_to_dynamic() async {
    await analyze('''
void f(List x) {}
''');
    var decoratedListType = decoratedTypeAnnotation('List');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedListType));
    expect(decoratedListType.node, isNotNull);
    expect(decoratedListType.node, isNot(never));
    var decoratedArgType = decoratedListType.typeArguments[0];
    expect(decoratedArgType.node.isImmutable, false);
  }

  Future<void> test_interfaceType_generic_instantiate_to_function_type() async {
    await analyze('''
class C<T extends int Function()> {}
void f(C x) {}
''');
    var decoratedCType = decoratedTypeAnnotation('C x');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedCType));
    expect(decoratedCType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedCType.typeArguments, hasLength(1));
    var decoratedArgType = decoratedCType.typeArguments[0];
    expect(decoratedArgType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArgType.typeArguments, isEmpty);
    var decoratedArgReturnType = decoratedArgType.returnType;
    expect(decoratedArgReturnType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArgReturnType.typeArguments, isEmpty);
  }

  Future<void>
      test_interfaceType_generic_instantiate_to_function_type_void() async {
    await analyze('''
class C<T extends void Function()> {}
void f(C x) {}
''');
    var decoratedCType = decoratedTypeAnnotation('C x');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedCType));
    expect(decoratedCType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedCType.typeArguments, hasLength(1));
    var decoratedArgType = decoratedCType.typeArguments[0];
    expect(decoratedArgType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArgType.typeArguments, isEmpty);
    var decoratedArgReturnType = decoratedArgType.returnType;
    expect(decoratedArgReturnType.node.isImmutable, false);
    expect(decoratedArgReturnType.typeArguments, isEmpty);
  }

  Future<void> test_interfaceType_generic_instantiate_to_generic_type() async {
    await analyze('''
class C<T> {}
class D<T extends C<int>> {}
void f(D x) {}
''');
    var decoratedDType = decoratedTypeAnnotation('D x');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedDType));
    expect(decoratedDType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedDType.typeArguments, hasLength(1));
    var decoratedArgType = decoratedDType.typeArguments[0];
    expect(decoratedArgType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArgType.typeArguments, hasLength(1));
    var decoratedArgArgType = decoratedArgType.typeArguments[0];
    expect(decoratedArgArgType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArgArgType.typeArguments, isEmpty);
  }

  Future<void>
      test_interfaceType_generic_instantiate_to_generic_type_2() async {
    await analyze('''
class C<T, U> {}
class D<T extends C<int, String>, U extends C<num, double>> {}
void f(D x) {}
''');
    var decoratedDType = decoratedTypeAnnotation('D x');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedDType));
    expect(decoratedDType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedDType.typeArguments, hasLength(2));
    var decoratedArg0Type = decoratedDType.typeArguments[0];
    expect(decoratedArg0Type.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArg0Type.typeArguments, hasLength(2));
    var decoratedArg0Arg0Type = decoratedArg0Type.typeArguments[0];
    expect(decoratedArg0Arg0Type.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArg0Arg0Type.typeArguments, isEmpty);
    var decoratedArg0Arg1Type = decoratedArg0Type.typeArguments[1];
    expect(decoratedArg0Arg1Type.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArg0Arg1Type.typeArguments, isEmpty);
    var decoratedArg1Type = decoratedDType.typeArguments[1];
    expect(decoratedArg1Type.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArg1Type.typeArguments, hasLength(2));
    var decoratedArg1Arg0Type = decoratedArg1Type.typeArguments[0];
    expect(decoratedArg1Arg0Type.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArg1Arg0Type.typeArguments, isEmpty);
    var decoratedArg1Arg1Type = decoratedArg1Type.typeArguments[1];
    expect(decoratedArg1Arg1Type.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArg1Arg1Type.typeArguments, isEmpty);
  }

  Future<void> test_interfaceType_generic_instantiate_to_object() async {
    await analyze('''
class C<T extends Object> {}
void f(C x) {}
''');
    var decoratedListType = decoratedTypeAnnotation('C x');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedListType));
    expect(decoratedListType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedListType.typeArguments, hasLength(1));
    var decoratedArgType = decoratedListType.typeArguments[0];
    expect(decoratedArgType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedArgType.typeArguments, isEmpty);
  }

  Future<void> test_interfaceType_typeParameter() async {
    await analyze('''
void f(List<int> x) {}
''');
    var decoratedListType = decoratedTypeAnnotation('List<int>');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedListType));
    expect(decoratedListType.node, isNotNull);
    expect(decoratedListType.node, isNot(never));
    var decoratedIntType = decoratedTypeAnnotation('int');
    expect(decoratedListType.typeArguments[0], same(decoratedIntType));
    expect(decoratedIntType.node, isNotNull);
    expect(decoratedIntType.node, isNot(never));
  }

  Future<void> test_local_function() async {
    await analyze('''
void f() {
  int g(int i) => 1;
}
''');
    var decoratedType = decoratedFunctionType('g');
    expect(decoratedType.returnType, same(decoratedTypeAnnotation('int g')));
    expect(decoratedType.positionalParameters[0],
        same(decoratedTypeAnnotation('int i')));
    expect(decoratedType.node, same(never));
  }

  Future<void> test_localVariable_type_implicit_dynamic() async {
    await analyze('''
main() {
  var x;
}
''');
    var decoratedType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedType.node.isImmutable, false);
  }

  Future<void> test_localVariable_type_inferred() async {
    await analyze('''
main() {
  var x = 1;
}
''');
    var decoratedType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
  }

  Future<void> test_localVariable_type_inferred_dynamic() async {
    await analyze('''
dynamic f() {}
main() {
  var x = f();
}
''');
    var decoratedType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedType.node.isImmutable, false);
  }

  Future<void> test_method_generic_bounded() async {
    await analyze('''
class C {
  T f<T extends Object>(T t) => t;
}
''');
    var decoratedType = decoratedMethodType('f');
    var bound = decoratedTypeParameterBound('T extends');
    expect(decoratedType.typeFormalBounds[0], same(bound));
    expect(decoratedTypeAnnotation('Object'), same(bound));
    expect(bound.node, isNot(always));
    expect(bound.type, typeProvider.objectType);
  }

  Future<void> test_method_generic_implicit_bound() async {
    await analyze('''
class C {
  T f<T>(T t) => t;
}
''');
    var decoratedType = decoratedMethodType('f');
    var bound = decoratedTypeParameterBound('T>');
    expect(decoratedType.typeFormalBounds[0], same(bound));
    assertEdge(always, bound.node, hard: false);
    expect(bound.type, same(typeProvider.objectType));
  }

  Future<void> test_method_metadata() async {
    await analyze('''
class A {
  final Object x;
  const A(this.x);
}
class C {
  @A(<int>[])
  f() {}
}
''');
    var node = decoratedTypeAnnotation('int').node;
    expect(node, TypeMatcher<NullabilityNodeMutable>());
  }

  Future<void> test_method_parameterType_implicit_dynamic() async {
    await analyze('''
class C {
  void f(x) {}
}
''');
    var decoratedType = decoratedMethodType('f').positionalParameters[0];
    expect(decoratedType.node.isImmutable, false);
  }

  Future<void> test_method_parameterType_implicit_dynamic_named() async {
    await analyze('''
class C {
  void f({x}) {}
}
''');
    var decoratedType = decoratedMethodType('f').namedParameters['x'];
    expect(decoratedType.node.isImmutable, false);
  }

  Future<void> test_method_parameterType_inferred() async {
    await analyze('''
class B {
  void f(int x) {}
}
class C extends B {
  void f/*C*/(x) {}
}
''');
    var decoratedType = decoratedMethodType('f/*C*/').positionalParameters[0];
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
  }

  Future<void> test_method_parameterType_inferred_dynamic() async {
    await analyze('''
class B {
  void f(dynamic x) {}
}
class C extends B {
  void f/*C*/(x) {}
}
''');
    var decoratedType = decoratedMethodType('f/*C*/').positionalParameters[0];
    expect(decoratedType.node.isImmutable, false);
  }

  Future<void> test_method_parameterType_inferred_dynamic_named() async {
    await analyze('''
class B {
  void f({dynamic x = 0}) {}
}
class C extends B {
  void f/*C*/({x = 0}) {}
}
''');
    var decoratedType = decoratedMethodType('f/*C*/').namedParameters['x'];
    expect(decoratedType.node.isImmutable, false);
  }

  Future<void>
      test_method_parameterType_inferred_generic_function_typed_no_bound() async {
    await analyze('''
class B {
  void f/*B*/(T Function<T>() x) {}
}
class C extends B {
  void f/*C*/(x) {}
}
''');
    var decoratedBaseType =
        decoratedMethodType('f/*B*/').positionalParameters[0];
    var decoratedType = decoratedMethodType('f/*C*/').positionalParameters[0];
    expect(decoratedType.typeFormalBounds, hasLength(1));
    expect(decoratedType.typeFormalBounds[0].type.toString(), 'Object');
    expect(decoratedType.typeFormalBounds[0].node,
        isNot(same(decoratedBaseType.typeFormalBounds[0].node)));
  }

  Future<void>
      test_method_parameterType_inferred_generic_function_typed_with_bound() async {
    await analyze('''
class B {
  void f/*B*/(T Function<T extends num>() x) {}
}
class C extends B {
  void f/*C*/(x) {}
}
''');
    var decoratedBaseType =
        decoratedMethodType('f/*B*/').positionalParameters[0];
    var decoratedType = decoratedMethodType('f/*C*/').positionalParameters[0];
    expect(decoratedType.typeFormalBounds, hasLength(1));
    expect(decoratedType.typeFormalBounds[0].type.toString(), 'num');
    expect(decoratedType.typeFormalBounds[0].node,
        isNot(same(decoratedBaseType.typeFormalBounds[0].node)));
  }

  Future<void> test_method_parameterType_inferred_named() async {
    await analyze('''
class B {
  void f({int x = 0}) {}
}
class C extends B {
  void f/*C*/({x = 0}) {}
}
''');
    var decoratedType = decoratedMethodType('f/*C*/').namedParameters['x'];
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
  }

  Future<void> test_method_returnType_implicit_dynamic() async {
    await analyze('''
class C {
  f() => 1;
}
''');
    var decoratedType = decoratedMethodType('f').returnType;
    expect(decoratedType.node.isImmutable, false);
  }

  Future<void> test_method_returnType_inferred() async {
    await analyze('''
class B {
  int f() => 1;
}
class C extends B {
  f/*C*/() => 1;
}
''');
    var decoratedType = decoratedMethodType('f/*C*/').returnType;
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
  }

  Future<void> test_method_returnType_inferred_dynamic() async {
    await analyze('''
class B {
  dynamic f() => 1;
}
class C extends B {
  f/*C*/() => 1;
}
''');
    var decoratedType = decoratedMethodType('f/*C*/').returnType;
    expect(decoratedType.node.isImmutable, false);
  }

  Future<void> test_parameters() async {
    await analyze('''
void foo({List<int> values})  {
  values.where((i) => true);
}
''');
    // No assertions; just checking that it doesn't crash.
  }

  Future<void> test_topLevelFunction_parameterType_implicit_dynamic() async {
    await analyze('''
void f(x) {}
''');
    var decoratedType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedType));
    expect(decoratedType.type.isDynamic, isTrue);
  }

  Future<void> test_topLevelFunction_parameterType_named_no_default() async {
    await analyze('''
void f({String s}) {}
''');
    var decoratedType = decoratedTypeAnnotation('String');
    var functionType = decoratedFunctionType('f');
    expect(functionType.namedParameters['s'], same(decoratedType));
    expect(decoratedType.node, isNotNull);
    expect(decoratedType.node, isNot(never));
    expect(decoratedType.node, isNot(always));
    expect(functionType.namedParameters['s'].node.isPossiblyOptional, true);
  }

  Future<void>
      test_topLevelFunction_parameterType_named_no_default_required() async {
    addMetaPackage();
    await analyze('''
import 'package:meta/meta.dart';
void f({@required String s}) {}
''');
    var decoratedType = decoratedTypeAnnotation('String');
    var functionType = decoratedFunctionType('f');
    expect(functionType.namedParameters['s'], same(decoratedType));
    expect(decoratedType.node, isNotNull);
    expect(decoratedType.node, isNot(never));
    expect(decoratedType.node, isNot(always));
    expect(functionType.namedParameters['s'].node.isPossiblyOptional, false);
  }

  Future<void> test_topLevelFunction_parameterType_named_with_default() async {
    await analyze('''
void f({String s: 'x'}) {}
''');
    var decoratedType = decoratedTypeAnnotation('String');
    var functionType = decoratedFunctionType('f');
    expect(functionType.namedParameters['s'], same(decoratedType));
    expect(decoratedType.node, isNotNull);
    expect(decoratedType.node, isNot(never));
    expect(functionType.namedParameters['s'].node.isPossiblyOptional, false);
  }

  Future<void> test_topLevelFunction_parameterType_positionalOptional() async {
    await analyze('''
void f([int i]) {}
''');
    var decoratedType = decoratedTypeAnnotation('int');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedType));
    expect(decoratedType.node, isNotNull);
    expect(decoratedType.node, isNot(never));
  }

  Future<void> test_topLevelFunction_parameterType_simple() async {
    await analyze('''
void f(int i) {}
''');
    var decoratedType = decoratedTypeAnnotation('int');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedType));
    expect(decoratedType.node, isNotNull);
    expect(decoratedType.node, isNot(never));
  }

  Future<void> test_topLevelFunction_returnType_implicit_dynamic() async {
    await analyze('''
f() {}
''');
    var decoratedType = decoratedFunctionType('f').returnType;
    expect(decoratedType.type.isDynamic, isTrue);
  }

  Future<void> test_topLevelFunction_returnType_simple() async {
    await analyze('''
int f() => 0;
''');
    var decoratedType = decoratedTypeAnnotation('int');
    expect(decoratedFunctionType('f').returnType, same(decoratedType));
    expect(decoratedType.node, isNotNull);
    expect(decoratedType.node, isNot(never));
  }

  Future<void> test_topLevelVariable_type_implicit_dynamic() async {
    await analyze('''
var x;
''');
    var decoratedType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedType.node.isImmutable, false);
  }

  Future<void> test_topLevelVariable_type_inferred() async {
    await analyze('''
var x = 1;
''');
    var decoratedType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
  }

  Future<void> test_topLevelVariable_type_inferred_dynamic() async {
    await analyze('''
dynamic f() {}
var x = f();
''');
    var decoratedType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedType.node.isImmutable, false);
  }

  Future<void> test_type_comment_bang() async {
    await analyze('''
void f(int/*!*/ i) {}
''');
    assertEdge(decoratedTypeAnnotation('int').node, never,
        hard: true, checkable: false);
  }

  Future<void> test_type_comment_question() async {
    await analyze('''
void f(int/*?*/ i) {}
''');
    assertUnion(always, decoratedTypeAnnotation('int').node);
  }

  Future<void> test_type_parameter_explicit_bound() async {
    await analyze('''
class C<T extends Object> {}
''');
    var bound = decoratedTypeParameterBound('T');
    expect(decoratedTypeAnnotation('Object'), same(bound));
    expect(bound.node, isNot(always));
    expect(bound.type, typeProvider.objectType);
  }

  Future<void> test_type_parameter_implicit_bound() async {
    // The implicit bound of `T` is automatically `Object?`.  TODO(paulberry):
    // consider making it possible for type inference to infer an explicit bound
    // of `Object`.
    await analyze('''
class C<T> {}
''');
    var bound = decoratedTypeParameterBound('T');
    assertEdge(always, bound.node, hard: false);
    expect(bound.type, same(typeProvider.objectType));
  }

  Future<void> test_typedef_reference_generic_instantiated() async {
    await analyze('''
typedef F<T> = T Function();
F<int> f;
''');
    // The instantiation of F should produce fresh nullability nodes, distinct
    // from the ones in the typedef (they will be unified by the edge builder).
    // This is necessary because there is no guarantee of whether the typedef or
    // its usage will be visited first.
    var typedefDecoratedType =
        variables.decoratedElementType(findElement.functionTypeAlias('F'));
    var decoratedType = decoratedTypeAnnotation('F<int>');
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedType.node, isNot(same(typedefDecoratedType.node)));
    expect(decoratedType.returnType.type.toString(), 'int');
    expect(
        decoratedType.returnType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedType.returnType.node,
        isNot(same(typedefDecoratedType.returnType.node)));
    expect(decoratedType.typeFormalBounds, isEmpty);
  }

  Future<void> test_typedef_reference_generic_uninstantiated() async {
    await analyze('''
typedef F = T Function<T extends num>();
F f;
''');
    // The instantiation of F should produce fresh nullability nodes, distinct
    // from the ones in the typedef (they will be unified by the edge builder).
    // This is necessary because there is no guarantee of whether the typedef or
    // its usage will be visited first.
    var typedefDecoratedType =
        variables.decoratedElementType(findElement.functionTypeAlias('F'));
    var decoratedType = decoratedTypeAnnotation('F f');
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedType.node, isNot(same(typedefDecoratedType.node)));
    expect(decoratedType.returnType.type.toString(), 'T');
    expect(
        decoratedType.returnType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedType.returnType.node,
        isNot(same(typedefDecoratedType.returnType.node)));
    expect(decoratedType.typeFormalBounds, hasLength(1));
    expect(decoratedType.typeFormalBounds[0].type.toString(), 'num');
    expect(decoratedType.typeFormalBounds[0].node,
        isNot(same(typedefDecoratedType.typeFormalBounds[0].node)));
  }

  Future<void> test_typedef_reference_simple() async {
    await analyze('''
typedef int F(String s);
F f;
''');
    // The instantiation of F should produce fresh nullability nodes, distinct
    // from the ones in the typedef (they will be unified by the edge builder).
    // This is necessary because there is no guarantee of whether the typedef or
    // its usage will be visited first.
    var typedefDecoratedType =
        variables.decoratedElementType(findElement.functionTypeAlias('F'));
    var decoratedType = decoratedTypeAnnotation('F f');
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedType.node, isNot(same(typedefDecoratedType.node)));
    expect(decoratedType.returnType.type.toString(), 'int');
    expect(
        decoratedType.returnType.node, TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedType.returnType.node,
        isNot(same(typedefDecoratedType.returnType.node)));
    expect(decoratedType.positionalParameters[0].type.toString(), 'String');
    expect(decoratedType.positionalParameters[0].node,
        TypeMatcher<NullabilityNodeMutable>());
    expect(decoratedType.positionalParameters[0].node,
        isNot(same(typedefDecoratedType.positionalParameters[0].node)));
    expect(decoratedType.typeFormalBounds, isEmpty);
  }

  Future<void> test_variableDeclaration_type_simple() async {
    await analyze('''
main() {
  int i;
}
''');
    var decoratedType = decoratedTypeAnnotation('int');
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
  }

  Future<void> test_variableDeclaration_visit_initializer() async {
    await analyze('''
class C<T> {}
void f(C<dynamic> c) {
  var x = c as C<int>;
}
''');
    var decoratedType = decoratedTypeAnnotation('int');
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
  }

  Future<void> test_void_type() async {
    await analyze('''
void f() {}
''');
    var decoratedType = decoratedTypeAnnotation('void');
    expect(decoratedFunctionType('f').returnType, same(decoratedType));
    assertNoEdge(always, decoratedType.node);
  }
}
