// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_ast;

abstract class NodeVisitor<T> {
  T visitProgram(Program node);

  T visitBlock(Block node);
  T visitExpressionStatement(ExpressionStatement node);
  T visitEmptyStatement(EmptyStatement node);
  T visitIf(If node);
  T visitFor(For node);
  T visitForIn(ForIn node);
  T visitWhile(While node);
  T visitDo(Do node);
  T visitContinue(Continue node);
  T visitBreak(Break node);
  T visitReturn(Return node);
  T visitThrow(Throw node);
  T visitTry(Try node);
  T visitCatch(Catch node);
  T visitSwitch(Switch node);
  T visitCase(Case node);
  T visitDefault(Default node);
  T visitFunctionDeclaration(FunctionDeclaration node);
  T visitLabeledStatement(LabeledStatement node);
  T visitLiteralStatement(LiteralStatement node);
  T visitDartYield(DartYield node);

  T visitLiteralExpression(LiteralExpression node);
  T visitVariableDeclarationList(VariableDeclarationList node);
  T visitAssignment(Assignment node);
  T visitVariableInitialization(VariableInitialization node);
  T visitConditional(Conditional cond);
  T visitNew(New node);
  T visitCall(Call node);
  T visitBinary(Binary node);
  T visitPrefix(Prefix node);
  T visitPostfix(Postfix node);

  T visitVariableUse(VariableUse node);
  T visitThis(This node);
  T visitVariableDeclaration(VariableDeclaration node);
  T visitParameter(Parameter node);
  T visitAccess(PropertyAccess node);

  T visitNamedFunction(NamedFunction node);
  T visitFun(Fun node);

  T visitDeferredExpression(DeferredExpression node);
  T visitDeferredNumber(DeferredNumber node);
  T visitDeferredString(DeferredString node);

  T visitLiteralBool(LiteralBool node);
  T visitLiteralString(LiteralString node);
  T visitLiteralNumber(LiteralNumber node);
  T visitLiteralNull(LiteralNull node);

  T visitStringConcatenation(StringConcatenation node);

  T visitName(Name node);

  T visitArrayInitializer(ArrayInitializer node);
  T visitArrayHole(ArrayHole node);
  T visitObjectInitializer(ObjectInitializer node);
  T visitProperty(Property node);
  T visitRegExpLiteral(RegExpLiteral node);

  T visitAwait(Await node);

  T visitComment(Comment node);

  T visitInterpolatedExpression(InterpolatedExpression node);
  T visitInterpolatedLiteral(InterpolatedLiteral node);
  T visitInterpolatedParameter(InterpolatedParameter node);
  T visitInterpolatedSelector(InterpolatedSelector node);
  T visitInterpolatedStatement(InterpolatedStatement node);
  T visitInterpolatedDeclaration(InterpolatedDeclaration node);
}

class BaseVisitor<T> implements NodeVisitor<T> {
  const BaseVisitor();

  T visitNode(Node node) {
    node.visitChildren(this);
    return null;
  }

  T visitProgram(Program node) => visitNode(node);

  T visitStatement(Statement node) => visitNode(node);
  T visitLoop(Loop node) => visitStatement(node);
  T visitJump(Statement node) => visitStatement(node);

  T visitBlock(Block node) => visitStatement(node);
  T visitExpressionStatement(ExpressionStatement node) => visitStatement(node);
  T visitEmptyStatement(EmptyStatement node) => visitStatement(node);
  T visitIf(If node) => visitStatement(node);
  T visitFor(For node) => visitLoop(node);
  T visitForIn(ForIn node) => visitLoop(node);
  T visitWhile(While node) => visitLoop(node);
  T visitDo(Do node) => visitLoop(node);
  T visitContinue(Continue node) => visitJump(node);
  T visitBreak(Break node) => visitJump(node);
  T visitReturn(Return node) => visitJump(node);
  T visitThrow(Throw node) => visitJump(node);
  T visitTry(Try node) => visitStatement(node);
  T visitSwitch(Switch node) => visitStatement(node);
  T visitFunctionDeclaration(FunctionDeclaration node) => visitStatement(node);
  T visitLabeledStatement(LabeledStatement node) => visitStatement(node);
  T visitLiteralStatement(LiteralStatement node) => visitStatement(node);

  T visitCatch(Catch node) => visitNode(node);
  T visitCase(Case node) => visitNode(node);
  T visitDefault(Default node) => visitNode(node);

  T visitExpression(Expression node) => visitNode(node);
  T visitVariableReference(VariableReference node) => visitExpression(node);

  T visitLiteralExpression(LiteralExpression node) => visitExpression(node);
  T visitVariableDeclarationList(VariableDeclarationList node) =>
      visitExpression(node);
  T visitAssignment(Assignment node) => visitExpression(node);
  T visitVariableInitialization(VariableInitialization node) {
    if (node.value != null) {
      return visitAssignment(node);
    } else {
      return visitExpression(node);
    }
  }

  T visitConditional(Conditional node) => visitExpression(node);
  T visitNew(New node) => visitExpression(node);
  T visitCall(Call node) => visitExpression(node);
  T visitBinary(Binary node) => visitExpression(node);
  T visitPrefix(Prefix node) => visitExpression(node);
  T visitPostfix(Postfix node) => visitExpression(node);
  T visitAccess(PropertyAccess node) => visitExpression(node);

  T visitVariableUse(VariableUse node) => visitVariableReference(node);
  T visitVariableDeclaration(VariableDeclaration node) =>
      visitVariableReference(node);
  T visitParameter(Parameter node) => visitVariableDeclaration(node);
  T visitThis(This node) => visitParameter(node);

  T visitNamedFunction(NamedFunction node) => visitExpression(node);
  T visitFun(Fun node) => visitExpression(node);

