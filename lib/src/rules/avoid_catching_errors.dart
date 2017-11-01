// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r"Don't explicitly catch Error or types that implement it.";

const _details = r'''

**DON'T** explicitly catch Error or types that implement it.

Errors differ from Exceptions in that Errors can be analyzed and prevented prior
to runtime.  It should almost never be necessary to catch an error at runtime.

**BAD:**
```
try {
  somethingRisky();
} on Error catch(e) {
  doSomething(e);
}
```

**GOOD:**
```
try {
  somethingRisky();
} on Exception catch(e) {
  doSomething(e);
}
```

''';

class AvoidCatchingErrors extends LintRule {
  _Visitor _visitor;
  AvoidCatchingErrors()
      : super(
            name: 'avoid_catching_errors',
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
  visitCatchClause(CatchClause node) {
    final exceptionType = node.exceptionType?.type;
    if (DartTypeUtilities.implementsInterface(
        exceptionType, 'Error', 'dart.core')) {
      rule.reportLint(node);
    }
  }
}
