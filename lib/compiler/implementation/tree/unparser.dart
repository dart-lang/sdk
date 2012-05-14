// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Unparser implements Visitor {
  StringBuffer sb;
  final bool printDebugInfo;

  Unparser([this.printDebugInfo = false]);

  String unparse(Node node) {
    sb = new StringBuffer();
    visit(node);
    return sb.toString();
  }

  void add(SourceString string) {
    string.printOn(sb);
  }

  visit(Node node) {
    if (node !== null) {
      if (printDebugInfo) sb.add('[${node.getObjectDescription()}: ');
      node.accept(this);
      if (printDebugInfo) sb.add(']');
    } else if (printDebugInfo) {
      sb.add('[null]');
    }
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

  visitClassNode(ClassNode node) {
    node.beginToken.value.printOn(sb);
    sb.add(' ');
    visit(node.name);
    sb.add(' ');
    if (node.extendsKeyword !== null) {
      node.extendsKeyword.value.printOn(sb);
      sb.add(' ');
      visit(node.superclass);
      sb.add(' ');
    }
    visit(node.interfaces);
    if (node.defaultClause !== null) {
      visit(node.defaultClause);
      sb.add(' ');
    }
    sb.add('{\n');
    sb.add('}\n');
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
    visit(node.conditionStatement);
    visit(node.update);
    sb.add(')');
    visit(node.body);
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    visit(node.function);
  }

  visitFunctionExpression(FunctionExpression node) {
    if (node.returnType !== null) {
      visit(node.returnType);
      sb.add(' ');
    }
    visit(node.name);
    visit(node.parameters);
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
      visit(node.elsePart);
    }
  }

  visitLiteralBool(LiteralBool node) {
    add(node.token.value);
  }

  visitLiteralDouble(LiteralDouble node) {
    add(node.token.value);
  }

  visitLiteralInt(LiteralInt node) {
    add(node.token.value);
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
    // TODO(ahe): handle 'const'.
    add(node.newToken.value);
    sb.add(' ');
    visit(node.send);
  }

  visitLiteralList(LiteralList node) {
    // TODO(ahe): handle 'const'.
    if (node.type !== null) {
      sb.add('<');
      visit(node.type);
      sb.add('>');
    }
    sb.add(' ');
    visit(node.elements);
  }

  visitModifiers(Modifiers node) => node.visitChildren(this);

  visitNodeList(NodeList node) {
    if (node.beginToken !== null) add(node.beginToken.value);
    if (node.nodes !== null) {
      String delimiter = (node.delimiter === null) ? " " : "${node.delimiter} ";
      node.nodes.printOn(sb, delimiter);
    }
    if (node.endToken !== null) add(node.endToken.value);
  }

  visitOperator(Operator node) {
    visitIdentifier(node);
  }

  visitReturn(Return node) {
    add(node.beginToken.value);
    if (node.hasExpression) {
      sb.add(' ');
      visit(node.expression);
    }
    if (node.endToken !== null) add(node.endToken.value);
  }


  unparseSendPart(Send node) {
    if (node.isPrefix) {
      visit(node.selector);
    }
    if (node.receiver !== null) {
      visit(node.receiver);
      if (node.selector is !Operator) sb.add('.');
    }
    if (!node.isPrefix) {
      visit(node.selector);
    }
  }

  visitSend(Send node) {
    unparseSendPart(node);
    visit(node.argumentsNode);
  }

  visitSendSet(SendSet node) {
    unparseSendPart(node);
    add(node.assignmentOperator.token.value);
    visit(node.argumentsNode);
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
    node.visitChildren(this);
  }

  visitTypeVariable(TypeVariable node) {
    visit(node.name);
    if (node.bound !== null) {
      sb.add(' extends ');
      visit(node.bound);
    }
  }

  visitVariableDefinitions(VariableDefinitions node) {
    if (node.type !== null) {
      visit(node.type);
    } else {
      sb.add('var');
    }
    sb.add(' ');
    // TODO(karlklose): print modifiers.
    visit(node.definitions);
    if (node.endToken.value == const SourceString(';')) {
      add(node.endToken.value);
    }
  }

  visitDoWhile(DoWhile node) {
    add(node.doKeyword.value);
    sb.add(' ');
    visit(node.body);
    sb.add(' ');
    add(node.whileKeyword.value);
    sb.add(' ');
    visit(node.condition);
    sb.add(node.endToken.value);
  }

  visitWhile(While node) {
    add(node.whileKeyword.value);
    sb.add(' ');
    visit(node.condition);
    sb.add(' ');
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
    sb.add(' (');
    visit(node.declaredIdentifier);
    add(node.inToken.value);
    visit(node.expression);
    sb.add(') ');
    visit(node.body);
  }

  visitLabel(Label node) {
    visit(node.identifier);
    add(node.colonToken.value);
   }

  visitLabeledStatement(LabeledStatement node) {
    visit(node.label);
    sb.add(' ');
    visit(node.statement);
  }

  visitLiteralMap(LiteralMap node) {
    // TODO(ahe): handle 'const'.
    if (node.typeArguments !== null) visit(node.typeArguments);
    visit(node.entries);
  }

  visitLiteralMapEntry(LiteralMapEntry node) {
    visit(node.key);
    add(node.colonToken.value);
    sb.add(' ');
    visit(node.value);
  }

  visitNamedArgument(NamedArgument node) {
    visit(node.name);
    add(node.colonToken.value);
    sb.add(' ');
    visit(node.expression);
  }

  visitSwitchStatement(SwitchStatement node) {
    add(node.switchKeyword.value);
    sb.add(' ');
    visit(node.parenthesizedExpression);
    sb.add(' ');
    visit(node.cases);
  }

  visitSwitchCase(SwitchCase node) {
    visit(node.labelsAndCases);
    if (node.isDefaultCase) {
      sb.add('default:');
    }
    visit(node.statements);
  }

  visitScriptTag(ScriptTag node) {
    add(node.beginToken.value);
    visit(node.tag);
    sb.add('(');
    visit(node.argument);
    if (node.prefixIdentifier !== null) {
      visit(node.prefixIdentifier);
      sb.add(': ');
      visit(node.prefix);
    }
    sb.add(')');
    add(node.endToken.value);
  }

  visitTryStatement(TryStatement node) {
    add(node.tryKeyword.value);
    sb.add(' ');
    visit(node.tryBlock);
    visit(node.catchBlocks);
    if (node.finallyKeyword !== null) {
      sb.add(' ');
      add(node.finallyKeyword.value);
      sb.add(' ');
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
    add(node.catchKeyword.value);
    sb.add(' ');
    visit(node.formals);
    sb.add(' ');
    visit(node.block);
  }

  visitTypedef(Typedef node) {
    add(node.typedefKeyword.value);
    sb.add(' ');
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
}