  T visitToken(DeferredToken node) => visitExpression(node);

  T visitDeferredExpression(DeferredExpression node) => visitExpression(node);
  T visitDeferredNumber(DeferredNumber node) => visitToken(node);
  T visitDeferredString(DeferredString node) => visitToken(node);

  T visitLiteral(Literal node) => visitExpression(node);

  T visitLiteralBool(LiteralBool node) => visitLiteral(node);
  T visitLiteralString(LiteralString node) => visitLiteral(node);
  T visitLiteralNumber(LiteralNumber node) => visitLiteral(node);
  T visitLiteralNull(LiteralNull node) => visitLiteral(node);

  T visitStringConcatenation(StringConcatenation node) => visitLiteral(node);

  T visitName(Name node) => visitNode(node);

  T visitArrayInitializer(ArrayInitializer node) => visitExpression(node);
  T visitArrayHole(ArrayHole node) => visitExpression(node);
  T visitObjectInitializer(ObjectInitializer node) => visitExpression(node);
  T visitProperty(Property node) => visitNode(node);
  T visitRegExpLiteral(RegExpLiteral node) => visitExpression(node);

  T visitInterpolatedNode(InterpolatedNode node) => visitNode(node);

  T visitInterpolatedExpression(InterpolatedExpression node) =>
      visitInterpolatedNode(node);
  T visitInterpolatedLiteral(InterpolatedLiteral node) =>
      visitInterpolatedNode(node);
  T visitInterpolatedParameter(InterpolatedParameter node) =>
      visitInterpolatedNode(node);
  T visitInterpolatedSelector(InterpolatedSelector node) =>
      visitInterpolatedNode(node);
  T visitInterpolatedStatement(InterpolatedStatement node) =>
      visitInterpolatedNode(node);
  T visitInterpolatedDeclaration(InterpolatedDeclaration node) {
    return visitInterpolatedNode(node);
  }

  // Ignore comments by default.
  T visitComment(Comment node) => null;

  T visitAwait(Await node) => visitExpression(node);
  T visitDartYield(DartYield node) => visitStatement(node);
}

abstract class NodeVisitor1<R, A> {
  R visitProgram(Program node, A arg);

  R visitBlock(Block node, A arg);
  R visitExpressionStatement(ExpressionStatement node, A arg);
  R visitEmptyStatement(EmptyStatement node, A arg);
  R visitIf(If node, A arg);
  R visitFor(For node, A arg);
  R visitForIn(ForIn node, A arg);
  R visitWhile(While node, A arg);
  R visitDo(Do node, A arg);
  R visitContinue(Continue node, A arg);
  R visitBreak(Break node, A arg);
  R visitReturn(Return node, A arg);
  R visitThrow(Throw node, A arg);
  R visitTry(Try node, A arg);
  R visitCatch(Catch node, A arg);
  R visitSwitch(Switch node, A arg);
  R visitCase(Case node, A arg);
  R visitDefault(Default node, A arg);
  R visitFunctionDeclaration(FunctionDeclaration node, A arg);
  R visitLabeledStatement(LabeledStatement node, A arg);
  R visitLiteralStatement(LiteralStatement node, A arg);
  R visitDartYield(DartYield node, A arg);

  R visitLiteralExpression(LiteralExpression node, A arg);
  R visitVariableDeclarationList(VariableDeclarationList node, A arg);
  R visitAssignment(Assignment node, A arg);
  R visitVariableInitialization(VariableInitialization node, A arg);
  R visitConditional(Conditional cond, A arg);
  R visitNew(New node, A arg);
  R visitCall(Call node, A arg);
  R visitBinary(Binary node, A arg);
  R visitPrefix(Prefix node, A arg);
  R visitPostfix(Postfix node, A arg);

  R visitVariableUse(VariableUse node, A arg);
  R visitThis(This node, A arg);
  R visitVariableDeclaration(VariableDeclaration node, A arg);
  R visitParameter(Parameter node, A arg);
  R visitAccess(PropertyAccess node, A arg);

  R visitNamedFunction(NamedFunction node, A arg);
  R visitFun(Fun node, A arg);

  R visitDeferredExpression(DeferredExpression node, A arg);
  R visitDeferredNumber(DeferredNumber node, A arg);
  R visitDeferredString(DeferredString node, A arg);

  R visitLiteralBool(LiteralBool node, A arg);
  R visitLiteralString(LiteralString node, A arg);
  R visitLiteralNumber(LiteralNumber node, A arg);
  R visitLiteralNull(LiteralNull node, A arg);

  R visitStringConcatenation(StringConcatenation node, A arg);

  R visitName(Name node, A arg);

  R visitArrayInitializer(ArrayInitializer node, A arg);
  R visitArrayHole(ArrayHole node, A arg);
  R visitObjectInitializer(ObjectInitializer node, A arg);
  R visitProperty(Property node, A arg);
  R visitRegExpLiteral(RegExpLiteral node, A arg);

  R visitAwait(Await node, A arg);

  R visitComment(Comment node, A arg);

  R visitInterpolatedExpression(InterpolatedExpression node, A arg);
  R visitInterpolatedLiteral(InterpolatedLiteral node, A arg);
  R visitInterpolatedParameter(InterpolatedParameter node, A arg);
  R visitInterpolatedSelector(InterpolatedSelector node, A arg);
  R visitInterpolatedStatement(InterpolatedStatement node, A arg);
  R visitInterpolatedDeclaration(InterpolatedDeclaration node, A arg);
}

class BaseVisitor1<R, A> implements NodeVisitor1<R, A> {
  const BaseVisitor1();

  R visitNode(Node node, A arg) {
    node.visitChildren1(this, arg);
    return null;
  }

  R visitProgram(Program node, A arg) => visitNode(node, arg);

