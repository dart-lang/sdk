// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/nullability/conditional_discard.dart';
import 'package:analyzer/src/dart/nullability/constraint_variable_gatherer.dart';
import 'package:analyzer/src/dart/nullability/decorated_type.dart';
import 'package:analyzer/src/dart/nullability/expression_checks.dart';
import 'package:analyzer/src/dart/nullability/unit_propagation.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';

/// Visitor that gathers nullability migration constraints from code to be
/// migrated.
///
/// The return type of each `visit...` method is a [DecoratedType] indicating
/// the static type of the visited expression, along with the constraint
/// variables that will determine its nullability.  For `visit...` methods that
/// don't visit expressions, `null` will be returned.
class ConstraintGatherer extends GeneralizingAstVisitor<DecoratedType> {
  /// The repository of constraint variables and decorated types (from a
  /// previous pass over the source code).
  final VariableRepository _variables;

  final bool _permissive;

  /// Constraints gathered by the visitor are stored here.
  final Constraints _constraints;

  /// The file being analyzed.
  final Source _source;

  /// For convenience, a [DecoratedType] representing non-nullable `Object`.
  final DecoratedType _notNullType;

  /// For convenience, a [DecoratedType] representing non-nullable `bool`.
  final DecoratedType _nonNullableBoolType;

  /// For convenience, a [DecoratedType] representing non-nullable `Type`.
  final DecoratedType _nonNullableTypeType;

  /// The [DecoratedType] of the innermost function or method being visited, or
  /// `null` if the visitor is not inside any function or method.
  ///
  /// This is needed to construct the appropriate nullability constraints for
  /// return statements.
  DecoratedType _currentFunctionType;

  /// Information about the most recently visited binary expression whose
  /// boolean value could possibly affect nullability analysis.
  _ConditionInfo _conditionInfo;

  /// The set of constraint variables that would have to be assigned the value
  /// of `true` for the code currently being visited to be reachable.
  ///
  /// Guard variables are attached to the left hand side of any generated
  /// constraints, so that constraints do not take effect if they come from
  /// code that can be proven unreachable by the migration tool.
  final _guards = <ConstraintVariable>[];

