// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';

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
class FunctionTypeTest with ElementsTypesMixin {
  static const bug_33294_fixed = false;
  static const bug_33300_fixed = false;
  static const bug_33301_fixed = false;
  static const bug_33302_fixed = false;

  final TypeProvider typeProvider = TestTypeProvider();

  InterfaceType get intType => typeProvider.intType;

  ClassElement get listElement => typeProvider.listType.element;

  ClassElement get mapElement => typeProvider.mapType.element;

  InterfaceType get objectType => typeProvider.objectType;

  void basicChecks(FunctionType f,
      {element,
      displayName: 'dynamic Function()',
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

  GenericTypeAliasElementImpl genericTypeAliasElement(
    String name, {
    List<ParameterElement> parameters: const [],
    DartType returnType,
    List<TypeParameterElement> typeParameters: const [],
    List<TypeParameterElement> innerTypeParameters: const [],
  }) {
    var aliasElement = GenericTypeAliasElementImpl(name, 0);
    aliasElement.typeParameters = typeParameters;

    var functionElement = GenericFunctionTypeElementImpl.forOffset(0);
    aliasElement.function = functionElement;
    functionElement.typeParameters = innerTypeParameters;
    functionElement.parameters = parameters;
    functionElement.returnType = returnType;

    return aliasElement;
  }

  DartType listOf(DartType elementType) => listElement.instantiate(
        typeArguments: [elementType],
        nullabilitySuffix: NullabilitySuffix.star,
      );

  DartType mapOf(DartType keyType, DartType valueType) =>
      mapElement.instantiate(
        typeArguments: [keyType, valueType],
        nullabilitySuffix: NullabilitySuffix.star,
      );

  test_forInstantiatedTypedef_bothTypeParameters_noTypeArgs() {
    // typedef F<T> = Map<T, U> Function<U>();
    var t = typeParameter('T');
    var u = typeParameter('U');
    var e = genericTypeAliasElement('F',
        typeParameters: [t],
        innerTypeParameters: [u],
        returnType: mapOf(typeParameterType(t), typeParameterType(u)));
    FunctionType f = new FunctionTypeImpl.forTypedef(e);
    // Note: forTypedef returns the type `<T>() -> Map<T, U>`.
    // See https://github.com/dart-lang/sdk/issues/34657.
    basicChecks(f,
        element: same(e),
        displayName: 'F',
        name: 'F',
        typeFormals: [same(t)],
        returnType: mapOf(typeParameterType(t), typeParameterType(u)));
  }

  test_forInstantiatedTypedef_innerTypeParameter_noTypeArgs() {
    // typedef F = T F<T>();
    var t = typeParameter('T');
    var e = genericTypeAliasElement('F',
        innerTypeParameters: [t], returnType: typeParameterType(t));
    FunctionType f = new FunctionTypeImpl.forTypedef(e);
    // Note: forTypedef returns the type `() -> T`.
    // See https://github.com/dart-lang/sdk/issues/34657.
    basicChecks(f,
        element: same(e),
        displayName: 'F',
        name: 'F',
        returnType: typeParameterType(t));
  }

  test_forInstantiatedTypedef_noTypeParameters_noTypeArgs() {
    // typedef F = void Function();
    var e = genericTypeAliasElement('F');
    FunctionType f = new FunctionTypeImpl.forTypedef(e);
    // Note: forTypedef returns the type `() -> void`.
    basicChecks(f, element: same(e), displayName: 'F', name: 'F');
  }

  test_forInstantiatedTypedef_outerTypeParameters_noTypeArgs() {
    // typedef F<T> = T Function();
    var t = typeParameter('T');
    var e = genericTypeAliasElement('F',
        typeParameters: [t], returnType: typeParameterType(t));
    FunctionType f = new FunctionTypeImpl.forTypedef(e);
    // Note: forTypedef returns the type `<T>() -> T`.
    // See https://github.com/dart-lang/sdk/issues/34657.
    basicChecks(f,
        element: same(e),
        displayName: 'F',
        name: 'F',
        typeFormals: [same(t)],
        returnType: typeParameterType(t));
  }

  test_forTypedef() {
    var e = genericTypeAliasElement('F');
    basicChecks(functionTypeAliasType(e),
        element: same(e), displayName: 'F', name: 'F');
    basicChecks(e.function.type,
        element: same(e.function), displayName: 'dynamic Function()');
  }

  test_forTypedef_innerAndOuterTypeParameter() {
    // typedef F<T> = T Function<U>(U p);
    var t = typeParameter('T');
    var u = typeParameter('U');
    var p = requiredParameter('p', type: typeParameterType(u));
    var e = genericTypeAliasElement('F',
        typeParameters: [t],
        innerTypeParameters: [u],
        returnType: typeParameterType(t),
        parameters: [p]);
    basicChecks(e.type,
        element: same(e),
        displayName: 'F',
        name: 'F',
        returnType: typeParameterType(t),
        normalParameterTypes: [typeParameterType(u)],
        normalParameterNames: ['p'],
        parameters: [same(p)],
        typeFormals: [same(t)]);
    basicChecks(e.function.type,
        element: same(e.function),
        displayName: 'T Function<U>(U)',
        returnType: typeParameterType(t),
        typeArguments: [typeParameterType(t)],
        typeParameters: [same(t)],
        typeFormals: [same(u)],
        normalParameterTypes: [typeParameterType(u)],
        normalParameterNames: ['p'],
        parameters: [same(p)]);
  }

  test_forTypedef_innerAndOuterTypeParameter_instantiate() {
    // typedef F<T> = T Function<U>(U p);
    var t = typeParameter('T');
    var u = typeParameter('U');
    var p = requiredParameter('p', type: typeParameterType(u));
    var e = genericTypeAliasElement('F',
        typeParameters: [t],
        innerTypeParameters: [u],
        returnType: typeParameterType(t),
        parameters: [p]);
    var instantiated = functionTypeAliasType(e, typeArguments: [objectType]);
    basicChecks(instantiated,
        element: same(e),
        displayName: 'F<Object>',
        name: 'F',
        returnType: same(objectType),
        normalParameterTypes: [typeParameterType(u)],
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
    var t = typeParameter('T');
    var e = genericTypeAliasElement('F',
        innerTypeParameters: [t], returnType: typeParameterType(t));
    basicChecks(functionTypeAliasType(e),
        element: same(e),
        displayName: 'F',
        name: 'F',
        returnType: typeParameterType(t));
    basicChecks(e.function.type,
        element: same(e.function),
        displayName: 'T Function<T>()',
        returnType: typeParameterType(t),
        typeFormals: [same(t)]);
  }

  test_forTypedef_normalParameter() {
    var p = requiredParameter('p', type: dynamicType);
    var e = genericTypeAliasElement('F', parameters: [p]);
    basicChecks(functionTypeAliasType(e),
        element: same(e),
        displayName: 'F',
        name: 'F',
        normalParameterNames: ['p'],
        normalParameterTypes: [same(dynamicType)],
        parameters: [same(p)]);
    basicChecks(e.function.type,
        element: same(e.function),
        displayName: 'dynamic Function(dynamic)',
        normalParameterNames: ['p'],
        normalParameterTypes: [same(dynamicType)],
        parameters: [same(p)]);
  }

  test_forTypedef_recursive_via_interfaceTypes() {
    // typedef F = List<G> Function();
    // typedef G = List<F> Function();
    var f = genericTypeAliasElement('F');
    var g = genericTypeAliasElement('G');
    f.function.returnType = listOf(g.function.type);
    g.function.returnType = listOf(f.function.type);
    basicChecks(functionTypeAliasType(f),
        element: same(f), displayName: 'F', name: 'F', returnType: isNotNull);
    var fReturn = functionTypeAliasType(f).returnType;
    expect(fReturn.element, same(listElement));
    if (bug_33302_fixed) {
      expect(fReturn.displayName, 'List<G>');
    } else {
      expect(fReturn.displayName, 'List<List<...> Function()>');
    }
    var fReturnArg = (fReturn as InterfaceType).typeArguments[0];
    expect(fReturnArg.element, same(g.function));
    var fReturnArgReturn = (fReturnArg as FunctionType).returnType;
    expect(fReturnArgReturn.element, same(listElement));
    expect((fReturnArgReturn as InterfaceType).typeArguments[0],
        new TypeMatcher<CircularFunctionTypeImpl>());
    basicChecks(f.function.type,
        element: same(f.function), displayName: isNotNull, returnType: fReturn);
    if (bug_33302_fixed) {
      expect(f.function.type.displayName, 'List<G> Function()');
    } else {
      expect(
          f.function.type.displayName, 'List<List<...> Function()> Function()');
    }
    basicChecks(functionTypeAliasType(g),
        element: same(g), displayName: 'G', name: 'G', returnType: isNotNull);
    var gReturn = functionTypeAliasType(g).returnType;
    expect(gReturn.element, same(listElement));
    if (bug_33302_fixed) {
      expect(gReturn.displayName, 'List<F>');
    } else {
      expect(gReturn.displayName, 'List<List<...> Function()>');
    }
    var gReturnArg = (gReturn as InterfaceType).typeArguments[0];
    expect(gReturnArg.element, same(f.function));
    var gReturnArgReturn = (gReturnArg as FunctionType).returnType;
    expect(gReturnArgReturn.element, same(listElement));
    expect((gReturnArgReturn as InterfaceType).typeArguments[0],
        new TypeMatcher<CircularFunctionTypeImpl>());
    basicChecks(g.function.type,
        element: same(g.function), displayName: isNotNull, returnType: gReturn);
    if (bug_33302_fixed) {
      expect(g.function.type.displayName, 'F Function()');
    } else {
      expect(
          g.function.type.displayName, 'List<List<...> Function()> Function()');
    }
  }

  test_forTypedef_recursive_via_parameterTypes() {
    // typedef F = void Function(G g);
    // typedef G = void Function(F f);
    var f = genericTypeAliasElement('F', returnType: voidType);
    var g = genericTypeAliasElement('G', returnType: voidType);
    f.function.parameters = [requiredParameter('g', type: g.function.type)];
    g.function.parameters = [requiredParameter('f', type: f.function.type)];
    basicChecks(functionTypeAliasType(f),
        element: same(f),
        displayName: 'F',
        name: 'F',
        parameters: hasLength(1),
        normalParameterTypes: hasLength(1),
        normalParameterNames: ['g'],
        returnType: same(voidType));
    var fParamType = functionTypeAliasType(f).normalParameterTypes[0];
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
      expect(f.function.type.displayName, 'void Function(G)');
    } else {
      expect(f.function.type.displayName, 'void Function(void Function(...))');
    }
    basicChecks(functionTypeAliasType(g),
        element: same(g),
        displayName: 'G',
        name: 'G',
        parameters: hasLength(1),
        normalParameterTypes: hasLength(1),
        normalParameterNames: ['f'],
        returnType: same(voidType));
    var gParamType = functionTypeAliasType(g).normalParameterTypes[0];
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
      expect(g.function.type.displayName, 'void Function(F)');
    } else {
      expect(g.function.type.displayName, 'void Function(void Function(...))');
    }
  }

  test_forTypedef_recursive_via_returnTypes() {
    // typedef F = G Function();
    // typedef G = F Function();
    var f = genericTypeAliasElement('F');
    var g = genericTypeAliasElement('G');
    f.function.returnType = g.function.type;
    g.function.returnType = f.function.type;
    basicChecks(functionTypeAliasType(f),
        element: same(f), displayName: 'F', name: 'F', returnType: isNotNull);
    var fReturn = functionTypeAliasType(f).returnType;
    expect(fReturn.element, same(g.function));
    expect((fReturn as FunctionType).returnType,
        new TypeMatcher<CircularFunctionTypeImpl>());
    basicChecks(f.function.type,
        element: same(f.function), displayName: isNotNull, returnType: fReturn);
    if (bug_33302_fixed) {
      expect(f.function.type.displayName, 'G Function()');
    } else {
      expect(f.function.type.displayName, '... Function() Function()');
    }
    basicChecks(functionTypeAliasType(g),
        element: same(g), displayName: 'G', name: 'G', returnType: isNotNull);
    var gReturn = functionTypeAliasType(g).returnType;
    expect(gReturn.element, same(f.function));
    expect((gReturn as FunctionType).returnType,
        new TypeMatcher<CircularFunctionTypeImpl>());
    basicChecks(g.function.type,
        element: same(g.function), displayName: isNotNull, returnType: gReturn);
    if (bug_33302_fixed) {
      expect(g.function.type.displayName, 'F Function()');
    } else {
      expect(g.function.type.displayName, '... Function() Function()');
    }
  }

  test_forTypedef_returnType() {
    var e = genericTypeAliasElement('F', returnType: objectType);
    basicChecks(functionTypeAliasType(e),
        element: same(e), displayName: 'F', name: 'F', returnType: objectType);
    basicChecks(e.function.type,
        element: same(e.function),
        displayName: 'Object Function()',
        returnType: objectType);
  }

  test_forTypedef_returnType_null() {
    var e = genericTypeAliasElement('F');
    basicChecks(functionTypeAliasType(e),
        element: same(e), displayName: 'F', name: 'F');
    basicChecks(e.function.type,
        element: same(e.function), displayName: 'dynamic Function()');
  }

  test_forTypedef_typeParameter() {
    // typedef F<T> = T Function();
    var t = typeParameter('T');
    var e = genericTypeAliasElement('F',
        typeParameters: [t], returnType: typeParameterType(t));
    basicChecks(e.type,
        element: same(e),
        displayName: 'F',
        name: 'F',
        returnType: typeParameterType(t),
        typeFormals: [same(t)]);
    basicChecks(e.function.type,
        element: same(e.function),
        displayName: 'T Function()',
        returnType: typeParameterType(t),
        typeArguments: [typeParameterType(t)],
        typeParameters: [same(t)]);
  }

  test_synthetic() {
    FunctionType f = new FunctionTypeImpl.synthetic(dynamicType, [], []);
    basicChecks(f, element: isNull);
  }

  test_synthetic_instantiate() {
    // T Function<T>(T x)
    var t = typeParameter('T');
    var x = requiredParameter('x', type: typeParameterType(t));
    FunctionType f =
        new FunctionTypeImpl.synthetic(typeParameterType(t), [t], [x]);
    FunctionType instantiated = f.instantiate([objectType]);
    basicChecks(instantiated,
        element: isNull,
        displayName: 'Object Function(Object)',
        returnType: same(objectType),
        normalParameterNames: ['x'],
        normalParameterTypes: [same(objectType)],
        parameters: hasLength(1));
  }

  test_synthetic_instantiate_argument_length_mismatch() {
    // dynamic Function<T>()
    var t = typeParameter('T');
    FunctionType f = new FunctionTypeImpl.synthetic(dynamicType, [t], []);
    expect(() => f.instantiate([]), throwsA(new TypeMatcher<ArgumentError>()));
  }

  test_synthetic_instantiate_no_type_formals() {
    FunctionType f = new FunctionTypeImpl.synthetic(dynamicType, [], []);
    expect(f.instantiate([]), same(f));
  }

  test_synthetic_instantiate_share_parameters() {
    // T Function<T>(int x)
    var t = typeParameter('T');
    var x = requiredParameter('x', type: intType);
    FunctionType f =
        new FunctionTypeImpl.synthetic(typeParameterType(t), [t], [x]);
    FunctionType instantiated = f.instantiate([objectType]);
    basicChecks(instantiated,
        element: isNull,
        displayName: 'Object Function(int)',
        returnType: same(objectType),
        normalParameterNames: ['x'],
        normalParameterTypes: [same(intType)],
        parameters: same(f.parameters));
  }

  test_synthetic_namedParameter() {
    var p = namedParameter('x', type: objectType);
    FunctionType f = new FunctionTypeImpl.synthetic(dynamicType, [], [p]);
    basicChecks(f,
        element: isNull,
        displayName: 'dynamic Function({x: Object})',
        namedParameterTypes: {'x': same(objectType)},
        parameters: hasLength(1));
    expect(f.parameters[0].isNamed, isTrue);
    expect(f.parameters[0].name, 'x');
    expect(f.parameters[0].type, same(objectType));
  }

  test_synthetic_normalParameter() {
    var p = requiredParameter('x', type: objectType);
    FunctionType f = new FunctionTypeImpl.synthetic(dynamicType, [], [p]);
    basicChecks(f,
        element: isNull,
        displayName: 'dynamic Function(Object)',
        normalParameterNames: ['x'],
        normalParameterTypes: [same(objectType)],
        parameters: hasLength(1));
    expect(f.parameters[0].isRequiredPositional, isTrue);
    expect(f.parameters[0].name, 'x');
    expect(f.parameters[0].type, same(objectType));
  }

  test_synthetic_optionalParameter() {
    var p = positionalParameter('x', type: objectType);
    FunctionType f = new FunctionTypeImpl.synthetic(dynamicType, [], [p]);
    basicChecks(f,
        element: isNull,
        displayName: 'dynamic Function([Object])',
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
        displayName: 'Object Function()',
        returnType: same(objectType));
  }

  test_synthetic_substitute() {
    // Map<T, U> Function<U extends T>(T x, U y)
    var t = typeParameter('T');
    var u = typeParameter('U', bound: typeParameterType(t));
    var x = requiredParameter('x', type: typeParameterType(t));
    var y = requiredParameter('y', type: typeParameterType(u));
    FunctionType f = new FunctionTypeImpl.synthetic(
        mapOf(typeParameterType(t), typeParameterType(u)), [u], [x, y]);
    FunctionType substituted =
        f.substitute2([objectType], [typeParameterType(t)]);
    var uSubstituted = substituted.typeFormals[0];
    basicChecks(substituted,
        element: isNull,
        displayName: 'Map<Object, U> Function<U extends Object>(Object, U)',
        returnType: mapOf(objectType, typeParameterType(uSubstituted)),
        typeFormals: [uSubstituted],
        normalParameterNames: ['x', 'y'],
        normalParameterTypes: [
          same(objectType),
          typeParameterType(uSubstituted)
        ],
        parameters: hasLength(2));
  }

  test_synthetic_substitute_argument_length_mismatch() {
    // dynamic Function()
    var t = typeParameter('T');
    FunctionType f = new FunctionTypeImpl.synthetic(dynamicType, [], []);
    expect(() => f.substitute2([], [typeParameterType(t)]),
        throwsA(new TypeMatcher<ArgumentError>()));
  }

  test_synthetic_substitute_share_returnType_and_parameters() {
    // int Function<U extends T>(int x)
    var t = typeParameter('T');
    var u = typeParameter('U', bound: typeParameterType(t));
    var x = requiredParameter('x', type: intType);
    FunctionType f = new FunctionTypeImpl.synthetic(intType, [u], [x]);
    FunctionType substituted =
        f.substitute2([objectType], [typeParameterType(t)]);
    basicChecks(substituted,
        element: isNull,
        displayName: 'int Function<U extends Object>(int)',
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
    var t = typeParameter('T');
    var u = typeParameter('U');
    var x = requiredParameter('x', type: typeParameterType(t));
    var y = requiredParameter('y', type: typeParameterType(u));
    FunctionType f = new FunctionTypeImpl.synthetic(intType, [u], [x, y]);
    FunctionType substituted =
        f.substitute2([objectType], [typeParameterType(t)]);
    basicChecks(substituted,
        element: isNull,
        displayName: 'int Function<U>(Object, U)',
        returnType: same(f.returnType),
        typeFormals: same(f.typeFormals),
        normalParameterNames: ['x', 'y'],
        normalParameterTypes: [same(objectType), typeParameterType(u)],
        parameters: hasLength(2));
  }

  test_synthetic_substitute_share_typeFormals_and_parameters() {
    // T Function<U>(U x)
    var t = typeParameter('T');
    var u = typeParameter('U');
    var x = requiredParameter('x', type: typeParameterType(u));
    FunctionType f =
        new FunctionTypeImpl.synthetic(typeParameterType(t), [u], [x]);
    FunctionType substituted =
        f.substitute2([objectType], [typeParameterType(t)]);
    basicChecks(substituted,
        element: isNull,
        displayName: 'Object Function<U>(U)',
        returnType: same(objectType),
        typeFormals: same(f.typeFormals),
        normalParameterNames: ['x'],
        normalParameterTypes: [typeParameterType(u)],
        parameters: same(f.parameters));
  }

  test_synthetic_substitute_unchanged() {
    // dynamic Function<U>(U x)
    var t = typeParameter('T');
    var u = typeParameter('U');
    var x = requiredParameter('x', type: typeParameterType(u));
    FunctionType f = new FunctionTypeImpl.synthetic(dynamicType, [u], [x]);
    FunctionType substituted =
        f.substitute2([objectType], [typeParameterType(t)]);
    expect(substituted, same(f));
  }

  test_synthetic_typeFormals() {
    var t = typeParameter('T');
    FunctionType f =
        new FunctionTypeImpl.synthetic(typeParameterType(t), [t], []);
    basicChecks(f,
        element: isNull,
        displayName: 'T Function<T>()',
        returnType: typeParameterType(t),
        typeFormals: [same(t)]);
  }

  test_unnamedConstructor() {
    var e = new MockFunctionTypedElement();
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f, element: same(e));
  }

  test_unnamedConstructor_instantiate_argument_length_mismatch() {
    var t = typeParameter('T');
    var e = new MockFunctionTypedElement(typeParameters: [t]);
    FunctionType f = new FunctionTypeImpl(e);
    expect(() => f.instantiate([]), throwsA(new TypeMatcher<ArgumentError>()));
  }

  test_unnamedConstructor_instantiate_noTypeParameters() {
    var e = new MockFunctionTypedElement();
    FunctionType f = new FunctionTypeImpl(e);
    expect(f.instantiate([]), same(f));
  }

  test_unnamedConstructor_instantiate_parameterType_simple() {
    var t = typeParameter('T');
    var p = requiredParameter('x', type: typeParameterType(t));
    var e = new MockFunctionTypedElement(typeParameters: [t], parameters: [p]);
    FunctionType f = new FunctionTypeImpl(e);
    var instantiated = f.instantiate([objectType]);
    basicChecks(instantiated,
        element: same(e),
        displayName: 'dynamic Function(Object)',
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
    var t = typeParameter('T');
    var e = new MockFunctionTypedElement(
        typeParameters: [t], returnType: typeParameterType(t));
    FunctionType f = new FunctionTypeImpl(e);
    var instantiated = f.instantiate([objectType]);
    basicChecks(instantiated,
        element: same(e),
        displayName: 'Object Function()',
        typeArguments: hasLength(1),
        typeParameters: [same(t)],
        returnType: same(objectType));
    expect(instantiated.typeArguments[0], same(objectType));
  }

  test_unnamedConstructor_namedParameter() {
    var p = namedParameter('x', type: dynamicType);
    var e = new MockFunctionTypedElement(parameters: [p]);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        displayName: 'dynamic Function({x: dynamic})',
        namedParameterTypes: {'x': same(dynamicType)},
        parameters: [same(p)]);
  }

  test_unnamedConstructor_namedParameter_object() {
    var p = namedParameter('x', type: objectType);
    var e = new MockFunctionTypedElement(parameters: [p]);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        displayName: 'dynamic Function({x: Object})',
        namedParameterTypes: {'x': same(objectType)},
        parameters: [same(p)]);
  }

