// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/variable_type_provider.dart';

/// Instances of the class `TypePromotionManager` manage the ability to promote
/// types of local variables and formal parameters from their declared types
/// based on control flow.
class TypePromotionManager {
  final TypeSystemImpl _typeSystem;

  /// The current promotion scope, or `null` if no scope has been entered.
  _TypePromoteScope _currentScope;

  final List<FunctionBody> _functionBodyStack = [];

  /// Body of the function currently being analyzed, if any.
  FunctionBody _currentFunctionBody;

  TypePromotionManager(this._typeSystem);

  LocalVariableTypeProvider get localVariableTypeProvider {
    return _LegacyLocalVariableTypeProvider(this);
  }

  /// Returns the elements with promoted types.
  Iterable<Element> get _promotedElements {
    return _currentScope.promotedElements;
  }

  void enterFunctionBody(FunctionBody body) {
    _functionBodyStack.add(_currentFunctionBody);
    _currentFunctionBody = body;
  }

  void exitFunctionBody() {
    if (_functionBodyStack.isEmpty) {
      assert(false, 'exitFunctionBody without a matching enterFunctionBody');
    } else {
      _currentFunctionBody = _functionBodyStack.removeLast();
    }
  }

  void visitBinaryExpression_and_rhs(
      Expression leftOperand, Expression rightOperand, void Function() f) {
    if (rightOperand != null) {
      _enterScope();
      try {
        // Type promotion.
        _promoteTypes(leftOperand);
        _clearTypePromotionsIfPotentiallyMutatedIn(leftOperand);
        _clearTypePromotionsIfPotentiallyMutatedIn(rightOperand);
        _clearTypePromotionsIfAccessedInClosureAndPotentiallyMutated(
            rightOperand);
        // Visit right operand.
        f();
      } finally {
        _exitScope();
      }
    }
  }

  void visitConditionalExpression_then(
      Expression condition, Expression thenExpression, void Function() f) {
    if (thenExpression != null) {
      _enterScope();
      try {
        // Type promotion.
        _promoteTypes(condition);
        _clearTypePromotionsIfPotentiallyMutatedIn(thenExpression);
        _clearTypePromotionsIfAccessedInClosureAndPotentiallyMutated(
          thenExpression,
        );
        // Visit "then" expression.
        f();
      } finally {
        _exitScope();
      }
    }
  }

  void visitIfElement_thenElement(
      Expression condition, CollectionElement thenElement, void Function() f) {
    if (thenElement != null) {
      _enterScope();
      try {
        // Type promotion.
        _promoteTypes(condition);
        _clearTypePromotionsIfPotentiallyMutatedIn(thenElement);
        _clearTypePromotionsIfAccessedInClosureAndPotentiallyMutated(
            thenElement);
        // Visit "then".
        f();
      } finally {
        _exitScope();
      }
    }
  }

  void visitIfStatement_thenStatement(
      Expression condition, Statement thenStatement, void Function() f) {
    if (thenStatement != null) {
      _enterScope();
      try {
        // Type promotion.
        _promoteTypes(condition);
        _clearTypePromotionsIfPotentiallyMutatedIn(thenStatement);
        _clearTypePromotionsIfAccessedInClosureAndPotentiallyMutated(
            thenStatement);
        // Visit "then".
        f();
      } finally {
        _exitScope();
      }
    }
  }

  /// Checks each promoted variable in the current scope for compliance with the
  /// following specification statement:
  ///
  /// If the variable <i>v</i> is accessed by a closure in <i>s<sub>1</sub></i>
  /// then the variable <i>v</i> is not potentially mutated anywhere in the
  /// scope of <i>v</i>.
  void _clearTypePromotionsIfAccessedInClosureAndPotentiallyMutated(
      AstNode target) {
    for (Element element in _promotedElements) {
      if (_currentFunctionBody
          .isPotentiallyMutatedInScope(element as VariableElement)) {
        if (_isVariableAccessedInClosure(element, target)) {
          _setType(element, null);
        }
      }
    }
  }

