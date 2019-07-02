// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  DecoratedType decoratedTypeParameterBound(String search) => variables
      .decoratedElementType(findNode.typeParameter(search).declaredElement);

  test_class_alias_synthetic_constructors_no_parameters() async {
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

  test_class_alias_synthetic_constructors_with_parameters() async {
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
    expect(cType.type.toString(), 'D Function({i: int})');
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

  test_class_with_default_constructor() async {
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

  test_class_with_default_constructor_generic() async {
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

  test_constructor_factory() async {
    await analyze('''
class C {
  C._();
  factory C() => C._();
}
''');
    var decoratedType = decoratedConstructorDeclaration('C(').returnType;
    expect(decoratedType.node, same(never));
  }

  test_constructor_returnType_implicit_dynamic() async {
    await analyze('''
class C {
  C();
}
''');
    var decoratedType = decoratedConstructorDeclaration('C(').returnType;
    expect(decoratedType.node, same(never));
  }

  test_directSupertypes_class_extends() async {
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

  test_directSupertypes_class_extends_default() async {
    await analyze('''
class C<T, U> {}
''');
    var types = decoratedDirectSupertypes('C');
    var decorated = types[typeProvider.objectType.element];
    expect(decorated.type.toString(), 'Object');
    expect(decorated.node, same(never));
    expect(decorated.typeArguments, isEmpty);
  }

  test_directSupertypes_class_implements() async {
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

  test_directSupertypes_class_with() async {
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

  test_directSupertypes_classAlias_extends() async {
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

  test_directSupertypes_classAlias_implements() async {
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

  test_directSupertypes_classAlias_with() async {
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

  test_directSupertypes_mixin_extends_default() async {
    await analyze('''
mixin C<T, U> {}
''');
    var types = decoratedDirectSupertypes('C');
    var decorated = types[typeProvider.objectType.element];
    expect(decorated.type.toString(), 'Object');
    expect(decorated.node, same(never));
    expect(decorated.typeArguments, isEmpty);
  }

  test_directSupertypes_mixin_implements() async {
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

  test_directSupertypes_mixin_on() async {
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

  test_dynamic_type() async {
    await analyze('''
dynamic f() {}
''');
    var decoratedType = decoratedTypeAnnotation('dynamic');
    expect(decoratedFunctionType('f').returnType, same(decoratedType));
    assertEdge(always, decoratedType.node, hard: false);
  }

  test_field_type_implicit_dynamic() async {
    await analyze('''
class C {
  var x;
}
''');
    var decoratedType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedType.node, same(always));
  }

  test_field_type_inferred() async {
    await analyze('''
class C {
  var x = 1;
}
''');
    var decoratedType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
  }

  test_field_type_inferred_dynamic() async {
    await analyze('''
dynamic f() {}
class C {
  var x = f();
}
''');
    var decoratedType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedType.node, same(always));
  }

  test_field_type_simple() async {
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

  test_fieldFormalParameter_function_namedParameter_typed() async {
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
    expect(ctorParamType.namedParameters['i'].node, same(always));
  }

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
    expect(ctorParamType.positionalParameters[0].node, same(always));
  }

  test_fieldFormalParameter_function_return_typed() async {
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

  test_fieldFormalParameter_function_return_untyped() async {
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
    expect(ctorParamType.returnType.node, same(always));
  }

  test_fieldFormalParameter_typed() async {
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

  test_fieldFormalParameter_untyped() async {
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

  test_functionTypedFormalParameter_namedParameter_typed() async {
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
    expect(gType.namedParameters['i'].node, same(always));
  }

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
    expect(gType.positionalParameters[0].node, same(always));
  }

  test_functionTypedFormalParameter_return_typed() async {
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

  test_functionTypedFormalParameter_return_untyped() async {
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
    expect(gType.returnType.node, same(always));
  }

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
    expect(decoratedFReturnReturnType.node, same(always));
  }

  test_genericFunctionType_namedParameterType() async {
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

  test_genericFunctionType_returnType() async {
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

  test_genericFunctionType_unnamedParameterType() async {
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

  test_interfaceType_generic_instantiate_to_dynamic() async {
    await analyze('''
void f(List x) {}
''');
    var decoratedListType = decoratedTypeAnnotation('List');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedListType));
    expect(decoratedListType.node, isNotNull);
    expect(decoratedListType.node, isNot(never));
    var decoratedArgType = decoratedListType.typeArguments[0];
    expect(decoratedArgType.node, same(always));
  }

  test_interfaceType_generic_instantiate_to_function_type() async {
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
    expect(decoratedArgReturnType.node, same(always));
    expect(decoratedArgReturnType.typeArguments, isEmpty);
  }

  test_interfaceType_generic_instantiate_to_generic_type() async {
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

  test_interfaceType_generic_instantiate_to_object() async {
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

  test_interfaceType_typeParameter() async {
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

  test_localVariable_type_implicit_dynamic() async {
    await analyze('''
main() {
  var x;
}
''');
    var decoratedType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedType.node, same(always));
  }

  test_localVariable_type_inferred() async {
    await analyze('''
main() {
  var x = 1;
}
''');
    var decoratedType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
  }

  test_localVariable_type_inferred_dynamic() async {
    await analyze('''
dynamic f() {}
main() {
  var x = f();
}
''');
    var decoratedType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedType.node, same(always));
  }

  test_method_parameterType_implicit_dynamic() async {
    await analyze('''
class C {
  void f(x) {}
}
''');
    var decoratedType = decoratedMethodType('f').positionalParameters[0];
    expect(decoratedType.node, same(always));
  }

  test_method_parameterType_implicit_dynamic_named() async {
    await analyze('''
class C {
  void f({x}) {}
}
''');
    var decoratedType = decoratedMethodType('f').namedParameters['x'];
    expect(decoratedType.node, same(always));
  }

  test_method_parameterType_inferred() async {
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

  test_method_parameterType_inferred_dynamic() async {
    await analyze('''
class B {
  void f(dynamic x) {}
}
class C extends B {
  void f/*C*/(x) {}
}
''');
    var decoratedType = decoratedMethodType('f/*C*/').positionalParameters[0];
    expect(decoratedType.node, same(always));
  }

  test_method_parameterType_inferred_dynamic_named() async {
    await analyze('''
class B {
  void f({dynamic x = 0}) {}
}
class C extends B {
  void f/*C*/({x = 0}) {}
}
''');
    var decoratedType = decoratedMethodType('f/*C*/').namedParameters['x'];
    expect(decoratedType.node, same(always));
  }

  test_method_parameterType_inferred_named() async {
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

  test_method_returnType_implicit_dynamic() async {
    await analyze('''
class C {
  f() => 1;
}
''');
    var decoratedType = decoratedMethodType('f').returnType;
    expect(decoratedType.node, same(always));
  }

  test_method_returnType_inferred() async {
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

  test_method_returnType_inferred_dynamic() async {
    await analyze('''
class B {
  dynamic f() => 1;
}
class C extends B {
  f/*C*/() => 1;
}
''');
    var decoratedType = decoratedMethodType('f/*C*/').returnType;
    expect(decoratedType.node, same(always));
  }

  test_topLevelFunction_parameterType_implicit_dynamic() async {
    await analyze('''
void f(x) {}
''');
    var decoratedType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedType));
    expect(decoratedType.type.isDynamic, isTrue);
  }

  test_topLevelFunction_parameterType_named_no_default() async {
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

  test_topLevelFunction_parameterType_named_with_default() async {
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

  test_topLevelFunction_parameterType_positionalOptional() async {
    await analyze('''
void f([int i]) {}
''');
    var decoratedType = decoratedTypeAnnotation('int');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedType));
    expect(decoratedType.node, isNotNull);
    expect(decoratedType.node, isNot(never));
  }

  test_topLevelFunction_parameterType_simple() async {
    await analyze('''
void f(int i) {}
''');
    var decoratedType = decoratedTypeAnnotation('int');
    expect(decoratedFunctionType('f').positionalParameters[0],
        same(decoratedType));
    expect(decoratedType.node, isNotNull);
    expect(decoratedType.node, isNot(never));
  }

  test_topLevelFunction_returnType_implicit_dynamic() async {
    await analyze('''
f() {}
''');
    var decoratedType = decoratedFunctionType('f').returnType;
    expect(decoratedType.type.isDynamic, isTrue);
  }

  test_topLevelFunction_returnType_simple() async {
    await analyze('''
int f() => 0;
''');
    var decoratedType = decoratedTypeAnnotation('int');
    expect(decoratedFunctionType('f').returnType, same(decoratedType));
    expect(decoratedType.node, isNotNull);
    expect(decoratedType.node, isNot(never));
  }

  test_topLevelVariable_type_implicit_dynamic() async {
    await analyze('''
var x;
''');
    var decoratedType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedType.node, same(always));
  }

  test_topLevelVariable_type_inferred() async {
    await analyze('''
var x = 1;
''');
    var decoratedType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
  }

  test_topLevelVariable_type_inferred_dynamic() async {
    await analyze('''
dynamic f() {}
var x = f();
''');
    var decoratedType =
        variables.decoratedElementType(findNode.simple('x').staticElement);
    expect(decoratedType.node, same(always));
  }

  test_type_comment_bang() async {
    await analyze('''
void f(int/*!*/ i) {}
''');
    assertEdge(decoratedTypeAnnotation('int').node, never, hard: true);
  }

  test_type_comment_question() async {
    await analyze('''
void f(int/*?*/ i) {}
''');
    assertEdge(always, decoratedTypeAnnotation('int').node, hard: false);
  }

  test_type_parameter_explicit_bound() async {
    await analyze('''
class C<T extends Object> {}
''');
    var bound = decoratedTypeParameterBound('T');
    expect(decoratedTypeAnnotation('Object'), same(bound));
    expect(bound.node, isNot(always));
    expect(bound.type, typeProvider.objectType);
  }

  test_type_parameter_implicit_bound() async {
    // The implicit bound of `T` is automatically `Object?`.  TODO(paulberry):
    // consider making it possible for type inference to infer an explicit bound
    // of `Object`.
    await analyze('''
class C<T> {}
''');
    var bound = decoratedTypeParameterBound('T');
    assertUnion(always, bound.node);
    expect(bound.type, same(typeProvider.objectType));
  }

  test_variableDeclaration_type_simple() async {
    await analyze('''
main() {
  int i;
}
''');
    var decoratedType = decoratedTypeAnnotation('int');
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
  }

  test_variableDeclaration_visit_initializer() async {
    await analyze('''
class C<T> {}
void f(C<dynamic> c) {
  var x = c as C<int>;
}
''');
    var decoratedType = decoratedTypeAnnotation('int');
    expect(decoratedType.node, TypeMatcher<NullabilityNodeMutable>());
  }

  test_void_type() async {
    await analyze('''
void f() {}
''');
    var decoratedType = decoratedTypeAnnotation('void');
    expect(decoratedFunctionType('f').returnType, same(decoratedType));
    assertEdge(always, decoratedType.node, hard: false);
  }
}
