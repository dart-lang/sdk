// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc =
    r'Prefer final in for-each loop variable if reference is not reassigned.';

const _details = r'''

**DO** prefer declaring for-each loop variables as final if they are not
reassigned later in the code.

Declaring for-each loop variables as final when possible is a good practice
because it helps avoid accidental reassignments and allows the compiler to do
optimizations.

**BAD:**
```
for (var element in elements) { // LINT
  print('Element: $element');
}
```

**GOOD:**
```
for (final element in elements) {
  print('Element: $element');
}
```

**GOOD:**
```
for (var element in elements) {
  element = element + element;
  print('Element: $element');
}
```

''';

class PreferFinalInForEach extends LintRule implements NodeLintRule {
  PreferFinalInForEach()
      : super(
            name: 'prefer_final_in_for_each',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addForStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitForStatement(ForStatement node) {
    var forLoopParts = node.forLoopParts;
    // If the following `if` test fails, then either the statement is not a
    // for-each loop, or it is something like `for(a in b) { ... }`.  In the
    // second case, notice `a` is not actually declared from within the
    // loop. `a` is a variable declared outside the loop.
    if (forLoopParts is ForEachPartsWithDeclaration) {
      final loopVariable = forLoopParts.loopVariable;

      if (loopVariable.isFinal) {
        return;
      }

      final function = node.thisOrAncestorOfType<FunctionBody>();
      if (function != null &&
          !function.isPotentiallyMutatedInScope(loopVariable.declaredElement)) {
        rule.reportLint(loopVariable.identifier);
      }
    }
  }
}
