// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for resolving [AssignmentExpression]s.
class AssignmentExpressionResolver {
  final ResolverVisitor _resolver;
  final TypePropertyResolver _typePropertyResolver;
  final AssignmentExpressionShared _assignmentShared;

  AssignmentExpressionResolver({
    required ResolverVisitor resolver,
  })  : _resolver = resolver,
        _typePropertyResolver = resolver.typePropertyResolver,
        _assignmentShared = AssignmentExpressionShared(
          resolver: resolver,
        );

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  TypeProvider get _typeProvider => _resolver.typeProvider;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(AssignmentExpressionImpl node, {required DartType contextType}) {
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
      _resolver.setReadElement(
        left,
        readElement,
        atDynamicTarget: leftResolution.atDynamicTarget,
      );
      {
        var recordField = leftResolution.recordField;
        if (recordField != null) {
          node.readType = recordField.type;
        }
      }
      _resolveOperator(node);
    }
    _resolver.setWriteElement(
      left,
      writeElement,
      atDynamicTarget: leftResolution.atDynamicTarget,
    );

    // TODO(scheglov): Use VariableElement and do in resolveForWrite() ?
    _assignmentShared.checkFinalAlreadyAssigned(left);

    DartType rhsContext;
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
      flow.ifNullExpression_rightBegin(left, SharedTypeView(node.readType!));
    }

    _resolver.analyzeExpression(right, SharedTypeSchemaView(rhsContext));
    right = _resolver.popRewrite()!;
    var whyNotPromoted = flow?.whyNotPromoted(right);

    _resolveTypes(node,
        whyNotPromoted: whyNotPromoted, contextType: contextType);

    if (flow != null) {
      if (writeElement is PromotableElement) {
        flow.write(node, writeElement, SharedTypeView(node.typeOrThrow),
            hasRead ? null : right);
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
    required Map<SharedTypeView<DartType>, NonPromotionReason> Function()?
        whyNotPromoted,
  }) {
    if (writeType is! VoidType && _checkForUseOfVoidResult(right)) {
      return;
    }

    var strictCasts = _resolver.analysisOptions.strictCasts;
    if (_typeSystem.isAssignableTo(rightType, writeType,
        strictCasts: strictCasts)) {
      return;
    }

    if (writeType is RecordType &&
        writeType.positionalFields.length == 1 &&
        rightType is! RecordType &&
        right is ParenthesizedExpression) {
      var field = writeType.positionalFields.first;
      if (_typeSystem.isAssignableTo(field.type, rightType,
          strictCasts: strictCasts)) {
        _errorReporter.atNode(
          right,
          CompileTimeErrorCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA,
        );
        return;
      }
    }

    _errorReporter.atNode(
      right,
      CompileTimeErrorCode.INVALID_ASSIGNMENT,
      arguments: [rightType, writeType],
      contextMessages: _resolver.computeWhyNotPromotedMessages(
          right, whyNotPromoted?.call()),
    );
  }

  /// Check for situations where the result of a method or function is used,
  /// when it returns 'void'. Or, in rare cases, when other types of expressions
  /// are void, such as identifiers.
  ///
  /// See [CompileTimeErrorCode.USE_OF_VOID_RESULT].
  // TODO(scheglov): this is duplicate
  bool _checkForUseOfVoidResult(Expression expression) {
    if (!identical(expression.staticType, VoidTypeImpl.instance)) {
      return false;
    }

    if (expression is MethodInvocation) {
      SimpleIdentifier methodName = expression.methodName;
      _errorReporter.atNode(
        methodName,
        CompileTimeErrorCode.USE_OF_VOID_RESULT,
      );
    } else {
      _errorReporter.atNode(
        expression,
        CompileTimeErrorCode.USE_OF_VOID_RESULT,
      );
    }

    return true;
  }

  DartType _computeRhsContext(AssignmentExpressionImpl node, DartType leftType,
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
        return UnknownInferredType.instance;
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
        _errorReporter.atToken(
          operator,
          CompileTimeErrorCode.USE_OF_VOID_RESULT,
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
      _errorReporter.atToken(
        operator,
        CompileTimeErrorCode.UNDEFINED_OPERATOR,
        arguments: [methodName, leftType],
      );
    }
  }

  void _resolveTypes(AssignmentExpressionImpl node,
      {required Map<SharedTypeView<DartType>, NonPromotionReason> Function()?
          whyNotPromoted,
      required DartType contextType}) {
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
      var leftType = node.readType!;
      var operatorElement = node.staticElement;
      if (leftType is DynamicType) {
        assignedType = DynamicTypeImpl.instance;
      } else if (operatorElement != null) {
        var rightType = rightHandSide.typeOrThrow;
        assignedType = _typeSystem.refineBinaryExpressionType(
          leftType,
          operator,
          rightType,
          operatorElement.returnType,
          operatorElement,
        );
      } else {
        assignedType = InvalidTypeImpl.instance;
      }
    }

    DartType nodeType;
    if (operator == TokenType.QUESTION_QUESTION_EQ) {
      // - An if-null assignment `E` of the form `lvalue ??= e` with context type
      //   `K` is analyzed as follows:
      //
      //   - Let `T1` be the read type the lvalue.
      var t1 = node.readType!;
      //   - Let `T2` be the type of `e` inferred with context type `T1`.
      var t2 = assignedType;
      //   - Let `T` be `UP(NonNull(T1), T2)`.
      var nonNullT1 = _typeSystem.promoteToNonNull(t1);
      var t = _typeSystem.leastUpperBound(nonNullT1, t2);
      //   - Let `S` be the greatest closure of `K`.
      var s = _typeSystem.greatestClosureOfSchema(contextType);
      // If `inferenceUpdate3` is not enabled, then the type of `E` is `T`.
      if (!_resolver.definingLibrary.featureSet
          .isEnabled(Feature.inference_update_3)) {
        nodeType = t;
      } else
      //   - If `T <: S`, then the type of `E` is `T`.
      if (_typeSystem.isSubtypeOf(t, s)) {
        nodeType = t;
      } else
      //   - Otherwise, if `NonNull(T1) <: S` and `T2 <: S`, then the type of
      //     `E` is `S`.
      if (_typeSystem.isSubtypeOf(nonNullT1, s) &&
          _typeSystem.isSubtypeOf(t2, s)) {
        nodeType = s;
      } else
      //   - Otherwise, the type of `E` is `T`.
      {
        nodeType = t;
      }
    } else {
      nodeType = assignedType;
    }
    node.recordStaticType(nodeType, resolver: _resolver);

    // TODO(scheglov): Remove from ErrorVerifier?
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
              _errorReporter.atNode(
                left,
                CompileTimeErrorCode.LATE_FINAL_LOCAL_ALREADY_ASSIGNED,
              );
            }
          } else {
            if (isForEachIdentifier || !unassigned) {
              _errorReporter.atNode(
                left,
                CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL,
                arguments: [element.name],
              );
            }
          }
        }
      }
    }
  }
}
