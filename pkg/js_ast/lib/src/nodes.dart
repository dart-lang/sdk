// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_ast.nodes;

import 'precedence.dart';
import 'printer.dart';

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
  T visitArrowFunction(ArrowFunction node);

  T visitDeferredStatement(DeferredStatement node);
  T visitDeferredExpression(DeferredExpression node);
  T visitDeferredNumber(DeferredNumber node);
  T visitDeferredString(DeferredString node);

  T visitLiteralBool(LiteralBool node);
  T visitLiteralString(LiteralString node);
  T visitLiteralNumber(LiteralNumber node);
  T visitLiteralNull(LiteralNull node);

  T visitStringConcatenation(StringConcatenation node);

  T visitName(Name node);

  T visitParentheses(Parentheses node);

  T visitArrayInitializer(ArrayInitializer node);
  T visitArrayHole(ArrayHole node);
  T visitObjectInitializer(ObjectInitializer node);
  T visitProperty(Property node);
  T visitMethodDefinition(MethodDefinition node);
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

abstract class BaseVisitor<T> implements NodeVisitor<T> {
  const BaseVisitor();

  T visitNode(Node node);
  @override
  T visitComment(Comment node);

  @override
  T visitProgram(Program node) => visitNode(node);

  T visitStatement(Statement node) => visitNode(node);
  T visitLoop(Loop node) => visitStatement(node);
  T visitJump(Statement node) => visitStatement(node);

  @override
  T visitBlock(Block node) => visitStatement(node);
  @override
  T visitExpressionStatement(ExpressionStatement node) => visitStatement(node);
  @override
  T visitEmptyStatement(EmptyStatement node) => visitStatement(node);
  @override
  T visitIf(If node) => visitStatement(node);
  @override
  T visitFor(For node) => visitLoop(node);
  @override
  T visitForIn(ForIn node) => visitLoop(node);
  @override
  T visitWhile(While node) => visitLoop(node);
  @override
  T visitDo(Do node) => visitLoop(node);
  @override
  T visitContinue(Continue node) => visitJump(node);
  @override
  T visitBreak(Break node) => visitJump(node);
  @override
  T visitReturn(Return node) => visitJump(node);
  @override
  T visitThrow(Throw node) => visitJump(node);
  @override
  T visitTry(Try node) => visitStatement(node);
  @override
  T visitSwitch(Switch node) => visitStatement(node);
  @override
  T visitFunctionDeclaration(FunctionDeclaration node) => visitStatement(node);
  @override
  T visitLabeledStatement(LabeledStatement node) => visitStatement(node);
  @override
  T visitLiteralStatement(LiteralStatement node) => visitStatement(node);

  @override
  T visitCatch(Catch node) => visitNode(node);
  @override
  T visitCase(Case node) => visitNode(node);
  @override
  T visitDefault(Default node) => visitNode(node);

  T visitExpression(Expression node) => visitNode(node);
  T visitVariableReference(VariableReference node) => visitExpression(node);

  @override
  T visitLiteralExpression(LiteralExpression node) => visitExpression(node);
  @override
  T visitVariableDeclarationList(VariableDeclarationList node) =>
      visitExpression(node);
  @override
  T visitAssignment(Assignment node) => visitExpression(node);
  @override
  T visitVariableInitialization(VariableInitialization node) =>
      visitExpression(node);

  @override
  T visitConditional(Conditional node) => visitExpression(node);
  @override
  T visitNew(New node) => visitExpression(node);
  @override
  T visitCall(Call node) => visitExpression(node);
  @override
  T visitBinary(Binary node) => visitExpression(node);
  @override
  T visitPrefix(Prefix node) => visitExpression(node);
  @override
  T visitPostfix(Postfix node) => visitExpression(node);
  @override
  T visitAccess(PropertyAccess node) => visitExpression(node);

  @override
  T visitVariableUse(VariableUse node) => visitVariableReference(node);
  @override
  T visitVariableDeclaration(VariableDeclaration node) =>
      visitVariableReference(node);
  @override
  T visitParameter(Parameter node) => visitVariableDeclaration(node);
  @override
  T visitThis(This node) => visitParameter(node);

  @override
  T visitNamedFunction(NamedFunction node) => visitExpression(node);
  T visitFunctionExpression(FunctionExpression node) => visitExpression(node);
  @override
  T visitFun(Fun node) => visitFunctionExpression(node);
  @override
  T visitArrowFunction(ArrowFunction node) => visitFunctionExpression(node);

  T visitToken(DeferredToken node) => visitExpression(node);

  @override
  T visitDeferredStatement(DeferredStatement node) => visitStatement(node);
  @override
  T visitDeferredExpression(DeferredExpression node) => visitExpression(node);
  @override
  T visitDeferredNumber(DeferredNumber node) => visitToken(node);
  @override
  T visitDeferredString(DeferredString node) => visitToken(node);

  T visitLiteral(Literal node) => visitExpression(node);

  @override
  T visitLiteralBool(LiteralBool node) => visitLiteral(node);
  @override
  T visitLiteralString(LiteralString node) => visitLiteral(node);
  @override
  T visitLiteralNumber(LiteralNumber node) => visitLiteral(node);
  @override
  T visitLiteralNull(LiteralNull node) => visitLiteral(node);

  @override
  T visitStringConcatenation(StringConcatenation node) => visitLiteral(node);

  @override
  T visitName(Name node) => visitNode(node);

  @override
  T visitParentheses(Parentheses node) => visitExpression(node);

  @override
  T visitArrayInitializer(ArrayInitializer node) => visitExpression(node);
  @override
  T visitArrayHole(ArrayHole node) => visitExpression(node);
  @override
  T visitObjectInitializer(ObjectInitializer node) => visitExpression(node);
  @override
  T visitProperty(Property node) => visitNode(node);
  @override
  T visitMethodDefinition(MethodDefinition node) => visitNode(node);
  @override
  T visitRegExpLiteral(RegExpLiteral node) => visitExpression(node);

  T visitInterpolatedNode(InterpolatedNode node) => visitNode(node);

