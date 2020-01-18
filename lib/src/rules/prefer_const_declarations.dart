// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../ast.dart';

const _desc = r'Prefer const over final for declarations.';

const _details = r'''

**PREFER** using `const` for const declarations.

Const declarations are more hot-reload friendly and allow to use const
constructors if an instantiation references this declaration.

**GOOD:**
```
const o = <int>[];

class A {
  static const o = <int>[];
}
```

**BAD:**
```
final o = const <int>[];

class A {
  static final o = const <int>[];
}
```

''';

class PreferConstDeclarations extends LintRule implements NodeLintRule {
  PreferConstDeclarations()
      : super(
            name: 'prefer_const_declarations',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this, context);
    registry.addFieldDeclaration(this, visitor);
    registry.addTopLevelVariableDeclaration(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;

  _Visitor(this.rule, this.context);

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
              (initializer.beginToken?.keyword == Keyword.CONST)) &&
          !hasConstantError(context, initializer);
    })) {
      rule.reportLint(node);
    }
  }
}