  R visitStatement(Statement node, A arg) => visitNode(node, arg);
  R visitLoop(Loop node, A arg) => visitStatement(node, arg);
  R visitJump(Statement node, A arg) => visitStatement(node, arg);

  R visitBlock(Block node, A arg) => visitStatement(node, arg);
  R visitExpressionStatement(ExpressionStatement node, A arg) =>
      visitStatement(node, arg);
  R visitEmptyStatement(EmptyStatement node, A arg) =>
      visitStatement(node, arg);
  R visitIf(If node, A arg) => visitStatement(node, arg);
  R visitFor(For node, A arg) => visitLoop(node, arg);
  R visitForIn(ForIn node, A arg) => visitLoop(node, arg);
  R visitWhile(While node, A arg) => visitLoop(node, arg);
  R visitDo(Do node, A arg) => visitLoop(node, arg);
  R visitContinue(Continue node, A arg) => visitJump(node, arg);
  R visitBreak(Break node, A arg) => visitJump(node, arg);
  R visitReturn(Return node, A arg) => visitJump(node, arg);
  R visitThrow(Throw node, A arg) => visitJump(node, arg);
  R visitTry(Try node, A arg) => visitStatement(node, arg);
  R visitSwitch(Switch node, A arg) => visitStatement(node, arg);
  R visitFunctionDeclaration(FunctionDeclaration node, A arg) =>
      visitStatement(node, arg);
  R visitLabeledStatement(LabeledStatement node, A arg) =>
      visitStatement(node, arg);
  R visitLiteralStatement(LiteralStatement node, A arg) =>
      visitStatement(node, arg);

  R visitCatch(Catch node, A arg) => visitNode(node, arg);
  R visitCase(Case node, A arg) => visitNode(node, arg);
  R visitDefault(Default node, A arg) => visitNode(node, arg);

  R visitExpression(Expression node, A arg) => visitNode(node, arg);
  R visitVariableReference(VariableReference node, A arg) =>
      visitExpression(node, arg);

  R visitLiteralExpression(LiteralExpression node, A arg) =>
      visitExpression(node, arg);
  R visitVariableDeclarationList(VariableDeclarationList node, A arg) =>
      visitExpression(node, arg);
  R visitAssignment(Assignment node, A arg) => visitExpression(node, arg);
  R visitVariableInitialization(VariableInitialization node, A arg) {
    if (node.value != null) {
      return visitAssignment(node, arg);
    } else {
      return visitExpression(node, arg);
    }
  }

  R visitConditional(Conditional node, A arg) => visitExpression(node, arg);
  R visitNew(New node, A arg) => visitExpression(node, arg);
  R visitCall(Call node, A arg) => visitExpression(node, arg);
  R visitBinary(Binary node, A arg) => visitExpression(node, arg);
  R visitPrefix(Prefix node, A arg) => visitExpression(node, arg);
  R visitPostfix(Postfix node, A arg) => visitExpression(node, arg);
  R visitAccess(PropertyAccess node, A arg) => visitExpression(node, arg);

  R visitVariableUse(VariableUse node, A arg) =>
      visitVariableReference(node, arg);
  R visitVariableDeclaration(VariableDeclaration node, A arg) =>
      visitVariableReference(node, arg);
  R visitParameter(Parameter node, A arg) =>
      visitVariableDeclaration(node, arg);
  R visitThis(This node, A arg) => visitParameter(node, arg);

  R visitNamedFunction(NamedFunction node, A arg) => visitExpression(node, arg);
  R visitFun(Fun node, A arg) => visitExpression(node, arg);

  R visitToken(DeferredToken node, A arg) => visitExpression(node, arg);

  R visitDeferredExpression(DeferredExpression node, A arg) =>
      visitExpression(node, arg);
  R visitDeferredNumber(DeferredNumber node, A arg) => visitToken(node, arg);
  R visitDeferredString(DeferredString node, A arg) => visitToken(node, arg);

  R visitLiteral(Literal node, A arg) => visitExpression(node, arg);

  R visitLiteralBool(LiteralBool node, A arg) => visitLiteral(node, arg);
  R visitLiteralString(LiteralString node, A arg) => visitLiteral(node, arg);
  R visitLiteralNumber(LiteralNumber node, A arg) => visitLiteral(node, arg);
  R visitLiteralNull(LiteralNull node, A arg) => visitLiteral(node, arg);

  R visitStringConcatenation(StringConcatenation node, A arg) =>
      visitLiteral(node, arg);

  R visitName(Name node, A arg) => visitNode(node, arg);

  R visitArrayInitializer(ArrayInitializer node, A arg) =>
      visitExpression(node, arg);
  R visitArrayHole(ArrayHole node, A arg) => visitExpression(node, arg);
  R visitObjectInitializer(ObjectInitializer node, A arg) =>
      visitExpression(node, arg);
  R visitProperty(Property node, A arg) => visitNode(node, arg);
  R visitRegExpLiteral(RegExpLiteral node, A arg) => visitExpression(node, arg);

  R visitInterpolatedNode(InterpolatedNode node, A arg) => visitNode(node, arg);

  R visitInterpolatedExpression(InterpolatedExpression node, A arg) =>
      visitInterpolatedNode(node, arg);
  R visitInterpolatedLiteral(InterpolatedLiteral node, A arg) =>
      visitInterpolatedNode(node, arg);
  R visitInterpolatedParameter(InterpolatedParameter node, A arg) =>
      visitInterpolatedNode(node, arg);
  R visitInterpolatedSelector(InterpolatedSelector node, A arg) =>
      visitInterpolatedNode(node, arg);
  R visitInterpolatedStatement(InterpolatedStatement node, A arg) =>
      visitInterpolatedNode(node, arg);
  R visitInterpolatedDeclaration(InterpolatedDeclaration node, A arg) {
    return visitInterpolatedNode(node, arg);
  }

