// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show IterableMixin;

import 'package:front_end/src/fasta/fasta_codes.dart' show Message;
import 'package:front_end/src/fasta/scanner.dart' show Token;
import 'package:front_end/src/fasta/scanner/token_constants.dart' as Tokens
    show PLUS_TOKEN;
import 'package:front_end/src/fasta/scanner/characters.dart';
import 'package:front_end/src/scanner/token.dart' show BeginToken, TokenType;

import '../common.dart';
import '../elements/elements.dart' show MetadataAnnotation;
import '../util/util.dart';
import 'dartstring.dart';
import 'prettyprint.dart';
import 'unparser.dart';

abstract class Visitor<R> {
  const Visitor();

  R visitNode(Node node);

  R visitAssert(Assert node) => visitStatement(node);
  R visitAsyncForIn(AsyncForIn node) => visitForIn(node);
  R visitAsyncModifier(AsyncModifier node) => visitNode(node);
  R visitAwait(Await node) => visitExpression(node);
  R visitBlock(Block node) => visitStatement(node);
  R visitBreakStatement(BreakStatement node) => visitGotoStatement(node);
  R visitCascade(Cascade node) => visitExpression(node);
  R visitCascadeReceiver(CascadeReceiver node) => visitExpression(node);
  R visitCaseMatch(CaseMatch node) => visitNode(node);
  R visitCatchBlock(CatchBlock node) => visitNode(node);
  R visitClassNode(ClassNode node) => visitNode(node);
  R visitCombinator(Combinator node) => visitNode(node);
  R visitConditional(Conditional node) => visitExpression(node);
  R visitConditionalUri(ConditionalUri node) => visitNode(node);
  R visitContinueStatement(ContinueStatement node) => visitGotoStatement(node);
  R visitDottedName(DottedName node) => visitExpression(node);
  R visitDoWhile(DoWhile node) => visitLoop(node);
  R visitEmptyStatement(EmptyStatement node) => visitStatement(node);
  R visitEnum(Enum node) => visitNode(node);
  R visitExport(Export node) => visitLibraryDependency(node);
  R visitExpression(Expression node) => visitNode(node);
  R visitExpressionStatement(ExpressionStatement node) => visitStatement(node);
  R visitFor(For node) => visitLoop(node);
  R visitForIn(ForIn node) => visitLoop(node);
  R visitFunctionDeclaration(FunctionDeclaration node) => visitStatement(node);
  R visitFunctionExpression(FunctionExpression node) => visitExpression(node);
  R visitFunctionTypeAnnotation(FunctionTypeAnnotation node) {
    return visitTypeAnnotation(node);
  }

  R visitGotoStatement(GotoStatement node) => visitStatement(node);
  R visitIdentifier(Identifier node) => visitExpression(node);
  R visitImport(Import node) => visitLibraryDependency(node);
  R visitIf(If node) => visitStatement(node);
  R visitLabel(Label node) => visitNode(node);
  R visitLabeledStatement(LabeledStatement node) => visitStatement(node);
  R visitLibraryDependency(LibraryDependency node) => visitLibraryTag(node);
  R visitLibraryName(LibraryName node) => visitLibraryTag(node);
  R visitLibraryTag(LibraryTag node) => visitNode(node);
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
  R visitSyncForIn(SyncForIn node) => visitForIn(node);
  R visitLoop(Loop node) => visitStatement(node);
  R visitMetadata(Metadata node) => visitNode(node);
  R visitMixinApplication(MixinApplication node) => visitNode(node);
  R visitModifiers(Modifiers node) => visitNode(node);
  R visitNamedArgument(NamedArgument node) => visitExpression(node);
  R visitNamedMixinApplication(NamedMixinApplication node) {
    return visitMixinApplication(node);
  }

  R visitNewExpression(NewExpression node) => visitExpression(node);
  R visitNodeList(NodeList node) => visitNode(node);
  R visitNominalTypeAnnotation(NominalTypeAnnotation node) {
    return visitTypeAnnotation(node);
  }

  R visitOperator(Operator node) => visitIdentifier(node);
  R visitParenthesizedExpression(ParenthesizedExpression node) {
    return visitExpression(node);
  }

  R visitPart(Part node) => visitLibraryTag(node);
  R visitPartOf(PartOf node) => visitNode(node);
  R visitPostfix(Postfix node) => visitNodeList(node);
  R visitPrefix(Prefix node) => visitNodeList(node);
  R visitRedirectingFactoryBody(RedirectingFactoryBody node) {
    return visitStatement(node);
  }

  R visitRethrow(Rethrow node) => visitStatement(node);
  R visitReturn(Return node) => visitStatement(node);
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
  R visitLiteralSymbol(LiteralSymbol node) => visitExpression(node);
  R visitThrow(Throw node) => visitExpression(node);
  R visitTryStatement(TryStatement node) => visitStatement(node);
  R visitTypeAnnotation(TypeAnnotation node) => visitNode(node);
  R visitTypedef(Typedef node) => visitNode(node);
  R visitTypeVariable(TypeVariable node) => visitNode(node);
  R visitVariableDefinitions(VariableDefinitions node) => visitStatement(node);
  R visitWhile(While node) => visitLoop(node);
  R visitYield(Yield node) => visitStatement(node);
}

/// Visitor for [Node]s that take an additional argument of type [A] and returns
/// a value of type [R].
abstract class Visitor1<R, A> {
  const Visitor1();

  R visitNode(Node node, A arg);

  R visitAssert(Assert node, A arg) => visitStatement(node, arg);
  R visitAsyncForIn(AsyncForIn node, A arg) => visitForIn(node, arg);
  R visitAsyncModifier(AsyncModifier node, A arg) => visitNode(node, arg);
  R visitAwait(Await node, A arg) => visitExpression(node, arg);
  R visitBlock(Block node, A arg) => visitStatement(node, arg);
  R visitBreakStatement(BreakStatement node, A arg) {
    return visitGotoStatement(node, arg);
  }

  R visitCascade(Cascade node, A arg) => visitExpression(node, arg);
  R visitCascadeReceiver(CascadeReceiver node, A arg) {
    return visitExpression(node, arg);
  }

  R visitCaseMatch(CaseMatch node, A arg) => visitNode(node, arg);
  R visitCatchBlock(CatchBlock node, A arg) => visitNode(node, arg);
  R visitClassNode(ClassNode node, A arg) => visitNode(node, arg);
  R visitCombinator(Combinator node, A arg) => visitNode(node, arg);
  R visitConditional(Conditional node, A arg) => visitExpression(node, arg);
  R visitConditionalUri(ConditionalUri node, A arg) {
    return visitNode(node, arg);
  }

  R visitContinueStatement(ContinueStatement node, A arg) {
    return visitGotoStatement(node, arg);
  }

  R visitDottedName(DottedName node, A arg) {
    return visitExpression(node, arg);
  }

  R visitDoWhile(DoWhile node, A arg) => visitLoop(node, arg);
  R visitEmptyStatement(EmptyStatement node, A arg) {
    return visitStatement(node, arg);
  }

  R visitEnum(Enum node, A arg) => visitNode(node, arg);
  R visitExport(Export node, A arg) => visitLibraryDependency(node, arg);
  R visitExpression(Expression node, A arg) => visitNode(node, arg);
  R visitExpressionStatement(ExpressionStatement node, A arg) {
    return visitStatement(node, arg);
  }

  R visitFor(For node, A arg) => visitLoop(node, arg);
  R visitForIn(ForIn node, A arg) => visitLoop(node, arg);
  R visitFunctionDeclaration(FunctionDeclaration node, A arg) {
    return visitStatement(node, arg);
  }

  R visitFunctionExpression(FunctionExpression node, A arg) {
    return visitExpression(node, arg);
  }

  R visitFunctionTypeAnnotation(FunctionTypeAnnotation node, A arg) {
    return visitTypeAnnotation(node, arg);
  }

  R visitGotoStatement(GotoStatement node, A arg) {
    return visitStatement(node, arg);
  }

  R visitIdentifier(Identifier node, A arg) {
    return visitExpression(node, arg);
  }

  R visitImport(Import node, A arg) {
    return visitLibraryDependency(node, arg);
  }

  R visitIf(If node, A arg) => visitStatement(node, arg);
  R visitLabel(Label node, A arg) => visitNode(node, arg);
  R visitLabeledStatement(LabeledStatement node, A arg) {
    return visitStatement(node, arg);
  }

  R visitLibraryDependency(LibraryDependency node, A arg) {
    return visitLibraryTag(node, arg);
  }

  R visitLibraryName(LibraryName node, A arg) => visitLibraryTag(node, arg);
  R visitLibraryTag(LibraryTag node, A arg) => visitNode(node, arg);
  R visitLiteral(Literal node, A arg) => visitExpression(node, arg);
  R visitLiteralBool(LiteralBool node, A arg) => visitLiteral(node, arg);
  R visitLiteralDouble(LiteralDouble node, A arg) => visitLiteral(node, arg);
  R visitLiteralInt(LiteralInt node, A arg) => visitLiteral(node, arg);
  R visitLiteralList(LiteralList node, A arg) => visitExpression(node, arg);
  R visitLiteralMap(LiteralMap node, A arg) => visitExpression(node, arg);
  R visitLiteralMapEntry(LiteralMapEntry node, A arg) => visitNode(node, arg);
  R visitLiteralNull(LiteralNull node, A arg) => visitLiteral(node, arg);
  R visitLiteralString(LiteralString node, A arg) => visitStringNode(node, arg);
  R visitStringJuxtaposition(StringJuxtaposition node, A arg) {
    return visitStringNode(node, arg);
  }

  R visitSyncForIn(SyncForIn node, A arg) => visitForIn(node, arg);
  R visitLoop(Loop node, A arg) => visitStatement(node, arg);
  R visitMetadata(Metadata node, A arg) => visitNode(node, arg);
  R visitMixinApplication(MixinApplication node, A arg) => visitNode(node, arg);
  R visitModifiers(Modifiers node, A arg) => visitNode(node, arg);
  R visitNamedArgument(NamedArgument node, A arg) => visitExpression(node, arg);
  R visitNamedMixinApplication(NamedMixinApplication node, A arg) {
    return visitMixinApplication(node, arg);
  }

  R visitNewExpression(NewExpression node, A arg) => visitExpression(node, arg);
  R visitNodeList(NodeList node, A arg) => visitNode(node, arg);
  R visitNominalTypeAnnotation(NominalTypeAnnotation node, A arg) {
    return visitTypeAnnotation(node, arg);
  }

  R visitOperator(Operator node, A arg) => visitIdentifier(node, arg);
  R visitParenthesizedExpression(ParenthesizedExpression node, A arg) {
    return visitExpression(node, arg);
  }

  R visitPart(Part node, A arg) => visitLibraryTag(node, arg);
  R visitPartOf(PartOf node, A arg) => visitNode(node, arg);
  R visitPostfix(Postfix node, A arg) => visitNodeList(node, arg);
  R visitPrefix(Prefix node, A arg) => visitNodeList(node, arg);
  R visitRedirectingFactoryBody(RedirectingFactoryBody node, A arg) {
    return visitStatement(node, arg);
  }

  R visitRethrow(Rethrow node, A arg) => visitStatement(node, arg);
  R visitReturn(Return node, A arg) => visitStatement(node, arg);
  R visitSend(Send node, A arg) => visitExpression(node, arg);
  R visitSendSet(SendSet node, A arg) => visitSend(node, arg);
  R visitStatement(Statement node, A arg) => visitNode(node, arg);
  R visitStringNode(StringNode node, A arg) => visitExpression(node, arg);
  R visitStringInterpolation(StringInterpolation node, A arg) {
    return visitStringNode(node, arg);
  }

  R visitStringInterpolationPart(StringInterpolationPart node, A arg) {
    return visitNode(node, arg);
  }

  R visitSwitchCase(SwitchCase node, A arg) => visitNode(node, arg);
  R visitSwitchStatement(SwitchStatement node, A arg) {
    return visitStatement(node, arg);
  }

