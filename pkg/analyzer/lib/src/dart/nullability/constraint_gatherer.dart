// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/nullability/conditional_discard.dart';
import 'package:analyzer/src/dart/nullability/constraint_variable_gatherer.dart';
import 'package:analyzer/src/dart/nullability/decorated_substitution.dart';
import 'package:analyzer/src/dart/nullability/decorated_type.dart';
import 'package:analyzer/src/dart/nullability/expression_checks.dart';
import 'package:analyzer/src/dart/nullability/unit_propagation.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:meta/meta.dart';

class ConstraintGatherer extends GeneralizingAstVisitor<DecoratedType> {
  final Variables _variables;
  final Constraints _constraints;
  final DecoratedType _notNullType;
  final DecoratedType _nonNullableBoolType;

  DecoratedType _currentFunctionType;

  _ConditionInfo _conditionInfo;

  final _guards = <ConstraintVariable>[];

  ConstraintGatherer(
      TypeProvider typeProvider, this._variables, this._constraints)
      : _notNullType = DecoratedType(typeProvider.objectType, null),
        _nonNullableBoolType = DecoratedType(typeProvider.boolType, null) {}

  DecoratedType getOrComputeElementType(Element element,
      {DecoratedType targetType}) {
    DecoratedSubstitution substitution;
    Element baseElement;
    if (element is Member) {
      assert(targetType != null);
      baseElement = element.baseElement;
      var targetTypeType = targetType.type;
      if (targetTypeType is InterfaceType &&
          baseElement is ClassMemberElement) {
        var enclosingClass = baseElement.enclosingElement;
        assert(targetTypeType.element == enclosingClass); // TODO(paulberry)
        var replacements = <TypeParameterElement, DecoratedType>{};
        assert(enclosingClass.typeParameters.length ==
            targetTypeType.typeArguments.length); // TODO(paulberry)
        for (int i = 0; i < enclosingClass.typeParameters.length; i++) {
          replacements[enclosingClass.typeParameters[i]] =
              targetType.typeArguments[i];
        }
        substitution = DecoratedSubstitution(replacements);
      }
    } else {
      baseElement = element;
    }
    var decoratedBaseType = _variables.decoratedElementType(baseElement);
    if (decoratedBaseType == null) {
      DecoratedType decorate(DartType type) {
        assert((type as TypeImpl).nullability ==
            Nullability.indeterminate); // TODO(paulberry)
        if (type is FunctionType) {
          var decoratedType = DecoratedType(type, null,
              returnType: decorate(type.returnType), positionalParameters: []);
          for (var parameter in type.parameters) {
            assert(parameter.isPositional); // TODO(paulberry)
            decoratedType.positionalParameters.add(decorate(parameter.type));
          }
          return decoratedType;
        } else if (type is InterfaceType) {
          assert(type.typeParameters.isEmpty); // TODO(paulberry)
          return DecoratedType(type, null);
        } else {
          throw type.runtimeType; // TODO(paulberry)
        }
      }

      if (baseElement is MethodElement) {
        decoratedBaseType = decorate(baseElement.type);
      } else {
        throw baseElement.runtimeType; // TODO(paulberry)
      }
      _variables.recordDecoratedElementType(baseElement, decoratedBaseType);
    }
    if (substitution != null) {
      DartType elementType;
      if (element is MethodElement) {
        elementType = element.type;
      } else {
        throw element.runtimeType; // TODO(paulberry)
      }
      return substitution.apply(decoratedBaseType, elementType);
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
    _handleAssignment(_notNullType, node.condition); // TODO(paulberry): test
    ConstraintVariable trueGuard;
    ConstraintVariable falseGuard;
    if (identical(_conditionInfo?.condition, node.condition)) {
      trueGuard = _conditionInfo.trueGuard;
      falseGuard = _conditionInfo.falseGuard;
      _variables.recordConditionalDiscard(
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
    // TODO(paulberry): test
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
  DecoratedType visitNullLiteral(NullLiteral node) {
    return DecoratedType(node.staticType, ConstraintVariable.always);
  }

  @override
  DecoratedType visitParenthesizedExpression(ParenthesizedExpression node) {
    // TODO(paulberry): test directly
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
    assert(staticElement is ParameterElement); // TODO(paulberry)
    return getOrComputeElementType(staticElement);
  }

  @override
  DecoratedType visitThisExpression(ThisExpression node) {
    return DecoratedType(node.staticType, null);
  }

  @override
  DecoratedType visitThrowExpression(ThrowExpression node) {
    // TODO(paulberry): test directly
    node.expression.accept(this);
    // TODO(paulberry): do we need to check the expression type?  I think not.
    return DecoratedType(node.staticType, null);
  }

  @override
  DecoratedType visitTypeName(TypeName typeName) {
    // TODO(paulberry): test
    return DecoratedType(typeName.type, null);
  }

  _checkAssignment(DecoratedType destinationType, DecoratedType sourceType,
      Expression expression) {
    if (sourceType.nullable != null) {
      if (destinationType.nullable != null) {
        _recordConstraint(sourceType.nullable, destinationType.nullable);
      } else {
        assert(expression != null); // TODO(paulberry)
        var checkNotNull = _variables.checkNotNullForExpression(expression);
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

  void _checkNonObjectMember(String name) {
    assert(name != 'toString');
    assert(name != 'hashCode');
    assert(name != 'noSuchMethod');
    assert(name != 'runtimeType');
  }

  DecoratedType _handleAssignment(
      DecoratedType destinationType, Expression expression) {
    var sourceType = expression.accept(this);
    _checkAssignment(destinationType, sourceType, expression);
    return sourceType;
  }

  bool _isSimple(DecoratedType type) {
    if (type.type.isBottom) return true;
    if (type.type is! InterfaceType) return false;
    if ((type.type as InterfaceType).typeParameters.isNotEmpty) return false;
    return true;
  }

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
    _recordConstraint(result, ConstraintVariable.or(a, b));
    return result;
  }

  void _recordConstraint(
      ConstraintVariable condition, ConstraintVariable consequence) {
    _guards.add(condition);
    _recordFact(consequence);
    _guards.removeLast();
  }

  void _recordFact(ConstraintVariable consequence) {
    _constraints.record(_guards, consequence);
  }
}

class _ConditionInfo {
  final Expression condition;

  final bool isPure;

  final ConstraintVariable trueGuard;

  final ConstraintVariable falseGuard;

  final ConstraintVariable trueChecksNonNull;

  final ConstraintVariable falseChecksNonNull;

  _ConditionInfo(this.condition,
      {@required this.isPure,
      this.trueGuard,
      this.falseGuard,
      this.trueChecksNonNull,
      this.falseChecksNonNull});
}
