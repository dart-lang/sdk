// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../linter_lint_codes.dart';

const _desc = r'Declare method return types.';

const _details = r'''
**DO** declare method return types.

When declaring a method or function *always* specify a return type.
Declaring return types for functions helps improve your codebase by allowing the
analyzer to more adequately check your code for errors that could occur during
runtime.

**BAD:**
```dart
main() { }

_bar() => _Foo();

class _Foo {
  _foo() => 42;
}
```

**GOOD:**
```dart
void main() { }

_Foo _bar() => _Foo();

class _Foo {
  int _foo() => 42;
}

typedef predicate = bool Function(Object o);
```

''';

class AlwaysDeclareReturnTypes extends LintRule {
  AlwaysDeclareReturnTypes()
      : super(
            name: 'always_declare_return_types',
            description: _desc,
            details: _details,
            categories: {LintRuleCategory.style});

  @override
  List<LintCode> get lintCodes => [
        LinterLintCode.always_declare_return_types_of_functions,
        LinterLintCode.always_declare_return_types_of_methods
      ];

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addFunctionDeclaration(this, visitor);
    registry.addFunctionTypeAlias(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (!node.isSetter && node.returnType == null && !node.isAugmentation) {
      rule.reportLintForToken(node.name,
          arguments: [node.name.lexeme],
          errorCode: LinterLintCode.always_declare_return_types_of_functions);
    }
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (node.returnType == null) {
      rule.reportLintForToken(node.name,
          arguments: [node.name.lexeme],
          errorCode: LinterLintCode.always_declare_return_types_of_functions);
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.returnType != null) return;
    if (node.isAugmentation) return;
    if (node.isSetter) return;
    if (node.name.type == TokenType.INDEX_EQ) return;

    if (context.isInTestDirectory) {
      if (node.name.lexeme.startsWith('test_') ||
          node.name.lexeme.startsWith('solo_test_')) {
        return;
      }
    }

    rule.reportLintForToken(
      node.name,
      arguments: [node.name.lexeme],
      errorCode: LinterLintCode.always_declare_return_types_of_methods,
    );
  }
}
