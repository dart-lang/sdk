// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Do not use environment declared variables.';

const _details = r'''
Using values derived from the environment at compile-time, creates
hidden global state and makes applications hard to understand and maintain.

**DO NOT** use `fromEnvironment` or `hasEnvironment` factory constructors.

**BAD:**
```
const loggingLevel =
  bool.hasEnvironment('logging') ? String.fromEnvironment('logging') : null;
```
''';

class DoNotUseEnvironment extends LintRule implements NodeLintRule {
  DoNotUseEnvironment()
      : super(
            name: 'do_not_use_environment',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var constructorNameNode = node.constructorName;
    if (constructorNameNode.staticElement?.isFactory != true) {
      return;
    }
    var staticType = node.staticType;
    if (staticType == null) {
      return;
    }
    var constructorName = constructorNameNode.name?.name;
    if (constructorName == null) {
      return;
    }

    if (((staticType.isDartCoreBool ||
                staticType.isDartCoreInt ||
                staticType.isDartCoreString) &&
            constructorName == 'fromEnvironment') ||
        (staticType.isDartCoreBool && constructorName == 'hasEnvironment')) {
      rule.reportLint(constructorNameNode);
    }
  }
}