  R visitLiteralSymbol(LiteralSymbol node, A arg) => visitExpression(node, arg);
  R visitThrow(Throw node, A arg) => visitExpression(node, arg);
  R visitTryStatement(TryStatement node, A arg) => visitStatement(node, arg);
  R visitTypedef(Typedef node, A arg) => visitNode(node, arg);
  R visitTypeAnnotation(TypeAnnotation node, A arg) => visitNode(node, arg);
  R visitTypeVariable(TypeVariable node, A arg) => visitNode(node, arg);
  R visitVariableDefinitions(VariableDefinitions node, A arg) {
    return visitStatement(node, arg);
  }

  R visitWhile(While node, A arg) => visitLoop(node, arg);
  R visitYield(Yield node, A arg) => visitStatement(node, arg);
}

Token firstBeginToken(Node first, Node second) {
  Token token = null;
  if (first != null) {
    token = first.getBeginToken();
  }
  if (token == null && second != null) {
    // [token] might be null even when [first] is not, e.g. for empty Modifiers.
    token = second.getBeginToken();
  }
  return token;
}

/**
 * A node in a syntax tree.
 *
 * The abstract part of "abstract syntax tree" is invalidated when
 * supporting tools such as code formatting. These tools need concrete
 * syntax such as parentheses and no constant folding.
 *
 * We support these tools by storing additional references back to the
 * token stream. These references are stored in fields ending with
 * "Token".
 */
abstract class Node extends NullTreeElementMixin implements Spannable {
  final int hashCode = _HASH_COUNTER = (_HASH_COUNTER + 1).toUnsigned(30);
  static int _HASH_COUNTER = 0;

  Node();

  accept(Visitor visitor);

  accept1(Visitor1 visitor, arg);

  visitChildren(Visitor visitor);

  visitChildren1(Visitor1 visitor, arg);

  /**
   * Returns this node unparsed to Dart source string.
   */
  toString() => unparse(this);

  /**
   * Returns Xml-like tree representation of this node.
   */
  toDebugString() {
    return PrettyPrinter.prettyPrint(this);
  }

  String getObjectDescription() => super.toString();

  Token getBeginToken();

  /// Returns the token that ends the 'prefix' of this node.
  ///
  /// For instance the end of the parameters in a [FunctionExpression] or the
  /// last token before the start of a class body for a [ClassNode].
  Token getPrefixEndToken() => getEndToken();

  Token getEndToken();

  Assert asAssert() => null;
  AsyncModifier asAsyncModifier() => null;
  Await asAwait() => null;
  Block asBlock() => null;
  BreakStatement asBreakStatement() => null;
  Cascade asCascade() => null;
  CascadeReceiver asCascadeReceiver() => null;
  CaseMatch asCaseMatch() => null;
  CatchBlock asCatchBlock() => null;
  ClassNode asClassNode() => null;
  Combinator asCombinator() => null;
  Conditional asConditional() => null;
  ConditionalUri asConditionalUri() => null;
  ContinueStatement asContinueStatement() => null;
  DottedName asDottedName() => null;
  DoWhile asDoWhile() => null;
  EmptyStatement asEmptyStatement() => null;
  Enum asEnum() => null;
  ErrorExpression asErrorExpression() => null;
  Export asExport() => null;
  Expression asExpression() => null;
  ExpressionStatement asExpressionStatement() => null;
  For asFor() => null;
  SyncForIn asSyncForIn() => null;
  AsyncForIn asAsyncForIn() => null;
  ForIn asForIn() => null;
  FunctionDeclaration asFunctionDeclaration() => null;
  FunctionExpression asFunctionExpression() => null;
  FunctionTypeAnnotation asFunctionTypeAnnotation() => null;
  Identifier asIdentifier() => null;
  If asIf() => null;
  Import asImport() => null;
  Label asLabel() => null;
  LabeledStatement asLabeledStatement() => null;
  LibraryName asLibraryName() => null;
  LibraryDependency asLibraryDependency() => null;
  LiteralBool asLiteralBool() => null;
  LiteralDouble asLiteralDouble() => null;
  LiteralInt asLiteralInt() => null;
  LiteralList asLiteralList() => null;
  LiteralMap asLiteralMap() => null;
  LiteralMapEntry asLiteralMapEntry() => null;
  LiteralNull asLiteralNull() => null;
  LiteralString asLiteralString() => null;
  LiteralSymbol asLiteralSymbol() => null;
  Metadata asMetadata() => null;
  MixinApplication asMixinApplication() => null;
  Modifiers asModifiers() => null;
  NamedArgument asNamedArgument() => null;
  NamedMixinApplication asNamedMixinApplication() => null;
  NewExpression asNewExpression() => null;
  NodeList asNodeList() => null;
  NominalTypeAnnotation asNominalTypeAnnotation() => null;
  Operator asOperator() => null;
  ParenthesizedExpression asParenthesizedExpression() => null;
  Part asPart() => null;
  PartOf asPartOf() => null;
  RedirectingFactoryBody asRedirectingFactoryBody() => null;
  Rethrow asRethrow() => null;
  Return asReturn() => null;
  Send asSend() => null;
  SendSet asSendSet() => null;
  Statement asStatement() => null;
  StringInterpolation asStringInterpolation() => null;
  StringInterpolationPart asStringInterpolationPart() => null;
  StringJuxtaposition asStringJuxtaposition() => null;
  StringNode asStringNode() => null;
  SwitchCase asSwitchCase() => null;
  SwitchStatement asSwitchStatement() => null;
  Throw asThrow() => null;
  TryStatement asTryStatement() => null;
  TypeVariable asTypeVariable() => null;
  Typedef asTypedef() => null;
  VariableDefinitions asVariableDefinitions() => null;
  While asWhile() => null;
  Yield asYield() => null;

  bool isValidBreakTarget() => false;
  bool isValidContinueTarget() => false;
  bool isThis() => false;
  bool isSuper() => false;

  bool get isErroneous => false;
}

// Used for caching boolean values on the stack
class Flag extends Node {
  static final TRUE = new Flag._(true);
  static final FALSE = new Flag._(false);

  final bool value;

  Flag._(this.value);

  @override
  accept(Visitor visitor) {
    throw 'not implemented';
  }

  @override
  accept1(Visitor1 visitor, arg) {
    throw 'not implemented';
  }

  @override
  Token getBeginToken() {
    return null;
  }

  @override
  Token getEndToken() {
    throw 'not implemented';
  }

  @override
  visitChildren(Visitor visitor) {
    throw 'not implemented';
  }

  @override
  visitChildren1(Visitor1 visitor, arg) {
    throw 'not implemented';
  }
}

class ClassNode extends Node {
  final Modifiers modifiers;
  final Identifier name;
  final Node superclass;
  final NodeList interfaces;
  final NodeList typeParameters;
  final NodeList body;

  final Token beginToken;
  final Token extendsKeyword;
  final Token endToken;

  ClassNode(
      this.modifiers,
      this.name,
      this.typeParameters,
      this.superclass,
      this.interfaces,
      this.beginToken,
      this.extendsKeyword,
      this.body,
      this.endToken);

  ClassNode asClassNode() => this;

  accept(Visitor visitor) => visitor.visitClassNode(this);

  accept1(Visitor1 visitor, arg) => visitor.visitClassNode(this, arg);

  visitChildren(Visitor visitor) {
    if (name != null) name.accept(visitor);
    if (typeParameters != null) typeParameters.accept(visitor);
    if (superclass != null) superclass.accept(visitor);
    if (interfaces != null) interfaces.accept(visitor);
    if (body != null) body.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (name != null) name.accept1(visitor, arg);
    if (typeParameters != null) typeParameters.accept1(visitor, arg);
    if (superclass != null) superclass.accept1(visitor, arg);
    if (interfaces != null) interfaces.accept1(visitor, arg);
    if (body != null) body.accept1(visitor, arg);
  }

  Token getBeginToken() => beginToken;

  @override
  Token getPrefixEndToken() {
    Token token;
    if (interfaces != null) {
      token = interfaces.getEndToken();
    }
    if (token == null && superclass != null) {
      token = superclass.getEndToken();
    }
    if (token == null && typeParameters != null) {
      token == typeParameters.getEndToken();
    }
    if (token == null) {
      token = name.getEndToken();
    }
    assert(token != null);
    return token;
  }

  Token getEndToken() => endToken;
}

class MixinApplication extends Node {
  final NominalTypeAnnotation superclass;
  final NodeList mixins;

  MixinApplication(this.superclass, this.mixins);

  MixinApplication asMixinApplication() => this;

  accept(Visitor visitor) => visitor.visitMixinApplication(this);

  accept1(Visitor1 visitor, arg) => visitor.visitMixinApplication(this, arg);

  visitChildren(Visitor visitor) {
    if (superclass != null) superclass.accept(visitor);
    if (mixins != null) mixins.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (superclass != null) superclass.accept1(visitor, arg);
    if (mixins != null) mixins.accept1(visitor, arg);
  }

  Token getBeginToken() => superclass.getBeginToken();
  Token getEndToken() => mixins.getEndToken();
}

class NamedMixinApplication extends Node implements MixinApplication {
  final Identifier name;
  final NodeList typeParameters;

  final Modifiers modifiers;
  final MixinApplication mixinApplication;
  final NodeList interfaces;

  final Token classKeyword;
  final Token endToken;

  NamedMixinApplication(this.name, this.typeParameters, this.modifiers,
      this.mixinApplication, this.interfaces, this.classKeyword, this.endToken);

  NominalTypeAnnotation get superclass => mixinApplication.superclass;
  NodeList get mixins => mixinApplication.mixins;

  MixinApplication asMixinApplication() => this;
  NamedMixinApplication asNamedMixinApplication() => this;

  accept(Visitor visitor) => visitor.visitNamedMixinApplication(this);

  accept1(Visitor1 visitor, arg) {
    return visitor.visitNamedMixinApplication(this, arg);
  }

  visitChildren(Visitor visitor) {
    name.accept(visitor);
    if (typeParameters != null) typeParameters.accept(visitor);
    if (modifiers != null) modifiers.accept(visitor);
    if (interfaces != null) interfaces.accept(visitor);
    mixinApplication.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    name.accept1(visitor, arg);
    if (typeParameters != null) typeParameters.accept1(visitor, arg);
    if (modifiers != null) modifiers.accept1(visitor, arg);
    if (interfaces != null) interfaces.accept1(visitor, arg);
    mixinApplication.accept1(visitor, arg);
  }

  Token getBeginToken() => classKeyword;
  Token getEndToken() => endToken;
}

abstract class Expression extends Node {
  Expression();

  Expression asExpression() => this;
}

abstract class Statement extends Node {
  Statement();

  Statement asStatement() => this;

  bool isValidBreakTarget() => true;
}

/// Erroneous expression that behaves as a literal null.
class ErrorExpression extends LiteralNull {
  ErrorExpression(token) : super(token);

  ErrorExpression asErrorExpression() => this;

  bool get isErroneous => true;
}

/**
 * A message send aka method invocation. In Dart, most operations can
 * (and should) be considered as message sends. Getters and setters
 * are just methods with a special syntax. Consequently, we model
 * property access, assignment, operators, and method calls with this
 * one node.
 */
class Send extends Expression with StoredTreeElementMixin {
  final Node receiver;
  final Node selector;
  final NodeList argumentsNode;
  final NodeList typeArgumentsNode;

  /// Whether this is a conditional send of the form `a?.b`.
  final bool isConditional;

  Link<Node> get arguments => argumentsNode.nodes;

  Send(
      [this.receiver,
      this.selector,
      this.argumentsNode,
      this.typeArgumentsNode,
      this.isConditional = false]);
  Send.postfix(this.receiver, this.selector,
      [Node argument = null, this.isConditional = false])
      : argumentsNode = (argument == null)
            ? new Postfix()
            : new Postfix.singleton(argument),
        typeArgumentsNode = null;
  Send.prefix(this.receiver, this.selector,
      [Node argument = null, this.isConditional = false])
      : argumentsNode =
            (argument == null) ? new Prefix() : new Prefix.singleton(argument),
        typeArgumentsNode = null;

  Send asSend() => this;

  accept(Visitor visitor) => visitor.visitSend(this);

  accept1(Visitor1 visitor, arg) => visitor.visitSend(this, arg);

