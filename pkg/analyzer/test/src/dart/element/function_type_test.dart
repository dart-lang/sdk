// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionTypeTest);
  });
}

DynamicTypeImpl get dynamicType => DynamicTypeImpl.instance;

VoidTypeImpl get voidType => VoidTypeImpl.instance;

Element getBaseElement(Element e) {
  if (e is Member) {
    return e.baseElement;
  } else {
    return e;
  }
}

@reflectiveTest
class FunctionTypeTest {
  static const bug_33294_fixed = false;
  static const bug_33300_fixed = false;
  static const bug_33301_fixed = false;
  static const bug_33302_fixed = false;

  final objectType = new InterfaceTypeImpl(new MockClassElement('Object'));

  final mapType = _makeMapType();

  final listType = _makeListType();

  final intType = new InterfaceTypeImpl(new MockClassElement('int'));

  void basicChecks(FunctionType f,
      {element,
      displayName: '() → dynamic',
      returnType,
      namedParameterTypes: isEmpty,
      normalParameterNames: isEmpty,
      normalParameterTypes: isEmpty,
      optionalParameterNames: isEmpty,
      optionalParameterTypes: isEmpty,
      parameters: isEmpty,
      typeFormals: isEmpty,
      typeArguments: isEmpty,
      typeParameters: isEmpty,
      name: isNull}) {
    // DartType properties
    expect(f.displayName, displayName, reason: 'displayName');
    expect(f.element, element, reason: 'element');
    expect(f.name, name, reason: 'name');
    // ParameterizedType properties
    expect(f.typeArguments, typeArguments, reason: 'typeArguments');
    expect(f.typeParameters, typeParameters, reason: 'typeParameters');
    // FunctionType properties
    expect(f.namedParameterTypes, namedParameterTypes,
        reason: 'namedParameterTypes');
    expect(f.normalParameterNames, normalParameterNames,
        reason: 'normalParameterNames');
    expect(f.normalParameterTypes, normalParameterTypes,
        reason: 'normalParameterTypes');
    expect(f.optionalParameterNames, optionalParameterNames,
        reason: 'optionalParameterNames');
    expect(f.optionalParameterTypes, optionalParameterTypes,
        reason: 'optionalParameterTypes');
    expect(f.parameters, parameters, reason: 'parameters');
    expect(f.returnType, returnType ?? same(dynamicType), reason: 'returnType');
    expect(f.typeFormals, typeFormals, reason: 'typeFormals');
  }

  DartType listOf(DartType elementType) => listType.instantiate([elementType]);

  DartType mapOf(DartType keyType, DartType valueType) =>
      mapType.instantiate([keyType, valueType]);

  test_forInstantiatedTypedef_bothTypeParameters() {
    var t = new MockTypeParameterElement('T');
    var u = new MockTypeParameterElement('U');
    var e = new MockGenericTypeAliasElement('F',
        typeParameters: [t],
        innerTypeParameters: [u],
        returnType: mapOf(t.type, u.type));
    FunctionType f =
        new FunctionTypeImpl.forTypedef(e, typeArguments: [objectType]);
    basicChecks(f,
        element: same(e),
        displayName: 'F<Object>',
        name: 'F',
        typeArguments: [same(objectType)],
        typeParameters: [same(t)],
        returnType: mapOf(objectType, u.type));
  }

  test_forInstantiatedTypedef_innerTypeParameter() {
    var t = new MockTypeParameterElement('T');
    var e = new MockGenericTypeAliasElement('F',
        innerTypeParameters: [t], returnType: t.type);
    FunctionType f = new FunctionTypeImpl.forTypedef(e, typeArguments: []);
    basicChecks(f,
        element: same(e),
        displayName: 'F',
        name: 'F',
        returnType: same(t.type));
  }

  test_forInstantiatedTypedef_noTypeParameters() {
    var e = new MockGenericTypeAliasElement('F');
    FunctionType f = new FunctionTypeImpl.forTypedef(e, typeArguments: []);
    basicChecks(f, element: same(e), displayName: 'F', name: 'F');
  }

  test_forInstantiatedTypedef_outerTypeParameters() {
    var t = new MockTypeParameterElement('T');
    var e = new MockGenericTypeAliasElement('F',
        typeParameters: [t], returnType: t.type);
    FunctionType f =
        new FunctionTypeImpl.forTypedef(e, typeArguments: [objectType]);
    basicChecks(f,
        element: same(e),
        displayName: 'F<Object>',
        name: 'F',
        typeArguments: [same(objectType)],
        typeParameters: [same(t)],
        returnType: same(objectType));
  }

  test_forTypedef() {
    var e = new MockGenericTypeAliasElement('F');
    basicChecks(e.type, element: same(e), displayName: 'F', name: 'F');
    basicChecks(e.function.type,
        element: same(e.function), displayName: '() → dynamic');
  }

  test_forTypedef_innerAndOuterTypeParameter() {
    // typedef F<T> = T Function<U>(U p);
    var t = new MockTypeParameterElement('T');
    var u = new MockTypeParameterElement('U');
    var p = new MockParameterElement('p', type: u.type);
    var e = new MockGenericTypeAliasElement('F',
        typeParameters: [t],
        innerTypeParameters: [u],
        returnType: t.type,
        parameters: [p]);
    basicChecks(e.type,
        element: same(e),
        displayName: 'F',
        name: 'F',
        returnType: same(t.type),
        normalParameterTypes: [same(u.type)],
        normalParameterNames: ['p'],
        parameters: [same(p)],
        typeFormals: [same(t)]);
    basicChecks(e.function.type,
        element: same(e.function),
        displayName: '<U>(U) → T',
        returnType: same(t.type),
        typeArguments: [same(t.type)],
        typeParameters: [same(t)],
        typeFormals: [same(u)],
        normalParameterTypes: [same(u.type)],
        normalParameterNames: ['p'],
        parameters: [same(p)]);
  }

