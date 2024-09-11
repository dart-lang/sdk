// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/lint/linter.dart'; // ignore: implementation_imports

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const lintName = 'use_named_constants';

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

class UseNamedConstants extends LintRule {
  UseNamedConstants()
      : super(
          name: lintName,
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.use_named_constants;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.isConst) {
      var type = node.staticType;
      if (type is! InterfaceType) return;
      var element = type.element;
      if (element is ClassElement) {
        var nodeField =
            node.thisOrAncestorOfType<VariableDeclaration>()?.declaredElement;

        // avoid diagnostic for fields in the same class having the same value
        // class A {
        //   const A();
        //   static const a = A();
        //   static const b = A();
        // }
        if (nodeField?.enclosingElement3 == element) return;

        var library = (node.root as CompilationUnit).declaredElement?.library;
        if (library == null) return;
        var value = node.computeConstantValue().value;
        for (var field
            in element.fields.where((e) => e.isStatic && e.isConst)) {
          if (field.isAccessibleIn(library) &&
              field.computeConstantValue() == value) {
            rule.reportLint(node, arguments: ['${element.name}.${field.name}']);
            return;
          }
        }
      }
    }
  }
}
