// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class AbstractVisitor<R> implements Visitor<R> {
  const AbstractVisitor();

  abstract R visitNode(Node node);

  R visitBlock(Block node) => visitStatement(node);
  R visitBreakStatement(BreakStatement node) => visitGotoStatement(node);
  R visitCascade(Cascade node) => visitExpression(node);
  R visitCascadeReceiver(CascadeReceiver node) => visitExpression(node);
  R visitCatchBlock(CatchBlock node) => visitNode(node);
  R visitClassNode(ClassNode node) => visitNode(node);
  R visitConditional(Conditional node) => visitExpression(node);
  R visitContinueStatement(ContinueStatement node) => visitGotoStatement(node);
  R visitDoWhile(DoWhile node) => visitLoop(node);
  R visitEmptyStatement(EmptyStatement node) => visitStatement(node);
  R visitExpression(Expression node) => visitNode(node);
  R visitExpressionStatement(ExpressionStatement node) => visitStatement(node);
  R visitFor(For node) => visitLoop(node);
  R visitForIn(ForIn node) => visitLoop(node);
  R visitFunctionDeclaration(FunctionDeclaration node) => visitStatement(node);
  R visitFunctionExpression(FunctionExpression node) => visitExpression(node);
  R visitGotoStatement(GotoStatement node) => visitStatement(node);
  R visitIdentifier(Identifier node) => visitExpression(node);
  R visitIf(If node) => visitStatement(node);
  R visitLabel(Label node) => visitNode(node);
  R visitLabeledStatement(LabeledStatement node) => visitStatement(node);
  R visitLiteral(Literal node) => visitExpression(node);
  R visitLiteralBool(LiteralBool node) => visitLiteral(node);
  R visitLiteralDouble(LiteralDouble node) => visitLiteral(node);
  R visitLiteralInt(LiteralInt node) => visitLiteral(node);
  R visitLiteralList(LiteralList node) => visitExpression(node);
  R visitLiteralMap(LiteralMap node) => visitExpression(node);
  R visitLiteralMapEntry(LiteralMapEntry node) => visitNode(node);
  R visitLiteralNull(LiteralNull node) => visitLiteral(node);
  R visitLiteralString(LiteralString node) => visitStringNode(node);
  R visitStringJuxtaposition(StringJuxtaposition node) => visitStringNode(node);
  R visitLoop(Loop node) => visitStatement(node);
  R visitModifiers(Modifiers node) => visitNode(node);
  R visitNamedArgument(NamedArgument node) => visitExpression(node);
  R visitNewExpression(NewExpression node) => visitExpression(node);
  R visitNodeList(NodeList node) => visitNode(node);
  R visitOperator(Operator node) => visitIdentifier(node);
  R visitParenthesizedExpression(ParenthesizedExpression node) {
    return visitExpression(node);
  }
  R visitPostfix(Postfix node) => visitNodeList(node);
  R visitPrefix(Prefix node) => visitNodeList(node);
  R visitReturn(Return node) => visitStatement(node);
  R visitScriptTag(ScriptTag node) => visitNode(node);
  R visitSend(Send node) => visitExpression(node);
  R visitSendSet(SendSet node) => visitSend(node);
  R visitStatement(Statement node) => visitNode(node);
  R visitStringNode(StringNode node) => visitExpression(node);
  R visitStringInterpolation(StringInterpolation node) => visitStringNode(node);
  R visitStringInterpolationPart(StringInterpolationPart node) {
    return visitNode(node);
  }
  R visitSwitchCase(SwitchCase node) => visitNode(node);
  R visitSwitchStatement(SwitchStatement node) => visitStatement(node);
  R visitThrow(Throw node) => visitStatement(node);
  R visitTryStatement(TryStatement node) => visitStatement(node);
  R visitTypeAnnotation(TypeAnnotation node) => visitNode(node);
  R visitTypedef(Typedef node) => visitNode(node);
  R visitTypeVariable(TypeVariable node) => visitNode(node);
  R visitVariableDefinitions(VariableDefinitions node) => visitStatement(node);
  R visitWhile(While node) => visitLoop(node);
}

/**
 * This visitor takes another visitor and applies it to every
 * node in the tree. There is currently no way to control the
 * traversal.
 */
class TraversingVisitor extends AbstractVisitor {
  final Visitor visitor;

  TraversingVisitor(Visitor this.visitor);

  visitNode(Node node) {
    node.accept(visitor);
    node.visitChildren(this);
  }
}
