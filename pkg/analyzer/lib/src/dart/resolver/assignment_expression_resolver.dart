// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [AssignmentExpression]s.
class AssignmentExpressionResolver {
  final ResolverVisitor _resolver;
  final TypePropertyResolver _typePropertyResolver;
  final InvocationInferenceHelper _inferenceHelper;
  final AssignmentExpressionShared _assignmentShared;

  AssignmentExpressionResolver({
    required ResolverVisitor resolver,
  })  : _resolver = resolver,
        _typePropertyResolver = resolver.typePropertyResolver,
        _inferenceHelper = resolver.inferenceHelper,
        _assignmentShared = AssignmentExpressionShared(
          resolver: resolver,
        );

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  bool get _isNonNullableByDefault => _typeSystem.isNonNullableByDefault;

  TypeProvider get _typeProvider => _resolver.typeProvider;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(
    AssignmentExpressionImpl node, {
    required DartType? contextType,
  }) {
    var operator = node.operator.type;
    var hasRead = operator != TokenType.EQ;
    var isIfNull = operator == TokenType.QUESTION_QUESTION_EQ;

    var leftResolution = _resolver.resolveForWrite(
      node: node.leftHandSide,
      hasRead: hasRead,
    );

    var left = node.leftHandSide;
    var right = node.rightHandSide;

    var readElement = leftResolution.readElement;
    var writeElement = leftResolution.writeElement;

    if (hasRead) {
      _resolver.setReadElement(left, readElement);
      {
        final recordField = leftResolution.recordField;
        if (recordField != null) {
          node.readType = recordField.type;
        }
      }
      _resolveOperator(node);
    }
    _resolver.setWriteElement(left, writeElement);
    _resolver.migrationResolutionHooks
        ?.setCompoundAssignmentExpressionTypes(node);

    // TODO(scheglov) Use VariableElement and do in resolveForWrite() ?
    _assignmentShared.checkFinalAlreadyAssigned(left);

    DartType? rhsContext;
    {
      var leftType = node.writeType;
      if (writeElement is VariableElement) {
        leftType = _resolver.localVariableTypeProvider
            .getType(left as SimpleIdentifier, isRead: false);
      }
      rhsContext = _computeRhsContext(node, leftType!, operator, right);
    }

    var flow = _resolver.flowAnalysis.flow;
    if (flow != null && isIfNull) {
      flow.ifNullExpression_rightBegin(left, node.readType!);
    }

    _resolver.analyzeExpression(right, rhsContext);
    right = _resolver.popRewrite()!;
    var whyNotPromoted = flow?.whyNotPromoted(right);

    _resolveTypes(node,
        whyNotPromoted: whyNotPromoted, contextType: contextType);

    if (flow != null) {
      if (writeElement is PromotableElement) {
        flow.write(
            node, writeElement, node.typeOrThrow, hasRead ? null : right);
      }
      if (isIfNull) {
        flow.ifNullExpression_end();
      }
    }

    _resolver.nullShortingTermination(node);
  }

  void _checkForInvalidAssignment(
    DartType writeType,
    Expression right,
    DartType rightType, {
    required Map<DartType, NonPromotionReason> Function()? whyNotPromoted,
  }) {
    if (writeType is! VoidType && _checkForUseOfVoidResult(right)) {
      return;
    }

    if (_typeSystem.isAssignableTo(rightType, writeType)) {
      return;
    }

    if (writeType is RecordType) {
      if (rightType is! RecordType && writeType.positionalFields.length == 1) {
        var field = writeType.positionalFields.first;
        if (_typeSystem.isAssignableTo(field.type, rightType)) {
          _errorReporter.reportErrorForNode(
            WarningCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA,
            right,
            [],
          );
          return;
        }
      }
    }

    _errorReporter.reportErrorForNode(
      CompileTimeErrorCode.INVALID_ASSIGNMENT,
      right,
      [rightType, writeType],
      _resolver.computeWhyNotPromotedMessages(right, whyNotPromoted?.call()),
    );
  }

