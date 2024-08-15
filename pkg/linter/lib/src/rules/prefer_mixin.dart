// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r'Prefer using mixins.';

const _details = r'''
Dart 2.1 introduced a new syntax for mixins that provides a safe way for a mixin
to invoke inherited members using `super`. The new style of mixins should always
be used for types that are to be mixed in. As a result, this lint will flag any
uses of a class in a `with` clause.

**BAD:**
```dart
class A {}
class B extends Object with A {}
```

**OK:**
```dart
mixin M {}
class C with M {}
```

''';

class PreferMixin extends LintRule {
  PreferMixin()
      : super(
            name: 'prefer_mixin',
            description: _desc,
            details: _details,
            categories: {
              LintRuleCategory.languageFeatureUsage,
              LintRuleCategory.style
            });

  @override
  LintCode get lintCode => LinterLintCode.prefer_mixin;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addWithClause(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitWithClause(WithClause node) {
    for (var mixinNode in node.mixinTypes) {
      var type = mixinNode.type;
      if (type is InterfaceType) {
        var element = type.element;
        if (element is MixinElement) continue;
        if (element is ClassElement && !element.isMixinClass) {
          rule.reportLint(mixinNode, arguments: [mixinNode.name2.lexeme]);
        }
      }
    }
  }
}
