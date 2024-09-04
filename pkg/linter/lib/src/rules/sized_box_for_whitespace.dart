// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';
import '../util/flutter_utils.dart';

const _desc = r'`SizedBox` for whitespace.';

const _details = r'''
Use `SizedBox` to add whitespace to a layout.

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
  SizedBoxForWhitespace()
      : super(
          name: 'sized_box_for_whitespace',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.sized_box_for_whitespace;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);

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

    if (_shouldReportForArguments(node.argumentList)) {
      rule.reportLint(node.constructorName);
    }
  }

  /// Determine if the lint [rule] should be reported for
  /// the specified [argumentList].
  static bool _shouldReportForArguments(ArgumentList argumentList) {
    var hasChild = false;
    var hasHeight = false;
    var hasWidth = false;

    for (var argument in argumentList.arguments) {
      if (argument is! NamedExpression) {
        // Positional arguments are not supported.
        return false;
      }
      switch (argument.name.label.name) {
        case 'child':
          hasChild = true;
        case 'height':
          hasHeight = true;
        case 'width':
          hasWidth = true;
        case 'key':
          // Ignore 'key' as both SizedBox and Container have it.
          break;
        case _:
          // Other named arguments are not supported.
          return false;
      }
    }

    return hasChild && (hasWidth || hasHeight) || hasWidth && hasHeight;
  }
}
