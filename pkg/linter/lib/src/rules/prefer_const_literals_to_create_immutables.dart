// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/lint/linter.dart'; // ignore: implementation_imports

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const desc =
    'Prefer const literals as parameters of constructors on @immutable classes.';

const details = '''
**PREFER** using `const` for instantiating list, map and set literals used as
parameters in immutable class instantiations.

**BAD:**
```dart
@immutable
class A {
  A(this.v);
  final v;
}

A a1 = new A([1]);
A a2 = new A({});
```

**GOOD:**
```dart
A a1 = new A(const [1]);
A a2 = new A(const {});
```

''';

class PreferConstLiteralsToCreateImmutables extends LintRule {
  PreferConstLiteralsToCreateImmutables()
      : super(
            name: 'prefer_const_literals_to_create_immutables',
            description: desc,
            details: details,
            categories: {LintRuleCategory.style});

  @override
  LintCode get lintCode =>
      LinterLintCode.prefer_const_literals_to_create_immutables;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addListLiteral(this, visitor);
    registry.addSetOrMapLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitListLiteral(ListLiteral node) => _visitTypedLiteral(node);

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _visitTypedLiteral(node);
  }

  void _visitTypedLiteral(TypedLiteral literal) {
    if (literal.isConst) return;

    // looking for parent instance creation to check if class is immutable
    AstNode? node = literal;
    while (node is! InstanceCreationExpression &&
        (node is ParenthesizedExpression ||
            node is ArgumentList ||
            node is ListLiteral ||
            node is SetOrMapLiteral ||
            node is MapLiteralEntry ||
            node is NamedExpression)) {
      node = node?.parent;
    }
    if (!(node is InstanceCreationExpression &&
        _hasImmutableAnnotation(node.staticType))) {
      return;
    }

    if (literal.canBeConst) {
      rule.reportLint(literal);
    }
  }

  // TODO(pq): consider making this a utility and sharing w/ `avoid_equals_and_hash_code_on_mutable_classes`
  static bool _hasImmutableAnnotation(DartType? type) {
    if (type is! InterfaceType) {
      // This happens when we find an instance creation expression for a class
      // that cannot be resolved.
      return false;
    }

    InterfaceType? current = type;
    while (current != null) {
      if (current.element.hasImmutable) return true;
      current = current.superclass;
    }

    return false;
  }
}
