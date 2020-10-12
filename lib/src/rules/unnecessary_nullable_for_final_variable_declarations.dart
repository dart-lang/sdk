// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Use a non-nullable type for a final variable initialized '
    'with a non-nullable value.';

const _details = r'''

Use a non-nullable type for a final variable initialized with a non-nullable
value.

**BAD:**
```
final int? i = 1;
```

**GOOD:**
```
final int i = 1;
```

''';

class UnnecessaryNullableForFinalVariableDeclarations extends LintRule
    implements NodeLintRule {
  UnnecessaryNullableForFinalVariableDeclarations()
      : super(
            name: 'unnecessary_nullable_for_final_variable_declarations',
            description: _desc,
            details: _details,
            maturity: Maturity.experimental,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (!context.isEnabled(Feature.non_nullable)) {
      return;
    }

    final visitor = _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
    registry.addFieldDeclaration(this, visitor);
    registry.addTopLevelVariableDeclaration(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final LintRule rule;
  final LinterContext context;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    for (var variable in node.fields.variables) {
      if (Identifier.isPrivateName(variable.name.name) || node.isStatic) {
        _visit(variable);
      }
    }
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    node.variables.variables.forEach(_visit);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    node.variables.variables.forEach(_visit);
  }

  void _visit(VariableDeclaration variable) {
    if (!variable.isFinal && !variable.isConst) {
      return;
    }
    if (variable.isSynthetic) {
      return;
    }
    if (variable.initializer == null) {
      return;
    }
    if (variable.declaredElement.type.isDynamic) {
      return;
    }
    if (context.typeSystem.isNullable(variable.declaredElement.type) &&
        context.typeSystem.isNonNullable(variable.initializer.staticType)) {
      rule.reportLint(variable);
    }
  }
}
