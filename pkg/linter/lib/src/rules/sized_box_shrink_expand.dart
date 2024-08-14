// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';
import '../util/flutter_utils.dart';

const _details = r'''
Use `SizedBox.shrink(...)` and `SizedBox.expand(...)` constructors
appropriately.

Either the `SizedBox.shrink(...)` or `SizedBox.expand(...)` constructor should
be used instead of the more general `SizedBox(...)` constructor when one of the
named constructors capture the intent of the code more succinctly.

**Examples**

**BAD:**
```dart
Widget buildLogo() {
  return SizedBox(
    height: 0,
    width: 0,
    child: const MyLogo(),
  );
}
```

```dart
Widget buildLogo() {
  return SizedBox(
    height: double.infinity,
    width: double.infinity,
    child: const MyLogo(),
  );
}
```

**GOOD:**
```dart
Widget buildLogo() {
  return SizedBox.shrink(
    child: const MyLogo(),
  );
}
```

```dart
Widget buildLogo() {
  return SizedBox.expand(
    child: const MyLogo(),
  );
}
```
''';

class SizedBoxShrinkExpand extends LintRule {
  SizedBoxShrinkExpand()
      : super(
            name: 'sized_box_shrink_expand',
            description: 'Use SizedBox shrink and expand named constructors.',
            details: _details,
            categories: {LintRuleCategory.flutter, LintRuleCategory.style});

  @override
  LintCode get lintCode => LinterLintCode.sized_box_shrink_expand;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);

    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final SizedBoxShrinkExpand rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Only interested in the default constructor for the SizedBox widget
    if (!isExactWidgetTypeSizedBox(node.staticType) ||
        node.constructorName.name != null) {
      return;
    }

    var data = _analyzeArguments(node.argumentList);
    if (data == null) {
      return;
    }

    if (data.width == 0 && data.height == 0) {
      rule.reportLint(node.constructorName, arguments: ['shrink']);
    } else if (data.width == double.infinity &&
        data.height == double.infinity) {
      rule.reportLint(node.constructorName, arguments: ['expand']);
    }
  }

  /// Determine the value of the arguments specified in the [argumentList],
  /// and return `null` if there are unsupported arguments.
  static ({double? height, double? width})? _analyzeArguments(
      ArgumentList argumentList) {
    double? height;
    double? width;

    for (var argument in argumentList.arguments) {
      if (argument is! NamedExpression) {
        // Positional arguments are not supported.
        return null;
      }

      switch (argument.name.label.name) {
        case 'width':
          width = argument.expression.argumentValue;
        case 'height':
          height = argument.expression.argumentValue;
      }
    }

    return (height: height, width: width);
  }
}

extension on Expression {
  double? get argumentValue {
    var self = this;
    return switch (self) {
      IntegerLiteral() => self.value?.toDouble(),
      DoubleLiteral() => self.value,
      PrefixedIdentifier(:var identifier, :var prefix)
          when identifier.name == 'infinity' && prefix.name == 'double' =>
        double.infinity,
      _ => null,
    };
  }
}
