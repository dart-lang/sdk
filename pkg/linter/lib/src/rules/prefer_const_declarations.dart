// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../ast.dart';
import '../linter_lint_codes.dart';

const _desc = r'Prefer `const` over `final` for declarations.';

const _details = r'''
**PREFER** using `const` for constant-valued declarations.

Constant declarations are more hot-reload friendly and allow
values to be used in other constant expressions.

**BAD:**
```dart
final o = const <int>[];

class A {
  static final o = const <int>[];
}
```

**GOOD:**
```dart
const o = <int>[];

class A {
  static const o = <int>[];
}
```

''';

class PreferConstDeclarations extends LintRule {
  PreferConstDeclarations()
      : super(
          name: 'prefer_const_declarations',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.prefer_const_declarations;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFieldDeclaration(this, visitor);
    registry.addTopLevelVariableDeclaration(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (!node.isStatic) return;
    _visitVariableDeclarationList(node.fields);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) =>
      _visitVariableDeclarationList(node.variables);

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) =>
      _visitVariableDeclarationList(node.variables);

  void _visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.isConst) return;
    if (!node.isFinal) return;
    if (node.variables.every((declaration) {
      var initializer = declaration.initializer;
      return initializer != null &&
          (initializer is! TypedLiteral ||
              (initializer.beginToken.keyword == Keyword.CONST)) &&
          !hasConstantError(initializer);
    })) {
      rule.reportLint(node);
    }
  }
}
