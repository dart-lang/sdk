// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc = 'Invocation of various collection methods with arguments of '
    'unrelated types.';

const _details = r'''
**DON'T** invoke certain collection method with an argument with an unrelated
type.

Doing this will invoke `==` on the collection's elements and most likely will
return `false`.

An argument passed to a collection method should relate to the collection type
as follows:

* an argument to `Iterable<E>.contains` should be related to `E`
* an argument to `List<E>.remove` should be related to `E`
* an argument to `Map<K, V>.containsKey` should be related to `K`
* an argument to `Map<K, V>.containsValue` should be related to `V`
* an argument to `Map<K, V>.remove` should be related to `K`
* an argument to `Map<K, V>.[]` should be related to `K`
* an argument to `Queue<E>.remove` should be related to `E`
* an argument to `Set<E>.lookup` should be related to `E`
* an argument to `Set<E>.remove` should be related to `E`

**BAD:**
```dart
void someFunction() {
  var list = <int>[];
  if (list.contains('1')) print('someFunction'); // LINT
}
```

**BAD:**
```dart
void someFunction() {
  var set = <int>{};
  set.remove('1'); // LINT
}
```

**GOOD:**
```dart
void someFunction() {
  var list = <int>[];
  if (list.contains(1)) print('someFunction'); // OK
}
```

**GOOD:**
```dart
void someFunction() {
  var set = <int>{};
  set.remove(1); // OK
}
```

''';

class CollectionMethodsUnrelatedType extends LintRule {
  static const LintCode code = LintCode('collection_methods_unrelated_type',
      "The argument type '{0}' isn't related to '{1}'.");

  CollectionMethodsUnrelatedType()
      : super(
            name: 'collection_methods_unrelated_type',
            description: _desc,
            details: _details,
            categories: {Category.errors});

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context.typeSystem, context.typeProvider);
    registry.addIndexExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

/// The kind of the expected argument.
enum _ExpectedArgumentKind {
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
abstract class _MethodDefinition {
  final String methodName;

  /// The index of the type argument which the method argument should match.
  final int typeArgumentIndex;

  final _ExpectedArgumentKind expectedArgumentKind;

  _MethodDefinition(
    this.methodName,
    this.expectedArgumentKind, {
    this.typeArgumentIndex = 0,
  });

  InterfaceType? collectionTypeFor(InterfaceType targetType);
}

class _MethodDefinitionForElement extends _MethodDefinition {
  /// The element on which this method is declared.
  final ClassElement element;

  _MethodDefinitionForElement(
    this.element,
    super.methodName,
    super.expectedArgumentKind, {
    super.typeArgumentIndex = 0,
  });

  @override
  InterfaceType? collectionTypeFor(InterfaceType targetType) =>
      targetType.asInstanceOf(element);
}

class _MethodDefinitionForName extends _MethodDefinition {
  final String libraryName;

  final String interfaceName;

  _MethodDefinitionForName(this.libraryName, this.interfaceName,
      super.methodName, super.expectedArgumentKind);

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

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final TypeSystem typeSystem;
  final TypeProvider typeProvider;
  _Visitor(this.rule, this.typeSystem, this.typeProvider);

  List<_MethodDefinition> get indexOperators => [
        // Argument to `Map<K, V>.[]` should be assignable to `K`.
        _MethodDefinitionForElement(
          typeProvider.mapElement,
          '[]',
          _ExpectedArgumentKind.assignableToCollectionTypeArgument,
        ),
      ];

  List<_MethodDefinition> get methods => [
        // Argument to `Iterable<E>.contains` should be assignable to `E`.
        _MethodDefinitionForElement(
          typeProvider.iterableElement,
          'contains',
          _ExpectedArgumentKind.assignableToCollectionTypeArgument,
        ),
        // Argument to `List<E>.remove` should be assignable to `E`.
        _MethodDefinitionForElement(
          typeProvider.listElement,
          'remove',
          _ExpectedArgumentKind.assignableToCollectionTypeArgument,
        ),
        // Argument to `Map<K, V>.containsKey` should be assignable to `K`.
        _MethodDefinitionForElement(
          typeProvider.mapElement,
          'containsKey',
          _ExpectedArgumentKind.assignableToCollectionTypeArgument,
        ),
        // Argument to `Map<K, V>.containsValue` should be assignable to `V`.
        _MethodDefinitionForElement(
          typeProvider.mapElement,
          'containsValue',
          _ExpectedArgumentKind.assignableToCollectionTypeArgument,
          typeArgumentIndex: 1,
        ),
        // Argument to `Map<K, V>.remove` should be assignable to `K`.
        _MethodDefinitionForElement(
          typeProvider.mapElement,
          'remove',
          _ExpectedArgumentKind.assignableToCollectionTypeArgument,
        ),
        // Argument to `Queue<E>.remove` should be assignable to `E`.
        _MethodDefinitionForName(
          'dart.collection',
          'Queue',
          'remove',
          _ExpectedArgumentKind.assignableToCollectionTypeArgument,
        ),
        // Argument to `Set<E>.lookup` should be assignable to `E`.
        _MethodDefinitionForElement(
          typeProvider.setElement,
          'lookup',
          _ExpectedArgumentKind.assignableToCollectionTypeArgument,
        ),
        // Argument to `Set<E>.remove` should be assignable to `E`.
        _MethodDefinitionForElement(
          typeProvider.setElement,
          'remove',
          _ExpectedArgumentKind.assignableToCollectionTypeArgument,
        ),
      ];

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
  void _checkMethod(Expression argument, _MethodDefinition methodDefinition,
      InterfaceType collectionType) {
    // Finally, determine whether the type of the argument is related to the
    // type of the method target.
    var argumentType = argument.staticType;
    if (argumentType == null) return;

    switch (methodDefinition.expectedArgumentKind) {
      case _ExpectedArgumentKind.assignableToCollectionTypeArgument:
        var typeArgument =
            collectionType.typeArguments[methodDefinition.typeArgumentIndex];
        if (typesAreUnrelated(typeSystem, argumentType, typeArgument)) {
          rule.reportLint(argument, arguments: [
            argumentType.getDisplayString(),
            typeArgument.getDisplayString(),
          ]);
        }

      case _ExpectedArgumentKind.assignableToCollection:
        if (!typeSystem.isAssignableTo(argumentType, collectionType)) {
          rule.reportLint(argument, arguments: [
            argumentType.getDisplayString(),
            collectionType.getDisplayString(),
          ]);
        }

      case _ExpectedArgumentKind.assignableToIterableOfTypeArgument:
        var iterableType =
            collectionType.asInstanceOf(typeProvider.iterableElement);
        if (iterableType != null &&
            !typeSystem.isAssignableTo(argumentType, iterableType)) {
          rule.reportLint(argument, arguments: [
            argumentType.getDisplayString(),
            iterableType.getDisplayString(),
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
        return parent.onClause?.extendedType.type;
      }
    }
    return null;
  }
}
