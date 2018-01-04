import 'package:kernel/ast.dart' as ir;

/// Helper class that traverses a kernel AST subtree to see if it has any
/// continue statements in the body of any switch cases (having continue
/// statements results in a more complex generated code).
class SwitchContinueAnalysis extends ir.Visitor<bool> {
  SwitchContinueAnalysis._();

  static bool containsContinue(ir.Statement switchCaseBody) {
    return switchCaseBody.accept(new SwitchContinueAnalysis._());
  }

  bool visitContinueSwitchStatement(ir.ContinueSwitchStatement continueStmt) {
    // TODO(efortuna): Check what the target of this continue statement actually
    // IS, because depending on where the label points if we have a nested
    // switch statement we might be able to output simpler code (not the complex
    // switch statement).
    return true;
  }

  bool visitBlock(ir.Block block) {
    for (ir.Statement statement in block.statements) {
      if (statement.accept(this)) {
        return true;
      }
    }
    return false;
  }

  bool visitLabeledStatement(ir.LabeledStatement statement) {
    return statement.body.accept(this);
  }

  bool visitDoStatement(ir.DoStatement doStatement) {
    return doStatement.body.accept(this);
  }

  bool visitForStatement(ir.ForStatement forStatement) {
    return forStatement.body.accept(this);
  }

  bool visitForInStatement(ir.ForInStatement forInStatement) {
    return forInStatement.body.accept(this);
  }

  bool visitSwitchStatement(ir.SwitchStatement switchStatement) {
    for (var switchCase in switchStatement.cases) {
      if (switchCase.accept(this)) {
        return true;
      }
    }
    return false;
  }

  bool visitSwitchCase(ir.SwitchCase switchCase) {
    return switchCase.body.accept(this);
  }

  bool visitIfStatement(ir.IfStatement ifStatement) {
    return ifStatement.then.accept(this) ||
        (ifStatement.otherwise != null && ifStatement.otherwise.accept(this));
  }

  bool visitTryCatch(ir.TryCatch tryCatch) {
    if (tryCatch.body.accept(this)) {
      for (var catchStatement in tryCatch.catches) {
        if (catchStatement.accept(this)) {
          return true;
        }
      }
    }
    return false;
  }

  bool visitWhileStatement(ir.WhileStatement statement) {
    return statement.body.accept(this);
  }

  bool visitCatch(ir.Catch catchStatement) {
    return catchStatement.body.accept(this);
  }

  bool visitTryFinally(ir.TryFinally tryFinally) {
    return tryFinally.body.accept(this) && tryFinally.finalizer.accept(this);
  }

  bool visitFunctionDeclaration(ir.FunctionDeclaration declaration) {
    return declaration.function.accept(this);
  }

  bool visitFunctionNode(ir.FunctionNode node) {
    return node.body.accept(this);
  }

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

  bool defaultNode(ir.Node node) => false;
}