  visitChildren(Visitor visitor) {
    if (receiver != null) receiver.accept(visitor);
    if (selector != null) selector.accept(visitor);
    if (argumentsNode != null) argumentsNode.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (receiver != null) receiver.accept1(visitor, arg);
    if (selector != null) selector.accept1(visitor, arg);
    if (argumentsNode != null) argumentsNode.accept1(visitor, arg);
  }

  int argumentCount() {
    return (argumentsNode == null) ? -1 : argumentsNode.slowLength();
  }

  bool get isSuperCall {
    return receiver != null && receiver.isSuper();
  }

  bool get isOperator => selector is Operator;
  bool get isPropertyAccess => argumentsNode == null;
  bool get isFunctionObjectInvocation => selector == null;
  bool get isPrefix => argumentsNode is Prefix;
  bool get isPostfix => argumentsNode is Postfix;
  bool get isCall => !isOperator && !isPropertyAccess;
  bool get isIndex =>
      isOperator && identical(selector.asOperator().source, '[]');
  bool get isLogicalAnd =>
      isOperator && identical(selector.asOperator().source, '&&');
  bool get isLogicalOr =>
      isOperator && identical(selector.asOperator().source, '||');
  bool get isIfNull =>
      isOperator && identical(selector.asOperator().source, '??');

  bool get isTypeCast {
    return isOperator && identical(selector.asOperator().source, 'as');
  }

  bool get isTypeTest {
    return isOperator && identical(selector.asOperator().source, 'is');
  }

  bool get isIsNotCheck {
    return isTypeTest && arguments.head.asSend() != null;
  }

  TypeAnnotation get typeAnnotationFromIsCheckOrCast {
    assert(isOperator);
    assert(identical(selector.asOperator().source, 'is') ||
        identical(selector.asOperator().source, 'as'));
    return isIsNotCheck ? arguments.head.asSend().receiver : arguments.head;
  }

  Token getBeginToken() {
    if (isPrefix && !isIndex) return selector.getBeginToken();
    return firstBeginToken(receiver, selector);
  }

  Token getEndToken() {
    if (isPrefix) {
      if (receiver != null) return receiver.getEndToken();
      if (selector != null) return selector.getEndToken();
      return null;
    }
    if (!isPostfix && argumentsNode != null) {
      Token token = argumentsNode.getEndToken();
      if (token != null) return token;
    }
    if (selector != null) return selector.getEndToken();
    return getBeginToken();
  }

  Send copyWithReceiver(Node newReceiver, bool isConditional) {
    assert(receiver == null);
    return new Send(
        newReceiver, selector, argumentsNode, typeArgumentsNode, isConditional);
  }
}

class Postfix extends NodeList {
  Postfix() : super(null, const Link<Node>());
  Postfix.singleton(Node argument) : super.singleton(argument);
}

class Prefix extends NodeList {
  Prefix() : super(null, const Link<Node>());
  Prefix.singleton(Node argument) : super.singleton(argument);
}

class SendSet extends Send {
  final Operator assignmentOperator;
  SendSet(receiver, selector, this.assignmentOperator, argumentsNode,
      [bool isConditional = false])
      : super(receiver, selector, argumentsNode, null, isConditional);
  SendSet.postfix(receiver, selector, this.assignmentOperator,
      [Node argument = null, bool isConditional = false])
      : super.postfix(receiver, selector, argument, isConditional);
  SendSet.prefix(receiver, selector, this.assignmentOperator,
      [Node argument = null, bool isConditional = false])
      : super.prefix(receiver, selector, argument, isConditional);

  SendSet asSendSet() => this;

  accept(Visitor visitor) => visitor.visitSendSet(this);

  accept1(Visitor1 visitor, arg) => visitor.visitSendSet(this, arg);

  visitChildren(Visitor visitor) {
    super.visitChildren(visitor);
    if (assignmentOperator != null) assignmentOperator.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    super.visitChildren1(visitor, arg);
    if (assignmentOperator != null) assignmentOperator.accept1(visitor, arg);
  }

  /// `true` if this send is not a simple assignment.
  bool get isComplex => !identical(assignmentOperator.source, '=');

  /// Whether this is an if-null assignment of the form `a ??= b`.
  bool get isIfNullAssignment => identical(assignmentOperator.source, '??=');

  Send copyWithReceiver(Node newReceiver, bool isConditional) {
    assert(receiver == null);
    return new SendSet(newReceiver, selector, assignmentOperator, argumentsNode,
        isConditional);
  }

  Token getBeginToken() {
    if (isPrefix) return assignmentOperator.getBeginToken();
    return super.getBeginToken();
  }

  Token getEndToken() {
    if (isPostfix) return assignmentOperator.getEndToken();
    return super.getEndToken();
  }
}

class NewExpression extends Expression {
  /** The token NEW or CONST or `null` for metadata */
  final Token newToken;

  // Note: we expect that send.receiver is null.
  final Send send;

  NewExpression([this.newToken, this.send]);

  NewExpression asNewExpression() => this;

  accept(Visitor visitor) => visitor.visitNewExpression(this);

  accept1(Visitor1 visitor, arg) => visitor.visitNewExpression(this, arg);

  visitChildren(Visitor visitor) {
    if (send != null) send.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (send != null) send.accept1(visitor, arg);
  }

  bool get isConst {
    return newToken == null || identical(newToken.stringValue, 'const');
  }

  Token getBeginToken() => newToken != null ? newToken : send.getBeginToken();

  Token getEndToken() => send.getEndToken();
}

class NodeList extends Node with IterableMixin<Node> {
  final Link<Node> nodes;
  final Token beginToken;
  final Token endToken;
  final String delimiter;
  bool get isEmpty => nodes.isEmpty;

  NodeList([this.beginToken, this.nodes, this.endToken, this.delimiter]);

  Iterator<Node> get iterator => nodes.iterator;

  NodeList.singleton(Node node) : this(null, const Link<Node>().prepend(node));
  NodeList.empty() : this(null, const Link<Node>());

  NodeList asNodeList() => this;

  // Override [IterableMixin.toString] with same code as [Node.toString].
  toString() => unparse(this);

  get length {
    throw new UnsupportedError('use slowLength() instead of get:length');
  }

  int slowLength() {
    int result = 0;
    for (Link<Node> cursor = nodes; !cursor.isEmpty; cursor = cursor.tail) {
      result++;
    }
    return result;
  }

  accept(Visitor visitor) => visitor.visitNodeList(this);

  accept1(Visitor1 visitor, arg) => visitor.visitNodeList(this, arg);

  visitChildren(Visitor visitor) {
    if (nodes == null) return;
    for (Link<Node> link = nodes; !link.isEmpty; link = link.tail) {
      if (link.head != null) link.head.accept(visitor);
    }
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (nodes == null) return;
    for (Link<Node> link = nodes; !link.isEmpty; link = link.tail) {
      if (link.head != null) link.head.accept1(visitor, arg);
    }
  }

  Token getBeginToken() {
    if (beginToken != null) return beginToken;
    if (nodes != null) {
      for (Link<Node> link = nodes; !link.isEmpty; link = link.tail) {
        if (link.head.getBeginToken() != null) {
          return link.head.getBeginToken();
        }
        if (link.head.getEndToken() != null) {
          return link.head.getEndToken();
        }
      }
    }
    return endToken;
  }

  Token getEndToken() {
    if (endToken != null) return endToken;
    if (nodes != null) {
      Link<Node> link = nodes;
      if (link.isEmpty) return beginToken;
      while (!link.tail.isEmpty) link = link.tail;
      Node lastNode = link.head;
      if (lastNode != null) {
        if (lastNode.getEndToken() != null) return lastNode.getEndToken();
        if (lastNode.getBeginToken() != null) return lastNode.getBeginToken();
      }
    }
    return beginToken;
  }
}

class Block extends Statement {
  final NodeList statements;

  Block(this.statements);

  Block asBlock() => this;

  accept(Visitor visitor) => visitor.visitBlock(this);

  accept1(Visitor1 visitor, arg) => visitor.visitBlock(this, arg);

  visitChildren(Visitor visitor) {
    if (statements != null) statements.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (statements != null) statements.accept1(visitor, arg);
  }

  Token getBeginToken() => statements.getBeginToken();

  Token getEndToken() => statements.getEndToken();
}

class If extends Statement {
  final ParenthesizedExpression condition;
  final Statement thenPart;
  final Statement elsePart;

  final Token ifToken;
  final Token elseToken;

  If(this.condition, this.thenPart, this.elsePart, this.ifToken,
      this.elseToken);

  If asIf() => this;

  bool get hasElsePart => elsePart != null;

  accept(Visitor visitor) => visitor.visitIf(this);

  accept1(Visitor1 visitor, arg) => visitor.visitIf(this, arg);

  visitChildren(Visitor visitor) {
    if (condition != null) condition.accept(visitor);
    if (thenPart != null) thenPart.accept(visitor);
    if (elsePart != null) elsePart.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (condition != null) condition.accept1(visitor, arg);
    if (thenPart != null) thenPart.accept1(visitor, arg);
    if (elsePart != null) elsePart.accept1(visitor, arg);
  }

  Token getBeginToken() => ifToken;

  Token getEndToken() {
    if (elsePart == null) return thenPart.getEndToken();
    return elsePart.getEndToken();
  }
}

class Conditional extends Expression {
  final Expression condition;
  final Expression thenExpression;
  final Expression elseExpression;

  final Token questionToken;
  final Token colonToken;

  Conditional(this.condition, this.thenExpression, this.elseExpression,
      this.questionToken, this.colonToken);

  Conditional asConditional() => this;

  accept(Visitor visitor) => visitor.visitConditional(this);

  accept1(Visitor1 visitor, arg) => visitor.visitConditional(this, arg);

  visitChildren(Visitor visitor) {
    condition.accept(visitor);
    thenExpression.accept(visitor);
    elseExpression.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    condition.accept1(visitor, arg);
    thenExpression.accept1(visitor, arg);
    elseExpression.accept1(visitor, arg);
  }

  Token getBeginToken() => condition.getBeginToken();

  Token getEndToken() => elseExpression.getEndToken();
}

class For extends Loop {
  /** Either a variable declaration or an expression. */
  final Node initializer;
  /** Either an expression statement or an empty statement. */
  final Statement conditionStatement;
  final NodeList update;

  final Token forToken;

  For(this.initializer, this.conditionStatement, this.update, body,
      this.forToken)
      : super(body);

  For asFor() => this;

  Expression get condition {
    ExpressionStatement expressionStatement =
        conditionStatement.asExpressionStatement();
    if (expressionStatement != null) {
      return expressionStatement.expression;
    } else {
      return null;
    }
  }

  accept(Visitor visitor) => visitor.visitFor(this);

  accept1(Visitor1 visitor, arg) => visitor.visitFor(this, arg);

  visitChildren(Visitor visitor) {
    if (initializer != null) initializer.accept(visitor);
    if (conditionStatement != null) conditionStatement.accept(visitor);
    if (update != null) update.accept(visitor);
    if (body != null) body.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (initializer != null) initializer.accept1(visitor, arg);
    if (conditionStatement != null) conditionStatement.accept1(visitor, arg);
    if (update != null) update.accept1(visitor, arg);
    if (body != null) body.accept1(visitor, arg);
  }

  Token getBeginToken() => forToken;

  Token getEndToken() {
    return body.getEndToken();
  }
}

class FunctionDeclaration extends Statement {
  final FunctionExpression function;

  FunctionDeclaration(this.function);

  FunctionDeclaration asFunctionDeclaration() => this;

  accept(Visitor visitor) => visitor.visitFunctionDeclaration(this);

  accept1(Visitor1 visitor, arg) => visitor.visitFunctionDeclaration(this, arg);

  visitChildren(Visitor visitor) => function.accept(visitor);

  visitChildren1(Visitor1 visitor, arg) => function.accept1(visitor, arg);

  Token getBeginToken() => function.getBeginToken();

  @override
  Token getPrefixEndToken() => function.getPrefixEndToken();

  Token getEndToken() => function.getEndToken();
}

/// Node representing the method implementation modifiers `sync*`, `async`, and
/// `async*` or the invalid modifier `sync`.
class AsyncModifier extends Node {
  /// The `async` or `sync` token.
  final Token asyncToken;

  /// The `*` token.
  final Token starToken;

  AsyncModifier(this.asyncToken, this.starToken);

