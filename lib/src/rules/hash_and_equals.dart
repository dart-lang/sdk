// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/ast.dart';

const _desc = r'Always override `hashCode` if overriding `==`.';

const _details = r'''

**DO** override `hashCode` if overriding `==`.

Every object in Dart has a `hashCode`.  Both the `==` operator and the
`hashCode` property of objects must be consistent in order for a common hash
map implementation to function properly.  Thus, when overriding `==`, the
`hashCode` should also be overriden to maintain consistency.

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

class HashAndEquals extends LintRule {
  HashAndEquals()
      : super(
            name: 'hash_and_equals',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;
  Visitor(this.rule);

  @override
  visitClassDeclaration(ClassDeclaration node) {
    MethodDeclaration eq, hash;
    for (ClassMember member in node.members) {
      if (isEquals(member)) {
        eq = member;
      } else if (isHashCode(member)) {
        hash = member;
      }
    }

    if (eq != null && hash == null) {
      rule.reportLint(eq.name);
    }
    if (hash != null && eq == null) {
      rule.reportLint(hash.name);
    }
  }
}
