// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/nullability/conditional_discard.dart';
import 'package:analysis_server/src/nullability/decorated_type.dart';
import 'package:analysis_server/src/nullability/expression_checks.dart';
import 'package:analysis_server/src/nullability/nullability_node.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:front_end/src/scanner/token.dart';

/// Visitor that builds nullability nodes based on visiting code to be migrated.
///
/// The return type of each `visit...` method is a [DecoratedType] indicating
/// the static type of the element declared by the visited node, along with the
/// constraint variables that will determine its nullability.  For `visit...`
/// methods that don't visit declarations, `null` will be returned.
class NodeBuilder extends GeneralizingAstVisitor<DecoratedType> {
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

  final bool _permissive;

  final NullabilityGraph _graph;

  final TypeProvider _typeProvider;

  NodeBuilder(this._variables, this._source, this._permissive, this._graph,
      this._typeProvider);

  /// Creates and stores a [DecoratedType] object corresponding to the given
  /// [type] AST, and returns it.
  DecoratedType decorateType(TypeAnnotation type, AstNode enclosingNode) {
    return type == null
        // TODO(danrubel): Return something other than this
        // to indicate that we should insert a type for the declaration
        // that is missing a type reference.
        ? new DecoratedType(
            DynamicTypeImpl.instance,
            NullabilityNode.forInferredDynamicType(
                _graph, enclosingNode.offset))
        : type.accept(this);
  }

  @override
  DecoratedType visitDefaultFormalParameter(DefaultFormalParameter node) {
    var decoratedType = node.parameter.accept(this);
    if (node.declaredElement.hasRequired || node.defaultValue != null) {
      return null;
    }
    decoratedType.node.trackPossiblyOptional();
    _variables.recordPossiblyOptional(_source, node, decoratedType.node);
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
        node.functionExpression.parameters, node.functionExpression.body, node);
    return null;
  }

  @override
  DecoratedType visitMethodDeclaration(MethodDeclaration node) {
    _handleExecutableDeclaration(node.declaredElement, node.returnType,
        node.parameters, node.body, node);
    return null;
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
  DecoratedType visitSimpleFormalParameter(SimpleFormalParameter node) {
    var type = decorateType(node.type, node);
    var declaredElement = node.declaredElement;
    _variables.recordDecoratedElementType(declaredElement, type);
    if (declaredElement.isNamed) {
      _currentFunctionType.namedParameters[declaredElement.name] = type;
    } else {
      _currentFunctionType.positionalParameters.add(type);
    }
    return type;
  }

  @override
  DecoratedType visitTypeAnnotation(TypeAnnotation node) {
    assert(node != null); // TODO(paulberry)
    assert(node is NamedType); // TODO(paulberry)
    var type = node.type;
    if (type.isVoid) {
      return DecoratedType(
          type, NullabilityNode.forTypeAnnotation(node.end, always: true));
    }
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
    var decoratedType = DecoratedTypeAnnotation(
        type,
        NullabilityNode.forTypeAnnotation(node.end,
            always: node.question != null),
        node.end,
        typeArguments: typeArguments);
    _variables.recordDecoratedTypeAnnotation(_source, node, decoratedType);
    if (_isBangComment(node.endToken.next.precedingComments)) {
      _graph.connect(decoratedType.node, NullabilityNode.never, hard: true);
    }
    return decoratedType;
  }

  @override
  DecoratedType visitTypeName(TypeName node) => visitTypeAnnotation(node);

  @override
  DecoratedType visitTypeParameter(TypeParameter node) {
    var element = node.declaredElement;
    var decoratedBound = node.bound?.accept(this) ??
        DecoratedType(element.bound ?? _typeProvider.objectType,
            NullabilityNode.forInferredDynamicType(_graph, node.offset));
    _variables.recordDecoratedElementType(element, decoratedBound);
    return null;
  }

  @override
  DecoratedType visitVariableDeclarationList(VariableDeclarationList node) {
    var type = decorateType(node.type, node);
    for (var variable in node.variables) {
      _variables.recordDecoratedElementType(variable.declaredElement, type);
    }
    return null;
  }

  /// Common handling of function and method declarations.
  void _handleExecutableDeclaration(
      ExecutableElement declaredElement,
      TypeAnnotation returnType,
      FormalParameterList parameters,
      FunctionBody body,
      AstNode enclosingNode) {
    var decoratedReturnType = decorateType(returnType, enclosingNode);
    var previousFunctionType = _currentFunctionType;
    // TODO(paulberry): test that it's correct to use `null` for the nullability
    // of the function type
    var functionType = DecoratedType(
        declaredElement.type, NullabilityNode.never,
        returnType: decoratedReturnType,
        positionalParameters: [],
        namedParameters: {});
    _currentFunctionType = functionType;
    try {
      parameters?.accept(this);
      body?.accept(this);
    } finally {
      _currentFunctionType = previousFunctionType;
    }
    _variables.recordDecoratedElementType(declaredElement, functionType);
  }

  bool _isBangComment(Token token) {
    if (token is CommentToken) {
      if (token.lexeme == '/*!*/') return true;
    }
    return false;
  }
}

/// Repository of constraint variables and decorated types corresponding to the
/// code being migrated.
///
/// This data structure records the results of the first pass of migration
/// ([NodeBuilder], which finds all the variables that need to be
/// constrained).
abstract class VariableRecorder {
  /// Associates decorated type information with the given [element].
  void recordDecoratedElementType(Element element, DecoratedType type);

  /// Associates decorated type information with the given [type] node.
  void recordDecoratedTypeAnnotation(
      Source source, TypeAnnotation node, DecoratedTypeAnnotation type);

  /// Records that [node] is associated with the question of whether the named
  /// [parameter] should be optional (should not have a `required`
  /// annotation added to it).
  void recordPossiblyOptional(
      Source source, DefaultFormalParameter parameter, NullabilityNode node);
}

/// Repository of constraint variables and decorated types corresponding to the
/// code being migrated.
///
/// This data structure allows the second pass of migration
/// ([ConstraintGatherer], which builds all the constraints) to access the
/// results of the first ([NodeBuilder], which finds all the
/// variables that need to be constrained).
abstract class VariableRepository {
  /// Retrieves the [DecoratedType] associated with the static type of the given
  /// [element].
  ///
  /// If [create] is `true`, and no decorated type is found for the given
  /// element, one is synthesized using [DecoratedType.forElement].
  DecoratedType decoratedElementType(Element element, {bool create: false});

  /// Gets the [DecoratedType] associated with the given [typeAnnotation].
  DecoratedType decoratedTypeAnnotation(
      Source source, TypeAnnotation typeAnnotation);

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
  void recordExpressionChecks(
      Source source, Expression expression, ExpressionChecks checks);
}
