// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/conditional_discard.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/edge_origin.dart';
import 'package:nnbd_migration/src/expression_checks.dart';
import 'package:nnbd_migration/src/node_builder.dart';
import 'package:nnbd_migration/src/nullability_node.dart';

/// Visitor that builds nullability graph edges by examining code to be
/// migrated.
///
/// The return type of each `visit...` method is a [DecoratedType] indicating
/// the static type of the visited expression, along with the constraint
/// variables that will determine its nullability.  For `visit...` methods that
/// don't visit expressions, `null` will be returned.
class GraphBuilder extends GeneralizingAstVisitor<DecoratedType> {
  /// The repository of constraint variables and decorated types (from a
  /// previous pass over the source code).
  final VariableRepository _variables;

  final NullabilityMigrationListener /*?*/ listener;

  final NullabilityGraph _graph;

  /// The file being analyzed.
  final Source _source;

  /// For convenience, a [DecoratedType] representing non-nullable `Object`.
  final DecoratedType _notNullType;

  /// For convenience, a [DecoratedType] representing non-nullable `bool`.
  final DecoratedType _nonNullableBoolType;

  /// For convenience, a [DecoratedType] representing non-nullable `Type`.
  final DecoratedType _nonNullableTypeType;

  /// For convenience, a [DecoratedType] representing `Null`.
  final DecoratedType _nullType;

  /// The [DecoratedType] of the innermost function or method being visited, or
  /// `null` if the visitor is not inside any function or method.
  ///
  /// This is needed to construct the appropriate nullability constraints for
  /// return statements.
  DecoratedType _currentFunctionType;

  /// Information about the most recently visited binary expression whose
  /// boolean value could possibly affect nullability analysis.
  _ConditionInfo _conditionInfo;

  /// The set of nullability nodes that would have to be `nullable` for the code
  /// currently being visited to be reachable.
  ///
  /// Guard variables are attached to the left hand side of any generated
  /// constraints, so that constraints do not take effect if they come from
  /// code that can be proven unreachable by the migration tool.
  final _guards = <NullabilityNode>[];

  /// Indicates whether the statement or expression being visited is within
  /// conditional control flow.  If `true`, this means that the enclosing
  /// function might complete normally without executing the current statement
  /// or expression.
  bool _inConditionalControlFlow = false;

  NullabilityNode _lastConditionalNode;

  GraphBuilder(TypeProvider typeProvider, this._variables, this._graph,
      this._source, this.listener)
      : _notNullType = DecoratedType(typeProvider.objectType, _graph.never),
        _nonNullableBoolType =
            DecoratedType(typeProvider.boolType, _graph.never),
        _nonNullableTypeType =
            DecoratedType(typeProvider.typeType, _graph.never),
        _nullType = DecoratedType(typeProvider.nullType, _graph.always);

  /// Gets the decorated type of [element] from [_variables], performing any
  /// necessary substitutions.
  DecoratedType getOrComputeElementType(Element element,
      {DecoratedType targetType}) {
    Map<TypeParameterElement, DecoratedType> substitution;
    Element baseElement;
    if (element is Member) {
      assert(targetType != null);
      baseElement = element.baseElement;
      var targetTypeType = targetType.type;
      if (targetTypeType is InterfaceType &&
          baseElement is ClassMemberElement) {
        var enclosingClass = baseElement.enclosingElement;
        assert(targetTypeType.element == enclosingClass); // TODO(paulberry)
        substitution = <TypeParameterElement, DecoratedType>{};
        assert(enclosingClass.typeParameters.length ==
            targetTypeType.typeArguments.length); // TODO(paulberry)
        for (int i = 0; i < enclosingClass.typeParameters.length; i++) {
          substitution[enclosingClass.typeParameters[i]] =
              targetType.typeArguments[i];
        }
      }
    } else {
      baseElement = element;
    }
    DecoratedType decoratedBaseType;
    if (baseElement is PropertyAccessorElement &&
        baseElement.isSynthetic &&
        !baseElement.variable.isSynthetic) {
      var variable = baseElement.variable;
      var decoratedElementType =
          _variables.decoratedElementType(variable, create: true);
      if (baseElement.isGetter) {
        decoratedBaseType = DecoratedType(baseElement.type, _graph.never,
            returnType: decoratedElementType);
      } else {
        assert(baseElement.isSetter);
        decoratedBaseType = DecoratedType(baseElement.type, _graph.never,
            positionalParameters: [decoratedElementType]);
      }
    } else {
      decoratedBaseType =
          _variables.decoratedElementType(baseElement, create: true);
    }
    if (substitution != null) {
      DartType elementType;
      if (element is MethodElement) {
        elementType = element.type;
      } else {
        throw element.runtimeType; // TODO(paulberry)
      }
      return decoratedBaseType.substitute(substitution, elementType);
    } else {
      return decoratedBaseType;
    }
  }

