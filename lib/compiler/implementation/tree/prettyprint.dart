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
  static final String INDENT = "  ";

  StringBuffer sb;
  int depth;
  /** Prefix for the type passed to the next [openNode()] call. */
  String nextTypePrefix;

  PrettyPrinter() : sb = new StringBuffer(), depth = 0;

  /**
   * Adds given string to result string.
   */
  void add(SourceString string) {
    string.printOn(sb);
  }

  /**
   * Adds given node type to result string, increasing current depth by 1.
   * The method "opens" the node, meaning that all output after calling
   * this method and before calling closeNode() will represent contents
   * of given node.
   */
  void openNode(String type, [Map params]) {
    addCurrentIndent();
    sb.add("<");
    addTypeWithParams(type, params);
    sb.add(">\n");
    depth++;
  }

  /**
   * Adds given node to result string, depth is not affected.
   */
  void openAndCloseNode(String type, [Map params]) {
    addCurrentIndent();
    sb.add("<");
    addTypeWithParams(type, params);
    sb.add("/>\n");
  }

  /**
   * Closes given node type, decreasing current depth by 1.
   */
  void closeNode(String type, [Map params]) {
    depth--;
    addCurrentIndent();
    sb.add("</");
    addTypeWithParams(type, params);
    sb.add(">\n");
  }

  void addTypeWithParams(String type, [Map params]) {
    if (nextTypePrefix !== null) {
      sb.add(nextTypePrefix);
      nextTypePrefix = null;
    }
    sb.add("${type}");
    if (params != null) {
      // TODO(smok): Escape doublequotes in values.
      params.forEach((k, v) {
        sb.add(' $k=');
        if (v !== null) {
          sb.add('"$v"');
        } else {
          sb.add('null');
        }
      });
    }
  }

  void addCurrentIndent() {
    for (int i = 0; i < depth; i++) {
      sb.add(INDENT);
    }
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
    openNode(type);
    node.visitChildren(this);
    closeNode(type);
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
    visitNodeWithChildren(node, "ClassNode");
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
    visitNodeWithChildren(node, "FunctionExpression");
  }

  visitIdentifier(Identifier node) {
    openAndCloseNode("Identifier", {"token" : node.token.slowToString()});
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
  visitLiteral(Literal node, String type) {
    openAndCloseNode(type, {"value" : node.value.toString()});
  }

  visitLiteralBool(LiteralBool node) {
    visitLiteral(node, "LiteralBool");
  }

  visitLiteralDouble(LiteralDouble node) {
    visitLiteral(node, "LiteralDouble");
  }

  visitLiteralInt(LiteralInt node) {
    visitLiteral(node, "LiteralInt");
  }

  /** Returns token string value or [null] if token is [null]. */
  tokenToStringOrNull(Token token) => token === null ? null : token.stringValue;

  visitLiteralList(LiteralList node) {
    openNode("LiteralList", {
      "constKeyword" : tokenToStringOrNull(node.constKeyword)
    });
    visitWithPrefix(node.type, "type:");
    visitWithPrefix(node.elements, "elements:");
    closeNode("LiteralList");
  }

  visitLiteralMap(LiteralMap node) {
    visitNodeWithChildren(node, "LiteralMap");
  }

  visitLiteralMapEntry(LiteralMapEntry node) {
    visitNodeWithChildren(node, "LiteralMapEntry");
  }

  visitLiteralNull(LiteralNull node) {
    visitLiteral(node, "LiteralNull");
  }

  visitLiteralString(LiteralString node) {
    openAndCloseNode("LiteralString", {"value" : node.token.slowToString()});
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
            node.delimiter !== null ? node.delimiter.stringValue : null,
        "beginToken" : tokenToStringOrNull(node.getBeginToken()),
        "endToken" : tokenToStringOrNull(node.getEndToken())};
    if (node.nodes.toList().length == 0) {
      openAndCloseNode("NodeList", params);
    } else {
      openNode("NodeList", params);
      node.visitChildren(this);
      closeNode("NodeList");
    }
  }

  visitOperator(Operator node) {
    openAndCloseNode("Operator", {"value" : node.token.slowToString()});
  }

  visitParenthesizedExpression(ParenthesizedExpression node) {
    visitNodeWithChildren(node, "ParenthesizedExpression");
  }

  visitReturn(Return node) {
    var beginToken = node.getBeginToken() !== null
        ? node.getBeginToken().stringValue : "null";
    var endToken = node.getEndToken() !== null
        ? node.getEndToken().stringValue : "null";
    openNode("Return", {"beginToken" : beginToken, "endToken" : endToken});
    visitWithPrefix(node.expression, "expression:");
    closeNode("Return");
  }

  visitScriptTag(ScriptTag node) {
    visitNodeWithChildren(node, "ScriptTag");
  }

  /** Custom helper to visit given node and print its type with prefix. */
  visitWithPrefix(Node node, String prefix) {
    if (node === null) return;
    nextTypePrefix = prefix;
    node.accept(this);
  }

  openSendNodeWithFields(Send node, String type) {
    openNode(type, {
        "isPrefix" : "${node.isPrefix}",
        "isPostfix" : "${node.isPostfix}",
        "isIndex" : "${node.isIndex}"
    });
    visitWithPrefix(node.receiver, "receiver:");
    visitWithPrefix(node.selector, "selector:");
    visitWithPrefix(node.argumentsNode, "argumentsNode:");
  }

  visitSend(Send node) {
    openSendNodeWithFields(node, "Send");
    closeNode("Send");
  }

  visitSendSet(SendSet node) {
    openSendNodeWithFields(node, "SendSet");
    visitWithPrefix(node.assignmentOperator, "assignmentOperator:");
    closeNode("SendSet");
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
    visitNodeWithChildren(node, "TypeAnnotation");
  }

  visitTypedef(Typedef node) {
    visitNodeWithChildren(node, "Typedef");
  }

  visitTypeVariable(TypeVariable node) {
    visitNodeWithChildren(node, "TypeVariable");
  }

  visitVariableDefinitions(VariableDefinitions node) {
    openNode("VariableDefinitions", {
      "beginToken" : "${node.getBeginToken().stringValue}",
      "endToken" : "${node.getEndToken().stringValue}"
    });
    visitWithPrefix(node.type, "type:");
    visitWithPrefix(node.modifiers, "modifiers:");
    visitWithPrefix(node.definitions, "definitions:");
    closeNode("VariableDefinitions");
  }

  visitWhile(While node) {
    visitNodeWithChildren(node, "While");
  }
}
