// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Sort constructor declarations before other members.';

const _details = r'''

**DO** sort constructor declarations before other members.

**GOOD:**
```dart
abstract class Animation<T> {
  const Animation(this.value);
  double value;
  void addListener(VoidCallback listener);
}
```

**BAD:**
```dart
abstract class Visitor {
  double value;
  visitSomething(Something s);
  Visitor();
}
```

''';

class SortConstructorsFirst extends LintRule {
  SortConstructorsFirst()
      : super(
            name: 'sort_constructors_first',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addEnumDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  void check(NodeList<ClassMember> classMembers) {
    // Sort members by offset.
    var members = classMembers.toList()
      ..sort((ClassMember m1, ClassMember m2) => m1.offset - m2.offset);

    var other = false;
    for (var member in members) {
      if (member is ConstructorDeclaration) {
        if (other) {
          rule.reportLint(member.returnType);
        }
      } else {
        other = true;
      }
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    check(node.members);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    check(node.members);
  }
}
