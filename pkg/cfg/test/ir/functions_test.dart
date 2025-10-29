// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/global_context.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/types.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/type_environment.dart';
import 'package:test/test.dart';
import '../test_helpers.dart';

void main() {
  final component = readVmPlatformKernelFile();
  final coreTypes = CoreTypes(component);
  final classHierarchy = ClassHierarchy(component, coreTypes);
  final typeEnvironment = TypeEnvironment(coreTypes, classHierarchy);
  final globalContext = GlobalContext(typeEnvironment: typeEnvironment);
  late FunctionRegistry functionRegistry;

  setUp(() {
    GlobalContext.setCurrentContext(globalContext);
    functionRegistry = FunctionRegistry();
  });

  tearDown(() {
    GlobalContext.setCurrentContext(null);
  });

  test('getter', () {
    final member = coreTypes.iteratorGetCurrent;
    final func =
        functionRegistry.getFunction(member, isGetter: true) as GetterFunction;
    expect(func.member, same(member));
    expect(func.hasReceiverParameter, isTrue);
    expect(func.hasClosureParameter, isFalse);
    expect(func.hasClassTypeParameters, isTrue);
    expect(func.hasFunctionTypeParameters, isFalse);
    final returnType = func.returnType;
    expect(returnType is StaticType, isTrue);
    expect(returnType.dartType, equals(member.getterType));
    expect(functionRegistry.getFunction(member, isGetter: true), same(func));
  });

  test('setter', () {
    final member = coreTypes.index.getMember('dart:core', 'List', 'set:length');
    final func =
        functionRegistry.getFunction(member, isSetter: true) as SetterFunction;
    expect(func.member, same(member));
    expect(func.hasReceiverParameter, isTrue);
    expect(func.hasClosureParameter, isFalse);
    expect(func.hasClassTypeParameters, isTrue);
    expect(func.hasFunctionTypeParameters, isFalse);
    final returnType = func.returnType;
    expect(returnType is TopType, isTrue);
    expect(returnType.dartType, equals(ast.VoidType()));
    expect(func.valueType, equals(const IntType()));
    expect(functionRegistry.getFunction(member, isSetter: true), same(func));
  });

  test('field getter', () {
    final member = coreTypes.pragmaName;
    final func =
        functionRegistry.getFunction(member, isGetter: true) as GetterFunction;
    expect(func.member, same(member));
    expect(func.hasReceiverParameter, isTrue);
    expect(func.hasClosureParameter, isFalse);
    expect(func.hasClassTypeParameters, isFalse);
    expect(func.hasFunctionTypeParameters, isFalse);
    expect(func.returnType, equals(StringType()));
    expect(functionRegistry.getFunction(member, isGetter: true), same(func));
  });

  test('field initializer', () {
    final member = coreTypes.index.getField('dart:core', 'double', 'nan');
    final func =
        functionRegistry.getFunction(member, isInitializer: true)
            as FieldInitializerFunction;
    expect(func.member, same(member));
    expect(func.hasReceiverParameter, isFalse);
    expect(func.hasClosureParameter, isFalse);
    expect(func.hasClassTypeParameters, isFalse);
    expect(func.hasFunctionTypeParameters, isFalse);
    expect(func.returnType, equals(DoubleType()));
    expect(
      functionRegistry.getFunction(member, isInitializer: true),
      same(func),
    );
    expect(
      functionRegistry.getFunction(member, isGetter: true),
      isNot(same(func)),
    );
  });

  test('regular', () {
    final member = coreTypes.index.getProcedure('dart:core', 'List', 'filled');
    final func = functionRegistry.getFunction(member) as RegularFunction;
    expect(func.member, same(member));
    expect(func.hasReceiverParameter, isFalse);
    expect(func.hasClosureParameter, isFalse);
    expect(func.hasClassTypeParameters, isFalse);
    expect(func.hasFunctionTypeParameters, isTrue);
    final returnType = func.returnType;
    expect(returnType is StaticType, isTrue);
    expect(returnType.dartType, equals(member.function.returnType));
    expect(functionRegistry.getFunction(member), same(func));
  });

  test('constructor', () {
    final member = coreTypes.index.getConstructor('dart:core', 'Object', '');
    final func = functionRegistry.getFunction(member) as GenerativeConstructor;
    expect(func.member, same(member));
    expect(func.hasReceiverParameter, isTrue);
    expect(func.hasClosureParameter, isFalse);
    expect(func.hasClassTypeParameters, isFalse);
    expect(func.hasFunctionTypeParameters, isFalse);
    final returnType = func.returnType;
    expect(returnType is TopType, isTrue);
    expect(returnType.dartType, equals(ast.VoidType()));
    expect(functionRegistry.getFunction(member), same(func));
  });

  test('tear-off', () {
    final member = coreTypes.index.getProcedure('dart:core', 'List', 'empty');
    final func =
        functionRegistry.getFunction(member, isTearOff: true)
            as TearOffFunction;
    expect(func.member, same(member));
    expect(func.hasReceiverParameter, isFalse);
    expect(func.hasClosureParameter, isTrue);
    expect(func.hasClassTypeParameters, isFalse);
    expect(func.hasFunctionTypeParameters, isTrue);
    final returnType = func.returnType;
    expect(returnType is StaticType, isTrue);
    expect(returnType.dartType, equals(member.function.returnType));
    expect(functionRegistry.getFunction(member, isTearOff: true), same(func));
    expect(functionRegistry.getFunction(member), isNot(same(func)));
  });

  test('local function', () {
    final member = coreTypes.futureValueFactory;
    final localFunction = ast.FunctionDeclaration(
      ast.VariableDeclaration('foo'),
      ast.FunctionNode(
        ast.Block([]),
        returnType: coreTypes.boolNonNullableRawType,
      ),
    );
    final func =
        functionRegistry.getFunction(member, localFunction: localFunction)
            as LocalFunction;
    expect(func.member, same(member));
    expect(func.localFunction, same(localFunction));
    expect(func.hasReceiverParameter, isFalse);
    expect(func.hasClosureParameter, isTrue);
    expect(func.hasClassTypeParameters, isFalse);
    expect(func.hasFunctionTypeParameters, isFalse);
    expect(func.returnType, equals(BoolType()));
    expect(
      functionRegistry.getFunction(member, localFunction: localFunction),
      same(func),
    );
  });
}