  @override
  DecoratedType visitAsExpression(AsExpression node) {
    // TODO(brianwilkerson)
    _unimplemented(node, 'AsExpression');
  }

  @override
  DecoratedType visitAssertStatement(AssertStatement node) {
    _handleAssignment(_notNullType, node.condition);
    if (identical(_conditionInfo?.condition, node.condition)) {
      if (!_inConditionalControlFlow &&
          _conditionInfo.trueDemonstratesNonNullIntent != null) {
        _graph.connect(_conditionInfo.trueDemonstratesNonNullIntent,
            _graph.never, NonNullAssertionOrigin(_source, node.offset),
            hard: true);
      }
    }
    node.message?.accept(this);
    return null;
  }

  @override
  DecoratedType visitAssignmentExpression(AssignmentExpression node) {
    if (node.operator.type != TokenType.EQ) {
      // TODO(paulberry)
      _unimplemented(node, 'Assignment with operator ${node.operator.lexeme}');
    }
    var leftType = node.leftHandSide.accept(this);
    var conditionalNode = _lastConditionalNode;
    _lastConditionalNode = null;
    var expressionType = _handleAssignment(leftType, node.rightHandSide);
    if (_isConditionalExpression(node.leftHandSide)) {
      expressionType = expressionType.withNode(
          NullabilityNode.forLUB(conditionalNode, expressionType.node));
      _variables.recordDecoratedExpressionType(node, expressionType);
    }
    return expressionType;
  }

  @override
  DecoratedType visitAwaitExpression(AwaitExpression node) {
    var expressionType = node.expression.accept(this);
    // TODO(paulberry) Handle subclasses of Future.
    if (expressionType.type.isDartAsyncFuture ||
        expressionType.type.isDartAsyncFutureOr) {
      expressionType = expressionType.typeArguments[0];
    }
    return expressionType;
  }

  @override
  DecoratedType visitBinaryExpression(BinaryExpression node) {
    var operatorType = node.operator.type;
    if (operatorType == TokenType.EQ_EQ || operatorType == TokenType.BANG_EQ) {
      assert(node.leftOperand is! NullLiteral); // TODO(paulberry)
      var leftType = node.leftOperand.accept(this);
      node.rightOperand.accept(this);
      if (node.rightOperand is NullLiteral) {
        // TODO(paulberry): figure out what the rules for isPure should be.
        // TODO(paulberry): only set falseChecksNonNull in unconditional
        // control flow
        bool isPure = node.leftOperand is SimpleIdentifier;
        var conditionInfo = _ConditionInfo(node,
            isPure: isPure,
            trueGuard: leftType.node,
            falseDemonstratesNonNullIntent: leftType.node);
        _conditionInfo = operatorType == TokenType.EQ_EQ
            ? conditionInfo
            : conditionInfo.not(node);
      }
      return _nonNullableBoolType;
    } else if (operatorType == TokenType.AMPERSAND_AMPERSAND ||
        operatorType == TokenType.BAR_BAR) {
      _handleAssignment(_notNullType, node.leftOperand);
      _handleAssignment(_notNullType, node.rightOperand);
      return _nonNullableBoolType;
    } else if (operatorType == TokenType.QUESTION_QUESTION) {
      DecoratedType expressionType;
      var leftType = node.leftOperand.accept(this);
      try {
        _guards.add(leftType.node);
        var rightType = node.rightOperand.accept(this);
        var ifNullNode = NullabilityNode.forIfNotNull();
        expressionType = DecoratedType(node.staticType, ifNullNode);
        _graph.connect(rightType.node, expressionType.node,
            IfNullOrigin(_source, node.offset),
            guards: _guards);
      } finally {
        _guards.removeLast();
      }
      _variables.recordDecoratedExpressionType(node, expressionType);
      return expressionType;
    } else if (operatorType.isUserDefinableOperator) {
      _handleAssignment(_notNullType, node.leftOperand);
      var callee = node.staticElement;
      assert(!(callee is ClassMemberElement &&
          callee
              .enclosingElement.typeParameters.isNotEmpty)); // TODO(paulberry)
      assert(callee != null); // TODO(paulberry)
      var calleeType = getOrComputeElementType(callee);
      // TODO(paulberry): substitute if necessary
      assert(calleeType.positionalParameters.length > 0); // TODO(paulberry)
      _handleAssignment(calleeType.positionalParameters[0], node.rightOperand);
      return calleeType.returnType;
    } else {
      // TODO(paulberry)
      node.leftOperand.accept(this);
      node.rightOperand.accept(this);
      _unimplemented(
          node, 'Binary expression with operator ${node.operator.lexeme}');
    }
  }

