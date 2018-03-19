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

class AvoidTypesAsParameterNames extends LintRule {
  AvoidTypesAsParameterNames()
      : super(
            name: 'avoid_types_as_parameter_names',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  Visitor(this.rule);

  final LintRule rule;

  @override
  visitFormalParameterList(FormalParameterList node) {
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
