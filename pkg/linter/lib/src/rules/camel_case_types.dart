// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../linter_lint_codes.dart';
import '../utils.dart';

const _desc = r'Name types using UpperCamelCase.';

const _details = r'''
From [Effective Dart](https://dart.dev/effective-dart/style#do-name-types-using-uppercamelcase):

**DO** name types using UpperCamelCase.

Classes and typedefs should capitalize the first letter of each word (including
the first word), and use no separators.

**GOOD:**
```dart
class SliderMenu {
  // ...
}

class HttpRequest {
  // ...
}

typedef num Adder(num x, num y);
```

''';

class CamelCaseTypes extends LintRule {
  CamelCaseTypes()
      : super(
          name: 'camel_case_types',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.camel_case_types;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addGenericTypeAlias(this, visitor);
    registry.addClassDeclaration(this, visitor);
    registry.addClassTypeAlias(this, visitor);
    registry.addFunctionTypeAlias(this, visitor);
    registry.addEnumDeclaration(this, visitor);
    registry.addExtensionTypeDeclaration(this, visitor);
    registry.addMixinDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  void check(Token name) {
    var lexeme = name.lexeme;
    if (!isCamelCase(lexeme)) {
      rule.reportLintForToken(name, arguments: [lexeme]);
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (node.isAugmentation) return;

    check(node.name);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    check(node.name);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    if (node.isAugmentation) return;

    check(node.name);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    if (node.isAugmentation) return;

    check(node.name);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    check(node.name);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    check(node.name);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    if (node.isAugmentation) return;

    check(node.name);
  }
}
