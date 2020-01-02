// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Prefer generic function type aliases.';

const _details = r'''

**PREFER** generic function type aliases.

With the introduction of generic functions, function type aliases
(`typedef void F()`) couldn't express all of the possible kinds of
parameterization that users might want to express. Generic function type aliases
(`typedef F = void Function()`) fixed that issue.

For consistency and readability reasons, it's better to only use one syntax and
thus prefer generic function type aliases.

**BAD:**
```
typedef void F();
```

**GOOD:**
```
typedef F = void Function();
```

''';

class PreferGenericFunctionTypeAliases extends LintRule
    implements NodeLintRule {
  PreferGenericFunctionTypeAliases()
      : super(
            name: 'prefer_generic_function_type_aliases',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addFunctionTypeAlias(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    rule.reportLint(node.name);
  }
}