  AsyncModifier asAsyncModifier() => this;

  accept(Visitor visitor) => visitor.visitAsyncModifier(this);

  accept1(Visitor1 visitor, arg) => visitor.visitAsyncModifier(this, arg);

  visitChildren(Visitor visitor) {}

  visitChildren1(Visitor1 visitor, arg) {}

  Token getBeginToken() => asyncToken;

  Token getEndToken() => starToken != null ? starToken : asyncToken;

  /// Is `true` if this modifier is either `async` or `async*`.
  bool get isAsynchronous => asyncToken.lexeme == 'async';

  /// Is `true` if this modifier is either `sync*` or `async*`.
  bool get isYielding => starToken != null;
}

class FunctionExpression extends Expression with StoredTreeElementMixin {
  final Node name;
  final NodeList typeVariables;

  /**
   * List of VariableDefinitions or NodeList.
   *
   * A NodeList can only occur at the end and holds named parameters.
   */
  final NodeList parameters;

  final Statement body;
  final TypeAnnotation returnType;
  final Modifiers modifiers;
  final NodeList initializers;

  final Token getOrSet;
  final AsyncModifier asyncModifier;

  FunctionExpression(
      this.name,
      this.typeVariables,
      this.parameters,
      this.body,
      this.returnType,
      this.modifiers,
      this.initializers,
      this.getOrSet,
      this.asyncModifier) {
    assert(modifiers != null);
  }

  FunctionExpression asFunctionExpression() => this;

  accept(Visitor visitor) => visitor.visitFunctionExpression(this);

  accept1(Visitor1 visitor, arg) => visitor.visitFunctionExpression(this, arg);

  bool get isRedirectingFactory {
    return body != null && body.asRedirectingFactoryBody() != null;
  }

  visitChildren(Visitor visitor) {
    if (modifiers != null) modifiers.accept(visitor);
    if (returnType != null) returnType.accept(visitor);
    if (name != null) name.accept(visitor);
    if (typeVariables != null) typeVariables.accept(visitor);
    if (parameters != null) parameters.accept(visitor);
    if (initializers != null) initializers.accept(visitor);
    if (asyncModifier != null) asyncModifier.accept(visitor);
    if (body != null) body.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (modifiers != null) modifiers.accept1(visitor, arg);
    if (returnType != null) returnType.accept1(visitor, arg);
    if (name != null) name.accept1(visitor, arg);
    if (typeVariables != null) typeVariables.accept1(visitor, arg);
    if (parameters != null) parameters.accept1(visitor, arg);
    if (initializers != null) initializers.accept1(visitor, arg);
    if (asyncModifier != null) asyncModifier.accept1(visitor, arg);
    if (body != null) body.accept1(visitor, arg);
  }

  bool get hasBody => body.asEmptyStatement() == null;

  bool get hasEmptyBody {
    Block block = body.asBlock();
    if (block == null) return false;
    return block.statements.isEmpty;
  }

  Token getBeginToken() {
    Token token = firstBeginToken(modifiers, returnType);
    if (token != null) return token;
    if (getOrSet != null) return getOrSet;
    return firstBeginToken(name, parameters);
  }

  @override
  Token getPrefixEndToken() {
    return parameters != null ? parameters.getEndToken() : name.getEndToken();
  }

  Token getEndToken() {
    Token token = (body == null) ? null : body.getEndToken();
    token = (token == null) ? parameters.getEndToken() : token;
    return (token == null) ? name.getEndToken() : token;
  }
}

typedef void DecodeErrorHandler(Token token, var error);

abstract class Literal<T> extends Expression {
  final Token token;
  final DecodeErrorHandler handler;

  Literal(Token this.token, DecodeErrorHandler this.handler);

  T get value;

  visitChildren(Visitor visitor) {}

  visitChildren1(Visitor1 visitor, arg) {}

  Token getBeginToken() => token;

  Token getEndToken() => token;
}

class LiteralInt extends Literal<int> {
  LiteralInt(Token token, DecodeErrorHandler handler) : super(token, handler);

  LiteralInt asLiteralInt() => this;

  int get value {
    try {
      Token valueToken = token;
      if (identical(valueToken.kind, Tokens.PLUS_TOKEN)) {
        valueToken = valueToken.next;
      }
      return int.parse(valueToken.lexeme);
    } on FormatException catch (ex) {
      throw handler(token, ex);
    }
  }

  accept(Visitor visitor) => visitor.visitLiteralInt(this);

  accept1(Visitor1 visitor, arg) => visitor.visitLiteralInt(this, arg);
}

class LiteralDouble extends Literal<double> {
  LiteralDouble(Token token, DecodeErrorHandler handler)
      : super(token, handler);

  LiteralDouble asLiteralDouble() => this;

  double get value {
    try {
      Token valueToken = token;
      if (identical(valueToken.kind, Tokens.PLUS_TOKEN)) {
        valueToken = valueToken.next;
      }
      return double.parse(valueToken.lexeme);
    } on FormatException catch (ex) {
      throw handler(token, ex);
    }
  }

  accept(Visitor visitor) => visitor.visitLiteralDouble(this);

  accept1(Visitor1 visitor, arg) => visitor.visitLiteralDouble(this, arg);
}

class LiteralBool extends Literal<bool> {
  LiteralBool(Token token, DecodeErrorHandler handler) : super(token, handler);

  LiteralBool asLiteralBool() => this;

  bool get value {
    if (identical(token.stringValue, 'true')) return true;
    if (identical(token.stringValue, 'false')) return false;
    (this.handler)(token, "not a bool ${token.lexeme}");
    throw false;
  }

  accept(Visitor visitor) => visitor.visitLiteralBool(this);

  accept1(Visitor1 visitor, arg) => visitor.visitLiteralBool(this, arg);
}

class StringQuoting {
  /// Cache of common quotings.
  static const List<StringQuoting> _mapping = const <StringQuoting>[
    const StringQuoting($SQ, raw: false, leftQuoteLength: 1),
    const StringQuoting($SQ, raw: true, leftQuoteLength: 1),
    const StringQuoting($DQ, raw: false, leftQuoteLength: 1),
    const StringQuoting($DQ, raw: true, leftQuoteLength: 1),
    // No string quotes with 2 characters.
    null,
    null,
    null,
    null,
    // Multiline quotings.
    const StringQuoting($SQ, raw: false, leftQuoteLength: 3),
    const StringQuoting($SQ, raw: true, leftQuoteLength: 3),
    const StringQuoting($DQ, raw: false, leftQuoteLength: 3),
    const StringQuoting($DQ, raw: true, leftQuoteLength: 3),
    // Leading single whitespace or escaped newline.
    const StringQuoting($SQ, raw: false, leftQuoteLength: 4),
    const StringQuoting($SQ, raw: true, leftQuoteLength: 4),
    const StringQuoting($DQ, raw: false, leftQuoteLength: 4),
    const StringQuoting($DQ, raw: true, leftQuoteLength: 4),
    // Other combinations of leading whitespace and/or escaped newline.
    const StringQuoting($SQ, raw: false, leftQuoteLength: 5),
    const StringQuoting($SQ, raw: true, leftQuoteLength: 5),
    const StringQuoting($DQ, raw: false, leftQuoteLength: 5),
    const StringQuoting($DQ, raw: true, leftQuoteLength: 5),
    const StringQuoting($SQ, raw: false, leftQuoteLength: 6),
    const StringQuoting($SQ, raw: true, leftQuoteLength: 6),
    const StringQuoting($DQ, raw: false, leftQuoteLength: 6),
    const StringQuoting($DQ, raw: true, leftQuoteLength: 6)
  ];

  final bool raw;
  final int leftQuoteCharCount;
  final int quote;
  const StringQuoting(this.quote, {this.raw, int leftQuoteLength})
      : this.leftQuoteCharCount = leftQuoteLength;
  String get quoteChar => identical(quote, $DQ) ? '"' : "'";

  int get leftQuoteLength => (raw ? 1 : 0) + leftQuoteCharCount;
  int get rightQuoteLength => (leftQuoteCharCount > 2) ? 3 : 1;
  static StringQuoting getQuoting(int quote, bool raw, int leftQuoteLength) {
    int quoteKindOffset = (quote == $DQ) ? 2 : 0;
    int rawOffset = raw ? 1 : 0;
    int index = (leftQuoteLength - 1) * 4 + rawOffset + quoteKindOffset;
    if (index < _mapping.length) return _mapping[index];
    return new StringQuoting(quote, raw: raw, leftQuoteLength: leftQuoteLength);
  }
}

/**
  * Superclass for classes representing string literals.
  */
abstract class StringNode extends Expression {
  DartString get dartString;
  bool get isInterpolation;

  StringNode asStringNode() => this;
}

class LiteralString extends StringNode {
  final Token token;
  /** Non-null on validated string literals. */
  final DartString dartString;

  LiteralString(this.token, this.dartString);

  LiteralString asLiteralString() => this;

  bool get isInterpolation => false;

  Token getBeginToken() => token;
  Token getEndToken() => token;

  accept(Visitor visitor) => visitor.visitLiteralString(this);

  accept1(Visitor1 visitor, arg) => visitor.visitLiteralString(this, arg);

  void visitChildren(Visitor visitor) {}

  void visitChildren1(Visitor1 visitor, arg) {}
}

class LiteralNull extends Literal<String> {
  LiteralNull(Token token) : super(token, null);

  LiteralNull asLiteralNull() => this;

  String get value => null;

  accept(Visitor visitor) => visitor.visitLiteralNull(this);

  accept1(Visitor1 visitor, arg) => visitor.visitLiteralNull(this, arg);
}

class LiteralList extends Expression {
  final NodeList typeArguments;
  final NodeList elements;

  final Token constKeyword;

  LiteralList(this.typeArguments, this.elements, this.constKeyword);

  bool get isConst => constKeyword != null;

  LiteralList asLiteralList() => this;
  accept(Visitor visitor) => visitor.visitLiteralList(this);

  accept1(Visitor1 visitor, arg) => visitor.visitLiteralList(this, arg);

  visitChildren(Visitor visitor) {
    if (typeArguments != null) typeArguments.accept(visitor);
    elements.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (typeArguments != null) typeArguments.accept1(visitor, arg);
    elements.accept1(visitor, arg);
  }

  Token getBeginToken() {
    if (constKeyword != null) return constKeyword;
    return firstBeginToken(typeArguments, elements);
  }

  Token getEndToken() => elements.getEndToken();
}

class LiteralSymbol extends Expression {
  final Token hashToken;
  // TODO: this could be a DottedNamed.
  final NodeList identifiers;

  LiteralSymbol(this.hashToken, this.identifiers);

  LiteralSymbol asLiteralSymbol() => this;

  accept(Visitor visitor) => visitor.visitLiteralSymbol(this);

  accept1(Visitor1 visitor, arg) => visitor.visitLiteralSymbol(this, arg);

  void visitChildren(Visitor visitor) {
    if (identifiers != null) identifiers.accept(visitor);
  }

  void visitChildren1(Visitor1 visitor, arg) {
    if (identifiers != null) identifiers.accept1(visitor, arg);
  }

  Token getBeginToken() => hashToken;

  Token getEndToken() => identifiers.getEndToken();

  String get slowNameString {
    Unparser unparser = new Unparser();
    unparser.unparseNodeListOfIdentifiers(identifiers);
    return unparser.result;
  }
}

class Identifier extends Expression with StoredTreeElementMixin {
  final Token token;

  String get source => token.lexeme;

  Identifier(Token this.token);

  bool isThis() => identical(source, 'this');

  bool isSuper() => identical(source, 'super');

  Identifier asIdentifier() => this;

  accept(Visitor visitor) => visitor.visitIdentifier(this);

  accept1(Visitor1 visitor, arg) => visitor.visitIdentifier(this, arg);

  visitChildren(Visitor visitor) {}

  visitChildren1(Visitor1 visitor, arg) {}

  Token getBeginToken() => token;

  Token getEndToken() => token;
}

// TODO(floitsch): a dotted identifier isn't really an expression. Should it
// inherit from Node instead?
class DottedName extends Expression {
  final Token token;
  final NodeList identifiers;

  DottedName(this.token, this.identifiers);

  DottedName asDottedName() => this;

