// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: omit_local_variable_types

library js_ast.nodes;

import 'precedence.dart';
import 'printer.dart';

abstract class NodeVisitor<T> {
  T visitProgram(Program node);

  T visitBlock(Block node);
  T visitDebuggerStatement(DebuggerStatement node);
  T visitExpressionStatement(ExpressionStatement node);
  T visitEmptyStatement(EmptyStatement node);
  T visitIf(If node);
  T visitFor(For node);
  T visitForIn(ForIn node);
  T visitForOf(ForOf node);
  T visitWhile(While node);
  T visitDo(Do node);
  T visitContinue(Continue node);
  T visitBreak(Break node);
  T visitReturn(Return node);
  T visitThrow(Throw node);
  T visitTry(Try node);
  T visitCatch(Catch node);
  T visitSwitch(Switch node);
  T visitCase(Case node);
  T visitDefault(Default node);
  T visitFunctionDeclaration(FunctionDeclaration node);
  T visitLabeledStatement(LabeledStatement node);
  T visitLiteralStatement(LiteralStatement node);
  T visitDartYield(DartYield node);

  T visitLiteralExpression(LiteralExpression node);
  T visitVariableDeclarationList(VariableDeclarationList node);
  T visitAssignment(Assignment node);
  T visitVariableInitialization(VariableInitialization node);
  T visitConditional(Conditional cond);
  T visitNew(New node);
  T visitCall(Call node);
  T visitBinary(Binary node);
  T visitPrefix(Prefix node);
  T visitPostfix(Postfix node);
  T visitSpread(Spread node);
  T visitYield(Yield node);

  T visitIdentifier(Identifier node);
  T visitThis(This node);
  T visitSuper(Super node);
  T visitAccess(PropertyAccess node);
  T visitRestParameter(RestParameter node);

  T visitNamedFunction(NamedFunction node);
  T visitFun(Fun node);
  T visitArrowFun(ArrowFun node);

  T visitLiteralBool(LiteralBool node);
  T visitLiteralString(LiteralString node);
  T visitLiteralNumber(LiteralNumber node);
  T visitLiteralNull(LiteralNull node);

  T visitArrayInitializer(ArrayInitializer node);
  T visitArrayHole(ArrayHole node);
  T visitObjectInitializer(ObjectInitializer node);
  T visitProperty(Property node);
  T visitRegExpLiteral(RegExpLiteral node);
  T visitTemplateString(TemplateString node);
  T visitTaggedTemplate(TaggedTemplate node);

  T visitAwait(Await node);

  T visitClassDeclaration(ClassDeclaration node);
  T visitClassExpression(ClassExpression node);
  T visitMethod(Method node);

  T visitImportDeclaration(ImportDeclaration node);
  T visitExportDeclaration(ExportDeclaration node);
  T visitExportClause(ExportClause node);
  T visitNameSpecifier(NameSpecifier node);

  T visitComment(Comment node);
  T visitCommentExpression(CommentExpression node);

  T visitInterpolatedExpression(InterpolatedExpression node);
  T visitInterpolatedLiteral(InterpolatedLiteral node);
  T visitInterpolatedParameter(InterpolatedParameter node);
  T visitInterpolatedSelector(InterpolatedSelector node);
  T visitInterpolatedStatement(InterpolatedStatement node);
  T visitInterpolatedMethod(InterpolatedMethod node);
  T visitInterpolatedIdentifier(InterpolatedIdentifier node);

  T visitArrayBindingPattern(ArrayBindingPattern node);
  T visitObjectBindingPattern(ObjectBindingPattern node);
  T visitDestructuredVariable(DestructuredVariable node);
  T visitSimpleBindingPattern(SimpleBindingPattern node);
}

abstract class BaseVisitor<T> implements NodeVisitor<T> {
  T visitNode(Node node);
  @override
  T visitProgram(Program node) => visitNode(node);

  T visitStatement(Statement node) => visitModuleItem(node);
  T visitLoop(Loop node) => visitStatement(node);
  T visitJump(Statement node) => visitStatement(node);

  @override
  T visitBlock(Block node) => visitStatement(node);
  @override
  T visitDebuggerStatement(node) => visitStatement(node);
  @override
  T visitExpressionStatement(ExpressionStatement node) => visitStatement(node);
  @override
  T visitEmptyStatement(EmptyStatement node) => visitStatement(node);
  @override
  T visitIf(If node) => visitStatement(node);
  @override
  T visitFor(For node) => visitLoop(node);
  @override
  T visitForIn(ForIn node) => visitLoop(node);
  @override
  T visitForOf(ForOf node) => visitLoop(node);
  @override
  T visitWhile(While node) => visitLoop(node);
  @override
  T visitDo(Do node) => visitLoop(node);
  @override
  T visitContinue(Continue node) => visitJump(node);
  @override
  T visitBreak(Break node) => visitJump(node);
  @override
  T visitReturn(Return node) => visitJump(node);
  @override
  T visitThrow(Throw node) => visitJump(node);
  @override
  T visitTry(Try node) => visitStatement(node);
  @override
  T visitSwitch(Switch node) => visitStatement(node);
  @override
  T visitFunctionDeclaration(FunctionDeclaration node) => visitStatement(node);
  @override
  T visitLabeledStatement(LabeledStatement node) => visitStatement(node);
  @override
  T visitLiteralStatement(LiteralStatement node) => visitStatement(node);

  @override
  T visitCatch(Catch node) => visitNode(node);
  @override
  T visitCase(Case node) => visitNode(node);
  @override
  T visitDefault(Default node) => visitNode(node);

  T visitExpression(Expression node) => visitNode(node);

  @override
  T visitLiteralExpression(LiteralExpression node) => visitExpression(node);
  @override
  T visitVariableDeclarationList(VariableDeclarationList node) =>
      visitExpression(node);
  @override
  T visitAssignment(Assignment node) => visitExpression(node);
  @override
  T visitVariableInitialization(VariableInitialization node) =>
      visitExpression(node);

  @override
  T visitConditional(Conditional node) => visitExpression(node);
  @override
  T visitNew(New node) => visitExpression(node);
  @override
  T visitCall(Call node) => visitExpression(node);
  @override
  T visitBinary(Binary node) => visitExpression(node);
  @override
  T visitPrefix(Prefix node) => visitExpression(node);
  @override
  T visitPostfix(Postfix node) => visitExpression(node);
  @override
  T visitSpread(Spread node) => visitPrefix(node);
  @override
  T visitYield(Yield node) => visitExpression(node);
  @override
  T visitAccess(PropertyAccess node) => visitExpression(node);

  @override
  T visitIdentifier(Identifier node) => visitExpression(node);
  @override
  T visitThis(This node) => visitExpression(node);
  @override
  T visitSuper(Super node) => visitExpression(node);

  @override
  T visitRestParameter(RestParameter node) => visitNode(node);

  @override
  T visitNamedFunction(NamedFunction node) => visitExpression(node);
  T visitFunctionExpression(FunctionExpression node) => visitExpression(node);
  @override
  T visitFun(Fun node) => visitFunctionExpression(node);
  @override
  T visitArrowFun(ArrowFun node) => visitFunctionExpression(node);

  T visitLiteral(Literal node) => visitExpression(node);

  @override
  T visitLiteralBool(LiteralBool node) => visitLiteral(node);
  @override
  T visitLiteralString(LiteralString node) => visitLiteral(node);
  @override
  T visitLiteralNumber(LiteralNumber node) => visitLiteral(node);
  @override
  T visitLiteralNull(LiteralNull node) => visitLiteral(node);

  @override
  T visitArrayInitializer(ArrayInitializer node) => visitExpression(node);
  @override
  T visitArrayHole(ArrayHole node) => visitExpression(node);
  @override
  T visitObjectInitializer(ObjectInitializer node) => visitExpression(node);
  @override
  T visitProperty(Property node) => visitNode(node);
  @override
  T visitRegExpLiteral(RegExpLiteral node) => visitExpression(node);
  @override
  T visitTemplateString(TemplateString node) => visitExpression(node);
  @override
  T visitTaggedTemplate(TaggedTemplate node) => visitExpression(node);

  @override
  T visitClassDeclaration(ClassDeclaration node) => visitStatement(node);
  @override
  T visitClassExpression(ClassExpression node) => visitExpression(node);
  @override
  T visitMethod(Method node) => visitProperty(node);

  T visitModuleItem(ModuleItem node) => visitNode(node);
  @override
  T visitImportDeclaration(ImportDeclaration node) => visitModuleItem(node);
  @override
  T visitExportDeclaration(ExportDeclaration node) => visitModuleItem(node);
  @override
  T visitExportClause(ExportClause node) => visitNode(node);
  @override
  T visitNameSpecifier(NameSpecifier node) => visitNode(node);

  T visitInterpolatedNode(InterpolatedNode node) => visitNode(node);

