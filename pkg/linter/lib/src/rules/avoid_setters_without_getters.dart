// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Avoid setters without getters.';

const _details = r'''
**DON'T** define a setter without a corresponding getter.

Defining a setter without defining a corresponding getter can lead to logical
inconsistencies.  Doing this could allow you to set a property to some value,
but then upon observing the property's value, it could easily be different.

**BAD:**
```dart
class Bad {
  int l, r;

  set length(int newLength) {
    r = l + newLength;
  }
}
```

**GOOD:**
```dart
class Good {
  int l, r;

  int get length => r - l;

  set length(int newLength) {
    r = l + newLength;
  }
}
```

''';

class AvoidSettersWithoutGetters extends LintRule {
  static const LintCode code = LintCode(
      'avoid_setters_without_getters', 'Setter has no corresponding getter.',
      correctionMessage:
          'Try adding a corresponding getter or removing the setter.');

  AvoidSettersWithoutGetters()
      : super(
            name: 'avoid_setters_without_getters',
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
    registry.addEnumDeclaration(this, visitor);
    registry.addExtensionTypeDeclaration(this, visitor);
    // TODO(pq): consider visiting mixin declarations
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    visitMembers(node.members);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    visitMembers(node.members);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    visitMembers(node.members);
  }

  void visitMembers(NodeList<ClassMember> members) {
    for (var member in members.whereType<MethodDeclaration>()) {
      if (member.isSetter &&
          member.lookUpInheritedConcreteSetter() == null &&
          member.lookUpGetter() == null) {
        rule.reportLintForToken(member.name);
      }
    }
  }
}
