// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';

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
      correctionMessage: 'Try using a collection literal.',
      hasPublishedDocs: true);

  PreferCollectionLiterals()
      : super(
            name: 'prefer_collection_literals',
            description: _desc,
            details: _details,
            categories: {LintRuleCategory.brevity, LintRuleCategory.style});

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
      var approximateContextType = node.approximateContextType;
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
      var approximateContextType = node.approximateContextType;
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
