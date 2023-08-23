// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r'Avoid defining a class that contains only static members.';

const _details = r'''
From [Effective Dart](https://dart.dev/effective-dart/design#avoid-defining-a-class-that-contains-only-static-members):

**AVOID** defining a class that contains only static members.

Creating classes with the sole purpose of providing utility or otherwise static
methods is discouraged.  Dart allows functions to exist outside of classes for
this very reason.

**BAD:**
```dart
class DateUtils {
  static DateTime mostRecent(List<DateTime> dates) {
    return dates.reduce((a, b) => a.isAfter(b) ? a : b);
  }
}

class _Favorites {
  static const mammal = 'weasel';
}
```

**GOOD:**
```dart
DateTime mostRecent(List<DateTime> dates) {
  return dates.reduce((a, b) => a.isAfter(b) ? a : b);
}

const _favoriteMammal = 'weasel';
```

''';

bool _isNonConst(FieldElement element) => !element.isConst;

bool _isStaticMember(ClassMember classMember) {
  if (classMember is MethodDeclaration) {
    return classMember.isStatic;
  }
  if (classMember is FieldDeclaration) {
    return classMember.isStatic;
  }
  return false;
}

class AvoidClassesWithOnlyStaticMembers extends LintRule {
  static const LintCode code = LintCode(
      'avoid_classes_with_only_static_members',
      'Classes should define instance members.',
      correctionMessage:
          'Try adding instance behavior or moving the members out of the class.');

  AvoidClassesWithOnlyStaticMembers()
      : super(
            name: 'avoid_classes_with_only_static_members',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var declaredElement = node.declaredElement;
    if (declaredElement == null) {
      return;
    }

    var interface = context.inheritanceManager.getInterface(declaredElement);
    var map = interface.map;
    for (var member in map.values) {
      var enclosingElement = member.enclosingElement;
      if (enclosingElement is ClassElement &&
          !enclosingElement.isDartCoreObject) {
        return;
      }
    }

    if (node.members.isNotEmpty &&
        node.members.every(_isStaticMember) &&
        (declaredElement.methods.isNotEmpty ||
            declaredElement.fields.any(_isNonConst))) {
      rule.reportLint(node);
    }
  }
}
