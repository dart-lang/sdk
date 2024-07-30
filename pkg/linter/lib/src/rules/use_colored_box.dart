// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

import '../analyzer.dart';
import '../util/flutter_utils.dart';

const _desc = r'Use `ColoredBox`.';

const _details = r'''
**DO** use `ColoredBox` when `Container` has only a `Color`.

A `Container` is a heavier Widget than a `ColoredBox`, and as bonus,
`ColoredBox` has a `const` constructor.

**BAD:**
```dart
Widget buildArea() {
  return Container(
    color: Colors.blue,
    child: const Text('hello'),
  );
}
```

**GOOD:**
```dart
Widget buildArea() {
  return const ColoredBox(
    color: Colors.blue,
    child: Text('hello'),
  );
}
```
''';

class UseColoredBox extends LintRule {
  static const LintCode code = LintCode('use_colored_box',
      "Use a 'ColoredBox' rather than a 'Container' with only a 'Color'.",
      correctionMessage: "Try replacing the 'Container' with a 'ColoredBox'.");

  UseColoredBox()
      : super(
            name: 'use_colored_box',
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
    var hasColor = false;

    for (var argument in argumentList.arguments) {
      if (argument is! NamedExpression) {
        // Positional arguments are not supported.
        return false;
      }
      switch (argument.name.label.name) {
        case 'child':
          hasChild = true;
        case 'color'
            when argument.staticType?.nullabilitySuffix !=
                NullabilitySuffix.question:
          hasColor = true;
        case 'key':
          // Ignore 'key' as both ColoredBox and Container have it.
          break;
        case _:
          // Other named arguments are not supported.
          return false;
      }
    }

    return hasChild && hasColor;
  }
}
