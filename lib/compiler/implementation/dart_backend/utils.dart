// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CloningVisitor implements Visitor<Node> {
  final TreeElements originalTreeElements;
  final TreeElementMapping cloneTreeElements;

  CloningVisitor(this.originalTreeElements)
      : cloneTreeElements = new TreeElementMapping();

  visit(Node node) {
    if (node == null) return null;
    final clone = node.accept(this);

    final originalElement = originalTreeElements[node];
    if (originalElement != null) cloneTreeElements[clone] = originalElement;

    final originalType = originalTreeElements.getType(node);
    if (originalType != null) cloneTreeElements.setType(clone, originalType);
    return clone;
  }

  visitBlock(Block node) => new Block(visit(node.statements));

  visitBreakStatement(BreakStatement node) => new BreakStatement(
      visit(node.target), node.keywordToken, node.semicolonToken);

  visitCascade(Cascade node) => new Cascade(visit(node.expression));

  visitCascadeReceiver(CascadeReceiver node) => new CascadeReceiver(
      visit(node.expression), node.cascadeOperator);

  visitCaseMatch(CaseMatch node) => new CaseMatch(
      node.caseKeyword, visit(node.expression), node.colonToken);

  visitCatchBlock(CatchBlock node) => new CatchBlock(
      visit(node.type), visit(node.formals), visit(node.block),
      node.onKeyword, node.catchKeyword);

  visitClassNode(ClassNode node) => new ClassNode(
      visit(node.modifiers), visit(node.name), visit(node.typeParameters),
      visit(node.superclass), visit(node.interfaces), visit(node.defaultClause),
      node.beginToken, node.extendsKeyword, visit(node.body), node.endToken);

  visitConditional(Conditional node) => new Conditional(
      visit(node.condition), visit(node.thenExpression),
      visit(node.elseExpression), node.questionToken, node.colonToken);

  visitContinueStatement(ContinueStatement node) => new ContinueStatement(
      visit(node.target), node.keywordToken, node.semicolonToken);

  visitDoWhile(DoWhile node) => new DoWhile(
      visit(node.body), visit(node.condition),
      node.doKeyword, node.whileKeyword, node.endToken);

  visitEmptyStatement(EmptyStatement node) => new EmptyStatement(
      node.semicolonToken);

  visitExpressionStatement(ExpressionStatement node) => new ExpressionStatement(
      visit(node.expression), node.endToken);

  visitFor(For node) => new For(
      visit(node.initializer), visit(node.conditionStatement),
      visit(node.update), visit(node.body), node.forToken);

  visitForIn(ForIn node) => new ForIn(
      visit(node.declaredIdentifier), visit(node.expression), visit(node.body),
      node.forToken, node.inToken);

  visitFunctionDeclaration(FunctionDeclaration node) => new FunctionDeclaration(
      visit(node.function));

  rewriteFunctionExpression(FunctionExpression node, Statement body) =>
      new FunctionExpression(
          visit(node.name), visit(node.parameters), body,
          visit(node.returnType), visit(node.modifiers),
          visit(node.initializers), node.getOrSet);

  visitFunctionExpression(FunctionExpression node) =>
      rewriteFunctionExpression(node, visit(node.body));

  visitIdentifier(Identifier node) => new Identifier(node.token);

  visitIf(If node) => new If(
      visit(node.condition), visit(node.thenPart), visit(node.elsePart),
      node.ifToken, node.elseToken);

  visitLabel(Label node) => new Label(visit(node.identifier), node.colonToken);

  visitLabeledStatement(LabeledStatement node) => new LabeledStatement(
      visit(node.labels), visit(node.statement));

  visitLiteralBool(LiteralBool node) => new LiteralBool(
      node.token, node.handler);

  visitLiteralDouble(LiteralDouble node) => new LiteralDouble(
      node.token, node.handler);

  visitLiteralInt(LiteralInt node) => new LiteralInt(node.token, node.handler);

  visitLiteralList(LiteralList node) => new LiteralList(
      visit(node.typeArguments), visit(node.elements), node.constKeyword);

  visitLiteralMap(LiteralMap node) => new LiteralMap(
      visit(node.typeArguments), visit(node.entries), node.constKeyword);

  visitLiteralMapEntry(LiteralMapEntry node) => new LiteralMapEntry(
      visit(node.key), node.colonToken, visit(node.value));

  visitLiteralNull(LiteralNull node) => new LiteralNull(node.token);

  visitLiteralString(LiteralString node) => new LiteralString(
      node.token, node.dartString);

  visitModifiers(Modifiers node) => new Modifiers(visit(node.nodes));

  visitNamedArgument(NamedArgument node) => new NamedArgument(
      visit(node.name), node.colonToken, visit(node.expression));

  visitNewExpression(NewExpression node) => new NewExpression(
      node.newToken, visit(node.send));

  rewriteNodeList(NodeList node, Link link) =>
      new NodeList(node.beginToken, link, node.endToken, node.delimiter);

  visitNodeList(NodeList node) {
    // Special case for classes which exist in hierarchy, but not
    // in the visitor.
    if (node is Prefix) {
      return node.nodes.isEmpty ?
          new Prefix() : new Prefix.singleton(visit(node.nodes.head));
    }
    if (node is Postfix) {
      return node.nodes.isEmpty ?
          new Postfix() : new Postfix.singleton(visit(node.nodes.head));
    }
    LinkBuilder<Node> builder = new LinkBuilder<Node>();
    for (Node n in node.nodes) {
      builder.addLast(visit(n));
    }
    return rewriteNodeList(node, builder.toLink());
  }

  visitOperator(Operator node) => new Operator(node.token);

  visitParenthesizedExpression(ParenthesizedExpression node) =>
      new ParenthesizedExpression(visit(node.expression), node.beginToken);

  visitReturn(Return node) => new Return(
      node.beginToken, node.endToken, visit(node.expression));

  visitScriptTag(ScriptTag node) => new ScriptTag(
      visit(node.tag), visit(node.argument),
      visit(node.prefixIdentifier), visit(node.prefix),
      node.beginToken, node.endToken);

  visitSend(Send node) => new Send(
      visit(node.receiver), visit(node.selector), visit(node.argumentsNode));

  visitSendSet(SendSet node) => new SendSet(
      visit(node.receiver), visit(node.selector),
      visit(node.assignmentOperator), visit(node.argumentsNode));

  visitStringInterpolation(StringInterpolation node) =>
      new StringInterpolation(visit(node.string), visit(node.parts));

  visitStringInterpolationPart(StringInterpolationPart node) =>
      new StringInterpolationPart(visit(node.expression), visit(node.string));

  visitStringJuxtaposition(StringJuxtaposition node) =>
      new StringJuxtaposition(visit(node.first), visit(node.second));

  visitSwitchCase(SwitchCase node) => new SwitchCase(
      visit(node.labelsAndCases), node.defaultKeyword, visit(node.statements),
      node.startToken);

  visitSwitchStatement(SwitchStatement node) => new SwitchStatement(
      visit(node.parenthesizedExpression), visit(node.cases),
      node.switchKeyword);

  visitThrow(Throw node) => new Throw(
      visit(node.expression), node.throwToken, node.endToken);

  visitTryStatement(TryStatement node) => new TryStatement(
      visit(node.tryBlock), visit(node.catchBlocks), visit(node.finallyBlock),
      node.tryKeyword, node.finallyKeyword);

  visitTypeAnnotation(TypeAnnotation node) => new TypeAnnotation(
      visit(node.typeName), visit(node.typeArguments));

  visitTypedef(Typedef node) => new Typedef(
      visit(node.returnType), visit(node.name), visit(node.typeParameters),
      visit(node.formals), node.typedefKeyword, node.endToken);

  visitTypeVariable(TypeVariable node) => new TypeVariable(
      visit(node.name), visit(node.bound));

  visitVariableDefinitions(VariableDefinitions node) => new VariableDefinitions(
      visit(node.type), visit(node.modifiers), visit(node.definitions),
      node.endToken);

  visitWhile(While node) => new While(
      visit(node.condition), visit(node.body), node.whileKeyword);

  Node visitNode(Node node) {
    unimplemented('visitNode', node: node);
  }

  Node visitCombinator(Combinator node) {
    unimplemented('visitNode', node: node);
  }

  Node visitExport(Export node) {
    unimplemented('visitNode', node: node);
  }

  Node visitExpression(Expression node) {
    unimplemented('visitNode', node: node);
  }

  Node visitGotoStatement(GotoStatement node) {
    unimplemented('visitNode', node: node);
  }

  Node visitImport(Import node) {
    unimplemented('visitNode', node: node);
  }

  Node visitLibraryDependency(LibraryTag node) {
    unimplemented('visitNode', node: node);
  }

  Node visitLibraryName(LibraryName node) {
    unimplemented('visitNode', node: node);
  }

  Node visitLibraryTag(LibraryTag node) {
    unimplemented('visitNode', node: node);
  }

  Node visitLiteral(Literal node) {
    unimplemented('visitNode', node: node);
  }

  Node visitLoop(Loop node) {
    unimplemented('visitNode', node: node);
  }

  Node visitPart(Part node) {
    unimplemented('visitNode', node: node);
  }

  Node visitPartOf(PartOf node) {
    unimplemented('visitNode', node: node);
  }

  Node visitPostfix(Postfix node) {
    unimplemented('visitNode', node: node);
  }

  Node visitPrefix(Prefix node) {
    unimplemented('visitNode', node: node);
  }

  Node visitStatement(Statement node) {
    unimplemented('visitNode', node: node);
  }

  Node visitStringNode(StringNode node) {
    unimplemented('visitNode', node: node);
  }

  unimplemented(String message, {Node node}) {
    throw message;
  }
}
