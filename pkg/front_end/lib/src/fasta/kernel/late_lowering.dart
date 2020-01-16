// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/core_types.dart';

import '../names.dart';

Statement createGetterWithInitializer(
    int fileOffset, String name, DartType type, Expression initializer,
    {Expression createVariableRead({bool needsPromotion}),
    Expression createVariableWrite(Expression value),
    Expression createIsSetRead(),
    Expression createIsSetWrite(Expression value)}) {
  if (type.isPotentiallyNullable) {
    // Generate:
    //
    //    if (!_#isSet#field) {
    //      _#isSet#field = true
    //      _#field = <init>;
    //    }
    //    return _#field;
    return new Block(<Statement>[
      new IfStatement(
          new Not(createIsSetRead()..fileOffset = fileOffset)
            ..fileOffset = fileOffset,
          new Block(<Statement>[
            new ExpressionStatement(
                createIsSetWrite(new BoolLiteral(true)..fileOffset = fileOffset)
                  ..fileOffset = fileOffset)
              ..fileOffset = fileOffset,
            new ExpressionStatement(
                createVariableWrite(initializer)..fileOffset = fileOffset)
              ..fileOffset = fileOffset,
          ]),
          null)
        ..fileOffset = fileOffset,
      new ReturnStatement(
          // If [type] is a type variable with undetermined nullability we need
          // to create a read of the field that is promoted to the type variable
          // type.
          createVariableRead(needsPromotion: type.isPotentiallyNonNullable))
        ..fileOffset = fileOffset
    ])
      ..fileOffset = fileOffset;
  } else {
    // Generate:
    //
    //    return let # = _#field in # == null ? _#field = <init> : #;
    VariableDeclaration variable = new VariableDeclaration.forValue(
        createVariableRead(needsPromotion: false)..fileOffset = fileOffset,
        type: type.withNullability(Nullability.nullable))
      ..fileOffset = fileOffset;
    return new ReturnStatement(
        new Let(
            variable,
            new ConditionalExpression(
                new MethodInvocation(
                    new VariableGet(variable)..fileOffset = fileOffset,
                    equalsName,
                    new Arguments(<Expression>[
                      new NullLiteral()..fileOffset = fileOffset
                    ])
                      ..fileOffset = fileOffset)
                  ..fileOffset = fileOffset,
                createVariableWrite(initializer)..fileOffset = fileOffset,
                new VariableGet(variable, type)..fileOffset = fileOffset,
                type)
              ..fileOffset = fileOffset)
          ..fileOffset = fileOffset)
      ..fileOffset = fileOffset;
  }
}

Statement createGetterBodyWithoutInitializer(CoreTypes coreTypes,
    int fileOffset, String name, DartType type, String variableKindName,
    {Expression createVariableRead({bool needsPromotion}),
    Expression createIsSetRead()}) {
  Expression exception = new Throw(new ConstructorInvocation(
      coreTypes.lateInitializationErrorConstructor,
      new Arguments(<Expression>[
        new StringLiteral(
            "$variableKindName '${name}' has not been initialized.")
          ..fileOffset = fileOffset
      ])
        ..fileOffset = fileOffset)
    ..fileOffset = fileOffset)
    ..fileOffset = fileOffset;
  if (type.isPotentiallyNullable) {
    // Generate:
    //
    //    return _#isSet#field ? _#field : throw '...';
    return new ReturnStatement(
        new ConditionalExpression(
            createIsSetRead()..fileOffset = fileOffset,
            createVariableRead(needsPromotion: type.isPotentiallyNonNullable)
              ..fileOffset = fileOffset,
            exception,
            type)
          ..fileOffset = fileOffset)
      ..fileOffset = fileOffset;
  } else {
    // Generate:
    //
    //    return let # = _#field in # == null ? throw '...' : #;
    VariableDeclaration variable = new VariableDeclaration.forValue(
        createVariableRead()..fileOffset = fileOffset,
        type: type.withNullability(Nullability.nullable))
      ..fileOffset = fileOffset;
    return new ReturnStatement(
        new Let(
            variable,
            new ConditionalExpression(
                new MethodInvocation(
                    new VariableGet(variable)..fileOffset = fileOffset,
                    equalsName,
                    new Arguments(<Expression>[
                      new NullLiteral()..fileOffset = fileOffset
                    ])
                      ..fileOffset = fileOffset)
                  ..fileOffset = fileOffset,
                exception,
                new VariableGet(variable, type)..fileOffset = fileOffset,
                type)
              ..fileOffset = fileOffset)
          ..fileOffset = fileOffset)
      ..fileOffset = fileOffset;
  }
}

