// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Annotate overridden members.';

const _details = r'''
**DO** annotate overridden methods and fields.

This practice improves code readability and helps protect against
unintentionally overriding superclass members.

**BAD:**
```dart
class Cat {
  int get lives => 9;
}

class Lucky extends Cat {
  final int lives = 14;
}
```

**GOOD:**
```dart
abstract class Dog {
  String get breed;
  void bark() {}
}

class Husky extends Dog {
  @override
  final String breed = 'Husky';
  @override
  void bark() {}
}
```

''';

class AnnotateOverrides extends LintRule {
  static const LintCode code = LintCode(
      'annotate_overrides',
      "The member '{0}' overrides an inherited member but isn't annotated "
          "with '@override'.",
      correctionMessage: "Try adding the '@override' annotation.");

  AnnotateOverrides()
      : super(
            name: 'annotate_overrides',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addFieldDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  void check(Element? element, Token target) {
    if (element == null || element.hasOverride) return;

    var member = context.inheritanceManager.overriddenMember(element);
    if (member != null) {
      rule.reportLintForToken(target, arguments: [member.name]);
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (node.isStatic) return;
    if (node.parent is ExtensionTypeDeclaration) return;

    for (var field in node.fields.variables) {
      check(field.declaredElement, field.name);
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isStatic) return;
    if (node.parent is ExtensionTypeDeclaration) return;

    check(node.declaredElement, node.name);
  }
}