  /// Checks each promoted variable in the current scope for compliance with the
  /// following specification statement:
  ///
  /// <i>v</i> is not potentially mutated in <i>s<sub>1</sub></i> or within a
  /// closure.
  void _clearTypePromotionsIfPotentiallyMutatedIn(AstNode target) {
    for (Element element in _promotedElements) {
      if (_isVariablePotentiallyMutatedIn(element, target)) {
        _setType(element, null);
      }
    }
  }

  /// Enter a new promotions scope.
  void _enterScope() {
    _currentScope = _TypePromoteScope(_currentScope);
  }

  /// Exit the current promotion scope.
  void _exitScope() {
    if (_currentScope == null) {
      throw StateError("No scope to exit");
    }
    _currentScope = _currentScope._outerScope;
  }

  /// Return the promoted type of the given [element], or `null` if the type of
  /// the element has not been promoted.
  DartType _getPromotedType(Element element) {
    return _currentScope?.getType(element);
  }

  /// Return the static element associated with the given expression whose type
  /// can be promoted, or `null` if there is no element whose type can be
  /// promoted.
  VariableElement _getPromotionStaticElement(Expression expression) {
    expression = expression?.unParenthesized;
    if (expression is SimpleIdentifier) {
      Element element = expression.staticElement;
      if (element is VariableElement) {
        ElementKind kind = element.kind;
        if (kind == ElementKind.LOCAL_VARIABLE ||
            kind == ElementKind.PARAMETER) {
          return element;
        }
      }
    }
    return null;
  }

  /// Given that the [node] is a reference to a [VariableElement], return the
  /// static type of the variable at this node - declared or promoted.
  DartType _getType(SimpleIdentifier node) {
    var variable = node.staticElement as VariableElement;
    return _getPromotedType(variable) ?? variable.type;
  }

  /// Return `true` if the given variable is accessed within a closure in the
  /// given [AstNode] and also mutated somewhere in variable scope. This
  /// information is only available for local variables (including parameters).
  ///
  /// @param variable the variable to check
  /// @param target the [AstNode] to check within
  /// @return `true` if this variable is potentially mutated somewhere in the
  ///         given ASTNode
  bool _isVariableAccessedInClosure(Element variable, AstNode target) {
    _ResolverVisitor_isVariableAccessedInClosure visitor =
        _ResolverVisitor_isVariableAccessedInClosure(variable);
    target.accept(visitor);
    return visitor.result;
  }

  /// Return `true` if the given variable is potentially mutated somewhere in
  /// the given [AstNode]. This information is only available for local
  /// variables (including parameters).
  ///
  /// @param variable the variable to check
  /// @param target the [AstNode] to check within
  /// @return `true` if this variable is potentially mutated somewhere in the
  ///         given ASTNode
  bool _isVariablePotentiallyMutatedIn(Element variable, AstNode target) {
    _ResolverVisitor_isVariablePotentiallyMutatedIn visitor =
        _ResolverVisitor_isVariablePotentiallyMutatedIn(variable);
    target.accept(visitor);
    return visitor.result;
  }

  /// If it is appropriate to do so, promotes the current type of the static
  /// element associated with the given expression with the given type.
  /// Generally speaking, it is appropriate if the given type is more specific
  /// than the current type.
  ///
  /// @param expression the expression used to access the static element whose
  ///        types might be promoted
  /// @param potentialType the potential type of the elements
  void _promote(Expression expression, DartType potentialType) {
    VariableElement element = _getPromotionStaticElement(expression);
    if (element != null) {
      // may be mutated somewhere in closure
      if (_currentFunctionBody.isPotentiallyMutatedInClosure(element)) {
        return;
      }
      // prepare current variable type
      DartType type = _getPromotedType(element) ??
          expression.staticType ??
          DynamicTypeImpl.instance;

      potentialType ??= DynamicTypeImpl.instance;

      // Check if we can promote to potentialType from type.
      DartType promoteType = _typeSystem.tryPromoteToType(potentialType, type);
      if (promoteType != null) {
        // Do promote type of variable.
        _setType(element, promoteType);
      }
    }
  }

