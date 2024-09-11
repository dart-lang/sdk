// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r'Sort unnamed constructor declarations first.';

const _details = r'''
**DO** sort unnamed constructor declarations first, before named ones.

**BAD:**
```dart
class _PriorityItem {
  factory _PriorityItem.forName(bool isStatic, String name, _MemberKind kind) => ...
  _PriorityItem(this.isStatic, this.kind, this.isPrivate);
  ...
}
```

**GOOD:**
```dart
abstract class CancelableFuture<T> implements Future<T>  {
  factory CancelableFuture(computation()) => ...
  factory CancelableFuture.delayed(Duration duration, [computation()]) => ...
  ...
}
```

''';

class SortUnnamedConstructorsFirst extends LintRule {
  SortUnnamedConstructorsFirst()
      : super(
          name: 'sort_unnamed_constructors_first',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.sort_unnamed_constructors_first;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addEnumDeclaration(this, visitor);
    registry.addExtensionTypeDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  void check(NodeList<ClassMember> members) {
    var seenConstructor = false;
    // Members are sorted by source position in the AST.
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

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    check(node.members);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    check(node.members);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    if (node.representation.constructorName == null) return;
    check(node.members);
  }
}
