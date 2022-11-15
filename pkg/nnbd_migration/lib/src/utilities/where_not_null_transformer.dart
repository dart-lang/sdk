// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/nullability_node.dart';

/// Information about a method call that we might want to transform into a call
/// to `whereNotNull` counterpart.  See [WhereNotNullTransformer] for more
/// information.
class WhereNotNullTransformationInfo {
  /// AST node of the method invocation.
  final MethodInvocation methodInvocation;

  /// AST node of the argument of the method invocation.
  final Expression argument;

  /// Original name of the method being called, prior to transformation.
  final String originalName;

  WhereNotNullTransformationInfo(
      this.methodInvocation, this.argument, this.originalName);

  /// New method to call, after transformation.
  String get replacementName => 'whereNotNull';
}

/// Methods to assist in transforming calls to the `Iterable` method `where`
/// into calls to the `package:collection` method `whereNotNull`, where
/// possible.
///
/// An example of the kind of code that can be transformed is:
///
///     Iterable<int> f(List<int/*?*/> x) => x.where((y) => y != null);
///
/// We transform this into:
///
///     Iterable<int> f(List<int?> x) => x.whereNotNull();
///
/// Without this transformation, the migrated result would have been:
///
///     Iterable<int?> f(List<int/*?*/> x) => x.where((y) => y != null);
///
/// Which would have placed an otherwise unnecessary requirement on callers to
/// handle `null` values in the resulting iterable.
class WhereNotNullTransformer {
  final TypeProvider _typeProvider;

  final TypeSystem _typeSystem;

  WhereNotNullTransformer(this._typeProvider, this._typeSystem);

  /// Transforms the [DecoratedType] of an invocation of `.where` to the
  /// [DecoratedType] of the corresponding invocation of `.whereNotNull` that
  /// will replace it.
  ///
  /// The transformation is that the type argument to `Iterable` is made
  /// non-nullable, so that nullability doesn't unnecessarily propagate to other
  /// parts of the code.
  DecoratedType transformDecoratedInvocationType(
      DecoratedType decoratedType, NullabilityGraph graph) {
    var type = decoratedType.type;
    var typeArguments = decoratedType.typeArguments;
    if (type is InterfaceType &&
        type.element == _typeProvider.iterableElement &&
        typeArguments.length == 1) {
      return DecoratedType(type, decoratedType.node,
          typeArguments: [typeArguments.single?.withNode(graph.never)]);
    }
    return decoratedType;
  }

  /// Transforms the post-migration type of an invocation of `.where` to the
  /// type of the corresponding invocation of `.whereNotNull` that will replace
  /// it.
  ///
  /// The transformation is that the type argument to `Iterable` is made
  /// non-nullable, so that we don't try to introduce any unnecessary null
  /// checks or type casts in other parts of the code.
  DartType transformPostMigrationInvocationType(DartType type) {
    if (type is InterfaceType &&
        type.element == _typeProvider.iterableElement) {
      var typeArguments = type.typeArguments;
      if (typeArguments.length == 1) {
        return InterfaceTypeImpl(
            element: type.element,
            typeArguments: [_typeSystem.promoteToNonNull(typeArguments.single)],
            nullabilitySuffix: type.nullabilitySuffix);
      }
    }
    return type;
  }

  /// If [node] is a call that can be transformed, returns information about the
  /// transformable call; otherwise returns `null`.
  WhereNotNullTransformationInfo? tryTransformMethodInvocation(AstNode? node) {
    if (node is MethodInvocation) {
      if (!_isTransformableMethod(node.methodName.staticElement)) return null;
      var arguments = node.argumentList.arguments;
      if (arguments.length != 1) return null;
      var argument = arguments[0];
      if (!_isClosureCheckingNotNull(argument)) return null;
      return WhereNotNullTransformationInfo(
          node, argument, node.methodName.name);
    }
    return null;
  }

  /// Checks whether [expression] is of the form `(x) => x != null`.
  bool _isClosureCheckingNotNull(Expression expression) {
    if (expression is! FunctionExpression) return false;
    if (expression.typeParameters != null) return false;
    var parameters = expression.parameters!.parameters;
    if (parameters.length != 1) return false;
    var parameter = parameters[0];
    if (parameter.isNamed) return false;
    var body = expression.body;
    if (body is! ExpressionFunctionBody) return false;
    var returnedExpression = body.expression;
    if (returnedExpression is! BinaryExpression) return false;
    if (returnedExpression.operator.type != TokenType.BANG_EQ) return false;
    var lhs = returnedExpression.leftOperand;
    if (lhs is! SimpleIdentifier) return false;
    if (lhs.staticElement != parameter.declaredElement) return false;
    if (returnedExpression.rightOperand is! NullLiteral) return false;
    return true;
  }

  /// Determines if [element] is a declaration of `.where` for which calls can
  /// be transformed.
  bool _isTransformableMethod(Element? element) {
    if (element is MethodElement) {
      if (element.isStatic) return false;
      if (element.name != 'where') return false;
      var enclosingElement = element.declaration.enclosingElement;
      if (enclosingElement is ClassElement) {
        // If the class is `Iterable` or a subtype of it, we consider the user
        // to be calling a transformable method.
        return _typeSystem.isSubtypeOf(
            enclosingElement.thisType, _typeProvider.iterableDynamicType);
      }
    }
    return false;
  }
}
