// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/utilities_general.dart'; // ignore: implementation_imports

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

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
  * `scheduleMicrotask` at the 0th positional parameter
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
  * `Iterable.singleWhere` at the 0th positional parameter, and the named
    parameter `orElse`
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

List<NonNullableFunction> _constructorsWithNonNullableArguments =
    <NonNullableFunction>[
  NonNullableFunction('dart.async', 'Future', null, positional: [0]),
  NonNullableFunction('dart.async', 'Future', 'microtask', positional: [0]),
  NonNullableFunction('dart.async', 'Future', 'sync', positional: [0]),
  NonNullableFunction('dart.async', 'Timer', null, positional: [1]),
  NonNullableFunction('dart.async', 'Timer', 'periodic', positional: [1]),
  NonNullableFunction('dart.core', 'List', 'generate', positional: [1]),
];

final Map<String, Set<NonNullableFunction>>
    _instanceMethodsWithNonNullableArguments = {
  'any': {
    NonNullableFunction('dart.core', 'Iterable', 'any', positional: [0]),
  },
  'complete': {
    NonNullableFunction('dart.async', 'Future', 'complete', positional: [0]),
  },
  'every': {
    NonNullableFunction('dart.core', 'Iterable', 'every', positional: [0]),
  },
  'expand': {
    NonNullableFunction('dart.core', 'Iterable', 'expand', positional: [0]),
  },
  'firstWhere': {
    NonNullableFunction('dart.core', 'Iterable', 'firstWhere',
        positional: [0], named: ['orElse']),
  },
  'forEach': {
    NonNullableFunction('dart.core', 'Iterable', 'forEach', positional: [0]),
    NonNullableFunction('dart.core', 'Map', 'forEach', positional: [0]),
  },
  'fold': {
    NonNullableFunction('dart.core', 'Iterable', 'fold', positional: [1]),
  },
  'lastWhere': {
    NonNullableFunction('dart.core', 'Iterable', 'lastWhere',
        positional: [0], named: ['orElse']),
  },
  'map': {
    NonNullableFunction('dart.core', 'Iterable', 'map', positional: [0]),
  },
  'putIfAbsent': {
    NonNullableFunction('dart.core', 'Map', 'putIfAbsent', positional: [1]),
  },
  'reduce': {
    NonNullableFunction('dart.core', 'Iterable', 'reduce', positional: [0]),
  },
  'removeWhere': {
    NonNullableFunction('dart.collection', 'Queue', 'removeWhere',
        positional: [0]),
    NonNullableFunction('dart.core', 'List', 'removeWhere', positional: [0]),
    NonNullableFunction('dart.core', 'Set', 'removeWhere', positional: [0]),
  },
  'replaceAllMapped': {
    NonNullableFunction('dart.core', 'String', 'replaceAllMapped',
        positional: [1]),
  },
  'replaceFirstMapped': {
    NonNullableFunction('dart.core', 'String', 'replaceFirstMapped',
        positional: [1]),
  },
  'retainWhere': {
    NonNullableFunction('dart.collection', 'Queue', 'retainWhere',
        positional: [0]),
    NonNullableFunction('dart.core', 'List', 'retainWhere', positional: [0]),
    NonNullableFunction('dart.core', 'Set', 'retainWhere', positional: [0]),
  },
  'singleWhere': {
    NonNullableFunction('dart.core', 'Iterable', 'singleWhere',
        positional: [0], named: ['orElse']),
  },
  'skipWhile': {
    NonNullableFunction('dart.core', 'Iterable', 'skipWhile', positional: [0]),
  },
  'splitMapJoin': {
    NonNullableFunction('dart.core', 'String', 'splitMapJoin',
        named: ['onMatch', 'onNonMatch']),
  },
  'takeWhile': {
    NonNullableFunction('dart.core', 'Iterable', 'takeWhile', positional: [0]),
  },
  'then': {
    NonNullableFunction('dart.async', 'Future', 'then',
        positional: [0], named: ['onError']),
  },
  'where': {
    NonNullableFunction('dart.core', 'Iterable', 'where', positional: [0]),
  },
};

List<NonNullableFunction> _staticFunctionsWithNonNullableArguments =
    <NonNullableFunction>[
  NonNullableFunction('dart.async', null, 'scheduleMicrotask', positional: [0]),
  NonNullableFunction('dart.async', 'Future', 'doWhile', positional: [0]),
  NonNullableFunction('dart.async', 'Future', 'forEach', positional: [1]),
  NonNullableFunction('dart.async', 'Future', 'wait', named: ['cleanUp']),
  NonNullableFunction('dart.async', 'Timer', 'run', positional: [0]),
];

/// Function with closure parameters that cannot accept null arguments.
class NonNullableFunction {
  final String library;
  final String type;
  final String name;
  final List<int> positional;
  final List<String> named;

  NonNullableFunction(this.library, this.type, this.name,
      {this.positional = const <int>[], this.named = const <String>[]});

  @override
  int get hashCode =>
      JenkinsSmiHash.hash3(library.hashCode, type.hashCode, name.hashCode);

  /// Two [NonNullableFunction] objects are equal if their [library], [type],
  /// and [name] are equal, for the purpose of discovering whether a function
  /// invocation is among a collection of non-nullable functions.
  @override
  bool operator ==(Object other) =>
      other is NonNullableFunction && other.hashCode == hashCode;
}

class NullClosures extends LintRule implements NodeLintRule {
  NullClosures()
      : super(
            name: 'null_closures',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
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
    var type = node.staticType;
    for (var constructor in _constructorsWithNonNullableArguments) {
      if (constructorName?.name?.name == constructor.name) {
        if (DartTypeUtilities.extendsClass(
            type, constructor.type, constructor.library)) {
          _checkNullArgForClosure(
              node.argumentList, constructor.positional, constructor.named);
        }
      }
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    final methodName = node.methodName?.name;
    final element = target is Identifier ? target?.staticElement : null;
    if (element is ClassElement) {
      // Static function called, "target" is the class.
      for (var function in _staticFunctionsWithNonNullableArguments) {
        if (methodName == function.name) {
          if (element.name == function.type) {
            _checkNullArgForClosure(
                node.argumentList, function.positional, function.named);
          }
        }
      }
    } else {
      // Instance method called, "target" is the instance.
      final targetType = target?.staticType;
      var method = _getInstanceMethod(targetType, methodName);
      if (method == null) {
        return;
      }
      _checkNullArgForClosure(
          node.argumentList, method.positional, method.named);
    }
  }

  void _checkNullArgForClosure(
      ArgumentList node, List<int> positions, List<String> names) {
    final args = node.arguments;
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];

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

  NonNullableFunction _getInstanceMethod(DartType type, String methodName) {
    var possibleMethods = _instanceMethodsWithNonNullableArguments[methodName];
    if (possibleMethods == null) {
      return null;
    }

    if (type is! InterfaceType) {
      return null;
    }

    NonNullableFunction getMethod(String library, String className) =>
        possibleMethods
            .lookup(NonNullableFunction(library, className, methodName));

    var method = getMethod(type.element.library.name, type.element.name);
    if (method != null) {
      return method;
    }

    final element = type.element as ClassElement;
    if (element.isSynthetic) {
      return null;
    }
    for (var supertype in element.allSupertypes) {
      method =
          getMethod(supertype.element.library.name, supertype.element.name);
      if (method != null) {
        return method;
      }
    }
    return null;
  }
}
