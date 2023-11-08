// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/type.dart' show InvalidTypeImpl;

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Use collection literals when possible.';

const _details = r'''
**DO** use collection literals when possible.

**BAD:**
```dart
var addresses = Map<String, String>();
var uniqueNames = Set<String>();
var ids = LinkedHashSet<int>();
var coordinates = LinkedHashMap<int, int>();
```

**GOOD:**
```dart
var addresses = <String, String>{};
var uniqueNames = <String>{};
var ids = <int>{};
var coordinates = <int, int>{};
```

**EXCEPTIONS:**

When a `LinkedHashSet` or `LinkedHashMap` is expected, a collection literal is
not preferred (or allowed).

```dart
void main() {
  LinkedHashSet<int> linkedHashSet =  LinkedHashSet.from([1, 2, 3]); // OK
  LinkedHashMap linkedHashMap = LinkedHashMap(); // OK
  
  printSet(LinkedHashSet<int>()); // LINT
  printHashSet(LinkedHashSet<int>()); // OK

  printMap(LinkedHashMap<int, int>()); // LINT
  printHashMap(LinkedHashMap<int, int>()); // OK
}

void printSet(Set<int> ids) => print('$ids!');
void printHashSet(LinkedHashSet<int> ids) => printSet(ids);
void printMap(Map map) => print('$map!');
void printHashMap(LinkedHashMap map) => printMap(map);
```
''';

class PreferCollectionLiterals extends LintRule {
  static const LintCode code = LintCode(
      'prefer_collection_literals', 'Unnecessary constructor invocation.',
      correctionMessage: 'Try using a collection literal.');

  PreferCollectionLiterals()
      : super(
            name: 'prefer_collection_literals',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context.typeProvider);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final TypeProvider typeProvider;
  _Visitor(this.rule, this.typeProvider);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var constructorName = node.constructorName.name?.name;

    if (node.constructorName.type.element is TypeAliasElement) {
      // Allow the use of typedef constructors.
      return;
    }

    // Maps.
    if (node.isHashMap) {
      var approximateContextType = _approximateContextType(node);
      if (approximateContextType is InvalidType) return;
      if (approximateContextType.isTypeHashMap) return;
    }
    if (node.isMap || node.isHashMap) {
      if (constructorName == null && node.argumentList.arguments.isEmpty) {
        rule.reportLint(node);
      }
      return;
    }

    // Sets.
    if (node.isHashSet) {
      var approximateContextType = _approximateContextType(node);
      if (approximateContextType is InvalidType) return;
      if (approximateContextType.isTypeHashSet) return;
    }
    if (node.isSet || node.isHashSet) {
      var args = node.argumentList.arguments;
      if (constructorName == null) {
        // Allow `LinkedHashSet(equals: (a, b) => false, hashCode: (o) => 13)`.
        if (args.isEmpty) {
          rule.reportLint(node);
        }
      } else if (constructorName == 'from' || constructorName == 'of') {
        if (args.length != 1) {
          return;
        }
        if (args.first is ListLiteral) {
          rule.reportLint(node);
        }
      }
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Something like `['foo', 'bar', 'baz'].toSet()`.
    if (node.methodName.name != 'toSet') {
      return;
    }
    if (node.target is ListLiteral) {
      rule.reportLint(node);
    }
  }