  ConstraintGatherer(TypeProvider typeProvider, this._variables,
      this._constraints, this._source, this._permissive)
      : _notNullType = DecoratedType(typeProvider.objectType, null),
        _nonNullableBoolType = DecoratedType(typeProvider.boolType, null),
        _nonNullableTypeType = DecoratedType(typeProvider.typeType, null);

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
      return decoratedBaseType.substitute(
          _constraints, substitution, elementType);
    } else {
      return decoratedBaseType;
    }
  }

  @override
  DecoratedType visitAssertStatement(AssertStatement node) {
    _handleAssignment(_notNullType, node.condition);
    if (identical(_conditionInfo?.condition, node.condition)) {
      // TODO(paulberry): should only do this if in unconditional control flow.
      if (_conditionInfo.trueChecksNonNull != null) {
        _recordFact(_conditionInfo.trueChecksNonNull);
      }
    }
    node.message?.accept(this);
    return null;
  }

  @override
  DecoratedType visitBinaryExpression(BinaryExpression node) {
    switch (node.operator.type) {
      case TokenType.EQ_EQ:
        assert(node.leftOperand is! NullLiteral); // TODO(paulberry)
        var leftType = node.leftOperand.accept(this);
        node.rightOperand.accept(this);
        if (node.rightOperand is NullLiteral) {
          // TODO(paulberry): figure out what the rules for isPure should be.
          // TODO(paulberry): only set falseChecksNonNull in unconditional
          // control flow
          bool isPure = node.leftOperand is SimpleIdentifier;
          _conditionInfo = _ConditionInfo(node,
              isPure: isPure,
              trueGuard: leftType.nullable,
              falseChecksNonNull: leftType.nullAsserts);
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
        _joinNullabilities(node, thenType.nullable, elseType.nullable));
    _variables.recordDecoratedExpressionType(node, overallType);
    return overallType;
  }

  @override
  DecoratedType visitDefaultFormalParameter(DefaultFormalParameter node) {
    assert(node.defaultValue == null); // TODO(paulberry)
    _recordFact(getOrComputeElementType(node.declaredElement).nullable);
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
    node.functionExpression.body.accept(this);
    _currentFunctionType = null;
    return null;
  }

  @override
  DecoratedType visitIfStatement(IfStatement node) {
    // TODO(paulberry): should the use of a boolean in an if-statement be
    // treated like an implicit `assert(b != null)`?  Probably.
    _handleAssignment(_notNullType, node.condition);
    ConstraintVariable trueGuard;
    ConstraintVariable falseGuard;
    if (identical(_conditionInfo?.condition, node.condition)) {
      trueGuard = _conditionInfo.trueGuard;
      falseGuard = _conditionInfo.falseGuard;
      _variables.recordConditionalDiscard(
          _source,
          node,
          ConditionalDiscard(trueGuard ?? ConstraintVariable.always,
              falseGuard ?? ConstraintVariable.always, _conditionInfo.isPure));
    }
    if (trueGuard != null) {
      _guards.add(trueGuard);
    }
    node.thenStatement.accept(this);
    if (trueGuard != null) {
      _guards.removeLast();
    }
    if (falseGuard != null) {
      _guards.add(falseGuard);
    }
    node.elseStatement?.accept(this);
    if (falseGuard != null) {
      _guards.removeLast();
    }
    return null;
  }

  @override
  DecoratedType visitIntegerLiteral(IntegerLiteral node) {
    return DecoratedType(node.staticType, null);
  }

  @override
  DecoratedType visitMethodDeclaration(MethodDeclaration node) {
    node.parameters.accept(this);
    assert(_currentFunctionType == null);
    _currentFunctionType =
        _variables.decoratedElementType(node.declaredElement);
    node.body.accept(this);
    _currentFunctionType = null;
    return null;
  }

  @override
  DecoratedType visitMethodInvocation(MethodInvocation node) {
    DecoratedType targetType;
    if (node.target != null) {
      assert(node.operator.type == TokenType.PERIOD);
      _checkNonObjectMember(node.methodName.name); // TODO(paulberry)
      targetType = _handleAssignment(_notNullType, node.target);
    }
    var callee = node.methodName.staticElement;
    assert(callee != null); // TODO(paulberry)
    var calleeType = getOrComputeElementType(callee, targetType: targetType);
    // TODO(paulberry): substitute if necessary
    var arguments = node.argumentList.arguments;
    for (int i = 0; i < arguments.length; i++) {
      var expression = arguments[i];
      assert(expression is! NamedExpression); // TODO(paulberry)
      assert(calleeType.positionalParameters.length > i); // TODO(paulberry)
      _handleAssignment(calleeType.positionalParameters[i], expression);
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
    return DecoratedType(node.staticType, ConstraintVariable.always);
  }

  @override
  DecoratedType visitParenthesizedExpression(ParenthesizedExpression node) {
    return node.expression.accept(this);
  }

  @override
  DecoratedType visitReturnStatement(ReturnStatement node) {
    // TODO(paulberry): handle implicit return
    assert(node.expression != null); // TODO(paulberry)
    _handleAssignment(_currentFunctionType.returnType, node.expression);
    return null;
  }

  @override
  DecoratedType visitSimpleIdentifier(SimpleIdentifier node) {
    var staticElement = node.staticElement;
    if (staticElement is ParameterElement) {
      return getOrComputeElementType(staticElement);
    } else if (staticElement is ClassElement) {
      return _nonNullableTypeType;
    } else {
      // TODO(paulberry)
      throw new UnimplementedError('${staticElement.runtimeType}');
    }
  }

  @override
  DecoratedType visitThisExpression(ThisExpression node) {
    return DecoratedType(node.staticType, null);
  }

  @override
  DecoratedType visitThrowExpression(ThrowExpression node) {
    node.expression.accept(this);
    // TODO(paulberry): do we need to check the expression type?  I think not.
    return DecoratedType(node.staticType, null);
  }

  @override
  DecoratedType visitTypeName(TypeName typeName) {
    return DecoratedType(typeName.type, null);
  }

  /// Creates the necessary constraint(s) for an assignment from [sourceType] to
  /// [destinationType].  [expression] is the expression whose type is
  /// [sourceType]; it is the expression we will have to null-check in the case
  /// where a nullable source is assigned to a non-nullable destination.
  void _checkAssignment(DecoratedType destinationType, DecoratedType sourceType,
      Expression expression) {
    if (sourceType.nullable != null) {
      if (destinationType.nullable != null) {
        _recordConstraint(sourceType.nullable, destinationType.nullable);
      } else {
        assert(expression != null); // TODO(paulberry)
        var checkNotNull =
            _variables.checkNotNullForExpression(_source, expression);
        _recordConstraint(sourceType.nullable, checkNotNull);
        _variables.recordExpressionChecks(
            expression, ExpressionChecks(checkNotNull));
      }
    }
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
      DecoratedType destinationType, Expression expression) {
    var sourceType = expression.accept(this);
    _checkAssignment(destinationType, sourceType, expression);
    return sourceType;
  }

  /// Double checks that [type] is sufficiently simple for this naive prototype
  /// implementation.
  ///
  /// TODO(paulberry): get rid of this method and put the correct logic into the
  /// call sites.
  bool _isSimple(DecoratedType type) {
    if (type.type.isBottom) return true;
    if (type.type is! InterfaceType) return false;
    if ((type.type as InterfaceType).typeParameters.isNotEmpty) return false;
    return true;
  }

  /// Creates a constraint variable (if necessary) representing the nullability
  /// of [node], which is the disjunction of the nullabilities [a] and [b].
  ConstraintVariable _joinNullabilities(
      ConditionalExpression node, ConstraintVariable a, ConstraintVariable b) {
    if (a == null) return b;
    if (b == null) return a;
    if (identical(a, ConstraintVariable.always) ||
        identical(b, ConstraintVariable.always)) {
      return ConstraintVariable.always;
    }
    var result = _variables.nullableForExpression(node);
    _recordConstraint(a, result);
    _recordConstraint(b, result);
    _recordConstraint(result, ConstraintVariable.or(_constraints, a, b));
    return result;
  }

  /// Records a constraint having [condition] as its left hand side and
  /// [consequence] as its right hand side.  Any [_guards] are included in the
  /// left hand side.
  void _recordConstraint(
      ConstraintVariable condition, ConstraintVariable consequence) {
    _guards.add(condition);
    _recordFact(consequence);
    _guards.removeLast();
  }

  /// Records a constraint having [consequence] as its right hand side.  Any
  /// [_guards] are used as the right hand side.
  void _recordFact(ConstraintVariable consequence) {
    _constraints.record(_guards, consequence);
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

  /// If not `null`, the [ConstraintVariable] whose value must be `true` in
  /// order for [condition] to evaluate to `true`.
  final ConstraintVariable trueGuard;

  /// If not `null`, the [ConstraintVariable] whose value must be `true` in
  /// order for [condition] to evaluate to `false`.
  final ConstraintVariable falseGuard;

  /// If not `null`, the [ConstraintVariable] whose value should be set to
  /// `true` if [condition] is asserted to be `true`.
  final ConstraintVariable trueChecksNonNull;

  /// If not `null`, the [ConstraintVariable] whose value should be set to
  /// `true` if [condition] is asserted to be `false`.
  final ConstraintVariable falseChecksNonNull;

  _ConditionInfo(this.condition,
      {@required this.isPure,
      this.trueGuard,
      this.falseGuard,
      this.trueChecksNonNull,
      this.falseChecksNonNull});
}
