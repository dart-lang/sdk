// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/nullable_dereference_verifier.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for verifying expression that should be of type bool.
class BoolExpressionVerifier {
  final ResolverVisitor _resolver;
  final DiagnosticReporter _diagnosticReporter;
  final NullableDereferenceVerifier _nullableDereferenceVerifier;

  final InterfaceTypeImpl _boolType;

  BoolExpressionVerifier({
    required ResolverVisitor resolver,
    required DiagnosticReporter diagnosticReporter,
    required NullableDereferenceVerifier nullableDereferenceVerifier,
  }) : _resolver = resolver,
       _diagnosticReporter = diagnosticReporter,
       _nullableDereferenceVerifier = nullableDereferenceVerifier,
       _boolType = resolver.typeSystem.typeProvider.boolType;

  /// Check to ensure that the [condition] is of type bool, are. Otherwise an
  /// error is reported on the expression.
  ///
  /// See [CompileTimeErrorCode.nonBoolCondition].
  void checkForNonBoolCondition(
    Expression condition, {
    required Map<SharedTypeView, NonPromotionReason> Function()? whyNotPromoted,
  }) {
    checkForNonBoolExpression(
      condition,
      diagnosticCode: CompileTimeErrorCode.nonBoolCondition,
      whyNotPromoted: whyNotPromoted,
    );
  }

  /// Verify that the given [expression] is of type 'bool', and report
  /// [diagnosticCode] if not, or a nullability error if its improperly
  /// nullable.
  void checkForNonBoolExpression(
    Expression expression, {
    required DiagnosticCode diagnosticCode,
    List<Object> arguments = const [],
    required Map<SharedTypeView, NonPromotionReason> Function()? whyNotPromoted,
  }) {
    var type = expression.typeOrThrow;
    if (!_checkForUseOfVoidResult(expression) &&
        !_resolver.typeSystem.isAssignableTo(
          type,
          _boolType,
          strictCasts: _resolver.analysisOptions.strictCasts,
        )) {
      if (type.isDartCoreBool) {
        _nullableDereferenceVerifier.report(
          CompileTimeErrorCode.uncheckedUseOfNullableValueAsCondition,
          expression,
          type,
          messages: _resolver.computeWhyNotPromotedMessages(
            expression,
            whyNotPromoted?.call(),
          ),
        );
      } else {
        _diagnosticReporter.atNode(
          expression,
          diagnosticCode,
          arguments: arguments,
        );
      }
    }
  }

  /// Checks to ensure that the given [expression] is assignable to bool.
  void checkForNonBoolNegationExpression(
    Expression expression, {
    required Map<SharedTypeView, NonPromotionReason> Function()? whyNotPromoted,
  }) {
    checkForNonBoolExpression(
      expression,
      diagnosticCode: CompileTimeErrorCode.nonBoolNegationExpression,
      whyNotPromoted: whyNotPromoted,
    );
  }

  /// Check for situations where the result of a method or function is used,
  /// when it returns 'void'. Or, in rare cases, when other types of expressions
  /// are void, such as identifiers.
  // TODO(scheglov): Move this in a separate verifier.
  bool _checkForUseOfVoidResult(Expression expression) {
    if (!identical(expression.staticType, VoidTypeImpl.instance)) {
      return false;
    }

    if (expression is MethodInvocation) {
      SimpleIdentifier methodName = expression.methodName;
      _diagnosticReporter.atNode(
        methodName,
        CompileTimeErrorCode.useOfVoidResult,
      );
    } else {
      _diagnosticReporter.atNode(
        expression,
        CompileTimeErrorCode.useOfVoidResult,
      );
    }

    return true;
  }
}
