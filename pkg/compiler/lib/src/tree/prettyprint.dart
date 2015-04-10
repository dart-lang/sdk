// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of tree;

/**
 * Pretty-prints Node tree in XML-like format.
 *
 * TODO(smok): Add main() to run from command-line to print out tree for given
 * .dart file.
 */
class PrettyPrinter extends Indentation implements Visitor {

  StringBuffer sb;
  Link<String> tagStack;

  PrettyPrinter() :
      sb = new StringBuffer(),
      tagStack = const Link<String>();

  void pushTag(String tag) {
    tagStack = tagStack.prepend(tag);
    indentMore();
  }

  String popTag() {
    assert(!tagStack.isEmpty);
    String tag = tagStack.head;
    tagStack = tagStack.tail;
    indentLess();
    return tag;
  }

  /**
   * Adds given string to result string.
   */
  void add(String string) {
    sb.write(string);
  }

  void addBeginAndEndTokensToParams(Node node, Map params) {
    params['getBeginToken'] = tokenToStringOrNull(node.getBeginToken());
    params['getEndToken'] = tokenToStringOrNull(node.getEndToken());
  }

  /**
   * Adds given node type to result string.
   * The method "opens" the node, meaning that all output after calling
   * this method and before calling closeNode() will represent contents
   * of given node.
   */
  void openNode(Node node, String type, [Map params]) {
    if (params == null) params = new Map();
    addCurrentIndent();
    sb.write("<");
    addBeginAndEndTokensToParams(node, params);
    addTypeWithParams(type, params);
    sb.write(">\n");
    pushTag(type);
  }

  /**
   * Adds given node to result string.
   */
  void openAndCloseNode(Node node, String type, [Map params]) {
    if (params == null) params = new Map();
    addCurrentIndent();
    sb.write("<");
    addBeginAndEndTokensToParams(node, params);
    addTypeWithParams(type, params);
    sb.write("/>\n");
  }

  /**
   * Closes current node type.
   */
  void closeNode() {
    String tag = popTag();
    addCurrentIndent();
    sb.write("</");
    addTypeWithParams(tag);
    sb.write(">\n");
  }

  void addTypeWithParams(String type, [Map params]) {
    if (params == null) params = new Map();
    sb.write("${type}");
    params.forEach((k, v) {
      String value;
      if (v != null) {
        var str = v;
        if (v is Token) str = v.value;
        value = str
            .replaceAll("<", "&lt;")
            .replaceAll(">", "&gt;")
            .replaceAll('"', "'");
      } else {
        value = "[null]";
      }
      sb.write(' $k="$value"');
    });
  }

  void addCurrentIndent() {
    sb.write(indentation);
  }

  /**
   * Pretty-prints given node tree into string.
   */
  static String prettyPrint(Node node) {
    var p = new PrettyPrinter();
    node.accept(p);
    return p.sb.toString();
  }

  visitNodeWithChildren(Node node, String type) {
    openNode(node, type);
    node.visitChildren(this);
    closeNode();
  }

  visitAsyncModifier(AsyncModifier node) {
    openAndCloseNode(node, "AsyncModifier",
        {'asyncToken': node.asyncToken,
         'starToken': node.starToken});
  }

  visitBlock(Block node) {
    visitNodeWithChildren(node, "Block");
  }

  visitBreakStatement(BreakStatement node) {
    visitNodeWithChildren(node, "BreakStatement");
  }

  visitCascade(Cascade node) {
    visitNodeWithChildren(node, "Cascade");
  }

  visitCascadeReceiver(CascadeReceiver node) {
    visitNodeWithChildren(node, "CascadeReceiver");
  }

  visitCaseMatch(CaseMatch node) {
    visitNodeWithChildren(node, "CaseMatch");
  }

  visitCatchBlock(CatchBlock node) {
    visitNodeWithChildren(node, "CatchBlock");
  }

  visitClassNode(ClassNode node) {
    openNode(node, "ClassNode", {
      "extendsKeyword" : tokenToStringOrNull(node.extendsKeyword)
    });
    visitChildNode(node.name, "name");
    visitChildNode(node.superclass, "superclass");
    visitChildNode(node.interfaces, "interfaces");
    visitChildNode(node.typeParameters, "typeParameters");
    closeNode();
  }

  visitConditional(Conditional node) {
    visitNodeWithChildren(node, "Conditional");
  }

  visitContinueStatement(ContinueStatement node) {
    visitNodeWithChildren(node, "ContinueStatement");
  }

  visitDoWhile(DoWhile node) {
    visitNodeWithChildren(node, "DoWhile");
  }

  visitEmptyStatement(EmptyStatement node) {
    visitNodeWithChildren(node, "EmptyStatement");
  }

  visitEnum(Enum node) {
    visitNodeWithChildren(node, "Enum");
  }

  visitExpressionStatement(ExpressionStatement node) {
    visitNodeWithChildren(node, "ExpressionStatement");
  }