  // Ignore comments by default.
  R visitComment(Comment node, A arg) => null;

  R visitAwait(Await node, A arg) => visitExpression(node, arg);
  R visitDartYield(DartYield node, A arg) => visitStatement(node, arg);
}

/// This tag interface has no behaviour but must be implemented by any class
/// that is to be stored on a [Node] as source information.
abstract class JavaScriptNodeSourceInformation {
  const JavaScriptNodeSourceInformation();
}

abstract class Node {
  JavaScriptNodeSourceInformation get sourceInformation => _sourceInformation;

  JavaScriptNodeSourceInformation _sourceInformation;

  T accept<T>(NodeVisitor<T> visitor);
  void visitChildren<T>(NodeVisitor<T> visitor);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg);
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg);

  // Shallow clone of node.  Does not clone positions since the only use of this
  // private method is create a copy with a new position.
  Node _clone();

  // Returns a node equivalent to [this], but with new source position and end
  // source position.
  Node withSourceInformation(
      JavaScriptNodeSourceInformation sourceInformation) {
    if (sourceInformation == _sourceInformation) {
      return this;
    }
    Node clone = _clone();
    // TODO(sra): Should existing data be 'sticky' if we try to overwrite with
    // `null`?
    clone._sourceInformation = sourceInformation;
    return clone;
  }

  VariableUse asVariableUse() => null;

  bool get isCommaOperator => false;

  Statement toStatement() {
    throw new UnsupportedError('toStatement');
  }

  String debugPrint() => DebugPrint(this);
}

class Program extends Node {
  final List<Statement> body;
  Program(this.body);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitProgram(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitProgram(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    for (Statement statement in body) statement.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    for (Statement statement in body) statement.accept1(visitor, arg);
  }

  Program _clone() => new Program(body);
}

abstract class Statement extends Node {
  Statement toStatement() => this;
}

class Block extends Statement {
  final List<Statement> statements;

  Block(this.statements);

  Block.empty() : this.statements = <Statement>[];

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitBlock(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitBlock(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    for (Statement statement in statements) statement.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    for (Statement statement in statements) statement.accept1(visitor, arg);
  }

  Block _clone() => new Block(statements);
}

class ExpressionStatement extends Statement {
  final Expression expression;