  /// A very, very rough approximation of the context type of [node].
  ///
  /// This approximation will never be accurate for some expressions.
  DartType? _approximateContextType(Expression node) {
    var ancestor = node.parent;
    var ancestorChild = node;
    while (ancestor != null) {
      if (ancestor is ParenthesizedExpression) {
        ancestorChild = ancestor;
        ancestor = ancestor.parent;
      } else if (ancestor is CascadeExpression &&
          ancestorChild == ancestor.target) {
        ancestorChild = ancestor;
        ancestor = ancestor.parent;
      } else {
        break;
      }
    }

    switch (ancestor) {
      // TODO(srawlins): Handle [AwaitExpression], [BinaryExpression],
      // [CascadeExpression], [ConditionalExpression], [SwitchExpressionCase],
      // likely others. Or move everything here to an analysis phase which
      // has the actual context type.
      case ArgumentList():
        // Allow `function(LinkedHashSet())` for `function(LinkedHashSet mySet)`
        // and `function(LinkedHashMap())` for `function(LinkedHashMap myMap)`.
        return node.staticParameterElement?.type ?? InvalidTypeImpl.instance;
      case AssignmentExpression():
        // Allow `x = LinkedHashMap()`.
        return ancestor.staticType;
      case ExpressionFunctionBody(parent: var function)
          when function is FunctionExpression:
        // Allow `<int, LinkedHashSet>{}.putIfAbsent(3, () => LinkedHashSet())`
        // and `<int, LinkedHashMap>{}.putIfAbsent(3, () => LinkedHashMap())`.
        var functionParent = function.parent;
        if (functionParent is FunctionDeclaration) {
          return functionParent.returnType?.type;
        }
        var functionType = _approximateContextType(function);
        return functionType is FunctionType ? functionType.returnType : null;
      case ExpressionFunctionBody(parent: var function)
          when function is FunctionDeclaration:
        return function.returnType?.type;
      case ExpressionFunctionBody(parent: var function)
          when function is MethodDeclaration:
        return function.returnType?.type;
      case NamedExpression():
        // Allow `void f({required LinkedHashSet<Foo> s})`.
        return ancestor.staticParameterElement?.type ??
            InvalidTypeImpl.instance;
      case ReturnStatement():
        return _expectedReturnType(
          ancestor.thisOrAncestorOfType<FunctionBody>(),
        );
      case VariableDeclaration(parent: VariableDeclarationList(:var type)):
        // Allow `LinkedHashSet<int> s = node` and
        // `LinkedHashMap<int> s = node`.
        return type?.type;
      case YieldStatement():
        return _expectedReturnType(
          ancestor.thisOrAncestorOfType<FunctionBody>(),
        );
    }

    return null;
  }

  /// Extracts the expected type for return statements or yield statements.
  ///
  /// For example, for an asynchronous [body] in a function with a declared
  /// [returnType] of `Future<int>`, this returns `int`. (Note: it would be more
  /// accurate to use `FutureOr<int>` and an assignability check, but `int` is
  /// an approximation that works for now; this should probably be revisited.)
  DartType? _expectedReturnableOrYieldableType(
    DartType? returnType,
    FunctionBody body,
  ) {
    if (returnType == null || returnType is InvalidType) return null;
    if (body.isAsynchronous) {
      if (!body.isGenerator && returnType.isDartAsyncFuture) {
        var typeArgs = (returnType as InterfaceType).typeArguments;
        return typeArgs.isEmpty ? null : typeArgs.first;
      }
      if (body.isGenerator && returnType.isDartAsyncStream) {
        var typeArgs = (returnType as InterfaceType).typeArguments;
        return typeArgs.isEmpty ? null : typeArgs.first;
      }
    } else {
      if (body.isGenerator && returnType.isDartCoreIterable) {
        var typeArgs = (returnType as InterfaceType).typeArguments;
        return typeArgs.isEmpty ? null : typeArgs.first;
      }
    }
    return returnType;
  }

  /// Attempts to calculate the expected return type of the function represented
  /// by [body], accounting for an approximation of the function's context type,
  /// in the case of a function literal.
  DartType? _expectedReturnType(FunctionBody? body) {
    if (body == null) return null;
    var parent = body.parent;
    if (parent is FunctionExpression) {
      var grandparent = parent.parent;
      if (grandparent is FunctionDeclaration) {
        var returnType = grandparent.declaredElement?.returnType;
        return _expectedReturnableOrYieldableType(returnType, body);
      }
      var functionType = _approximateContextType(parent);
      if (functionType is! FunctionType) return null;
      var returnType = functionType.returnType;
      return _expectedReturnableOrYieldableType(returnType, body);
    }
    if (parent is MethodDeclaration) {
      var returnType = parent.declaredElement?.returnType;
      return _expectedReturnableOrYieldableType(returnType, body);
    }
    return null;
  }
}

extension on Expression {
  bool get isHashMap => staticType.isTypeHashMap;

  bool get isHashSet => staticType.isTypeHashSet;

  bool get isMap => staticType?.isDartCoreMap ?? false;

  bool get isSet => staticType?.isDartCoreSet ?? false;
}

extension on DartType? {
  bool get isTypeHashMap => isSameAs('LinkedHashMap', 'dart.collection');

  bool get isTypeHashSet => isSameAs('LinkedHashSet', 'dart.collection');
}
