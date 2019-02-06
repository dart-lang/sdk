// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/nullability/conditional_discard.dart';
import 'package:analyzer/src/dart/nullability/decorated_type.dart';
import 'package:analyzer/src/dart/nullability/expression_checks.dart';
import 'package:analyzer/src/dart/nullability/unit_propagation.dart';
import 'package:analyzer/src/generated/source.dart';

/// Visitor that gathers constraint variables for nullability migration from
/// code to be migrated.
///
/// The return type of each `visit...` method is a [DecoratedType] indicating
/// the static type of the element declared by the visited node, along with the
/// constraint variables that will determine its nullability.  For `visit...`
/// methods that don't visit declarations, `null` will be returned.
class ConstraintVariableGatherer extends GeneralizingAstVisitor<DecoratedType> {
  /// Constraint variables and decorated types are stored here.
  final VariableRecorder _variables;

  /// The file being analyzed.
  final Source _source;

  /// If the parameters of a function or method are being visited, the
  /// [DecoratedType] of the corresponding function or method type.
  ///
  /// TODO(paulberry): should this be updated when we visit generic function
  /// type syntax?  How about when we visit old-style function-typed formal
  /// parameters?
  DecoratedType _currentFunctionType;

  ConstraintVariableGatherer(this._variables, this._source);

  /// Creates and stores a [DecoratedType] object corresponding to the given
  /// [type] AST, and returns it.
  DecoratedType decorateType(TypeAnnotation type) {
    return type == null
        // TODO(danrubel): Return something other than this
        // to indicate that we should insert a type for the declaration
        // that is missing a type reference.
        ? new DecoratedType(DynamicTypeImpl.instance, ConstraintVariable.always)
        : type.accept(this);
  }

  @override
  DecoratedType visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.parameter.accept(this);
    return null;
  }

  @override
  DecoratedType visitFormalParameter(FormalParameter node) {
    // Do not visit children
    // TODO(paulberry): handle all types of formal parameters
    // - NormalFormalParameter
    // - SimpleFormalParameter
    // - FieldFormalParameter
    // - FunctionTypedFormalParameter
    // - DefaultFormalParameter
    return null;
  }

  @override
  DecoratedType visitFunctionDeclaration(FunctionDeclaration node) {
    _handleExecutableDeclaration(node.declaredElement, node.returnType,
        node.functionExpression.parameters);
    return null;
  }

  @override
  DecoratedType visitMethodDeclaration(MethodDeclaration node) {
    _handleExecutableDeclaration(
        node.declaredElement, node.returnType, node.parameters);
    return null;
  }

  @override
  DecoratedType visitSimpleFormalParameter(SimpleFormalParameter node) {
    var type = decorateType(node.type);
    _variables.recordDecoratedElementType(node.declaredElement, type);
    assert(!node.declaredElement.isNamed); // TODO(paulberry)
    _currentFunctionType.positionalParameters.add(type);
    return null;
  }

  @override
  DecoratedType visitTypeAnnotation(TypeAnnotation node) {
    assert(node != null); // TODO(paulberry)
    assert(node is NamedType); // TODO(paulberry)
    var type = node.type;
    if (type.isVoid) return DecoratedType(type, ConstraintVariable.always);
    assert(
        type is InterfaceType || type is TypeParameterType); // TODO(paulberry)
    var typeArguments = const <DecoratedType>[];
    if (type is InterfaceType && type.typeParameters.isNotEmpty) {
      if (node is TypeName) {
        assert(node.typeArguments != null);
        typeArguments =
            node.typeArguments.arguments.map((t) => t.accept(this)).toList();
      } else {
        assert(false); // TODO(paulberry): is this possible?
      }
    }
    var nullable = node.question == null
        ? _variables.nullableForTypeAnnotation(_source, node)
        : ConstraintVariable.always;
    // TODO(paulberry): decide whether to assign a variable for nullAsserts
    var nullAsserts = null;
    var decoratedType = DecoratedType(type, nullable,
        nullAsserts: nullAsserts, typeArguments: typeArguments);
    _variables.recordDecoratedTypeAnnotation(node, decoratedType);
    return decoratedType;
  }

  @override
  DecoratedType visitTypeName(TypeName node) => visitTypeAnnotation(node);

  /// Common handling of function and method declarations.
  void _handleExecutableDeclaration(ExecutableElement declaredElement,
      TypeAnnotation returnType, FormalParameterList parameters) {
    var decoratedReturnType = decorateType(returnType);
    var previousFunctionType = _currentFunctionType;
    // TODO(paulberry): test that it's correct to use `null` for the nullability
    // of the function type
    var functionType = DecoratedType(declaredElement.type, null,
        returnType: decoratedReturnType, positionalParameters: []);
    _currentFunctionType = functionType;
    parameters.accept(this);
    _currentFunctionType = previousFunctionType;
    _variables.recordDecoratedElementType(declaredElement, functionType);
  }
}

/// Repository of constraint variables and decorated types corresponding to the
/// code being migrated.
///
/// This data structure records the results of the first pass of migration
/// ([ConstraintVariableGatherer], which finds all the variables that need to be
/// constrained).
abstract class VariableRecorder {
  /// Creates a constraint variable to represent whether the given [node] should
  /// be made nullable (by adding a `?` after it).
  ConstraintVariable nullableForTypeAnnotation(
      Source source, TypeAnnotation node);

  /// Associates decorated type information with the given [element].
  void recordDecoratedElementType(Element element, DecoratedType type);

  /// Associates decorated type information with the given [type] node.
  void recordDecoratedTypeAnnotation(TypeAnnotation node, DecoratedType type);
}

/// Repository of constraint variables and decorated types corresponding to the
/// code being migrated.
///
/// This data structure allows the second pass of migration
/// ([ConstraintGatherer], which builds all the constraints) to access the
/// results of the first ([ConstraintVariableGatherer], which finds all the
/// variables that need to be constrained).
abstract class VariableRepository {
  /// Creates a constraint variable to represent whether the given [expression]
  /// should be null-checked.
  ConstraintVariable checkNotNullForExpression(
      Source source, Expression expression);

  /// Retrieves the [DecoratedType] associated with the static type of the given
  /// [element].
  ///
  /// If [create] is `true`, and no decorated type is found for the given
  /// element, one is synthesized using [DecoratedType.forElement].
  DecoratedType decoratedElementType(Element element, {bool create: false});

  /// Creates a constraint variable to represent whether the static type of
  /// the given [expression] will be nullable after the migration.
  ConstraintVariable nullableForExpression(Expression expression);

  /// Records conditional discard information for the given AST node (which is
  /// an `if` statement or a conditional (`?:`) expression).
  void recordConditionalDiscard(
      Source source, AstNode node, ConditionalDiscard conditionalDiscard);

  /// Associates decorated type information with the given [element].
  ///
  /// TODO(paulberry): why is this in both [VariableRecorder] and
  /// [VariableRepository]?
  void recordDecoratedElementType(Element element, DecoratedType type);

  /// Associates decorated type information with the given expression [node].
  void recordDecoratedExpressionType(Expression node, DecoratedType type);

  /// Associates a set of nullability checks with the given expression [node].
  void recordExpressionChecks(Expression expression, ExpressionChecks checks);
}