  visitFor(For node) {
    visitNodeWithChildren(node, "For");
  }

  visitForIn(ForIn node) {
    openNode(node, "ForIn", {'await': node.awaitToken});
    node.visitChildren(this);
    closeNode();
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    visitNodeWithChildren(node, "FunctionDeclaration");
  }

  visitFunctionExpression(FunctionExpression node) {
    openNode(node, "FunctionExpression", {
      "getOrSet" : tokenToStringOrNull(node.getOrSet)
    });
    visitChildNode(node.modifiers, "modifiers");
    visitChildNode(node.returnType, "returnType");
    visitChildNode(node.name, "name");
    visitChildNode(node.parameters, "parameters");
    visitChildNode(node.initializers, "initializers");
    visitChildNode(node.body, "body");
    closeNode();
  }

  visitIdentifier(Identifier node) {
    openAndCloseNode(node, "Identifier", {"token" : node.token});
  }

  visitIf(If node) {
    visitNodeWithChildren(node, "If");
  }

  visitLabel(Label node) {
    visitNodeWithChildren(node, "Label");
  }

  visitLabeledStatement(LabeledStatement node) {
    visitNodeWithChildren(node, "LabeledStatement");
  }

  // Custom.
  printLiteral(Literal node, String type) {
    openAndCloseNode(node, type, {"value" : node.value.toString()});
  }

  visitLiteralBool(LiteralBool node) {
    printLiteral(node, "LiteralBool");
  }

  visitLiteralDouble(LiteralDouble node) {
    printLiteral(node, "LiteralDouble");
  }

  visitLiteralInt(LiteralInt node) {
    printLiteral(node, "LiteralInt");
  }

  /** Returns token string value or [:null:] if token is [:null:]. */
  tokenToStringOrNull(Token token) => token == null ? null : token.stringValue;

  visitLiteralList(LiteralList node) {
    openNode(node, "LiteralList", {
      "constKeyword" : tokenToStringOrNull(node.constKeyword)
    });
    visitChildNode(node.typeArguments, "typeArguments");
    visitChildNode(node.elements, "elements");
    closeNode();
  }

  visitLiteralMap(LiteralMap node) {
    visitNodeWithChildren(node, "LiteralMap");
  }

  visitLiteralMapEntry(LiteralMapEntry node) {
    visitNodeWithChildren(node, "LiteralMapEntry");
  }

  visitLiteralNull(LiteralNull node) {
    printLiteral(node, "LiteralNull");
  }

  visitLiteralString(LiteralString node) {
    openAndCloseNode(node, "LiteralString",
        {"value" : node.token});
  }

  visitMixinApplication(MixinApplication node) {
    visitNodeWithChildren(node, "MixinApplication");
  }

  visitModifiers(Modifiers node) {
    visitNodeWithChildren(node, "Modifiers");
  }

  visitNamedArgument(NamedArgument node) {
    visitNodeWithChildren(node, "NamedArgument");
  }

  visitNamedMixinApplication(NamedMixinApplication node) {
    visitNodeWithChildren(node, "NamedMixinApplication");
  }

  visitNewExpression(NewExpression node) {
    visitNodeWithChildren(node, "NewExpression");
  }

  visitNodeList(NodeList node) {
    var params = { "delimiter" : node.delimiter };
    if (node.isEmpty) {
      openAndCloseNode(node, "NodeList", params);
    } else {
      openNode(node, "NodeList", params);
      node.visitChildren(this);
      closeNode();
    }
  }

  visitOperator(Operator node) {
    openAndCloseNode(node, "Operator", {"value" : node.token});
  }

  visitParenthesizedExpression(ParenthesizedExpression node) {
    visitNodeWithChildren(node, "ParenthesizedExpression");
  }

  visitRedirectingFactoryBody(RedirectingFactoryBody node) {
    openNode(node, "RedirectingFactoryBody");
    visitChildNode(node.constructorReference, "constructorReference");
    closeNode();
  }

  visitRethrow(Rethrow node) {
    visitNodeWithChildren(node, "Rethrow");
  }

  visitReturn(Return node) {
    openNode(node, "Return");
    visitChildNode(node.expression, "expression");
    closeNode();
  }

  visitYield(Yield node) {
    openNode(node, "Yield", {'star': node.starToken});
    visitChildNode(node.expression, "expression");
    closeNode();
  }

  visitChildNode(Node node, String fieldName) {
    if (node == null) return;
    addCurrentIndent();
    sb.write("<$fieldName>\n");
    pushTag(fieldName);
    node.accept(this);
    popTag();
    addCurrentIndent();
    sb.write("</$fieldName>\n");
  }

