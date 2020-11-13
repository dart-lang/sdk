// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';

/// Information about a method call that we might want to transform into its
/// "OrNull" counterpart.  See [WhereOrNullTransformer] for more information.
class WhereOrNullTransformationInfo {
  /// AST node of the method invocation.
  final MethodInvocation methodInvocation;

  /// AST node of the "orElse" argument of the method invocation.
  final NamedExpression orElseArgument;

  /// Original name of the method being called, prior to transformation.
  final String originalName;

  /// New method to call, after transformation.
  final String replacementName;

  WhereOrNullTransformationInfo(this.methodInvocation, this.orElseArgument,
      this.originalName, this.replacementName);
}

/// Methods to assist in transforming calls to the `Iterable` methods
/// `firstWhere`, `lastWhere`, and `singleWhere` into calls to the
/// `package:collection` methods `firstWhereOrNull`, `lastWhereOrNull`, or
/// `singleWhereOrNull`, where possible.
///
/// An example of the kind of code that can be transformed is:
///
///     int firstEven(Iterable<int> x)
///         => x.firstWhere((x) => x.isEven, orElse: () => null);
///
/// We transform this into:
///
///     int firstEven(Iterable<int> x)
///         => x.firstWhereOrNull((x) => x.isEven);
///
/// Without this transformation, the migrated result would have been:
///
///     int firstEven(Iterable<int?> x)
///         => x.firstWhere((x) => x.isEven, orElse: () => null);
///
/// Which would have placed an otherwise unnecessary nullability requirement on
/// the type argument of the type of `x`.
class WhereOrNullTransformer {
  static const _replacementNames = {
    'firstWhere': 'firstWhereOrNull',
    'lastWhere': 'lastWhereOrNull',
    'singleWhere': 'singleWhereOrNull'
  };

  final TypeProvider _typeProvider;

  final TypeSystem _typeSystem;

  WhereOrNullTransformer(this._typeProvider, this._typeSystem);

  /// If [expression] is the expression part of the `orElse` argument of a call
  /// that can be transformed, returns information about the transformable call;
  /// otherwise returns `null`.
  WhereOrNullTransformationInfo tryTransformOrElseArgument(
      Expression expression) {
    var transformationInfo =
        _tryTransformMethodInvocation(expression?.parent?.parent?.parent);
    if (transformationInfo != null &&
        identical(transformationInfo.orElseArgument.expression, expression)) {
      return transformationInfo;
    } else {
      return null;
    }
  }

  /// Searches [argumentList] for a named argument with the name "orElse".  If
  /// such an argument is found, and no other named arguments are found, it is
  /// returned; otherwise `null` is returned.
  NamedExpression _findOrElseArgument(ArgumentList argumentList) {
    NamedExpression orElseArgument;
    for (var argument in argumentList.arguments) {
      if (argument is NamedExpression) {
        if (argument.name.label.name == 'orElse') {
          orElseArgument = argument;
        } else {
          // The presence of an unexpected named argument means the user is
          // calling their own override of the method, and presumably they are
          // using this named argument to trigger a special behavior of their
          // override.  So don't try to replace it.
          return null;
        }
      }
    }
    return orElseArgument;
  }

  /// Determines if [element] is a method that can be transformed; if it can,
  /// the name of the replacement is returned; otherwise, `null` is returned.
  String _getTransformableMethodReplacementName(Element element) {
    if (element is MethodElement) {
      if (element.isStatic) return null;
      var replacementName = _replacementNames[element.name];
      if (replacementName == null) return null;
      var enclosingElement = element.declaration.enclosingElement;
      if (enclosingElement is ClassElement) {
        // If the class is `Iterable` or a subtype of it, we consider the user
        // to be calling a transformable method.
        if (_typeSystem.isSubtypeOf(
            enclosingElement.thisType, _typeProvider.iterableDynamicType)) {
          return replacementName;
        }
      }
    }
    return null;
  }

  /// Checks whether [expression] is of the form `() => null`.
  bool _isClosureReturningNull(Expression expression) {
    if (expression is FunctionExpression) {
      if (expression.typeParameters != null) return false;
      if (expression.parameters.parameters.isNotEmpty) return false;
      var body = expression.body;
      if (body is ExpressionFunctionBody) {
        if (body.expression is NullLiteral) return true;
      }
    }
    return false;
  }

  /// If [node] is a call that can be transformed, returns information about the
  /// transformable call; otherwise returns `null`.
  WhereOrNullTransformationInfo _tryTransformMethodInvocation(AstNode node) {
    if (node is MethodInvocation) {
      var replacementName =
          _getTransformableMethodReplacementName(node.methodName.staticElement);
      if (replacementName == null) return null;
      var orElseArgument = _findOrElseArgument(node.argumentList);
      if (orElseArgument == null) return null;
      if (!_isClosureReturningNull(orElseArgument.expression)) return null;
      return WhereOrNullTransformationInfo(
          node, orElseArgument, node.methodName.name, replacementName);
    }
    return null;
  }
}