  test_forTypedef_innerAndOuterTypeParameter_instantiate() {
    // typedef F<T> = T Function<U>(U p);
    var t = new MockTypeParameterElement('T');
    var u = new MockTypeParameterElement('U');
    var p = new MockParameterElement('p', type: u.type);
    var e = new MockGenericTypeAliasElement('F',
        typeParameters: [t],
        innerTypeParameters: [u],
        returnType: t.type,
        parameters: [p]);
    var instantiated = e.type.instantiate([objectType]);
    basicChecks(instantiated,
        element: same(e),
        displayName: 'F<Object>',
        name: 'F',
        returnType: same(objectType),
        normalParameterTypes: [same(u.type)],
        normalParameterNames: ['p'],
        parameters: [same(p)],
        typeFormals: isNotNull,
        typeArguments: [same(objectType)],
        typeParameters: [same(t)]);
    if (bug_33294_fixed) {
      expect(instantiated.typeFormals, [same(u)]);
    } else {
      expect(instantiated.typeFormals, isEmpty);
    }
  }

  test_forTypedef_innerTypeParameter() {
    // typedef F = T Function<T>();
    var t = new MockTypeParameterElement('T');
    var e = new MockGenericTypeAliasElement('F',
        innerTypeParameters: [t], returnType: t.type);
    basicChecks(e.type,
        element: same(e),
        displayName: 'F',
        name: 'F',
        returnType: same(t.type));
    basicChecks(e.function.type,
        element: same(e.function),
        displayName: '<T>() → T',
        returnType: same(t.type),
        typeFormals: [same(t)]);
  }

  test_forTypedef_normalParameter() {
    var p = new MockParameterElement('p');
    var e = new MockGenericTypeAliasElement('F', parameters: [p]);
    basicChecks(e.type,
        element: same(e),
        displayName: 'F',
        name: 'F',
        normalParameterNames: ['p'],
        normalParameterTypes: [same(dynamicType)],
        parameters: [same(p)]);
    basicChecks(e.function.type,
        element: same(e.function),
        displayName: '(dynamic) → dynamic',
        normalParameterNames: ['p'],
        normalParameterTypes: [same(dynamicType)],
        parameters: [same(p)]);
  }

  test_forTypedef_recursive_via_interfaceTypes() {
    // typedef F = List<G> Function();
    // typedef G = List<F> Function();
    var f = new MockGenericTypeAliasElement('F');
    var g = new MockGenericTypeAliasElement('G');
    f.returnType = listOf(g.function.type);
    g.returnType = listOf(f.function.type);
    basicChecks(f.type,
        element: same(f), displayName: 'F', name: 'F', returnType: isNotNull);
    var fReturn = f.type.returnType;
    expect(fReturn.element, same(listType.element));
    if (bug_33302_fixed) {
      expect(fReturn.displayName, 'List<G>');
    } else {
      expect(fReturn.displayName, 'List<() → List<...>>');
    }
    var fReturnArg = (fReturn as InterfaceType).typeArguments[0];
    expect(fReturnArg.element, same(g.function));
    var fReturnArgReturn = (fReturnArg as FunctionType).returnType;
    expect(fReturnArgReturn.element, same(listType.element));
    expect((fReturnArgReturn as InterfaceType).typeArguments[0],
        new TypeMatcher<CircularFunctionTypeImpl>());
    basicChecks(f.function.type,
        element: same(f.function), displayName: isNotNull, returnType: fReturn);
    if (bug_33302_fixed) {
      expect(f.function.type.displayName, '() → List<G>');
    } else {
      expect(f.function.type.displayName, '() → List<() → List<...>>');
    }
    basicChecks(g.type,
        element: same(g), displayName: 'G', name: 'G', returnType: isNotNull);
    var gReturn = g.type.returnType;
    expect(gReturn.element, same(listType.element));
    if (bug_33302_fixed) {
      expect(gReturn.displayName, 'List<F>');
    } else {
      expect(gReturn.displayName, 'List<() → List<...>>');
    }
    var gReturnArg = (gReturn as InterfaceType).typeArguments[0];
    expect(gReturnArg.element, same(f.function));
    var gReturnArgReturn = (gReturnArg as FunctionType).returnType;
    expect(gReturnArgReturn.element, same(listType.element));
    expect((gReturnArgReturn as InterfaceType).typeArguments[0],
        new TypeMatcher<CircularFunctionTypeImpl>());
    basicChecks(g.function.type,
        element: same(g.function), displayName: isNotNull, returnType: gReturn);
    if (bug_33302_fixed) {
      expect(g.function.type.displayName, '() → F');
    } else {
      expect(g.function.type.displayName, '() → List<() → List<...>>');
    }
  }