Statement createSetterBody(
    int fileOffset, String name, VariableDeclaration parameter, DartType type,
    {bool shouldReturnValue,
    Expression createVariableWrite(Expression value),
    Expression createIsSetWrite(Expression value)}) {
  Statement createReturn(Expression value) {
    if (shouldReturnValue) {
      return new ReturnStatement(value)..fileOffset = fileOffset;
    } else {
      return new ExpressionStatement(value)..fileOffset = fileOffset;
    }
  }

  Statement assignment = createReturn(
      createVariableWrite(new VariableGet(parameter)..fileOffset = fileOffset)
        ..fileOffset = fileOffset);

  if (type.isPotentiallyNullable) {
    // Generate:
    //
    //    _#isSet#field = true;
    //    return _#field = parameter
    //
    return new Block([
      new ExpressionStatement(
          createIsSetWrite(new BoolLiteral(true)..fileOffset = fileOffset)
            ..fileOffset = fileOffset)
        ..fileOffset = fileOffset,
      assignment
    ])
      ..fileOffset = fileOffset;
  } else {
    // Generate:
    //
    //    return _#field = parameter
    //
    return assignment;
  }
}

Statement createSetterBodyFinal(
    CoreTypes coreTypes,
    int fileOffset,
    String name,
    VariableDeclaration parameter,
    DartType type,
    String variableKindName,
    {bool shouldReturnValue,
    Expression createVariableRead(),
    Expression createVariableWrite(Expression value),
    Expression createIsSetRead(),
    Expression createIsSetWrite(Expression value)}) {
  Expression exception = new Throw(new ConstructorInvocation(
      coreTypes.lateInitializationErrorConstructor,
      new Arguments(<Expression>[
        new StringLiteral(
            "${variableKindName} '${name}' has already been initialized.")
          ..fileOffset = fileOffset
      ])
        ..fileOffset = fileOffset)
    ..fileOffset = fileOffset)
    ..fileOffset = fileOffset;

  Statement createReturn(Expression value) {
    if (shouldReturnValue) {
      return new ReturnStatement(value)..fileOffset = fileOffset;
    } else {
      return new ExpressionStatement(value)..fileOffset = fileOffset;
    }
  }

  if (type.isPotentiallyNullable) {
    // Generate:
    //
    //    if (_#isSet#field) {
    //      throw '...';
    //    } else
    //      _#isSet#field = true;
    //      return _#field = parameter
    //    }
    return new IfStatement(
        createIsSetRead()..fileOffset = fileOffset,
        new ExpressionStatement(exception)..fileOffset = fileOffset,
        new Block([
          new ExpressionStatement(
              createIsSetWrite(new BoolLiteral(true)..fileOffset = fileOffset)
                ..fileOffset = fileOffset)
            ..fileOffset = fileOffset,
          createReturn(createVariableWrite(
              new VariableGet(parameter)..fileOffset = fileOffset)
            ..fileOffset = fileOffset)
        ])
          ..fileOffset = fileOffset)
      ..fileOffset = fileOffset;
  } else {
    // Generate:
    //
    //    if (_#field == null) {
    //      return _#field = parameter;
    //    } else {
    //      throw '...';
    //    }
    return new IfStatement(
      new MethodInvocation(
          createVariableRead()..fileOffset = fileOffset,
          equalsName,
          new Arguments(
              <Expression>[new NullLiteral()..fileOffset = fileOffset])
            ..fileOffset = fileOffset)
        ..fileOffset = fileOffset,
      createReturn(createVariableWrite(
          new VariableGet(parameter)..fileOffset = fileOffset)
        ..fileOffset = fileOffset),
      new ExpressionStatement(exception)..fileOffset = fileOffset,
    )..fileOffset = fileOffset;
  }
}
