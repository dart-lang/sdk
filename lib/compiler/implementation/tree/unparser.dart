// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String unparse(Node node) {
  Unparser unparser = new Unparser();
  unparser.unparse(node);
  return unparser.result;
}

class Unparser implements Visitor {
  final StringBuffer sb;

  String get result => sb.toString();

  Unparser() : sb = new StringBuffer();

  void add(SourceString string) {
    string.printOn(sb);
  }

  void addToken(Token token) {
    if (token === null) return;
    add(token.value);
    if (token.kind === KEYWORD_TOKEN || token.kind === IDENTIFIER_TOKEN) {
      sb.add(' ');
    }
  }

  unparse(Node node) { visit(node); }

  visit(Node node) {
    if (node !== null) node.accept(this);
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

  unparseClassWithBody(ClassNode node, Iterable<Node> members) {
    addToken(node.beginToken);
    if (node.beginToken.stringValue == 'abstract') {
      addToken(node.beginToken.next);
    }
    visit(node.name);
    if (node.typeParameters !== null) {
      visit(node.typeParameters);
    }
    if (node.extendsKeyword !== null) {
      sb.add(' ');
      addToken(node.extendsKeyword);
      visit(node.superclass);
    }
    if (!node.interfaces.isEmpty()) {
      sb.add(' ');
      visit(node.interfaces);
    }
    if (node.defaultClause !== null) {
      sb.add(' default ');
      visit(node.defaultClause);
    }
    sb.add('{');
    for (final member in members) {
      visit(member);
    }
    sb.add('}');
  }

  visitClassNode(ClassNode node) {
    unparseClassWithBody(node, node.body.nodes);
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
    sb.add('(');
    visit(node.initializer);
    if (node.initializer is !Statement) sb.add(';');
    visit(node.conditionStatement);
    visit(node.update);
    sb.add(')');
    visit(node.body);
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    visit(node.function);
  }

  visitFunctionExpression(FunctionExpression node) {
    // Check length to not print unnecessary whitespace.
    if (node.modifiers.nodes.length() > 0) {
      visit(node.modifiers);
      sb.add(' ');
    }
    if (node.returnType !== null) {
      visit(node.returnType);
      sb.add(' ');
    }
    if (node.getOrSet !== null) {
      add(node.getOrSet.value);
      sb.add(' ');
    }
    // TODO(antonm): that's a workaround as currently FunctionExpression
    // names are modelled with Send and it emits operator[] as only
    // operator, without [] which are expected to be emitted with
    // arguments.
    if (node.name is Send) {
      Send send = node.name;
      assert(send is !SendSet);
      if (!send.isOperator) {
        // Looks like a factory method.
        visit(send.receiver);
        sb.add('.');
      } else {
        visit(send.receiver);
        Identifier identifier = send.selector.asIdentifier();
        if (identifier.token.kind === KEYWORD_TOKEN) {
          sb.add(' ');
        } else if (identifier.source == const SourceString('negate')) {
          // TODO(ahe): Remove special case for negate.
          sb.add(' ');
        }
      }
      visit(send.selector);
    } else {
      visit(node.name);
    }
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
      if (node.elsePart is !Block) sb.add(' ');
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
    sb.add(" ");
    visit(node.second);
  }

  visitLiteralNull(LiteralNull node) {
    add(node.token.value);
  }

  visitNewExpression(NewExpression node) {
    addToken(node.newToken);
    visit(node.send);
  }

  visitLiteralList(LiteralList node) {
    if (node.constKeyword !== null) add(node.constKeyword.value);
    visit(node.typeArguments);
    visit(node.elements);
    // If list is empty, emit space after [] to disambiguate cases like []==[].
    if (node.elements.isEmpty()) sb.add(' ');
  }

  visitModifiers(Modifiers node) => node.visitChildren(this);

  /**
   * Unparses given NodeList starting from specific node.
   */
  unparseNodeListFrom(NodeList node, Link<Node> from) {
    if (from.isEmpty()) return;
    String delimiter = (node.delimiter === null) ? "" : "${node.delimiter}";
    visit(from.head);
    for (Link link = from.tail; !link.isEmpty(); link = link.tail) {
      sb.add(delimiter);
      visit(link.head);
    }
  }

  visitNodeList(NodeList node) {
    addToken(node.beginToken);
    if (node.nodes !== null) {
      unparseNodeListFrom(node, node.nodes);
    }
    if (node.endToken !== null) add(node.endToken.value);
  }

  visitOperator(Operator node) {
    visitIdentifier(node);
  }

  visitReturn(Return node) {
    add(node.beginToken.value);
    if (node.hasExpression && node.beginToken.stringValue != '=>') {
      sb.add(' ');
    }
    visit(node.expression);
    if (node.endToken !== null) add(node.endToken.value);
  }

  unparseSendReceiver(Send node, [bool spacesNeeded=false]) {
    if (node.receiver === null) return;
    visit(node.receiver);
    CascadeReceiver asCascadeReceiver = node.receiver.asCascadeReceiver();
    if (asCascadeReceiver !== null) {
      add(asCascadeReceiver.cascadeOperator.value);
    } else if (node.selector.asOperator() === null) {
      sb.add('.');
    } else if (spacesNeeded) {
      sb.add(' ');
    }
  }

  visitSend(Send node) {
    Operator op = node.selector.asOperator();
    String opString = op !== null ? op.source.stringValue : null;
    bool spacesNeeded = opString === 'is' || opString === 'as';

    if (node.isPrefix) visit(node.selector);
    unparseSendReceiver(node, spacesNeeded: spacesNeeded);
    if (!node.isPrefix && !node.isIndex) visit(node.selector);
    if (spacesNeeded) sb.add(' ');
    // Also add a space for sequences like x + +1 and y - -y.
    if (opString === '-' || opString === '+') {
      Token beginToken = node.argumentsNode.getBeginToken();
      if (beginToken !== null && beginToken.stringValue === opString) {
        sb.add(' ');
      }
    }
    visit(node.argumentsNode);
  }

  visitSendSet(SendSet node) {
    if (node.isPrefix) {
      sb.add(' ');
      visit(node.assignmentOperator);
    }
    unparseSendReceiver(node);
    if (node.isIndex) {
      sb.add('[');
      visit(node.arguments.head);
      sb.add(']');
      if (!node.isPrefix) visit(node.assignmentOperator);
      unparseNodeListFrom(node.argumentsNode, node.argumentsNode.nodes.tail);
    } else {
      visit(node.selector);
      if (!node.isPrefix) {
        visit(node.assignmentOperator);
        if (node.assignmentOperator.source.slowToString() != '=') sb.add(' ');
      }
      visit(node.argumentsNode);
    }
  }

  visitThrow(Throw node) {
    add(node.throwToken.value);
    if (node.expression !== null) {
      sb.add(' ');
      visit(node.expression);
    }
    node.endToken.value.printOn(sb);
  }

  visitTypeAnnotation(TypeAnnotation node) {
    visit(node.typeName);
    visit(node.typeArguments);
  }

  visitTypeVariable(TypeVariable node) {
    visit(node.name);
    if (node.bound !== null) {
      sb.add(' extends ');
      visit(node.bound);
    }
  }

  visitVariableDefinitions(VariableDefinitions node) {
    visit(node.modifiers);
    if (node.modifiers.nodes.length() > 0) {
      sb.add(' ');
    }
    if (node.type !== null) {
      visit(node.type);
      sb.add(' ');
    }
    visit(node.definitions);
    if (node.endToken.value == const SourceString(';')) {
      add(node.endToken.value);
    }
  }

  visitDoWhile(DoWhile node) {
    add(node.doKeyword.value);
    if (node.body is !Block) sb.add(' ');
    visit(node.body);
    add(node.whileKeyword.value);
    visit(node.condition);
    sb.add(node.endToken.value);
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
    sb.add('\${'); // TODO(ahe): Preserve the real tokens.
    visit(node.expression);
    sb.add('}');
    visit(node.string);
  }

  visitEmptyStatement(EmptyStatement node) {
    add(node.semicolonToken.value);
  }

  visitGotoStatement(GotoStatement node) {
    add(node.keywordToken.value);
    if (node.target !== null) {
      sb.add(' ');
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
    sb.add('(');
    visit(node.declaredIdentifier);
    sb.add(' ');
    addToken(node.inToken);
    visit(node.expression);
    sb.add(')');
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
    if (node.constKeyword !== null) add(node.constKeyword.value);
    if (node.typeArguments !== null) visit(node.typeArguments);
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
      sb.add('default:');
    }
    visit(node.statements);
  }

  unparseImportTag(String uri, [String prefix]) {
    final suffix = prefix === null ? '' : ',prefix:"$prefix"';
    sb.add('#import("$uri"$suffix);');
  }

  visitScriptTag(ScriptTag node) {
    add(node.beginToken.value);
    visit(node.tag);
    sb.add('(');
    visit(node.argument);
    if (node.prefixIdentifier !== null) {
      visit(node.prefixIdentifier);
      sb.add(':');
      visit(node.prefix);
    }
    sb.add(')');
    add(node.endToken.value);
  }

  visitTryStatement(TryStatement node) {
    addToken(node.tryKeyword);
    visit(node.tryBlock);
    visit(node.catchBlocks);
    if (node.finallyKeyword !== null) {
      addToken(node.finallyKeyword);
      visit(node.finallyBlock);
    }
  }

  visitCaseMatch(CaseMatch node) {
    add(node.caseKeyword.value);
    sb.add(" ");
    visit(node.expression);
    add(node.colonToken.value);
  }

  visitCatchBlock(CatchBlock node) {
    addToken(node.onKeyword);
    if (node.type !== null) {
      visit(node.type);
      sb.add(' ');
    }
    addToken(node.catchKeyword);
    visit(node.formals);
    visit(node.block);
  }

  visitTypedef(Typedef node) {
    addToken(node.typedefKeyword);
    if (node.returnType !== null) {
      visit(node.returnType);
      sb.add(' ');
    }
    visit(node.name);
    if (node.typeParameters !== null) {
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
    if (node.prefix != null) {
      sb.add(' ');
      addToken(node.asKeyword);
      visit(node.prefix);
    }
    if (node.combinators != null) {
      visit(node.combinators);
    }
    add(node.getEndToken().value);
  }

  visitExport(Export node) {
    addToken(node.exportKeyword);
    visit(node.uri);
    if (node.combinators != null) {
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
}