  /// Check for situations where the result of a method or function is used,
  /// when it returns 'void'. Or, in rare cases, when other types of expressions
  /// are void, such as identifiers.
  ///
  /// See [CompileTimeErrorCode.USE_OF_VOID_RESULT].
  /// TODO(scheglov) this is duplicate
  bool _checkForUseOfVoidResult(Expression expression) {
    if (!identical(expression.staticType, VoidTypeImpl.instance)) {
      return false;
    }

    if (expression is MethodInvocation) {
      SimpleIdentifier methodName = expression.methodName;
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.USE_OF_VOID_RESULT, methodName, []);
    } else {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.USE_OF_VOID_RESULT, expression, []);
    }

    return true;
  }

  DartType? _computeRhsContext(AssignmentExpressionImpl node, DartType leftType,
      TokenType operator, Expression right) {
    switch (operator) {
      case TokenType.EQ:
      case TokenType.QUESTION_QUESTION_EQ:
        return leftType;
      case TokenType.AMPERSAND_AMPERSAND_EQ:
      case TokenType.BAR_BAR_EQ:
        return _typeProvider.boolType;
      default:
        var method = node.staticElement;
        if (method != null) {
          var parameters = method.parameters;
          if (parameters.isNotEmpty) {
            return _typeSystem.refineNumericInvocationContext(
                leftType, method, leftType, parameters[0].type);
          }
        }
        return null;
    }
  }

  void _resolveOperator(AssignmentExpressionImpl node) {
    var left = node.leftHandSide;
    var operator = node.operator;
    var operatorType = operator.type;

    var leftType = node.readType!;
    if (identical(leftType, NeverTypeImpl.instance)) {
      return;
    }

    // Values of the type void cannot be used.
    // Example: `y += 0`, is not allowed.
    if (operatorType != TokenType.EQ) {
      if (leftType is VoidType) {
        _errorReporter.reportErrorForToken(
          CompileTimeErrorCode.USE_OF_VOID_RESULT,
          operator,
        );
        return;
      }
    }

    if (operatorType == TokenType.AMPERSAND_AMPERSAND_EQ ||
        operatorType == TokenType.BAR_BAR_EQ ||
        operatorType == TokenType.EQ ||
        operatorType == TokenType.QUESTION_QUESTION_EQ) {
      return;
    }

    var binaryOperatorType = operatorType.binaryOperatorOfCompoundAssignment;
    if (binaryOperatorType == null) {
      return;
    }
    var methodName = binaryOperatorType.lexeme;

    var result = _typePropertyResolver.resolve(
      receiver: left,
      receiverType: leftType,
      name: methodName,
      propertyErrorEntity: operator,
      nameErrorEntity: operator,
    );
    node.staticElement = result.getter as MethodElement?;
    if (result.needsGetterError) {
      _errorReporter.reportErrorForToken(
        CompileTimeErrorCode.UNDEFINED_OPERATOR,
        operator,
        [methodName, leftType],
      );
    }
  }

  void _resolveTypes(AssignmentExpressionImpl node,
      {required Map<DartType, NonPromotionReason> Function()? whyNotPromoted,
      required DartType? contextType}) {
    DartType assignedType;

    var rightHandSide = node.rightHandSide;
    var operator = node.operator.type;
    if (operator == TokenType.EQ) {
      assignedType = rightHandSide.typeOrThrow;
    } else if (operator == TokenType.QUESTION_QUESTION_EQ) {
      assignedType = rightHandSide.typeOrThrow;
    } else if (operator == TokenType.AMPERSAND_AMPERSAND_EQ ||
        operator == TokenType.BAR_BAR_EQ) {
      assignedType = _typeProvider.boolType;
    } else {
      var operatorElement = node.staticElement;
      if (operatorElement != null) {
        var leftType = node.readType!;
        var rightType = rightHandSide.typeOrThrow;
        assignedType = _typeSystem.refineBinaryExpressionType(
          leftType,
          operator,
          rightType,
          operatorElement.returnType,
          operatorElement,
        );
      } else {
        assignedType = DynamicTypeImpl.instance;
      }
    }

    DartType nodeType;
    if (operator == TokenType.QUESTION_QUESTION_EQ) {
      var leftType = node.readType!;

      // The LHS value will be used only if it is non-null.
      if (_isNonNullableByDefault) {
        leftType = _typeSystem.promoteToNonNull(leftType);
      }

      nodeType = _typeSystem.getLeastUpperBound(leftType, assignedType);
    } else {
      nodeType = assignedType;
    }
    _inferenceHelper.recordStaticType(node, nodeType, contextType: contextType);

    // TODO(scheglov) Remove from ErrorVerifier?
    _checkForInvalidAssignment(
      node.writeType!,
      node.rightHandSide,
      assignedType,
      whyNotPromoted: operator == TokenType.EQ ? whyNotPromoted : null,
    );
    if (operator != TokenType.EQ &&
        operator != TokenType.QUESTION_QUESTION_EQ) {
      _resolver.checkForArgumentTypeNotAssignableForArgument(node.rightHandSide,
          whyNotPromoted: whyNotPromoted);
    }
  }
}

class AssignmentExpressionShared {
  final ResolverVisitor _resolver;

  AssignmentExpressionShared({
    required ResolverVisitor resolver,
  }) : _resolver = resolver;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  void checkFinalAlreadyAssigned(Expression left,
      {bool isForEachIdentifier = false}) {
    var flowAnalysis = _resolver.flowAnalysis;

    var flow = flowAnalysis.flow;
    if (flow == null) return;

    if (left is SimpleIdentifier) {
      var element = left.staticElement;
      if (element is PromotableElement) {
        var assigned = flowAnalysis.isDefinitelyAssigned(left, element);
        var unassigned = flowAnalysis.isDefinitelyUnassigned(left, element);

        if (element.isFinal) {
          if (element.isLate) {
            if (isForEachIdentifier || assigned) {
              _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.LATE_FINAL_LOCAL_ALREADY_ASSIGNED,
                left,
              );
            }
          } else {
            if (isForEachIdentifier || !unassigned) {
              _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL,
                left,
                [element.name],
              );
            }
          }
        }
      }
    }
  }
}
