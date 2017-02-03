// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.throw_in_finally;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules/control_flow_in_finally.dart';

const desc = r'Avoid `throw` in finally block.';

const details = r'''
**AVOID** throwing exceptions in finally blocks. This will cause unexpected
behavior that is hard to debug.

**GOOD:**
```
class Ok {
  double compliantMethod() {
    var i = 5;
    try {
      i = 1 / 0;
    } catch (e) {
      print(e); // OK
    }
    return i;
  }
}
```

**BAD:**
```
class BadThrow {
  double nonCompliantMethod() {
    try {
      print('hello world! ${1 / 0}');
    } catch (e) {
      print(e);
    } finally {
      throw 'Find the hidden error :P'; // LINT
    }
  }
}
```
''';

class ThrowInFinally extends LintRule {
  _Visitor _visitor;

  ThrowInFinally()
      : super(
            name: 'throw_in_finally',
            description: desc,
            details: details,
            group: Group.errors) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor
    with ControlFlowInFinallyBlockReporterMixin {
  @override
  final LintRule rule;

  _Visitor(this.rule);

  @override
  visitThrowExpression(ThrowExpression node) {
    reportIfFinallyAncestorExists(node);
  }
}
