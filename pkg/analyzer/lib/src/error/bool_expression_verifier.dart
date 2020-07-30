// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/nullable_dereference_verifier.dart';
import 'package:meta/meta.dart';

/// Helper for verifying expression that should be of type bool.
class BoolExpressionVerifier {
  final TypeSystemImpl _typeSystem;
  final ErrorReporter _errorReporter;
  final NullableDereferenceVerifier _nullableDereferenceVerifier;

  final ClassElement _boolElement;
  final InterfaceType _boolType;

  BoolExpressionVerifier({
    @required TypeSystemImpl typeSystem,
    @required ErrorReporter errorReporter,
    @required NullableDereferenceVerifier nullableDereferenceVerifier,
  })  : _typeSystem = typeSystem,
        _errorReporter = errorReporter,
        _nullableDereferenceVerifier = nullableDereferenceVerifier,
        _boolElement = typeSystem.typeProvider.boolElement,
        _boolType = typeSystem.typeProvider.boolType;

  /// Check to ensure that the [condition] is of type bool, are. Otherwise an
  /// error is reported on the expression.
  ///
  /// See [CompileTimeErrorCode.NON_BOOL_CONDITION].
  void checkForNonBoolCondition(Expression condition) {
    checkForNonBoolExpression(
      condition,
      errorCode: CompileTimeErrorCode.NON_BOOL_CONDITION,
    );
  }

  /// Verify that the given [expression] is of type 'bool', and report
  /// [errorCode] if not, or a nullability error if its improperly nullable.
  void checkForNonBoolExpression(Expression expression,
      {@required ErrorCode errorCode, List<Object> arguments}) {
    var type = expression.staticType;
    if (!_checkForUseOfVoidResult(expression) &&
        !_typeSystem.isAssignableTo2(type, _boolType)) {
      if (type.element == _boolElement) {
        _nullableDereferenceVerifier.report(expression, type);
      } else {
        _errorReporter.reportErrorForNode(errorCode, expression, arguments);
      }
    }
  }

  /// Checks to ensure that the given [expression] is assignable to bool.
  void checkForNonBoolNegationExpression(Expression expression) {
    checkForNonBoolExpression(
      expression,
      errorCode: CompileTimeErrorCode.NON_BOOL_NEGATION_EXPRESSION,
    );
  }

  /// Check for situations where the result of a method or function is used,
  /// when it returns 'void'. Or, in rare cases, when other types of expressions
  /// are void, such as identifiers.
  // TODO(scheglov) Move this in a separate verifier.
  bool _checkForUseOfVoidResult(Expression expression) {
    if (expression == null ||
        !identical(expression.staticType, VoidTypeImpl.instance)) {
      return false;
    }

    if (expression is MethodInvocation) {
      SimpleIdentifier methodName = expression.methodName;
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.USE_OF_VOID_RESULT,
        methodName,
      );
    } else {
      _errorReporter.reportErrorForNode(
        CompileTimeErrorCode.USE_OF_VOID_RESULT,
        expression,
      );
    }

    return true;
  }
}
