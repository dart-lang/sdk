// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../linter_lint_codes.dart';

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
  OneMemberAbstracts()
      : super(
          name: 'one_member_abstracts',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.one_member_abstracts;

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
    if (node.abstractKeyword == null) return;
    if (node.extendsClause != null) return;

    if (node.macroKeyword != null) return;
    if (node.isAugmentation) return;

    var element = node.declaredElement;
    if (element == null) return;

    if (element.allInterfaces.isNotEmpty) return;
    if (element.allMixins.isNotEmpty) return;
    if (element.allFields.isNotEmpty) return;

    var methods = element.allMethods;
    if (methods.length != 1) return;

    var method = methods.first;
    if (method.isAbstract) {
      rule.reportLintForToken(node.name, arguments: [method.name]);
    }
  }
}
