// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const desc = 'Prefer bool as assert condition.';

const details = '''
**DO** use bool as assert condition.

**BAD:**
```
assert(() {return f(););
```

**GOOD:**
```
assert(() {return f();)();
```
''';

class PreferBoolInAsserts extends LintRule {
  PreferBoolInAsserts()
      : super(
            name: 'prefer_bool_in_asserts',
            description: desc,
            details: details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;
  Visitor(this.rule);

  @override
  visitAssertStatement(AssertStatement node) {
    if (!DartTypeUtilities.isClass(
        node.condition.staticType, 'bool', 'dart.core')) {
      rule.reportLint(node.condition);
    }
  }
}
