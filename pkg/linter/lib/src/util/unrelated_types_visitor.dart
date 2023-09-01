// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

/// The kind of the expected argument.
enum ExpectedArgumentKind {
  /// An argument is expected to be assignable to a type argument on the
  /// collection type.
  assignableToCollectionTypeArgument,

  /// An argument is expected to be assignable to the collection type.
  assignableToCollection,

  /// An argument is expected to be assignable to `Iterable<E>` where `E` is the
  /// (only) type argument on the collection type.
  assignableToIterableOfTypeArgument,
}

/// A definition of a method and the expected characteristics of the first
/// argument to any invocation.
abstract class MethodDefinition {
  final String methodName;

  /// The index of the type argument which the method argument should match.
  final int typeArgumentIndex;

  final ExpectedArgumentKind expectedArgumentKind;

  MethodDefinition(
    this.methodName,
    this.expectedArgumentKind, {
    this.typeArgumentIndex = 0,
  });

  InterfaceType? collectionTypeFor(InterfaceType targetType);
}

class MethodDefinitionForElement extends MethodDefinition {
  /// The element on which this method is declared.
  final ClassElement element;

  MethodDefinitionForElement(
    this.element,
    super.methodName,
    super.expectedArgumentKind, {
    super.typeArgumentIndex = 0,
  });

  @override
  InterfaceType? collectionTypeFor(InterfaceType targetType) =>
      targetType.asInstanceOf(element);
}

class MethodDefinitionForName extends MethodDefinition {
  final String libraryName;

  final String interfaceName;

  MethodDefinitionForName(
    this.libraryName,
    this.interfaceName,
    super.methodName,
    super.expectedArgumentKind, {
    super.typeArgumentIndex = 0,
  });

  @override
  InterfaceType? collectionTypeFor(InterfaceType targetType) {
    for (var supertype in [targetType, ...targetType.allSupertypes]) {
      var element = supertype.element;
      if (element.name == interfaceName &&
          element.library.name == libraryName) {
        return targetType.asInstanceOf(element);
      }
    }
    return null;
  }
}

/// Base class for visitor used in rules where we want to lint about invoking
/// methods on generic classes where the type of the singular argument is
/// unrelated to the singular type argument of the class. Extending this
/// visitor is as simple as knowing the methods, classes and libraries that
/// uniquely define the target, i.e. implement only [methods].
abstract class UnrelatedTypesProcessors extends SimpleAstVisitor<void> {
  final LintRule rule;
  final TypeSystem typeSystem;
  final TypeProvider typeProvider;

  UnrelatedTypesProcessors(this.rule, this.typeSystem, this.typeProvider);

  List<MethodDefinition> get indexOperators => [];

  /// The method definitions which this [UnrelatedTypesProcessors] is concerned
  /// with.
  List<MethodDefinition> get methods;

  @override
  void visitIndexExpression(IndexExpression node) {
    var matchingMethods =
        indexOperators.where((method) => '[]' == method.methodName);
    if (matchingMethods.isEmpty) {
      return;
    }

    var targetType = _getTargetType(node, node.realTarget);
    if (targetType is! InterfaceType) {
      return;
    }

    for (var methodDefinition in matchingMethods) {
      var collectionType = methodDefinition.collectionTypeFor(targetType);
      if (collectionType != null) {
        _checkMethod(node.index, methodDefinition, collectionType);
        return;
      }
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.argumentList.arguments.length != 1) {
      return;
    }

    var matchingMethods =
        methods.where((method) => node.methodName.name == method.methodName);
    if (matchingMethods.isEmpty) {
      return;
    }

    // At this point, we know that [node] is an invocation of a method which
    // has the same name as the method that this [UnrelatedTypesProcessors] is
    // concerned with, and that the method call has a single argument.
    //
    // We've completed the "cheap" checks, and must now continue with the
    // arduous task of determining whether the method target implements
    // [definition].
    var targetType = _getTargetType(node, node.realTarget);
    if (targetType is! InterfaceType) {
      return;
    }

    for (var methodDefinition in matchingMethods) {
      var collectionType = methodDefinition.collectionTypeFor(targetType);
      if (collectionType != null) {
        _checkMethod(node.argumentList.arguments.first, methodDefinition,
            collectionType);
        return;
      }
    }
  }

  /// Checks a [MethodInvocation] or [IndexExpression] which has a singular
  /// [argument] and matches [methodDefinition], with a target with a static
  /// type of [collectionType].
  void _checkMethod(Expression argument, MethodDefinition methodDefinition,
      InterfaceType collectionType) {
    // Finally, determine whether the type of the argument is related to the
    // type of the method target.
    var argumentType = argument.staticType;
    if (argumentType == null) return;

    switch (methodDefinition.expectedArgumentKind) {
      case ExpectedArgumentKind.assignableToCollectionTypeArgument:
        var typeArgument =
            collectionType.typeArguments[methodDefinition.typeArgumentIndex];
        if (typesAreUnrelated(typeSystem, argumentType, typeArgument)) {
          rule.reportLint(argument, arguments: [
            argumentType.getDisplayString(withNullability: true),
            typeArgument.getDisplayString(withNullability: true),
          ]);
        }

      case ExpectedArgumentKind.assignableToCollection:
        if (!typeSystem.isAssignableTo(argumentType, collectionType)) {
          rule.reportLint(argument, arguments: [
            argumentType.getDisplayString(withNullability: true),
            collectionType.getDisplayString(withNullability: true),
          ]);
        }

      case ExpectedArgumentKind.assignableToIterableOfTypeArgument:
        var iterableType =
            collectionType.asInstanceOf(typeProvider.iterableElement);
        if (iterableType != null &&
            !typeSystem.isAssignableTo(argumentType, iterableType)) {
          rule.reportLint(argument, arguments: [
            argumentType.getDisplayString(withNullability: true),
            iterableType.getDisplayString(withNullability: true),
          ]);
        }
    }
  }

  DartType? _getTargetType(Expression node, Expression? target) {
    if (target != null) {
      return target.staticType;
    }

    // Look for an implicit receiver, starting with [node]'s parent's parent.
    for (AstNode? parent = node.parent?.parent;
        parent != null;
        parent = parent.parent) {
      if (parent is ClassDeclaration) {
        return parent.declaredElement?.thisType;
      } else if (parent is MixinDeclaration) {
        return parent.declaredElement?.thisType;
      } else if (parent is EnumDeclaration) {
        return parent.declaredElement?.thisType;
      } else if (parent is ExtensionDeclaration) {
        return parent.extendedType.type;
      }
    }
    return null;
  }
}