  @override
  DecoratedType visitBooleanLiteral(BooleanLiteral node) {
    return DecoratedType(node.staticType, _graph.never);
  }

  @override
  DecoratedType visitCascadeExpression(CascadeExpression node) {
    var type = node.target.accept(this);
    node.cascadeSections.accept(this);
    return type;
  }

  @override
  DecoratedType visitClassDeclaration(ClassDeclaration node) {
    node.members.accept(this);
    return null;
  }

  @override
  DecoratedType visitConditionalExpression(ConditionalExpression node) {
    _handleAssignment(_notNullType, node.condition);
    // TODO(paulberry): guard anything inside the true and false branches
    var thenType = node.thenExpression.accept(this);
    assert(_isSimple(thenType)); // TODO(paulberry)
    var elseType = node.elseExpression.accept(this);
    assert(_isSimple(elseType)); // TODO(paulberry)
    var overallType = DecoratedType(
        node.staticType, NullabilityNode.forLUB(thenType.node, elseType.node));
    _variables.recordDecoratedExpressionType(node, overallType);
    return overallType;
  }

  @override
  DecoratedType visitDefaultFormalParameter(DefaultFormalParameter node) {
    var defaultValue = node.defaultValue;
    if (defaultValue == null) {
      if (node.declaredElement.hasRequired) {
        // Nothing to do; the implicit default value of `null` will never be
        // reached.
      } else {
        _graph.connect(
            _graph.always,
            getOrComputeElementType(node.declaredElement).node,
            OptionalFormalParameterOrigin(_source, node.offset),
            guards: _guards);
      }
    } else {
      _handleAssignment(
          getOrComputeElementType(node.declaredElement), defaultValue,
          canInsertChecks: false);
    }
    return null;
  }

  @override
  DecoratedType visitDoubleLiteral(DoubleLiteral node) {
    return DecoratedType(node.staticType, _graph.never);
  }

