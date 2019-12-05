// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r'Prefer using mixins.';

const _details = r'''

Dart 2.1 introduced a new syntax for mixins that provides a safe way for a mixin
to invoke inherited members using `super`. The new style of mixins should always
be used for types that are to be mixed in. As a result, this lint will flag any
uses of a class in a `with` clause.

**BAD:**
```
class A {}
class B extends Object with A {}
```

**OK:**
```
mixin M {}
class C with M {}
```

''';

class PreferMixin extends LintRule implements NodeLintRule {
  PreferMixin()
      : super(
            name: 'prefer_mixin',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addWithClause(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitWithClause(WithClause node) {
    for (var type in node.mixinTypes) {
      final element = type.name.staticElement;
      if (element is ClassElement && !element.isMixin) {
        rule.reportLint(type);
      }
    }
  }
}
