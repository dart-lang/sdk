// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:front_end/src/fasta/flow_analysis/flow_analysis.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/src/decorated_class_hierarchy.dart';
import 'package:nnbd_migration/src/variables.dart';

/// This class visits the AST of code being migrated, after graph propagation,
/// to figure out what changes need to be made to the code.  It doesn't actually
/// make the changes; it simply reports what changes are necessary through
/// abstract methods.
abstract class FixBuilder extends GeneralizingAstVisitor<DartType> {
  /// The decorated class hierarchy for this migration run.
  final DecoratedClassHierarchy _decoratedClassHierarchy;

  /// Type provider providing non-nullable types.
  final TypeProvider _typeProvider;

  /// The type system.
  final TypeSystem _typeSystem;

  /// Variables for this migration run.
  final Variables _variables;

  /// If we are visiting a function body or initializer, instance of flow
  /// analysis.  Otherwise `null`.
  FlowAnalysis<Statement, Expression, PromotableElement, DartType>
      _flowAnalysis;

  /// If we are visiting a function body or initializer, assigned variable
  /// information  used in flow analysis.  Otherwise `null`.
  AssignedVariables<AstNode, VariableElement> _assignedVariables;

  /// If we are visiting a subexpression, the context type used for type
  /// inference.  This is used to determine when `!` needs to be inserted.
  DartType _contextType;

  FixBuilder(this._decoratedClassHierarchy, TypeProvider typeProvider,
      this._typeSystem, this._variables)
      : _typeProvider = (typeProvider as TypeProviderImpl)
            .withNullability(NullabilitySuffix.none);

  /// Called whenever an expression is found for which a `!` needs to be
  /// inserted.
  void addNullCheck(Expression subexpression);

  /// Initializes flow analysis for a function node.
  void createFlowAnalysis(AstNode node) {
    assert(_flowAnalysis == null);
    assert(_assignedVariables == null);
    _flowAnalysis =
        FlowAnalysis<Statement, Expression, PromotableElement, DartType>(
            const AnalyzerNodeOperations(),
            TypeSystemTypeOperations(_typeSystem),
            AnalyzerFunctionBodyAccess(node is FunctionBody ? node : null));
    _assignedVariables = FlowAnalysisHelper.computeAssignedVariables(node);
  }

  @override
  DartType visitBinaryExpression(BinaryExpression node) {
    var leftOperand = node.leftOperand;
    var rightOperand = node.rightOperand;
    var operatorType = node.operator.type;
    var staticElement = node.staticElement;
    switch (operatorType) {
      case TokenType.BANG_EQ:
      case TokenType.EQ_EQ:
        visitSubexpression(leftOperand, _typeProvider.dynamicType);
        visitSubexpression(rightOperand, _typeProvider.dynamicType);
        if (leftOperand is SimpleIdentifier && rightOperand is NullLiteral) {
          var leftElement = leftOperand.staticElement;
          if (leftElement is PromotableElement) {
            _flowAnalysis.conditionEqNull(node, leftElement,
                notEqual: operatorType == TokenType.BANG_EQ);
          }
        }
        return _typeProvider.boolType;
      case TokenType.AMPERSAND_AMPERSAND:
      case TokenType.BAR_BAR:
        var isAnd = operatorType == TokenType.AMPERSAND_AMPERSAND;
        visitSubexpression(leftOperand, _typeProvider.boolType);
        _flowAnalysis.logicalBinaryOp_rightBegin(leftOperand, isAnd: isAnd);
        visitSubexpression(rightOperand, _typeProvider.boolType);
        _flowAnalysis.logicalBinaryOp_end(node, rightOperand, isAnd: isAnd);
        return _typeProvider.boolType;
      case TokenType.QUESTION_QUESTION:
        // If `a ?? b` is used in a non-nullable context, we don't want to
        // migrate it to `(a ?? b)!`.  We want to migrate it to `a ?? b!`.
        // TODO(paulberry): once flow analysis supports `??`, integrate it here.
        var leftType = visitSubexpression(node.leftOperand,
            _typeSystem.makeNullable(_contextType as TypeImpl));
        var rightType = visitSubexpression(node.rightOperand, _contextType);
        return _typeSystem.leastUpperBound(
            _typeSystem.promoteToNonNull(leftType as TypeImpl), rightType);
      default:
        var targetType =
            visitSubexpression(leftOperand, _typeProvider.objectType);
        DartType contextType;
        DartType returnType;
        if (staticElement == null) {
          contextType = _typeProvider.dynamicType;
          returnType = _typeProvider.dynamicType;
        } else {
          var methodType =
              _computeMigratedType(staticElement, targetType: targetType)
                  as FunctionType;
          contextType = methodType.parameters[0].type;
          returnType = methodType.returnType;
        }
        visitSubexpression(rightOperand, contextType);
        return _fixNumericTypes(returnType, node.staticType);
    }
  }

