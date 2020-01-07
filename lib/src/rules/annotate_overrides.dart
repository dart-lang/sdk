// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r'Annotate overridden members.';

const _details = r'''

**DO** annotate overridden methods and fields.

This practice improves code readability and helps protect against
unintentionally overriding superclass members.

**GOOD:**
```
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

**BAD:**
```
class Cat {
  int get lives => 9;
}

class Lucky extends Cat {
  final int lives = 14;
}
```

''';

class AnnotateOverrides extends LintRule implements NodeLintRule {
  AnnotateOverrides()
      : super(
            name: 'annotate_overrides',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
    registry.addFieldDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  Element getOverriddenMember(Element member) {
    if (member == null) {
      return null;
    }

    final classElement = member.thisOrAncestorOfType<ClassElement>();
    if (classElement == null) {
      return null;
    }

    final libraryUri = classElement.library.source.uri;
    return context.inheritanceManager.getInherited(
      classElement.thisType,
      Name(libraryUri, member.name),
    );
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    for (var field in node.fields.variables) {
      var element = field.declaredElement;
      if (element != null && !element.hasOverride) {
        final member = getOverriddenMember(element);
        if (member != null) {
          rule.reportLint(field);
        }
      }
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    var element = node.declaredElement;
    if (element != null && !element.hasOverride) {
      final member = getOverriddenMember(element);
      if (member != null) {
        rule.reportLint(node.name);
      }
    }
  }
}
