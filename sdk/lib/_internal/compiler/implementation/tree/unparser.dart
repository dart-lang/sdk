// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of tree;

String unparse(Node node) {
  Unparser unparser = new Unparser();
  unparser.unparse(node);
  return unparser.result;
}

class Unparser implements Visitor {
  final StringBuffer sb;

  String get result => sb.toString();

  Unparser() : sb = new StringBuffer();

  void add(String string) {
    sb.write(string);
  }

  void addToken(Token token) {
    if (token == null) return;
    add(token.value);
    if (identical(token.kind, KEYWORD_TOKEN)
        || identical(token.kind, IDENTIFIER_TOKEN)) {
      sb.write(' ');
    }
  }

  unparse(Node node) { visit(node); }

  visit(Node node) {
    if (node != null) node.accept(this);
  }

  visitBlock(Block node) {
    visit(node.statements);
  }

  visitCascade(Cascade node) {
    visit(node.expression);
  }

  visitCascadeReceiver(CascadeReceiver node) {
    visit(node.expression);
  }

  unparseClassWithBody(ClassNode node, members) {
    addToken(node.beginToken);
    if (node.beginToken.stringValue == 'abstract') {
      addToken(node.beginToken.next);
    }
    visit(node.name);
    if (node.typeParameters != null) {
      visit(node.typeParameters);
    }
    if (node.extendsKeyword != null) {
      sb.write(' ');
      addToken(node.extendsKeyword);
      visit(node.superclass);
    }
    if (!node.interfaces.isEmpty) {
      sb.write(' ');
      visit(node.interfaces);
    }
    sb.write('{');
    for (final member in members) {
      visit(member);
    }
    sb.write('}');
  }

  visitClassNode(ClassNode node) {
    unparseClassWithBody(node, node.body.nodes);
  }

  visitMixinApplication(MixinApplication node) {
    visit(node.superclass);
    sb.write(' with ');
    visit(node.mixins);
  }

  visitNamedMixinApplication(NamedMixinApplication node) {
    if (!node.modifiers.nodes.isEmpty) {
      visit(node.modifiers);
      sb.write(' ');
    }
    sb.write('class ');
    visit(node.name);
    if (node.typeParameters != null) {
      visit(node.typeParameters);
    }
    sb.write(' = ');
    visit(node.mixinApplication);
    if (node.interfaces != null) {
      sb.write(' implements ');
      visit(node.interfaces);
    }
    sb.write(';');
  }

  visitConditional(Conditional node) {
    visit(node.condition);
    add(node.questionToken.value);
    visit(node.thenExpression);
    add(node.colonToken.value);
    visit(node.elseExpression);
  }

  visitExpressionStatement(ExpressionStatement node) {
    visit(node.expression);
    add(node.endToken.value);
  }

  visitFor(For node) {
    add(node.forToken.value);
    sb.write('(');
    visit(node.initializer);
    sb.write(';');
    visit(node.conditionStatement);
    visit(node.update);
    sb.write(')');
    visit(node.body);
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    visit(node.function);
  }

  void unparseFunctionName(Node name) {
    // TODO(antonm): that's a workaround as currently FunctionExpression
    // names are modelled with Send and it emits operator[] as only
    // operator, without [] which are expected to be emitted with
    // arguments.
    if (name is Send) {
      Send send = name;
      assert(send is !SendSet);
      if (!send.isOperator) {
        // Looks like a factory method.
        visit(send.receiver);
        sb.write('.');
      } else {
        visit(send.receiver);
        Identifier identifier = send.selector.asIdentifier();
        if (identical(identifier.token.kind, KEYWORD_TOKEN)) {
          sb.write(' ');
        } else if (identifier.source == 'negate') {
          // TODO(ahe): Remove special case for negate.
          sb.write(' ');
        }
      }
      visit(send.selector);
    } else {
      visit(name);
    }
  }

