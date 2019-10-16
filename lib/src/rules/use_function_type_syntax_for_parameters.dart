// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Use generic function type syntax for parameters.';

const _details = r'''

Use generic function type syntax for parameters.

**BAD:**
```
Iterable<T> where(bool predicate(T element)) {}
```

**GOOD:**
```
Iterable<T> where(bool Function(T) predicate) {}
```

''';

class UseFunctionTypeSyntaxForParameters extends LintRule
    implements NodeLintRule {
  UseFunctionTypeSyntaxForParameters()
      : super(
            name: 'use_function_type_syntax_for_parameters',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addFunctionTypedFormalParameter(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    rule.reportLint(node);
  }
}
