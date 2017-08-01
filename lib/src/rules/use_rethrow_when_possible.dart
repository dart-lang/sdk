// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Use rethrow to rethrow a caught exception.';

const _details = r'''

**DO** use rethrow to rethrow a caught exception.

**BAD:**
```
try {
  somethingRisky();
} catch(e) {
  if (!canHandle(e)) throw e;
  handle(e);
}
```

**GOOD:**
```
try {
  somethingRisky();
} catch(e) {
  if (!canHandle(e)) rethrow;
  handle(e);
}
```

''';

class UseRethrowWhenPossible extends LintRule {
  _Visitor _visitor;
  UseRethrowWhenPossible()
      : super(
            name: 'use_rethrow_when_possible',
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
  visitThrowExpression(ThrowExpression node) {
    final element =
        DartTypeUtilities.getCanonicalElementFromIdentifier(node.expression);
    if (element != null) {
      final catchClause =
          node.getAncestor((e) => e is CatchClause) as CatchClause;
      final exceptionParameter = DartTypeUtilities
          .getCanonicalElementFromIdentifier(catchClause?.exceptionParameter);
      if (element == exceptionParameter) {
        rule.reportLint(node);
      }
    }
  }
}
