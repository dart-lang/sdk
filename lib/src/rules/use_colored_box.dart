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
  var positionalArgumentsFound = false;
  var additionalArgumentsFound = false;
  var hasColor = false;
  var hasChild = false;

  _ArgumentData(ArgumentList node) {
    for (var argument in node.arguments) {
      if (argument is! NamedExpression) {
        positionalArgumentsFound = true;
        return;
      }
      var label = argument.name.label;
      if (label.name == 'color' &&
          argument.staticType?.nullabilitySuffix !=
              NullabilitySuffix.question) {
        hasColor = true;
      } else if (label.name == 'child') {
        hasChild = true;
      } else if (label.name == 'key') {
        // Ignore key
      } else {
        additionalArgumentsFound = true;
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

    if (data.additionalArgumentsFound || data.positionalArgumentsFound) {
      return;
    }

    if (data.hasChild && data.hasColor) {
      rule.reportLint(node.constructorName);
    }
  }
}