  @override
  T visitInterpolatedExpression(InterpolatedExpression node) =>
      visitInterpolatedNode(node);
  @override
  T visitInterpolatedLiteral(InterpolatedLiteral node) =>
      visitInterpolatedNode(node);
  @override
  T visitInterpolatedParameter(InterpolatedParameter node) =>
      visitInterpolatedNode(node);
  @override
  T visitInterpolatedSelector(InterpolatedSelector node) =>
      visitInterpolatedNode(node);
  @override
  T visitInterpolatedStatement(InterpolatedStatement node) =>
      visitInterpolatedNode(node);
  @override
  T visitInterpolatedMethod(InterpolatedMethod node) =>
      visitInterpolatedNode(node);
  @override
  T visitInterpolatedIdentifier(InterpolatedIdentifier node) =>
      visitInterpolatedNode(node);

  @override
  T visitComment(Comment node);
  @override
  T visitCommentExpression(CommentExpression node);

  @override
  T visitAwait(Await node) => visitExpression(node);
  @override
  T visitDartYield(DartYield node) => visitStatement(node);

  T visitBindingPattern(BindingPattern node) => visitNode(node);
  @override
  T visitArrayBindingPattern(ArrayBindingPattern node) =>
      visitBindingPattern(node);
  @override
  T visitObjectBindingPattern(ObjectBindingPattern node) =>
      visitBindingPattern(node);
  @override
  T visitDestructuredVariable(DestructuredVariable node) => visitNode(node);
  @override
  T visitSimpleBindingPattern(SimpleBindingPattern node) => visitNode(node);
}

class BaseVisitorVoid extends BaseVisitor<void> {
  @override
  void visitNode(Node node) {
    node.visitChildren(this);
  }

  // Ignore comments by default.
  @override
  void visitComment(Comment node) {}
  @override
  void visitCommentExpression(CommentExpression node) {}
}

abstract class Node {
  /// Sets the source location of this node. For performance reasons, we allow
  /// setting this after construction.
  Object? sourceInformation;

  T accept<T>(NodeVisitor<T> visitor);
  void visitChildren(NodeVisitor visitor);

  /// Shallow clone of node.
  ///
  /// Does not clone positions since the only use of this private method is
  /// create a copy with a new position.
  Node _clone();

  /// Returns a node equivalent to [this], but with new source position and end
  /// source position.
  T _withSourceInformation<T extends Node>(
      sourceInformation, T Function() cloneFunc) {
    if (sourceInformation == this.sourceInformation) {
      return this as T;
    }
    final clone = cloneFunc();
    // TODO(sra): Should existing data be 'sticky' if we try to overwrite with
    // `null`?
    clone.sourceInformation = sourceInformation;
    return clone;
  }

  Node withSourceInformation(sourceInformation) =>
      _withSourceInformation(sourceInformation, _clone);

  bool get isCommaOperator => false;

  Statement toStatement() {
    throw UnsupportedError('toStatement');
  }

  Statement toReturn() {
    throw UnsupportedError('toReturn');
  }

  // For debugging
  @override
  String toString() {
    var context = SimpleJavaScriptPrintingContext();
    var opts = JavaScriptPrintingOptions(allowKeywordsInProperties: true);
    context.buffer.write('js_ast `');
    accept(Printer(opts, context));
    context.buffer.write('`');
    return context.getText();
  }
}

// TODO(jmesserly): rename to Module.
class Program extends Node {
  /// Script tag hash-bang, e.g. `#!/usr/bin/env node`.
  final String? scriptTag;

  /// Top-level statements in the program.
  final List<ModuleItem> body;

  // Top-level comments prepended to the compiled program.
  final List<Comment> header;

  /// The module's own name.
  ///
  /// This is not used in ES6, but is provided to allow module lowering.
  final String? name;

  Program(this.body, {this.scriptTag, this.name, this.header = const []});

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitProgram(this);
  @override
  void visitChildren(NodeVisitor visitor) {
    for (ModuleItem statement in body) {
      statement.accept(visitor);
    }
  }

  @override
  Program _clone() =>
      Program(body, scriptTag: scriptTag, name: name, header: header);
}

abstract class Statement extends ModuleItem {
  static Statement from(List<Statement> statements) {
    // TODO(jmesserly): empty block singleton? Should this use empty statement?
    if (statements.isEmpty) return Block([]);
    if (statements.length == 1) return statements[0];
    return Block(statements);
  }

  /// True if this declares any name from [names].
  ///
  /// This predicate is true if the statement declares a variable via `let` or
  /// `const` with any name in the set.  This does not include variables nested
  /// inside of blocks.  The predicate tests whether adding a declaration of one
  /// of the named variables to a block containing this statement will be a
  /// JavaScript syntax error due to a redeclared identifier.
  bool shadows(Set<String> names) => false;

  /// Whether this statement would always `return` if used as a function body.
  ///
  /// This is only well defined on the outermost block; it cannot be used for a
  /// block inside of a loop (because of `break` and `continue`).
  bool get alwaysReturns => false;

  @override
  Statement _clone();

  @override
  Statement withSourceInformation(Object? sourceInformation) =>
      _withSourceInformation(sourceInformation, _clone);

  /// If this statement [shadows] any name from [names], this will wrap it in a
  /// new scoped [Block].
  Statement toScopedBlock(Set<String> names) {
    return shadows(names) ? Block([this], isScope: true) : this;
  }

  @override
  Statement toStatement() => this;
  @override
  Statement toReturn() => Block([this, Return()]);

  Block toBlock() => Block([this]);
}

class Block extends Statement {
  final List<Statement> statements;

  /// True to preserve this [Block] for scoping reasons.
  final bool isScope;

  Block(this.statements, {this.isScope = false});

  Block.empty()
      : statements = <Statement>[],
        isScope = false;

  @override
  bool get alwaysReturns =>
      statements.isNotEmpty && statements.last.alwaysReturns;

  @override
  Block toBlock() => this;

  @override
  bool shadows(Set<String> names) =>
      !isScope && statements.any((s) => s.shadows(names));

  @override
  Block toScopedBlock(Set<String> names) {
    var scoped = statements.any((s) => s.shadows(names));
    if (scoped == isScope) return this;
    return Block(statements, isScope: scoped)
      ..sourceInformation = sourceInformation;
  }

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitBlock(this);
  @override
  void visitChildren(NodeVisitor visitor) {
    for (Statement statement in statements) {
      statement.accept(visitor);
    }
  }

  @override
  Block _clone() => Block(statements);
}

class ExpressionStatement extends Statement {
  final Expression expression;
  ExpressionStatement(this.expression);

  @override
  bool shadows(Set<String> names) {
    Expression expression = this.expression;
    return expression is VariableDeclarationList && expression.shadows(names);
  }

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitExpressionStatement(this);
  @override
  void visitChildren(NodeVisitor visitor) {
    expression.accept(visitor);
  }

  @override
  ExpressionStatement _clone() => ExpressionStatement(expression);
}

class EmptyStatement extends Statement {
  EmptyStatement();

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitEmptyStatement(this);
  @override
  void visitChildren(NodeVisitor visitor) {}
  @override
  EmptyStatement _clone() => EmptyStatement();
}

class If extends Statement {
  final Expression condition;
  final Statement then;
  final Statement otherwise;

  If(this.condition, this.then, this.otherwise);

  If.noElse(this.condition, this.then) : otherwise = EmptyStatement();

  @override
  bool get alwaysReturns =>
      hasElse && then.alwaysReturns && otherwise.alwaysReturns;

  bool get hasElse => otherwise is! EmptyStatement;

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitIf(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    condition.accept(visitor);
    then.accept(visitor);
    otherwise.accept(visitor);
  }

  @override
  If _clone() => If(condition, then, otherwise);
}

abstract class Loop extends Statement {
  final Statement body;
  Loop(this.body);
}

class For extends Loop {
  final Expression? init;
  final Expression? condition;
  final Expression? update;

  For(this.init, this.condition, this.update, Statement body) : super(body);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitFor(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    init?.accept(visitor);
    condition?.accept(visitor);
    update?.accept(visitor);
    body.accept(visitor);
  }

  @override
  For _clone() => For(init, condition, update, body);
}

class ForIn extends Loop {
  // Note that [VariableDeclarationList] is a subclass of [Expression].
  // Therefore we can type the leftHandSide as [Expression].
  final Expression leftHandSide;
  final Expression object;

  ForIn(this.leftHandSide, this.object, Statement body) : super(body);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitForIn(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    leftHandSide.accept(visitor);
    object.accept(visitor);
    body.accept(visitor);
  }

  @override
  ForIn _clone() => ForIn(leftHandSide, object, body);
}

class ForOf extends Loop {
  // Note that [VariableDeclarationList] is a subclass of [Expression].
  // Therefore we can type the leftHandSide as [Expression].
  final Expression leftHandSide;
  final Expression iterable;

