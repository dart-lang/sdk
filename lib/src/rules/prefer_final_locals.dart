// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc =
    r'Prefer final for variable declarations if they are not reassigned.';

const _details = r'''

**DO** prefer declaring variables as final if they are not reassigned later in
the code.

Declaring variables as final when possible is a good practice because it helps
avoid accidental reassignments and allows the compiler to do optimizations.

**BAD:**
```
void badMethod() {
  var label = 'hola mundo! badMethod'; // LINT
  print(label);
}
```

**GOOD:**
```
void goodMethod() {
  final label = 'hola mundo! goodMethod';
  print(label);
}
```

**GOOD:**
```
void mutableCase() {
  var label = 'hola mundo! mutableCase';
  print(label);
  label = 'hello world';
  print(label);
}
```

''';

class PreferFinalLocals extends LintRule implements NodeLintRule {
  PreferFinalLocals()
      : super(
            name: 'prefer_final_locals',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  List<String> get incompatibleRules => const ['unnecessary_final'];

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addVariableDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.isConst ||
        node.isFinal ||
        node.equals == null ||
        node.initializer == null) {
      return;
    }

    final function = node.thisOrAncestorOfType<FunctionBody>();
    if (function != null &&
        !function.isPotentiallyMutatedInScope(node.declaredElement)) {
      rule.reportLint(node.name);
    }
  }
}