  visitFunctionExpression(FunctionExpression node) {
    if (!node.modifiers.nodes.isEmpty) {
      visit(node.modifiers);
      sb.write(' ');
    }
    if (node.returnType != null) {
      visit(node.returnType);
      sb.write(' ');
    }
    if (node.getOrSet != null) {
      add(node.getOrSet.value);
      sb.write(' ');
    }
    unparseFunctionName(node.name);
    visit(node.parameters);
    visit(node.initializers);
    visit(node.body);
  }

  visitIdentifier(Identifier node) {
    add(node.token.value);
  }

  visitIf(If node) {
    add(node.ifToken.value);
    visit(node.condition);
    visit(node.thenPart);
    if (node.hasElsePart) {
      add(node.elseToken.value);
      if (node.elsePart is !Block) sb.write(' ');
      visit(node.elsePart);
    }
  }

  visitLiteralBool(LiteralBool node) {
    add(node.token.value);
  }

  visitLiteralDouble(LiteralDouble node) {
    add(node.token.value);
    // -Lit is represented as a send.
    if (node.token.kind == PLUS_TOKEN) add(node.token.next.value);
  }

  visitLiteralInt(LiteralInt node) {
    add(node.token.value);
    // -Lit is represented as a send.
    if (node.token.kind == PLUS_TOKEN) add(node.token.next.value);
  }

  visitLiteralString(LiteralString node) {
    add(node.token.value);
  }

  visitStringJuxtaposition(StringJuxtaposition node) {
    visit(node.first);
    sb.write(" ");
    visit(node.second);
  }

  visitLiteralNull(LiteralNull node) {
    add(node.token.value);
  }

  visitLiteralSymbol(LiteralSymbol node) {
    add(node.hashToken.value);
    visit(node.identifiers);
  }

  visitNewExpression(NewExpression node) {
    addToken(node.newToken);
    visit(node.send);
  }

  visitLiteralList(LiteralList node) {
    if (node.constKeyword != null) add(node.constKeyword.value);
    visit(node.typeArguments);
    visit(node.elements);
    // If list is empty, emit space after [] to disambiguate cases like []==[].
    if (node.elements.isEmpty) sb.write(' ');
  }

  visitModifiers(Modifiers node) => node.visitChildren(this);

  /**
   * Unparses given NodeList starting from specific node.
   */
  unparseNodeListFrom(NodeList node, Link<Node> from) {
    if (from.isEmpty) return;
    String delimiter = (node.delimiter == null) ? "" : "${node.delimiter}";
    visit(from.head);
    for (Link link = from.tail; !link.isEmpty; link = link.tail) {
      sb.write(delimiter);
      visit(link.head);
    }
  }

  visitNodeList(NodeList node) {
    addToken(node.beginToken);
    if (node.nodes != null) {
      unparseNodeListFrom(node, node.nodes);
    }
    if (node.endToken != null) add(node.endToken.value);
  }

  visitOperator(Operator node) {
    visitIdentifier(node);
  }

  visitRethrow(Rethrow node) {
    sb.write('rethrow;');
  }

  visitReturn(Return node) {
    if (node.isRedirectingFactoryBody) {
      sb.write(' ');
    }
    add(node.beginToken.value);
    if (node.hasExpression && node.beginToken.stringValue != '=>') {
      sb.write(' ');
    }
    visit(node.expression);
    if (node.endToken != null) add(node.endToken.value);
  }

  unparseSendReceiver(Send node, {bool spacesNeeded: false}) {
    if (node.receiver == null) return;
    visit(node.receiver);
    CascadeReceiver asCascadeReceiver = node.receiver.asCascadeReceiver();
    if (asCascadeReceiver != null) {
      add(asCascadeReceiver.cascadeOperator.value);
    } else if (node.selector.asOperator() == null) {
      sb.write('.');
    } else if (spacesNeeded) {
      sb.write(' ');
    }
  }