  /// Promotes type information using given condition.
  void _promoteTypes(Expression condition) {
    if (condition is BinaryExpression) {
      if (condition.operator.type == TokenType.AMPERSAND_AMPERSAND) {
        Expression left = condition.leftOperand;
        Expression right = condition.rightOperand;
        _promoteTypes(left);
        _promoteTypes(right);
        _clearTypePromotionsIfPotentiallyMutatedIn(right);
      }
    } else if (condition is IsExpression) {
      if (condition.notOperator == null) {
        _promote(condition.expression, condition.type.type);
      }
    } else if (condition is ParenthesizedExpression) {
      _promoteTypes(condition.expression);
    }
  }

  /// Set the promoted type of the given element to the given type.
  ///
  /// @param element the element whose type might have been promoted
  /// @param type the promoted type of the given element
  void _setType(Element element, DartType type) {
    if (_currentScope == null) {
      throw StateError("Cannot promote without a scope");
    }
    _currentScope.setType(element, type);
  }
}

/// The legacy, pre-NNBD implementation of [LocalVariableTypeProvider].
class _LegacyLocalVariableTypeProvider implements LocalVariableTypeProvider {
  final TypePromotionManager _manager;

  _LegacyLocalVariableTypeProvider(this._manager);

  @override
  DartType getType(SimpleIdentifier node) {
    return _manager._getType(node);
  }
}

class _ResolverVisitor_isVariableAccessedInClosure
    extends RecursiveAstVisitor<void> {
  final Element variable;

  bool result = false;

  bool _inClosure = false;

  _ResolverVisitor_isVariableAccessedInClosure(this.variable);

  @override
  void visitFunctionExpression(FunctionExpression node) {
    bool inClosure = _inClosure;
    try {
      _inClosure = true;
      super.visitFunctionExpression(node);
    } finally {
      _inClosure = inClosure;
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (result) {
      return;
    }
    if (_inClosure && identical(node.staticElement, variable)) {
      result = true;
    }
  }
}

class _ResolverVisitor_isVariablePotentiallyMutatedIn
    extends RecursiveAstVisitor<void> {
  final Element variable;

  bool result = false;

  _ResolverVisitor_isVariablePotentiallyMutatedIn(this.variable);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (result) {
      return;
    }
    if (identical(node.staticElement, variable)) {
      if (node.inSetterContext()) {
        result = true;
      }
    }
  }
}

/// Instances of the class `TypePromoteScope` represent a scope in which the
/// types of elements can be promoted.
class _TypePromoteScope {
  /// The outer scope in which types might be promoter.
  final _TypePromoteScope _outerScope;

  /// A table mapping elements to the promoted type of that element.
  final Map<Element, DartType> _promotedTypes = {};

  /// Initialize a newly created scope to be an empty child of the given scope.
  ///
  /// @param outerScope the outer scope in which types might be promoted
  _TypePromoteScope(this._outerScope);

  /// Returns the elements with promoted types.
  Iterable<Element> get promotedElements => _promotedTypes.keys.toSet();

  /// Return the promoted type of the given element, or `null` if the type of
  /// the element has not been promoted.
  ///
  /// @param element the element whose type might have been promoted
  /// @return the promoted type of the given element
  DartType getType(Element element) {
    DartType type = _promotedTypes[element];
    if (type == null && element is PropertyAccessorElement) {
      type = _promotedTypes[element.variable];
    }
    if (type != null) {
      return type;
    } else if (_outerScope != null) {
      return _outerScope.getType(element);
    }
    return null;
  }

  /// Set the promoted type of the given element to the given type.
  ///
  /// @param element the element whose type might have been promoted
  /// @param type the promoted type of the given element
  void setType(Element element, DartType type) {
    _promotedTypes[element] = type;
  }
}
