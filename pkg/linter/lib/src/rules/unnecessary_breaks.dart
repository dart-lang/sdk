// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r"Don't use explicit `break`s when a break is implied.";

const _details = r'''
Only use a `break` in a non-empty switch case statement if you need to break
before the end of the case body.  Dart does not support fallthrough execution
for non-empty cases, so `break`s at the end of non-empty switch case statements
are unnecessary.

**BAD:**
```dart
switch (1) {
  case 1:
    print("one");
    break;
  case 2:
    print("two");
    break;
}
```

**GOOD:**
```dart
switch (1) {
  case 1:
    print("one");
  case 2:
    print("two");
}
```

```dart
switch (1) {
  case 1:
  case 2:
    print("one or two");
}
```

```dart
switch (1) {
  case 1:
    break;
  case 2:
    print("just two");
}
```

NOTE: This lint only reports unnecessary breaks in libraries with a
[language version](https://dart.dev/guides/language/evolution#language-versioning)
of 3.0 or greater. Explicit breaks are still required in Dart 2.19 and below.
''';

class UnnecessaryBreaks extends LintRule {
  static const LintCode code = LintCode(
      'unnecessary_breaks', "Unnecessary 'break' statement.",
      correctionMessage: "Try removing the 'break'.");

  UnnecessaryBreaks()
      : super(
            name: 'unnecessary_breaks',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (!context.isEnabled(Feature.patterns)) return;
    var visitor = _Visitor(this);
    registry.addBreakStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  visitBreakStatement(BreakStatement node) {
    if (node.label != null) return;
    var parent = node.parent;
    if (parent is SwitchPatternCase) {
      var statements = parent.statements;
      if (statements.length == 1) return;
      if (node == statements.last) {
        rule.reportLint(node);
      }
    }
  }
}
