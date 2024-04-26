// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/type_algebra.dart' show Substitution;
import 'package:kernel/type_environment.dart' show StaticTypeContext;

class ForInVariables {
  static const stream = ':stream';
  static const forIterator = ':for-iterator';
  static const syncForIterator = ':sync-for-iterator';
}

/// VM-specific desugaring of for-in loops.
class ForInLowering {
  final CoreTypes coreTypes;
  final bool productMode;

  ForInLowering(this.coreTypes, {required this.productMode});

  Statement transformForInStatement(ForInStatement stmt,
      FunctionNode? enclosingFunction, StaticTypeContext staticTypeContext) {
    if (stmt.isAsync) {
      if (enclosingFunction == null ||
          (enclosingFunction.asyncMarker != AsyncMarker.Async &&
              enclosingFunction.asyncMarker != AsyncMarker.AsyncStar)) {
        return stmt;
      }
      // Transform
      //
      //   await for (T variable in <stream-expression>) { ... }
      //
      // To (in product mode):
      //
      //   {
      //     :stream = <stream-expression>;
      //     _StreamIterator<T> :for-iterator = new _StreamIterator<T>(:stream);
      //     try {
      //       while (await :for-iterator.moveNext()) {
      //         T <variable> = :for-iterator.current;
      //         ...
      //       }
      //     } finally {
      //       if (:for-iterator._subscription != null)
      //           await :for-iterator.cancel();
      //     }
      //   }
      //
      // Or (in non-product mode):
      //
      //   {
      //     :stream = <stream-expression>;
      //     _StreamIterator<T> :for-iterator = new _StreamIterator<T>(:stream);
      //     try {
      //       while (let _ = _asyncStarMoveNextHelper(:stream) in
      //           await :for-iterator.moveNext()) {
      //         T <variable> = :for-iterator.current;
      //         ...
      //       }
      //     } finally {
      //       if (:for-iterator._subscription != null)
      //           await :for-iterator.cancel();
      //     }
      //   }
      final valueVariable = stmt.variable;

      final streamVariable = new VariableDeclaration(ForInVariables.stream,
          initializer: stmt.iterable,
          type: stmt.iterable.getStaticType(staticTypeContext),
          isSynthesized: true);

      final streamIteratorType = new InterfaceType(
          coreTypes.streamIteratorClass,
          staticTypeContext.nullable,
          [valueVariable.type]);
      final forIteratorVariable = VariableDeclaration(
          ForInVariables.forIterator,
          initializer: new ConstructorInvocation(
              coreTypes.streamIteratorDefaultConstructor,
              new Arguments(<Expression>[new VariableGet(streamVariable)],
                  types: [valueVariable.type])),
          type: streamIteratorType,
          isSynthesized: true);

      // await :for-iterator.moveNext()
      final condition = new AwaitExpression(new InstanceInvocation(
          InstanceAccessKind.Instance,
          VariableGet(forIteratorVariable),
          coreTypes.streamIteratorMoveNext.name,
          new Arguments([]),
          interfaceTarget: coreTypes.streamIteratorMoveNext,
          functionType:
              coreTypes.streamIteratorMoveNext.getterType as FunctionType))
        ..fileOffset = stmt.fileOffset;

      Expression whileCondition;
      if (productMode) {
        whileCondition = condition;
      } else {
        // _asyncStarMoveNextHelper(:stream)
        final asyncStarMoveNextCall = new StaticInvocation(
            coreTypes.asyncStarMoveNextHelper,
            new Arguments([new VariableGet(streamVariable)]))
          ..fileOffset = stmt.fileOffset;

        // let _ = asyncStarMoveNextCall in (condition)
        whileCondition = new Let(
            new VariableDeclaration(null,
                initializer: asyncStarMoveNextCall, isSynthesized: true),
            condition);
      }

      // T <variable> = :for-iterator.current;
      valueVariable.initializer = new InstanceGet(
          InstanceAccessKind.Instance,
          VariableGet(forIteratorVariable),
          coreTypes.streamIteratorCurrent.name,
          interfaceTarget: coreTypes.streamIteratorCurrent,
          resultType: valueVariable.type)
        ..fileOffset = stmt.bodyOffset;
      valueVariable.initializer!.parent = valueVariable;

      final whileBody = new Block(<Statement>[valueVariable, stmt.body]);
      final tryBody = new WhileStatement(whileCondition, whileBody);

      // if (:for-iterator._subscription != null) await :for-iterator.cancel();
      final DartType subscriptionType =
          Substitution.fromInterfaceType(streamIteratorType)
              .substituteType(coreTypes.streamIteratorSubscription.getterType);
      final tryFinalizer = new IfStatement(
          new Not(new EqualsNull(new InstanceGet(
              InstanceAccessKind.Instance,
              VariableGet(forIteratorVariable),
              coreTypes.streamIteratorSubscription.name,
              interfaceTarget: coreTypes.streamIteratorSubscription,
              resultType: subscriptionType))),
          new ExpressionStatement(new AwaitExpression(new InstanceInvocation(
              InstanceAccessKind.Instance,
              VariableGet(forIteratorVariable),
              coreTypes.streamIteratorCancel.name,
              new Arguments(<Expression>[]),
              interfaceTarget: coreTypes.streamIteratorCancel,
              functionType:
                  coreTypes.streamIteratorCancel.getterType as FunctionType))),
          null);

      final tryFinally = new TryFinally(tryBody, tryFinalizer);

      final block = new Block(
          <Statement>[streamVariable, forIteratorVariable, tryFinally]);
      return block;
    }

    // Transform
    //
    //   for ({var/final} T <variable> in <iterable>) { ... }
    //
    // Into
    //
    //  {
    //    final Iterator<T> :sync-for-iterator = <iterable>.iterator;
    //    for (; :sync-for-iterator.moveNext() ;) {
    //        {var/final} T variable = :sync-for-iterator.current;
    //        ...
    //      }
    //    }
    //  }

    // The CFE might invoke this transformation despite the program having
    // compile-time errors. So we will not transform this [stmt] if the
    // `stmt.iterable` is an invalid expression or has an invalid type and
    // instead eliminate the entire for-in and replace it with a invalid
    // expression statement.
    final iterable = stmt.iterable;
    final iterableType = iterable.getStaticType(staticTypeContext);
    if (iterableType is InvalidType) {
      return ExpressionStatement(
          InvalidExpression('Invalid iterable type in for-in'));
    }

    assert(coreTypes.iterableGetIterator.function.returnType.nullability ==
        Nullability.nonNullable);

    final DartType elementType = stmt.getElementType(staticTypeContext);
    final iteratorType = InterfaceType(
        coreTypes.iteratorClass, staticTypeContext.nonNullable, [elementType]);

    final syncForIterator = VariableDeclaration(ForInVariables.syncForIterator,
        initializer: InstanceGet(InstanceAccessKind.Instance, iterable,
            coreTypes.iterableGetIterator.name,
            interfaceTarget: coreTypes.iterableGetIterator,
            resultType: iteratorType)
          ..fileOffset = iterable.fileOffset,
        type: iteratorType,
        isSynthesized: true)
      ..fileOffset = iterable.fileOffset;

    final condition = InstanceInvocation(
        InstanceAccessKind.Instance,
        VariableGet(syncForIterator),
        coreTypes.iteratorMoveNext.name,
        Arguments([]),
        interfaceTarget: coreTypes.iteratorMoveNext,
        functionType: coreTypes.iteratorMoveNext.getterType as FunctionType)
      ..fileOffset = iterable.fileOffset;

    final variable = stmt.variable
      ..initializer = (InstanceGet(InstanceAccessKind.Instance,
          VariableGet(syncForIterator), coreTypes.iteratorGetCurrent.name,
          interfaceTarget: coreTypes.iteratorGetCurrent,
          resultType: elementType)
        ..fileOffset = stmt.bodyOffset);
    variable.initializer!.parent = variable;

    final Block body = Block([variable, stmt.body])
      ..fileOffset = stmt.bodyOffset;

    return Block([syncForIterator, ForStatement([], condition, [], body)]);
  }
}