  visitSend(Send node) {
    Operator op = node.selector.asOperator();
    String opString = op != null ? op.source : null;
    bool spacesNeeded = identical(opString, 'is') || identical(opString, 'as');

    if (node.isPrefix) visit(node.selector);
    unparseSendReceiver(node, spacesNeeded: spacesNeeded);
    if (!node.isPrefix && !node.isIndex) visit(node.selector);
    if (spacesNeeded) sb.write(' ');
    // Also add a space for sequences like x + +1 and y - -y.
    // TODO(ahe): remove case for '+' when we drop the support for it.
    if (node.argumentsNode != null && (identical(opString, '-')
        || identical(opString, '+'))) {
      Token beginToken = node.argumentsNode.getBeginToken();
      if (beginToken != null && identical(beginToken.stringValue, opString)) {
        sb.write(' ');
      }
    }
    visit(node.argumentsNode);
  }

  visitSendSet(SendSet node) {
    if (node.isPrefix) {
      sb.write(' ');
      visit(node.assignmentOperator);
    }
    unparseSendReceiver(node);
    if (node.isIndex) {
      sb.write('[');
      visit(node.arguments.head);
      sb.write(']');
      if (!node.isPrefix) visit(node.assignmentOperator);
      unparseNodeListFrom(node.argumentsNode, node.argumentsNode.nodes.tail);
    } else {
      visit(node.selector);
      if (!node.isPrefix) {
        visit(node.assignmentOperator);
        if (node.assignmentOperator.source != '=') sb.write(' ');
      }
      visit(node.argumentsNode);
    }
  }

  visitThrow(Throw node) {
    add(node.throwToken.value);
    sb.write(' ');
    visit(node.expression);
  }

  visitTypeAnnotation(TypeAnnotation node) {
    visit(node.typeName);
    visit(node.typeArguments);
  }

  visitTypeVariable(TypeVariable node) {
    visit(node.name);
    if (node.bound != null) {
      sb.write(' extends ');
      visit(node.bound);
    }
  }

  visitVariableDefinitions(VariableDefinitions node) {
    if (node.metadata != null) {
      visit(node.metadata);
      sb.write(' ');
    }
    visit(node.modifiers);
    if (!node.modifiers.nodes.isEmpty) {
      sb.write(' ');
    }
    if (node.type != null) {
      visit(node.type);
      sb.write(' ');
    }
    visit(node.definitions);
  }

  visitDoWhile(DoWhile node) {
    add(node.doKeyword.value);
    if (node.body is !Block) sb.write(' ');
    visit(node.body);
    add(node.whileKeyword.value);
    visit(node.condition);
    sb.write(node.endToken.value);
  }

  visitWhile(While node) {
    addToken(node.whileKeyword);
    visit(node.condition);
    visit(node.body);
  }

  visitParenthesizedExpression(ParenthesizedExpression node) {
    add(node.getBeginToken().value);
    visit(node.expression);
    add(node.getEndToken().value);
  }

  visitStringInterpolation(StringInterpolation node) {
    visit(node.string);
    visit(node.parts);
  }

  visitStringInterpolationPart(StringInterpolationPart node) {
    sb.write('\${'); // TODO(ahe): Preserve the real tokens.
    visit(node.expression);
    sb.write('}');
    visit(node.string);
  }

  visitEmptyStatement(EmptyStatement node) {
    add(node.semicolonToken.value);
  }

  visitGotoStatement(GotoStatement node) {
    add(node.keywordToken.value);
    if (node.target != null) {
      sb.write(' ');
      visit(node.target);
    }
    add(node.semicolonToken.value);
  }

  visitBreakStatement(BreakStatement node) {
    visitGotoStatement(node);
  }

  visitContinueStatement(ContinueStatement node) {
    visitGotoStatement(node);
  }

  visitForIn(ForIn node) {
    add(node.forToken.value);
    sb.write('(');
    visit(node.declaredIdentifier);
    sb.write(' ');
    addToken(node.inToken);
    visit(node.expression);
    sb.write(')');
    visit(node.body);
  }

  visitLabel(Label node) {
    visit(node.identifier);
    add(node.colonToken.value);
   }

  visitLabeledStatement(LabeledStatement node) {
    visit(node.labels);
    visit(node.statement);
  }

  visitLiteralMap(LiteralMap node) {
    if (node.constKeyword != null) add(node.constKeyword.value);
    if (node.typeArguments != null) visit(node.typeArguments);
    visit(node.entries);
  }

