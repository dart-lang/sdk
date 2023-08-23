// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../rules/control_flow_in_finally.dart';

const _desc = r'Avoid `throw` in finally block.';

const _details = r'''
**AVOID** throwing exceptions in finally blocks.

Throwing exceptions in finally blocks will inevitably cause unexpected behavior
that is hard to debug.

**BAD:**
```dart
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

**GOOD:**
```dart
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

''';

class ThrowInFinally extends LintRule {
  static const LintCode code = LintCode(
      'throw_in_finally', "Use of '{0}' in 'finally' block.",
      correctionMessage: "Try moving the '{0}' outside the 'finally' block.");

  ThrowInFinally()
      : super(
            name: 'throw_in_finally',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addThrowExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void>
    with ControlFlowInFinallyBlockReporter {
  @override
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitThrowExpression(ThrowExpression node) {
    reportIfFinallyAncestorExists(node, kind: 'throw');
  }
}