  ForOf(this.leftHandSide, this.iterable, Statement body) : super(body);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitForOf(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    leftHandSide.accept(visitor);
    iterable.accept(visitor);
    body.accept(visitor);
  }

  @override
  ForOf _clone() => ForOf(leftHandSide, iterable, body);
}

class While extends Loop {
  final Expression condition;

  While(this.condition, Statement body) : super(body);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitWhile(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    condition.accept(visitor);
    body.accept(visitor);
  }

  @override
  While _clone() => While(condition, body);
}

class Do extends Loop {
  final Expression condition;

  Do(super.body, this.condition);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitDo(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    body.accept(visitor);
    condition.accept(visitor);
  }

  @override
  Do _clone() => Do(body, condition);
}

class Continue extends Statement {
  /// Name of the label L for `continue L;` or `null` for `continue;`.
  final String? targetLabel;

  Continue(this.targetLabel);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitContinue(this);
  @override
  void visitChildren(NodeVisitor visitor) {}

  @override
  Continue _clone() => Continue(targetLabel);
}

class Break extends Statement {
  /// Name of the label L for `break L;` or `null` for `break;`.
  final String? targetLabel;

  Break(this.targetLabel);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitBreak(this);
  @override
  void visitChildren(NodeVisitor visitor) {}

  @override
  Break _clone() => Break(targetLabel);
}

class Return extends Statement {
  final Expression? value;

  Return([this.value]);

  @override
  bool get alwaysReturns => true;

  @override
  Statement toReturn() => this;

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitReturn(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    value?.accept(visitor);
  }

  @override
  Return _clone() => Return(value);

  static bool foundIn(Node node) {
    _returnFinder.found = false;
    node.accept(_returnFinder);
    return _returnFinder.found;
  }
}

final _returnFinder = _ReturnFinder();

class _ReturnFinder extends BaseVisitorVoid {
  bool found = false;
  @override
  void visitReturn(Return node) {
    found = true;
  }

  @override
  void visitNode(Node node) {
    if (!found) super.visitNode(node);
  }
}

class Throw extends Statement {
  final Expression expression;

  Throw(this.expression);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitThrow(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    expression.accept(visitor);
  }

  @override
  Throw _clone() => Throw(expression);
}

class Try extends Statement {
  final Block body;
  final Catch? catchPart; // Can be null if [finallyPart] is non-null.
  final Block? finallyPart; // Can be null if [catchPart] is non-null.

  Try(this.body, this.catchPart, this.finallyPart) {
    assert(catchPart != null || finallyPart != null);
  }

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitTry(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    body.accept(visitor);
    catchPart?.accept(visitor);
    finallyPart?.accept(visitor);
  }

  @override
  Try _clone() => Try(body, catchPart, finallyPart);
}

class Catch extends Node {
  final Identifier declaration;
  final Block body;

  Catch(this.declaration, this.body);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitCatch(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    declaration.accept(visitor);
    body.accept(visitor);
  }

  @override
  Catch _clone() => Catch(declaration, body);
}

class Switch extends Statement {
  final Expression key;
  final List<SwitchClause> cases;

  Switch(this.key, this.cases);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitSwitch(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    key.accept(visitor);
    for (var clause in cases) {
      clause.accept(visitor);
    }
  }

  @override
  Switch _clone() => Switch(key, cases);
}

abstract class SwitchClause extends Node {
  final Block body;

  SwitchClause(this.body);
}

class Case extends SwitchClause {
  final Expression expression;

  Case(this.expression, Block body) : super(body);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitCase(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    expression.accept(visitor);
    body.accept(visitor);
  }

  @override
  Case _clone() => Case(expression, body);
}

class Default extends SwitchClause {
  Default(super.body);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitDefault(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    body.accept(visitor);
  }

  @override
  Default _clone() => Default(body);
}

class FunctionDeclaration extends Statement {
  final Identifier name;
  final Fun function;

  FunctionDeclaration(this.name, this.function);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitFunctionDeclaration(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    name.accept(visitor);
    function.accept(visitor);
  }

  @override
  FunctionDeclaration _clone() => FunctionDeclaration(name, function);
}

class LabeledStatement extends Statement {
  final String label;
  final Statement body;

  LabeledStatement(this.label, this.body);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLabeledStatement(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    body.accept(visitor);
  }

  @override
  LabeledStatement _clone() => LabeledStatement(label, body);
}

class LiteralStatement extends Statement {
  final String code;

  LiteralStatement(this.code);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralStatement(this);
  @override
  void visitChildren(NodeVisitor visitor) {}

  @override
  LiteralStatement _clone() => LiteralStatement(code);
}

/// Not a real JavaScript node, but represents the yield statement from a dart
/// program translated to JavaScript.
class DartYield extends Statement {
  final Expression expression;

  final bool hasStar;

  DartYield(this.expression, this.hasStar);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitDartYield(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    expression.accept(visitor);
  }

  @override
  DartYield _clone() => DartYield(expression, hasStar);
}

abstract class Expression extends Node {
  Expression();

  factory Expression.binary(List<Expression> exprs, String op) {
    Expression? comma;
    for (var node in exprs) {
      comma = (comma == null) ? node : Binary(op, comma, node);
    }
    return comma!;
  }

  int get precedenceLevel;

  @override
  Statement toStatement() => ExpressionStatement(toVoidExpression());
  @override
  Statement toReturn() => Return(this);

  Expression toVoidExpression() => this;
  Expression toAssignExpression(Expression left, [String? op]) =>
      Assignment.compound(left, op, this);

  // TODO(jmesserly): make this work for more cases?
  Statement toVariableDeclaration(VariableBinding name) =>
      VariableDeclarationList('let', [VariableInitialization(name, this)])
          .toStatement();

  @override
  Expression _clone();

  @override
  Expression withSourceInformation(sourceInformation) =>
      _withSourceInformation(sourceInformation, _clone);
}

class LiteralExpression extends Expression {
  final String template;
  LiteralExpression(this.template);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralExpression(this);

  @override
  void visitChildren(NodeVisitor visitor) {}

  @override
  LiteralExpression _clone() => LiteralExpression(template);

  // Code that uses LiteralExpression must take care of operator precedences,
  // and put parenthesis if needed.
  @override
  int get precedenceLevel => PRIMARY;
}

/// [VariableDeclarationList] is a subclass of [Expression] to simplify the AST.
class VariableDeclarationList extends Expression {
  /// The `var` or `let` or `const` keyword used for this variable declaration
  /// list.
  ///
  /// Can be null in the case of non-static field declarations.
  final String? keyword;
  final List<VariableInitialization> declarations;

  VariableDeclarationList(this.keyword, this.declarations);

  /// True if this declares any name from [names].
  ///
  /// Analogous to the predicate [Statement.shadows].
  bool shadows(Set<String> names) {
    if (keyword == 'var') return false;
    for (var d in declarations) {
      if (d.declaration.shadows(names)) return true;
    }
    return false;
  }

  @override
  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitVariableDeclarationList(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    for (VariableInitialization declaration in declarations) {
      declaration.accept(visitor);
    }
  }

  @override
  VariableDeclarationList _clone() =>
      VariableDeclarationList(keyword, declarations);

  @override
  int get precedenceLevel => EXPRESSION;
}

class Assignment extends Expression {
  final Expression leftHandSide;
  final String? op; // `null` if the assignment is not compound.
  final Expression value;

  Assignment(this.leftHandSide, this.value) : op = null;

  // If `this.op == null` this will be a non-compound assignment.
  Assignment.compound(this.leftHandSide, this.op, this.value);

  @override
  int get precedenceLevel => ASSIGNMENT;

  bool get isCompound => op != null;

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitAssignment(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    leftHandSide.accept(visitor);
    value.accept(visitor);
  }

  @override
  Assignment _clone() => Assignment.compound(leftHandSide, op, value);
}

class VariableInitialization extends Expression {
  final VariableBinding declaration;
  // The initializing value can be missing, e.g. for `a` in `var a, b=1;`.
  final Expression? value;

  VariableInitialization(this.declaration, this.value);

  @override
  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitVariableInitialization(this);

  @override
  VariableInitialization _clone() => VariableInitialization(declaration, value);

  @override
  int get precedenceLevel => ASSIGNMENT;

  @override
  void visitChildren(NodeVisitor visitor) {
    declaration.accept(visitor);
    value?.accept(visitor);
  }
}

sealed class VariableBinding extends Expression {
  /// True if this binding declares any name from [names].
  ///
  /// Analogous to the predicate [Statement.shadows].
  bool shadows(Set<String> names);
}

// TODO(jmesserly): destructuring was originally implemented in the context of
// Closure Compiler work. Rethink how this is represented.
class DestructuredVariable extends Expression implements Parameter {
  final Identifier name;

  /// The property in an object binding pattern, for example:
  ///
  ///     let key = 'z';
  ///     let {[key]: foo} = {z: 'bar'};
  ///     console.log(foo); // "bar"
  ///
  // TODO(jmesserly): parser does not support this feature.
  final Expression? property;
  final BindingPattern? structure;
  final Expression? defaultValue;

