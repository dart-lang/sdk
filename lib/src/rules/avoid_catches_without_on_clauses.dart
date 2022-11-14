// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Avoid catches without on clauses.';

const _details = r'''
**AVOID** catches without on clauses.

Using catch clauses without on clauses make your code prone to encountering
unexpected errors that won't be thrown (and thus will go unnoticed).

**BAD:**
```dart
try {
 somethingRisky()
}
catch(e) {
  doSomething(e);
}
```

**GOOD:**
```dart
try {
 somethingRisky()
}
on Exception catch(e) {
  doSomething(e);
}
```

''';

class AvoidCatchesWithoutOnClauses extends LintRule {
  static const LintCode code = LintCode(
      'avoid_catches_without_on_clauses',
      "Catch clause needs to use 'on' to specify the type of exception being "
          'caught.',
      correctionMessage: "Try adding an 'on' clause before the 'catch'.");

  AvoidCatchesWithoutOnClauses()
      : super(
            name: 'avoid_catches_without_on_clauses',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addCatchClause(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitCatchClause(CatchClause node) {
    if (node.onKeyword == null) {
      rule.reportLint(node);
    }
  }
}