  @override
  T visitInterpolatedExpression(InterpolatedExpression node) =>
      visitInterpolatedNode(node);
  @override
  T visitInterpolatedLiteral(InterpolatedLiteral node) =>
      visitInterpolatedNode(node);
  @override
  T visitInterpolatedParameter(InterpolatedParameter node) =>
      visitInterpolatedNode(node);
  @override
  T visitInterpolatedSelector(InterpolatedSelector node) =>
      visitInterpolatedNode(node);
  @override
  T visitInterpolatedStatement(InterpolatedStatement node) =>
      visitInterpolatedNode(node);
  @override
  T visitInterpolatedDeclaration(InterpolatedDeclaration node) {
    return visitInterpolatedNode(node);
  }

  @override
  T visitAwait(Await node) => visitExpression(node);
  @override
  T visitDartYield(DartYield node) => visitStatement(node);
}

class BaseVisitorVoid extends BaseVisitor<void> {
  @override
  void visitNode(Node node) {
    node.visitChildren(this);
  }

  // Ignore comments by default.
  @override
  void visitComment(Comment node) {}
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
  R visitArrowFunction(ArrowFunction node, A arg);

  R visitDeferredStatement(DeferredStatement node, A arg);
  R visitDeferredExpression(DeferredExpression node, A arg);
  R visitDeferredNumber(DeferredNumber node, A arg);
  R visitDeferredString(DeferredString node, A arg);

  R visitLiteralBool(LiteralBool node, A arg);
  R visitLiteralString(LiteralString node, A arg);
  R visitLiteralNumber(LiteralNumber node, A arg);
  R visitLiteralNull(LiteralNull node, A arg);

  R visitStringConcatenation(StringConcatenation node, A arg);

  R visitName(Name node, A arg);

  R visitParentheses(Parentheses node, A arg);

  R visitArrayInitializer(ArrayInitializer node, A arg);
  R visitArrayHole(ArrayHole node, A arg);
  R visitObjectInitializer(ObjectInitializer node, A arg);
  R visitProperty(Property node, A arg);
  R visitMethodDefinition(MethodDefinition node, A arg);
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

abstract class BaseVisitor1<R, A> implements NodeVisitor1<R, A> {
  const BaseVisitor1();

  R visitNode(Node node, A arg);
  @override
  R visitComment(Comment node, A arg);

  @override
  R visitProgram(Program node, A arg) => visitNode(node, arg);

  R visitStatement(Statement node, A arg) => visitNode(node, arg);
  R visitLoop(Loop node, A arg) => visitStatement(node, arg);
  R visitJump(Statement node, A arg) => visitStatement(node, arg);

  @override
  R visitBlock(Block node, A arg) => visitStatement(node, arg);
  @override
  R visitExpressionStatement(ExpressionStatement node, A arg) =>
      visitStatement(node, arg);
  @override
  R visitEmptyStatement(EmptyStatement node, A arg) =>
      visitStatement(node, arg);
  @override
  R visitIf(If node, A arg) => visitStatement(node, arg);
  @override
  R visitFor(For node, A arg) => visitLoop(node, arg);
  @override
  R visitForIn(ForIn node, A arg) => visitLoop(node, arg);
  @override
  R visitWhile(While node, A arg) => visitLoop(node, arg);
  @override
  R visitDo(Do node, A arg) => visitLoop(node, arg);
  @override
  R visitContinue(Continue node, A arg) => visitJump(node, arg);
  @override
  R visitBreak(Break node, A arg) => visitJump(node, arg);
  @override
  R visitReturn(Return node, A arg) => visitJump(node, arg);
  @override
  R visitThrow(Throw node, A arg) => visitJump(node, arg);
  @override
  R visitTry(Try node, A arg) => visitStatement(node, arg);
  @override
  R visitSwitch(Switch node, A arg) => visitStatement(node, arg);
  @override
  R visitFunctionDeclaration(FunctionDeclaration node, A arg) =>
      visitStatement(node, arg);
  @override
  R visitLabeledStatement(LabeledStatement node, A arg) =>
      visitStatement(node, arg);
  @override
  R visitLiteralStatement(LiteralStatement node, A arg) =>
      visitStatement(node, arg);

  @override
  R visitCatch(Catch node, A arg) => visitNode(node, arg);
  @override
  R visitCase(Case node, A arg) => visitNode(node, arg);
  @override
  R visitDefault(Default node, A arg) => visitNode(node, arg);

  R visitExpression(Expression node, A arg) => visitNode(node, arg);
  R visitVariableReference(VariableReference node, A arg) =>
      visitExpression(node, arg);

  @override
  R visitLiteralExpression(LiteralExpression node, A arg) =>
      visitExpression(node, arg);
  @override
  R visitVariableDeclarationList(VariableDeclarationList node, A arg) =>
      visitExpression(node, arg);
  @override
  R visitAssignment(Assignment node, A arg) => visitExpression(node, arg);
  @override
  R visitVariableInitialization(VariableInitialization node, A arg) =>
      visitExpression(node, arg);

  @override
  R visitConditional(Conditional node, A arg) => visitExpression(node, arg);
  @override
  R visitNew(New node, A arg) => visitExpression(node, arg);
  @override
  R visitCall(Call node, A arg) => visitExpression(node, arg);
  @override
  R visitBinary(Binary node, A arg) => visitExpression(node, arg);
  @override
  R visitPrefix(Prefix node, A arg) => visitExpression(node, arg);
  @override
  R visitPostfix(Postfix node, A arg) => visitExpression(node, arg);
  @override
  R visitAccess(PropertyAccess node, A arg) => visitExpression(node, arg);

  @override
  R visitVariableUse(VariableUse node, A arg) =>
      visitVariableReference(node, arg);
  @override
  R visitVariableDeclaration(VariableDeclaration node, A arg) =>
      visitVariableReference(node, arg);
  @override
  R visitParameter(Parameter node, A arg) =>
      visitVariableDeclaration(node, arg);
  @override
  R visitThis(This node, A arg) => visitParameter(node, arg);

  @override
  R visitNamedFunction(NamedFunction node, A arg) => visitExpression(node, arg);
  @override
  R visitFun(Fun node, A arg) => visitExpression(node, arg);
  @override
  R visitArrowFunction(ArrowFunction node, A arg) => visitExpression(node, arg);