  accept(Visitor visitor) => visitor.visitDottedName(this);

  accept1(Visitor1 visitor, arg) => visitor.visitDottedName(this, arg);

  void visitChildren(Visitor visitor) {
    identifiers.accept(visitor);
  }

  void visitChildren1(Visitor1 visitor, arg) {
    identifiers.accept1(visitor, arg);
  }

  Token getBeginToken() => token;
  Token getEndToken() => identifiers.getEndToken();

  String get slowNameString {
    Unparser unparser = new Unparser();
    unparser.unparseNodeListOfIdentifiers(identifiers);
    return unparser.result;
  }
}

class Operator extends Identifier {
  static const COMPLEX_OPERATORS = const [
    "--",
    "++",
    '+=',
    "-=",
    "*=",
    "/=",
    "%=",
    "&=",
    "|=",
    "~/=",
    "^=",
    ">>=",
    "<<=",
    "??="
  ];

  static const INCREMENT_OPERATORS = const <String>["++", "--"];

  Operator(Token token) : super(token);

  Operator asOperator() => this;

  accept(Visitor visitor) => visitor.visitOperator(this);

  accept1(Visitor1 visitor, arg) => visitor.visitOperator(this, arg);
}

class Return extends Statement {
  final Node expression;
  final Token beginToken;
  final Token endToken;

  Return(this.beginToken, this.endToken, this.expression);

  Return asReturn() => this;

  bool get hasExpression => expression != null;

  /// `true` if this return is of the form `=> e;`.
  bool get isArrowBody => beginToken.type == TokenType.FUNCTION;

  accept(Visitor visitor) => visitor.visitReturn(this);

  accept1(Visitor1 visitor, arg) => visitor.visitReturn(this, arg);

  visitChildren(Visitor visitor) {
    if (expression != null) expression.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (expression != null) expression.accept1(visitor, arg);
  }

  Token getBeginToken() => beginToken;

  Token getEndToken() {
    if (endToken == null) return expression.getEndToken();
    return endToken;
  }
}

class Yield extends Statement {
  final Node expression;
  final Token yieldToken;
  final Token starToken;
  final Token endToken;

  Yield(this.yieldToken, this.starToken, this.expression, this.endToken);

  Yield asYield() => this;

  bool get hasStar => starToken != null;

  accept(Visitor visitor) => visitor.visitYield(this);

  accept1(Visitor1 visitor, arg) => visitor.visitYield(this, arg);

  visitChildren(Visitor visitor) {
    expression.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    expression.accept1(visitor, arg);
  }

  Token getBeginToken() => yieldToken;

  Token getEndToken() => endToken;
}

class RedirectingFactoryBody extends Statement with StoredTreeElementMixin {
  final Node constructorReference;
  final Token beginToken;
  final Token endToken;

  RedirectingFactoryBody(
      this.beginToken, this.endToken, this.constructorReference);

  RedirectingFactoryBody asRedirectingFactoryBody() => this;

  accept(Visitor visitor) => visitor.visitRedirectingFactoryBody(this);

  accept1(Visitor1 visitor, arg) {
    return visitor.visitRedirectingFactoryBody(this, arg);
  }

  visitChildren(Visitor visitor) {
    constructorReference.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    constructorReference.accept1(visitor, arg);
  }

  Token getBeginToken() => beginToken;

  Token getEndToken() => endToken;
}

class ExpressionStatement extends Statement {
  final Expression expression;
  final Token endToken;

  ExpressionStatement(this.expression, this.endToken);

  ExpressionStatement asExpressionStatement() => this;

  accept(Visitor visitor) => visitor.visitExpressionStatement(this);

  accept1(Visitor1 visitor, arg) => visitor.visitExpressionStatement(this, arg);

  visitChildren(Visitor visitor) {
    if (expression != null) expression.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (expression != null) expression.accept1(visitor, arg);
  }

  Token getBeginToken() => expression.getBeginToken();

  Token getEndToken() => endToken;
}

class Throw extends Expression {
  final Expression expression;

  final Token throwToken;
  final Token endToken;

  Throw(this.expression, this.throwToken, this.endToken);

  Throw asThrow() => this;

  accept(Visitor visitor) => visitor.visitThrow(this);

  accept1(Visitor1 visitor, arg) => visitor.visitThrow(this, arg);

  visitChildren(Visitor visitor) {
    expression.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    expression.accept1(visitor, arg);
  }

  Token getBeginToken() => throwToken;

  Token getEndToken() => endToken;
}

class Await extends Expression {
  final Expression expression;

  final Token awaitToken;

  Await(this.awaitToken, this.expression);

  Await asAwait() => this;

  accept(Visitor visitor) => visitor.visitAwait(this);

  accept1(Visitor1 visitor, arg) => visitor.visitAwait(this, arg);

  visitChildren(Visitor visitor) {
    expression.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    expression.accept1(visitor, arg);
  }

  Token getBeginToken() => awaitToken;

  Token getEndToken() => expression.getEndToken();
}

class Assert extends Statement {
  final Token assertToken;
  final Expression condition;
  /** Message may be `null`. */
  final Expression message;
  final Token semicolonToken;

  Assert(this.assertToken, this.condition, this.message, this.semicolonToken);

  Assert asAssert() => this;

  bool get hasMessage => message != null;

  accept(Visitor visitor) => visitor.visitAssert(this);

  accept1(Visitor1 visitor, arg) => visitor.visitAssert(this, arg);

  visitChildren(Visitor visitor) {
    condition.accept(visitor);
    if (message != null) message.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    condition.accept1(visitor, arg);
    if (message != null) message.accept1(visitor, arg);
  }

  Token getBeginToken() => assertToken;
  Token getEndToken() => semicolonToken;
}

class Rethrow extends Statement {
  final Token throwToken;
  final Token endToken;

  Rethrow(this.throwToken, this.endToken);

  Rethrow asRethrow() => this;

  accept(Visitor visitor) => visitor.visitRethrow(this);

  accept1(Visitor1 visitor, arg) => visitor.visitRethrow(this, arg);

  visitChildren(Visitor visitor) {}

  visitChildren1(Visitor1 visitor, arg) {}

  Token getBeginToken() => throwToken;
  Token getEndToken() => endToken;
}

abstract class TypeAnnotation extends Node {}

class NominalTypeAnnotation extends TypeAnnotation {
  final Expression typeName;
  final NodeList typeArguments;

  NominalTypeAnnotation(this.typeName, this.typeArguments);

  NominalTypeAnnotation asNominalTypeAnnotation() => this;

  accept(Visitor visitor) => visitor.visitNominalTypeAnnotation(this);

  accept1(Visitor1 visitor, arg) {
    return visitor.visitNominalTypeAnnotation(this, arg);
  }

  visitChildren(Visitor visitor) {
    typeName.accept(visitor);
    if (typeArguments != null) typeArguments.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    typeName.accept1(visitor, arg);
    if (typeArguments != null) typeArguments.accept1(visitor, arg);
  }

  Token getBeginToken() => typeName.getBeginToken();

  Token getEndToken() {
    if (typeArguments != null) return typeArguments.getEndToken();
    return typeName.getEndToken();
  }
}

class TypeVariable extends Node {
  final Identifier name;
  final Token extendsOrSuper;
  final TypeAnnotation bound;
  TypeVariable(this.name, this.extendsOrSuper, this.bound);

  accept(Visitor visitor) => visitor.visitTypeVariable(this);

  accept1(Visitor1 visitor, arg) => visitor.visitTypeVariable(this, arg);

  visitChildren(Visitor visitor) {
    name.accept(visitor);
    if (bound != null) {
      bound.accept(visitor);
    }
  }

  visitChildren1(Visitor1 visitor, arg) {
    name.accept1(visitor, arg);
    if (bound != null) {
      bound.accept1(visitor, arg);
    }
  }

  TypeVariable asTypeVariable() => this;

  Token getBeginToken() => name.getBeginToken();

  Token getEndToken() {
    return (bound != null) ? bound.getEndToken() : name.getEndToken();
  }
}

class VariableDefinitions extends Statement {
  final NodeList metadata;
  final TypeAnnotation type;
  final Modifiers modifiers;
  final NodeList definitions;

  VariableDefinitions(this.type, this.modifiers, this.definitions)
      : this.metadata = null {
    assert(modifiers != null);
  }

  // TODO(johnniwinther): Make this its own node type.
  VariableDefinitions.forParameter(
      this.metadata, this.type, this.modifiers, this.definitions) {
    assert(modifiers != null);
  }

  VariableDefinitions asVariableDefinitions() => this;

  accept(Visitor visitor) => visitor.visitVariableDefinitions(this);

  accept1(Visitor1 visitor, arg) => visitor.visitVariableDefinitions(this, arg);

  visitChildren(Visitor visitor) {
    if (metadata != null) metadata.accept(visitor);
    if (type != null) type.accept(visitor);
    if (definitions != null) definitions.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (metadata != null) metadata.accept1(visitor, arg);
    if (type != null) type.accept1(visitor, arg);
    if (definitions != null) definitions.accept1(visitor, arg);
  }

  Token getBeginToken() {
    var token = firstBeginToken(modifiers, type);
    if (token == null) {
      token = definitions.getBeginToken();
    }
    return token;
  }

  Token getEndToken() {
    var result = definitions.getEndToken();
    if (result != null) return result;
    assert(definitions.nodes.length == 1);
    assert(definitions.nodes.last == null);
    return type.getEndToken();
  }
}

abstract class Loop extends Statement {
  Expression get condition;
  final Statement body;

  Loop(this.body);

  bool isValidContinueTarget() => true;
}

class DoWhile extends Loop {
  final Token doKeyword;
  final Token whileKeyword;
  final Token endToken;

  final Expression condition;

  DoWhile(Statement body, Expression this.condition, Token this.doKeyword,
      Token this.whileKeyword, Token this.endToken)
      : super(body);

  DoWhile asDoWhile() => this;

  accept(Visitor visitor) => visitor.visitDoWhile(this);

  accept1(Visitor1 visitor, arg) => visitor.visitDoWhile(this, arg);

  visitChildren(Visitor visitor) {
    if (condition != null) condition.accept(visitor);
    if (body != null) body.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (condition != null) condition.accept1(visitor, arg);
    if (body != null) body.accept1(visitor, arg);
  }

  Token getBeginToken() => doKeyword;

  Token getEndToken() => endToken;
}

class While extends Loop {
  final Token whileKeyword;
  final Expression condition;

  While(Expression this.condition, Statement body, Token this.whileKeyword)
      : super(body);

  While asWhile() => this;

  accept(Visitor visitor) => visitor.visitWhile(this);

  accept1(Visitor1 visitor, arg) => visitor.visitWhile(this, arg);

  visitChildren(Visitor visitor) {
    if (condition != null) condition.accept(visitor);
    if (body != null) body.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (condition != null) condition.accept1(visitor, arg);
    if (body != null) body.accept1(visitor, arg);
  }

  Token getBeginToken() => whileKeyword;

  Token getEndToken() => body.getEndToken();
}

class ParenthesizedExpression extends Expression {
  final Expression expression;
  final BeginToken beginToken;

  ParenthesizedExpression(
      Expression this.expression, BeginToken this.beginToken);

  ParenthesizedExpression asParenthesizedExpression() => this;

  accept(Visitor visitor) => visitor.visitParenthesizedExpression(this);

  accept1(Visitor1 visitor, arg) {
    return visitor.visitParenthesizedExpression(this, arg);
  }

  visitChildren(Visitor visitor) {
    if (expression != null) expression.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (expression != null) expression.accept1(visitor, arg);
  }

  Token getBeginToken() => beginToken;

  Token getEndToken() => beginToken.endGroup;
}

/** Representation of modifiers such as static, abstract, final, etc. */
class Modifiers extends Node {
  /**
   * Pseudo-constant for empty modifiers.
   */
  static final Modifiers EMPTY = new Modifiers(new NodeList.empty());

  /* TODO(ahe): The following should be validated relating to modifiers:
   * 1. The nodes must come in a certain order.
   * 2. The keywords "var" and "final" may not be used at the same time.
   * 3. The keywords "abstract" and "external" may not be used at the same time.
   * 4. The type of an element must be null if isVar() is true.
   */