  @override
  DartType visitExpression(Expression node) {
    // Every expression type needs its own visit method.
    throw UnimplementedError('No visit method for ${node.runtimeType}');
  }

  @override
  DartType visitLiteral(Literal node) {
    if (node is AdjacentStrings) {
      // TODO(paulberry): need to visit interpolations
      throw UnimplementedError('TODO(paulberry)');
    }
    if (node is TypedLiteral) {
      throw UnimplementedError('TODO(paulberry)');
    }
    return (node.staticType as TypeImpl)
        .withNullability(NullabilitySuffix.none);
  }

  @override
  DartType visitParenthesizedExpression(ParenthesizedExpression node) {
    return node.expression.accept(this);
  }

  @override
  DartType visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.staticElement;
    if (element == null) return _typeProvider.dynamicType;
    if (element is PromotableElement) {
      var promotedType = _flowAnalysis.promotedType(element);
      if (promotedType != null) return promotedType;
    }
    return _computeMigratedType(element);
  }

  /// Recursively visits a subexpression, providing a context type.
  DartType visitSubexpression(Expression subexpression, DartType contextType) {
    var oldContextType = _contextType;
    try {
      _contextType = contextType;
      var type = subexpression.accept(this);
      if (_doesAssignmentNeedCheck(from: type, to: contextType)) {
        addNullCheck(subexpression);
        return _typeSystem.promoteToNonNull(type as TypeImpl);
      } else {
        return type;
      }
    } finally {
      _contextType = oldContextType;
    }
  }

  /// Computes the type that [element] will have after migration.
  ///
  /// If [targetType] is present, and [element] is a class member, it is the
  /// type of the class within which [element] is being accessed; this is used
  /// to perform the correct substitutions.
  DartType _computeMigratedType(Element element, {DartType targetType}) {
    Element baseElement;
    if (element is Member) {
      assert(targetType != null);
      baseElement = element.baseElement;
    } else {
      baseElement = element;
    }
    DartType type;
    if (baseElement is ClassElement || baseElement is TypeParameterElement) {
      return _typeProvider.typeType;
    } else if (baseElement is PropertyAccessorElement) {
      if (baseElement.isSynthetic) {
        type = _variables
            .decoratedElementType(baseElement.variable)
            .toFinalType(_typeProvider);
      } else {
        var functionType = _variables.decoratedElementType(baseElement);
        var decoratedType = baseElement.isGetter
            ? functionType.returnType
            : throw UnimplementedError('TODO(paulberry)');
        type = decoratedType.toFinalType(_typeProvider);
      }
    } else {
      type = _variables
          .decoratedElementType(baseElement)
          .toFinalType(_typeProvider);
    }
    if (targetType is InterfaceType && targetType.typeArguments.isNotEmpty) {
      var superclass = baseElement.enclosingElement as ClassElement;
      var class_ = targetType.element;
      if (class_ != superclass) {
        var supertype = _decoratedClassHierarchy
            .getDecoratedSupertype(class_, superclass)
            .toFinalType(_typeProvider) as InterfaceType;
        type = Substitution.fromInterfaceType(supertype).substituteType(type);
      }
      return substitute(type, {
        for (int i = 0; i < targetType.typeArguments.length; i++)
          class_.typeParameters[i]: targetType.typeArguments[i]
      });
    } else {
      return type;
    }
  }

  /// Determines whether a null check is needed when assigning a value of type
  /// [from] to a context of type [to].
  bool _doesAssignmentNeedCheck(
      {@required DartType from, @required DartType to}) {
    return !from.isDynamic &&
        _typeSystem.isNullable(from) &&
        !_typeSystem.isNullable(to);
  }

  /// Determines whether a `num` type originating from a call to a
  /// user-definable operator needs to be changed to `int`.  [type] is the type
  /// determined by naive operator lookup; [originalType] is the type that was
  /// determined by the analyzer's full resolution algorithm when analyzing the
  /// pre-migrated code.
  DartType _fixNumericTypes(DartType type, DartType originalType) {
    if (type.isDartCoreNum && originalType.isDartCoreInt) {
      return (originalType as TypeImpl)
          .withNullability((type as TypeImpl).nullabilitySuffix);
    } else {
      return type;
    }
  }
}