  test_forTypedef_recursive_via_parameterTypes() {
    // typedef F = void Function(G g);
    // typedef G = void Function(F f);
    var f = new MockGenericTypeAliasElement('F', returnType: voidType);
    var g = new MockGenericTypeAliasElement('G', returnType: voidType);
    f.parameters = [new MockParameterElement('g', type: g.function.type)];
    g.parameters = [new MockParameterElement('f', type: f.function.type)];
    basicChecks(f.type,
        element: same(f),
        displayName: 'F',
        name: 'F',
        parameters: hasLength(1),
        normalParameterTypes: hasLength(1),
        normalParameterNames: ['g'],
        returnType: same(voidType));
    var fParamType = f.type.normalParameterTypes[0];
    expect(fParamType.element, same(g.function));
    expect((fParamType as FunctionType).normalParameterTypes[0],
        new TypeMatcher<CircularFunctionTypeImpl>());
    basicChecks(f.function.type,
        element: same(f.function),
        displayName: isNotNull,
        parameters: hasLength(1),
        normalParameterTypes: [fParamType],
        normalParameterNames: ['g'],
        returnType: same(voidType));
    if (bug_33302_fixed) {
      expect(f.function.type.displayName, '(G) → void');
    } else {
      expect(f.function.type.displayName, '((...) → void) → void');
    }
    basicChecks(g.type,
        element: same(g),
        displayName: 'G',
        name: 'G',
        parameters: hasLength(1),
        normalParameterTypes: hasLength(1),
        normalParameterNames: ['f'],
        returnType: same(voidType));
    var gParamType = g.type.normalParameterTypes[0];
    expect(gParamType.element, same(f.function));
    expect((gParamType as FunctionType).normalParameterTypes[0],
        new TypeMatcher<CircularFunctionTypeImpl>());
    basicChecks(g.function.type,
        element: same(g.function),
        displayName: isNotNull,
        parameters: hasLength(1),
        normalParameterTypes: [gParamType],
        normalParameterNames: ['f'],
        returnType: same(voidType));
    if (bug_33302_fixed) {
      expect(g.function.type.displayName, '(F) → void');
    } else {
      expect(g.function.type.displayName, '((...) → void) → void');
    }
  }

  test_forTypedef_recursive_via_returnTypes() {
    // typedef F = G Function();
    // typedef G = F Function();
    var f = new MockGenericTypeAliasElement('F');
    var g = new MockGenericTypeAliasElement('G');
    f.returnType = g.function.type;
    g.returnType = f.function.type;
    basicChecks(f.type,
        element: same(f), displayName: 'F', name: 'F', returnType: isNotNull);
    var fReturn = f.type.returnType;
    expect(fReturn.element, same(g.function));
    expect((fReturn as FunctionType).returnType,
        new TypeMatcher<CircularFunctionTypeImpl>());
    basicChecks(f.function.type,
        element: same(f.function), displayName: isNotNull, returnType: fReturn);
    if (bug_33302_fixed) {
      expect(f.function.type.displayName, '() → G');
    } else {
      expect(f.function.type.displayName, '() → () → ...');
    }
    basicChecks(g.type,
        element: same(g), displayName: 'G', name: 'G', returnType: isNotNull);
    var gReturn = g.type.returnType;
    expect(gReturn.element, same(f.function));
    expect((gReturn as FunctionType).returnType,
        new TypeMatcher<CircularFunctionTypeImpl>());
    basicChecks(g.function.type,
        element: same(g.function), displayName: isNotNull, returnType: gReturn);
    if (bug_33302_fixed) {
      expect(g.function.type.displayName, '() → F');
    } else {
      expect(g.function.type.displayName, '() → () → ...');
    }
  }

  test_forTypedef_returnType() {
    var e = new MockGenericTypeAliasElement('F', returnType: objectType);
    basicChecks(e.type,
        element: same(e), displayName: 'F', name: 'F', returnType: objectType);
    basicChecks(e.function.type,
        element: same(e.function),
        displayName: '() → Object',
        returnType: objectType);
  }

  test_forTypedef_returnType_null() {
    var e = new MockGenericTypeAliasElement.withNullReturn('F');
    basicChecks(e.type, element: same(e), displayName: 'F', name: 'F');
    basicChecks(e.function.type,
        element: same(e.function), displayName: '() → dynamic');
  }

  test_forTypedef_typeParameter() {
    // typedef F<T> = T Function();
    var t = new MockTypeParameterElement('T');
    var e = new MockGenericTypeAliasElement('F',
        typeParameters: [t], returnType: t.type);
    basicChecks(e.type,
        element: same(e),
        displayName: 'F',
        name: 'F',
        returnType: same(t.type),
        typeFormals: [same(t)]);
    basicChecks(e.function.type,
        element: same(e.function),
        displayName: '() → T',
        returnType: same(t.type),
        typeArguments: [same(t.type)],
        typeParameters: [same(t)]);
  }

  test_synthetic() {
    FunctionType f = new FunctionTypeImpl.synthetic(dynamicType, [], []);
    basicChecks(f, element: isNull);
  }

  test_synthetic_instantiate() {
    // T Function<T>(T x)
    var t = new MockTypeParameterElement('T');
    var x = new MockParameterElement('x', type: t.type);
    FunctionType f = new FunctionTypeImpl.synthetic(t.type, [t], [x]);
    FunctionType instantiated = f.instantiate([objectType]);
    basicChecks(instantiated,
        element: isNull,
        displayName: '(Object) → Object',
        returnType: same(objectType),
        normalParameterNames: ['x'],
        normalParameterTypes: [same(objectType)],
        parameters: hasLength(1));
  }

  test_synthetic_instantiate_argument_length_mismatch() {
    // dynamic Function<T>()
    var t = new MockTypeParameterElement('T');
    FunctionType f = new FunctionTypeImpl.synthetic(dynamicType, [t], []);
    expect(() => f.instantiate([]), throwsA(new TypeMatcher<ArgumentError>()));
  }

