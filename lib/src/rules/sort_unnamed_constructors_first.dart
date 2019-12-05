// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Sort unnamed constructor declarations first.';

const _details = r'''

**DO** sort unnamed constructor declarations first, before named ones.

**GOOD:**
```
abstract class CancelableFuture<T> implements Future<T>  {
  factory CancelableFuture(computation()) => ...
  factory CancelableFuture.delayed(Duration duration, [computation()]) => ...
  ...
}
```

**BAD:**
```
class _PriorityItem {
  factory _PriorityItem.forName(bool isStatic, String name, _MemberKind kind) => ...
  _PriorityItem(this.isStatic, this.kind, this.isPrivate);
  ...
}
```

''';

class SortUnnamedConstructorsFirst extends LintRule implements NodeLintRule {
  SortUnnamedConstructorsFirst()
      : super(
            name: 'sort_unnamed_constructors_first',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Sort members by offset.
    final members = node.members.toList()
      ..sort((ClassMember m1, ClassMember m2) => m1.offset - m2.offset);

    var seenConstructor = false;
    for (var member in members) {
      if (member is ConstructorDeclaration) {
        if (member.name == null) {
          if (seenConstructor) {
            rule.reportLint(member.returnType);
          }
        } else {
          seenConstructor = true;
        }
      }
    }
  }
}
