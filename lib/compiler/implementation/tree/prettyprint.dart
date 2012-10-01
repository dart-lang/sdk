// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Pretty-prints Node tree in XML-like format.
 *
 * TODO(smok): Add main() to run from command-line to print out tree for given
 * .dart file.
 */
class PrettyPrinter implements Visitor {

  /** String used to represent one level of indent. */
  static const String INDENT = "  ";

  StringBuffer sb;
  Link<String> tagStack;

  PrettyPrinter() :
      sb = new StringBuffer(),
      tagStack = new EmptyLink<String>();

  void pushTag(String tag) {
    tagStack = tagStack.prepend(tag);
  }

  String popTag() {
    assert(!tagStack.isEmpty());
    String tag = tagStack.head;
    tagStack = tagStack.tail;
    return tag;
  }

  /**
   * Adds given string to result string.
   */
  void add(SourceString string) {
    string.printOn(sb);
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
    if (params === null) params = new Map();
    addCurrentIndent();
    sb.add("<");
    addBeginAndEndTokensToParams(node, params);
    addTypeWithParams(type, params);
    sb.add(">\n");
    pushTag(type);
  }

  /**
   * Adds given node to result string.
   */
  void openAndCloseNode(Node node, String type, [Map params]) {
    if (params === null) params = new Map();
    addCurrentIndent();
    sb.add("<");
    addBeginAndEndTokensToParams(node, params);
    addTypeWithParams(type, params);
    sb.add("/>\n");
  }

  /**
   * Closes current node type.
   */
  void closeNode() {
    String tag = popTag();
    addCurrentIndent();
    sb.add("</");
    addTypeWithParams(tag);
    sb.add(">\n");
  }

  void addTypeWithParams(String type, [Map params]) {
    if (params === null) params = new Map();
    sb.add("${type}");
    params.forEach((k, v) {
      String value;
      if (v !== null) {
        value = v
            .replaceAll("<", "&lt;")
            .replaceAll(">", "&gt;")
            .replaceAll('"', "'");
      } else {
        value = "[null]";
      }
      sb.add(' $k="$value"');
    });
  }

  void addCurrentIndent() {
    tagStack.forEach((_) { sb.add(INDENT); });
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
    visitChildNode(node.defaultClause, "defaultClause");
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

  visitExpressionStatement(ExpressionStatement node) {
    visitNodeWithChildren(node, "ExpressionStatement");
  }

  visitFor(For node) {
    visitNodeWithChildren(node, "For");
  }

  visitForIn(ForIn node) {
    visitNodeWithChildren(node, "ForIn");
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
    openAndCloseNode(node, "Identifier", {"token" : node.token.slowToString()});
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

  /** Returns token string value or [null] if token is [null]. */
  tokenToStringOrNull(Token token) => token === null ? null : token.stringValue;

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
        {"value" : node.token.slowToString()});
  }

  visitModifiers(Modifiers node) {
    visitNodeWithChildren(node, "Modifiers");
  }

  visitNamedArgument(NamedArgument node) {
    visitNodeWithChildren(node, "NamedArgument");
  }

  visitNewExpression(NewExpression node) {
    visitNodeWithChildren(node, "NewExpression");
  }

  visitNodeList(NodeList node) {
    var params = {
        "delimiter" :
            node.delimiter !== null ? node.delimiter.stringValue : null
    };
    if (node.nodes.toList().length == 0) {
      openAndCloseNode(node, "NodeList", params);
    } else {
      openNode(node, "NodeList", params);
      node.visitChildren(this);
      closeNode();
    }
  }

  visitOperator(Operator node) {
    openAndCloseNode(node, "Operator", {"value" : node.token.slowToString()});
  }

  visitParenthesizedExpression(ParenthesizedExpression node) {
    visitNodeWithChildren(node, "ParenthesizedExpression");
  }

  visitReturn(Return node) {
    openNode(node, "Return");
    visitChildNode(node.expression, "expression");
    closeNode();
  }

  visitScriptTag(ScriptTag node) {
    visitNodeWithChildren(node, "ScriptTag");
  }

  visitChildNode(Node node, String fieldName) {
    if (node === null) return;
    addCurrentIndent();
    sb.add("<$fieldName>\n");
    pushTag(fieldName);
    node.accept(this);
    popTag();
    addCurrentIndent();
    sb.add("</$fieldName>\n");
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

  visitThrow(Throw node) {
    visitNodeWithChildren(node, "Throw");
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
}