  test_synthetic_instantiate_no_type_formals() {
    FunctionType f = new FunctionTypeImpl.synthetic(dynamicType, [], []);
    expect(f.instantiate([]), same(f));
  }

  test_synthetic_instantiate_share_parameters() {
    // T Function<T>(int x)
    var t = new MockTypeParameterElement('T');
    var x = new MockParameterElement('x', type: intType);
    FunctionType f = new FunctionTypeImpl.synthetic(t.type, [t], [x]);
    FunctionType instantiated = f.instantiate([objectType]);
    basicChecks(instantiated,
        element: isNull,
        displayName: '(int) → Object',
        returnType: same(objectType),
        normalParameterNames: ['x'],
        normalParameterTypes: [same(intType)],
        parameters: same(f.parameters));
  }

  test_synthetic_namedParameter() {
    var p = new MockParameterElement('x',
        type: objectType, parameterKind: ParameterKind.NAMED);
    FunctionType f = new FunctionTypeImpl.synthetic(dynamicType, [], [p]);
    basicChecks(f,
        element: isNull,
        displayName: '({x: Object}) → dynamic',
        namedParameterTypes: {'x': same(objectType)},
        parameters: hasLength(1));
    expect(f.parameters[0].isNamed, isTrue);
    expect(f.parameters[0].name, 'x');
    expect(f.parameters[0].type, same(objectType));
  }

  test_synthetic_normalParameter() {
    var p = new MockParameterElement('x', type: objectType);
    FunctionType f = new FunctionTypeImpl.synthetic(dynamicType, [], [p]);
    basicChecks(f,
        element: isNull,
        displayName: '(Object) → dynamic',
        normalParameterNames: ['x'],
        normalParameterTypes: [same(objectType)],
        parameters: hasLength(1));
    expect(f.parameters[0].isNotOptional, isTrue);
    expect(f.parameters[0].name, 'x');
    expect(f.parameters[0].type, same(objectType));
  }

  test_synthetic_optionalParameter() {
    var p = new MockParameterElement('x',
        type: objectType, parameterKind: ParameterKind.POSITIONAL);
    FunctionType f = new FunctionTypeImpl.synthetic(dynamicType, [], [p]);
    basicChecks(f,
        element: isNull,
        displayName: '([Object]) → dynamic',
        optionalParameterNames: ['x'],
        optionalParameterTypes: [same(objectType)],
        parameters: hasLength(1));
    expect(f.parameters[0].isOptionalPositional, isTrue);
    expect(f.parameters[0].name, 'x');
    expect(f.parameters[0].type, same(objectType));
  }

  test_synthetic_returnType() {
    FunctionType f = new FunctionTypeImpl.synthetic(objectType, [], []);
    basicChecks(f,
        element: isNull,
        displayName: '() → Object',
        returnType: same(objectType));
  }

  test_synthetic_substitute() {
    // Map<T, U> Function<U extends T>(T x, U y)
    var t = new MockTypeParameterElement('T');
    var u = new MockTypeParameterElement('U', bound: t.type);
    var x = new MockParameterElement('x', type: t.type);
    var y = new MockParameterElement('y', type: u.type);
    FunctionType f =
        new FunctionTypeImpl.synthetic(mapOf(t.type, u.type), [u], [x, y]);
    FunctionType substituted = f.substitute2([objectType], [t.type]);
    var uSubstituted = substituted.typeFormals[0];
    basicChecks(substituted,
        element: isNull,
        displayName: '<U extends Object>(Object, U) → Map<Object, U>',
        returnType: mapOf(objectType, uSubstituted.type),
        typeFormals: [uSubstituted],
        normalParameterNames: ['x', 'y'],
        normalParameterTypes: [same(objectType), same(uSubstituted.type)],
        parameters: hasLength(2));
  }

  test_synthetic_substitute_argument_length_mismatch() {
    // dynamic Function()
    var t = new MockTypeParameterElement('T');
    FunctionType f = new FunctionTypeImpl.synthetic(dynamicType, [], []);
    expect(() => f.substitute2([], [t.type]),
        throwsA(new TypeMatcher<ArgumentError>()));
  }

  test_synthetic_substitute_share_returnType_and_parameters() {
    // int Function<U extends T>(int x)
    var t = new MockTypeParameterElement('T');
    var u = new MockTypeParameterElement('U', bound: t.type);
    var x = new MockParameterElement('x', type: intType);
    FunctionType f = new FunctionTypeImpl.synthetic(intType, [u], [x]);
    FunctionType substituted = f.substitute2([objectType], [t.type]);
    basicChecks(substituted,
        element: isNull,
        displayName: '<U extends Object>(int) → int',
        returnType: same(f.returnType),
        typeFormals: hasLength(1),
        normalParameterNames: ['x'],
        normalParameterTypes: [same(intType)],
        parameters: same(f.parameters));
    expect(substituted.typeFormals[0].name, 'U');
    expect(substituted.typeFormals[0].bound, same(objectType));
  }

