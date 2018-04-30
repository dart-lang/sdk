// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Avoid types as parameter names.';

const _details = r'''

**AVOID** using parameter names that is the same as an existing type.

**BAD:**
```
m(f(int));
```

**GOOD:**
```
m(f(int v));
```

''';

class AvoidTypesAsParameterNames extends LintRule implements NodeLintRule {
  AvoidTypesAsParameterNames()
      : super(
            name: 'avoid_types_as_parameter_names',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(NodeLintRegistry registry) {
    final visitor = new _Visitor(this);
    registry.addFormalParameterList(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFormalParameterList(FormalParameterList node) {
    if (node.parent is GenericFunctionType) return;

    // TODO(a14n) test that parameter name matches a existing type. No api to do
    // that for now.
    for (final parameter in node.parameters) {
      if (parameter.element.hasImplicitType &&
          (parameter.identifier.name.startsWith(new RegExp('[A-Z]')) ||
              ['num', 'int', 'double', 'bool', 'dynamic']
                  .contains(parameter.identifier.name))) {
        rule.reportLint(parameter.identifier);
      }
    }
  }
}
