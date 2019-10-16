// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../ast.dart';
import '../util/dart_type_utilities.dart';

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

class AvoidSettersWithoutGetters extends LintRule implements NodeLintRule {
  AvoidSettersWithoutGetters()
      : super(
            name: 'avoid_setters_without_getters',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    for (var member in node.members.where(isMethod)) {
      var method = member as MethodDeclaration;
      if (method.isSetter &&
          !_hasInheritedSetter(method) &&
          !_hasGetter(method)) {
        rule.reportLint(method.name);
      }
    }
  }
}