  test_synthetic_substitute_share_returnType_and_typeFormals() {
    // int Function<U>(T x, U y)
    var t = new MockTypeParameterElement('T');
    var u = new MockTypeParameterElement('U');
    var x = new MockParameterElement('x', type: t.type);
    var y = new MockParameterElement('y', type: u.type);
    FunctionType f = new FunctionTypeImpl.synthetic(intType, [u], [x, y]);
    FunctionType substituted = f.substitute2([objectType], [t.type]);
    basicChecks(substituted,
        element: isNull,
        displayName: '<U>(Object, U) → int',
        returnType: same(f.returnType),
        typeFormals: same(f.typeFormals),
        normalParameterNames: ['x', 'y'],
        normalParameterTypes: [same(objectType), same(u.type)],
        parameters: hasLength(2));
  }

  test_synthetic_substitute_share_typeFormals_and_parameters() {
    // T Function<U>(U x)
    var t = new MockTypeParameterElement('T');
    var u = new MockTypeParameterElement('U');
    var x = new MockParameterElement('x', type: u.type);
    FunctionType f = new FunctionTypeImpl.synthetic(t.type, [u], [x]);
    FunctionType substituted = f.substitute2([objectType], [t.type]);
    basicChecks(substituted,
        element: isNull,
        displayName: '<U>(U) → Object',
        returnType: same(objectType),
        typeFormals: same(f.typeFormals),
        normalParameterNames: ['x'],
        normalParameterTypes: [same(u.type)],
        parameters: same(f.parameters));
  }

  test_synthetic_substitute_unchanged() {
    // dynamic Function<U>(U x)
    var t = new MockTypeParameterElement('T');
    var u = new MockTypeParameterElement('U');
    var x = new MockParameterElement('x', type: u.type);
    FunctionType f = new FunctionTypeImpl.synthetic(dynamicType, [u], [x]);
    FunctionType substituted = f.substitute2([objectType], [t.type]);
    expect(substituted, same(f));
  }

  test_synthetic_typeFormals() {
    var t = new MockTypeParameterElement('T');
    FunctionType f = new FunctionTypeImpl.synthetic(t.type, [t], []);
    basicChecks(f,
        element: isNull,
        displayName: '<T>() → T',
        returnType: same(t.type),
        typeFormals: [same(t)]);
  }