  final NodeList nodes;
  /** Bit pattern to easy check what modifiers are present. */
  final int flags;

  static const int FLAG_STATIC = 1;
  static const int FLAG_ABSTRACT = FLAG_STATIC << 1;
  static const int FLAG_FINAL = FLAG_ABSTRACT << 1;
  static const int FLAG_VAR = FLAG_FINAL << 1;
  static const int FLAG_CONST = FLAG_VAR << 1;
  static const int FLAG_FACTORY = FLAG_CONST << 1;
  static const int FLAG_EXTERNAL = FLAG_FACTORY << 1;
  static const int FLAG_COVARIANT = FLAG_EXTERNAL << 1;

  Modifiers(NodeList nodes) : this.withFlags(nodes, computeFlags(nodes.nodes));

  Modifiers.withFlags(this.nodes, this.flags);

  static int computeFlags(Link<Node> nodes) {
    int flags = 0;
    for (; !nodes.isEmpty; nodes = nodes.tail) {
      String value = nodes.head.asIdentifier().source;
      if (identical(value, 'static'))
        flags |= FLAG_STATIC;
      else if (identical(value, 'abstract'))
        flags |= FLAG_ABSTRACT;
      else if (identical(value, 'final'))
        flags |= FLAG_FINAL;
      else if (identical(value, 'var'))
        flags |= FLAG_VAR;
      else if (identical(value, 'const'))
        flags |= FLAG_CONST;
      else if (identical(value, 'factory'))
        flags |= FLAG_FACTORY;
      else if (identical(value, 'external'))
        flags |= FLAG_EXTERNAL;
      else if (identical(value, 'covariant'))
        flags |= FLAG_COVARIANT;
      else
        throw 'internal error: ${nodes.head}';
    }
    return flags;
  }

  Node findModifier(String modifier) {
    Link<Node> nodeList = nodes.nodes;
    for (; !nodeList.isEmpty; nodeList = nodeList.tail) {
      String value = nodeList.head.asIdentifier().source;
      if (identical(value, modifier)) {
        return nodeList.head;
      }
    }
    return null;
  }

  Modifiers asModifiers() => this;
  Token getBeginToken() => nodes.getBeginToken();
  Token getEndToken() => nodes.getEndToken();

  accept(Visitor visitor) => visitor.visitModifiers(this);

  accept1(Visitor1 visitor, arg) => visitor.visitModifiers(this, arg);

  visitChildren(Visitor visitor) => nodes.accept(visitor);

  visitChildren1(Visitor1 visitor, arg) => nodes.accept1(visitor, arg);

  bool get isStatic => (flags & FLAG_STATIC) != 0;
  bool get isAbstract => (flags & FLAG_ABSTRACT) != 0;
  bool get isFinal => (flags & FLAG_FINAL) != 0;
  bool get isVar => (flags & FLAG_VAR) != 0;
  bool get isConst => (flags & FLAG_CONST) != 0;
  bool get isFactory => (flags & FLAG_FACTORY) != 0;
  bool get isExternal => (flags & FLAG_EXTERNAL) != 0;
  bool get isCovariant => (flags & FLAG_COVARIANT) != 0;

  Node getStatic() => findModifier('static');

  /**
   * Use this to check if the declaration is either explicitly or implicitly
   * final.
   */
  bool get isFinalOrConst => isFinal || isConst;

  String toString() {
    return modifiersToString(
        isStatic: isStatic,
        isAbstract: isAbstract,
        isFinal: isFinal,
        isVar: isVar,
        isConst: isConst,
        isFactory: isFactory,
        isExternal: isExternal,
        isCovariant: isCovariant);
  }
}

class StringInterpolation extends StringNode {
  final LiteralString string;
  final NodeList parts;

  StringInterpolation(this.string, this.parts);

  StringInterpolation asStringInterpolation() => this;

  DartString get dartString => null;
  bool get isInterpolation => true;

  accept(Visitor visitor) => visitor.visitStringInterpolation(this);

  accept1(Visitor1 visitor, arg) => visitor.visitStringInterpolation(this, arg);

  visitChildren(Visitor visitor) {
    string.accept(visitor);
    parts.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    string.accept1(visitor, arg);
    parts.accept1(visitor, arg);
  }

  Token getBeginToken() => string.getBeginToken();
  Token getEndToken() => parts.getEndToken();
}

class StringInterpolationPart extends Node {
  final Expression expression;
  final LiteralString string;

  StringInterpolationPart(this.expression, this.string);

  StringInterpolationPart asStringInterpolationPart() => this;

  accept(Visitor visitor) => visitor.visitStringInterpolationPart(this);

  accept1(Visitor1 visitor, arg) {
    return visitor.visitStringInterpolationPart(this, arg);
  }

  visitChildren(Visitor visitor) {
    expression.accept(visitor);
    string.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    expression.accept1(visitor, arg);
    string.accept1(visitor, arg);
  }

  Token getBeginToken() => expression.getBeginToken();

  Token getEndToken() => string.getEndToken();
}

/**
 * A class representing juxtaposed string literals.
 * The string literals can be both plain literals and string interpolations.
 */
class StringJuxtaposition extends StringNode {
  final Expression first;
  final Expression second;

  /**
   * Caches the check for whether this juxtaposition contains a string
   * interpolation
   */
  bool isInterpolationCache = null;

  /**
   * Caches a Dart string representation of the entire juxtaposition's
   * content. Only juxtapositions that don't (transitively) contains
   * interpolations have a static representation.
   */
  DartString dartStringCache = null;

  StringJuxtaposition(this.first, this.second);

  StringJuxtaposition asStringJuxtaposition() => this;

  bool get isInterpolation {
    if (isInterpolationCache == null) {
      isInterpolationCache = (first.accept(const IsInterpolationVisitor()) ||
          second.accept(const IsInterpolationVisitor()));
    }
    return isInterpolationCache;
  }

  /**
   * Retrieve a single DartString that represents this entire juxtaposition
   * of string literals.
   * Should only be called if [isInterpolation] returns false.
   */
  DartString get dartString {
    if (isInterpolation) {
      failedAt(this, "Getting dartString on interpolation;");
    }
    if (dartStringCache == null) {
      DartString firstString = first.accept(const GetDartStringVisitor());
      DartString secondString = second.accept(const GetDartStringVisitor());
      if (firstString == null || secondString == null) {
        return null;
      }
      dartStringCache = new DartString.concat(firstString, secondString);
    }
    return dartStringCache;
  }

  accept(Visitor visitor) => visitor.visitStringJuxtaposition(this);

  accept1(Visitor1 visitor, arg) => visitor.visitStringJuxtaposition(this, arg);

  void visitChildren(Visitor visitor) {
    first.accept(visitor);
    second.accept(visitor);
  }

  void visitChildren1(Visitor1 visitor, arg) {
    first.accept1(visitor, arg);
    second.accept1(visitor, arg);
  }

  Token getBeginToken() => first.getBeginToken();

  Token getEndToken() => second.getEndToken();
}

class EmptyStatement extends Statement {
  final Token semicolonToken;

  EmptyStatement(this.semicolonToken);

  EmptyStatement asEmptyStatement() => this;

  accept(Visitor visitor) => visitor.visitEmptyStatement(this);

  accept1(Visitor1 visitor, arg) => visitor.visitEmptyStatement(this, arg);

  visitChildren(Visitor visitor) {}

  visitChildren1(Visitor1 visitor, arg) {}

  Token getBeginToken() => semicolonToken;

  Token getEndToken() => semicolonToken;
}

class LiteralMap extends Expression {
  final NodeList typeArguments;
  final NodeList entries;

  final Token constKeyword;

  LiteralMap(this.typeArguments, this.entries, this.constKeyword);

  bool get isConst => constKeyword != null;

  LiteralMap asLiteralMap() => this;

  accept(Visitor visitor) => visitor.visitLiteralMap(this);

  accept1(Visitor1 visitor, arg) => visitor.visitLiteralMap(this, arg);

  visitChildren(Visitor visitor) {
    if (typeArguments != null) typeArguments.accept(visitor);
    entries.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (typeArguments != null) typeArguments.accept1(visitor, arg);
    entries.accept1(visitor, arg);
  }

  Token getBeginToken() {
    if (constKeyword != null) return constKeyword;
    return firstBeginToken(typeArguments, entries);
  }

  Token getEndToken() => entries.getEndToken();
}

class LiteralMapEntry extends Node {
  final Expression key;
  final Expression value;

  final Token colonToken;

  LiteralMapEntry(this.key, this.colonToken, this.value);

  LiteralMapEntry asLiteralMapEntry() => this;

  accept(Visitor visitor) => visitor.visitLiteralMapEntry(this);

  accept1(Visitor1 visitor, arg) => visitor.visitLiteralMapEntry(this, arg);

  visitChildren(Visitor visitor) {
    key.accept(visitor);
    value.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    key.accept1(visitor, arg);
    value.accept1(visitor, arg);
  }

  Token getBeginToken() => key.getBeginToken();

  Token getEndToken() => value.getEndToken();
}

class NamedArgument extends Expression {
  final Identifier name;
  final Expression expression;

  final Token colonToken;

  NamedArgument(this.name, this.colonToken, this.expression);

  NamedArgument asNamedArgument() => this;

  accept(Visitor visitor) => visitor.visitNamedArgument(this);

  accept1(Visitor1 visitor, arg) => visitor.visitNamedArgument(this, arg);

  visitChildren(Visitor visitor) {
    name.accept(visitor);
    expression.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    name.accept1(visitor, arg);
    expression.accept1(visitor, arg);
  }

  Token getBeginToken() => name.getBeginToken();

  Token getEndToken() => expression.getEndToken();
}

class SwitchStatement extends Statement {
  final ParenthesizedExpression parenthesizedExpression;
  final NodeList cases;

  final Token switchKeyword;

  SwitchStatement(this.parenthesizedExpression, this.cases, this.switchKeyword);

  SwitchStatement asSwitchStatement() => this;

  Expression get expression => parenthesizedExpression.expression;

  accept(Visitor visitor) => visitor.visitSwitchStatement(this);

  accept1(Visitor1 visitor, arg) => visitor.visitSwitchStatement(this, arg);

  visitChildren(Visitor visitor) {
    parenthesizedExpression.accept(visitor);
    cases.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    parenthesizedExpression.accept1(visitor, arg);
    cases.accept1(visitor, arg);
  }

  Token getBeginToken() => switchKeyword;

  Token getEndToken() => cases.getEndToken();
}

class CaseMatch extends Node {
  final Token caseKeyword;
  final Expression expression;
  final Token colonToken;
  CaseMatch(this.caseKeyword, this.expression, this.colonToken);

  CaseMatch asCaseMatch() => this;
  Token getBeginToken() => caseKeyword;
  Token getEndToken() => colonToken;

  accept(Visitor visitor) => visitor.visitCaseMatch(this);

  accept1(Visitor1 visitor, arg) => visitor.visitCaseMatch(this, arg);

  visitChildren(Visitor visitor) => expression.accept(visitor);

  visitChildren1(Visitor1 visitor, arg) => expression.accept1(visitor, arg);
}

class SwitchCase extends Node {
  // The labels and case patterns are collected in [labelsAndCases].
  // The default keyword, if present, is collected in [defaultKeyword].
  // Any actual switch case must have at least one 'case' or 'default'
  // clause.
  // Notice: The labels and cases can occur interleaved in the source.
  // They are separated here, since the order is irrelevant to the meaning
  // of the switch.

  /** List of [Label] and [CaseMatch] nodes. */
  final NodeList labelsAndCases;
  /** A "default" keyword token, if applicable. */
  final Token defaultKeyword;
  /** List of statements, the body of the case. */
  final NodeList statements;

  final Token startToken;

  SwitchCase(this.labelsAndCases, this.defaultKeyword, this.statements,
      this.startToken);

  SwitchCase asSwitchCase() => this;

  bool get isDefaultCase => defaultKeyword != null;

  bool isValidContinueTarget() => true;

  accept(Visitor visitor) => visitor.visitSwitchCase(this);

  accept1(Visitor1 visitor, arg) => visitor.visitSwitchCase(this, arg);