  DestructuredVariable(
      {required this.name, this.property, this.structure, this.defaultValue});

  @override
  bool shadows(Set<String> names) {
    return name.shadows(names) || (structure?.shadows(names) ?? false);
  }

  @override
  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitDestructuredVariable(this);
  @override
  void visitChildren(NodeVisitor visitor) {
    name.accept(visitor);
    structure?.accept(visitor);
    defaultValue?.accept(visitor);
  }

  /// Avoid parenthesis when pretty-printing.
  @override
  int get precedenceLevel => PRIMARY;
  @override
  String get parameterName => name.name;
  @override
  DestructuredVariable _clone() => DestructuredVariable(
      name: name,
      property: property,
      structure: structure,
      defaultValue: defaultValue);
}

abstract class BindingPattern extends Expression implements VariableBinding {
  final List<DestructuredVariable> variables;
  BindingPattern(this.variables);

  @override
  bool shadows(Set<String> names) {
    for (var v in variables) {
      if (v.shadows(names)) return true;
    }
    return false;
  }

  @override
  void visitChildren(NodeVisitor visitor) {
    for (DestructuredVariable v in variables) {
      v.accept(visitor);
    }
  }
}

class SimpleBindingPattern extends BindingPattern {
  final Identifier name;
  SimpleBindingPattern(this.name) : super([DestructuredVariable(name: name)]);

  @override
  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitSimpleBindingPattern(this);

  @override
  bool shadows(Set<String> names) => names.contains(name.name);

  /// Avoid parenthesis when pretty-printing.
  @override
  int get precedenceLevel => PRIMARY;
  @override
  SimpleBindingPattern _clone() => SimpleBindingPattern(name);
}

class ObjectBindingPattern extends BindingPattern {
  ObjectBindingPattern(super.variables);
  @override
  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitObjectBindingPattern(this);

  /// Avoid parenthesis when pretty-printing.
  @override
  int get precedenceLevel => PRIMARY;
  @override
  ObjectBindingPattern _clone() => ObjectBindingPattern(variables);
}

class ArrayBindingPattern extends BindingPattern {
  ArrayBindingPattern(super.variables);
  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitArrayBindingPattern(this);

  /// Avoid parenthesis when pretty-printing.
  @override
  int get precedenceLevel => PRIMARY;
  @override
  ArrayBindingPattern _clone() => ArrayBindingPattern(variables);
}

class Conditional extends Expression {
  final Expression condition;
  final Expression then;
  final Expression otherwise;

  Conditional(this.condition, this.then, this.otherwise);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitConditional(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    condition.accept(visitor);
    then.accept(visitor);
    otherwise.accept(visitor);
  }

  @override
  Conditional _clone() => Conditional(condition, then, otherwise);

  @override
  int get precedenceLevel => ASSIGNMENT;
}

class Call extends Expression {
  Expression target;
  List<Expression> arguments;

  Call(this.target, this.arguments);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitCall(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    target.accept(visitor);
    for (Expression arg in arguments) {
      arg.accept(visitor);
    }
  }

  @override
  Call _clone() => Call(target, arguments);

  @override
  int get precedenceLevel => CALL;
}

class New extends Call {
  New(super.cls, super.arguments);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitNew(this);

  @override
  New _clone() => New(target, arguments);

  @override
  int get precedenceLevel => ACCESS;
}

class Binary extends Expression {
  final String op;
  final Expression left;
  final Expression right;

  Binary(this.op, this.left, this.right);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitBinary(this);

  @override
  Binary _clone() => Binary(op, left, right);

  @override
  void visitChildren(NodeVisitor visitor) {
    left.accept(visitor);
    right.accept(visitor);
  }

  @override
  bool get isCommaOperator => op == ',';

  @override
  Expression toVoidExpression() {
    if (!isCommaOperator) return super.toVoidExpression();
    var l = left.toVoidExpression();
    var r = right.toVoidExpression();
    if (l == left && r == right) return this;
    return Binary(',', l, r);
  }

  @override
  Statement toStatement() {
    if (!isCommaOperator) return super.toStatement();
    return Block([left.toStatement(), right.toStatement()]);
  }

  @override
  Statement toReturn() {
    if (!isCommaOperator) return super.toReturn();
    return Block([left.toStatement(), right.toReturn()]);
  }

  List<Expression> commaToExpressionList() {
    if (!isCommaOperator) throw StateError('not a comma expression');
    var exprs = <Expression>[];
    _flattenComma(exprs, left);
    _flattenComma(exprs, right);
    return exprs;
  }

  static void _flattenComma(List<Expression> exprs, Expression node) {
    if (node is Binary && node.isCommaOperator) {
      _flattenComma(exprs, node.left);
      _flattenComma(exprs, node.right);
    } else {
      exprs.add(node);
    }
  }

  @override
  int get precedenceLevel {
    // TODO(floitsch): switch to constant map.
    switch (op) {
      case '**':
        return EXPONENTIATION;
      case '*':
      case '/':
      case '%':
        return MULTIPLICATIVE;
      case '+':
      case '-':
        return ADDITIVE;
      case '<<':
      case '>>':
      case '>>>':
        return SHIFT;
      case '<':
      case '>':
      case '<=':
      case '>=':
      case 'instanceof':
      case 'in':
        return RELATIONAL;
      case '==':
      case '===':
      case '!=':
      case '!==':
        return EQUALITY;
      case '&':
        return BIT_AND;
      case '^':
        return BIT_XOR;
      case '|':
        return BIT_OR;
      case '&&':
        return LOGICAL_AND;
      case '||':
        return LOGICAL_OR;
      case ',':
        return EXPRESSION;
      default:
        throw 'Internal Error: Unhandled binary operator: $op';
    }
  }
}

class Prefix extends Expression {
  final String op;
  final Expression argument;

  Prefix(this.op, this.argument);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitPrefix(this);

  @override
  Prefix _clone() => Prefix(op, argument);

  @override
  void visitChildren(NodeVisitor visitor) {
    argument.accept(visitor);
  }

  @override
  int get precedenceLevel => UNARY;
}

/// SpreadElement isn't really a prefix expression, as it can only appear in
/// certain places such as ArgumentList and BindingPattern, but we pretend
/// it is for simplicity's sake.
class Spread extends Prefix {
  Spread(Expression operand) : super('...', operand);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitSpread(this);
  @override
  Spread _clone() => Spread(argument);
}

class Postfix extends Expression {
  final String op;
  final Expression argument;

  Postfix(this.op, this.argument);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitPostfix(this);

  @override
  Postfix _clone() => Postfix(op, argument);

  @override
  void visitChildren(NodeVisitor visitor) {
    argument.accept(visitor);
  }

  @override
  int get precedenceLevel => UNARY;
}

abstract class Parameter implements Expression, VariableBinding {
  String get parameterName;
}

class Identifier extends Expression implements Parameter {
  final String name;
  final bool allowRename;

  Identifier(this.name, {this.allowRename = true}) {
    if (!_identifierRE.hasMatch(name)) {
      throw ArgumentError.value(name, 'name', 'not a valid identifier');
    }
  }
  static final RegExp _identifierRE = RegExp(r'^[A-Za-z_$][A-Za-z_$0-9]*$');

  @override
  bool shadows(Set<String> names) => names.contains(name);

  @override
  Identifier _clone() => Identifier(name, allowRename: allowRename);
  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitIdentifier(this);
  @override
  int get precedenceLevel => PRIMARY;
  @override
  String get parameterName => name;
  @override
  void visitChildren(NodeVisitor visitor) {}
}

/// This is an expression for convenience in the AST.
class RestParameter extends Expression implements Parameter {
  final Identifier parameter;

  RestParameter(this.parameter);

  @override
  bool shadows(Set<String> names) => names.contains(parameter.name);

  @override
  RestParameter _clone() => RestParameter(parameter);
  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitRestParameter(this);
  @override
  void visitChildren(NodeVisitor visitor) {
    parameter.accept(visitor);
  }

  @override
  int get precedenceLevel => PRIMARY;
  @override
  String get parameterName => parameter.parameterName;
}

class This extends Literal {
  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitThis(this);
  @override
  This _clone() => This();
  @override
  int get precedenceLevel => PRIMARY;
  @override
  void visitChildren(NodeVisitor visitor) {}
}

/// `super` is more restricted in the ES6 spec, but for simplicity we accept
/// it anywhere that `this` is accepted.
class Super extends Literal {
  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitSuper(this);
  @override
  Super _clone() => Super();
  @override
  int get precedenceLevel => PRIMARY;
  @override
  void visitChildren(NodeVisitor visitor) {}
}

class NamedFunction extends Expression {
  final Identifier name;
  final Fun function;

  /// A heuristic to force extra parens around this function.
  ///
  /// V8 and other engines use this IIFE (immediately invoked function
  /// expression) heuristic to eagerly parse a function.
  final bool immediatelyInvoked;

