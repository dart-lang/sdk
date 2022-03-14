// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart';

const Map<String, ClassData> expectedClassData = {
  'Class1': ClassData(superclassOf: 'Object'),
  'Class2': ClassData(isAbstract: true, superclassOf: 'Object'),
  'Class3': ClassData(superclassOf: 'Class2', superSuperclassOf: 'Object'),
  'Class4': ClassData(superclassOf: 'Class1', superSuperclassOf: 'Object'),
};

const Map<String, FunctionData> expectedFunctionData = {
  'topLevelFunction1': FunctionData(
      returnType: NamedTypeData(name: 'void'),
      positionalParameters: [
        ParameterData('a',
            type: NamedTypeData(name: 'Class1'), isRequired: true),
      ],
      namedParameters: [
        ParameterData('b',
            type: NamedTypeData(name: 'Class1', isNullable: true),
            isNamed: true,
            isRequired: false),
        ParameterData('c',
            type: NamedTypeData(name: 'Class2', isNullable: true),
            isNamed: true,
            isRequired: true),
      ]),
  'topLevelFunction2': FunctionData(
    isExternal: true,
    returnType: NamedTypeData(name: 'Class2'),
    positionalParameters: [
      ParameterData('a', type: NamedTypeData(name: 'Class1'), isRequired: true),
      ParameterData('b', type: NamedTypeData(name: 'Class2', isNullable: true)),
    ],
  ),
};

expect(expected, actual, property) {
  if (expected != actual) {
    throw 'Expected $expected, actual $actual on $property';
  }
}

Future<void> throws(Future<void> Function() f, property) async {
  try {
    await f();
  } catch (_) {
    return;
  }
  throw 'Expected throws on $property';
}

void checkTypeAnnotation(
    TypeData expected, TypeAnnotation typeAnnotation, String context) {
  expect(expected.isNullable, typeAnnotation.isNullable, '$context.isNullable');
  expect(expected is NamedTypeData, typeAnnotation is NamedTypeAnnotation,
      '$context is NamedTypeAnnotation');
  if (expected is NamedTypeData && typeAnnotation is NamedTypeAnnotation) {
    expect(expected.name, typeAnnotation.identifier.name, '$context.name');
    // TODO(johnniwinther): Test more properties.
  }
}

void checkParameterDeclaration(
    ParameterData expected, ParameterDeclaration declaration, String context) {
  expect(expected.name, declaration.identifier.name, '$context.identifer.name');
  expect(expected.isNamed, declaration.isNamed, '$context.isNamed');
  expect(expected.isRequired, declaration.isRequired, '$context.isRequired');
  checkTypeAnnotation(expected.type, declaration.type, '$context.type');
}

Future<void> checkClassDeclaration(ClassDeclaration declaration,
    {ClassIntrospector? classIntrospector}) async {
  String name = declaration.identifier.name;
  ClassData? expected = expectedClassData[name];
  if (expected != null) {
    expect(expected.isAbstract, declaration.isAbstract, '$name.isAbstract');
    expect(expected.isExternal, declaration.isExternal, '$name.isExternal');
    if (classIntrospector != null) {
      ClassDeclaration? superclassOf =
          await classIntrospector.superclassOf(declaration);
      expect(expected.superclassOf, superclassOf?.identifier.name,
          '$name.superclassOf');
      if (superclassOf != null) {
        ClassDeclaration? superSuperclassOf =
            await classIntrospector.superclassOf(superclassOf);
        expect(expected.superSuperclassOf, superSuperclassOf?.identifier.name,
            '$name.superSuperclassOf');
      }
    }
    // TODO(johnniwinther): Test more properties when there are supported.
  } else {
    throw 'Unexpected class declaration "${name}"';
  }
}

void checkFunctionDeclaration(FunctionDeclaration actual) {
  String name = actual.identifier.name;
  FunctionData? expected = expectedFunctionData[name];
  if (expected != null) {
    expect(expected.isAbstract, actual.isAbstract, '$name.isAbstract');
    expect(expected.isExternal, actual.isExternal, '$name.isExternal');
    expect(expected.isOperator, actual.isOperator, '$name.isOperator');
    expect(expected.isGetter, actual.isGetter, '$name.isGetter');
    expect(expected.isSetter, actual.isSetter, '$name.isSetter');
    checkTypeAnnotation(
        expected.returnType, actual.returnType, '$name.returnType');
    expect(
        expected.positionalParameters.length,
        actual.positionalParameters.length,
        '$name.positionalParameters.length');
    for (int i = 0; i < expected.positionalParameters.length; i++) {
      checkParameterDeclaration(
          expected.positionalParameters[i],
          actual.positionalParameters.elementAt(i),
          '$name.positionalParameters[$i]');
    }
    expect(expected.namedParameters.length, actual.namedParameters.length,
        '$name.namedParameters.length');
    for (int i = 0; i < expected.namedParameters.length; i++) {
      checkParameterDeclaration(expected.namedParameters[i],
          actual.namedParameters.elementAt(i), '$name.namedParameters[$i]');
    }
    // TODO(johnniwinther): Test more properties.
  } else {
    throw 'Unexpected function declaration "${name}"';
  }
}

Future<void> checkIdentifierResolver(
    IdentifierResolver identifierResolver) async {
  Uri dartCore = Uri.parse('dart:core');
  Uri macroApiData = Uri.parse('package:macro_api_test/api_test_data.dart');

  Future<void> check(Uri uri, String name, {bool expectThrows: false}) async {
    if (expectThrows) {
      await throws(() async {
        await identifierResolver.resolveIdentifier(uri, name);
      }, '$name from $uri');
    } else {
      Identifier result = await identifierResolver.resolveIdentifier(uri, name);
      expect(name, result.name, '$name from $uri');
    }
  }

  await check(dartCore, 'Object');
  await check(dartCore, 'String');
  await check(dartCore, 'override');

  await check(macroApiData, 'Class1');
  await check(macroApiData, 'getter');
  await check(macroApiData, 'setter=');
  await check(macroApiData, 'field');

  await check(macroApiData, 'non-existing', expectThrows: true);
  await check(macroApiData, 'getter=', expectThrows: true);
  await check(macroApiData, 'setter', expectThrows: true);
  await check(macroApiData, 'field=', expectThrows: true);
}

class ClassData {
  final bool isAbstract;
  final bool isExternal;
  final String superclassOf;
  final String? superSuperclassOf;

  const ClassData(
      {this.isAbstract: false,
      this.isExternal: false,
      required this.superclassOf,
      this.superSuperclassOf});
}

class FunctionData {
  final bool isAbstract;
  final bool isExternal;
  final bool isOperator;
  final bool isGetter;
  final bool isSetter;
  final TypeData returnType;
  final List<ParameterData> positionalParameters;
  final List<ParameterData> namedParameters;

  const FunctionData(
      {this.isAbstract: false,
      this.isExternal: false,
      this.isOperator: false,
      this.isGetter: false,
      this.isSetter: false,
      required this.returnType,
      this.positionalParameters: const [],
      this.namedParameters: const []});
}

class TypeData {
  final bool isNullable;

  const TypeData({this.isNullable: false});
}

class NamedTypeData extends TypeData {
  final String? name;
  final List<TypeData>? typeArguments;

  const NamedTypeData({bool isNullable: false, this.name, this.typeArguments})
      : super(isNullable: isNullable);
}

class ParameterData {
  final String name;
  final TypeData type;
  final bool isRequired;
  final bool isNamed;

  const ParameterData(this.name,
      {required this.type, this.isNamed: false, this.isRequired: false});
}