  @override
  DecoratedType visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _handleAssignment(_currentFunctionType.returnType, node.expression);
    return null;
  }

  @override
  DecoratedType visitFunctionDeclaration(FunctionDeclaration node) {
    node.functionExpression.parameters?.accept(this);
    assert(_currentFunctionType == null);
    _currentFunctionType =
        _variables.decoratedElementType(node.declaredElement);
    _inConditionalControlFlow = false;
    try {
      node.functionExpression.body.accept(this);
    } finally {
      _currentFunctionType = null;
    }
    return null;
  }

  @override
  DecoratedType visitFunctionExpression(FunctionExpression node) {
    // TODO(brianwilkerson)
    _unimplemented(node, 'FunctionExpression');
  }

  @override
  DecoratedType visitFunctionExpressionInvocation(
      FunctionExpressionInvocation node) {
    // TODO(brianwilkerson)
    _unimplemented(node, 'FunctionExpressionInvocation');
  }

  @override
  DecoratedType visitIfStatement(IfStatement node) {
    // TODO(paulberry): should the use of a boolean in an if-statement be
    // treated like an implicit `assert(b != null)`?  Probably.
    _handleAssignment(_notNullType, node.condition);
    _inConditionalControlFlow = true;
    NullabilityNode trueGuard;
    NullabilityNode falseGuard;
    if (identical(_conditionInfo?.condition, node.condition)) {
      trueGuard = _conditionInfo.trueGuard;
      falseGuard = _conditionInfo.falseGuard;
      _variables.recordConditionalDiscard(_source, node,
          ConditionalDiscard(trueGuard, falseGuard, _conditionInfo.isPure));
    }
    if (trueGuard != null) {
      _guards.add(trueGuard);
    }
    try {
      node.thenStatement.accept(this);
    } finally {
      if (trueGuard != null) {
        _guards.removeLast();
      }
    }
    if (falseGuard != null) {
      _guards.add(falseGuard);
    }
    try {
      node.elseStatement?.accept(this);
    } finally {
      if (falseGuard != null) {
        _guards.removeLast();
      }
    }
    return null;
  }

  @override
  DecoratedType visitIndexExpression(IndexExpression node) {
    DecoratedType targetType;
    var target = node.realTarget;
    if (target != null) {
      targetType = _handleAssignment(_notNullType, target);
    }
    var callee = node.staticElement;
    if (callee == null) {
      // TODO(paulberry)
      _unimplemented(node, 'Index expression with no static type');
    }
    var calleeType = getOrComputeElementType(callee, targetType: targetType);
    // TODO(paulberry): substitute if necessary
    _handleAssignment(calleeType.positionalParameters[0], node.index);
    if (node.inSetterContext()) {
      return calleeType.positionalParameters[1];
    } else {
      return calleeType.returnType;
    }
  }

  @override
  DecoratedType visitInstanceCreationExpression(
      InstanceCreationExpression node) {
    var callee = node.staticElement;
    var calleeType = getOrComputeElementType(callee);
    if (callee.enclosingElement.typeParameters.isNotEmpty) {
      // If the class has type parameters then we might need to substitute the
      // appropriate type arguments.
      // TODO(brianwilkerson)
      _unimplemented(node, 'Instance creation expression with type arguments');
    }
    _handleInvocationArguments(node.argumentList, calleeType);
    return calleeType.returnType;
  }

  @override
  DecoratedType visitIntegerLiteral(IntegerLiteral node) {
    return DecoratedType(node.staticType, _graph.never);
  }

  @override
  DecoratedType visitIsExpression(IsExpression node) {
    var type = node.type;
    if (type is NamedType && type.typeArguments != null) {
      // TODO(brianwilkerson) Figure out what constraints we need to add to
      //  allow the tool to decide whether to make the type arguments nullable.
      // TODO(brianwilkerson)
      _unimplemented(node, 'Is expression with type arguments');
    } else if (type is GenericFunctionType) {
      // TODO(brianwilkerson)
      _unimplemented(node, 'Is expression with GenericFunctionType');
    }
    node.visitChildren(this);
    return DecoratedType(node.staticType, _graph.never);
  }

  @override
  DecoratedType visitListLiteral(ListLiteral node) {
    var listType = node.staticType as InterfaceType;
    if (node.typeArguments == null) {
      // TODO(brianwilkerson) We might want to create a fake node in the graph
      //  to represent the type argument so that we can still create edges from
      //  the elements to it.
      // TODO(brianwilkerson)
      _unimplemented(node, 'List literal with no type arguments');
    } else {
      var typeArgumentType = _variables.decoratedTypeAnnotation(
          _source, node.typeArguments.arguments[0]);
      if (typeArgumentType == null) {
        _unimplemented(node, 'Could not compute type argument type');
      }
      for (var element in node.elements) {
        if (element is Expression) {
          _handleAssignment(typeArgumentType, element);
        } else {
          // Handle spread and control flow elements.
          element.accept(this);
          // TODO(brianwilkerson)
          _unimplemented(node, 'Spread or control flow element');
        }
      }
      return DecoratedType(listType, _graph.never,
          typeArguments: [typeArgumentType]);
    }
  }

  @override
  DecoratedType visitMethodDeclaration(MethodDeclaration node) {
    node.parameters?.accept(this);
    assert(_currentFunctionType == null);
    _currentFunctionType =
        _variables.decoratedElementType(node.declaredElement);
    _inConditionalControlFlow = false;
    try {
      node.body.accept(this);
    } finally {
      _currentFunctionType = null;
    }
    return null;
  }

  @override
  DecoratedType visitMethodInvocation(MethodInvocation node) {
    DecoratedType targetType;
    var target = node.realTarget;
    bool isConditional = _isConditionalExpression(node);
    if (target != null) {
      if (isConditional) {
        targetType = target.accept(this);
      } else {
        _checkNonObjectMember(node.methodName.name); // TODO(paulberry)
        targetType = _handleAssignment(_notNullType, target);
      }
    }
    var callee = node.methodName.staticElement;
    if (callee == null) {
      // TODO(paulberry)
      _unimplemented(node, 'Unresolved method name');
    }
    var calleeType = getOrComputeElementType(callee, targetType: targetType);
    // TODO(paulberry): substitute if necessary
    _handleInvocationArguments(node.argumentList, calleeType);
    var expressionType = calleeType.returnType;
    if (isConditional) {
      expressionType = expressionType.withNode(
          NullabilityNode.forLUB(targetType.node, expressionType.node));
      _variables.recordDecoratedExpressionType(node, expressionType);
    }
    return expressionType;
  }

  @override
  DecoratedType visitNamespaceDirective(NamespaceDirective node) {
    // skip directives
    return null;
  }

  @override
  DecoratedType visitNode(AstNode node) {
    if (listener != null) {
      try {
        return super.visitNode(node);
      } catch (exception, stackTrace) {
        listener.addDetail('''
$exception

$stackTrace''');
        return null;
      }
    } else {
      return super.visitNode(node);
    }
  }

  @override
  DecoratedType visitNullLiteral(NullLiteral node) {
    return _nullType;
  }

  @override
  DecoratedType visitParenthesizedExpression(ParenthesizedExpression node) {
    return node.expression.accept(this);
  }

  @override
  DecoratedType visitPostfixExpression(PostfixExpression node) {
    var operatorType = node.operator.type;
    if (operatorType == TokenType.PLUS_PLUS ||
        operatorType == TokenType.MINUS_MINUS) {
      _handleAssignment(_notNullType, node.operand);
      var callee = node.staticElement;
      if (callee is ClassMemberElement &&
          callee.enclosingElement.typeParameters.isNotEmpty) {
        // TODO(paulberry)
        _unimplemented(node,
            'Operator ${operatorType.lexeme} defined on a class with type parameters');
      }
      if (callee == null) {
        // TODO(paulberry)
        _unimplemented(node, 'Unresolved operator ${operatorType.lexeme}');
      }
      var calleeType = getOrComputeElementType(callee);
      // TODO(paulberry): substitute if necessary
      return calleeType.returnType;
    }
    _unimplemented(
        node, 'Postfix expression with operator ${node.operator.lexeme}');
  }

  @override
  DecoratedType visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.staticElement is ImportElement) {
      // TODO(paulberry)
      _unimplemented(node, 'PrefixedIdentifier with a prefix');
    } else {
      return _handlePropertyAccess(node, node.prefix, node.identifier);
    }
  }

  @override
  DecoratedType visitPrefixExpression(PrefixExpression node) {
    /* DecoratedType operandType = */
    _handleAssignment(_notNullType, node.operand);
    var operatorType = node.operator.type;
    if (operatorType == TokenType.BANG) {
      return _nonNullableBoolType;
    } else if (operatorType == TokenType.PLUS_PLUS ||
        operatorType == TokenType.MINUS_MINUS) {
      var callee = node.staticElement;
      if (callee is ClassMemberElement &&
          callee.enclosingElement.typeParameters.isNotEmpty) {
        // TODO(paulberry)
        _unimplemented(node,
            'Operator ${operatorType.lexeme} defined on a class with type parameters');
      }
      if (callee == null) {
        // TODO(paulberry)
        _unimplemented(node, 'Unresolved operator ${operatorType.lexeme}');
      }
      var calleeType = getOrComputeElementType(callee);
      // TODO(paulberry): substitute if necessary
      return calleeType.returnType;
    }
    // TODO(brianwilkerson) The remaining cases are invocations.
    _unimplemented(
        node, 'Prefix expression with operator ${node.operator.lexeme}');
  }

  @override
  DecoratedType visitPropertyAccess(PropertyAccess node) {
    return _handlePropertyAccess(node, node.realTarget, node.propertyName);
  }

  @override
  DecoratedType visitReturnStatement(ReturnStatement node) {
    if (node.expression == null) {
      _checkAssignment(_currentFunctionType.returnType, _nullType, null,
          hard: false);
    } else {
      _handleAssignment(_currentFunctionType.returnType, node.expression);
    }
    return null;
  }

  @override
  DecoratedType visitSetOrMapLiteral(SetOrMapLiteral node) {
    var listType = node.staticType as InterfaceType;
    var typeArguments = node.typeArguments?.arguments;
    if (typeArguments == null) {
      // TODO(brianwilkerson) We might want to create fake nodes in the graph to
      //  represent the type arguments so that we can still create edges from
      //  the elements to them.
      // TODO(brianwilkerson)
      _unimplemented(node, 'Set or map literal with no type arguments');
    } else if (typeArguments.length == 1) {
      var elementType =
          _variables.decoratedTypeAnnotation(_source, typeArguments[0]);
      for (var element in node.elements) {
        if (element is Expression) {
          _handleAssignment(elementType, element);
        } else {
          // Handle spread and control flow elements.
          element.accept(this);
          // TODO(brianwilkerson)
          _unimplemented(node, 'Spread or control flow element');
        }
      }
      return DecoratedType(listType, _graph.never,
          typeArguments: [elementType]);
    } else if (typeArguments.length == 2) {
      var keyType =
          _variables.decoratedTypeAnnotation(_source, typeArguments[0]);
      var valueType =
          _variables.decoratedTypeAnnotation(_source, typeArguments[1]);
      for (var element in node.elements) {
        if (element is MapLiteralEntry) {
          _handleAssignment(keyType, element.key);
          _handleAssignment(valueType, element.value);
        } else {
          // Handle spread and control flow elements.
          element.accept(this);
          // TODO(brianwilkerson)
          _unimplemented(node, 'Spread or control flow element');
        }
      }
      return DecoratedType(listType, _graph.never,
          typeArguments: [keyType, valueType]);
    } else {
      // TODO(brianwilkerson)
      _unimplemented(
          node, 'Set or map literal with more than two type arguments');
    }
  }

  @override
  DecoratedType visitSimpleIdentifier(SimpleIdentifier node) {
    var staticElement = node.staticElement;
    if (staticElement is ParameterElement ||
        staticElement is LocalVariableElement ||
        staticElement is FunctionElement) {
      return getOrComputeElementType(staticElement);
    } else if (staticElement is PropertyAccessorElement) {
      var elementType = getOrComputeElementType(staticElement);
      return staticElement.isGetter
          ? elementType.returnType
          : elementType.positionalParameters[0];
    } else if (staticElement is ClassElement) {
      return _nonNullableTypeType;
    } else {
      // TODO(paulberry)
      _unimplemented(node,
          'Simple identifier with a static element of type ${staticElement.runtimeType}');
    }
  }

  @override
  DecoratedType visitStringLiteral(StringLiteral node) {
    node.visitChildren(this);
    return DecoratedType(node.staticType, _graph.never);
  }

  @override
  DecoratedType visitSuperExpression(SuperExpression node) {
    return DecoratedType(node.staticType, _graph.never);
  }

  @override
  DecoratedType visitSymbolLiteral(SymbolLiteral node) {
    return DecoratedType(node.staticType, _graph.never);
  }

  @override
  DecoratedType visitThisExpression(ThisExpression node) {
    return DecoratedType(node.staticType, _graph.never);
  }

  @override
  DecoratedType visitThrowExpression(ThrowExpression node) {
    node.expression.accept(this);
    // TODO(paulberry): do we need to check the expression type?  I think not.
    return DecoratedType(node.staticType, _graph.never);
  }

  @override
  DecoratedType visitTypeName(TypeName typeName) {
    var typeArguments = typeName.typeArguments?.arguments;
    var element = typeName.name.staticElement;
    if (element is TypeParameterizedElement) {
      if (typeArguments == null) {
        var instantiatedType =
            _variables.decoratedTypeAnnotation(_source, typeName);
        if (instantiatedType == null) {
          throw new StateError('No type annotation for type name '
              '${typeName.toSource()}, offset=${typeName.offset}');
        }
        var origin = InstantiateToBoundsOrigin(_source, typeName.offset);
        for (int i = 0; i < instantiatedType.typeArguments.length; i++) {
          _unionDecoratedTypes(
              instantiatedType.typeArguments[i],
              _variables.decoratedElementType(element.typeParameters[i],
                  create: true),
              origin);
        }
      } else {
        for (int i = 0; i < typeArguments.length; i++) {
          DecoratedType bound;
          bound = _variables.decoratedElementType(element.typeParameters[i],
              create: true);
          _checkAssignment(
              bound,
              _variables.decoratedTypeAnnotation(_source, typeArguments[i]),
              null,
              hard: true);
        }
      }
    }
    return _nonNullableTypeType;
  }

  @override
  DecoratedType visitVariableDeclaration(VariableDeclaration node) {
    var destinationType = getOrComputeElementType(node.declaredElement);
    var initializer = node.initializer;
    if (initializer == null) {
      // TODO(paulberry)
      _unimplemented(node, 'Variable declaration with no initializer');
    } else {
      _handleAssignment(destinationType, initializer);
    }
    return null;
  }

  /// Creates the necessary constraint(s) for an assignment from [sourceType] to
  /// [destinationType].  [expressionChecks] tracks checks that might have to be
  /// done on the type of an expression.  [hard] indicates whether a hard edge
  /// should be created.
  void _checkAssignment(DecoratedType destinationType, DecoratedType sourceType,
      ExpressionChecks expressionChecks,
      {@required bool hard}) {
    var edge = _graph.connect(
        sourceType.node, destinationType.node, expressionChecks,
        guards: _guards, hard: hard);
    expressionChecks?.edges?.add(edge);
    // TODO(paulberry): generalize this.
    if ((_isSimple(sourceType) || destinationType.type.isObject) &&
        _isSimple(destinationType)) {
      // Ok; nothing further to do.
    } else if (sourceType.type is InterfaceType &&
        destinationType.type is InterfaceType &&
        sourceType.type.element == destinationType.type.element) {
      assert(sourceType.typeArguments.length ==
          destinationType.typeArguments.length);
      for (int i = 0; i < sourceType.typeArguments.length; i++) {
        _checkAssignment(destinationType.typeArguments[i],
            sourceType.typeArguments[i], expressionChecks,
            hard: false);
      }
    } else if (sourceType.type is FunctionType &&
        destinationType.type is FunctionType) {
      _checkAssignment(
          destinationType.returnType, sourceType.returnType, expressionChecks,
          hard: hard);
      if (sourceType.typeArguments.isNotEmpty ||
          destinationType.typeArguments.isNotEmpty) {
        throw UnimplementedError('TODO(paulberry)');
      }
      if (sourceType.positionalParameters.isNotEmpty ||
          destinationType.positionalParameters.isNotEmpty) {
        throw UnimplementedError('TODO(paulberry)');
      }
      if (sourceType.namedParameters.isNotEmpty ||
          destinationType.namedParameters.isNotEmpty) {
        throw UnimplementedError('TODO(paulberry)');
      }
    } else if (destinationType.type.isDynamic || sourceType.type.isDynamic) {
      // ok; nothing further to do.
    } else {
      throw '$destinationType <= $sourceType'; // TODO(paulberry)
    }
  }

  /// Double checks that [name] is not the name of a method or getter declared
  /// on [Object].
  ///
  /// TODO(paulberry): get rid of this method and put the correct logic into the
  /// call sites.
  void _checkNonObjectMember(String name) {
    assert(name != 'toString');
    assert(name != 'hashCode');
    assert(name != 'noSuchMethod');
    assert(name != 'runtimeType');
  }

  /// Creates the necessary constraint(s) for an assignment of the given
  /// [expression] to a destination whose type is [destinationType].
  DecoratedType _handleAssignment(
      DecoratedType destinationType, Expression expression,
      {bool canInsertChecks = true}) {
    var sourceType = expression.accept(this);
    if (sourceType == null) {
      throw StateError('No type computed for ${expression.runtimeType} '
          '(${expression.toSource()}) offset=${expression.offset}');
    }
    ExpressionChecks expressionChecks;
    if (canInsertChecks) {
      expressionChecks = ExpressionChecks(expression.end);
      _variables.recordExpressionChecks(_source, expression, expressionChecks);
    }
    _checkAssignment(destinationType, sourceType, expressionChecks,
        hard: _isVariableOrParameterReference(expression) &&
            !_inConditionalControlFlow);
    return sourceType;
  }

  /// Creates the necessary constraint(s) for an [argumentList] when invoking an
  /// executable element whose type is [calleeType].
  void _handleInvocationArguments(
      ArgumentList argumentList, DecoratedType calleeType) {
    var arguments = argumentList.arguments;
    int i = 0;
    var suppliedNamedParameters = Set<String>();
    for (var expression in arguments) {
      if (expression is NamedExpression) {
        var name = expression.name.label.name;
        var parameterType = calleeType.namedParameters[name];
        if (parameterType == null) {
          // TODO(paulberry)
          _unimplemented(expression, 'Missing type for named parameter');
        }
        _handleAssignment(parameterType, expression.expression);
        suppliedNamedParameters.add(name);
      } else {
        if (calleeType.positionalParameters.length <= i) {
          // TODO(paulberry)
          _unimplemented(argumentList, 'Missing positional parameter at $i');
        }
        _handleAssignment(calleeType.positionalParameters[i++], expression);
      }
    }
    // Any parameters not supplied must be optional.
    for (var entry in calleeType.namedParameters.entries) {
      if (suppliedNamedParameters.contains(entry.key)) continue;
      entry.value.node.recordNamedParameterNotSupplied(_guards, _graph,
          NamedParameterNotSuppliedOrigin(_source, argumentList.offset));
    }
  }

  DecoratedType _handlePropertyAccess(
      Expression node, Expression target, SimpleIdentifier propertyName) {
    DecoratedType targetType;
    bool isConditional = _isConditionalExpression(node);
    if (isConditional) {
      targetType = target.accept(this);
    } else {
      _checkNonObjectMember(propertyName.name); // TODO(paulberry)
      targetType = _handleAssignment(_notNullType, target);
    }
    var callee = propertyName.staticElement;
    if (callee == null) {
      // TODO(paulberry)
      _unimplemented(node, 'Unresolved property access');
    }
    var calleeType = getOrComputeElementType(callee, targetType: targetType);
    // TODO(paulberry): substitute if necessary
    if (propertyName.inSetterContext()) {
      if (isConditional) {
        _lastConditionalNode = targetType.node;
      }
      return calleeType.positionalParameters[0];
    } else {
      var expressionType = calleeType.returnType;
      if (isConditional) {
        expressionType = expressionType.withNode(
            NullabilityNode.forLUB(targetType.node, expressionType.node));
        _variables.recordDecoratedExpressionType(node, expressionType);
      }
      return expressionType;
    }
  }

  bool _isConditionalExpression(Expression expression) {
    Token token;
    if (expression is MethodInvocation) {
      token = expression.operator;
      if (token == null) return false;
    } else if (expression is PropertyAccess) {
      token = expression.operator;
    } else {
      return false;
    }
    switch (token.type) {
      case TokenType.PERIOD:
      case TokenType.PERIOD_PERIOD:
        return false;
      case TokenType.QUESTION_PERIOD:
        return true;
      default:
        // TODO(paulberry)
        _unimplemented(
            expression, 'Conditional expression with operator ${token.lexeme}');
    }
  }

  /// Double checks that [type] is sufficiently simple for this naive prototype
  /// implementation.
  ///
  /// TODO(paulberry): get rid of this method and put the correct logic into the
  /// call sites.
  bool _isSimple(DecoratedType type) {
    if (type.type.isBottom) return true;
    if (type.type.isVoid) return true;
    if (type.type is TypeParameterType) return true;
    if (type.type is! InterfaceType) return false;
    if ((type.type as InterfaceType).typeParameters.isNotEmpty) return false;
    return true;
  }

  bool _isVariableOrParameterReference(Expression expression) {
    expression = expression.unParenthesized;
    if (expression is SimpleIdentifier) {
      var element = expression.staticElement;
      if (element is LocalVariableElement) return true;
      if (element is ParameterElement) return true;
    }
    return false;
  }

  @alwaysThrows
  void _unimplemented(AstNode node, String message) {
    CompilationUnit unit = node.root as CompilationUnit;
    StringBuffer buffer = StringBuffer();
    buffer.write(message);
    buffer.write(' in "');
    buffer.write(node.toSource());
    buffer.write('" on line ');
    buffer.write(unit.lineInfo.getLocation(node.offset).lineNumber);
    buffer.write(' of "');
    buffer.write(unit.declaredElement.source.fullName);
    buffer.write('"');
    throw UnimplementedError(buffer.toString());
  }

  void _unionDecoratedTypes(
      DecoratedType x, DecoratedType y, EdgeOrigin origin) {
    _graph.union(x.node, y.node, origin);
    if (x.typeArguments.isNotEmpty ||
        y.typeArguments.isNotEmpty ||
        x.returnType != null ||
        y.returnType != null ||
        x.positionalParameters.isNotEmpty ||
        y.positionalParameters.isNotEmpty ||
        x.namedParameters.isNotEmpty ||
        y.namedParameters.isNotEmpty) {
      // TODO(paulberry)
      throw UnimplementedError('_unionDecoratedTypes($x, $y, $origin)');
    }
  }
}

