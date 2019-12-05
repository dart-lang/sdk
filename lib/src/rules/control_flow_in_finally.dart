// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Avoid control flow in finally blocks.';

const _details = r'''

**AVOID** control flow leaving finally blocks.

Using control flow in finally blocks will inevitably cause unexpected behavior
that is hard to debug.

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
class BadReturn {
  double nonCompliantMethod() {
    try {
      return 1 / 0;
    } catch (e) {
      print(e);
    } finally {
      return 1.0; // LINT
    }
  }
}
```

**BAD:**
```
class BadContinue {
  double nonCompliantMethod() {
    for (var o in [1, 2]) {
      try {
        print(o / 0);
      } catch (e) {
        print(e);
      } finally {
        continue; // LINT
      }
    }
    return 1.0;
  }
}
```

**BAD:**
```
class BadBreak {
  double nonCompliantMethod() {
    for (var o in [1, 2]) {
      try {
        print(o / 0);
      } catch (e) {
        print(e);
      } finally {
        break; // LINT
      }
    }
    return 1.0;
  }
}
```

''';

class ControlFlowInFinally extends LintRule implements NodeLintRule {
  ControlFlowInFinally()
      : super(
            name: 'control_flow_in_finally',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addBreakStatement(this, visitor);
    registry.addContinueStatement(this, visitor);
    registry.addReturnStatement(this, visitor);
  }
}

/// Do not extend this class, it is meant to be used from
/// [ControlFlowInFinally] which is in a separate rule to allow a more granular
/// configurability given that reporting throw statements in a finally clause is
/// controversial.
abstract class ControlFlowInFinallyBlockReporterMixin {
  LintRule get rule;

  void reportIfFinallyAncestorExists(AstNode node, {AstNode ancestor}) {
    final tryStatement = node.thisOrAncestorOfType<TryStatement>();
    final finallyBlock = tryStatement?.finallyBlock;
    bool finallyBlockAncestorPredicate(AstNode n) => n == finallyBlock;
    if (tryStatement == null ||
        finallyBlock == null ||
        node.thisOrAncestorMatching(finallyBlockAncestorPredicate) == null) {
      return;
    }

    final enablerNode = _findEnablerNode(
        ancestor, finallyBlockAncestorPredicate, node, tryStatement);
    if (enablerNode == null) {
      rule.reportLint(node);
    }
  }

  AstNode _findEnablerNode(
      AstNode ancestor,
      bool Function(AstNode n) finallyBlockAncestorPredicate,
      AstNode node,
      TryStatement tryStatement) {
    AstNode enablerNode;
    if (ancestor == null) {
      bool functionBlockPredicate(n) =>
          n is FunctionBody &&
          n.thisOrAncestorMatching(finallyBlockAncestorPredicate) != null;
      enablerNode = node.thisOrAncestorMatching(functionBlockPredicate);
    } else {
      enablerNode = ancestor.thisOrAncestorMatching((n) => n == tryStatement);
    }

    return enablerNode;
  }
}

class _Visitor extends SimpleAstVisitor<void>
    with ControlFlowInFinallyBlockReporterMixin {
  @override
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitBreakStatement(BreakStatement node) {
    reportIfFinallyAncestorExists(node, ancestor: node.target);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    reportIfFinallyAncestorExists(node, ancestor: node.target);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    reportIfFinallyAncestorExists(node);
  }
}
