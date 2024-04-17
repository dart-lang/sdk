// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.g.dart';

/// Verifies usages of `Future.value` and `Completer.complete` when null-safety
/// is enabled.
///
/// `Future.value` and `Completer.complete` both accept a `FutureOr<T>?` as an
/// optional argument but throw an exception when `T` is non-nullable and `null`
/// is passed as an argument.
///
/// This verifier detects and reports those scenarios.
class NullSafeApiVerifier {
  final ErrorReporter _errorReporter;
  final TypeSystemImpl _typeSystem;

  NullSafeApiVerifier(this._errorReporter, this._typeSystem);

  /// Reports an error if the expression creates a `Future<T>.value` with a non-
  /// nullable value `T` and an argument that is effectively `null`.
  void instanceCreation(InstanceCreationExpression expression) {
    var constructor = expression.constructorName.staticElement;
    if (constructor == null) return;

    var type = constructor.returnType;
    var isFutureValue = type.isDartAsyncFuture && constructor.name == 'value';

    if (isFutureValue) {
      _checkTypes(expression, 'Future.value', type.typeArguments.single,
          expression.argumentList);
    }
  }

  /// Reports an error if `Completer<T>.complete` is invoked with a non-nullable
  /// `T` and an argument that is effectively `null`.
  void methodInvocation(MethodInvocation node) {
    var targetType = node.realTarget?.staticType;
    if (targetType is! InterfaceType) return;

    var targetClass = targetType.element;

    if (targetClass.library.isDartAsync == true &&
        targetClass.name == 'Completer' &&
        node.methodName.name == 'complete') {
      _checkTypes(node, 'Completer.complete', targetType.typeArguments.single,
          node.argumentList);
    }
  }

  void _checkTypes(
      Expression node, String memberName, DartType type, ArgumentList args) {
    // If there's more than one argument, something else is wrong (and will
    // generate another diagnostic). Also, only check the argument type if we
    // expect a non-nullable type in the first place.
    if (args.arguments.length > 1 || !_typeSystem.isNonNullable(type)) return;

    var argument = args.arguments.isEmpty ? null : args.arguments.single;
    var argumentType = argument?.staticType;
    // Skip if the type is not currently resolved.
    if (argument != null && argumentType == null) return;

    var argumentIsNull = argument == null || _typeSystem.isNull(argumentType!);

    if (argumentIsNull) {
      _errorReporter.atNode(
        argument ?? node,
        WarningCode.NULL_ARGUMENT_TO_NON_NULL_TYPE,
        arguments: [memberName, type.getDisplayString()],
      );
    }
  }
}
