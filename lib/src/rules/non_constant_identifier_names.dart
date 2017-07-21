// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const desc = r'Name non-constant identifiers using lowerCamelCase.';

const details = r'''
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

class NonConstantIdentifierNames extends LintRule {
  NonConstantIdentifierNames()
      : super(
            name: 'non_constant_identifier_names',
            description: desc,
            details: details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;
  Visitor(this.rule);

  checkIdentifier(SimpleIdentifier id, {bool underscoresOk: false}) {
    if (underscoresOk && Analyzer.facade.isJustUnderscores(id.name)) {
      // For example, `___` is OK in a callback.
      return;
    }
    if (!Analyzer.facade.isLowerCamelCase(id.name)) {
      rule.reportLint(id);
    }
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.name != null) {
      checkIdentifier(node.name);
    }
  }

  @override
  visitFormalParameterList(FormalParameterList node) {
    node.parameters.forEach((FormalParameter p) {
      if (p is! FieldFormalParameter && p.identifier != null) {
        checkIdentifier(p.identifier, underscoresOk: true);
      }
    });
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    checkIdentifier(node.name);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    if (!node.isOperator) {
      checkIdentifier(node.name);
    }
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
    node.variables.forEach((VariableDeclaration v) {
      if (!v.isConst) {
        checkIdentifier(v.name);
      }
    });
  }
}
