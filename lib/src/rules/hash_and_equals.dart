// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../ast.dart';

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
```
class Bad {
  final int value;
  Bad(this.value);

  @override
  bool operator ==(Object other) => other is Bad && other.value == value;
}
```

**GOOD:**
```
class Better {
  final int value;
  Better(this.value);

  @override
  bool operator ==(Object other) => other is Better && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
```
''';

class HashAndEquals extends LintRule implements NodeLintRule {
  HashAndEquals()
      : super(
            name: 'hash_and_equals',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static const LintCode hashMemberCode = LintCode(
      'hash_and_equals', 'Override `==` if overriding `hashCode`.',
      correction: 'Implement `==`.');
  static const LintCode equalsMemberCode = LintCode(
      'hash_and_equals', 'Override `hashCode` if overriding `==`.',
      correction: 'Implement `hashCode`.');

  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    MethodDeclaration eq;
    ClassMember hash;
    for (var member in node.members) {
      if (isEquals(member)) {
        eq = member as MethodDeclaration;
      } else if (isHashCode(member)) {
        hash = member;
      }
    }

    if (eq != null && hash == null) {
      rule.reportLint(eq.name, errorCode: equalsMemberCode);
    }
    if (hash != null && eq == null) {
      if (hash is MethodDeclaration) {
        rule.reportLint(hash.name, errorCode: hashMemberCode);
      } else if (hash is FieldDeclaration) {
        rule.reportLint(getFieldIdentifier(hash, 'hashCode'),
            errorCode: hashMemberCode);
      }
    }
  }
}
