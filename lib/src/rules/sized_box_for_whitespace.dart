// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../util/flutter_utils.dart';

const _desc = r'SizedBox for whitespace.';

const _details = r'''
Use SizedBox to add whitespace to a layout.

A `Container` is a heavier Widget than a `SizedBox`, and as bonus, `SizedBox`
has a `const` constructor.

**BAD:**
```dart
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
```dart
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

class SizedBoxForWhitespace extends LintRule {
  static const LintCode code = LintCode('sized_box_for_whitespace',
      "Use a 'SizedBox' to add whitespace to a layout.",
      correctionMessage: "Try using a 'SizedBox' rather than a 'Container'.");

  SizedBoxForWhitespace()
      : super(
            name: 'sized_box_for_whitespace',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);

    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _ArgumentData {
  var incompatibleParamsFound = false;

  var positionalArgumentFound = false;
  var seenWidth = false;
  var seenHeight = false;
  var seenChild = false;
  _ArgumentData(ArgumentList node) {
    for (var argument in node.arguments) {
      if (argument is! NamedExpression) {
        positionalArgumentFound = true;
        return;
      }
      var label = argument.name.label;
      if (label.name == 'width') {
        seenWidth = true;
      } else if (label.name == 'height') {
        seenHeight = true;
      } else if (label.name == 'child') {
        seenChild = true;
      } else if (label.name == 'key') {
        // key doesn't matter (both SizedBox and Container have it)
      } else {
        incompatibleParamsFound = true;
      }
    }
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

    var data = _ArgumentData(node.argumentList);

    if (data.incompatibleParamsFound || data.positionalArgumentFound) {
      return;
    }
    if (data.seenChild && (data.seenWidth || data.seenHeight) ||
        data.seenWidth && data.seenHeight) {
      rule.reportLint(node.constructorName);
    }
  }
}
