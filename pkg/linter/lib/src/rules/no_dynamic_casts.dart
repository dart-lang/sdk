// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Avoid implicit casts from `dynamic`.';

class NoDynamicCasts extends AnalysisRule {
  new()
    : super(
        name: LintNames.no_dynamic_casts,
        description: _desc,
        state: .stable(since: .new(3, 13, 0)),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.noDynamicCasts;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry
      ..addArgumentList(this, visitor)
      ..addAssignmentExpression(this, visitor)
      ..addBinaryExpression(this, visitor)
      ..addConditionalExpression(this, visitor)
      ..addDoStatement(this, visitor)
      ..addExpressionFunctionBody(this, visitor)
      ..addForEachPartsWithDeclaration(this, visitor)
      ..addForEachPartsWithIdentifier(this, visitor)
      ..addForEachPartsWithPattern(this, visitor)
      ..addForStatement(this, visitor)
      ..addIfElement(this, visitor)
      ..addIfStatement(this, visitor)
      ..addListLiteral(this, visitor)
      ..addPrefixExpression(this, visitor)
      ..addReturnStatement(this, visitor)
      ..addSetOrMapLiteral(this, visitor)
      ..addVariableDeclaration(this, visitor)
      ..addWhenClause(this, visitor)
      ..addWhileStatement(this, visitor)
      ..addYieldStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule _rule;
  final RuleContext _context;

  new(this._rule, this._context);

  @override
  void visitArgumentList(ArgumentList node) {
    for (var argument in node.arguments) {
      _check(
        argument.argumentExpression,
        argument.correspondingParameter?.type,
      );
    }
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _check(node.rightHandSide, node.writeType);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type == TokenType.AMPERSAND_AMPERSAND ||
        node.operator.type == TokenType.BAR_BAR) {
      _check(node.leftOperand, _context.typeProvider.boolType);
      _check(node.rightOperand, _context.typeProvider.boolType);
    }
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _check(node.condition, _context.typeProvider.boolType);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _check(node.condition, _context.typeProvider.boolType);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    var returnType = _getEnclosingReturnType(node);
    _check(node.expression, returnType);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _checkForEachParts(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    _checkForEachParts(node);
  }

  @override
  void visitForEachPartsWithPattern(ForEachPartsWithPattern node) {
    _checkForEachParts(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    if (node.forLoopParts case ForParts parts) {
      var condition = parts.condition;
      if (condition != null) {
        _check(condition, _context.typeProvider.boolType);
      }
    }
  }

  @override
  void visitIfElement(IfElement node) {
    _check(node.expression, _context.typeProvider.boolType);
  }

  @override
  void visitIfStatement(IfStatement node) {
    _check(node.expression, _context.typeProvider.boolType);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    var type = node.staticType;
    if (type case ParameterizedType(typeArguments: [var elementType])) {
      for (var element in node.elements) {
        _checkCollectionElement(element, elementType);
      }
    }
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (node.operator.type == TokenType.BANG) {
      _check(node.operand, _context.typeProvider.boolType);
    }
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    if (node.expression case var expression?) {
      var returnType = _getEnclosingReturnType(node);
      _check(expression, returnType);
    }
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    var type = node.staticType;
    if (type is! ParameterizedType) return;
    if (node.isSet && type.typeArguments.isNotEmpty) {
      var elementType = type.typeArguments[0];
      for (var element in node.elements) {
        _checkCollectionElement(element, elementType);
      }
    } else if (node.isMap && type.typeArguments.length == 2) {
      var keyType = type.typeArguments[0];
      var valueType = type.typeArguments[1];
      for (var element in node.elements) {
        _checkCollectionElementMap(element, keyType, valueType);
      }
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.initializer case var initializer?) {
      var parent = node.parent;
      if (parent case VariableDeclarationList(:var type?)) {
        _check(initializer, type.type);
      }
    }
  }

  @override
  void visitWhenClause(WhenClause node) {
    _check(node.expression, _context.typeProvider.boolType);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _check(node.condition, _context.typeProvider.boolType);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    var returnType = _getEnclosingReturnType(node);
    if (returnType == null) return;

    if (node.star != null) {
      _check(node.expression, returnType);
    } else {
      if (returnType case ParameterizedType(typeArguments: [var elementType])) {
        _check(node.expression, elementType);
      }
    }
  }

  /// Reports lint if [expression] is `dynamic`-typed and [targetType] is
  /// neither `dynamic` nor `Object?`.
  void _check(Expression expression, DartType? targetType) {
    if (targetType == null) return;

    var sourceType = expression.staticType;
    if (sourceType is! DynamicType) return;

    if (targetType is DynamicType) return;
    if (targetType == _context.typeProvider.objectQuestionType) return;

    // Ignore if the expression is an explicit cast.
    if (expression.unParenthesized is AsExpression) return;

    _rule.reportAtNode(expression);
  }

  /// Checks [element], as an element in a List or Set literal, for
  /// `dynamic`-typed sub-elements.
  void _checkCollectionElement(
    CollectionElement element,
    DartType elementType,
  ) {
    switch (element) {
      case Expression():
        _check(element, elementType);
      case IfElement():
        _checkCollectionElement(element.thenElement, elementType);
        if (element.elseElement case var elseElement?) {
          _checkCollectionElement(elseElement, elementType);
        }
      case ForElement():
        _checkCollectionElement(element.body, elementType);
      case SpreadElement():
        var expectedType = _context.typeProvider.iterableType(elementType);
        _check(element.expression, expectedType);
      default:
        break;
    }
  }

  /// Checks [element], as an element in a Map literal, for `dynamic`-typed
  /// sub-elements.
  void _checkCollectionElementMap(
    CollectionElement element,
    DartType keyType,
    DartType valueType,
  ) {
    switch (element) {
      case MapLiteralEntry():
        _check(element.key, keyType);
        _check(element.value, valueType);
      case IfElement():
        _checkCollectionElementMap(element.thenElement, keyType, valueType);
        if (element.elseElement case var elseElement?) {
          _checkCollectionElementMap(elseElement, keyType, valueType);
        }
      case ForElement():
        _checkCollectionElementMap(element.body, keyType, valueType);
      case SpreadElement():
        var expectedType = _context.typeProvider.mapType(keyType, valueType);
        _check(element.expression, expectedType);
      default:
        break;
    }
  }

  /// Checks [node] for `dynamic`-typed sub-expressions.
  void _checkForEachParts(ForEachParts node) {
    var forStatement = node.parent;
    if (forStatement is! ForStatement) return;
    var isAsync = forStatement.awaitKeyword != null;
    var targetType = isAsync
        ? _context.typeProvider.streamType(_context.typeProvider.dynamicType)
        : _context.typeProvider.iterableType(_context.typeProvider.dynamicType);
    _check(node.iterable, targetType);

    // Also check loop variable assignment.
    DartType? loopVarType;
    if (node is ForEachPartsWithDeclaration) {
      loopVarType = node.loopVariable.type?.type;
    } else if (node is ForEachPartsWithIdentifier) {
      loopVarType = node.identifier.staticType;
    }
    if (loopVarType == null) return;
    if (loopVarType is DynamicType || loopVarType is VoidType) return;

    var iterableType = node.iterable.staticType;
    DartType? elementType;
    if (iterableType is ParameterizedType &&
        iterableType.typeArguments.isNotEmpty) {
      elementType = iterableType.typeArguments[0];
    } else if (iterableType is DynamicType) {
      elementType = iterableType;
    }
    if (elementType is! DynamicType) return;
    if (loopVarType is DynamicType) return;
    if (loopVarType == _context.typeProvider.objectQuestionType) return;

    _rule.reportAtNode(node.iterable);
  }

  DartType? _getEnclosingReturnType(AstNode node) {
    var parent = node.thisOrAncestorMatching(
      (e) =>
          e is FunctionDeclaration ||
          e is MethodDeclaration ||
          e is ConstructorDeclaration ||
          e is FunctionExpression,
    );
    if (parent == null) return null;

    DartType? returnType;
    bool isAsync = false;

    if (parent is FunctionDeclaration) {
      returnType = parent.declaredFragment?.element.returnType;
      isAsync = parent.functionExpression.body.isAsynchronous;
    } else if (parent is MethodDeclaration) {
      returnType = parent.declaredFragment?.element.returnType;
      isAsync = parent.body.isAsynchronous;
    } else if (parent is ConstructorDeclaration) {
      returnType = parent.declaredFragment?.element.returnType;
    } else if (parent is FunctionExpression) {
      if (parent.staticType case FunctionType staticType) {
        returnType = staticType.returnType;
      }
      isAsync = parent.body.isAsynchronous;
    }

    if (returnType == null) return null;

    return isAsync ? _context.typeSystem.flatten(returnType) : returnType;
  }
}
