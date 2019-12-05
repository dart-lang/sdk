// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r'Prefer using a boolean as the assert condition.';

const _details = r'''

**DO** use a boolean for assert conditions.

Not using booleans in assert conditions can lead to code where it isn't clear
what the intention of the assert statement is.

**BAD:**
```
assert(() {
  f();
  return true;
});
```

**GOOD:**
```
assert(() {
  f();
  return true;
}());
```

**DEPRECATED:** In Dart 2, `assert`s no longer accept  non-`bool` values so this
rule is made redundant by the Dart analyzer's basic checks and is no longer
necessary.
 
The rule will be removed in a future Linter release.
''';

class PreferBoolInAsserts extends LintRule implements NodeLintRule {
  PreferBoolInAsserts()
      : super(
            name: 'prefer_bool_in_asserts',
            description: _desc,
            details: _details,
            maturity: Maturity.deprecated,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this, context);
    registry.addAssertStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final TypeSystem typeSystem;

  final DartType boolType;

  _Visitor(this.rule, LinterContext context)
      : typeSystem = context.typeSystem,
        boolType = context.typeProvider.boolType;

  @override
  void visitAssertStatement(AssertStatement node) {
    var conditionType = _unbound(node.condition.staticType);
    if (!typeSystem.isAssignableTo(conditionType, boolType)) {
      rule.reportLint(node.condition);
    }
  }

  DartType _unbound(DartType type) {
    var t = type;
    while (t is TypeParameterType) {
      t = (t as TypeParameterType).bound;
    }
    return t;
  }
}
