// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r"Don't explicitly initialize variables to null.";

const _details = r'''
From [Effective Dart](https://dart.dev/effective-dart/usage#dont-explicitly-initialize-variables-to-null):

**DON'T** explicitly initialize variables to `null`.

If a variable has a non-nullable type or is `final`, 
Dart reports a compile error if you try to use it
before it has been definitely initialized. 
If the variable is nullable and not `const` or `final`, 
then it is implicitly initialized to `null` for you. 
There's no concept of "uninitialized memory" in Dart 
and no need to explicitly initialize a variable to `null` to be "safe".
Adding `= null` is redundant and unneeded.

**BAD:**
```dart
Item? bestDeal(List<Item> cart) {
  Item? bestItem = null;

  for (final item in cart) {
    if (bestItem == null || item.price < bestItem.price) {
      bestItem = item;
    }
  }

  return bestItem;
}
```

**GOOD:**
```dart
Item? bestDeal(List<Item> cart) {
  Item? bestItem;

  for (final item in cart) {
    if (bestItem == null || item.price < bestItem.price) {
      bestItem = item;
    }
  }

  return bestItem;
}
```

''';

class AvoidInitToNull extends LintRule {
  static const LintCode code = LintCode(
      'avoid_init_to_null', "Redundant initialization to 'null'.",
      correctionMessage: 'Try removing the initializer.');

  AvoidInitToNull()
      : super(
            name: 'avoid_init_to_null',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addVariableDeclaration(this, visitor);
    registry.addDefaultFormalParameter(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  final bool nnbdEnabled;
  _Visitor(this.rule, this.context)
      : nnbdEnabled = context.isEnabled(Feature.non_nullable);

  bool isNullable(DartType type) =>
      !nnbdEnabled || context.typeSystem.isNullable(type);

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    var declaredElement = node.declaredElement;
    if (declaredElement == null) return;

    if (declaredElement is SuperFormalParameterElement) {
      var superConstructorParameter = declaredElement.superConstructorParameter;
      if (superConstructorParameter is! ParameterElement) return;
      var defaultValue = superConstructorParameter.defaultValueCode ?? 'null';
      if (defaultValue != 'null') return;
    }

    if (node.defaultValue.isNullLiteral && isNullable(declaredElement.type)) {
      rule.reportLint(node);
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    var declaredElement = node.declaredElement;
    if (declaredElement != null &&
        !node.isConst &&
        !node.isFinal &&
        node.initializer.isNullLiteral &&
        isNullable(declaredElement.type)) {
      rule.reportLint(node);
    }
  }
}
