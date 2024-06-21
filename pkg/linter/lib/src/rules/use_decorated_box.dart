// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../util/flutter_utils.dart';

const _desc = r'Use `DecoratedBox`.';

const _details = r'''
**DO** use `DecoratedBox` when `Container` has only a `Decoration`.

A `Container` is a heavier Widget than a `DecoratedBox`, and as bonus,
`DecoratedBox` has a `const` constructor.

**BAD:**
```dart
Widget buildArea() {
  return Container(
    decoration: const BoxDecoration(
      color: Colors.blue,
      borderRadius: BorderRadius.all(
        Radius.circular(5),
      ),
    ),
    child: const Text('...'),
  );
}
```

**GOOD:**
```dart
Widget buildArea() {
  return const DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.blue,
      borderRadius: BorderRadius.all(
        Radius.circular(5),
      ),
    ),
    child: Text('...'),
  );
}
```
''';

class UseDecoratedBox extends LintRule {
  static const LintCode code = LintCode('use_decorated_box',
      "Use 'DecoratedBox' rather than a 'Container' with only a 'Decoration'.",
      correctionMessage:
          "Try replacing the 'Container' with a 'DecoratedBox'.");

  UseDecoratedBox()
      : super(
            name: 'use_decorated_box',
            description: _desc,
            details: _details,
            categories: {Category.style});

  @override
  LintCode get lintCode => code;

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
    var hasDecoration = false;

    for (var argument in argumentList.arguments) {
      if (argument is! NamedExpression) {
        // Positional arguments are not supported.
        return false;
      }
      switch (argument.name.label.name) {
        case 'child':
          hasChild = true;
        case 'decoration':
          hasDecoration = true;
        case 'key':
          // Ignore 'key' as both DecoratedBox and Container have it.
          break;
        case _:
          // Other named arguments are not supported.
          return false;
      }
    }

    return hasChild && hasDecoration;
  }
}
