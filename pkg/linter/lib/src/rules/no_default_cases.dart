// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../linter_lint_codes.dart';

const _desc = r'No default cases.';

const _details = r'''
Switches on enums and enum-like classes should not use a `default` clause.

Enum-like classes are defined as concrete (non-abstract) classes that have:
  * only private non-factory constructors
  * two or more static const fields whose type is the enclosing class and
  * no subclasses of the class in the defining library

**DO** define default behavior outside switch statements.

**BAD:**
```dart
  switch (testEnum) {
    case TestEnum.A:
      return '123';
    case TestEnum.B:
      return 'abc';
    default:
      return null;
  }
```

**GOOD:**
```dart
  switch (testEnum) {
    case TestEnum.A:
      return '123';
    case TestEnum.B:
      return 'abc';
  }
  // Default here.
  return null;
```

''';

class NoDefaultCases extends LintRule {
  NoDefaultCases()
      : super(
          name: 'no_default_cases',
          description: _desc,
          details: _details,
          categories: {LintRuleCategory.style},
          state: State.experimental(),
        );

  @override
  LintCode get lintCode => LinterLintCode.no_default_cases;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addSwitchStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitSwitchStatement(SwitchStatement statement) {
    var expressionType = statement.expression.staticType;
    if (expressionType is InterfaceType) {
      for (var member in statement.members) {
        if (member is SwitchDefault) {
          var interfaceElement = expressionType.element;
          if (interfaceElement is EnumElement ||
              interfaceElement is ClassElement &&
                  interfaceElement.isEnumLikeClass()) {
            rule.reportLint(member);
          }
          return;
        }
      }
    }
  }
}
