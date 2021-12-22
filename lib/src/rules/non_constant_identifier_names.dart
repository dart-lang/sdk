// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../util/ascii_utils.dart';
import '../utils.dart';

const _desc = r'Name non-constant identifiers using lowerCamelCase.';

const _details = r'''

**DO** name non-constant identifiers using lowerCamelCase.

Class members, top-level definitions, variables, parameters, named parameters
and named constructors should capitalize the first letter of each word
except the first word, and use no separators.

**GOOD:**
```dart
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
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addCatchClause(this, visitor);
    registry.addConstructorDeclaration(this, visitor);
    registry.addForEachPartsWithDeclaration(this, visitor);
    registry.addFormalParameterList(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addVariableDeclaration(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  void checkIdentifier(SimpleIdentifier? id, {bool underscoresOk = false}) {
    if (id == null) {
      return;
    }
    if (underscoresOk && id.name.isJustUnderscores) {
      // For example, `___` is OK in a callback.
      return;
    }
    if (!isLowerCamelCase(id.name)) {
      rule.reportLint(id);
    }
  }

  @override
  void visitCatchClause(CatchClause node) {
    checkIdentifier(node.exceptionParameter, underscoresOk: true);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    // For rationale on accepting underscores, see:
    // https://github.com/dart-lang/linter/issues/1854
    checkIdentifier(node.name, underscoresOk: true);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    checkIdentifier(node.loopVariable.identifier);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    for (var p in node.parameters) {
      if (p is! FieldFormalParameter) {
        checkIdentifier(p.identifier, underscoresOk: true);
      }
    }
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

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    for (var variable in node.variables.variables) {
      if (!variable.isConst) {
        checkIdentifier(variable.name);
      }
    }
  }
}
