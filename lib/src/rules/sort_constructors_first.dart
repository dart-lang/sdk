// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Sort constructor declarations before method declarations.';

const _details = r'''

**DO** sort constructor declarations before method declarations.

**GOOD:**
```
abstract class Animation<T> {
  const Animation();
  void addListener(VoidCallback listener);
}
```

**BAD:**
```
abstract class Visitor {
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
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;
  Visitor(this.rule);

  @override
  visitClassDeclaration(ClassDeclaration decl) {
    // Sort members by offset.
    List<ClassMember> members = decl.members.toList()
      ..sort((ClassMember m1, ClassMember m2) => m1.offset - m2.offset);

    bool seenMethod = false;
    for (ClassMember member in members) {
      if (member is ConstructorDeclaration) {
        if (seenMethod) {
          rule.reportLint(member.returnType);
        }
      }
      if (member is MethodDeclaration) {
        seenMethod = true;
      }
    }
  }
}
