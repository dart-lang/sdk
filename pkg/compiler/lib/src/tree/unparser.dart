// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/scanner.dart' show Token;
import 'package:front_end/src/fasta/scanner/token_constants.dart' as Tokens
    show IDENTIFIER_TOKEN, KEYWORD_TOKEN, PLUS_TOKEN;
import '../util/util.dart';
import 'nodes.dart';

String unparse(Node node, {minify: true}) {
  Unparser unparser = new Unparser(minify: minify);
  unparser.unparse(node);
  return unparser.result;
}

class Unparser extends Indentation implements Visitor {
  final StringBuffer sb = new StringBuffer();

  String get result => sb.toString();

  Unparser({this.minify: true, this.stripTypes: false});

  bool minify;
  bool stripTypes;

  void newline() {
    if (!minify) {
      sb.write("\n");
      onEmptyLine = true;
    }
  }

  void space([String token = " "]) {
    write(minify ? "" : token);
  }

  void addToken(Token token) {
    if (token == null) return;
    write(token.lexeme);
    if (identical(token.kind, Tokens.KEYWORD_TOKEN) ||
        identical(token.kind, Tokens.IDENTIFIER_TOKEN)) {
      write(' ');
    }
  }

  bool onEmptyLine = true;

  write(object) {
    String s = object.toString();
    if (s == '') return;
    if (onEmptyLine) {
      sb.write(indentation);
    }
    sb.write(s);
    onEmptyLine = false;
  }

  unparse(Node node) {
    visit(node);
  }

  visit(Node node) {
    if (node != null) node.accept(this);
  }

  visitAssert(Assert node) {
    write(node.assertToken.lexeme);
    write('(');
    visit(node.condition);
    if (node.hasMessage) {
      write(',');
      space();
      visit(node.message);
    }
    write(');');
  }

  visitBlock(Block node) => unparseBlockStatements(node.statements);

  unparseBlockStatements(NodeList statements) {
    addToken(statements.beginToken);

    Link<Node> nodes = statements.nodes;
    if (nodes != null && !nodes.isEmpty) {
      indentMore();
      newline();
      visit(nodes.head);
      for (Link link = nodes.tail; !link.isEmpty; link = link.tail) {
        newline();
        visit(link.head);
      }
      indentLess();
      newline();
    }
    if (statements.endToken != null) {
      write(statements.endToken.lexeme);
    }
  }

  visitCascade(Cascade node) {
    visit(node.expression);
  }

  visitCascadeReceiver(CascadeReceiver node) {
    visit(node.expression);
  }

  unparseClassWithBody(ClassNode node, members) {
    if (!node.modifiers.nodes.isEmpty) {
      visit(node.modifiers);
      write(' ');
    }
    write('class ');
    visit(node.name);
    if (node.typeParameters != null) {
      visit(node.typeParameters);
    }
    if (node.extendsKeyword != null) {
      write(' ');
      addToken(node.extendsKeyword);
      visit(node.superclass);
    }
    if (!node.interfaces.isEmpty) {
      write(' ');
      visit(node.interfaces);
    }
    space();
    write('{');
    if (!members.isEmpty) {
      newline();
      indentMore();
      for (Node member in members) {
        visit(member);
        newline();
      }
      indentLess();
    }
    write('}');
  }

  visitEnum(Enum node) {
    sb.write('enum ');
    visit(node.name);
    sb.write(' ');
    visit(node.names);
  }

  visitClassNode(ClassNode node) {
    unparseClassWithBody(node, node.body.nodes);
  }

  visitMixinApplication(MixinApplication node) {
    visit(node.superclass);
    write(' with ');
    visit(node.mixins);
  }

  visitNamedMixinApplication(NamedMixinApplication node) {
    if (!node.modifiers.nodes.isEmpty) {
      visit(node.modifiers);
      write(' ');
    }
    write('class ');
    visit(node.name);
    if (node.typeParameters != null) {
      visit(node.typeParameters);
    }
    write(' = ');
    visit(node.mixinApplication);
    if (node.interfaces != null) {
      write(' implements ');
      visit(node.interfaces);
    }
    write(';');
  }

  visitConditional(Conditional node) {
    visit(node.condition);
    space();
    write(node.questionToken.lexeme);
    space();
    visit(node.thenExpression);
    space();
    write(node.colonToken.lexeme);
    space();
    visit(node.elseExpression);
  }