  visitLiteralMapEntry(LiteralMapEntry node) {
    visit(node.key);
    add(node.colonToken.value);
    visit(node.value);
  }

  visitNamedArgument(NamedArgument node) {
    visit(node.name);
    add(node.colonToken.value);
    visit(node.expression);
  }

  visitSwitchStatement(SwitchStatement node) {
    addToken(node.switchKeyword);
    visit(node.parenthesizedExpression);
    visit(node.cases);
  }

  visitSwitchCase(SwitchCase node) {
    visit(node.labelsAndCases);
    if (node.isDefaultCase) {
      sb.write('default:');
    }
    visit(node.statements);
  }

  unparseImportTag(String uri, [String prefix]) {
    final suffix = prefix == null ? '' : ' as $prefix';
    sb.write('import "$uri"$suffix;');
  }

  visitTryStatement(TryStatement node) {
    addToken(node.tryKeyword);
    visit(node.tryBlock);
    visit(node.catchBlocks);
    if (node.finallyKeyword != null) {
      addToken(node.finallyKeyword);
      visit(node.finallyBlock);
    }
  }

  visitCaseMatch(CaseMatch node) {
    add(node.caseKeyword.value);
    sb.write(" ");
    visit(node.expression);
    add(node.colonToken.value);
  }

  visitCatchBlock(CatchBlock node) {
    addToken(node.onKeyword);
    if (node.type != null) {
      visit(node.type);
      sb.write(' ');
    }
    addToken(node.catchKeyword);
    visit(node.formals);
    visit(node.block);
  }

  visitTypedef(Typedef node) {
    addToken(node.typedefKeyword);
    if (node.returnType != null) {
      visit(node.returnType);
      sb.write(' ');
    }
    visit(node.name);
    if (node.typeParameters != null) {
      visit(node.typeParameters);
    }
    visit(node.formals);
    add(node.endToken.value);
  }

  visitLibraryName(LibraryName node) {
    addToken(node.libraryKeyword);
    node.visitChildren(this);
    add(node.getEndToken().value);
  }

  visitImport(Import node) {
    addToken(node.importKeyword);
    visit(node.uri);
    if (node.isDeferred) {
      sb.write(' deferred');
    }
    if (node.prefix != null) {
      sb.write(' as ');
      visit(node.prefix);
    }
    if (node.combinators != null) {
      sb.write(' ');
      visit(node.combinators);
    }
    add(node.getEndToken().value);
  }

  visitExport(Export node) {
    addToken(node.exportKeyword);
    visit(node.uri);
    if (node.combinators != null) {
      sb.write(' ');
      visit(node.combinators);
    }
    add(node.getEndToken().value);
  }

  visitPart(Part node) {
    addToken(node.partKeyword);
    visit(node.uri);
    add(node.getEndToken().value);
  }

  visitPartOf(PartOf node) {
    addToken(node.partKeyword);
    addToken(node.ofKeyword);
    visit(node.name);
    add(node.getEndToken().value);
  }

  visitCombinator(Combinator node) {
    addToken(node.keywordToken);
    visit(node.identifiers);
  }

  visitMetadata(Metadata node) {
    addToken(node.token);
    visit(node.expression);
  }

  visitNode(Node node) {
    throw 'internal error'; // Should not be called.
  }

  visitExpression(Expression node) {
    throw 'internal error'; // Should not be called.
  }

  visitLibraryTag(LibraryTag node) {
    throw 'internal error'; // Should not be called.
  }

  visitLibraryDependency(Node node) {
    throw 'internal error'; // Should not be called.
  }

  visitLiteral(Literal node) {
    throw 'internal error'; // Should not be called.
  }

  visitLoop(Loop node) {
    throw 'internal error'; // Should not be called.
  }

  visitPostfix(Postfix node) {
    throw 'internal error'; // Should not be called.
  }

  visitPrefix(Prefix node) {
    throw 'internal error'; // Should not be called.
  }

  visitStatement(Statement node) {
    throw 'internal error'; // Should not be called.
  }

  visitStringNode(StringNode node) {
    throw 'internal error'; // Should not be called.
  }
}