  NamedFunction(this.name, this.function, [this.immediatelyInvoked = false]);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitNamedFunction(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    name.accept(visitor);
    function.accept(visitor);
  }

  @override
  NamedFunction _clone() => NamedFunction(name, function, immediatelyInvoked);

  @override
  int get precedenceLevel =>
      immediatelyInvoked ? EXPRESSION : PRIMARY_LOW_PRECEDENCE;
}

abstract class FunctionExpression extends Expression {
  Node get body; // Expression or block
  List<Parameter> get params;
  AsyncModifier get asyncModifier;
}

class Fun extends FunctionExpression {
  @override
  final List<Parameter> params;
  @override
  final Block body;

  /// Whether this is a JS generator (`function*`) that may contain `yield`.
  final bool isGenerator;

  @override
  final AsyncModifier asyncModifier;

  Fun(this.params, this.body,
      {this.isGenerator = false, this.asyncModifier = AsyncModifier.sync});

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitFun(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    for (Parameter param in params) {
      param.accept(visitor);
    }
    body.accept(visitor);
  }

  @override
  Fun _clone() =>
      Fun(params, body, isGenerator: isGenerator, asyncModifier: asyncModifier);

  @override
  int get precedenceLevel => PRIMARY_LOW_PRECEDENCE;
}

class ArrowFun extends FunctionExpression {
  @override
  final List<Parameter> params;
  @override
  final Node body; // Expression or Block

  @override
  AsyncModifier get asyncModifier => AsyncModifier.sync;

  ArrowFun(this.params, this.body);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitArrowFun(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    for (Parameter param in params) {
      param.accept(visitor);
    }
    body.accept(visitor);
  }

  @override
  int get precedenceLevel => PRIMARY_LOW_PRECEDENCE;

  @override
  ArrowFun _clone() => ArrowFun(params, body);
}

/// The Dart sync, sync*, async, and async* modifier.
///
/// See [DartYield]. This is not used for JS functions.
enum AsyncModifier {
  sync(isAsync: false, isYielding: false, description: 'sync'),
  async(isAsync: true, isYielding: false, description: 'async'),
  asyncStar(isAsync: true, isYielding: true, description: 'async*'),
  syncStar(isAsync: false, isYielding: true, description: 'sync*');

  const AsyncModifier(
      {required this.isAsync,
      required this.isYielding,
      required this.description});

  final bool isAsync;
  final bool isYielding;
  final String description;
  @override
  String toString() => description;
}

class PropertyAccess extends Expression {
  final Expression receiver;
  final Expression selector;

  PropertyAccess(this.receiver, this.selector);
  PropertyAccess.field(this.receiver, String fieldName)
      : selector = LiteralString('"$fieldName"');
  PropertyAccess.indexed(this.receiver, int index)
      : selector = LiteralNumber('$index');

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitAccess(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    receiver.accept(visitor);
    selector.accept(visitor);
  }

  @override
  PropertyAccess _clone() => PropertyAccess(receiver, selector);

  @override
  int get precedenceLevel => ACCESS;
}

abstract class Literal extends Expression {
  @override
  void visitChildren(NodeVisitor visitor) {}

  @override
  int get precedenceLevel => PRIMARY;
}

class LiteralBool extends Literal {
  final bool value;

  LiteralBool(this.value);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralBool(this);
  // [visitChildren] inherited from [Literal].
  @override
  LiteralBool _clone() => LiteralBool(value);
}

class LiteralNull extends Literal {
  LiteralNull();

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralNull(this);
  @override
  LiteralNull _clone() => LiteralNull();
}

class LiteralString extends Literal {
  final String value;

  /// Constructs a LiteralString from a string value.
  ///
  /// The constructor does not add the required quotes.  If [value] is not
  /// surrounded by quotes and property escaped, the resulting object is invalid
  /// as a JS value.
  ///
  /// TODO(sra): Introduce variants for known valid strings that don't allocate
  /// a new string just to add quotes.
  LiteralString(this.value);

  /// Gets the value inside the string without the beginning and end quotes.
  String get valueWithoutQuotes => value.substring(1, value.length - 1);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralString(this);
  @override
  LiteralString _clone() => LiteralString(value);
}

class LiteralNumber extends Literal {
  final String value; // Must be a valid JavaScript number literal.

  LiteralNumber(this.value);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralNumber(this);
  @override
  LiteralNumber _clone() => LiteralNumber(value);

  /// Use a different precedence level depending on whether the value contains a
  /// dot to ensure we generate `(1).toString()` and `1.0.toString()`.
  @override
  int get precedenceLevel => value.contains('.') ? PRIMARY : UNARY;
}

class ArrayInitializer extends Expression {
  final List<Expression> elements;
  final bool multiline;

  ArrayInitializer(this.elements, {this.multiline = false});

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitArrayInitializer(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    for (Expression element in elements) {
      element.accept(visitor);
    }
  }

  @override
  ArrayInitializer _clone() => ArrayInitializer(elements);

  @override
  int get precedenceLevel => PRIMARY;
}

/// An empty place in an [ArrayInitializer].
///
/// For example the list [1, , , 2] would contain two holes.
class ArrayHole extends Expression {
  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitArrayHole(this);

  @override
  void visitChildren(NodeVisitor visitor) {}

  @override
  ArrayHole _clone() => ArrayHole();

  @override
  int get precedenceLevel => PRIMARY;
}

class ObjectInitializer extends Expression {
  final List<Property> properties;
  final bool _multiline;

  /// Constructs a new object-initializer containing the given [properties].
  ObjectInitializer(this.properties, {bool multiline = false})
      : _multiline = multiline;

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitObjectInitializer(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    for (Property init in properties) {
      init.accept(visitor);
    }
  }

  @override
  ObjectInitializer _clone() => ObjectInitializer(properties);

  @override
  int get precedenceLevel => PRIMARY;

  /// If set to true, forces a vertical layout when using the [Printer].
  ///
  /// Otherwise, layout will be vertical if and only if any [properties] are
  /// [FunctionExpression]s.
  bool get multiline {
    return _multiline || properties.any((p) => p.value is FunctionExpression);
  }
}

class Property extends Node {
  final Expression name;
  final Expression value;

  Property(this.name, this.value);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitProperty(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    name.accept(visitor);
    value.accept(visitor);
  }

  @override
  Property _clone() => Property(name, value);
}

// TODO(jmesserly): parser does not support this yet.
class TemplateString extends Expression {
  /// The parts of this template string: a sequence of [String]s and
  /// [Expression]s.
  ///
  /// Strings and expressions will alternate, for example:
  ///
  ///     `foo${1 + 2} bar ${'hi'}`
  ///
  /// would be represented by [strings]:
  ///
  ///     ['foo', ' bar ', '']
  ///
  /// and [interpolations]:
  ///
  ///     [new JS.Binary('+', js.number(1), js.number(2)),
  ///      new JS.LiteralString("'hi'")]
  ///
  /// There should be exactly one more string than interpolation expression.
  final List<String> strings;
  final List<Expression> interpolations;

  TemplateString(this.strings, this.interpolations) {
    assert(strings.length == interpolations.length + 1);
  }

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitTemplateString(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    for (var element in interpolations) {
      element.accept(visitor);
    }
  }

  @override
  TemplateString _clone() => TemplateString(strings, interpolations);

  @override
  int get precedenceLevel => PRIMARY;
}

// TODO(jmesserly): parser does not support this yet.
class TaggedTemplate extends Expression {
  final Expression tag;
  final TemplateString template;

  TaggedTemplate(this.tag, this.template);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitTaggedTemplate(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    tag.accept(visitor);
    template.accept(visitor);
  }

  @override
  TaggedTemplate _clone() => TaggedTemplate(tag, template);

  @override
  int get precedenceLevel => CALL;
}

// TODO(jmesserly): parser does not support this yet.
class Yield extends Expression {
  final Expression? value;

  /// Whether this yield expression is a `yield*` that iterates each item in
  /// [value].
  final bool star;

  Yield(this.value, {this.star = false});

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitYield(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    value?.accept(visitor);
  }

  @override
  Yield _clone() => Yield(value);

  @override
  int get precedenceLevel => YIELD;
}

class ClassDeclaration extends Statement {
  final ClassExpression classExpr;

  ClassDeclaration(this.classExpr);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitClassDeclaration(this);
  @override
  void visitChildren(NodeVisitor visitor) => classExpr.accept(visitor);
  @override
  ClassDeclaration _clone() => ClassDeclaration(classExpr);
}

class ClassExpression extends Expression {
  final Identifier name;
  final Expression? heritage;
  final List<Method> methods;

  ClassExpression(this.name, this.heritage, this.methods);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitClassExpression(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    name.accept(visitor);
    heritage?.accept(visitor);
    for (Method element in methods) {
      element.accept(visitor);
    }
  }

