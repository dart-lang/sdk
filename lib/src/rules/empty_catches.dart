// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../utils.dart';

const _desc = r'Avoid empty catch blocks.';

const _details = r'''

**AVOID** empty catch blocks.

In general, empty catch blocks should be avoided.  In cases where they are
intended, a comment should be provided to explain why exceptions are being
caught and suppressed.  Alternatively, the exception identifier can be named with
underscores (e.g., `_`) to indicate that we intend to skip it.

**BAD:**
```
try {
  ...
} catch(exception) { }
```

**GOOD:**
```
try {
  ...
} catch(e) {
  // ignored, really.
}

// Alternatively:
try {
  ...
} catch(_) { }

// Better still:
try {
  ...
} catch(e) {
  doSomething(e);
}
```

''';

class EmptyCatches extends LintRule implements NodeLintRule {
  EmptyCatches()
      : super(
            name: 'empty_catches',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addCatchClause(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitCatchClause(CatchClause node) {
    // Skip exceptions named with underscores.
    final exceptionParameter = node.exceptionParameter;
    if (exceptionParameter != null &&
        isJustUnderscores(exceptionParameter.name)) {
      return;
    }

    final body = node.body;
    if (node.body.statements.isEmpty &&
        body.rightBracket?.precedingComments == null) {
      rule.reportLint(body);
    }
  }
}
