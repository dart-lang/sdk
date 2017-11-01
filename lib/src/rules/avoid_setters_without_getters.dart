// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/ast.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Avoid setters without getters.';

const _details = r'''

**DON'T** define a setter without a corresponding getter.

Defining a setter without defining a corresponding getter can lead to logical
inconsistencies.  Doing this could allow you to set a property to some value,
but then upon observing the property's value, it could easily be different.

**BAD:**
```
class Bad {
  int l, r;

  set length(int newLength) {
    r = l + newLength;
  }
}
```

**GOOD:**
```
class Good {
  int l, r;

  int get length => r - l;

  set length(int newLength) {
    r = l + newLength;
  }
}
```

''';

bool _hasGetter(MethodDeclaration node) =>
    DartTypeUtilities.lookUpGetter(node) != null;

bool _hasInheritedSetter(MethodDeclaration node) =>
    DartTypeUtilities.lookUpInheritedConcreteSetter(node) != null;

class AvoidSettersWithoutGetters extends LintRule {
  _Visitor _visitor;
  AvoidSettersWithoutGetters()
      : super(
            name: 'avoid_setters_without_getters',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  LintRule rule;
  _Visitor(this.rule);

  @override
  visitClassDeclaration(ClassDeclaration node) {
    final methods = node.members.where(isMethod);
    for (MethodDeclaration method in methods) {
      if (method.isSetter &&
          !_hasInheritedSetter(method) &&
          !_hasGetter(method)) {
        rule.reportLint(method.name);
      }
    }
  }
}