  visitChildren(Visitor visitor) {
    labelsAndCases.accept(visitor);
    statements.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    labelsAndCases.accept1(visitor, arg);
    statements.accept1(visitor, arg);
  }

  Token getBeginToken() {
    return startToken;
  }

  Token getEndToken() {
    if (statements.nodes.isEmpty) {
      // All cases must have at least one expression or be the default.
      if (defaultKeyword != null) {
        // The colon after 'default'.
        return defaultKeyword.next;
      }
      // The colon after the last expression.
      return labelsAndCases.getEndToken();
    } else {
      return statements.getEndToken();
    }
  }
}

abstract class GotoStatement extends Statement {
  final Identifier target;
  final Token keywordToken;
  final Token semicolonToken;

  GotoStatement(this.target, this.keywordToken, this.semicolonToken);

  visitChildren(Visitor visitor) {
    if (target != null) target.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (target != null) target.accept1(visitor, arg);
  }

  Token getBeginToken() => keywordToken;

  Token getEndToken() => semicolonToken;

  // TODO(ahe): make class abstract instead of adding an abstract method.
  accept(Visitor visitor);
}

class BreakStatement extends GotoStatement {
  BreakStatement(Identifier target, Token keywordToken, Token semicolonToken)
      : super(target, keywordToken, semicolonToken);

  BreakStatement asBreakStatement() => this;

  accept(Visitor visitor) => visitor.visitBreakStatement(this);

  accept1(Visitor1 visitor, arg) => visitor.visitBreakStatement(this, arg);
}

class ContinueStatement extends GotoStatement {
  ContinueStatement(Identifier target, Token keywordToken, Token semicolonToken)
      : super(target, keywordToken, semicolonToken);

  ContinueStatement asContinueStatement() => this;

  accept(Visitor visitor) => visitor.visitContinueStatement(this);

  accept1(Visitor1 visitor, arg) => visitor.visitContinueStatement(this, arg);
}

abstract class ForIn extends Loop {
  final Node declaredIdentifier;
  final Expression expression;

  final Token forToken;
  final Token inToken;

  ForIn(this.declaredIdentifier, this.expression, Statement body, this.forToken,
      this.inToken)
      : super(body);

  Expression get condition => null;

  ForIn asForIn() => this;

  Token getEndToken() => body.getEndToken();
}

class SyncForIn extends ForIn with StoredTreeElementMixin {
  SyncForIn(declaredIdentifier, expression, Statement body, forToken, inToken)
      : super(declaredIdentifier, expression, body, forToken, inToken);

  SyncForIn asSyncForIn() => this;

  accept(Visitor visitor) => visitor.visitSyncForIn(this);

  accept1(Visitor1 visitor, arg) => visitor.visitSyncForIn(this, arg);

  visitChildren(Visitor visitor) {
    declaredIdentifier.accept(visitor);
    expression.accept(visitor);
    body.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    declaredIdentifier.accept1(visitor, arg);
    expression.accept1(visitor, arg);
    body.accept1(visitor, arg);
  }

  Token getBeginToken() => forToken;
}

class AsyncForIn extends ForIn with StoredTreeElementMixin {
  final Token awaitToken;

  AsyncForIn(declaredIdentifier, expression, Statement body, this.awaitToken,
      forToken, inToken)
      : super(declaredIdentifier, expression, body, forToken, inToken);

  AsyncForIn asAsyncForIn() => this;

  accept(Visitor visitor) => visitor.visitAsyncForIn(this);

  accept1(Visitor1 visitor, arg) => visitor.visitAsyncForIn(this, arg);

  visitChildren(Visitor visitor) {
    declaredIdentifier.accept(visitor);
    expression.accept(visitor);
    body.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    declaredIdentifier.accept1(visitor, arg);
    expression.accept1(visitor, arg);
    body.accept1(visitor, arg);
  }

  Token getBeginToken() => awaitToken;
}

class Label extends Node {
  final Identifier identifier;
  final Token colonToken;

  Label(this.identifier, this.colonToken);

  String get labelName => identifier.source;

  Label asLabel() => this;

  accept(Visitor visitor) => visitor.visitLabel(this);

  accept1(Visitor1 visitor, arg) => visitor.visitLabel(this, arg);

  void visitChildren(Visitor visitor) {
    identifier.accept(visitor);
  }

  void visitChildren1(Visitor1 visitor, arg) {
    identifier.accept1(visitor, arg);
  }

  Token getBeginToken() => identifier.token;
  Token getEndToken() => colonToken;
}

class LabeledStatement extends Statement {
  final NodeList labels;
  final Statement statement;

  LabeledStatement(this.labels, this.statement);

  LabeledStatement asLabeledStatement() => this;

  accept(Visitor visitor) => visitor.visitLabeledStatement(this);

  accept1(Visitor1 visitor, arg) => visitor.visitLabeledStatement(this, arg);

  visitChildren(Visitor visitor) {
    labels.accept(visitor);
    statement.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    labels.accept1(visitor, arg);
    statement.accept1(visitor, arg);
  }

  Token getBeginToken() => labels.getBeginToken();

  Token getEndToken() => statement.getEndToken();

  bool isValidContinueTarget() => statement.isValidContinueTarget();
}

abstract class LibraryTag extends Node {
  final List<MetadataAnnotation> metadata;

  LibraryTag(this.metadata);

  bool get isLibraryName => false;
  bool get isImport => false;
  bool get isExport => false;
  bool get isPart => false;
  bool get isPartOf => false;
}

class LibraryName extends LibraryTag {
  final Expression name;

  final Token libraryKeyword;

  LibraryName(this.libraryKeyword, this.name, List<MetadataAnnotation> metadata)
      : super(metadata);

  bool get isLibraryName => true;

  LibraryName asLibraryName() => this;

  accept(Visitor visitor) => visitor.visitLibraryName(this);

  accept1(Visitor1 visitor, arg) => visitor.visitLibraryName(this, arg);

  visitChildren(Visitor visitor) => name.accept(visitor);

  visitChildren1(Visitor1 visitor, arg) => name.accept1(visitor, arg);

  Token getBeginToken() => libraryKeyword;

  Token getEndToken() => name.getEndToken().next;
}

/**
 * This tag describes a dependency between one library and the exported
 * identifiers of another library. The other library is specified by the [uri].
 * Combinators filter away some identifiers from the other library.
 */
abstract class LibraryDependency extends LibraryTag {
  final StringNode uri;
  final NodeList conditionalUris;
  final NodeList combinators;

  LibraryDependency(this.uri, this.conditionalUris, this.combinators,
      List<MetadataAnnotation> metadata)
      : super(metadata);

  LibraryDependency asLibraryDependency() => this;

  bool get hasConditionalUris => conditionalUris != null;
}

/**
 * An [:import:] library tag.
 *
 * An import tag is dependency on another library where the exported identifiers
 * are put into the import scope of the importing library. The import scope is
 * only visible inside the library.
 */
class Import extends LibraryDependency {
  final Identifier prefix;
  final Token importKeyword;
  final bool isDeferred;

  Import(this.importKeyword, StringNode uri, NodeList conditionalUris,
      this.prefix, NodeList combinators, List<MetadataAnnotation> metadata,
      {this.isDeferred})
      : super(uri, conditionalUris, combinators, metadata);

  bool get isImport => true;

  Import asImport() => this;

  accept(Visitor visitor) => visitor.visitImport(this);

  accept1(Visitor1 visitor, arg) => visitor.visitImport(this, arg);

  visitChildren(Visitor visitor) {
    uri.accept(visitor);
    if (prefix != null) prefix.accept(visitor);
    if (combinators != null) combinators.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    uri.accept1(visitor, arg);
    if (prefix != null) prefix.accept1(visitor, arg);
    if (combinators != null) combinators.accept1(visitor, arg);
  }

  Token getBeginToken() => importKeyword;

  Token getEndToken() {
    if (combinators != null) return combinators.getEndToken().next;
    if (prefix != null) return prefix.getEndToken().next;
    if (conditionalUris != null) return conditionalUris.getEndToken().next;
    return uri.getEndToken().next;
  }
}

/**
 * A conditional uri inside an import or export clause.
 *
 * Example:
 *
 *     import 'foo.dart'
 *       if (some.condition == "someValue") 'bar.dart'
 *       if (other.condition) 'gee.dart';
 */
class ConditionalUri extends Node {
  final Token ifToken;
  final DottedName key;
  // Value may be null.
  final LiteralString value;
  final StringNode uri;

  ConditionalUri(this.ifToken, this.key, this.value, this.uri);

  ConditionalUri asConditionalUri() => this;

  accept(Visitor visitor) => visitor.visitConditionalUri(this);

  accept1(Visitor1 visitor, arg) => visitor.visitConditionalUri(this, arg);

  visitChildren(Visitor visitor) {
    key.accept(visitor);
    if (value != null) value.accept(visitor);
    uri.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    key.accept1(visitor, arg);
    if (value != null) value.accept1(visitor, arg);
    uri.accept1(visitor, arg);
  }

  Token getBeginToken() => ifToken;

  Token getEndToken() => uri.getEndToken();
}

/**
 * An `enum` declaration.
 *
 * An `enum` defines a number of named constants inside a non-extensible class
 */
class Enum extends Node {
  /** The name of the enum class. */
  final Identifier name;
  /** The names of the enum constants. */
  final NodeList names;
  final Token enumToken;

  Enum(this.enumToken, this.name, this.names);

  Enum asEnum() => this;

  accept(Visitor visitor) => visitor.visitEnum(this);

  accept1(Visitor1 visitor, arg) => visitor.visitEnum(this, arg);

  visitChildren(Visitor visitor) {
    name.accept(visitor);
    if (names != null) names.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    name.accept1(visitor, arg);
    if (names != null) names.accept1(visitor, arg);
  }

  Token getBeginToken() => enumToken;
  Token getEndToken() => names.getEndToken();
}

/**
 * An [:export:] library tag.
 *
 * An export tag is dependency on another library where the exported identifiers
 * are put into the export scope of the exporting library. The export scope is
 * not visible inside the library.
 */
class Export extends LibraryDependency {
  final Token exportKeyword;

  Export(this.exportKeyword, StringNode uri, NodeList conditionalUris,
      NodeList combinators, List<MetadataAnnotation> metadata)
      : super(uri, conditionalUris, combinators, metadata);

  bool get isExport => true;

  Export asExport() => this;

  accept(Visitor visitor) => visitor.visitExport(this);

  accept1(Visitor1 visitor, arg) => visitor.visitExport(this, arg);

  visitChildren(Visitor visitor) {
    uri.accept(visitor);
    if (combinators != null) combinators.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    uri.accept1(visitor, arg);
    if (combinators != null) combinators.accept1(visitor, arg);
  }

  Token getBeginToken() => exportKeyword;

  Token getEndToken() {
    if (combinators != null) return combinators.getEndToken().next;
    if (conditionalUris != null) return conditionalUris.getEndToken().next;
    return uri.getEndToken().next;
  }
}

class Part extends LibraryTag {
  final StringNode uri;

  final Token partKeyword;

  Part(this.partKeyword, this.uri, List<MetadataAnnotation> metadata)
      : super(metadata);

  bool get isPart => true;

  Part asPart() => this;

  accept(Visitor visitor) => visitor.visitPart(this);

  accept1(Visitor1 visitor, arg) => visitor.visitPart(this, arg);

  visitChildren(Visitor visitor) => uri.accept(visitor);

  visitChildren1(Visitor1 visitor, arg) => uri.accept1(visitor, arg);

  Token getBeginToken() => partKeyword;

  Token getEndToken() => uri.getEndToken().next;
}

class PartOf extends Node {
  final Expression name;

  final Token partKeyword;

  final List<MetadataAnnotation> metadata;

  PartOf(this.partKeyword, this.name, this.metadata);

  Token get ofKeyword => partKeyword.next;

  bool get isPartOf => true;

  PartOf asPartOf() => this;

  accept(Visitor visitor) => visitor.visitPartOf(this);

  accept1(Visitor1 visitor, arg) => visitor.visitPartOf(this, arg);

  visitChildren(Visitor visitor) => name.accept(visitor);

  visitChildren1(Visitor1 visitor, arg) => name.accept1(visitor, arg);

  Token getBeginToken() => partKeyword;

  Token getEndToken() => name.getEndToken().next;
}

