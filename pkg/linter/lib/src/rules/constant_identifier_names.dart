// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../utils.dart';

const _desc = r'Prefer using lowerCamelCase for constant names.';

const _details = r'''
**PREFER** using lowerCamelCase for constant names.

In new code, use `lowerCamelCase` for constant variables, including enum values.

In existing code that uses `ALL_CAPS_WITH_UNDERSCORES` for constants, you may
continue to use all caps to stay consistent.

**BAD:**
```dart
const PI = 3.14;
const kDefaultTimeout = 1000;
final URL_SCHEME = RegExp('^([a-z]+):');

class Dice {
  static final NUMBER_GENERATOR = Random();
}
```

**GOOD:**
```dart
const pi = 3.14;
const defaultTimeout = 1000;
final urlScheme = RegExp('^([a-z]+):');

class Dice {
  static final numberGenerator = Random();
}
```

''';

class ConstantIdentifierNames extends LintRule {
  static const LintCode code = LintCode('constant_identifier_names',
      "The constant name '{0}' isn't a lowerCamelCase identifier.",
      correctionMessage:
          'Try changing the name to follow the lowerCamelCase style.');

  ConstantIdentifierNames()
      : super(
            name: 'constant_identifier_names',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addDeclaredVariablePattern(this, visitor);
    registry.addEnumConstantDeclaration(this, visitor);
    registry.addTopLevelVariableDeclaration(this, visitor);
    registry.addVariableDeclarationList(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  void checkIdentifier(Token id) {
    var name = id.lexeme;
    if (!isLowerCamelCase(name)) {
      rule.reportLintForToken(id, arguments: [name]);
    }
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    if (node.parent.isFieldNameShortcut) return;
    checkIdentifier(node.name);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    checkIdentifier(node.name);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    visitVariableDeclarationList(node.variables);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    for (var v in node.variables) {
      if (v.isConst) {
        checkIdentifier(v.name);
      }
    }
  }
}