  test_unnamedConstructor() {
    var e = new MockFunctionTypedElement();
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f, element: same(e));
  }

  test_unnamedConstructor_instantiate_argument_length_mismatch() {
    var t = new MockTypeParameterElement('T');
    var e = new MockFunctionTypedElement(typeParameters: [t]);
    FunctionType f = new FunctionTypeImpl(e);
    expect(() => f.instantiate([]), throwsA(new TypeMatcher<ArgumentError>()));
  }

  test_unnamedConstructor_instantiate_noop() {
    var t = new MockTypeParameterElement('T');
    var p = new MockParameterElement('x', type: t.type);
    var e = new MockFunctionTypedElement(typeParameters: [t], parameters: [p]);
    FunctionType f = new FunctionTypeImpl(e);
    var instantiated = f.instantiate([t.type]);
    basicChecks(instantiated,
        element: same(e),
        displayName: '(T) → dynamic',
        typeArguments: hasLength(1),
        typeParameters: [same(t)],
        normalParameterNames: ['x'],
        normalParameterTypes: [same(t.type)],
        parameters: [same(p)]);
    expect(instantiated.typeArguments[0], same(t.type));
  }

  test_unnamedConstructor_instantiate_noTypeParameters() {
    var e = new MockFunctionTypedElement();
    FunctionType f = new FunctionTypeImpl(e);
    expect(f.instantiate([]), same(f));
  }

  test_unnamedConstructor_instantiate_parameterType_simple() {
    var t = new MockTypeParameterElement('T');
    var p = new MockParameterElement('x', type: t.type);
    var e = new MockFunctionTypedElement(typeParameters: [t], parameters: [p]);
    FunctionType f = new FunctionTypeImpl(e);
    var instantiated = f.instantiate([objectType]);
    basicChecks(instantiated,
        element: same(e),
        displayName: '(Object) → dynamic',
        typeArguments: hasLength(1),
        typeParameters: [same(t)],
        normalParameterNames: ['x'],
        normalParameterTypes: [same(objectType)],
        parameters: hasLength(1));
    expect(instantiated.typeArguments[0], same(objectType));
    expect(instantiated.parameters[0].name, 'x');
    expect(instantiated.parameters[0].type, same(objectType));
  }

  test_unnamedConstructor_instantiate_returnType_simple() {
    var t = new MockTypeParameterElement('T');
    var e =
        new MockFunctionTypedElement(typeParameters: [t], returnType: t.type);
    FunctionType f = new FunctionTypeImpl(e);
    var instantiated = f.instantiate([objectType]);
    basicChecks(instantiated,
        element: same(e),
        displayName: '() → Object',
        typeArguments: hasLength(1),
        typeParameters: [same(t)],
        returnType: same(objectType));
    expect(instantiated.typeArguments[0], same(objectType));
  }

  test_unnamedConstructor_namedParameter() {
    var p = new MockParameterElement('x', parameterKind: ParameterKind.NAMED);
    var e = new MockFunctionTypedElement(parameters: [p]);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        displayName: '({x: dynamic}) → dynamic',
        namedParameterTypes: {'x': same(dynamicType)},
        parameters: [same(p)]);
  }

  test_unnamedConstructor_namedParameter_object() {
    var p = new MockParameterElement('x',
        parameterKind: ParameterKind.NAMED, type: objectType);
    var e = new MockFunctionTypedElement(parameters: [p]);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        displayName: '({x: Object}) → dynamic',
        namedParameterTypes: {'x': same(objectType)},
        parameters: [same(p)]);
  }

  test_unnamedConstructor_nonTypedef_noTypeArguments() {
    var e = new MockFunctionTypedElement();
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f, element: same(e));
  }

  test_unnamedConstructor_nonTypedef_withTypeArguments() {
    var t = new MockTypeParameterElement('T');
    var c = new MockClassElement('C', typeParameters: [t]);
    var e = new MockMethodElement(c, returnType: t.type);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        typeArguments: [same(t.type)],
        typeParameters: [same(t)],
        displayName: '() → T',
        returnType: same(t.type));
  }

  test_unnamedConstructor_normalParameter() {
    var p = new MockParameterElement('x');
    var e = new MockFunctionTypedElement(parameters: [p]);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        displayName: '(dynamic) → dynamic',
        normalParameterNames: ['x'],
        normalParameterTypes: [same(dynamicType)],
        parameters: [same(p)]);
  }

  test_unnamedConstructor_normalParameter_object() {
    var p = new MockParameterElement('x', type: objectType);
    var e = new MockFunctionTypedElement(parameters: [p]);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        displayName: '(Object) → dynamic',
        normalParameterNames: ['x'],
        normalParameterTypes: [same(objectType)],
        parameters: [same(p)]);
  }

  test_unnamedConstructor_optionalParameter() {
    var p =
        new MockParameterElement('x', parameterKind: ParameterKind.POSITIONAL);
    var e = new MockFunctionTypedElement(parameters: [p]);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        displayName: '([dynamic]) → dynamic',
        optionalParameterNames: ['x'],
        optionalParameterTypes: [same(dynamicType)],
        parameters: [same(p)]);
  }

  test_unnamedConstructor_optionalParameter_object() {
    var p = new MockParameterElement('x',
        parameterKind: ParameterKind.POSITIONAL, type: objectType);
    var e = new MockFunctionTypedElement(parameters: [p]);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        displayName: '([Object]) → dynamic',
        optionalParameterNames: ['x'],
        optionalParameterTypes: [same(objectType)],
        parameters: [same(p)]);
  }

  test_unnamedConstructor_returnType() {
    var e = new MockFunctionTypedElement(returnType: objectType);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        returnType: same(objectType),
        displayName: '() → Object');
  }

  test_unnamedConstructor_returnType_null() {
    var e = new MockFunctionTypedElement.withNullReturn();
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        returnType: same(dynamicType),
        displayName: '() → dynamic');
  }

  test_unnamedConstructor_staticMethod_ignores_enclosing_type_params() {
    var t = new MockTypeParameterElement('T');
    var c = new MockClassElement('C', typeParameters: [t]);
    var e = new MockMethodElement(c, isStatic: true);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f, element: same(e));
  }

  test_unnamedConstructor_substitute_argument_length_mismatch() {
    // abstract class C<T> {
    //   dynamic f();
    // }
    var t = new MockTypeParameterElement('T');
    var c = new MockClassElement('C', typeParameters: [t]);
    var e = new MockFunctionTypedElement(enclosingElement: c);
    FunctionType f = new FunctionTypeImpl(e);
    expect(() => f.substitute2([], [t.type]),
        throwsA(new TypeMatcher<ArgumentError>()));
  }

  test_unnamedConstructor_substitute_bound_recursive() {
    // abstract class C<T> {
    //   Map<S, V> f<S extends T, T extends U, V extends T>();
    // }
    var s = new MockTypeParameterElement('S');
    var t = new MockTypeParameterElement('T');
    var u = new MockTypeParameterElement('U');
    var v = new MockTypeParameterElement('V');
    s.bound = t.type;
    t.bound = u.type;
    v.bound = t.type;
    var c = new MockClassElement('C', typeParameters: [u]);
    var e = new MockFunctionTypedElement(
        returnType: mapOf(s.type, v.type),
        typeParameters: [s, t, v],
        enclosingElement: c);
    FunctionType f = new FunctionTypeImpl(e);
    var substituted = f.substitute2([objectType], [u.type]);
    basicChecks(substituted,
        element: same(e),
        displayName: isNotNull,
        returnType: isNotNull,
        typeFormals: hasLength(3),
        typeParameters: [same(u)],
        typeArguments: [same(objectType)]);
    if (bug_33300_fixed) {
      expect(substituted.displayName,
          '<S extends T,T extends Object,V extends T>() → Map<S, V>');
    } else {
      expect(substituted.displayName,
          '<S extends T extends Object,T extends Object,V extends T>() → Map<S, V>');
    }
    var s2 = substituted.typeFormals[0];
    var t2 = substituted.typeFormals[1];
    var v2 = substituted.typeFormals[2];
    expect(s2.name, 'S');
    expect(t2.name, 'T');
    expect(v2.name, 'V');
    expect(s2.bound, t2.type);
    expect(t2.bound, same(objectType));
    expect(v2.bound, t2.type);
    if (bug_33301_fixed) {
      expect(substituted.returnType, mapOf(s2.type, v2.type));
    } else {
      expect(substituted.returnType, mapOf(s.type, v.type));
    }
  }

  test_unnamedConstructor_substitute_bound_recursive_parameter() {
    // abstract class C<T> {
    //   void f<S extends T, T extends U, V extends T>(S x, V y);
    // }
    var s = new MockTypeParameterElement('S');
    var t = new MockTypeParameterElement('T');
    var u = new MockTypeParameterElement('U');
    var v = new MockTypeParameterElement('V');
    s.bound = t.type;
    t.bound = u.type;
    v.bound = t.type;
    var c = new MockClassElement('C', typeParameters: [u]);
    var x = new MockParameterElement('x', type: s.type);
    var y = new MockParameterElement('y', type: v.type);
    var e = new MockFunctionTypedElement(
        returnType: voidType,
        typeParameters: [s, t, v],
        enclosingElement: c,
        parameters: [x, y]);
    FunctionType f = new FunctionTypeImpl(e);
    var substituted = f.substitute2([objectType], [u.type]);
    basicChecks(substituted,
        element: same(e),
        displayName: isNotNull,
        returnType: same(voidType),
        normalParameterNames: ['x', 'y'],
        normalParameterTypes: hasLength(2),
        parameters: hasLength(2),
        typeFormals: hasLength(3),
        typeParameters: [same(u)],
        typeArguments: [same(objectType)]);
    if (bug_33300_fixed) {
      expect(substituted.displayName,
          '<S extends T,T extends Object,V extends T>(S, V) → void');
    } else {
      expect(
          substituted.displayName,
          '<S extends T extends Object,T extends Object,V extends T>(S, V) '
          '→ void');
    }
    var s2 = substituted.typeFormals[0];
    var t2 = substituted.typeFormals[1];
    var v2 = substituted.typeFormals[2];
    expect(s2.name, 'S');
    expect(t2.name, 'T');
    expect(v2.name, 'V');
    expect(s2.bound, t2.type);
    expect(t2.bound, same(objectType));
    expect(v2.bound, t2.type);
    if (bug_33301_fixed) {
      expect(substituted.normalParameterTypes, [same(s2.type), same(v2.type)]);
    } else {
      expect(substituted.normalParameterTypes, [same(s.type), same(v.type)]);
    }
  }

  test_unnamedConstructor_substitute_bound_simple() {
    // abstract class C<T> {
    //   U f<U extends T>();
    // }
    var t = new MockTypeParameterElement('T');
    var c = new MockClassElement('C', typeParameters: [t]);
    var u = new MockTypeParameterElement('U', bound: t.type);
    var e = new MockFunctionTypedElement(
        typeParameters: [u], returnType: u.type, enclosingElement: c);
    FunctionType f = new FunctionTypeImpl(e);
    var substituted = f.substitute2([objectType], [t.type]);
    basicChecks(substituted,
        element: same(e),
        displayName: '<U extends Object>() → U',
        typeArguments: [same(objectType)],
        typeParameters: [same(t)],
        returnType: isNotNull,
        typeFormals: hasLength(1));
    expect(substituted.typeFormals[0].name, 'U');
    expect(substituted.typeFormals[0].bound, same(objectType));
    expect((substituted.returnType as TypeParameterTypeImpl).element,
        same(getBaseElement(substituted.typeFormals[0])));
  }

  test_unnamedConstructor_substitute_noop() {
    var t = new MockTypeParameterElement('T');
    var e = new MockFunctionTypedElement(returnType: t.type);
    FunctionType f = new FunctionTypeImpl(e);
    var substituted = f.substitute2([t.type], [t.type]);
    basicChecks(substituted,
        element: same(e), displayName: '() → T', returnType: same(t.type));
    // TODO(paulberry): test substitute length mismatch
  }

  test_unnamedConstructor_substitute_parameterType_simple() {
    var t = new MockTypeParameterElement('T');
    var c = new MockClassElement('C', typeParameters: [t]);
    var p = new MockParameterElement('x', type: t.type);
    var e = new MockFunctionTypedElement(parameters: [p], enclosingElement: c);
    FunctionType f = new FunctionTypeImpl(e);
    var substituted = f.substitute2([objectType], [t.type]);
    basicChecks(substituted,
        element: same(e),
        displayName: '(Object) → dynamic',
        normalParameterNames: ['x'],
        normalParameterTypes: [same(objectType)],
        parameters: hasLength(1),
        typeArguments: [same(objectType)],
        typeParameters: [same(t)]);
    expect(substituted.parameters[0].name, 'x');
    expect(substituted.parameters[0].type, same(objectType));
  }

  test_unnamedConstructor_substitute_returnType_simple() {
    var t = new MockTypeParameterElement('T');
    var c = new MockClassElement('C', typeParameters: [t]);
    var e =
        new MockFunctionTypedElement(returnType: t.type, enclosingElement: c);
    FunctionType f = new FunctionTypeImpl(e);
    var substituted = f.substitute2([objectType], [t.type]);
    basicChecks(substituted,
        element: same(e),
        displayName: '() → Object',
        returnType: same(objectType),
        typeArguments: [same(objectType)],
        typeParameters: [same(t)]);
  }

  test_unnamedConstructor_typeParameter() {
    var t = new MockTypeParameterElement('T');
    var e = new MockFunctionTypedElement(typeParameters: [t]);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        displayName: '<T>() → dynamic',
        typeFormals: [same(t)]);
    // TODO(paulberry): test pruning of bounds
  }

  test_unnamedConstructor_typeParameter_with_bound() {
    var t = new MockTypeParameterElement('T');
    var c = new MockClassElement('C', typeParameters: [t]);
    var u = new MockTypeParameterElement('U', bound: t.type);
    var e = new MockFunctionTypedElement(
        typeParameters: [u], returnType: u.type, enclosingElement: c);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        displayName: '<U extends T>() → U',
        typeArguments: [same(t.type)],
        typeParameters: [same(t)],
        returnType: same(u.type),
        typeFormals: hasLength(1));
    expect(f.typeFormals[0].name, 'U');
    expect(f.typeFormals[0].bound, same(t.type));
  }

  test_unnamedConstructor_with_enclosing_type_parameters() {
    // Test a weird behavior: substitutions are recorded in typeArguments and
    // typeParameters.
    var t = new MockTypeParameterElement('T');
    var c = new MockClassElement('C', typeParameters: [t]);
    var e =
        new MockFunctionTypedElement(returnType: t.type, enclosingElement: c);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        displayName: '() → T',
        returnType: same(t.type),
        typeArguments: [same(t.type)],
        typeParameters: [same(t)]);
  }

  static InterfaceTypeImpl _makeListType() {
    var e = new MockTypeParameterElement('E');
    return new InterfaceTypeImpl.elementWithNameAndArgs(
        new MockClassElement('List', typeParameters: [e]),
        'List',
        () => [e.type]);
  }

  static InterfaceTypeImpl _makeMapType() {
    var k = new MockTypeParameterElement('K');
    var v = new MockTypeParameterElement('V');
    return new InterfaceTypeImpl.elementWithNameAndArgs(
        new MockClassElement('Map', typeParameters: [k, v]),
        'Map',
        () => [k.type, v.type]);
  }
}

