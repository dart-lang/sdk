// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc =
    r'Avoid defining a one-member abstract class when a simple function will do.';

const _details = r'''
From [Effective Dart](https://dart.dev/effective-dart/design#avoid-defining-a-one-member-abstract-class-when-a-simple-function-will-do):

**AVOID** defining a one-member abstract class when a simple function will do.

Unlike Java, Dart has first-class functions, closures, and a nice light syntax
for using them.  If all you need is something like a callback, just use a
function.  If you're defining a class and it only has a single abstract member
with a meaningless name like `call` or `invoke`, there is a good chance
you just want a function.

**BAD:**
```dart
abstract class Predicate {
  bool test(item);
}
```

**GOOD:**
```dart
typedef Predicate = bool Function(item);
```

''';

class OneMemberAbstracts extends LintRule {
  static const LintCode code = LintCode(
      'one_member_abstracts', 'Unnecessary use of an abstract class.',
      correctionMessage:
          "Try making '{0}' a top-level function and removing the class.");

  OneMemberAbstracts()
      : super(
            name: 'one_member_abstracts',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var declaredElement = node.declaredElement;
    if (declaredElement == null) {
      return;
    }
    if (declaredElement.interfaces.isNotEmpty) {
      return;
    }
    if (declaredElement.mixins.isNotEmpty) {
      return;
    }
    if (node.abstractKeyword != null &&
        node.extendsClause == null &&
        node.members.length == 1) {
      var member = node.members.first;
      if (member is MethodDeclaration &&
          member.isAbstract &&
          !member.isGetter &&
          !member.isSetter) {
        rule.reportLintForToken(node.name, arguments: [member.name.lexeme]);
      }
    }
  }
}
