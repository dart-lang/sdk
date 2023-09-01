// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';
import '../util/unrelated_types_visitor.dart';

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
            group: Group.errors);

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

class _Visitor extends UnrelatedTypesProcessors {
  _Visitor(super.rule, super.typeSystem, super.typeProvider);

  @override
  List<MethodDefinition> get indexOperators => [
        // Argument to `Map<K, V>.[]` should be assignable to `K`.
        MethodDefinitionForElement(
          typeProvider.mapElement,
          '[]',
          ExpectedArgumentKind.assignableToCollectionTypeArgument,
        ),
      ];

  @override
  List<MethodDefinition> get methods => [
        // Argument to `Iterable<E>.contains` should be assignable to `E`.
        MethodDefinitionForElement(
          typeProvider.iterableElement,
          'contains',
          ExpectedArgumentKind.assignableToCollectionTypeArgument,
        ),
        // Argument to `List<E>.remove` should be assignable to `E`.
        MethodDefinitionForElement(
          typeProvider.listElement,
          'remove',
          ExpectedArgumentKind.assignableToCollectionTypeArgument,
        ),
        // Argument to `Map<K, V>.containsKey` should be assignable to `K`.
        MethodDefinitionForElement(
          typeProvider.mapElement,
          'containsKey',
          ExpectedArgumentKind.assignableToCollectionTypeArgument,
        ),
        // Argument to `Map<K, V>.containsValue` should be assignable to `V`.
        MethodDefinitionForElement(
          typeProvider.mapElement,
          'containsValue',
          ExpectedArgumentKind.assignableToCollectionTypeArgument,
          typeArgumentIndex: 1,
        ),
        // Argument to `Map<K, V>.remove` should be assignable to `K`.
        MethodDefinitionForElement(
          typeProvider.mapElement,
          'remove',
          ExpectedArgumentKind.assignableToCollectionTypeArgument,
        ),
        // Argument to `Queue<E>.remove` should be assignable to `E`.
        MethodDefinitionForName(
          'dart.collection',
          'Queue',
          'remove',
          ExpectedArgumentKind.assignableToCollectionTypeArgument,
        ),
        // Argument to `Set<E>.lookup` should be assignable to `E`.
        MethodDefinitionForElement(
          typeProvider.setElement,
          'lookup',
          ExpectedArgumentKind.assignableToCollectionTypeArgument,
        ),
        // Argument to `Set<E>.remove` should be assignable to `E`.
        MethodDefinitionForElement(
          typeProvider.setElement,
          'remove',
          ExpectedArgumentKind.assignableToCollectionTypeArgument,
        ),
      ];
}