class Combinator extends Node {
  final NodeList identifiers;

  final Token keywordToken;

  Combinator(this.identifiers, this.keywordToken);

  bool get isShow => identical(keywordToken.stringValue, 'show');

  bool get isHide => identical(keywordToken.stringValue, 'hide');

  Combinator asCombinator() => this;

  accept(Visitor visitor) => visitor.visitCombinator(this);

  accept1(Visitor1 visitor, arg) => visitor.visitCombinator(this, arg);

  visitChildren(Visitor visitor) => identifiers.accept(visitor);

  visitChildren1(Visitor1 visitor, arg) => identifiers.accept1(visitor, arg);

  Token getBeginToken() => keywordToken;

  Token getEndToken() => identifiers.getEndToken();
}

class Typedef extends Node {
  final bool isGeneralizedTypeAlias;

  /// Parameters to the template.
  ///
  /// For example, `T` and `S` are template parameters in the following
  /// typedef: `typedef F<S, T> = Function(S, T)`, or, in the inlined syntax,
  /// `typedef F<S, T>(S x, T y)`.
  final NodeList templateParameters;

  final TypeAnnotation returnType;
  final Identifier name;

  /// The generic type parameters to the function type.
  ///
  /// For example `A` and `B` (but not `T`) are type parameters in
  /// `typedef F<T> = Function<A, B>(A, B, T)`;
  final NodeList typeParameters;
  final NodeList formals;

  final Token typedefKeyword;
  final Token endToken;

  Typedef(
      this.isGeneralizedTypeAlias,
      this.templateParameters,
      this.returnType,
      this.name,
      this.typeParameters,
      this.formals,
      this.typedefKeyword,
      this.endToken);

  Typedef asTypedef() => this;

  accept(Visitor visitor) => visitor.visitTypedef(this);

  accept1(Visitor1 visitor, arg) => visitor.visitTypedef(this, arg);

  visitChildren(Visitor visitor) {
    if (templateParameters != null) templateParameters.accept(visitor);
    if (returnType != null) returnType.accept(visitor);
    name.accept(visitor);
    if (typeParameters != null) typeParameters.accept(visitor);
    formals.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (templateParameters != null) templateParameters.accept1(visitor, arg);
    if (returnType != null) returnType.accept1(visitor, arg);
    name.accept1(visitor, arg);
    if (typeParameters != null) typeParameters.accept1(visitor, arg);
    formals.accept1(visitor, arg);
  }

  Token getBeginToken() => typedefKeyword;

  Token getEndToken() => endToken;
}

class FunctionTypeAnnotation extends TypeAnnotation {
  final TypeAnnotation returnType;
  final Token functionToken;
  final NodeList typeParameters;
  final NodeList formals;

  FunctionTypeAnnotation(
      this.returnType, this.functionToken, this.typeParameters, this.formals);

  FunctionTypeAnnotation asFunctionTypeAnnotation() => this;

  accept(Visitor visitor) => visitor.visitFunctionTypeAnnotation(this);

  accept1(Visitor1 visitor, arg) {
    return visitor.visitFunctionTypeAnnotation(this, arg);
  }

  visitChildren(Visitor visitor) {
    if (returnType != null) returnType.accept(visitor);
    if (typeParameters != null) typeParameters.accept(visitor);
    formals.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (returnType != null) returnType.accept1(visitor, arg);
    if (typeParameters != null) typeParameters.accept1(visitor, arg);
    formals.accept1(visitor, arg);
  }

  Token getBeginToken() {
    if (returnType != null) return returnType.getBeginToken();
    return functionToken;
  }

  Token getEndToken() => formals.getEndToken();
}

class TryStatement extends Statement {
  final Block tryBlock;
  final NodeList catchBlocks;
  final Block finallyBlock;

  final Token tryKeyword;
  final Token finallyKeyword;

  TryStatement(this.tryBlock, this.catchBlocks, this.finallyBlock,
      this.tryKeyword, this.finallyKeyword);

  TryStatement asTryStatement() => this;

  accept(Visitor visitor) => visitor.visitTryStatement(this);

  accept1(Visitor1 visitor, arg) => visitor.visitTryStatement(this, arg);

  visitChildren(Visitor visitor) {
    tryBlock.accept(visitor);
    catchBlocks.accept(visitor);
    if (finallyBlock != null) finallyBlock.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    tryBlock.accept1(visitor, arg);
    catchBlocks.accept1(visitor, arg);
    if (finallyBlock != null) finallyBlock.accept1(visitor, arg);
  }

  Token getBeginToken() => tryKeyword;

  Token getEndToken() {
    if (finallyBlock != null) return finallyBlock.getEndToken();
    if (!catchBlocks.isEmpty) return catchBlocks.getEndToken();
    return tryBlock.getEndToken();
  }
}

class Cascade extends Expression {
  final Expression expression;
  Cascade(this.expression);

  Cascade asCascade() => this;
  accept(Visitor visitor) => visitor.visitCascade(this);

  accept1(Visitor1 visitor, arg) => visitor.visitCascade(this, arg);

  void visitChildren(Visitor visitor) {
    expression.accept(visitor);
  }

  void visitChildren1(Visitor1 visitor, arg) {
    expression.accept1(visitor, arg);
  }

  Token getBeginToken() => expression.getBeginToken();

  Token getEndToken() => expression.getEndToken();
}

class CascadeReceiver extends Expression {
  final Expression expression;
  final Token cascadeOperator;
  CascadeReceiver(this.expression, this.cascadeOperator);

  CascadeReceiver asCascadeReceiver() => this;
  accept(Visitor visitor) => visitor.visitCascadeReceiver(this);

  accept1(Visitor1 visitor, arg) => visitor.visitCascadeReceiver(this, arg);

  void visitChildren(Visitor visitor) {
    expression.accept(visitor);
  }

  void visitChildren1(Visitor1 visitor, arg) {
    expression.accept1(visitor, arg);
  }

  Token getBeginToken() => expression.getBeginToken();

  Token getEndToken() => expression.getEndToken();
}

class CatchBlock extends Node {
  final TypeAnnotation type;
  final NodeList formals;
  final Block block;

  final Token onKeyword;
  final Token catchKeyword;

  CatchBlock(
      this.type, this.formals, this.block, this.onKeyword, this.catchKeyword);

  CatchBlock asCatchBlock() => this;

  accept(Visitor visitor) => visitor.visitCatchBlock(this);

  accept1(Visitor1 visitor, arg) => visitor.visitCatchBlock(this, arg);

  Node get exception {
    if (formals == null || formals.nodes.isEmpty) return null;
    VariableDefinitions declarations = formals.nodes.head;
    return declarations.definitions.nodes.head;
  }

  Node get trace {
    if (formals == null || formals.nodes.isEmpty) return null;
    Link<Node> declarations = formals.nodes.tail;
    if (declarations.isEmpty) return null;
    VariableDefinitions head = declarations.head;
    return head.definitions.nodes.head;
  }

  visitChildren(Visitor visitor) {
    if (type != null) type.accept(visitor);
    if (formals != null) formals.accept(visitor);
    block.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    if (type != null) type.accept1(visitor, arg);
    if (formals != null) formals.accept1(visitor, arg);
    block.accept1(visitor, arg);
  }

  Token getBeginToken() => onKeyword != null ? onKeyword : catchKeyword;

  Token getEndToken() => block.getEndToken();
}

class Metadata extends Node {
  final Token token;
  final Expression expression;

  Metadata(this.token, this.expression);

  Metadata asMetadata() => this;

  accept(Visitor visitor) => visitor.visitMetadata(this);

  accept1(Visitor1 visitor, arg) => visitor.visitMetadata(this, arg);

  visitChildren(Visitor visitor) {
    expression.accept(visitor);
  }

  visitChildren1(Visitor1 visitor, arg) {
    expression.accept1(visitor, arg);
  }

  Token getBeginToken() => token;

  Token getEndToken() => expression.getEndToken();
}

class Initializers {
  static bool isSuperConstructorCall(Send node) {
    return (node.receiver == null && node.selector.isSuper()) ||
        (node.receiver != null &&
            node.receiver.isSuper() &&
            !node.isConditional &&
            node.selector.asIdentifier() != null);
  }

  static bool isConstructorRedirect(Send node) {
    return (node.receiver == null && node.selector.isThis()) ||
        (node.receiver != null &&
            node.receiver.isThis() &&
            !node.isConditional &&
            node.selector.asIdentifier() != null);
  }
}

class GetDartStringVisitor extends Visitor<DartString> {
  const GetDartStringVisitor();
  DartString visitNode(Node node) => null;
  DartString visitStringJuxtaposition(StringJuxtaposition node) =>
      node.dartString;
  DartString visitLiteralString(LiteralString node) => node.dartString;
}

class IsInterpolationVisitor extends Visitor<bool> {
  const IsInterpolationVisitor();
  bool visitNode(Node node) => false;
  bool visitStringInterpolation(StringInterpolation node) => true;
  bool visitStringJuxtaposition(StringJuxtaposition node) =>
      node.isInterpolation;
}

/// Erroneous node used to recover from parser errors.  Implements various
/// interfaces and provides bare minimum of implementation to avoid unnecessary
/// messages.
class ErrorNode extends Node
    implements FunctionExpression, VariableDefinitions, Typedef {
  final Token token;
  final Message message;
  final Identifier name;
  final NodeList definitions;

  ErrorNode.internal(this.token, this.message, this.name, this.definitions);

  factory ErrorNode(Token token, Message message) {
    Identifier name = new Identifier(token);
    NodeList definitions =
        new NodeList(null, const Link<Node>().prepend(name), null, null);
    return new ErrorNode.internal(token, message, name, definitions);
  }

  Token get beginToken => token;
  Token get endToken => token;

  Token getBeginToken() => token;

  Token getEndToken() => token;

  accept(Visitor visitor) {}

  accept1(Visitor1 visitor, arg) {}

  visitChildren(Visitor visitor) {}

  visitChildren1(Visitor1 visitor, arg) {}

  bool get isErroneous => true;

  // FunctionExpression.
  get asyncModifier => null;
  get typeVariables => null;
  get parameters => null;
  get body => null;
  get returnType => null;
  get modifiers => Modifiers.EMPTY;
  get initializers => null;
  get getOrSet => null;
  get isRedirectingFactory => false;
  bool get hasBody => false;
  bool get hasEmptyBody => false;

  // VariableDefinitions.
  get metadata => null;
  get type => null;

  // Typedef.
  get isGeneralizedTypeAlias => null;
  get templateParameters => null;
  get typeParameters => null;
  get formals => null;
  get typedefKeyword => null;
}

/**
 * Encapsulates the field [TreeElementMixin._element].
 *
 * This library is an implementation detail of dart2js, and should not
 * be imported except by resolution and tree node libraries, or for
 * testing.
 *
 * We have taken great care to ensure AST nodes can be cached between
 * compiler instances.  Part of this requires that we always access
 * resolution results through TreeElements.
 *
 * So please, do not add additional elements to this library, and do
 * not import it.
 */
/// Interface for associating
abstract class TreeElementMixin {
  Object get _element;
  void set _element(Object value);
}

/// Null implementation of [TreeElementMixin] which does not allow association
/// of elements.
///
/// This class is the superclass of all AST nodes.
abstract class NullTreeElementMixin implements TreeElementMixin, Spannable {
  // Deliberately using [Object] here to thwart code completion.
  // You're not really supposed to access this field anyways.
  Object get _element => null;
  set _element(_) {
    assert(false,
        failedAt(this, "Elements cannot be associated with ${runtimeType}."));
  }
}

/// Actual implementation of [TreeElementMixin] which stores the associated
/// element in the private field [_element].
///
/// This class is mixed into the node classes that are actually associated with
/// elements.
abstract class StoredTreeElementMixin implements TreeElementMixin {
  Object _element;
}

/**
 * Do not call this method directly.  Instead, use an instance of
 * TreeElements.
 *
 * Using [Object] as return type to thwart code completion.
 */
Object getTreeElement(TreeElementMixin node) => node._element;

/**
 * Do not call this method directly.  Instead, use an instance of
 * TreeElements.
 */
void setTreeElement(TreeElementMixin node, Object value) {
  node._element = value;
}
