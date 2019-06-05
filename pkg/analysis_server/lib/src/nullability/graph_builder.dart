// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/nullability/conditional_discard.dart';
import 'package:analysis_server/src/nullability/decorated_type.dart';
import 'package:analysis_server/src/nullability/expression_checks.dart';
import 'package:analysis_server/src/nullability/node_builder.dart';
import 'package:analysis_server/src/nullability/nullability_node.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';

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

  final bool _permissive;

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

  GraphBuilder(TypeProvider typeProvider, this._variables, this._graph,
      this._source, this._permissive)
      : _notNullType =
            DecoratedType(typeProvider.objectType, NullabilityNode.never),
        _nonNullableBoolType =
            DecoratedType(typeProvider.boolType, NullabilityNode.never),
        _nonNullableTypeType =
            DecoratedType(typeProvider.typeType, NullabilityNode.never),
        _nullType =
            DecoratedType(typeProvider.nullType, NullabilityNode.always);

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
    var decoratedBaseType =
        _variables.decoratedElementType(baseElement, create: true);
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
  DecoratedType visitAssertStatement(AssertStatement node) {
    _handleAssignment(_notNullType, node.condition);
    if (identical(_conditionInfo?.condition, node.condition)) {
      if (!_inConditionalControlFlow &&
          _conditionInfo.trueDemonstratesNonNullIntent != null) {
        _conditionInfo.trueDemonstratesNonNullIntent
            ?.recordNonNullIntent(_guards, _graph);
      }
    }
    node.message?.accept(this);
    return null;
  }

  @override
  DecoratedType visitAssignmentExpression(AssignmentExpression node) {
    if (node.operator.type != TokenType.EQ) {
      throw UnimplementedError('TODO(paulberry)');
    }
    var leftType = node.leftHandSide.accept(this);
    return _handleAssignment(leftType, node.rightHandSide);
  }

  @override
  DecoratedType visitBinaryExpression(BinaryExpression node) {
    switch (node.operator.type) {
      case TokenType.EQ_EQ:
      case TokenType.BANG_EQ:
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
          _conditionInfo = node.operator.type == TokenType.EQ_EQ
              ? conditionInfo
              : conditionInfo.not(node);
        }
        return _nonNullableBoolType;
      case TokenType.PLUS:
        _handleAssignment(_notNullType, node.leftOperand);
        var callee = node.staticElement;
        assert(!(callee is ClassMemberElement &&
            callee.enclosingElement.typeParameters
                .isNotEmpty)); // TODO(paulberry)
        assert(callee != null); // TODO(paulberry)
        var calleeType = getOrComputeElementType(callee);
        // TODO(paulberry): substitute if necessary
        assert(calleeType.positionalParameters.length > 0); // TODO(paulberry)
        _handleAssignment(
            calleeType.positionalParameters[0], node.rightOperand);
        return calleeType.returnType;
      default:
        assert(false); // TODO(paulberry)
        return null;
    }
  }

  @override
  DecoratedType visitBooleanLiteral(BooleanLiteral node) {
    return DecoratedType(node.staticType, NullabilityNode.never);
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
    var overallType = DecoratedType(node.staticType,
        NullabilityNode.forLUB(node, thenType.node, elseType.node, _graph));
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
        NullabilityNode.recordAssignment(NullabilityNode.always,
            getOrComputeElementType(node.declaredElement).node, _guards, _graph,
            hard: false);
      }
    } else {
      _handleAssignment(
          getOrComputeElementType(node.declaredElement), defaultValue,
          canInsertChecks: false);
    }
    return null;
  }

  @override
  DecoratedType visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _handleAssignment(_currentFunctionType.returnType, node.expression);
    return null;
  }

  @override
  DecoratedType visitFunctionDeclaration(FunctionDeclaration node) {
    node.functionExpression.parameters.accept(this);
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
    if (node.target != null) {
      targetType = _handleAssignment(_notNullType, node.target);
    }
    var callee = node.staticElement;
    if (callee == null) {
      throw new UnimplementedError('TODO(paulberry)');
    }
    var calleeType = getOrComputeElementType(callee, targetType: targetType);
    // TODO(paulberry): substitute if necessary
    _handleAssignment(calleeType.positionalParameters[0], node.index);
    return calleeType.returnType;
  }

  @override
  DecoratedType visitIntegerLiteral(IntegerLiteral node) {
    return DecoratedType(node.staticType, NullabilityNode.never);
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
    if (node.target != null) {
      if (node.operator.type != TokenType.PERIOD) {
        throw new UnimplementedError('TODO(paulberry)');
      }
      _checkNonObjectMember(node.methodName.name); // TODO(paulberry)
      targetType = _handleAssignment(_notNullType, node.target);
    }
    var callee = node.methodName.staticElement;
    if (callee == null) {
      throw new UnimplementedError('TODO(paulberry)');
    }
    var calleeType = getOrComputeElementType(callee, targetType: targetType);
    // TODO(paulberry): substitute if necessary
    var arguments = node.argumentList.arguments;
    int i = 0;
    var suppliedNamedParameters = Set<String>();
    for (var expression in arguments) {
      if (expression is NamedExpression) {
        var name = expression.name.label.name;
        var parameterType = calleeType.namedParameters[name];
        assert(parameterType != null); // TODO(paulberry)
        _handleAssignment(parameterType, expression.expression);
        suppliedNamedParameters.add(name);
      } else {
        assert(calleeType.positionalParameters.length > i); // TODO(paulberry)
        _handleAssignment(calleeType.positionalParameters[i++], expression);
      }
    }
    // Any parameters not supplied must be optional.
    for (var entry in calleeType.namedParameters.entries) {
      if (suppliedNamedParameters.contains(entry.key)) continue;
      entry.value.node.recordNamedParameterNotSupplied(_guards, _graph);
    }
    return calleeType.returnType;
  }

  @override
  DecoratedType visitNode(AstNode node) {
    if (_permissive) {
      try {
        return super.visitNode(node);
      } catch (_) {
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
  DecoratedType visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.staticElement is ImportElement) {
      throw new UnimplementedError('TODO(paulberry)');
    } else {
      return _handlePropertyAccess(node.prefix, node.period, node.identifier);
    }
  }

  @override
  DecoratedType visitPropertyAccess(PropertyAccess node) {
    return _handlePropertyAccess(node.target, node.operator, node.propertyName);
  }

  @override
  DecoratedType visitReturnStatement(ReturnStatement node) {
    if (node.expression == null) {
      _checkAssignment(_currentFunctionType.returnType, _nullType, null);
    } else {
      _handleAssignment(_currentFunctionType.returnType, node.expression);
    }
    return null;
  }

  @override
  DecoratedType visitSimpleIdentifier(SimpleIdentifier node) {
    var staticElement = node.staticElement;
    if (staticElement is ParameterElement ||
        staticElement is LocalVariableElement) {
      return getOrComputeElementType(staticElement);
    } else if (staticElement is ClassElement) {
      return _nonNullableTypeType;
    } else {
      // TODO(paulberry)
      throw new UnimplementedError('${staticElement.runtimeType}');
    }
  }

  @override
  DecoratedType visitStringLiteral(StringLiteral node) {
    return DecoratedType(node.staticType, NullabilityNode.never);
  }

  @override
  DecoratedType visitThisExpression(ThisExpression node) {
    return DecoratedType(node.staticType, NullabilityNode.never);
  }

  @override
  DecoratedType visitThrowExpression(ThrowExpression node) {
    node.expression.accept(this);
    // TODO(paulberry): do we need to check the expression type?  I think not.
    return DecoratedType(node.staticType, NullabilityNode.never);
  }

  @override
  DecoratedType visitTypeName(TypeName typeName) {
    var typeArguments = typeName.typeArguments?.arguments;
    var element = typeName.name.staticElement;
    if (typeArguments != null) {
      for (int i = 0; i < typeArguments.length; i++) {
        DecoratedType bound;
        if (element is TypeParameterizedElement) {
          bound = _variables.decoratedElementType(element.typeParameters[i],
              create: true);
        } else {
          throw new UnimplementedError('TODO(paulberry)');
        }
        _checkAssignment(bound,
            _variables.decoratedTypeAnnotation(_source, typeArguments[i]), null,
            hard: true);
      }
    }
    return DecoratedType(typeName.type, NullabilityNode.never);
  }

  @override
  DecoratedType visitVariableDeclaration(VariableDeclaration node) {
    var destinationType = getOrComputeElementType(node.declaredElement);
    var initializer = node.initializer;
    if (initializer == null) {
      throw UnimplementedError('TODO(paulberry)');
    } else {
      return _handleAssignment(destinationType, initializer);
    }
  }

  /// Creates the necessary constraint(s) for an assignment from [sourceType] to
  /// [destinationType].  [expression] is the expression whose type is
  /// [sourceType]; it is the expression we will have to null-check in the case
  /// where a nullable source is assigned to a non-nullable destination.
  void _checkAssignment(DecoratedType destinationType, DecoratedType sourceType,
      Expression expression,
      {bool hard}) {
    if (expression != null) {
      _variables.recordExpressionChecks(
          _source,
          expression,
          ExpressionChecks(
              expression.end, sourceType.node, destinationType.node, _guards));
    }
    NullabilityNode.recordAssignment(
        sourceType.node, destinationType.node, _guards, _graph,
        hard: hard ??
            (_isVariableOrParameterReference(expression) &&
                !_inConditionalControlFlow));
    // TODO(paulberry): it's a cheat to pass in expression=null for the
    // recursive checks.  Really we want to unify all the checks in a single
    // ExpressionChecks object.
    expression = null;
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
            sourceType.typeArguments[i], expression);
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
    _checkAssignment(
        destinationType, sourceType, canInsertChecks ? expression : null);
    return sourceType;
  }

  DecoratedType _handlePropertyAccess(
      Expression target, Token operator, SimpleIdentifier propertyName) {
    if (operator.type != TokenType.PERIOD) {
      throw new UnimplementedError('TODO(paulberry)');
    }
    _checkNonObjectMember(propertyName.name); // TODO(paulberry)
    var targetType = _handleAssignment(_notNullType, target);
    var callee = propertyName.staticElement;
    if (callee == null) {
      throw new UnimplementedError('TODO(paulberry)');
    }
    var calleeType = getOrComputeElementType(callee, targetType: targetType);
    // TODO(paulberry): substitute if necessary
    return calleeType.returnType;
  }

  /// Double checks that [type] is sufficiently simple for this naive prototype
  /// implementation.
  ///
  /// TODO(paulberry): get rid of this method and put the correct logic into the
  /// call sites.
  bool _isSimple(DecoratedType type) {
    if (type.type.isBottom) return true;
    if (type.type.isVoid) return true;
    if (type.type is! InterfaceType) return false;
    if ((type.type as InterfaceType).typeParameters.isNotEmpty) return false;
    return true;
  }

  bool _isVariableOrParameterReference(Expression expression) {
    if (expression is SimpleIdentifier) {
      var element = expression.staticElement;
      if (element is LocalVariableElement) return true;
      if (element is ParameterElement) return true;
    }
    return false;
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
