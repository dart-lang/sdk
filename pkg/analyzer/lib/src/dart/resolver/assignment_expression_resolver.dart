// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/dart/resolver/property_element_resolver.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/migration.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:meta/meta.dart';

/// Helper for resolving [AssignmentExpression]s.
class AssignmentExpressionResolver {
  final ResolverVisitor _resolver;
  final FlowAnalysisHelper _flowAnalysis;
  final TypePropertyResolver _typePropertyResolver;
  final InvocationInferenceHelper _inferenceHelper;
  final AssignmentExpressionShared _assignmentShared;

  AssignmentExpressionResolver({
    @required ResolverVisitor resolver,
    @required FlowAnalysisHelper flowAnalysis,
  })  : _resolver = resolver,
        _flowAnalysis = flowAnalysis,
        _typePropertyResolver = resolver.typePropertyResolver,
        _inferenceHelper = resolver.inferenceHelper,
        _assignmentShared = AssignmentExpressionShared(
          resolver: resolver,
          flowAnalysis: flowAnalysis,
        );

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  bool get _isNonNullableByDefault => _typeSystem.isNonNullableByDefault;

  MigrationResolutionHooks get _migrationResolutionHooks {
    return _resolver.migrationResolutionHooks;
  }

  TypeProvider get _typeProvider => _resolver.typeProvider;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

