// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../util/ascii_utils.dart';

const _desc = r'Avoid leading underscores for local identifiers.';

const _details = r'''
**DON'T** use a leading underscore for identifiers that aren't private. Dart
uses a leading underscore in an identifier to mark members and top-level
declarations as private. This trains users to associate a leading underscore
with one of those kinds of declarations. They see `_` and  think "private".
There is no concept of "private" for local variables or parameters.  When one of 
those has a name that starts with an underscore, it sends a confusing signal to
the reader. To avoid that, don't use leading underscores in those names.

**EXCEPTION:**: An unused parameter can be named `_`, `__`, `___`, etc.  This is
common practice in callbacks where you are passed a value but you don't need
to use it. Giving it a name that consists solely of underscores is the idiomatic
way to indicate that the value isn't used.

**BAD:**
```dart
void print(String _name) {
  var _size = _name.length;
  ...
}
```
**GOOD:**

```dart
void print(String name) {
  var size = name.length;
  ...
}
```

**OK:**

```dart
[1,2,3].map((_) => print('Hello'));
```
''';

class NoLeadingUnderscoresForLocalIdentifiers extends LintRule {
  static const LintCode code = LintCode(
      'no_leading_underscores_for_local_identifiers',
      "The local variable '{0}' starts with an underscore.",
      correctionMessage:
          'Try renaming the variable to not start with an underscore.');

  NoLeadingUnderscoresForLocalIdentifiers()
      : super(
            name: 'no_leading_underscores_for_local_identifiers',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addCatchClause(this, visitor);
    registry.addDeclaredIdentifier(this, visitor);
    registry.addFormalParameterList(this, visitor);
    registry.addForPartsWithDeclarations(this, visitor);
    registry.addFunctionDeclarationStatement(this, visitor);
    registry.addDeclaredVariablePattern(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  void checkIdentifier(Token? id) {
    if (id == null) return;
    if (!id.lexeme.hasLeadingUnderscore) return;
    if (id.lexeme.isJustUnderscores) return;

    rule.reportLintForToken(id, arguments: [id.lexeme]);
  }

  @override
  void visitCatchClause(CatchClause node) {
    checkIdentifier(node.exceptionParameter?.name);
    checkIdentifier(node.stackTraceParameter?.name);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    checkIdentifier(node.name);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    if (node.parent.isFieldNameShortcut) return;
    checkIdentifier(node.name);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    for (var parameter in node.parameters) {
      if (parameter is DefaultFormalParameter) {
        parameter = parameter.parameter;
      }
      if (parameter is FieldFormalParameter ||
          parameter is SuperFormalParameter) {
        // These are not local identifiers.
        return;
      }
      if (!parameter.isNamed) {
        // Named parameters produce a `private_optional_parameter` diagnostic.
        checkIdentifier(parameter.name);
      }
    }
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    for (var variable in node.variables.variables) {
      checkIdentifier(variable.name);
    }
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    checkIdentifier(node.functionDeclaration.name);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    for (var variable in node.variables.variables) {
      checkIdentifier(variable.name);
    }
  }
}