  @override
  ClassDeclaration toStatement() => ClassDeclaration(this);

  @override
  ClassExpression _clone() => ClassExpression(name, heritage, methods);

  @override
  int get precedenceLevel => PRIMARY_LOW_PRECEDENCE;
}

class Method extends Node implements Property {
  @override
  final Expression name;
  final Fun function;
  final bool isGetter;
  final bool isSetter;
  final bool isStatic;

  Method(this.name, this.function,
      {this.isGetter = false, this.isSetter = false, this.isStatic = false}) {
    assert(!isGetter || function.params.isEmpty);
    assert(!isSetter || function.params.length == 1);
    assert(!isGetter && !isSetter || !function.isGenerator);
  }

  @override
  Fun get value => function;

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitMethod(this);

  @override
  void visitChildren(NodeVisitor visitor) {
    name.accept(visitor);
    function.accept(visitor);
  }

  @override
  Method _clone() => Method(name, function,
      isGetter: isGetter, isSetter: isSetter, isStatic: isStatic);
}

/// Tag class for all interpolated positions.
mixin InterpolatedNode implements Node {
  dynamic get nameOrPosition;

  bool get isNamed => nameOrPosition is String;
  bool get isPositional => nameOrPosition is int;
}

class InterpolatedExpression extends Expression with InterpolatedNode {
  @override
  final Object nameOrPosition;

  InterpolatedExpression(this.nameOrPosition);

  @override
  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitInterpolatedExpression(this);
  @override
  void visitChildren(NodeVisitor visitor) {}
  @override
  InterpolatedExpression _clone() => InterpolatedExpression(nameOrPosition);

  @override
  int get precedenceLevel => PRIMARY;
}

class InterpolatedLiteral extends Literal with InterpolatedNode {
  @override
  final Object nameOrPosition;

  InterpolatedLiteral(this.nameOrPosition);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitInterpolatedLiteral(this);
  @override
  void visitChildren(NodeVisitor visitor) {}
  @override
  InterpolatedLiteral _clone() => InterpolatedLiteral(nameOrPosition);
}

class InterpolatedParameter extends Expression
    with InterpolatedNode
    implements Identifier {
  @override
  final Object nameOrPosition;

  @override
  String get name {
    throw 'InterpolatedParameter.name must not be invoked';
  }

  @override
  String get parameterName {
    throw 'InterpolatedParameter.parameterName must not be invoked';
  }

  @override
  bool shadows(Set<String> names) => false;

  @override
  bool get allowRename => false;

  InterpolatedParameter(this.nameOrPosition);

  @override
  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitInterpolatedParameter(this);
  @override
  void visitChildren(NodeVisitor visitor) {}
  @override
  InterpolatedParameter _clone() => InterpolatedParameter(nameOrPosition);

  @override
  int get precedenceLevel => PRIMARY;
}

class InterpolatedSelector extends Expression with InterpolatedNode {
  @override
  final Object nameOrPosition;

  InterpolatedSelector(this.nameOrPosition);

  @override
  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitInterpolatedSelector(this);
  @override
  void visitChildren(NodeVisitor visitor) {}
  @override
  InterpolatedSelector _clone() => InterpolatedSelector(nameOrPosition);

  @override
  int get precedenceLevel => PRIMARY;
}

class InterpolatedStatement extends Statement with InterpolatedNode {
  @override
  final Object nameOrPosition;

  InterpolatedStatement(this.nameOrPosition);

  @override
  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitInterpolatedStatement(this);
  @override
  void visitChildren(NodeVisitor visitor) {}
  @override
  InterpolatedStatement _clone() => InterpolatedStatement(nameOrPosition);
}

// TODO(jmesserly): generalize this to InterpolatedProperty?
class InterpolatedMethod extends Expression
    with InterpolatedNode
    implements Method {
  @override
  final Object nameOrPosition;

  InterpolatedMethod(this.nameOrPosition);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitInterpolatedMethod(this);
  @override
  void visitChildren(NodeVisitor visitor) {}
  @override
  InterpolatedMethod _clone() => InterpolatedMethod(nameOrPosition);

  @override
  int get precedenceLevel => PRIMARY;
  @override
  Expression get name => throw _unsupported;
  @override
  Fun get value => throw _unsupported;
  @override
  bool get isGetter => throw _unsupported;
  @override
  bool get isSetter => throw _unsupported;
  @override
  bool get isStatic => throw _unsupported;
  @override
  Fun get function => throw _unsupported;
  Error get _unsupported =>
      UnsupportedError('$runtimeType does not support this member.');
}

class InterpolatedIdentifier extends Expression
    with InterpolatedNode
    implements Identifier {
  @override
  final Object nameOrPosition;

  InterpolatedIdentifier(this.nameOrPosition);

  @override
  bool shadows(Set<String> names) => false;

  @override
  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitInterpolatedIdentifier(this);
  @override
  void visitChildren(NodeVisitor visitor) {}
  @override
  InterpolatedIdentifier _clone() => InterpolatedIdentifier(nameOrPosition);

  @override
  int get precedenceLevel => PRIMARY;
  @override
  String get name => throw '$runtimeType does not support this member.';
  @override
  String get parameterName =>
      throw '$runtimeType does not support this member.';
  @override
  bool get allowRename => false;
}

/// [RegExpLiteral]s, despite being called "Literal", do not inherit from
/// [Literal].
///
/// Indeed, regular expressions in JavaScript have a side-effect and are thus
/// not in the same category as numbers or strings.
class RegExpLiteral extends Expression {
  /// Contains the pattern and the flags.
  final String pattern;

  RegExpLiteral(this.pattern);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitRegExpLiteral(this);
  @override
  void visitChildren(NodeVisitor visitor) {}
  @override
  RegExpLiteral _clone() => RegExpLiteral(pattern);

  @override
  int get precedenceLevel => PRIMARY;
}

/// An asynchronous await.
///
/// Not part of JavaScript. We desugar this expression before outputting.
/// Should only occur in a [Fun] with `asyncModifier` async or asyncStar.
class Await extends Expression {
  /// The awaited expression.
  final Expression expression;

  Await(this.expression);

  @override
  int get precedenceLevel => UNARY;
  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitAwait(this);
  @override
  void visitChildren(NodeVisitor visitor) => expression.accept(visitor);
  @override
  Await _clone() => Await(expression);
}

/// A comment.
///
/// Extends [Statement] so we can add comments before statements in [Block] and
/// [Program].
class Comment extends Statement {
  final String comment;

  Comment(this.comment);

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitComment(this);
  @override
  Comment _clone() => Comment(comment);

  @override
  void visitChildren(NodeVisitor visitor) {}
}

/// A comment for expressions.
///
/// Extends [Expression] so we can add comments before expressions. Has the
/// highest possible precedence, so we don't add parentheses around it.
class CommentExpression extends Expression {
  final String comment;
  final Expression expression;

  CommentExpression(this.comment, this.expression);

  @override
  int get precedenceLevel => PRIMARY;
  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitCommentExpression(this);
  @override
  CommentExpression _clone() => CommentExpression(comment, expression);

  @override
  void visitChildren(NodeVisitor visitor) => expression.accept(visitor);
}

class DebuggerStatement extends Statement {
  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitDebuggerStatement(this);
  @override
  DebuggerStatement _clone() => DebuggerStatement();
  @override
  void visitChildren(NodeVisitor visitor) {}
}

/// Represents allowed module items:
/// [Statement], [ImportDeclaration], and [ExportDeclaration].
abstract class ModuleItem extends Node {}

class ImportDeclaration extends ModuleItem {
  final Identifier? defaultBinding;

  // Can be `null`, a single specifier of `* as name`, or a list.
  final List<NameSpecifier>? namedImports;

  final LiteralString from;

  ImportDeclaration(
      {this.defaultBinding, this.namedImports, required this.from});

  /// The `import "name.js"` form of import.
  ImportDeclaration.all(LiteralString module) : this(from: module);

  /// If this import has `* as name` returns the name, otherwise null.
  Identifier? get importStarAs {
    var imports = namedImports;
    if (imports != null && imports.length == 1 && imports[0].isStar) {
      return imports[0].asName;
    }
    return null;
  }

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitImportDeclaration(this);
  @override
  void visitChildren(NodeVisitor visitor) {
    var imports = namedImports;
    if (imports != null) {
      for (NameSpecifier name in imports) {
        name.accept(visitor);
      }
    }
    from.accept(visitor);
  }

  @override
  ImportDeclaration _clone() => ImportDeclaration(
      defaultBinding: defaultBinding, namedImports: namedImports, from: from);
}

class ExportDeclaration extends ModuleItem {
  /// Exports a name from this module.
  ///
  /// This can be a [ClassDeclaration] or [FunctionDeclaration].
  /// If [isDefault] is true, it can also be an [Expression].
  /// Otherwise it can be a [VariableDeclarationList] or an [ExportClause].
  final Node exported;

