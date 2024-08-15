// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';

import '../analyzer.dart';
import '../ast.dart';
import '../extensions.dart';
import '../linter_lint_codes.dart';

const _desc = r'Always override `hashCode` if overriding `==`.';

const _details = r'''
**DO** override `hashCode` if overriding `==` and prefer overriding `==` if
overriding `hashCode`.

Every object in Dart has a `hashCode`.  Both the `==` operator and the
`hashCode` property of objects must be consistent in order for a common hash
map implementation to function properly.  Thus, when overriding `==`, the
`hashCode` should also be overridden to maintain consistency. Similarly, if
`hashCode` is overridden, `==` should be also.

**BAD:**
```dart
class Bad {
  final int value;
  Bad(this.value);

  @override
  bool operator ==(Object other) => other is Bad && other.value == value;
}
```

**GOOD:**
```dart
class Better {
  final int value;
  Better(this.value);

  @override
  bool operator ==(Object other) =>
      other is Better &&
      other.runtimeType == runtimeType &&
      other.value == value;

  @override
  int get hashCode => value.hashCode;
}
```
''';

class HashAndEquals extends LintRule {
  HashAndEquals()
      : super(
            name: 'hash_and_equals',
            description: _desc,
            details: _details,
            categories: {LintRuleCategory.errorProne});

  @override
  LintCode get lintCode => LinterLintCode.hash_and_equals;

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
    MethodDeclaration? eq;
    ClassMember? hash;
    for (var member in node.members) {
      if (isEquals(member)) {
        eq = member as MethodDeclaration;
      } else if (isHashCode(member)) {
        hash = member;
      }
    }
    if (eq == null && hash == null) return;

    if (eq == null) {
      if (!node.hasMethod('==')) {
        if (hash is MethodDeclaration) {
          rule.reportLintForToken(hash.name, arguments: ['==', 'hashCode']);
        } else if (hash is FieldDeclaration) {
          rule.reportLintForToken(getFieldName(hash, 'hashCode'),
              arguments: ['==', 'hashCode']);
        }
      }
    }

    if (hash == null) {
      if (!node.hasField('hashCode') && !node.hasMethod('hashCode')) {
        rule.reportLintForToken(eq!.name, arguments: ['hashCode', '==']);
      }
    }
  }
}

extension on ClassDeclaration {
  bool hasField(String name) =>
      declaredElement?.allFields.namedOrNull(name) != null;
  bool hasMethod(String name) =>
      declaredElement?.allMethods.namedOrNull(name) != null;
}

extension<E extends ClassMemberElement> on List<E> {
  E? namedOrNull(String name) => firstWhereOrNull((e) => e.name == name);
}
