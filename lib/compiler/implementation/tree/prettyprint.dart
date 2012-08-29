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
  int depth;
  /** Prefix for the type passed to the next [openNode()] call. */
  String nextTypePrefix;
  /** Nodes that were opened with [openNode()] calls. */
  Link<String> currentNodeTypes;

  PrettyPrinter() :
      sb = new StringBuffer(),
      depth = 0,
      currentNodeTypes = new EmptyLink<String>();

  void pushCurrentNodeType(String nodeType) {
    currentNodeTypes = currentNodeTypes.prepend(nodeType);
  }

  String popCurrentNodeType() {
    assert(!currentNodeTypes.isEmpty());
    String currentNodeType = currentNodeTypes.head;
    currentNodeTypes = currentNodeTypes.tail;
    return currentNodeType;
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
   * Adds given node type to result string, increasing current depth by 1.
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
    pushCurrentNodeType(type);
    depth++;
  }

  /**
   * Adds given node to result string, depth is not affected.
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
   * Closes current node type, decreasing current depth by 1.
   */
  void closeNode() {
    depth--;
    addCurrentIndent();
    sb.add("</");
    addTypeWithParams(popCurrentNodeType());
    sb.add(">\n");
  }

  void addTypeWithParams(String type, [Map params]) {
    if (params === null) params = new Map();
    if (nextTypePrefix !== null) {
      sb.add(nextTypePrefix);
      nextTypePrefix = null;
    }
    sb.add("${type}");
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
    visitWithPrefix(node.name, "name:");
    visitWithPrefix(node.superclass, "superclass:");
    visitWithPrefix(node.interfaces, "interfaces:");
    visitWithPrefix(node.typeParameters, "typeParameters:");
    visitWithPrefix(node.defaultClause, "defaultClause:");
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
    visitWithPrefix(node.modifiers, "modifiers:");
    visitWithPrefix(node.returnType, "returnType:");
    visitWithPrefix(node.name, "name:");
    visitWithPrefix(node.parameters, "parameters:");
    visitWithPrefix(node.initializers, "initializers:");
    visitWithPrefix(node.body, "body:");
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
  visitLiteral(Literal node, String type) {
    openAndCloseNode(node, type, {"value" : node.value.toString()});
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
    openNode(node, "LiteralList", {
      "constKeyword" : tokenToStringOrNull(node.constKeyword)
    });
    visitWithPrefix(node.typeArguments, "typeArguments:");
    visitWithPrefix(node.elements, "elements:");
    closeNode();
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
    visitWithPrefix(node.expression, "expression:");
    closeNode();
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
    openNode(node, type, {
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
    closeNode();
  }

  visitSendSet(SendSet node) {
    openSendNodeWithFields(node, "SendSet");
    visitWithPrefix(node.assignmentOperator, "assignmentOperator:");
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
    visitWithPrefix(node.typeName, "typeName:");
    visitWithPrefix(node.typeArguments, "typeArguments:");
    closeNode();
  }

  visitTypedef(Typedef node) {
    visitNodeWithChildren(node, "Typedef");
  }

  visitTypeVariable(TypeVariable node) {
    openNode(node, "TypeVariable");
    visitWithPrefix(node.name, "name:");
    visitWithPrefix(node.bound, "bound:");
    closeNode();
  }

  visitVariableDefinitions(VariableDefinitions node) {
    openNode(node, "VariableDefinitions");
    visitWithPrefix(node.type, "type:");
    visitWithPrefix(node.modifiers, "modifiers:");
    visitWithPrefix(node.definitions, "definitions:");
    closeNode();
  }

  visitWhile(While node) {
    visitNodeWithChildren(node, "While");
  }
}
