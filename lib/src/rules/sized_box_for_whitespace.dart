// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../util/flutter_utils.dart';

const _desc = r'SizedBox for whitespace.';

const _details = r'''Use SizedBox to add whitespace to a layout.

A `Container` is a heavier Widget than a `SizedBox`, and as bonus, `SizedBox`
has a `const` constructor.

**BAD:**
```
Widget buildRow() {
  return Row(
    children: <Widget>[
      const MyLogo(),
      Container(width: 4),
      const Expanded(
        child: Text('...'),
      ),
    ],
  );
}
```

**GOOD:**
```
Widget buildRow() {
  return Row(
    children: const <Widget>[
      MyLogo(),
      SizedBox(width: 4),
      Expanded(
        child: Text('...'),
      ),
    ],
  );
}
```
''';

class SizedBoxForWhitespace extends LintRule implements NodeLintRule {
  SizedBoxForWhitespace()
      : super(
            name: 'sized_box_for_whitespace',
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
    if (!isExactWidgetTypeContainer(node.staticType)) {
      return;
    }

    final visitor = _WidthOrHeightArgumentVisitor();
    node.visitChildren(visitor);
    if (visitor.seenIncompatibleParams) {
      return;
    }
    if (visitor.seenChild && (visitor.seenWidth || visitor.seenHeight) ||
        visitor.seenWidth && visitor.seenHeight) {
      rule.reportLint(node.constructorName);
    }
  }
}

class _WidthOrHeightArgumentVisitor extends SimpleAstVisitor<void> {
  var seenWidth = false;
  var seenHeight = false;
  var seenChild = false;
  var seenIncompatibleParams = false;

  @override
  void visitArgumentList(ArgumentList node) {
    for (final name in node.arguments
        .cast<NamedExpression>()
        .map((arg) => arg.name.label.name)) {
      if (name == 'width') {
        seenWidth = true;
      } else if (name == 'height') {
        seenHeight = true;
      } else if (name == 'child') {
        seenChild = true;
      } else if (name == 'key') {
        // key doesn't matter (both SiezdBox and Container have it)
      } else {
        seenIncompatibleParams = true;
      }
    }
  }
}