  openSendNodeWithFields(Send node, String type) {
    openNode(node, type, {
        "isPrefix" : "${node.isPrefix}",
        "isPostfix" : "${node.isPostfix}",
        "isIndex" : "${node.isIndex}"
    });
    visitChildNode(node.receiver, "receiver");
    visitChildNode(node.selector, "selector");
    visitChildNode(node.argumentsNode, "argumentsNode");
  }

  visitSend(Send node) {
    openSendNodeWithFields(node, "Send");
    closeNode();
  }

  visitSendSet(SendSet node) {
    openSendNodeWithFields(node, "SendSet");
    visitChildNode(node.assignmentOperator, "assignmentOperator");
    closeNode();
  }

  visitStringInterpolation(StringInterpolation node) {
    visitNodeWithChildren(node, "StringInterpolation");
  }

  visitStringInterpolationPart(StringInterpolationPart node) {
    visitNodeWithChildren(node, "StringInterpolationPart");
  }

  visitStringJuxtaposition(StringJuxtaposition node) {
    visitNodeWithChildren(node, "StringJuxtaposition");
  }

  visitSwitchCase(SwitchCase node) {
    visitNodeWithChildren(node, "SwitchCase");
  }

  visitSwitchStatement(SwitchStatement node) {
    visitNodeWithChildren(node, "SwitchStatement");
  }

  visitLiteralSymbol(LiteralSymbol node) {
    openNode(node, "LiteralSymbol");
    visitChildNode(node.identifiers, "identifiers");
    closeNode();
  }

  visitThrow(Throw node) {
    visitNodeWithChildren(node, "Throw");
  }

  visitAwait(Await node) {
    visitNodeWithChildren(node, "Await");
  }

  visitTryStatement(TryStatement node) {
    visitNodeWithChildren(node, "TryStatement");
  }

  visitTypeAnnotation(TypeAnnotation node) {
    openNode(node, "TypeAnnotation");
    visitChildNode(node.typeName, "typeName");
    visitChildNode(node.typeArguments, "typeArguments");
    closeNode();
  }

  visitTypedef(Typedef node) {
    visitNodeWithChildren(node, "Typedef");
  }

  visitTypeVariable(TypeVariable node) {
    openNode(node, "TypeVariable");
    visitChildNode(node.name, "name");
    visitChildNode(node.bound, "bound");
    closeNode();
  }

  visitVariableDefinitions(VariableDefinitions node) {
    openNode(node, "VariableDefinitions");
    visitChildNode(node.type, "type");
    visitChildNode(node.modifiers, "modifiers");
    visitChildNode(node.definitions, "definitions");
    closeNode();
  }

  visitWhile(While node) {
    visitNodeWithChildren(node, "While");
  }

  visitMetadata(Metadata node) {
    openNode(node, "Metadata", {
      "token": node.token
    });
    visitChildNode(node.expression, "expression");
    closeNode();
  }

  visitCombinator(Combinator node) {
    openNode(node, "Combinator", {"isShow" : "${node.isShow}",
                                  "isHide" : "${node.isHide}"});
    closeNode();
  }

  visitExport(Export node) {
    openNode(node, "Export");
    visitChildNode(node.uri, "uri");
    visitChildNode(node.combinators, "combinators");
    closeNode();
  }

  visitImport(Import node) {
    openNode(node, "Import", {
      "isDeferred" : "${node.isDeferred}"});
    visitChildNode(node.uri, "uri");
    visitChildNode(node.combinators, "combinators");
    if (node.prefix != null) {
      visitChildNode(node.prefix, "prefix");
    }
    closeNode();
  }

  visitPart(Part node) {
    openNode(node, "Part");
    visitChildNode(node.uri, "uri");
    closeNode();
  }

  visitPartOf(PartOf node) {
    openNode(node, "PartOf");
    visitChildNode(node.name, "name");
    closeNode();
  }

  visitLibraryName(LibraryName node) {
    openNode(node, "LibraryName");
    visitChildNode(node.name, "name");
    closeNode();
  }

  visitNode(Node node) {
    unimplemented('visitNode', node: node);
  }

  visitLibraryDependency(Node node) {
    unimplemented('visitNode', node: node);
  }

  visitLibraryTag(LibraryTag node) {
    unimplemented('visitNode', node: node);
  }

  visitLiteral(Literal node) {
    unimplemented('visitNode', node: node);
  }

  visitLoop(Loop node) {
    unimplemented('visitNode', node: node);
  }

  visitPostfix(Postfix node) {
    unimplemented('visitNode', node: node);
  }

  visitPrefix(Prefix node) {
    unimplemented('visitNode', node: node);
  }

  visitStringNode(StringNode node) {
    unimplemented('visitNode', node: node);
  }

  visitStatement(Statement node) {
    unimplemented('visitNode', node: node);
  }

  visitExpression(Expression node) {
    unimplemented('visitNode', node: node);
  }

  visitGotoStatement(GotoStatement node) {
    unimplemented('visitNode', node: node);
  }

  unimplemented(String message, {Node node}) {
    throw message;
  }
}
