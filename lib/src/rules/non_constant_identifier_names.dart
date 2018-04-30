// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/utils.dart';

const _desc = r'Name non-constant identifiers using lowerCamelCase.';

const _details = r'''

**DO** name non-constant identifiers using lowerCamelCase.

Class members, top-level definitions, variables, parameters, named parameters
and named constructors should capitalize the first letter of each word
except the first word, and use no separators.

**GOOD:**
```
var item;

HttpRequest httpRequest;

align(clearItems) {
  // ...
}
```

''';

class NonConstantIdentifierNames extends LintRule implements NodeLintRule {
  NonConstantIdentifierNames()
      : super(
            name: 'non_constant_identifier_names',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry) {
    final visitor = new _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
    registry.addFormalParameterList(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addVariableDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  checkIdentifier(SimpleIdentifier id, {bool underscoresOk: false}) {
    if (underscoresOk && isJustUnderscores(id.name)) {
      // For example, `___` is OK in a callback.
      return;
    }
    if (!isLowerCamelCase(id.name)) {
      rule.reportLint(id);
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.name != null) {
      checkIdentifier(node.name);
    }
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    node.parameters.forEach((FormalParameter p) {
      if (p is! FieldFormalParameter && p.identifier != null) {
        checkIdentifier(p.identifier, underscoresOk: true);
      }
    });
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    checkIdentifier(node.name);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!node.isOperator) {
      checkIdentifier(node.name);
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (!node.isConst) {
      checkIdentifier(node.name);
    }
  }
}