  R visitToken(DeferredToken node, A arg) => visitExpression(node, arg);

  @override
  R visitDeferredStatement(DeferredStatement node, A arg) =>
      visitStatement(node, arg);
  @override
  R visitDeferredExpression(DeferredExpression node, A arg) =>
      visitExpression(node, arg);
  @override
  R visitDeferredNumber(DeferredNumber node, A arg) => visitToken(node, arg);
  @override
  R visitDeferredString(DeferredString node, A arg) => visitToken(node, arg);

  R visitLiteral(Literal node, A arg) => visitExpression(node, arg);

  @override
  R visitLiteralBool(LiteralBool node, A arg) => visitLiteral(node, arg);
  @override
  R visitLiteralString(LiteralString node, A arg) => visitLiteral(node, arg);
  @override
  R visitLiteralNumber(LiteralNumber node, A arg) => visitLiteral(node, arg);
  @override
  R visitLiteralNull(LiteralNull node, A arg) => visitLiteral(node, arg);

  @override
  R visitStringConcatenation(StringConcatenation node, A arg) =>
      visitLiteral(node, arg);

  @override
  R visitName(Name node, A arg) => visitNode(node, arg);

  @override
  R visitParentheses(Parentheses node, A arg) => visitExpression(node, arg);

  @override
  R visitArrayInitializer(ArrayInitializer node, A arg) =>
      visitExpression(node, arg);
  @override
  R visitArrayHole(ArrayHole node, A arg) => visitExpression(node, arg);
  @override
  R visitObjectInitializer(ObjectInitializer node, A arg) =>
      visitExpression(node, arg);
  @override
  R visitProperty(Property node, A arg) => visitNode(node, arg);
  @override
  R visitMethodDefinition(MethodDefinition node, A arg) => visitNode(node, arg);
  @override
  R visitRegExpLiteral(RegExpLiteral node, A arg) => visitExpression(node, arg);

  R visitInterpolatedNode(InterpolatedNode node, A arg) => visitNode(node, arg);

  @override
  R visitInterpolatedExpression(InterpolatedExpression node, A arg) =>
      visitInterpolatedNode(node, arg);
  @override
  R visitInterpolatedLiteral(InterpolatedLiteral node, A arg) =>
      visitInterpolatedNode(node, arg);
  @override
  R visitInterpolatedParameter(InterpolatedParameter node, A arg) =>
      visitInterpolatedNode(node, arg);
  @override
  R visitInterpolatedSelector(InterpolatedSelector node, A arg) =>
      visitInterpolatedNode(node, arg);
  @override
  R visitInterpolatedStatement(InterpolatedStatement node, A arg) =>
      visitInterpolatedNode(node, arg);
  @override
  R visitInterpolatedDeclaration(InterpolatedDeclaration node, A arg) {
    return visitInterpolatedNode(node, arg);
  }

  @override
  R visitAwait(Await node, A arg) => visitExpression(node, arg);
  @override
  R visitDartYield(DartYield node, A arg) => visitStatement(node, arg);
}

class BaseVisitor1Void<A> extends BaseVisitor1<void, A> {
  @override
  void visitNode(Node node, A arg) {
    node.visitChildren1(this, arg);
  }

  // Ignore comments by default.
  @override
  void visitComment(Comment node, A arg) {}
}

/// This tag interface has no behavior but must be implemented by any class
/// that is to be stored on a [Node] as source information.
abstract class JavaScriptNodeSourceInformation {
  const JavaScriptNodeSourceInformation();
}

abstract class Node {
  JavaScriptNodeSourceInformation? get sourceInformation => _sourceInformation;

  JavaScriptNodeSourceInformation? _sourceInformation;

  T accept<T>(NodeVisitor<T> visitor);
  void visitChildren<T>(NodeVisitor<T> visitor);

  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg);
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg);

  /// Shallow clone of node.
  ///
  /// Does not clone positions since the only use of this private method is
  /// create a copy with a new position.
  Node _clone();

  /// Returns a node equivalent to [this], but with new source position and end
  /// source position.
  Node withSourceInformation(
      JavaScriptNodeSourceInformation? sourceInformation) {
    if (sourceInformation == _sourceInformation) {
      return this;
    }
    Node clone = _clone();
    // TODO(sra): Should existing data be 'sticky' if we try to overwrite with
    // `null`?
    clone._sourceInformation = sourceInformation;
    return clone;
  }

  bool get isCommaOperator => false;

  Statement toStatement() {
    throw UnsupportedError('toStatement');
  }

  String debugPrint() => DebugPrint(this);

  /// Some nodes, e.g. DeferredExpression, become finalized in a 'linking'
  /// phase.
  bool get isFinalized => true;

  /// If a node is not finalized, debug printing can print something indicative
  /// of the node instead of the finalized AST. This method returns the
  /// replacement text.
  String nonfinalizedDebugText() {
    assert(!isFinalized);
    return '$runtimeType';
  }
}

class Program extends Node {
  final List<Statement> body;
  Program(this.body);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitProgram(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitProgram(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    for (Statement statement in body) {
      statement.accept(visitor);
    }
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    for (Statement statement in body) {
      statement.accept1(visitor, arg);
    }
  }

  @override
  Program _clone() => Program(body);
}

abstract class Statement extends Node {
  @override
  Statement toStatement() => this;
}

/// Interface for a deferred [Statement] value. An implementation has to provide
/// a value via the [statement] getter the latest when the ast is printed.
abstract class DeferredStatement extends Statement {
  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitDeferredStatement(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitDeferredStatement(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    statement.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    statement.accept1(visitor, arg);
  }

  Statement get statement;
}

class Block extends Statement {
  final List<Statement> statements;

  Block(this.statements);

  Block.empty() : statements = [];

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitBlock(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitBlock(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    for (Statement statement in statements) {
      statement.accept(visitor);
    }
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    for (Statement statement in statements) {
      statement.accept1(visitor, arg);
    }
  }

  @override
  Block _clone() => Block(statements);
}

class ExpressionStatement extends Statement {
  final Expression expression;

