// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Avoid annotating with dynamic when not required.';

const _details = r'''

**AVOID** annotating with dynamic when not required.

As `dynamic` is the assumed return value of a function or method, it is usually
not necessary to annotate it.

**BAD:**
```
dynamic lookUpOrDefault(String name, Map map, dynamic defaultValue) {
  var value = map[name];
  if (value != null) return value;
  return defaultValue;
}
```

**GOOD:**
```
lookUpOrDefault(String name, Map map, defaultValue) {
  var value = map[name];
  if (value != null) return value;
  return defaultValue;
}
```

''';

class AvoidAnnotatingWithDynamic extends LintRule {
  _Visitor _visitor;
  AvoidAnnotatingWithDynamic()
      : super(
            name: 'avoid_annotating_with_dynamic',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  visitSimpleFormalParameter(SimpleFormalParameter node) {
    final type = node.type;
    if (type is TypeName && type.name.name == 'dynamic') {
      rule.reportLint(node);
    }
  }
}
