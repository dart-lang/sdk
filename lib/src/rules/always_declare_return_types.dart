// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart'
    show AstVisitor, FunctionDeclaration, FunctionTypeAlias, MethodDeclaration;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Declare method return types.';

const _details = r'''

**DO** declare method return types.

When declaring a method or function *always* specify a return type.
Declaring return types for functions helps improve your codebase by allowing the
analyzer to more adequately check your code for errors that could occur during
runtime.

**BAD:**
```
main() { }

_bar() => new _Foo();

class _Foo {
  _foo() => 42;
}
```

**GOOD:**
```
void main() { }

_Foo _bar() => new _Foo();

class _Foo {
  int _foo() => 42;
}

typedef bool predicate(Object o);
```

''';

class AlwaysDeclareReturnTypes extends LintRule {
  AlwaysDeclareReturnTypes()
      : super(
            name: 'always_declare_return_types',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;
  Visitor(this.rule);

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    if (!node.isSetter && node.returnType == null) {
      rule.reportLint(node.name);
    }
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (node.returnType == null) {
      rule.reportLint(node.name);
    }
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    if (!node.isSetter &&
        node.returnType == null &&
        node.name.token.type != TokenType.INDEX_EQ) {
      rule.reportLint(node.name);
    }
  }
}
