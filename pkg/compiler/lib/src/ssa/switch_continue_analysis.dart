// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

/// Helper class that traverses a kernel AST subtree to see if it has any
/// continue statements in the body of any switch cases (having continue
/// statements results in a more complex generated code).
class SwitchContinueAnalysis extends ir.VisitorDefault<bool>
    with ir.VisitorDefaultValueMixin<bool> {
  SwitchContinueAnalysis._();

  static bool containsContinue(ir.Statement switchCaseBody) {
    return switchCaseBody.accept(SwitchContinueAnalysis._());
  }

  @override
  bool visitContinueSwitchStatement(ir.ContinueSwitchStatement node) {
    // TODO(efortuna): Check what the target of this continue statement actually
    // IS, because depending on where the label points if we have a nested
    // switch statement we might be able to output simpler code (not the complex
    // switch statement).
    return true;
  }

  @override
  bool visitBlock(ir.Block node) {
    for (ir.Statement statement in node.statements) {
      if (statement.accept(this)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool visitLabeledStatement(ir.LabeledStatement node) {
    return node.body.accept(this);
  }

  @override
  bool visitDoStatement(ir.DoStatement node) {
    return node.body.accept(this);
  }

  @override
  bool visitForStatement(ir.ForStatement node) {
    return node.body.accept(this);
  }

  @override
  bool visitForInStatement(ir.ForInStatement node) {
    return node.body.accept(this);
  }

  @override
  bool visitSwitchStatement(ir.SwitchStatement node) {
    for (var switchCase in node.cases) {
      if (switchCase.accept(this)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool visitSwitchCase(ir.SwitchCase node) {
    return node.body.accept(this);
  }

  @override
  bool visitIfStatement(ir.IfStatement node) {
    return node.then.accept(this) ||
        (node.otherwise != null && node.otherwise!.accept(this));
  }

  @override
  bool visitTryCatch(ir.TryCatch node) {
    if (node.body.accept(this)) {
      for (var catchStatement in node.catches) {
        if (catchStatement.accept(this)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  bool visitWhileStatement(ir.WhileStatement node) {
    return node.body.accept(this);
  }

  @override
  bool visitCatch(ir.Catch node) {
    return node.body.accept(this);
  }

  @override
  bool visitTryFinally(ir.TryFinally node) {
    return node.body.accept(this) && node.finalizer.accept(this);
  }

  @override
  bool visitFunctionDeclaration(ir.FunctionDeclaration node) {
    return node.function.accept(this);
  }

  @override
  bool visitFunctionNode(ir.FunctionNode node) {
    return node.body!.accept(this);
  }

  @override
  bool defaultStatement(ir.Statement node) {
    if (node is ir.ExpressionStatement ||
        node is ir.EmptyStatement ||
        node is ir.BreakStatement ||
        node is ir.ReturnStatement ||
        node is ir.AssertStatement ||
        node is ir.YieldStatement ||
        node is ir.VariableDeclaration) {
      return false;
    }
    throw 'Statement type ${node.runtimeType} not handled in '
        'SwitchContinueAnalysis';
  }

  @override
  bool get defaultValue => false;
}
