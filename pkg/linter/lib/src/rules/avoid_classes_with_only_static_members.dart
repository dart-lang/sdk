// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../linter_lint_codes.dart';

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

class AvoidClassesWithOnlyStaticMembers extends LintRule {
  AvoidClassesWithOnlyStaticMembers()
      : super(
          name: 'avoid_classes_with_only_static_members',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode =>
      LinterLintCode.avoid_classes_with_only_static_members;

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
    var element = node.declaredElement;
    if (element == null || element.isAugmentation || element.isSealed) {
      return;
    }

    var interface = context.inheritanceManager.getInterface(element);
    var map = interface.map;
    for (var member in map.values) {
      var enclosingElement = member.enclosingElement3;
      if (enclosingElement is ClassElement &&
          !enclosingElement.isDartCoreObject) {
        return;
      }
    }

    var declaredElement = node.declaredElement;
    if (declaredElement == null) return;

    var constructors = declaredElement.allConstructors;
    if (constructors.isNotEmpty &&
        constructors.any((c) => !c.isDefaultConstructor)) {
      return;
    }

    var methods = declaredElement.allMethods;
    if (methods.isNotEmpty && !methods.every((m) => m.isStatic)) return;

    if (methods.isNotEmpty ||
        declaredElement.allFields.any((f) => !f.isConst)) {
      rule.reportLint(node);
    }
  }
}
