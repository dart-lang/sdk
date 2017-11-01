// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc =
    r'Avoid defining a one-member abstract class when a simple function will do.';

const _details = r'''

From the [style guide](https://www.dartlang.org/articles/style-guide/):

**AVOID** defining a one-member abstract class when a simple function will do.

Unlike Java, Dart has first-class functions, closures, and a nice light syntax
for using them.  If all you need is something like a callback, just use a
function.  If you're defining an class and it only has a single abstract member
with a meaningless name like `call` or `invoke`, there is a good chance
you just want a function.

**GOOD:**
```
typedef bool Predicate(item);
```

**BAD:**
```
abstract class Predicate {
  bool test(item);
}
```

''';

class OneMemberAbstracts extends LintRule {
  OneMemberAbstracts()
      : super(
            name: 'one_member_abstracts',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  LintRule rule;
  Visitor(this.rule);

  @override
  visitClassDeclaration(ClassDeclaration node) {
    if (node.isAbstract &&
        node.extendsClause == null &&
        node.members.length == 1) {
      var member = node.members[0];
      if (member is MethodDeclaration &&
          member.isAbstract &&
          !member.isGetter &&
          !member.isSetter) {
        rule.reportLint(node.name);
      }
    }
  }
}