  void resolve(AssignmentExpressionImpl node) {
    var left = node.leftHandSide;
    var right = node.rightHandSide;

    var operator = node.operator.type;
    var hasRead = operator != TokenType.EQ;
    var isIfNull = operator == TokenType.QUESTION_QUESTION_EQ;

    PropertyElementResolverResult leftResolution;
    if (left is IndexExpression) {
      leftResolution = _resolve_IndexExpression(node, left, hasRead);
    } else if (left is PrefixedIdentifier) {
      leftResolution = _resolve_PrefixedIdentifier(node, left, hasRead);
      left = node.leftHandSide;
    } else if (left is PropertyAccess) {
      leftResolution = _resolve_PropertyAccess(node, left, hasRead);
    } else if (left is SimpleIdentifier) {
      leftResolution = _resolve_SimpleIdentifier(node, left, hasRead);
    } else {
      leftResolution = _resolve_NotLValue(node);
      left = node.leftHandSide;
    }

    var readElement = leftResolution.readElement;
    var writeElement = leftResolution.writeElement;

    if (hasRead) {
      _resolver.setReadElement(left, readElement);
    }
    _resolver.setWriteElement(left, writeElement);

    _setBackwardCompatibility(node);

    _resolveOperator(node);

    {
      var leftType = node.writeType;
      if (writeElement is VariableElement) {
        leftType = _resolver.localVariableTypeProvider.getType(left);
      }
      _setRhsContext(node, leftType, operator, right);
    }

    var flow = _flowAnalysis?.flow;
    if (flow != null && isIfNull) {
      flow.ifNullExpression_rightBegin(left, node.readType);
    }

    right.accept(_resolver);

    _resolveTypes(node);

    if (flow != null) {
      if (writeElement is VariableElement) {
        flow.write(writeElement, node.staticType);
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
    DartType rightType,
  ) {
    if (!writeType.isVoid && _checkForUseOfVoidResult(right)) {
      return;
    }

    if (_typeSystem.isAssignableTo2(rightType, writeType)) {
      return;
    }

    _errorReporter.reportErrorForNode(
      CompileTimeErrorCode.INVALID_ASSIGNMENT,
      right,
      [rightType, writeType],
    );
  }

  /// Check for situations where the result of a method or function is used,
  /// when it returns 'void'. Or, in rare cases, when other types of expressions
  /// are void, such as identifiers.
  ///
  /// See [StaticWarningCode.USE_OF_VOID_RESULT].
  /// TODO(scheglov) this is duplicate
  bool _checkForUseOfVoidResult(Expression expression) {
    if (expression == null ||
        !identical(expression.staticType, VoidTypeImpl.instance)) {
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

  /// Record that the static type of the given node is the given type.
  ///
  /// @param expression the node whose type is to be recorded
  /// @param type the static type of the node
  ///
  /// TODO(scheglov) this is duplication
  void _recordStaticType(Expression expression, DartType type) {
    if (_resolver.migrationResolutionHooks != null) {
      type = _migrationResolutionHooks.modifyExpressionType(expression, type);
    }

    // TODO(scheglov) type cannot be null
    if (type == null) {
      expression.staticType = DynamicTypeImpl.instance;
    } else {
      expression.staticType = type;
      if (_typeSystem.isBottom(type)) {
        _flowAnalysis?.flow?.handleExit();
      }
    }
  }

  PropertyElementResolverResult _resolve_IndexExpression(
    AssignmentExpressionImpl node,
    IndexExpression left,
    bool hasRead,
  ) {
    left.target?.accept(_resolver);
    _resolver.startNullAwareIndexExpression(left);

    var resolver = PropertyElementResolver(_resolver);
    var result = resolver.resolveIndexExpression(
      node: left,
      hasRead: hasRead,
      hasWrite: true,
    );

    InferenceContext.setType(left.index, result.indexContextType);
    left.index.accept(_resolver);

    return result;
  }

  PropertyElementResolverResult _resolve_NotLValue(
    AssignmentExpressionImpl node,
  ) {
    node.leftHandSide.accept(_resolver);
    return PropertyElementResolverResult();
  }

  PropertyElementResolverResult _resolve_PrefixedIdentifier(
    AssignmentExpressionImpl node,
    PrefixedIdentifier left,
    bool hasRead,
  ) {
    left.prefix?.accept(_resolver);

    var resolver = PropertyElementResolver(_resolver);
    return resolver.resolvePrefixedIdentifier(
      node: left,
      hasRead: hasRead,
      hasWrite: true,
    );
  }

  PropertyElementResolverResult _resolve_PropertyAccess(
    AssignmentExpressionImpl node,
    PropertyAccess left,
    bool hasRead,
  ) {
    left.target?.accept(_resolver);

    _resolver.startNullAwarePropertyAccess(left);

    var resolver = PropertyElementResolver(_resolver);
    return resolver.resolvePropertyAccess(
      node: left,
      hasRead: hasRead,
      hasWrite: true,
    );
  }

  PropertyElementResolverResult _resolve_SimpleIdentifier(
    AssignmentExpressionImpl node,
    SimpleIdentifier left,
    bool hasRead,
  ) {
    var resolver = PropertyElementResolver(_resolver);
    return resolver.resolveSimpleIdentifier(
      node: left,
      hasRead: hasRead,
      hasWrite: true,
    );
  }

  void _resolveOperator(AssignmentExpressionImpl node) {
    var left = node.leftHandSide;
    var operator = node.operator;
    var operatorType = operator.type;

    var leftType = node.readType;
    if (identical(leftType, NeverTypeImpl.instance)) {
      return;
    }

    _assignmentShared.checkFinalAlreadyAssigned(left);

    // Values of the type void cannot be used.
    // Example: `y += 0`, is not allowed.
    if (operatorType != TokenType.EQ) {
      if (leftType.isVoid) {
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

    var binaryOperatorType = operatorFromCompoundAssignment(operatorType);
    var methodName = binaryOperatorType.lexeme;

    var result = _typePropertyResolver.resolve(
      receiver: left,
      receiverType: leftType,
      name: methodName,
      receiverErrorNode: left,
      nameErrorEntity: operator,
    );
    node.staticElement = result.getter;
    if (result.needsGetterError) {
      _errorReporter.reportErrorForToken(
        CompileTimeErrorCode.UNDEFINED_OPERATOR,
        operator,
        [methodName, leftType],
      );
    }
  }

  void _resolveTypes(AssignmentExpressionImpl node) {
    DartType assignedType;
    DartType nodeType;

    var operator = node.operator.type;
    if (operator == TokenType.EQ) {
      assignedType = node.rightHandSide.staticType;
      nodeType = assignedType;
    } else if (operator == TokenType.QUESTION_QUESTION_EQ) {
      var leftType = node.readType;

      // The LHS value will be used only if it is non-null.
      if (_isNonNullableByDefault) {
        leftType = _typeSystem.promoteToNonNull(leftType);
      }

      assignedType = node.rightHandSide.staticType;
      nodeType = _typeSystem.getLeastUpperBound(leftType, assignedType);
    } else if (operator == TokenType.AMPERSAND_AMPERSAND_EQ ||
        operator == TokenType.BAR_BAR_EQ) {
      assignedType = _typeProvider.boolType;
      nodeType = assignedType;
    } else {
      var operatorElement = node.staticElement;
      if (operatorElement != null) {
        var leftType = node.readType;
        var rightType = node.rightHandSide.staticType;
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
      nodeType = assignedType;
    }

    _inferenceHelper.recordStaticType(node, nodeType);

    // TODO(scheglov) Remove from ErrorVerifier?
    _checkForInvalidAssignment(
      node.writeType,
      node.rightHandSide,
      assignedType,
    );
  }

  /// TODO(scheglov) This is mostly necessary for backward compatibility.
  /// Although we also use `staticElement` for `getType(left)` below.
  void _setBackwardCompatibility(AssignmentExpressionImpl node) {
    var operator = node.operator.type;

    var left = node.leftHandSide;
    var hasRead = operator != TokenType.EQ;

    if (left is IndexExpression) {
      if (hasRead) {
        left.staticElement = node.writeElement;
        left.auxiliaryElements = AuxiliaryElements(node.readElement);
        _resolver.setReadElement(node, node.readElement);
        _resolver.setWriteElement(node, node.writeElement);
      } else {
        left.staticElement = node.writeElement;
        _resolver.setWriteElement(node, node.writeElement);
      }
      _recordStaticType(left, node.writeType);
      return;
    }

    SimpleIdentifier leftIdentifier;
    if (left is PrefixedIdentifier) {
      leftIdentifier = left.identifier;
      _recordStaticType(left, node.writeType);
    } else if (left is PropertyAccess) {
      leftIdentifier = left.propertyName;
      _recordStaticType(left, node.writeType);
    } else if (left is SimpleIdentifier) {
      leftIdentifier = left;
    } else {
      return;
    }

    if (hasRead) {
      var readElement = node.readElement;
      if (readElement is PropertyAccessorElement) {
        leftIdentifier.auxiliaryElements = AuxiliaryElements(readElement);
      }
    }

    leftIdentifier.staticElement = node.writeElement;
    if (node.readElement is VariableElement) {
      var leftType =
          _resolver.localVariableTypeProvider.getType(leftIdentifier);
      _recordStaticType(leftIdentifier, leftType);
    } else {
      _recordStaticType(leftIdentifier, node.writeType);
    }
  }

  void _setRhsContext(AssignmentExpressionImpl node, DartType leftType,
      TokenType operator, Expression right) {
    switch (operator) {
      case TokenType.EQ:
      case TokenType.QUESTION_QUESTION_EQ:
        InferenceContext.setType(right, leftType);
        break;
      case TokenType.AMPERSAND_AMPERSAND_EQ:
      case TokenType.BAR_BAR_EQ:
        InferenceContext.setType(right, _typeProvider.boolType);
        break;
      default:
        var method = node.staticElement;
        if (method != null) {
          var parameters = method.parameters;
          if (parameters.isNotEmpty) {
            InferenceContext.setType(
                right,
                _typeSystem.refineNumericInvocationContext(
                    leftType, method, leftType, parameters[0].type));
          }
        }
        break;
    }
  }
}

class AssignmentExpressionShared {
  final ResolverVisitor _resolver;
  final FlowAnalysisHelper _flowAnalysis;

  AssignmentExpressionShared({
    @required ResolverVisitor resolver,
    @required FlowAnalysisHelper flowAnalysis,
  })  : _resolver = resolver,
        _flowAnalysis = flowAnalysis;

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  void checkFinalAlreadyAssigned(Expression left) {
    var flow = _flowAnalysis?.flow;
    if (flow != null && left is SimpleIdentifier) {
      var element = left.staticElement;
      if (element is VariableElement) {
        var assigned = _flowAnalysis.isDefinitelyAssigned(left, element);
        var unassigned = _flowAnalysis.isDefinitelyUnassigned(left, element);

        if (element.isFinal) {
          if (element.isLate) {
            if (assigned) {
              _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.LATE_FINAL_LOCAL_ALREADY_ASSIGNED,
                left,
              );
            }
          } else {
            if (!unassigned) {
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