  test_unnamedConstructor_nonTypedef_noTypeArguments() {
    var e = new MockFunctionTypedElement();
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f, element: same(e));
  }

  test_unnamedConstructor_nonTypedef_withTypeArguments() {
    var t = typeParameter('T');
    var e = method('e', typeParameterType(t));
    class_(name: 'C', typeParameters: [t], methods: [e]);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        typeArguments: [typeParameterType(t)],
        typeParameters: [same(t)],
        displayName: 'T Function()',
        returnType: typeParameterType(t));
  }

  test_unnamedConstructor_normalParameter() {
    var p = requiredParameter('x', type: dynamicType);
    var e = new MockFunctionTypedElement(parameters: [p]);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        displayName: 'dynamic Function(dynamic)',
        normalParameterNames: ['x'],
        normalParameterTypes: [same(dynamicType)],
        parameters: [same(p)]);
  }

  test_unnamedConstructor_normalParameter_object() {
    var p = requiredParameter('x', type: objectType);
    var e = new MockFunctionTypedElement(parameters: [p]);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        displayName: 'dynamic Function(Object)',
        normalParameterNames: ['x'],
        normalParameterTypes: [same(objectType)],
        parameters: [same(p)]);
  }

  test_unnamedConstructor_optionalParameter() {
    var p = positionalParameter('x', type: dynamicType);
    var e = new MockFunctionTypedElement(parameters: [p]);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        displayName: 'dynamic Function([dynamic])',
        optionalParameterNames: ['x'],
        optionalParameterTypes: [same(dynamicType)],
        parameters: [same(p)]);
  }

  test_unnamedConstructor_optionalParameter_object() {
    var p = positionalParameter('x', type: objectType);
    var e = new MockFunctionTypedElement(parameters: [p]);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        displayName: 'dynamic Function([Object])',
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
        displayName: 'Object Function()');
  }

  test_unnamedConstructor_returnType_null() {
    var e = new MockFunctionTypedElement.withNullReturn();
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        returnType: same(dynamicType),
        displayName: 'dynamic Function()');
  }

  test_unnamedConstructor_staticMethod_ignores_enclosing_type_params() {
    var t = typeParameter('T');
    var e = method('e', dynamicType, isStatic: true);
    class_(name: 'C', typeParameters: [t], methods: [e]);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f, element: same(e));
  }

  test_unnamedConstructor_substitute_argument_length_mismatch() {
    // abstract class C<T> {
    //   dynamic f();
    // }
    var t = typeParameter('T');
    var c = class_(name: 'C', typeParameters: [t]);
    var e = new MockFunctionTypedElement(enclosingElement: c);
    FunctionType f = new FunctionTypeImpl(e);
    expect(() => f.substitute2([], [typeParameterType(t)]),
        throwsA(new TypeMatcher<ArgumentError>()));
  }

  test_unnamedConstructor_substitute_bound_recursive() {
    // abstract class C<T> {
    //   Map<S, V> f<S extends T, T extends U, V extends T>();
    // }
    var s = typeParameter('S');
    var t = typeParameter('T');
    var u = typeParameter('U');
    var v = typeParameter('V');
    s.bound = typeParameterType(t);
    t.bound = typeParameterType(u);
    v.bound = typeParameterType(t);
    var c = class_(name: 'C', typeParameters: [u]);
    var e = new MockFunctionTypedElement(
        returnType: mapOf(typeParameterType(s), typeParameterType(v)),
        typeParameters: [s, t, v],
        enclosingElement: c);
    FunctionType f = new FunctionTypeImpl(e);
    var substituted = f.substitute2([objectType], [typeParameterType(u)]);
    basicChecks(substituted,
        element: same(e),
        displayName: isNotNull,
        returnType: isNotNull,
        typeFormals: hasLength(3),
        typeParameters: [same(u)],
        typeArguments: [same(objectType)]);
    if (bug_33300_fixed) {
      expect(substituted.displayName,
          'Map<S, V> Function<S extends T,T extends Object,V extends T>()');
    } else {
      expect(substituted.displayName,
          'Map<S, V> Function<S extends T extends Object,T extends Object,V extends T>()');
    }
    var s2 = substituted.typeFormals[0];
    var t2 = substituted.typeFormals[1];
    var v2 = substituted.typeFormals[2];
    expect(s2.name, 'S');
    expect(t2.name, 'T');
    expect(v2.name, 'V');
    expect(s2.bound, typeParameterType(t2));
    expect(t2.bound, same(objectType));
    expect(v2.bound, typeParameterType(t2));
    if (bug_33301_fixed) {
      expect(substituted.returnType,
          mapOf(typeParameterType(s2), typeParameterType(v2)));
    } else {
      expect(substituted.returnType,
          mapOf(typeParameterType(s), typeParameterType(v)));
    }
  }

  test_unnamedConstructor_substitute_bound_recursive_parameter() {
    // abstract class C<T> {
    //   void f<S extends T, T extends U, V extends T>(S x, V y);
    // }
    var s = typeParameter('S');
    var t = typeParameter('T');
    var u = typeParameter('U');
    var v = typeParameter('V');
    s.bound = typeParameterType(t);
    t.bound = typeParameterType(u);
    v.bound = typeParameterType(t);
    var c = class_(name: 'C', typeParameters: [u]);
    var x = requiredParameter('x', type: typeParameterType(s));
    var y = requiredParameter('y', type: typeParameterType(v));
    var e = new MockFunctionTypedElement(
        returnType: voidType,
        typeParameters: [s, t, v],
        enclosingElement: c,
        parameters: [x, y]);
    FunctionType f = new FunctionTypeImpl(e);
    var substituted = f.substitute2([objectType], [typeParameterType(u)]);
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
          'void Function<S extends T,T extends Object,V extends T>(S, V)');
    } else {
      expect(substituted.displayName,
          'void Function<S extends T extends Object,T extends Object,V extends T>(S, V)');
    }
    var s2 = substituted.typeFormals[0];
    var t2 = substituted.typeFormals[1];
    var v2 = substituted.typeFormals[2];
    expect(s2.name, 'S');
    expect(t2.name, 'T');
    expect(v2.name, 'V');
    expect(s2.bound, typeParameterType(t2));
    expect(t2.bound, same(objectType));
    expect(v2.bound, typeParameterType(t2));
    if (bug_33301_fixed) {
      expect(substituted.normalParameterTypes,
          [same(typeParameterType(s2)), same(typeParameterType(v2))]);
    } else {
      expect(substituted.normalParameterTypes,
          [typeParameterType(s), typeParameterType(v)]);
    }
  }

  test_unnamedConstructor_substitute_bound_simple() {
    // abstract class C<T> {
    //   U f<U extends T>();
    // }
    var t = typeParameter('T');
    var c = class_(name: 'C', typeParameters: [t]);
    var u = typeParameter('U', bound: typeParameterType(t));
    var e = new MockFunctionTypedElement(
        typeParameters: [u],
        returnType: typeParameterType(u),
        enclosingElement: c);
    FunctionType f = new FunctionTypeImpl(e);
    var substituted = f.substitute2([objectType], [typeParameterType(t)]);
    basicChecks(substituted,
        element: same(e),
        displayName: 'U Function<U extends Object>()',
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
    var t = typeParameter('T');
    var e = new MockFunctionTypedElement(returnType: typeParameterType(t));
    FunctionType f = new FunctionTypeImpl(e);
    var substituted =
        f.substitute2([typeParameterType(t)], [typeParameterType(t)]);
    basicChecks(substituted,
        element: same(e),
        displayName: 'T Function()',
        returnType: typeParameterType(t));
    // TODO(paulberry): test substitute length mismatch
  }

  test_unnamedConstructor_substitute_parameterType_simple() {
    var t = typeParameter('T');
    var c = class_(name: 'C', typeParameters: [t]);
    var p = requiredParameter('x', type: typeParameterType(t));
    var e = new MockFunctionTypedElement(parameters: [p], enclosingElement: c);
    FunctionType f = new FunctionTypeImpl(e);
    var substituted = f.substitute2([objectType], [typeParameterType(t)]);
    basicChecks(substituted,
        element: same(e),
        displayName: 'dynamic Function(Object)',
        normalParameterNames: ['x'],
        normalParameterTypes: [same(objectType)],
        parameters: hasLength(1),
        typeArguments: [same(objectType)],
        typeParameters: [same(t)]);
    expect(substituted.parameters[0].name, 'x');
    expect(substituted.parameters[0].type, same(objectType));
  }

  test_unnamedConstructor_substitute_returnType_simple() {
    var t = typeParameter('T');
    var c = class_(name: 'C', typeParameters: [t]);
    var e = new MockFunctionTypedElement(
        returnType: typeParameterType(t), enclosingElement: c);
    FunctionType f = new FunctionTypeImpl(e);
    var substituted = f.substitute2([objectType], [typeParameterType(t)]);
    basicChecks(substituted,
        element: same(e),
        displayName: 'Object Function()',
        returnType: same(objectType),
        typeArguments: [same(objectType)],
        typeParameters: [same(t)]);
  }

  test_unnamedConstructor_typeParameter() {
    var t = typeParameter('T');
    var e = new MockFunctionTypedElement(typeParameters: [t]);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        displayName: 'dynamic Function<T>()',
        typeFormals: [same(t)]);
    // TODO(paulberry): test pruning of bounds
  }

  test_unnamedConstructor_typeParameter_with_bound() {
    var t = typeParameter('T');
    var c = class_(name: 'C', typeParameters: [t]);
    var u = typeParameter('U', bound: typeParameterType(t));
    var e = new MockFunctionTypedElement(
        typeParameters: [u],
        returnType: typeParameterType(u),
        enclosingElement: c);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        displayName: 'U Function<U extends T>()',
        typeArguments: [typeParameterType(t)],
        typeParameters: [same(t)],
        returnType: typeParameterType(u),
        typeFormals: hasLength(1));
    expect(f.typeFormals[0].name, 'U');
    expect(f.typeFormals[0].bound, typeParameterType(t));
  }

  test_unnamedConstructor_with_enclosing_type_parameters() {
    // Test a weird behavior: substitutions are recorded in typeArguments and
    // typeParameters.
    var t = typeParameter('T');
    var c = class_(name: 'C', typeParameters: [t]);
    var e = new MockFunctionTypedElement(
        returnType: typeParameterType(t), enclosingElement: c);
    FunctionType f = new FunctionTypeImpl(e);
    basicChecks(f,
        element: same(e),
        displayName: 'T Function()',
        returnType: typeParameterType(t),
        typeArguments: [typeParameterType(t)],
        typeParameters: [same(t)]);
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

class MockLibraryElement implements LibraryElement {
  const MockLibraryElement();

  @override
  get enclosingElement => null;

  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