class MockClassElement implements ClassElementImpl {
  @override
  final List<TypeParameterElement> typeParameters;

  @override
  final String displayName;

  MockClassElement(this.displayName, {this.typeParameters: const []});

  @override
  get enclosingElement => const MockCompilationUnitElement();

  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockCompilationUnitElement implements CompilationUnitElement {
  const MockCompilationUnitElement();

  @override
  get enclosingElement => const MockLibraryElement();

  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockElementLocation implements ElementLocation {
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockFunctionTypedElement implements FunctionTypedElement {
  @override
  final List<ParameterElement> parameters;

  @override
  final DartType returnType;

  @override
  final List<TypeParameterElement> typeParameters;

  @override
  final Element enclosingElement;

  MockFunctionTypedElement(
      {this.parameters: const [],
      DartType returnType,
      this.typeParameters: const [],
      this.enclosingElement: const MockCompilationUnitElement()})
      : returnType = returnType ?? dynamicType;

  MockFunctionTypedElement.withNullReturn(
      {this.parameters: const [],
      this.typeParameters: const [],
      this.enclosingElement: const MockCompilationUnitElement()})
      : returnType = null;

  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockGenericFunctionTypeElementImpl
    implements GenericFunctionTypeElementImpl {
  @override
  final MockGenericTypeAliasElement enclosingElement;

  FunctionTypeImpl _type;

  MockGenericFunctionTypeElementImpl(this.enclosingElement);

  @override
  get parameters => enclosingElement.parameters;

  @override
  get returnType => enclosingElement.returnType;

  @override
  get type => _type ??= new FunctionTypeImpl(this);

  @override
  get typeParameters => enclosingElement.innerTypeParameters;

  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockGenericTypeAliasElement implements GenericTypeAliasElement {
  @override
  final String name;

  @override
  List<ParameterElement> parameters;

  @override
  final List<TypeParameterElement> typeParameters;

  @override
  DartType returnType;

  FunctionType _type;

  MockGenericFunctionTypeElementImpl _function;

  final List<TypeParameterElement> innerTypeParameters;

  MockGenericTypeAliasElement(this.name,
      {this.parameters: const [],
      DartType returnType,
      this.typeParameters: const [],
      this.innerTypeParameters: const []})
      : returnType = returnType ?? dynamicType;

  MockGenericTypeAliasElement.withNullReturn(this.name,
      {this.parameters: const [],
      this.typeParameters: const [],
      this.innerTypeParameters: const []})
      : returnType = null;

  @override
  get enclosingElement => const MockCompilationUnitElement();

  @override
  get function => _function ??= new MockGenericFunctionTypeElementImpl(this);

  @override
  get isSynthetic => false;

  @override
  FunctionType get type => _type ??= new FunctionTypeImpl.forTypedef(this);

  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockLibraryElement implements LibraryElement {
  const MockLibraryElement();

  @override
  get enclosingElement => null;

  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockMethodElement extends MockFunctionTypedElement
    implements MethodElement {
  @override
  final bool isStatic;

  MockMethodElement(MockClassElement enclosingElement,
      {this.isStatic: false, DartType returnType})
      : super(enclosingElement: enclosingElement, returnType: returnType);

  @override
  ClassElement get enclosingElement => super.enclosingElement;
}

class MockParameterElement implements ParameterElementImpl {
  @override
  Element enclosingElement;

  @override
  final String name;

  @override
  final ParameterKind parameterKind;

  @override
  final DartType type;

  MockParameterElement(this.name,
      {this.parameterKind: ParameterKind.REQUIRED, this.type});

  @override
  get displayName => name;

  @override
  bool get isNamed => parameterKind == ParameterKind.NAMED;

  @override
  bool get isNotOptional => parameterKind == ParameterKind.REQUIRED;

  @override
  bool get isOptionalPositional => parameterKind == ParameterKind.POSITIONAL;

  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockTypeParameterElement implements TypeParameterElement {
  @override
  final String name;

  TypeParameterTypeImpl _type;

  MockElementLocation _location;

  @override
  DartType bound;

  MockTypeParameterElement(this.name, {this.bound});

  @override
  get kind => ElementKind.TYPE_PARAMETER;

  @override
  get location => _location ??= new MockElementLocation();

  @override
  get type => _type ??= new TypeParameterTypeImpl(this);

  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