  visitExpressionStatement(ExpressionStatement node) {
    visit(node.expression);
    write(node.endToken.lexeme);
  }

  visitFor(For node) {
    write(node.forToken.lexeme);
    space();
    write('(');
    visit(node.initializer);
    write(';');
    if (node.conditionStatement is! EmptyStatement) space();
    visit(node.conditionStatement);
    if (!node.update.nodes.isEmpty) space();
    visit(node.update);
    write(')');
    space();
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
      assert(send is! SendSet);
      if (!send.isOperator) {
        // Looks like a factory method.
        visit(send.receiver);
        write('.');
      } else {
        visit(send.receiver);
        Identifier identifier = send.selector.asIdentifier();
        if (identical(identifier.token.kind, Tokens.KEYWORD_TOKEN)) {
          write(' ');
        } else if (identifier.source == 'negate') {
          // TODO(ahe): Remove special case for negate.
          write(' ');
        }
      }
      visit(send.selector);
    } else {
      visit(name);
    }
  }

  visitAsyncModifier(AsyncModifier node) {
    write(node.asyncToken.lexeme);
    if (node.starToken != null) {
      write(node.starToken.lexeme);
    }
  }

  visitFunctionExpression(FunctionExpression node) {
    if (!node.modifiers.nodes.isEmpty) {
      visit(node.modifiers);
      write(' ');
    }
    if (node.returnType != null && !stripTypes) {
      visit(node.returnType);
      write(' ');
    }
    if (node.getOrSet != null) {
      write(node.getOrSet.lexeme);
      write(' ');
    }
    unparseFunctionName(node.name);
    visit(node.typeVariables);
    visit(node.parameters);
    if (node.initializers != null) {
      space();
      write(':');
      space();
      unparseNodeListFrom(node.initializers, node.initializers.nodes,
          spaces: true);
    }
    if (node.asyncModifier != null) {
      if (node.getOrSet != null) {
        write(' ');
      } else {
        // Space is optional if this is not a getter.
        space();
      }
      visit(node.asyncModifier);
    }
    if (node.body != null && node.body is! EmptyStatement) {
      space();
    }
    visit(node.body);
  }

  visitIdentifier(Identifier node) {
    write(node.token.lexeme);
  }

  visitIf(If node) {
    write(node.ifToken.lexeme);
    space();
    visit(node.condition);
    space();
    visit(node.thenPart);
    if (node.hasElsePart) {
      space();
      write(node.elseToken.lexeme);
      space();
      if (node.elsePart is! Block && minify) write(' ');
      visit(node.elsePart);
    }
  }

  visitLiteralBool(LiteralBool node) {
    write(node.token.lexeme);
  }

  visitLiteralDouble(LiteralDouble node) {
    write(node.token.lexeme);
    // -Lit is represented as a send.
    if (node.token.kind == Tokens.PLUS_TOKEN) write(node.token.next.lexeme);
  }

  visitLiteralInt(LiteralInt node) {
    write(node.token.lexeme);
    // -Lit is represented as a send.
    if (node.token.kind == Tokens.PLUS_TOKEN) write(node.token.next.lexeme);
  }

  visitLiteralString(LiteralString node) {
    write(node.token.lexeme);
  }

  visitStringJuxtaposition(StringJuxtaposition node) {
    visit(node.first);
    write(" ");
    visit(node.second);
  }

  visitLiteralNull(LiteralNull node) {
    write(node.token.lexeme);
  }

  visitLiteralSymbol(LiteralSymbol node) {
    write(node.hashToken.lexeme);
    unparseNodeListOfIdentifiers(node.identifiers);
  }

  unparseNodeListOfIdentifiers(NodeList node) {
    // Manually print the list to avoid spaces around operators in unminified
    // code.
    Link<Node> l = node.nodes;
    write(l.head.asIdentifier().token.lexeme);
    for (l = l.tail; !l.isEmpty; l = l.tail) {
      write(".");
      write(l.head.asIdentifier().token.lexeme);
    }
  }

  visitNewExpression(NewExpression node) {
    addToken(node.newToken);
    visit(node.send);
  }

  visitLiteralList(LiteralList node) {
    if (node.constKeyword != null) write(node.constKeyword.lexeme);
    visit(node.typeArguments);
    visit(node.elements);
    // If list is empty, emit space after [] to disambiguate cases like []==[].
    if (minify && node.elements.isEmpty) write(' ');
  }

  visitModifiers(Modifiers node) {
    // Spaces are already included as delimiter.
    unparseNodeList(node.nodes, spaces: false);
  }

  /**
   * Unparses given NodeList starting from specific node.
   */
  unparseNodeListFrom(NodeList node, Link<Node> from, {bool spaces: true}) {
    if (from.isEmpty) return;
    String delimiter = (node.delimiter == null) ? "" : "${node.delimiter}";
    visit(from.head);
    for (Link link = from.tail; !link.isEmpty; link = link.tail) {
      write(delimiter);
      if (spaces) space();
      visit(link.head);
    }
  }

  unparseNodeList(NodeList node, {bool spaces: true}) {
    addToken(node.beginToken);
    if (node.nodes != null) {
      unparseNodeListFrom(node, node.nodes, spaces: spaces);
    }
    // If the NodeList is a single "[]" token
    // then beginToken == endToken and only write beginToken.
    if (node.endToken != null && node.endToken != node.beginToken) {
      write(node.endToken.lexeme);
    }
  }

  visitNodeList(NodeList node) {
    unparseNodeList(node);
  }

  visitOperator(Operator node) {
    visitIdentifier(node);
  }

  visitRedirectingFactoryBody(RedirectingFactoryBody node) {
    space();
    write(node.beginToken.lexeme);
    space();
    visit(node.constructorReference);
    write(node.endToken.lexeme);
  }

  visitRethrow(Rethrow node) {
    write('rethrow;');
  }

  visitReturn(Return node) {
    write(node.beginToken.lexeme);
    if (node.hasExpression && node.beginToken.stringValue != '=>') {
      write(' ');
    }
    if (node.beginToken.stringValue == '=>') space();
    visit(node.expression);
    if (node.endToken != null) write(node.endToken.lexeme);
  }

  visitYield(Yield node) {
    write(node.yieldToken.lexeme);
    if (node.starToken != null) {
      write(node.starToken.lexeme);
    }
    write(' ');
    visit(node.expression);
    write(node.endToken.lexeme);
  }

  unparseSendReceiver(Send node, {bool spacesNeeded: false}) {
    if (node.receiver == null) return;
    visit(node.receiver);
    CascadeReceiver asCascadeReceiver = node.receiver.asCascadeReceiver();
    if (asCascadeReceiver != null) {
      newline();
      indentMore();
      indentMore();
      write(asCascadeReceiver.cascadeOperator.lexeme);
      indentLess();
      indentLess();
    } else if (node.selector.asOperator() == null) {
      write(node.isConditional ? '?.' : '.');
    } else if (spacesNeeded) {
      write(' ');
    }
  }

  unparseSendArgument(Send node, {bool spacesNeeded: false}) {
    if (node.argumentsNode == null) return;

    if (node.isIsNotCheck) {
      Send argNode = node.arguments.head;
      visit(argNode.selector);
      space();
      visit(argNode.receiver);
    } else {
      if (spacesNeeded) write(' ');
      visit(node.typeArgumentsNode);
      visit(node.argumentsNode);
    }
  }

  visitSend(Send node) {
    Operator op = node.selector.asOperator();
    String opString = op != null ? op.source : null;
    bool spacesNeeded = minify
        ? identical(opString, 'is') || identical(opString, 'as')
        : (opString != null && !node.isPrefix && !node.isIndex);

    void minusMinusSpace(Node other) {
      if (other != null && opString == '-') {
        Token beginToken = other.getBeginToken();
        if (beginToken != null &&
            beginToken.stringValue != null &&
            beginToken.stringValue.startsWith('-')) {
          sb.write(' ');
          spacesNeeded = false;
        }
      }
    }

    if (node.isPrefix) {
      visit(node.selector);
      // Add a space for sequences like - -x (double unary minus).
      minusMinusSpace(node.receiver);
    }

    unparseSendReceiver(node, spacesNeeded: spacesNeeded);
    if (!node.isPrefix && !node.isIndex) {
      visit(node.selector);
    }
    minusMinusSpace(node.argumentsNode);

    unparseSendArgument(node, spacesNeeded: spacesNeeded);
  }

  visitSendSet(SendSet node) {
    if (node.isPrefix) {
      if (minify) {
        write(' ');
      }
      visit(node.assignmentOperator);
    }
    unparseSendReceiver(node);
    if (node.isIndex) {
      write('[');
      visit(node.arguments.head);
      write(']');
      if (!node.isPrefix) {
        if (!node.isPostfix) {
          space();
        }
        visit(node.assignmentOperator);
        if (!node.isPostfix) {
          space();
        }
      }
      unparseNodeListFrom(node.argumentsNode, node.argumentsNode.nodes.tail);
    } else {
      visit(node.selector);
      if (!node.isPrefix) {
        if (!node.isPostfix && node.assignmentOperator.source != ':') {
          space();
        }
        visit(node.assignmentOperator);
        if (!node.isPostfix) {
          space();
        }
        if (minify && node.assignmentOperator.source != '=') {
          write(' ');
        }
      }
      visit(node.argumentsNode);
    }
  }

  visitThrow(Throw node) {
    write(node.throwToken.lexeme);
    write(' ');
    visit(node.expression);
  }

  visitAwait(Await node) {
    write(node.awaitToken.lexeme);
    write(' ');
    visit(node.expression);
  }

  visitNominalTypeAnnotation(NominalTypeAnnotation node) {
    visit(node.typeName);
    visit(node.typeArguments);
  }

  visitFunctionTypeAnnotation(FunctionTypeAnnotation node) {
    visit(node.returnType);
    write(' Function');
    visit(node.typeParameters);
    visit(node.formals);
  }

  visitTypeVariable(TypeVariable node) {
    visit(node.name);
    if (node.bound != null) {
      write(' extends ');
      visit(node.bound);
    }
  }

  visitVariableDefinitions(VariableDefinitions node) {
    if (node.metadata != null) {
      visit(node.metadata);
      write(' ');
    }
    visit(node.modifiers);
    if (!node.modifiers.nodes.isEmpty) {
      write(' ');
    }
    // TODO(sigurdm): Avoid writing the space when [stripTypes], but still write
    // it if the 'type; is var.
    if (node.type != null) {
      visit(node.type);
      write(' ');
    }
    visit(node.definitions);
  }

  visitDoWhile(DoWhile node) {
    write(node.doKeyword.lexeme);
    if (node.body is! Block) {
      write(' ');
    } else {
      space();
    }
    visit(node.body);
    space();
    write(node.whileKeyword.lexeme);
    space();
    visit(node.condition);
    write(node.endToken.lexeme);
  }

  visitWhile(While node) {
    write(node.whileKeyword.lexeme);
    space();
    visit(node.condition);
    space();
    visit(node.body);
  }

  visitParenthesizedExpression(ParenthesizedExpression node) {
    write(node.getBeginToken().lexeme);
    visit(node.expression);
    write(node.getEndToken().lexeme);
  }

  visitStringInterpolation(StringInterpolation node) {
    visit(node.string);
    unparseNodeList(node.parts, spaces: false);
  }

  visitStringInterpolationPart(StringInterpolationPart node) {
    write('\${'); // TODO(ahe): Preserve the real tokens.
    visit(node.expression);
    write('}');
    visit(node.string);
  }

  visitEmptyStatement(EmptyStatement node) {
    write(node.semicolonToken.lexeme);
  }

  visitGotoStatement(GotoStatement node) {
    write(node.keywordToken.lexeme);
    if (node.target != null) {
      write(' ');
      visit(node.target);
    }
    write(node.semicolonToken.lexeme);
  }

  visitBreakStatement(BreakStatement node) {
    visitGotoStatement(node);
  }

  visitContinueStatement(ContinueStatement node) {
    visitGotoStatement(node);
  }

  visitForIn(ForIn node) {
    write(node.forToken.lexeme);
    space();
    write('(');
    visit(node.declaredIdentifier);
    write(' ');
    addToken(node.inToken);
    visit(node.expression);
    write(')');
    space();
    visit(node.body);
  }

  visitAsyncForIn(AsyncForIn node) {
    write(node.awaitToken.lexeme);
    write(' ');
    visitForIn(node);
  }

  visitSyncForIn(SyncForIn node) {
    visitForIn(node);
  }

  visitLabel(Label node) {
    visit(node.identifier);
    write(node.colonToken.lexeme);
  }

  visitLabeledStatement(LabeledStatement node) {
    visit(node.labels);
    visit(node.statement);
  }

  visitLiteralMap(LiteralMap node) {
    if (node.constKeyword != null) write(node.constKeyword.lexeme);
    if (node.typeArguments != null) visit(node.typeArguments);
    visit(node.entries);
  }

  visitLiteralMapEntry(LiteralMapEntry node) {
    visit(node.key);
    write(node.colonToken.lexeme);
    space();
    visit(node.value);
  }

  visitNamedArgument(NamedArgument node) {
    visit(node.name);
    write(node.colonToken.lexeme);
    space();
    visit(node.expression);
  }

  visitSwitchStatement(SwitchStatement node) {
    addToken(node.switchKeyword);
    visit(node.parenthesizedExpression);
    space();
    unparseNodeList(node.cases, spaces: false);
  }

  visitSwitchCase(SwitchCase node) {
    newline();
    indentMore();
    visit(node.labelsAndCases);
    if (node.isDefaultCase) {
      write('default:');
    }
    unparseBlockStatements(node.statements);
    indentLess();
  }

  unparseLibraryName(String libraryName) {
    write('library $libraryName;');
    newline();
  }

  unparseImportTag(String uri,
      {String prefix,
      List<String> shows: const <String>[],
      bool isDeferred: false}) {
    String deferredString = isDeferred ? ' deferred' : '';
    String prefixString = prefix == null ? '' : ' as $prefix';
    String showString = shows.isEmpty ? '' : ' show ${shows.join(", ")}';
    write('import "$uri"$deferredString$prefixString$showString;');
    newline();
  }

  unparseExportTag(String uri, {List<String> shows: const []}) {
    String suffix = shows.isEmpty ? '' : ' show ${shows.join(", ")}';
    write('export "$uri"$suffix;');
    newline();
  }

  visitTryStatement(TryStatement node) {
    addToken(node.tryKeyword);
    visit(node.tryBlock);
    visit(node.catchBlocks);
    if (node.finallyKeyword != null) {
      space();
      addToken(node.finallyKeyword);
      visit(node.finallyBlock);
    }
  }

  visitCaseMatch(CaseMatch node) {
    addToken(node.caseKeyword);
    visit(node.expression);
    write(node.colonToken.lexeme);
  }

  visitCatchBlock(CatchBlock node) {
    addToken(node.onKeyword);
    if (node.type != null) {
      visit(node.type);
      write(' ');
    }
    space();
    addToken(node.catchKeyword);
    visit(node.formals);
    space();
    visit(node.block);
  }

  visitTypedef(Typedef node) {
    addToken(node.typedefKeyword);
    if (node.returnType != null) {
      visit(node.returnType);
      write(' ');
    }
    visit(node.name);
    if (node.templateParameters != null) {
      visit(node.templateParameters);
    }
    visit(node.formals);
    write(node.endToken.lexeme);
  }

  visitLibraryName(LibraryName node) {
    addToken(node.libraryKeyword);
    node.visitChildren(this);
    write(node.getEndToken().lexeme);
    newline();
  }

  visitConditionalUri(ConditionalUri node) {
    write(node.ifToken.lexeme);
    space();
    write('(');
    visit(node.key);
    if (node.value != null) {
      space();
      write("==");
      space();
      visit(node.value);
    }
    write(")");
    space();
    visit(node.uri);
  }

  visitDottedName(DottedName node) {
    unparseNodeListOfIdentifiers(node.identifiers);
  }

  visitImport(Import node) {
    addToken(node.importKeyword);
    visit(node.uri);
    if (node.hasConditionalUris) {
      write(' ');
      visitNodeList(node.conditionalUris);
    }
    if (node.isDeferred) {
      write(' deferred');
    }
    if (node.prefix != null) {
      write(' as ');
      visit(node.prefix);
    }
    if (node.combinators != null) {
      write(' ');
      visit(node.combinators);
    }
    write(node.getEndToken().lexeme);
    newline();
  }

  visitExport(Export node) {
    addToken(node.exportKeyword);
    visit(node.uri);
    if (node.hasConditionalUris) {
      write(' ');
      visitNodeList(node.conditionalUris);
    }
    if (node.combinators != null) {
      write(' ');
      visit(node.combinators);
    }
    write(node.getEndToken().lexeme);
    newline();
  }

  visitPart(Part node) {
    addToken(node.partKeyword);
    visit(node.uri);
    write(node.getEndToken().lexeme);
  }

  visitPartOf(PartOf node) {
    addToken(node.partKeyword);
    addToken(node.ofKeyword);
    visit(node.name);
    write(node.getEndToken().lexeme);
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

  visitTypeAnnotation(TypeAnnotation node) {
    throw 'internal error'; // Should not be called.
  }
}
