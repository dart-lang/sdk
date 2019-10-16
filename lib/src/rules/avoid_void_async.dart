// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r'Avoid async functions that return void.';

const _details = r'''

**DO** mark async functions to return Future<void>.

When declaring an async method or function which does not return a value,
declare that it returns Future<void> and not just void.

**BAD:**
```
void f() async {}
void f2() async => null;
```

**GOOD:**
```
Future<void> f() async {}
Future<void> f2() async => null;
```

''';

class AvoidVoidAsync extends LintRule implements NodeLintRule {
  AvoidVoidAsync()
      : super(
            name: 'avoid_void_async',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (_isAsync(node.declaredElement) && _isVoid(node.returnType)) {
      rule.reportLint(node.name);
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (_isAsync(node.declaredElement) && _isVoid(node.returnType)) {
      rule.reportLint(node.name);
    }
  }

  bool _isAsync(ExecutableElement element) {
    if (element == null) {
      return false;
    }
    return element.isAsynchronous || element.isGenerator;
  }

  bool _isVoid(TypeAnnotation typeAnnotation) =>
      typeAnnotation?.type?.isVoid ?? false;
}