  /// True if this is an `export default`.
  final bool isDefault;

  ExportDeclaration(this.exported, {this.isDefault = false}) {
    assert(exported is ClassDeclaration ||
            exported is FunctionDeclaration ||
            isDefault
        ? exported is Expression
        : exported is VariableDeclarationList || exported is ExportClause);
  }

  /// Gets the list of names exported by this export declaration, or `null`
  /// if this is an `export *`.
  ///
  /// This can be useful for lowering to other module formats.
  List<NameSpecifier>? get exportedNames {
    if (isDefault) return [NameSpecifier(Identifier('default'))];

    var exported = this.exported;
    if (exported is ClassDeclaration) {
      return [NameSpecifier(exported.classExpr.name)];
    }
    if (exported is FunctionDeclaration) return [NameSpecifier(exported.name)];
    if (exported is VariableDeclarationList) {
      return exported.declarations
          .map((i) => NameSpecifier(i.declaration as Identifier))
          .toList();
    }
    if (exported is ExportClause) {
      if (exported.exportStar) return null;
      return exported.exports;
    }
    throw StateError('invalid export declaration');
  }

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitExportDeclaration(this);
  @override
  void visitChildren(NodeVisitor visitor) => exported.accept(visitor);
  @override
  ExportDeclaration _clone() =>
      ExportDeclaration(exported, isDefault: isDefault);
}

class ExportClause extends Node {
  final List<NameSpecifier> exports;
  final LiteralString? from;

  ExportClause(this.exports, {this.from});

  /// The `export * from 'name.js'` form.
  ExportClause.star(LiteralString from)
      : this([NameSpecifier.star()], from: from);

  /// True if this is an `export *`.
  bool get exportStar => exports.length == 1 && exports[0].isStar;

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitExportClause(this);
  @override
  void visitChildren(NodeVisitor visitor) {
    for (NameSpecifier name in exports) {
      name.accept(visitor);
    }
    from?.accept(visitor);
  }

  @override
  ExportClause _clone() => ExportClause(exports, from: from);
}

/// An import or export specifier.
class NameSpecifier extends Node {
  final Identifier? name;
  final Identifier? asName;

  NameSpecifier(this.name, {this.asName});
  NameSpecifier.star() : this(null);

  /// True if this is a `* as someName` specifier.
  bool get isStar => name == null;

  @override
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitNameSpecifier(this);
  @override
  void visitChildren(NodeVisitor visitor) {}
  @override
  NameSpecifier _clone() => NameSpecifier(name, asName: asName);
}

/// Visitor used to transform specific subtrees within the [Node] AST.
///
/// This transformer will only clone a node if it detects a subtree under that
/// node has changed, otherwise it returns the same node. Subclasses of this
/// transformer can override specific 'visit' methods to return modified nodes.
abstract class Transformer extends BaseVisitor<Node> {
  T visit<T extends Node>(Node node) {
    return (node.accept(this)..sourceInformation = node.sourceInformation) as T;
  }

  T? visitNullable<T extends Node>(Node? node) {
    return (node?.accept(this)?..sourceInformation = node?.sourceInformation)
        as T?;
  }

  List<T> visitList<T extends Node>(List<Node> node) {
    return node.map((e) => visit<T>(e)).toList();
  }

  List<T>? visitNullableList<T extends Node>(List<Node>? node) {
    return node?.map((e) => visit<T>(e)).toList();
  }

  bool isUnchanged(Node? before, Node? after) {
    if (before == null) return after == null;
    if (after == null) return false;
    return identical(before, after) &&
        identical(before.sourceInformation, after.sourceInformation);
  }

  bool isUnchangedList(List<Node>? before, List<Node>? after) {
    if (before == null) return after == null;
    if (after == null) return false;
    if (before.length != after.length) return false;
    for (var i = 0; i < before.length; i++) {
      if (!isUnchanged(before[i], after[i])) return false;
    }
    return true;
  }

  N transformIfUnchanged1<N extends Node, T extends Node>(
      N node, T childNode, N Function(T newChildNode) clone) {
    final newChildNode = visit<T>(childNode);
    final hasNoChange = isUnchanged(childNode, newChildNode);
    return hasNoChange ? node : clone(newChildNode);
  }

  N transformIfUnchanged2<N extends Node, T extends Node, U extends Node>(
      N node,
      T childNode1,
      U childNode2,
      N Function(T newChildNode1, U newChildNode2) clone) {
    final newChildNode1 = visit<T>(childNode1);
    final newChildNode2 = visit<U>(childNode2);
    final hasNoChange = isUnchanged(childNode1, newChildNode1) &&
        isUnchanged(childNode2, newChildNode2);
    return hasNoChange ? node : clone(newChildNode1, newChildNode2);
  }

  N transformIfUnchanged3<N extends Node, T extends Node, U extends Node,
          V extends Node>(N node, T childNode1, U childNode2, V childNode3,
      N Function(T newChildNode1, U newChildNode2, V newChildNode3) clone) {
    final newChildNode1 = visit<T>(childNode1);
    final newChildNode2 = visit<U>(childNode2);
    final newChildNode3 = visit<V>(childNode3);
    final hasNoChange = isUnchanged(childNode1, newChildNode1) &&
        isUnchanged(childNode2, newChildNode2) &&
        isUnchanged(childNode3, newChildNode3);
    return hasNoChange
        ? node
        : clone(newChildNode1, newChildNode2, newChildNode3);
  }

  N transformIfUnchangedList<N extends Node, T extends Node>(
      N node, List<T> childNodes, N Function(List<T> newChildNodes) clone) {
    final newChildNodes = visitList<T>(childNodes);
    final hasNoChange = isUnchangedList(childNodes, newChildNodes);
    return hasNoChange ? node : clone(newChildNodes);
  }

  N transformIfUnchangedList1<N extends Node, T extends Node, U extends Node>(
      N node,
      List<T> childNodeList,
      U childNode,
      N Function(List<T> newChildNodeList, U childNode) clone) {
    final newChildNodeList = visitList<T>(childNodeList);
    final newChildNode = visit<U>(childNode);
    final hasNoChange = isUnchangedList(childNodeList, newChildNodeList) &&
        isUnchanged(childNode, newChildNode);
    return hasNoChange ? node : clone(newChildNodeList, newChildNode);
  }

  @override
  Node visitNode(Node node) => node;

  @override
  Node visitComment(Comment node) => node;

  @override
  Node visitAccess(PropertyAccess node) {
    return transformIfUnchanged2(
        node, node.receiver, node.selector, PropertyAccess.new);
  }

  @override
  Node visitArrayBindingPattern(ArrayBindingPattern node) {
    return transformIfUnchangedList(
        node, node.variables, ArrayBindingPattern.new);
  }

  @override
  Node visitArrayInitializer(ArrayInitializer node) {
    return transformIfUnchangedList(node, node.elements, ArrayInitializer.new);
  }

  @override
  Node visitArrowFun(ArrowFun node) {
    return transformIfUnchangedList1(
        node, node.params, node.body, ArrowFun.new);
  }

  @override
  Node visitAssignment(Assignment node) {
    if (node.isCompound) {
      return transformIfUnchanged2(node, node.leftHandSide, node.value,
          (e1, e2) => Assignment.compound(e1, node.op, e2));
    }
    return transformIfUnchanged2(
        node, node.leftHandSide, node.value, Assignment.new);
  }

  @override
  Node visitAwait(Await node) {
    return transformIfUnchanged1(node, node.expression, Await.new);
  }

  @override
  Node visitBinary(Binary node) {
    return transformIfUnchanged2(
        node, node.left, node.right, (e1, e2) => Binary(node.op, e1, e2));
  }

  @override
  Node visitBlock(Block node) {
    return transformIfUnchangedList(node, node.statements, Block.new);
  }

  @override
  Node visitCall(Call node) {
    return transformIfUnchangedList1(
        node, node.arguments, node.target, (e1, e2) => Call(e2, e1));
  }

  @override
  Node visitCase(Case node) {
    return transformIfUnchanged2(node, node.expression, node.body, Case.new);
  }

  @override
  Node visitCatch(Catch node) {
    return transformIfUnchanged2(node, node.declaration, node.body, Catch.new);
  }

  @override
  Node visitClassDeclaration(ClassDeclaration node) {
    return transformIfUnchanged1(node, node.classExpr, ClassDeclaration.new);
  }

  @override
  Node visitClassExpression(ClassExpression node) {
    final name = visit<Identifier>(node.name);
    final heritage = visitNullable<Expression>(node.heritage);
    final methods = visitList<Method>(node.methods);
    if (isUnchanged(name, node.name) &&
        isUnchanged(heritage, node.heritage) &&
        isUnchangedList(methods, node.methods)) {
      return node;
    }
    return ClassExpression(name, heritage, methods);
  }

  @override
  Node visitCommentExpression(CommentExpression node) {
    return transformIfUnchanged1(
        node, node.expression, (e) => CommentExpression(node.comment, e));
  }