  ExpressionStatement(this.expression);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitExpressionStatement(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitExpressionStatement(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    expression.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    expression.accept1(visitor, arg);
  }

  @override
  ExpressionStatement _clone() => ExpressionStatement(expression);
}

class EmptyStatement extends Statement {
  EmptyStatement();

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitEmptyStatement(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitEmptyStatement(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {}

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  @override
  EmptyStatement _clone() => EmptyStatement();
}

class If extends Statement {
  final Expression condition;
  final Statement then;
  final Statement otherwise;

  If(this.condition, this.then, this.otherwise);

  If.noElse(this.condition, this.then) : otherwise = EmptyStatement();

  bool get hasElse => otherwise is! EmptyStatement;

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitIf(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitIf(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    condition.accept(visitor);
    then.accept(visitor);
    otherwise.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    condition.accept1(visitor, arg);
    then.accept1(visitor, arg);
    otherwise.accept1(visitor, arg);
  }

  @override
  If _clone() => If(condition, then, otherwise);
}

abstract class Loop extends Statement {
  final Statement body;
  Loop(this.body);
}

class For extends Loop {
  final Expression? init;
  final Expression? condition;
  final Expression? update;

  For(this.init, this.condition, this.update, Statement body) : super(body);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitFor(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitFor(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    init?.accept(visitor);
    condition?.accept(visitor);
    update?.accept(visitor);
    body.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    init?.accept1(visitor, arg);
    condition?.accept1(visitor, arg);
    update?.accept1(visitor, arg);
    body.accept1(visitor, arg);
  }

  @override
  For _clone() => For(init, condition, update, body);
}

class ForIn extends Loop {
  // Note that [VariableDeclarationList] is a subclass of [Expression].
  // Therefore we can type the leftHandSide as [Expression].
  final Expression leftHandSide;
  final Expression object;

  ForIn(this.leftHandSide, this.object, Statement body) : super(body);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitForIn(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitForIn(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    leftHandSide.accept(visitor);
    object.accept(visitor);
    body.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    leftHandSide.accept1(visitor, arg);
    object.accept1(visitor, arg);
    body.accept1(visitor, arg);
  }

  @override
  ForIn _clone() => ForIn(leftHandSide, object, body);
}

class While extends Loop {
  final Expression condition;

  While(this.condition, Statement body) : super(body);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitWhile(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitWhile(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    condition.accept(visitor);
    body.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    condition.accept1(visitor, arg);
    body.accept1(visitor, arg);
  }

  @override
  While _clone() => While(condition, body);
}

class Do extends Loop {
  final Expression condition;

  Do(Statement body, this.condition) : super(body);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitDo(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitDo(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    body.accept(visitor);
    condition.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    body.accept1(visitor, arg);
    condition.accept1(visitor, arg);
  }

  @override
  Do _clone() => Do(body, condition);
}

class Continue extends Statement {
  /// Name of the label L for `continue L;` or `null` for `continue;`.
  final String? targetLabel;

  Continue(this.targetLabel);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitContinue(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitContinue(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {}

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  @override
  Continue _clone() => Continue(targetLabel);
}

class Break extends Statement {
  /// Name of the label L for `break L;` or `null` for `break;`.
  final String? targetLabel;

  Break(this.targetLabel);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitBreak(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitBreak(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {}

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  @override
  Break _clone() => Break(targetLabel);
}

class Return extends Statement {
  /// The expression for `return expression;`, or `null` for `return;`.
  final Expression? value;

  Return([this.value]);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitReturn(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitReturn(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    value?.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    value?.accept1(visitor, arg);
  }

  @override
  Return _clone() => Return(value);
}

class Throw extends Statement {
  final Expression expression;

  Throw(this.expression);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitThrow(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitThrow(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    expression.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    expression.accept1(visitor, arg);
  }

  @override
  Throw _clone() => Throw(expression);
}

class Try extends Statement {
  final Block body;
  final Catch? catchPart; // Can be null if [finallyPart] is non-null.
  final Block? finallyPart; // Can be null if [catchPart] is non-null.

  Try(this.body, this.catchPart, this.finallyPart) {
    assert(catchPart != null || finallyPart != null);
  }

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitTry(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitTry(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    body.accept(visitor);
    catchPart?.accept(visitor);
    finallyPart?.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    body.accept1(visitor, arg);
    catchPart?.accept1(visitor, arg);
    finallyPart?.accept1(visitor, arg);
  }

  @override
  Try _clone() => Try(body, catchPart, finallyPart);
}

class Catch extends Node {
  final Declaration declaration;
  final Block body;

  Catch(this.declaration, this.body);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitCatch(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitCatch(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    declaration.accept(visitor);
    body.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    declaration.accept1(visitor, arg);
    body.accept1(visitor, arg);
  }

  @override
  Catch _clone() => Catch(declaration, body);
}

class Switch extends Statement {
  final Expression key;
  final List<SwitchClause> cases;

  Switch(this.key, this.cases);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitSwitch(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitSwitch(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    key.accept(visitor);
    for (SwitchClause clause in cases) {
      clause.accept(visitor);
    }
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    key.accept1(visitor, arg);
    for (SwitchClause clause in cases) {
      clause.accept1(visitor, arg);
    }
  }

  @override
  Switch _clone() => Switch(key, cases);
}

abstract class SwitchClause extends Node {
  final Block body;

  SwitchClause(this.body);
}

class Case extends SwitchClause {
  final Expression expression;

  Case(this.expression, Block body) : super(body);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitCase(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitCase(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    expression.accept(visitor);
    body.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    expression.accept1(visitor, arg);
    body.accept1(visitor, arg);
  }

  @override
  Case _clone() => Case(expression, body);
}

class Default extends SwitchClause {
  Default(Block body) : super(body);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitDefault(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitDefault(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    body.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    body.accept1(visitor, arg);
  }

  @override
  Default _clone() => Default(body);
}

class FunctionDeclaration extends Statement {
  final Declaration name;
  final Fun function;

  FunctionDeclaration(this.name, this.function);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitFunctionDeclaration(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitFunctionDeclaration(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    name.accept(visitor);
    function.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    name.accept1(visitor, arg);
    function.accept1(visitor, arg);
  }

  @override
  FunctionDeclaration _clone() => FunctionDeclaration(name, function);
}

class LabeledStatement extends Statement {
  final String label;
  final Statement body;

  LabeledStatement(this.label, this.body);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLabeledStatement(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitLabeledStatement(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    body.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    body.accept1(visitor, arg);
  }

  @override
  LabeledStatement _clone() => LabeledStatement(label, body);
}

class LiteralStatement extends Statement {
  final String code;

  LiteralStatement(this.code);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralStatement(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitLiteralStatement(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {}

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  @override
  LiteralStatement _clone() => LiteralStatement(code);
}

/// Not a real JavaScript node, but represents the yield statement from a dart
/// program translated to JavaScript.
class DartYield extends Statement {
  final Expression expression;

  final bool hasStar;

  DartYield(this.expression, this.hasStar);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitDartYield(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitDartYield(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    expression.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    expression.accept1(visitor, arg);
  }

  @override
  DartYield _clone() => DartYield(expression, hasStar);
}

abstract class Expression extends Node {
  // [precedenceLevel] must not be used before printing, as deferred nodes can
  // have precedence depending on how the deferred node is resolved.
  int get precedenceLevel;

  @override
  Statement toStatement() => ExpressionStatement(this);
}

abstract class Declaration implements VariableReference {}

/// [Name] is an extension point to allow a JavaScript AST to contain
/// identifiers that are bound later. This is used in minification.
///
/// [Name] is a [Literal] so that it can occur as a property access selector.
//
// TODO(sra): Figure out why [Name] is a Declaration and Parameter, and where
// that is used. How should the printer know if an occurrence of a Name is meant
// to be a Literal or a Declaration (which includes a VariableUse)?
abstract class Name extends Literal implements Declaration, Parameter {
  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitName(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitName(this, arg);

  @override
  Name _clone();

  /// Returns the text of this name.
  ///
  /// May throw if the text has not been decided. Typically the text is decided
  /// in some finalization phase that happens before the AST is printed.
  @override
  String get name;

  /// Returns a unique [key] for this name.
  ///
  /// The key is unrelated to the actual name and is not intended for human
  /// consumption. As such, it might be long or cryptic.
  String get key;

  @override
  bool get allowRename => false;
}

class LiteralStringFromName extends LiteralString {
  final Name name;

  LiteralStringFromName(this.name) : super('') {
    ArgumentError.checkNotNull(name, 'name');
  }

  @override
  bool get isFinalized => name.isFinalized;

  @override
  String get value => name.name;

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    name.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    name.accept1(visitor, arg);
  }
}

class LiteralExpression extends Expression {
  final String template;
  LiteralExpression(this.template);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralExpression(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitLiteralExpression(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {}

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  @override
  LiteralExpression _clone() => LiteralExpression(template);

  // Code that uses LiteralExpression must take care of operator precedences,
  // and put parenthesis if needed.
  @override
  int get precedenceLevel => PRIMARY;
}

/// [VariableDeclarationList] is a subclass of [Expression] to simplify the AST.
class VariableDeclarationList extends Expression {
  final List<VariableInitialization> declarations;

  /// When pretty-printing a declaration list with multiple declarations over
  /// several lines, the declarations are usually indented with respect to the
  /// `var` keyword. Set [indentSplits] to `false` to suppress the indentation.
  final bool indentSplits;

  VariableDeclarationList(this.declarations, {this.indentSplits = true});

  @override
  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitVariableDeclarationList(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitVariableDeclarationList(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    for (VariableInitialization declaration in declarations) {
      declaration.accept(visitor);
    }
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    for (VariableInitialization declaration in declarations) {
      declaration.accept1(visitor, arg);
    }
  }

  @override
  VariableDeclarationList _clone() => VariableDeclarationList(declarations);

  @override
  int get precedenceLevel => EXPRESSION;
}

/// Forced parenthesized expression. Pretty-printing will emit parentheses based
/// on need, so this node is very rarely needed.
class Parentheses extends Expression {
  final Expression enclosed;

  Parentheses(this.enclosed);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitParentheses(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitParentheses(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    enclosed.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    enclosed.accept1(visitor, arg);
  }

  @override
  Parentheses _clone() => Parentheses(enclosed);

  @override
  int get precedenceLevel => PRIMARY;
}

class Assignment extends Expression {
  final Expression leftHandSide;
  final String? op; // `null` if the assignment is not compound.
  final Expression value;

  Assignment(this.leftHandSide, this.value) : op = null;

  // If `this.op == null` this will be a non-compound assignment.
  Assignment.compound(this.leftHandSide, this.op, this.value);

  @override
  int get precedenceLevel => ASSIGNMENT;

  bool get isCompound => op != null;

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitAssignment(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitAssignment(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    leftHandSide.accept(visitor);
    value.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    leftHandSide.accept1(visitor, arg);
    value.accept1(visitor, arg);
  }

  @override
  Assignment _clone() => Assignment.compound(leftHandSide, op, value);
}

class VariableInitialization extends Expression {
  // TODO(sra): Can [VariableInitialization] be a non-expression?

  final Declaration declaration;
  // The initializing value can be missing, e.g. for `a` in `var a, b=1;`.
  final Expression? value;

  VariableInitialization(this.declaration, this.value);

  @override
  int get precedenceLevel => ASSIGNMENT;

  @override
  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitVariableInitialization(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitVariableInitialization(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    declaration.accept(visitor);
    value?.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    declaration.accept1(visitor, arg);
    value?.accept1(visitor, arg);
  }

  @override
  VariableInitialization _clone() => VariableInitialization(declaration, value);
}

class Conditional extends Expression {
  final Expression condition;
  final Expression then;
  final Expression otherwise;

  Conditional(this.condition, this.then, this.otherwise);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitConditional(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitConditional(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    condition.accept(visitor);
    then.accept(visitor);
    otherwise.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    condition.accept1(visitor, arg);
    then.accept1(visitor, arg);
    otherwise.accept1(visitor, arg);
  }

  @override
  Conditional _clone() => Conditional(condition, then, otherwise);

  @override
  int get precedenceLevel => ASSIGNMENT;
}

class Call extends Expression {
  Expression target;
  List<Expression> arguments;

  Call(this.target, this.arguments,
      {JavaScriptNodeSourceInformation? sourceInformation}) {
    _sourceInformation = sourceInformation;
  }

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitCall(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitCall(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    target.accept(visitor);
    for (Expression arg in arguments) {
      arg.accept(visitor);
    }
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    target.accept1(visitor, arg);
    for (Expression arg in arguments) {
      arg.accept1(visitor, arg);
    }
  }

  @override
  Call _clone() => Call(target, arguments);

  @override
  int get precedenceLevel => CALL;
}

class New extends Call {
  New(Expression cls, List<Expression> arguments) : super(cls, arguments);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitNew(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitNew(this, arg);

  @override
  New _clone() => New(target, arguments);
}

class Binary extends Expression {
  final String op;
  final Expression left;
  final Expression right;

  Binary(this.op, this.left, this.right);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitBinary(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitBinary(this, arg);

  @override
  Binary _clone() => Binary(op, left, right);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    left.accept(visitor);
    right.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    left.accept1(visitor, arg);
    right.accept1(visitor, arg);
  }

  @override
  bool get isCommaOperator => op == ',';

  @override
  int get precedenceLevel {
    // TODO(floitsch): switch to constant map.
    switch (op) {
      case '**':
        return EXPONENTIATION;
      case '*':
      case '/':
      case '%':
        return MULTIPLICATIVE;
      case '+':
      case '-':
        return ADDITIVE;
      case '<<':
      case '>>':
      case '>>>':
        return SHIFT;
      case '<':
      case '>':
      case '<=':
      case '>=':
      case 'instanceof':
      case 'in':
        return RELATIONAL;
      case '==':
      case '===':
      case '!=':
      case '!==':
        return EQUALITY;
      case '&':
        return BIT_AND;
      case '^':
        return BIT_XOR;
      case '|':
        return BIT_OR;
      case '&&':
        return LOGICAL_AND;
      case '||':
        return LOGICAL_OR;
      case ',':
        return EXPRESSION;
      default:
        throw 'Internal Error: Unhandled binary operator: $op';
    }
  }
}

class Prefix extends Expression {
  final String op;
  final Expression argument;

  Prefix(this.op, this.argument);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitPrefix(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitPrefix(this, arg);

  @override
  Prefix _clone() => Prefix(op, argument);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    argument.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    argument.accept1(visitor, arg);
  }

  @override
  int get precedenceLevel => UNARY;
}

class Postfix extends Expression {
  final String op;
  final Expression argument;

  Postfix(this.op, this.argument);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitPostfix(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitPostfix(this, arg);

  @override
  Postfix _clone() => Postfix(op, argument);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    argument.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    argument.accept1(visitor, arg);
  }

  @override
  int get precedenceLevel => UNARY;
}

RegExp _identifierRE = RegExp(r'^[A-Za-z_$][A-Za-z_$0-9]*$');

abstract class VariableReference extends Expression {
  final String name;

  VariableReference(this.name) {
    assert(_identifierRE.hasMatch(name), "Non-identifier name '$name'");
  }

  @override
  T accept<T>(NodeVisitor<T> visitor);

  @override
  int get precedenceLevel => PRIMARY;

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {}

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}
}

class VariableUse extends VariableReference {
  VariableUse(String name) : super(name);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitVariableUse(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitVariableUse(this, arg);

  @override
  VariableUse _clone() => VariableUse(name);

  @override
  String toString() => 'VariableUse($name)';
}

class VariableDeclaration extends VariableReference implements Declaration {
  final bool allowRename;

  VariableDeclaration(String name, {this.allowRename = true}) : super(name);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitVariableDeclaration(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitVariableDeclaration(this, arg);

  @override
  VariableDeclaration _clone() => VariableDeclaration(name);
}

class Parameter extends VariableDeclaration {
  Parameter(String name) : super(name);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitParameter(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitParameter(this, arg);

  @override
  Parameter _clone() => Parameter(name);
}

class This extends Parameter {
  This() : super('this');

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitThis(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitThis(this, arg);

  @override
  This _clone() => This();
}

class NamedFunction extends Expression {
  final Declaration name;
  final Fun function;

  NamedFunction(this.name, this.function);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitNamedFunction(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitNamedFunction(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    name.accept(visitor);
    function.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    name.accept1(visitor, arg);
    function.accept1(visitor, arg);
  }

  @override
  NamedFunction _clone() => NamedFunction(name, function);

  @override
  int get precedenceLevel => LEFT_HAND_SIDE;
}

abstract class FunctionExpression extends Expression {
  Node get body;
  List<Parameter> get params;
  AsyncModifier get asyncModifier;
}

class Fun extends FunctionExpression {
  @override
  final Block body;
  @override
  final List<Parameter> params;
  @override
  final AsyncModifier asyncModifier;

  Fun(this.params, this.body, {this.asyncModifier = AsyncModifier.sync});

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitFun(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitFun(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    for (Parameter param in params) {
      param.accept(visitor);
    }
    body.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    for (Parameter param in params) {
      param.accept1(visitor, arg);
    }
    body.accept1(visitor, arg);
  }

  @override
  Fun _clone() => Fun(params, body, asyncModifier: asyncModifier);

  @override
  int get precedenceLevel => LEFT_HAND_SIDE;
}

class ArrowFunction extends FunctionExpression {
  @override
  final Node body;
  @override
  final List<Parameter> params;
  @override
  final AsyncModifier asyncModifier;

  /// Indicates whether it is permissible to try to emit this arrow function
  /// in a form with an implicit 'return'.
  final bool implicitReturnAllowed;

  ArrowFunction(this.params, this.body,
      {this.asyncModifier = AsyncModifier.sync,
      this.implicitReturnAllowed = true});

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitArrowFunction(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitArrowFunction(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    for (Parameter param in params) {
      param.accept(visitor);
    }
    body.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    for (Parameter param in params) {
      param.accept1(visitor, arg);
    }
    body.accept1(visitor, arg);
  }

  @override
  ArrowFunction _clone() => ArrowFunction(params, body,
      asyncModifier: asyncModifier,
      implicitReturnAllowed: implicitReturnAllowed);

  @override
  int get precedenceLevel => ASSIGNMENT;
}

class AsyncModifier {
  final int index;
  final bool isAsync;
  final bool isYielding;
  final String description;

  const AsyncModifier(this.index, this.description,
      {required this.isAsync, required this.isYielding});

  static const AsyncModifier sync =
      AsyncModifier(0, 'sync', isAsync: false, isYielding: false);
  static const AsyncModifier async =
      AsyncModifier(1, 'async', isAsync: true, isYielding: false);
  static const AsyncModifier asyncStar =
      AsyncModifier(2, 'async*', isAsync: true, isYielding: true);
  static const AsyncModifier syncStar =
      AsyncModifier(3, 'sync*', isAsync: false, isYielding: true);

  static const List<AsyncModifier> values = [sync, async, asyncStar, syncStar];

  @override
  String toString() => description;
}

class PropertyAccess extends Expression {
  final Expression receiver;
  final Expression selector;

  PropertyAccess(this.receiver, this.selector);

  PropertyAccess.field(this.receiver, String fieldName)
      : selector = LiteralString(fieldName);

  PropertyAccess.indexed(this.receiver, int index)
      : selector = LiteralNumber('$index');

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitAccess(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitAccess(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    receiver.accept(visitor);
    selector.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    receiver.accept1(visitor, arg);
    selector.accept1(visitor, arg);
  }

  @override
  PropertyAccess _clone() => PropertyAccess(receiver, selector);

  @override
  int get precedenceLevel => LEFT_HAND_SIDE;
}

/// A [DeferredToken] is a placeholder for some [Expression] that is not known
/// at construction time of an ast. Unlike [InterpolatedExpression],
/// [DeferredToken] is not limited to templates but may also occur in
/// fully instantiated asts.
abstract class DeferredToken extends Expression {
  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {}

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  @override
  DeferredToken _clone() => this;
}

/// Interface for a deferred integer value. An implementation has to provide
/// a value via the [value] getter the latest when the ast is printed.
abstract class DeferredNumber extends DeferredToken implements Literal {
  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitDeferredNumber(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitDeferredNumber(this, arg);

  int get value;

  @override
  int get precedenceLevel => value.isNegative ? UNARY : PRIMARY;
}

/// Interface for a deferred string value. An implementation has to provide
/// a value via the [value] getter the latest when the ast is printed.
abstract class DeferredString extends DeferredToken implements Literal {
  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitDeferredString(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitDeferredString(this, arg);

  String get value;

  @override
  int get precedenceLevel => PRIMARY;
}

/// Interface for a deferred [Expression] value. An implementation has to provide
/// a value via the [value] getter the latest when the ast is printed.
/// Also, [precedenceLevel] has to return the same value that
/// [value.precedenceLevel] returns once [value] is bound to an [Expression].
abstract class DeferredExpression extends DeferredToken {
  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitDeferredExpression(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitDeferredExpression(this, arg);

  Expression get value;
}

abstract class Literal extends Expression {
  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {}

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  @override
  int get precedenceLevel => PRIMARY;
}

class LiteralBool extends Literal {
  final bool value;

  LiteralBool(this.value);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralBool(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitLiteralBool(this, arg);

  // [visitChildren] inherited from [Literal].

  @override
  LiteralBool _clone() => LiteralBool(value);
}

class LiteralNull extends Literal {
  LiteralNull();

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralNull(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitLiteralNull(this, arg);

  @override
  LiteralNull _clone() => LiteralNull();
}

class LiteralString extends Literal {
  final String value;

  /// Constructs a LiteralString for a string containing the characters of
  /// `value`.
  ///
  /// When printed, the string will be escaped and quoted according to the
  /// printer's settings.
  LiteralString(this.value);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralString(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitLiteralString(this, arg);

  @override
  LiteralString _clone() => LiteralString(value);

  @override
  String toString() {
    final sb = StringBuffer('$runtimeType("');
    String end = '"';
    int count = 0;
    for (int rune in value.runes) {
      if (++count > 20) {
        end = '"...';
        break;
      }
      if (32 <= rune && rune < 127) {
        sb.writeCharCode(rune);
      } else {
        sb.write(r'\u{');
        sb.write(rune.toRadixString(16));
        sb.write(r'}');
      }
    }
    sb.write(end);
    sb.write(')');
    return sb.toString();
  }
}

class StringConcatenation extends Literal {
  final List<Literal> parts;

  /// Constructs a StringConcatenation from a list of Literal elements.
  ///
  /// The constructor does not add surrounding quotes to the resulting
  /// concatenated string.
  StringConcatenation(this.parts);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitStringConcatenation(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitStringConcatenation(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    for (Literal part in parts) {
      part.accept(visitor);
    }
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    for (Literal part in parts) {
      part.accept1(visitor, arg);
    }
  }

  @override
  StringConcatenation _clone() => StringConcatenation(parts);
}

class LiteralNumber extends Literal {
  final String value; // Must be a valid JavaScript number literal.

  LiteralNumber(this.value);

  @override
  int get precedenceLevel => value.startsWith('-') ? UNARY : PRIMARY;

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralNumber(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitLiteralNumber(this, arg);

  @override
  LiteralNumber _clone() => LiteralNumber(value);
}

class ArrayInitializer extends Expression {
  final List<Expression> elements;

  ArrayInitializer(this.elements) : assert(!elements.contains(null));

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitArrayInitializer(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitArrayInitializer(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    for (Expression element in elements) {
      element.accept(visitor);
    }
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    for (Expression element in elements) {
      element.accept1(visitor, arg);
    }
  }

  @override
  ArrayInitializer _clone() => ArrayInitializer(elements);

  @override
  int get precedenceLevel => PRIMARY;
}

/// An empty place in an [ArrayInitializer].
/// For example the list [1, , , 2] would contain two holes.
class ArrayHole extends Expression {
  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitArrayHole(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitArrayHole(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {}

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  @override
  ArrayHole _clone() => ArrayHole();

  @override
  int get precedenceLevel => PRIMARY;
}

class ObjectInitializer extends Expression {
  final List<Property> properties;
  final bool isOneLiner;

  /// Constructs a new object-initializer containing the given [properties].
  ///
  /// [isOneLiner] describes the behavior when pretty-printing (non-minified).
  /// If true print all properties on the same line.
  /// If false print each property on a separate line.
  ObjectInitializer(this.properties, {this.isOneLiner = true});

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitObjectInitializer(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitObjectInitializer(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    for (Property init in properties) {
      init.accept(visitor);
    }
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    for (Property init in properties) {
      init.accept1(visitor, arg);
    }
  }

  @override
  ObjectInitializer _clone() =>
      ObjectInitializer(properties, isOneLiner: isOneLiner);

  @override
  int get precedenceLevel => PRIMARY;
}

class Property extends Node {
  final Expression name;
  final Expression value;

  Property(this.name, this.value)
      : assert(name is Literal || name is DeferredExpression);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitProperty(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitProperty(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    name.accept(visitor);
    value.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    name.accept1(visitor, arg);
    value.accept1(visitor, arg);
  }

  @override
  Property _clone() => Property(name, value);
}

class MethodDefinition extends Node implements Property {
  @override
  final Expression name;
  final Fun function;

  MethodDefinition(this.name, this.function);

  @override
  Fun get value => function;

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitMethodDefinition(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitMethodDefinition(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {
    name.accept(visitor);
    function.accept(visitor);
  }

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {
    name.accept1(visitor, arg);
    function.accept1(visitor, arg);
  }

  @override
  MethodDefinition _clone() => MethodDefinition(name, function);
}

/// Tag class for all interpolated positions.
abstract class InterpolatedNode implements Node {
  dynamic get nameOrPosition;

  bool get isNamed => nameOrPosition is String;

  bool get isPositional => nameOrPosition is int;
}

class InterpolatedExpression extends Expression with InterpolatedNode {
  @override
  final dynamic nameOrPosition;

  InterpolatedExpression(this.nameOrPosition);

  @override
  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitInterpolatedExpression(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitInterpolatedExpression(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {}

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  @override
  InterpolatedExpression _clone() => InterpolatedExpression(nameOrPosition);

  @override
  int get precedenceLevel => PRIMARY;
}

class InterpolatedLiteral extends Literal with InterpolatedNode {
  @override
  final dynamic nameOrPosition;

  InterpolatedLiteral(this.nameOrPosition);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitInterpolatedLiteral(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitInterpolatedLiteral(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {}

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  @override
  InterpolatedLiteral _clone() => InterpolatedLiteral(nameOrPosition);
}

class InterpolatedParameter extends Expression
    with InterpolatedNode
    implements Parameter {
  @override
  final dynamic nameOrPosition;

  InterpolatedParameter(this.nameOrPosition);

  @override
  String get name {
    throw 'InterpolatedParameter.name must not be invoked';
  }

  @override
  bool get allowRename => false;

  @override
  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitInterpolatedParameter(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitInterpolatedParameter(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {}

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  @override
  InterpolatedParameter _clone() => InterpolatedParameter(nameOrPosition);

  @override
  int get precedenceLevel => PRIMARY;
}

class InterpolatedSelector extends Expression with InterpolatedNode {
  @override
  final dynamic nameOrPosition;

  InterpolatedSelector(this.nameOrPosition);

  @override
  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitInterpolatedSelector(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitInterpolatedSelector(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {}

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  @override
  InterpolatedSelector _clone() => InterpolatedSelector(nameOrPosition);

  @override
  int get precedenceLevel => PRIMARY;
}

class InterpolatedStatement extends Statement with InterpolatedNode {
  @override
  final dynamic nameOrPosition;

  InterpolatedStatement(this.nameOrPosition);

  @override
  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitInterpolatedStatement(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitInterpolatedStatement(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {}

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  @override
  InterpolatedStatement _clone() => InterpolatedStatement(nameOrPosition);
}

class InterpolatedDeclaration extends Expression
    with InterpolatedNode
    implements Declaration {
  @override
  final dynamic nameOrPosition;

  InterpolatedDeclaration(this.nameOrPosition);

  @override
  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitInterpolatedDeclaration(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitInterpolatedDeclaration(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {}

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  @override
  InterpolatedDeclaration _clone() {
    return InterpolatedDeclaration(nameOrPosition);
  }

  @override
  String get name => throw 'No name for the interpolated node';

  @override
  int get precedenceLevel => PRIMARY;
}

/// [RegExpLiteral]s, despite being called "Literal", do not inherit from
/// [Literal].
///
/// Indeed, regular expressions in JavaScript have a side-effect and are thus
/// not in the same category as numbers or strings.
class RegExpLiteral extends Expression {
  /// Contains the pattern and the flags.
  final String pattern;

  RegExpLiteral(this.pattern);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitRegExpLiteral(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitRegExpLiteral(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {}

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}

  @override
  RegExpLiteral _clone() => RegExpLiteral(pattern);

  @override
  int get precedenceLevel => PRIMARY;
}

/// An asynchronous await.
///
/// Not part of JavaScript. We desugar this expression before outputting.
/// Should only occur in a [Fun] with `asyncModifier` async or asyncStar.
class Await extends Expression {
  /// The awaited expression.
  final Expression expression;

  Await(this.expression);

  @override
  int get precedenceLevel => UNARY;

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitAwait(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitAwait(this, arg);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) => expression.accept(visitor);

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      expression.accept1(visitor, arg);

  @override
  Await _clone() => Await(expression);
}

/// A comment.
///
/// Extends [Statement] so we can add comments before statements in
/// [Block] and [Program].
class Comment extends Statement {
  final String comment;

  Comment(this.comment);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitComment(this);

  @override
  R accept1<R, A>(NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitComment(this, arg);

  @override
  Comment _clone() => Comment(comment);

  @override
  void visitChildren<T>(NodeVisitor<T> visitor) {}

  @override
  void visitChildren1<R, A>(NodeVisitor1<R, A> visitor, A arg) {}
}

/// Returns the value of [node] if it is a [DeferredExpression].
///
/// Otherwise returns the [node] itself.
Node undefer(Node node) {
  return node is DeferredExpression ? undefer(node.value) : node;
}
