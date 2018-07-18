// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Do not pass `null` as an argument where a closure is expected.';

const _details = r'''

**DO NOT** pass null as an argument where a closure is expected.

Often a closure that is passed to a method will only be called conditionally,
so that tests and "happy path" production calls do not reveal that `null` will
result in an exception being thrown.

This rule only catches null literals being passed where closures are expected
in the following locations:

#### Constructors

* From `dart:async`
  * `Future` at the 0th positional parameter
  * `Future.microtask` at the 0th positional parameter
  * `Future.sync` at the 0th positional parameter
  * `Timer` at the 0th positional parameter
  * `Timer.periodic` at the 1st positional parameter
* From `dart:core`
  * `List.generate` at the 1st positional parameter

#### Static functions

* From `dart:async`
  * `sheduleMicrotask` at the 0th positional parameter
  * `Future.doWhile` at the 0th positional parameter
  * `Future.forEach` at the 0th positional parameter
  * `Future.wait` at the named parameter `cleanup`
  * `Timer.run` at the 0th positional parameter

#### Instance methods

* From `dart:async`
  * `Future.then` at the 0th positional parameter
  * `Future.complete` at the 0th positional parameter
* From `dart:collection`
  * `Queue.removeWhere` at the 0th positional parameter
  * `Queue.retain
  * `Iterable.firstWhere` at the 0th positional parameter, and the named
    parameter `orElse`
  * `Iterable.forEach` at the 0th positional parameter
  * `Iterable.fold` at the 1st positional parameter
  * `Iterable.lastWhere` at the 0th positional parameter, and the named
    parameter `orElse`
  * `Iterable.map` at the 0th positional parameter
  * `Iterable.reduce` at the 0th positional parameter
  * `Iterable.singleWhere` at the 0th positional parameter
  * `Iterable.skipWhile` at the 0th positional parameter
  * `Iterable.takeWhile` at the 0th positional parameter
  * `Iterable.where` at the 0th positional parameter
  * `List.removeWhere` at the 0th positional parameter
  * `List.retainWhere` at the 0th positional parameter
  * `String.replaceAllMapped` at the 1st positional parameter
  * `String.replaceFirstMapped` at the 1st positional parameter
  * `String.splitMapJoin` at the named parameters `onMatch` and `onNonMatch`

**BAD:**
```
[1, 3, 5].firstWhere((e) => e.isOdd, orElse: null);
```

**GOOD:**
```
[1, 3, 5].firstWhere((e) => e.isOdd, orElse: () => null);
```

''';

/// Function with closure parameters that cannot accept null arguments.
class NonNullableFunction {
  final String library;
  final String type;
  final String name;
  final List<int> positional;
  final List<String> named;

  // Lazily instantiated, only when this function is found to be called.
  InterfaceTypeDefinition _typeDefinition;

  NonNullableFunction(this.library, this.type, this.name,
      {this.positional: const <int>[], this.named: const <String>[]});

  InterfaceTypeDefinition get typeDefinition =>
      _typeDefinition ??= new InterfaceTypeDefinition(type, library);
}

List<NonNullableFunction> _constructorsWithNonNullableArguments =
    <NonNullableFunction>[
  new NonNullableFunction('dart.async', 'Future', null, positional: [0]),
  new NonNullableFunction('dart.async', 'Future', 'microtask', positional: [0]),
  new NonNullableFunction('dart.async', 'Future', 'sync', positional: [0]),
  new NonNullableFunction('dart.async', 'Timer', null, positional: [1]),
  new NonNullableFunction('dart.async', 'Timer', 'periodic', positional: [1]),
  new NonNullableFunction('dart.core', 'List', 'generate', positional: [1]),
];

List<NonNullableFunction> _staticFunctionsWithNonNullableArguments =
    <NonNullableFunction>[
  new NonNullableFunction('dart.async', null, 'scheduleMicrotask',
      positional: [0]),
  new NonNullableFunction('dart.async', 'Future', 'doWhile', positional: [0]),
  new NonNullableFunction('dart.async', 'Future', 'forEach', positional: [1]),
  new NonNullableFunction('dart.async', 'Future', 'wait', named: ['cleanUp']),
  new NonNullableFunction('dart.async', 'Timer', 'run', positional: [0]),
];