  ExpressionStatement(this.expression) {
    assert(this.expression != null);
  }

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitExpressionStatement(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitExpressionStatement(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    expression.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    expression.accept1(visitor, arg);
  }

  ExpressionStatement _clone() => new ExpressionStatement(expression);
}

class EmptyStatement extends Statement {
  EmptyStatement();

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitEmptyStatement(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitEmptyStatement(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {}

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  EmptyStatement _clone() => new EmptyStatement();
}

class If extends Statement {
  final Expression condition;
  final Statement then;
  final Statement otherwise;

  If(this.condition, this.then, this.otherwise);

  If.noElse(this.condition, this.then) : this.otherwise = new EmptyStatement();

  bool get hasElse => otherwise is! EmptyStatement;

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitIf(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitIf(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    condition.accept(visitor);
    then.accept(visitor);
    otherwise.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    condition.accept1(visitor, arg);
    then.accept1(visitor, arg);
    otherwise.accept1(visitor, arg);
  }

  If _clone() => new If(condition, then, otherwise);
}

abstract class Loop extends Statement {
  final Statement body;

  Loop(this.body);
}

class For extends Loop {
  final Expression init;
  final Expression condition;
  final Expression update;

  For(this.init, this.condition, this.update, Statement body) : super(body);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitFor(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitFor(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    if (init != null) init.accept(visitor);
    if (condition != null) condition.accept(visitor);
    if (update != null) update.accept(visitor);
    body.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    if (init != null) init.accept1(visitor, arg);
    if (condition != null) condition.accept1(visitor, arg);
    if (update != null) update.accept1(visitor, arg);
    body.accept1(visitor, arg);
  }

  For _clone() => new For(init, condition, update, body);
}

class ForIn extends Loop {
  // Note that [VariableDeclarationList] is a subclass of [Expression].
  // Therefore we can type the leftHandSide as [Expression].
  final Expression leftHandSide;
  final Expression object;

  ForIn(this.leftHandSide, this.object, Statement body) : super(body);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitForIn(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitForIn(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    leftHandSide.accept(visitor);
    object.accept(visitor);
    body.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    leftHandSide.accept1(visitor, arg);
    object.accept1(visitor, arg);
    body.accept1(visitor, arg);
  }

  ForIn _clone() => new ForIn(leftHandSide, object, body);
}

class While extends Loop {
  final Node condition;

  While(this.condition, Statement body) : super(body);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitWhile(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitWhile(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    condition.accept(visitor);
    body.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    condition.accept1(visitor, arg);
    body.accept1(visitor, arg);
  }

  While _clone() => new While(condition, body);
}

class Do extends Loop {
  final Expression condition;

  Do(Statement body, this.condition) : super(body);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitDo(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitDo(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    body.accept(visitor);
    condition.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    body.accept1(visitor, arg);
    condition.accept1(visitor, arg);
  }

  Do _clone() => new Do(body, condition);
}

class Continue extends Statement {
  final String targetLabel; // Can be null.

  Continue(this.targetLabel);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitContinue(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitContinue(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {}

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  Continue _clone() => new Continue(targetLabel);
}

class Break extends Statement {
  final String targetLabel; // Can be null.

  Break(this.targetLabel);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitBreak(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitBreak(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {}

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  Break _clone() => new Break(targetLabel);
}

class Return extends Statement {
  final Expression value; // Can be null.

  Return([this.value = null]);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitReturn(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitReturn(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    if (value != null) value.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    if (value != null) value.accept1(visitor, arg);
  }

  Return _clone() => new Return(value);
}

class Throw extends Statement {
  final Expression expression;

  Throw(this.expression);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitThrow(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitThrow(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    expression.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    expression.accept1(visitor, arg);
  }

  Throw _clone() => new Throw(expression);
}

class Try extends Statement {
  final Block body;
  final Catch catchPart; // Can be null if [finallyPart] is non-null.
  final Block finallyPart; // Can be null if [catchPart] is non-null.

  Try(this.body, this.catchPart, this.finallyPart) {
    assert(catchPart != null || finallyPart != null);
  }

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitTry(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitTry(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    body.accept(visitor);
    if (catchPart != null) catchPart.accept(visitor);
    if (finallyPart != null) finallyPart.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    body.accept1(visitor, arg);
    if (catchPart != null) catchPart.accept1(visitor, arg);
    if (finallyPart != null) finallyPart.accept1(visitor, arg);
  }

  Try _clone() => new Try(body, catchPart, finallyPart);
}

class Catch extends Node {
  final Declaration declaration;
  final Block body;

  Catch(this.declaration, this.body);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitCatch(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitCatch(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    declaration.accept(visitor);
    body.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    declaration.accept1(visitor, arg);
    body.accept1(visitor, arg);
  }

  Catch _clone() => new Catch(declaration, body);
}

class Switch extends Statement {
  final Expression key;
  final List<SwitchClause> cases;

  Switch(this.key, this.cases);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitSwitch(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitSwitch(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    key.accept(visitor);
    for (SwitchClause clause in cases) clause.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    key.accept1(visitor, arg);
    for (SwitchClause clause in cases) clause.accept1(visitor, arg);
  }

  Switch _clone() => new Switch(key, cases);
}

abstract class SwitchClause extends Node {
  final Block body;

  SwitchClause(this.body);
}

class Case extends SwitchClause {
  final Expression expression;

  Case(this.expression, Block body) : super(body);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitCase(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitCase(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    expression.accept(visitor);
    body.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    expression.accept1(visitor, arg);
    body.accept1(visitor, arg);
  }

  Case _clone() => new Case(expression, body);
}

class Default extends SwitchClause {
  Default(Block body) : super(body);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitDefault(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitDefault(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    body.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    body.accept1(visitor, arg);
  }

  Default _clone() => new Default(body);
}

class FunctionDeclaration extends Statement {
  final Declaration name;
  final Fun function;

  FunctionDeclaration(this.name, this.function);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitFunctionDeclaration(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitFunctionDeclaration(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    name.accept(visitor);
    function.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    name.accept1(visitor, arg);
    function.accept1(visitor, arg);
  }

  FunctionDeclaration _clone() => new FunctionDeclaration(name, function);
}

class LabeledStatement extends Statement {
  final String label;
  final Statement body;

  LabeledStatement(this.label, this.body);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLabeledStatement(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitLabeledStatement(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    body.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    body.accept1(visitor, arg);
  }

  LabeledStatement _clone() => new LabeledStatement(label, body);
}

class LiteralStatement extends Statement {
  final String code;

  LiteralStatement(this.code);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralStatement(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitLiteralStatement(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {}

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  LiteralStatement _clone() => new LiteralStatement(code);
}

// Not a real JavaScript node, but represents the yield statement from a dart
// program translated to JavaScript.
class DartYield extends Statement {
  final Expression expression;

  final bool hasStar;

  DartYield(this.expression, this.hasStar);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitDartYield(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitDartYield(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    expression.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    expression.accept1(visitor, arg);
  }

  DartYield _clone() => new DartYield(expression, hasStar);
}

abstract class Expression extends Node {
  int get precedenceLevel;

  Statement toStatement() => new ExpressionStatement(this);
}

abstract class Declaration implements VariableReference {}

/// An implementation of [Name] represents a potentially late bound name in
/// the generated ast.
///
/// While [Name] implements comparable, there is no requirement on the actual
/// implementation of [compareTo] other than that it needs to be stable.
/// In particular, there is no guarantee that implementations of [compareTo]
/// will implement some form of lexicographic ordering like [String.compareTo].
abstract class Name extends Literal
    implements Declaration, Parameter, Comparable {
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitName(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitName(this, arg);

  /// Returns a unique [key] for this name.
  ///
  /// The key is unrelated to the actual name and is not intended for human
  /// consumption. As such, it might be long or cryptic.
  String get key;

  bool get allowRename => false;
}

class LiteralStringFromName extends LiteralString {
  Name name;

  LiteralStringFromName(this.name) : super(null);

  String get value => '"${name.name}"';

  void visitChildren<T>(NodeVisitor<T> visitor) {
    name.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    name.accept1(visitor, arg);
  }
}

class LiteralExpression extends Expression {
  final String template;
  final List<Expression> inputs;

  LiteralExpression(this.template) : inputs = const [];

  LiteralExpression.withData(this.template, this.inputs);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralExpression(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitLiteralExpression(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    if (inputs != null) {
      for (Expression expr in inputs) expr.accept(visitor);
    }
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    if (inputs != null) {
      for (Expression expr in inputs) expr.accept1(visitor, arg);
    }
  }

  LiteralExpression _clone() =>
      new LiteralExpression.withData(template, inputs);

  // Code that uses JS must take care of operator precedences, and
  // put parenthesis if needed.
  int get precedenceLevel => PRIMARY;
}

/**
 * [VariableDeclarationList] is a subclass of [Expression] to simplify the
 * AST.
 */
class VariableDeclarationList extends Expression {
  final List<VariableInitialization> declarations;

  VariableDeclarationList(this.declarations);

  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitVariableDeclarationList(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitVariableDeclarationList(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    for (VariableInitialization declaration in declarations) {
      declaration.accept(visitor);
    }
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    for (VariableInitialization declaration in declarations) {
      declaration.accept1(visitor, arg);
    }
  }

  VariableDeclarationList _clone() => new VariableDeclarationList(declarations);

  int get precedenceLevel => EXPRESSION;
}

class Assignment extends Expression {
  final Expression leftHandSide;
  final String op; // Null, if the assignment is not compound.
  final Expression value; // May be null, for [VariableInitialization]s.

  Assignment(leftHandSide, value) : this.compound(leftHandSide, null, value);

  // If `this.op == null` this will be a non-compound assignment.
  Assignment.compound(this.leftHandSide, this.op, this.value);

  int get precedenceLevel => ASSIGNMENT;

  bool get isCompound => op != null;

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitAssignment(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitAssignment(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    leftHandSide.accept(visitor);
    if (value != null) value.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    leftHandSide.accept1(visitor, arg);
    if (value != null) value.accept1(visitor, arg);
  }

  Assignment _clone() => new Assignment.compound(leftHandSide, op, value);
}

class VariableInitialization extends Assignment {
  /** [value] may be null. */
  VariableInitialization(Declaration declaration, Expression value)
      : super(declaration, value);

  Declaration get declaration => leftHandSide;

  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitVariableInitialization(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitVariableInitialization(this, arg);

  VariableInitialization _clone() =>
      new VariableInitialization(declaration, value);
}

class Conditional extends Expression {
  final Expression condition;
  final Expression then;
  final Expression otherwise;

  Conditional(this.condition, this.then, this.otherwise);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitConditional(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitConditional(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    condition.accept(visitor);
    then.accept(visitor);
    otherwise.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    condition.accept1(visitor, arg);
    then.accept1(visitor, arg);
    otherwise.accept1(visitor, arg);
  }

  Conditional _clone() => new Conditional(condition, then, otherwise);

  int get precedenceLevel => ASSIGNMENT;
}

class Call extends Expression {
  Expression target;
  List<Expression> arguments;

  Call(this.target, this.arguments,
      {JavaScriptNodeSourceInformation sourceInformation}) {
    this._sourceInformation = sourceInformation;
  }

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitCall(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitCall(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    target.accept(visitor);
    for (Expression arg in arguments) {
      arg.accept(visitor);
    }
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    target.accept1(visitor, arg);
    for (Expression arg in arguments) {
      arg.accept1(visitor, arg);
    }
  }

  Call _clone() => new Call(target, arguments);

  int get precedenceLevel => CALL;
}

class New extends Call {
  New(Expression cls, List<Expression> arguments) : super(cls, arguments);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitNew(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitNew(this, arg);

  New _clone() => new New(target, arguments);
}

class Binary extends Expression {
  final String op;
  final Expression left;
  final Expression right;

  Binary(this.op, this.left, this.right);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitBinary(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitBinary(this, arg);

  Binary _clone() => new Binary(op, left, right);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    left.accept(visitor);
    right.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    left.accept1(visitor, arg);
    right.accept1(visitor, arg);
  }

  bool get isCommaOperator => op == ',';

  int get precedenceLevel {
    // TODO(floitsch): switch to constant map.
    switch (op) {
      case "*":
      case "/":
      case "%":
        return MULTIPLICATIVE;
      case "+":
      case "-":
        return ADDITIVE;
      case "<<":
      case ">>":
      case ">>>":
        return SHIFT;
      case "<":
      case ">":
      case "<=":
      case ">=":
      case "instanceof":
      case "in":
        return RELATIONAL;
      case "==":
      case "===":
      case "!=":
      case "!==":
        return EQUALITY;
      case "&":
        return BIT_AND;
      case "^":
        return BIT_XOR;
      case "|":
        return BIT_OR;
      case "&&":
        return LOGICAL_AND;
      case "||":
        return LOGICAL_OR;
      case ',':
        return EXPRESSION;
      default:
        throw "Internal Error: Unhandled binary operator: $op";
    }
  }
}

class Prefix extends Expression {
  final String op;
  final Expression argument;

  Prefix(this.op, this.argument);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitPrefix(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitPrefix(this, arg);

  Prefix _clone() => new Prefix(op, argument);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    argument.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    argument.accept1(visitor, arg);
  }

  int get precedenceLevel => UNARY;
}

class Postfix extends Expression {
  final String op;
  final Expression argument;

  Postfix(this.op, this.argument);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitPostfix(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitPostfix(this, arg);

  Postfix _clone() => new Postfix(op, argument);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    argument.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    argument.accept1(visitor, arg);
  }

  int get precedenceLevel => UNARY;
}

abstract class VariableReference extends Expression {
  final String name;

  VariableReference(this.name) {
    assert(_identifierRE.hasMatch(name), "Non-identifier name '$name'");
  }

  static RegExp _identifierRE = new RegExp(r'^[A-Za-z_$][A-Za-z_$0-9]*$');

  accept(NodeVisitor visitor);

  int get precedenceLevel => PRIMARY;

  void visitChildren<T>(NodeVisitor<T> visitor) {}

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}
}

class VariableUse extends VariableReference {
  VariableUse(String name) : super(name);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitVariableUse(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitVariableUse(this, arg);

  VariableUse _clone() => new VariableUse(name);

  VariableUse asVariableUse() => this;

  String toString() => 'VariableUse($name)';
}

class VariableDeclaration extends VariableReference implements Declaration {
  final bool allowRename;

  VariableDeclaration(String name, {this.allowRename: true}) : super(name);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitVariableDeclaration(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitVariableDeclaration(this, arg);

  VariableDeclaration _clone() => new VariableDeclaration(name);
}

class Parameter extends VariableDeclaration {
  Parameter(String name) : super(name);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitParameter(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitParameter(this, arg);

  Parameter _clone() => new Parameter(name);
}

class This extends Parameter {
  This() : super("this");

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitThis(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitThis(this, arg);

  This _clone() => new This();
}

class NamedFunction extends Expression {
  final Declaration name;
  final Fun function;

  NamedFunction(this.name, this.function);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitNamedFunction(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitNamedFunction(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    name.accept(visitor);
    function.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    name.accept1(visitor, arg);
    function.accept1(visitor, arg);
  }

  NamedFunction _clone() => new NamedFunction(name, function);

  int get precedenceLevel => LEFT_HAND_SIDE;
}

class Fun extends Expression {
  final List<Parameter> params;
  final Block body;
  final AsyncModifier asyncModifier;

  Fun(this.params, this.body, {this.asyncModifier: const AsyncModifier.sync()});

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitFun(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitFun(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    for (Parameter param in params) param.accept(visitor);
    body.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    for (Parameter param in params) param.accept1(visitor, arg);
    body.accept1(visitor, arg);
  }

  Fun _clone() => new Fun(params, body, asyncModifier: asyncModifier);

  int get precedenceLevel => LEFT_HAND_SIDE;
}

class AsyncModifier {
  final bool isAsync;
  final bool isYielding;
  final String description;

  const AsyncModifier.sync()
      : isAsync = false,
        isYielding = false,
        description = "sync";
  const AsyncModifier.async()
      : isAsync = true,
        isYielding = false,
        description = "async";
  const AsyncModifier.asyncStar()
      : isAsync = true,
        isYielding = true,
        description = "async*";
  const AsyncModifier.syncStar()
      : isAsync = false,
        isYielding = true,
        description = "sync*";
  toString() => description;
}

class PropertyAccess extends Expression {
  final Expression receiver;
  final Expression selector;

  PropertyAccess(this.receiver, this.selector);

  PropertyAccess.field(this.receiver, String fieldName)
      : selector = new LiteralString('"$fieldName"');

  PropertyAccess.indexed(this.receiver, int index)
      : selector = new LiteralNumber('$index');

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitAccess(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitAccess(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    receiver.accept(visitor);
    selector.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    receiver.accept1(visitor, arg);
    selector.accept1(visitor, arg);
  }

  PropertyAccess _clone() => new PropertyAccess(receiver, selector);

  int get precedenceLevel => LEFT_HAND_SIDE;
}

/// A [DeferredToken] is a placeholder for some [Expression] that is not known
/// at construction time of an ast. Unlike [InterpolatedExpression],
/// [DeferredToken] is not limited to templates but may also occur in
/// fully instantiated asts.
abstract class DeferredToken extends Expression {
  void visitChildren<T>(NodeVisitor<T> visitor) {}

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  DeferredToken _clone() => this;
}

/// Interface for a deferred integer value. An implementation has to provide
/// a value via the [value] getter the latest when the ast is printed.
abstract class DeferredNumber extends DeferredToken implements Literal {
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitDeferredNumber(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitDeferredNumber(this, arg);

  int get value;

  int get precedenceLevel => value.isNegative ? UNARY : PRIMARY;
}

/// Interface for a deferred string value. An implementation has to provide
/// a value via the [value] getter the latest when the ast is printed.
abstract class DeferredString extends DeferredToken implements Literal {
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitDeferredString(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitDeferredString(this, arg);

  String get value;

  int get precedenceLevel => PRIMARY;
}

/// Interface for a deferred [Expression] value. An implementation has to provide
/// a value via the [value] getter the latest when the ast is printed.
/// Also, [precedenceLevel] has to return the same value that
/// [value.precedenceLevel] returns once [value] is bound to an [Expression].
abstract class DeferredExpression extends DeferredToken {
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitDeferredExpression(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitDeferredExpression(this, arg);

  Expression get value;
}

abstract class Literal extends Expression {
  void visitChildren<T>(NodeVisitor<T> visitor) {}

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  int get precedenceLevel => PRIMARY;
}

class LiteralBool extends Literal {
  final bool value;

  LiteralBool(this.value);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralBool(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitLiteralBool(this, arg);

  // [visitChildren] inherited from [Literal].

  LiteralBool _clone() => new LiteralBool(value);
}

class LiteralNull extends Literal {
  LiteralNull();

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralNull(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitLiteralNull(this, arg);

  LiteralNull _clone() => new LiteralNull();
}

class LiteralString extends Literal {
  final String value;

  /**
   * Constructs a LiteralString from a string value.
   *
   * The constructor does not add the required quotes.  If [value] is not
   * surrounded by quotes and properly escaped, the resulting object is invalid
   * as a JS value.
   *
   * TODO(sra): Introduce variants for known valid strings that don't allocate a
   * new string just to add quotes.
   */
  LiteralString(this.value);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralString(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitLiteralString(this, arg);

  LiteralString _clone() => new LiteralString(value);
}

class StringConcatenation extends Literal {
  final List<Literal> parts;

  /**
   * Constructs a StringConcatenation from a list of Literal elements.
   * The constructor does not add surrounding quotes to the resulting
   * concatenated string.
   */
  StringConcatenation(this.parts);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitStringConcatenation(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitStringConcatenation(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    for (Literal part in parts) part.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    for (Literal part in parts) part.accept1(visitor, arg);
  }

  StringConcatenation _clone() => new StringConcatenation(this.parts);
}

class LiteralNumber extends Literal {
  final String value; // Must be a valid JavaScript number literal.

  LiteralNumber(this.value);

  int get precedenceLevel => value.startsWith('-') ? UNARY : PRIMARY;

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralNumber(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitLiteralNumber(this, arg);

  LiteralNumber _clone() => new LiteralNumber(value);
}

class ArrayInitializer extends Expression {
  final List<Expression> elements;

  ArrayInitializer(this.elements);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitArrayInitializer(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitArrayInitializer(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    for (Expression element in elements) element.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    for (Expression element in elements) element.accept1(visitor, arg);
  }

  ArrayInitializer _clone() => new ArrayInitializer(elements);

  int get precedenceLevel => PRIMARY;
}

/**
 * An empty place in an [ArrayInitializer].
 * For example the list [1, , , 2] would contain two holes.
 */
class ArrayHole extends Expression {
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitArrayHole(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitArrayHole(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {}

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  ArrayHole _clone() => new ArrayHole();

  int get precedenceLevel => PRIMARY;
}

class ObjectInitializer extends Expression {
  final List<Property> properties;
  final bool isOneLiner;

  /**
   * Constructs a new object-initializer containing the given [properties].
   *
   * [isOneLiner] describes the behaviour when pretty-printing (non-minified).
   * If true print all properties on the same line.
   * If false print each property on a seperate line.
   */
  ObjectInitializer(this.properties, {this.isOneLiner: true});

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitObjectInitializer(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitObjectInitializer(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    for (Property init in properties) init.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    for (Property init in properties) init.accept1(visitor, arg);
  }

  ObjectInitializer _clone() =>
      new ObjectInitializer(properties, isOneLiner: isOneLiner);

  int get precedenceLevel => PRIMARY;
}

class Property extends Node {
  final Literal name;
  final Expression value;

  Property(this.name, this.value);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitProperty(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitProperty(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {
    name.accept(visitor);
    value.accept(visitor);
  }

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    name.accept1(visitor, arg);
    value.accept1(visitor, arg);
  }

  Property _clone() => new Property(name, value);
}

/// Tag class for all interpolated positions.
abstract class InterpolatedNode implements Node {
  get nameOrPosition;

  bool get isNamed => nameOrPosition is String;

  bool get isPositional => nameOrPosition is int;
}

class InterpolatedExpression extends Expression with InterpolatedNode {
  final nameOrPosition;

  InterpolatedExpression(this.nameOrPosition);

  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitInterpolatedExpression(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitInterpolatedExpression(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {}

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  InterpolatedExpression _clone() => new InterpolatedExpression(nameOrPosition);

  int get precedenceLevel => PRIMARY;
}

class InterpolatedLiteral extends Literal with InterpolatedNode {
  final nameOrPosition;

  InterpolatedLiteral(this.nameOrPosition);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitInterpolatedLiteral(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitInterpolatedLiteral(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {}

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  InterpolatedLiteral _clone() => new InterpolatedLiteral(nameOrPosition);
}

class InterpolatedParameter extends Expression
    with InterpolatedNode
    implements Parameter {
  final nameOrPosition;

  InterpolatedParameter(this.nameOrPosition);

  String get name {
    throw "InterpolatedParameter.name must not be invoked";
  }

  bool get allowRename => false;

  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitInterpolatedParameter(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitInterpolatedParameter(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {}

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  InterpolatedParameter _clone() => new InterpolatedParameter(nameOrPosition);

  int get precedenceLevel => PRIMARY;
}

class InterpolatedSelector extends Expression with InterpolatedNode {
  final nameOrPosition;

  InterpolatedSelector(this.nameOrPosition);

  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitInterpolatedSelector(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitInterpolatedSelector(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {}

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  InterpolatedSelector _clone() => new InterpolatedSelector(nameOrPosition);

  int get precedenceLevel => PRIMARY;
}

class InterpolatedStatement extends Statement with InterpolatedNode {
  final nameOrPosition;

  InterpolatedStatement(this.nameOrPosition);

  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitInterpolatedStatement(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitInterpolatedStatement(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {}

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  InterpolatedStatement _clone() => new InterpolatedStatement(nameOrPosition);
}

class InterpolatedDeclaration extends Expression
    with InterpolatedNode
    implements Declaration {
  final nameOrPosition;

  InterpolatedDeclaration(this.nameOrPosition);

  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitInterpolatedDeclaration(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitInterpolatedDeclaration(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {}

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  InterpolatedDeclaration _clone() {
    return new InterpolatedDeclaration(nameOrPosition);
  }

  @override
  String get name => throw "No name for the interpolated node";

  @override
  int get precedenceLevel => PRIMARY;
}

/**
 * [RegExpLiteral]s, despite being called "Literal", do not inherit from
 * [Literal]. Indeed, regular expressions in JavaScript have a side-effect and
 * are thus not in the same category as numbers or strings.
 */
class RegExpLiteral extends Expression {
  /** Contains the pattern and the flags.*/
  final String pattern;

  RegExpLiteral(this.pattern);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitRegExpLiteral(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitRegExpLiteral(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) {}

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  RegExpLiteral _clone() => new RegExpLiteral(pattern);

  int get precedenceLevel => PRIMARY;
}

/**
 * An asynchronous await.
 *
 * Not part of JavaScript. We desugar this expression before outputting.
 * Should only occur in a [Fun] with `asyncModifier` async or asyncStar.
 */
class Await extends Expression {
  /** The awaited expression. */
  final Expression expression;

  Await(this.expression);

  int get precedenceLevel => UNARY;

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitAwait(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitAwait(this, arg);

  void visitChildren<T>(NodeVisitor<T> visitor) => expression.accept(visitor);

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      expression.accept1(visitor, arg);

  Await _clone() => new Await(expression);
}

/**
 * A comment.
 *
 * Extends [Statement] so we can add comments before statements in
 * [Block] and [Program].
 */
class Comment extends Statement {
  final String comment;

  Comment(this.comment);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitComment(this);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitComment(this, arg);

  Comment _clone() => new Comment(comment);

  void visitChildren<T>(NodeVisitor<T> visitor) {}

  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}
}
