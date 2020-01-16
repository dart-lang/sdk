// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:meta/meta.dart';

/// Helper for verifying expression that should be of type bool.
class BoolExpressionVerifier {
  final TypeSystemImpl _typeSystem;
  final ErrorReporter _errorReporter;

  final ClassElement _boolElement;
  final InterfaceType _boolType;

  BoolExpressionVerifier({
    @required TypeSystemImpl typeSystem,
    @required ErrorReporter errorReporter,
  })  : _typeSystem = typeSystem,
        _errorReporter = errorReporter,
        _boolElement = typeSystem.typeProvider.boolElement,
        _boolType = typeSystem.typeProvider.boolType;

  /// Check to ensure that the [condition] is of type bool, are. Otherwise an
  /// error is reported on the expression.
  ///
  /// See [StaticTypeWarningCode.NON_BOOL_CONDITION].
  void checkForNonBoolCondition(Expression condition) {
    checkForNonBoolExpression(
      condition,
      errorCode: StaticTypeWarningCode.NON_BOOL_CONDITION,
    );
  }

  /// Verify that the given [expression] is of type 'bool', and report
  /// [errorCode] if not, or a nullability error if its improperly nullable.
  void checkForNonBoolExpression(Expression expression,
      {@required ErrorCode errorCode}) {
    var type = expression.staticType;
    if (!_checkForUseOfVoidResult(expression) &&
        !_typeSystem.isAssignableTo(type, _boolType)) {
      if (type.element == _boolElement) {
        _errorReporter.reportErrorForNode(
          StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE,
          expression,
        );
      } else {
        _errorReporter.reportErrorForNode(errorCode, expression);
      }
    }
  }

  /// Checks to ensure that the given [expression] is assignable to bool.
  void checkForNonBoolNegationExpression(Expression expression) {
    checkForNonBoolExpression(
      expression,
      errorCode: StaticTypeWarningCode.NON_BOOL_NEGATION_EXPRESSION,
    );
  }

  /**
   * Check for situations where the result of a method or function is used, when
   * it returns 'void'. Or, in rare cases, when other types of expressions are
   * void, such as identifiers.
   *
   * TODO(scheglov) Move this in a separate verifier.
   */
  bool _checkForUseOfVoidResult(Expression expression) {
    if (expression == null ||
        !identical(expression.staticType, VoidTypeImpl.instance)) {
      return false;
    }

    if (expression is MethodInvocation) {
      SimpleIdentifier methodName = expression.methodName;
      _errorReporter.reportErrorForNode(
        StaticWarningCode.USE_OF_VOID_RESULT,
        methodName,
      );
    } else {
      _errorReporter.reportErrorForNode(
        StaticWarningCode.USE_OF_VOID_RESULT,
        expression,
      );
    }

    return true;
  }
}
