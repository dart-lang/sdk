// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../util/flutter_utils.dart';

const _desc = r'Avoid unnecessary containers.';

const _details = r'''Avoid wrapping widgets in unnecessary containers.

Wrapping a widget in `Container` with no other parameters set has no effect 
and makes code needlessly more complex.

**BAD:**
```
Widget buildRow() {
  return Container(
      child: Row(
        children: <Widget>[
          const MyLogo(),
          const Expanded(
            child: Text('...'),
          ),
        ],
      )
  );
}
```

**GOOD:**
```
Widget buildRow() {
  return Row(
    children: <Widget>[
      const MyLogo(),
      const Expanded(
        child: Text('...'),
      ),
    ],
  );
}
```
''';

class AvoidUnnecessaryContainers extends LintRule implements NodeLintRule {
  AvoidUnnecessaryContainers()
      : super(
            name: 'avoid_unnecessary_containers',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = _Visitor(this);

    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!isWidgetType(node.staticType)) {
      return;
    }
    final parent = node.parent;
    if (parent is NamedExpression && parent.name.label.name == 'child') {
      final args = parent.thisOrAncestorOfType<ArgumentList>();
      if (args.arguments.length == 1) {
        final parentCreation =
            parent.thisOrAncestorOfType<InstanceCreationExpression>();
        if (parentCreation != null) {
          if (isExactWidgetTypeContainer(parentCreation.staticType)) {
            rule.reportLint(parentCreation.constructorName);
          }
        }
      }
    }
  }
}
