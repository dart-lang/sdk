// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r'Use predefined named constants.';

const _details = r'''

Where possible, use already defined const values.

**BAD:**
```dart
const Duration(seconds: 0);
```

**GOOD:**
```dart
Duration.zero;
```

''';
const lintName = 'use_named_constants';

class UseNamedConstants extends LintRule implements NodeLintRule {
  UseNamedConstants()
      : super(
          name: lintName,
          description: _desc,
          details: _details,
          group: Group.style,
        );

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this, context);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final LintRule rule;
  final LinterContext context;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.isConst) {
      final element = node.staticType?.element;
      if (element is ClassElement) {
        final nodeField =
            node.thisOrAncestorOfType<VariableDeclaration>()?.declaredElement;

        // avoid diagnostic for fields in the same class having the same value
        // class A {
        //   const A();
        //   static const a = A();
        //   static const b = A();
        // }
        if (nodeField?.enclosingElement == element) return;

        final library = (node.root as CompilationUnit).declaredElement?.library;
        final value = context.evaluateConstant(node).value;
        for (final field
            in element.fields.where((e) => e.isStatic && e.isConst)) {
          if (field.isAccessibleIn(library) &&
              field.computeConstantValue() == value) {
            rule.reportLint(node,
                arguments: ['${element.name}.${field.name}'],
                errorCode: const LintCode(lintName,
                    "The constant '{0}' should be referenced instead of duplicating its value.",
                    correction: "Try using the predefined constant '{0}'."));
            return;
          }
        }
      }
    }
  }
}