List<NonNullableFunction> _instanceMethodsWithNonNullableArguments =
    <NonNullableFunction>[
  new NonNullableFunction('dart.async', 'Future', 'then',
      positional: [0], named: ['onError']),
  new NonNullableFunction('dart.async', 'Future', 'complete', positional: [0]),
  new NonNullableFunction('dart.collection', 'Queue', 'removeWhere',
      positional: [0]),
  new NonNullableFunction('dart.collection', 'Queue', 'retainWhere',
      positional: [0]),
  new NonNullableFunction('dart.core', 'Iterable', 'any', positional: [0]),
  new NonNullableFunction('dart.core', 'Iterable', 'every', positional: [0]),
  new NonNullableFunction('dart.core', 'Iterable', 'expand', positional: [0]),
  new NonNullableFunction('dart.core', 'Iterable', 'firstWhere',
      positional: [0], named: ['orElse']),
  new NonNullableFunction('dart.core', 'Iterable', 'forEach', positional: [0]),
  new NonNullableFunction('dart.core', 'Iterable', 'fold', positional: [1]),
  new NonNullableFunction('dart.core', 'Iterable', 'lastWhere',
      positional: [0], named: ['orElse']),
  new NonNullableFunction('dart.core', 'Iterable', 'map', positional: [0]),
  new NonNullableFunction('dart.core', 'Iterable', 'reduce', positional: [0]),
  new NonNullableFunction('dart.core', 'Iterable', 'singleWhere',
      positional: [0]),
  new NonNullableFunction('dart.core', 'Iterable', 'skipWhile',
      positional: [0]),
  new NonNullableFunction('dart.core', 'Iterable', 'takeWhile',
      positional: [0]),
  new NonNullableFunction('dart.core', 'Iterable', 'where', positional: [0]),
  new NonNullableFunction('dart.core', 'List', 'removeWhere', positional: [0]),
  new NonNullableFunction('dart.core', 'List', 'retainWhere', positional: [0]),
  new NonNullableFunction('dart.core', 'Map', 'forEach', positional: [0]),
  new NonNullableFunction('dart.core', 'Map', 'putIfAbsent', positional: [1]),
  new NonNullableFunction('dart.core', 'Set', 'removeWhere', positional: [0]),
  new NonNullableFunction('dart.core', 'Set', 'retainWhere', positional: [0]),
  new NonNullableFunction('dart.core', 'String', 'replaceAllMapped',
      positional: [1]),
  new NonNullableFunction('dart.core', 'String', 'replaceFirstMapped',
      positional: [1]),
  new NonNullableFunction('dart.core', 'String', 'splitMapJoin',
      named: ['onMatch', 'onNonMatch']),
];

class NullClosures extends LintRule implements NodeLintRule {
  NullClosures()
      : super(
            name: 'null_closures',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry) {
    final visitor = new _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var constructorName = node.constructorName;
    var type = node.bestType;
    for (var constructor in _constructorsWithNonNullableArguments) {
      if (DartTypeUtilities.extendsClass(
          type, constructor.type, constructor.library)) {
        if (constructorName?.name?.name == constructor.name) {
          _checkNullArgForClosure(
              node.argumentList, constructor.positional, constructor.named);
        }
      }
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    Expression target = node.target;
    String methodName = node.methodName?.name;
    Element element = target is Identifier ? target?.bestElement : null;
    if (element is ClassElement) {
      // Static function called, "target" is the class.
      for (var function in _staticFunctionsWithNonNullableArguments) {
        if (element.name == function.type) {
          if (methodName == function.name) {
            _checkNullArgForClosure(
                node.argumentList, function.positional, function.named);
          }
        }
      }
    } else {
      // Instance method called, "target" is the instance.
      DartType targetType = target?.bestType;
      for (var method in _instanceMethodsWithNonNullableArguments) {
        if (DartTypeUtilities.implementsAnyInterface(
            targetType, [method.typeDefinition])) {
          if (methodName == method.name) {
            _checkNullArgForClosure(
                node.argumentList, method.positional, method.named);
          }
        }
      }
    }
  }

  void _checkNullArgForClosure(
      ArgumentList node, List<int> positions, List<String> names) {
    NodeList<Expression> args = node.arguments;
    for (int i = 0; i < args.length; i++) {
      Expression arg = args[i];

      if (arg is NamedExpression) {
        if (arg.expression is NullLiteral &&
            names.contains(arg.name.label.name)) {
          rule.reportLint(arg);
        }
      } else {
        if (arg is NullLiteral && positions.contains(i)) {
          rule.reportLint(arg);
        }
      }
    }
  }
}