/// Information about a binary expression whose boolean value could possibly
/// affect nullability analysis.
class _ConditionInfo {
  /// The [expression] of interest.
  final Expression condition;

  /// Indicates whether [condition] is pure (free from side effects).
  ///
  /// For example, a condition like `x == null` is pure (assuming `x` is a local
  /// variable or static variable), because evaluating it has no user-visible
  /// effect other than returning a boolean value.
  final bool isPure;

  /// If not `null`, the [NullabilityNode] that would need to be nullable in
  /// order for [condition] to evaluate to `true`.
  final NullabilityNode trueGuard;

  /// If not `null`, the [NullabilityNode] that would need to be nullable in
  /// order for [condition] to evaluate to `false`.
  final NullabilityNode falseGuard;

  /// If not `null`, the [NullabilityNode] that should be asserted to have
  //  /// non-null intent if [condition] is asserted to be `true`.
  final NullabilityNode trueDemonstratesNonNullIntent;

  /// If not `null`, the [NullabilityNode] that should be asserted to have
  /// non-null intent if [condition] is asserted to be `false`.
  final NullabilityNode falseDemonstratesNonNullIntent;

  _ConditionInfo(this.condition,
      {@required this.isPure,
      this.trueGuard,
      this.falseGuard,
      this.trueDemonstratesNonNullIntent,
      this.falseDemonstratesNonNullIntent});

  /// Returns a new [_ConditionInfo] describing the boolean "not" of `this`.
  _ConditionInfo not(Expression condition) => _ConditionInfo(condition,
      isPure: isPure,
      trueGuard: falseGuard,
      falseGuard: trueGuard,
      trueDemonstratesNonNullIntent: falseDemonstratesNonNullIntent,
      falseDemonstratesNonNullIntent: trueDemonstratesNonNullIntent);
}