  @override
  Node visitConditional(Conditional node) {
    return transformIfUnchanged3(
        node, node.condition, node.then, node.otherwise, Conditional.new);
  }

  @override
  Node visitDartYield(DartYield node) {
    return transformIfUnchanged1(
        node, node.expression, (e) => DartYield(e, node.hasStar));
  }

  @override
  Node visitDefault(Default node) {
    return transformIfUnchanged1(node, node.body, Default.new);
  }

  @override
  Node visitDestructuredVariable(DestructuredVariable node) {
    final name = visit<Identifier>(node.name);
    final property = visitNullable<Expression>(node.property);
    final structure = visitNullable<BindingPattern>(node.structure);
    final defaultValue = visitNullable<Expression>(node.defaultValue);

    if (isUnchanged(node.name, name) &&
        isUnchanged(node.property, node.property) &&
        isUnchanged(node.structure, structure) &&
        isUnchanged(node.defaultValue, defaultValue)) {
      return node;
    }
    return DestructuredVariable(
        name: name,
        property: property,
        structure: structure,
        defaultValue: defaultValue);
  }

  @override
  Node visitDo(Do node) {
    return transformIfUnchanged2(node, node.body, node.condition, Do.new);
  }

  @override
  Node visitExportClause(ExportClause node) {
    final exports = visitList<NameSpecifier>(node.exports);
    final from = visitNullable<LiteralString>(node.from);
    if (isUnchangedList(node.exports, exports) &&
        isUnchanged(node.from, from)) {
      return node;
    }
    return ExportClause(exports, from: from);
  }

  @override
  Node visitExportDeclaration(ExportDeclaration node) {
    return transformIfUnchanged1(node, node.exported,
        (e) => ExportDeclaration(e, isDefault: node.isDefault));
  }

  @override
  Node visitExpressionStatement(ExpressionStatement node) {
    return transformIfUnchanged1(
        node, node.expression, ExpressionStatement.new);
  }

  @override
  Node visitFor(For node) {
    final init = visitNullable<Expression>(node.init);
    final condition = visitNullable<Expression>(node.condition);
    final update = visitNullable<Expression>(node.update);
    final body = visit<Statement>(node.body);
    if (isUnchanged(node.init, init) &&
        isUnchanged(node.condition, condition) &&
        isUnchanged(node.update, update) &&
        isUnchanged(node.body, body)) {
      return node;
    }
    return For(init, condition, update, body);
  }

  @override
  Node visitForIn(ForIn node) {
    return transformIfUnchanged3(
        node, node.leftHandSide, node.object, node.body, ForIn.new);
  }

  @override
  Node visitForOf(ForOf node) {
    return transformIfUnchanged3(
        node, node.leftHandSide, node.iterable, node.body, ForOf.new);
  }

  @override
  Node visitFun(Fun node) {
    return transformIfUnchangedList1(
        node,
        node.params,
        node.body,
        (e1, e2) => Fun(e1, e2,
            isGenerator: node.isGenerator, asyncModifier: node.asyncModifier));
  }

  @override
  Node visitFunctionDeclaration(FunctionDeclaration node) {
    return transformIfUnchanged2(
        node, node.name, node.function, FunctionDeclaration.new);
  }

  @override
  Node visitIf(If node) {
    return transformIfUnchanged3(
        node, node.condition, node.then, node.otherwise, If.new);
  }

  @override
  Node visitImportDeclaration(ImportDeclaration node) {
    final defaultBinding = visitNullable<Identifier>(node.defaultBinding);
    final namedImports = visitNullableList<NameSpecifier>(node.namedImports);
    final from = visit<LiteralString>(node.from);
    if (isUnchanged(node.defaultBinding, defaultBinding) &&
        isUnchangedList(node.namedImports, namedImports) &&
        isUnchanged(node.from, from)) {
      return node;
    }
    return ImportDeclaration(
        defaultBinding: defaultBinding, namedImports: namedImports, from: from);
  }

  @override
  Node visitLabeledStatement(LabeledStatement node) {
    return transformIfUnchanged1(
        node, node.body, (e) => LabeledStatement(node.label, e));
  }

  @override
  Node visitMethod(Method node) {
    return transformIfUnchanged2(
        node,
        node.name,
        node.function,
        (e1, e2) => Method(e1, e2,
            isGetter: node.isGetter,
            isSetter: node.isSetter,
            isStatic: node.isStatic));
  }

  @override
  Node visitNameSpecifier(NameSpecifier node) {
    final name = visitNullable<Identifier>(node.name);
    final asName = visitNullable<Identifier>(node.asName);
    if (isUnchanged(node.name, name) && isUnchanged(node.asName, asName)) {
      return node;
    }
    return NameSpecifier(name, asName: asName);
  }

  @override
  Node visitNamedFunction(NamedFunction node) {
    return transformIfUnchanged2(node, node.name, node.function,
        (e1, e2) => NamedFunction(e1, e2, node.immediatelyInvoked));
  }

  @override
  Node visitNew(New node) {
    return transformIfUnchangedList1(
        node, node.arguments, node.target, (e1, e2) => New(e2, e1));
  }

  @override
  Node visitObjectBindingPattern(ObjectBindingPattern node) {
    return transformIfUnchangedList(
        node, node.variables, ObjectBindingPattern.new);
  }

  @override
  Node visitObjectInitializer(ObjectInitializer node) {
    return transformIfUnchangedList(node, node.properties,
        (e) => ObjectInitializer(e, multiline: node.multiline));
  }

  @override
  Node visitPostfix(Postfix node) {
    return transformIfUnchanged1(
        node, node.argument, (e) => Postfix(node.op, e));
  }

  @override
  Node visitPrefix(Prefix node) {
    return transformIfUnchanged1(
        node, node.argument, (e) => Prefix(node.op, e));
  }

  @override
  Node visitProgram(Program node) {
    final body = visitList<ModuleItem>(node.body);
    final header = visitList<Comment>(node.header);
    if (isUnchangedList(node.body, body) &&
        isUnchangedList(node.header, header)) {
      return node;
    }
    return Program(body,
        scriptTag: node.scriptTag, name: node.name, header: header);
  }

  @override
  Node visitProperty(Property node) {
    return transformIfUnchanged2(node, node.name, node.value, Property.new);
  }

  @override
  Node visitRestParameter(RestParameter node) {
    return transformIfUnchanged1(node, node.parameter, RestParameter.new);
  }

  @override
  Node visitReturn(Return node) {
    final value = visitNullable<Expression>(node.value);
    if (isUnchanged(node.value, value)) {
      return node;
    }
    return Return(value);
  }

  @override
  Node visitSimpleBindingPattern(SimpleBindingPattern node) {
    return transformIfUnchanged1(node, node.name, SimpleBindingPattern.new);
  }

  @override
  Node visitSpread(Spread node) {
    return transformIfUnchanged1(node, node.argument, Spread.new);
  }

  @override
  Node visitSwitch(Switch node) {
    return transformIfUnchangedList1(
        node, node.cases, node.key, (e1, e2) => Switch(e2, e1));
  }

  @override
  Node visitTaggedTemplate(TaggedTemplate node) {
    return transformIfUnchanged2(
        node, node.tag, node.template, TaggedTemplate.new);
  }

  @override
  Node visitTemplateString(TemplateString node) {
    return transformIfUnchangedList(
        node, node.interpolations, (e) => TemplateString(node.strings, e));
  }

  @override
  Node visitThrow(Throw node) {
    return transformIfUnchanged1(node, node.expression, Throw.new);
  }

  @override
  Node visitTry(Try node) {
    final body = visit<Block>(node.body);
    final catchPart = visitNullable<Catch>(node.catchPart);
    final finallyPart = visitNullable<Block>(node.finallyPart);
    if (isUnchanged(node.body, body) &&
        isUnchanged(node.catchPart, catchPart) &&
        isUnchanged(node.finallyPart, finallyPart)) {
      return node;
    }
    return Try(body, catchPart, finallyPart);
  }

  @override
  Node visitVariableDeclarationList(VariableDeclarationList node) {
    return transformIfUnchangedList(node, node.declarations,
        (e) => VariableDeclarationList(node.keyword, e));
  }

  @override
  Node visitVariableInitialization(VariableInitialization node) {
    final declaration = visit<VariableBinding>(node.declaration);
    final value = visitNullable<Expression>(node.value);
    if (isUnchanged(node.declaration, declaration) &&
        isUnchanged(node.value, value)) {
      return node;
    }
    return VariableInitialization(declaration, value);
  }

  @override
  Node visitWhile(While node) {
    return transformIfUnchanged2(node, node.condition, node.body, While.new);
  }

  @override
  Node visitYield(Yield node) {
    final value = visitNullable<Expression>(node.value);
    if (isUnchanged(node.value, value)) {
      return node;
    }
    return Yield(value, star: node.star);
  }
}
