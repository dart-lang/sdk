// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_ast;

abstract class NodeVisitor<T> implements TypeRefVisitor<T> {
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
  T visitSwitchCase(SwitchCase node);
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
  T visitModule(Module node);

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

abstract class TypeRefVisitor<T> {
  T visitQualifiedTypeRef(QualifiedTypeRef node);
  T visitGenericTypeRef(GenericTypeRef node);
  T visitUnionTypeRef(UnionTypeRef node);
  T visitRecordTypeRef(RecordTypeRef node);
  T visitOptionalTypeRef(OptionalTypeRef node);
  T visitFunctionTypeRef(FunctionTypeRef node);
  T visitAnyTypeRef(AnyTypeRef node);
  T visitUnknownTypeRef(UnknownTypeRef node);
  T visitArrayTypeRef(ArrayTypeRef node);
}

class BaseVisitor<T> implements NodeVisitor<T> {
  T visitNode(Node node) {
    node.visitChildren(this);
    return null;
  }

  T visitProgram(Program node) => visitNode(node);

  T visitStatement(Statement node) => visitModuleItem(node);
  T visitLoop(Loop node) => visitStatement(node);
  T visitJump(Statement node) => visitStatement(node);

  T visitBlock(Block node) => visitStatement(node);
  T visitDebuggerStatement(node) => visitStatement(node);
  T visitExpressionStatement(ExpressionStatement node) => visitStatement(node);
  T visitEmptyStatement(EmptyStatement node) => visitStatement(node);
  T visitIf(If node) => visitStatement(node);
  T visitFor(For node) => visitLoop(node);
  T visitForIn(ForIn node) => visitLoop(node);
  T visitForOf(ForOf node) => visitLoop(node);
  T visitWhile(While node) => visitLoop(node);
  T visitDo(Do node) => visitLoop(node);
  T visitContinue(Continue node) => visitJump(node);
  T visitBreak(Break node) => visitJump(node);
  T visitReturn(Return node) => visitJump(node);
  T visitThrow(Throw node) => visitJump(node);
  T visitTry(Try node) => visitStatement(node);
  T visitSwitch(Switch node) => visitStatement(node);
  T visitFunctionDeclaration(FunctionDeclaration node) => visitStatement(node);
  T visitLabeledStatement(LabeledStatement node) => visitStatement(node);
  T visitLiteralStatement(LiteralStatement node) => visitStatement(node);

  T visitCatch(Catch node) => visitNode(node);
  T visitSwitchCase(SwitchCase node) => visitNode(node);

  T visitExpression(Expression node) => visitNode(node);

  T visitLiteralExpression(LiteralExpression node) => visitExpression(node);
  T visitVariableDeclarationList(VariableDeclarationList node) =>
      visitExpression(node);
  T visitAssignment(Assignment node) => visitExpression(node);
  T visitVariableInitialization(VariableInitialization node) =>
      visitExpression(node);

  T visitConditional(Conditional node) => visitExpression(node);
  T visitNew(New node) => visitExpression(node);
  T visitCall(Call node) => visitExpression(node);
  T visitBinary(Binary node) => visitExpression(node);
  T visitPrefix(Prefix node) => visitExpression(node);
  T visitPostfix(Postfix node) => visitExpression(node);
  T visitSpread(Spread node) => visitPrefix(node);
  T visitYield(Yield node) => visitExpression(node);
  T visitAccess(PropertyAccess node) => visitExpression(node);

  T visitIdentifier(Identifier node) => visitExpression(node);
  T visitThis(This node) => visitExpression(node);
  T visitSuper(Super node) => visitExpression(node);

  T visitRestParameter(RestParameter node) => visitNode(node);

  T visitNamedFunction(NamedFunction node) => visitExpression(node);
  T visitFunctionExpression(FunctionExpression node) => visitExpression(node);
  T visitFun(Fun node) => visitFunctionExpression(node);
  T visitArrowFun(ArrowFun node) => visitFunctionExpression(node);

  T visitLiteral(Literal node) => visitExpression(node);

  T visitLiteralBool(LiteralBool node) => visitLiteral(node);
  T visitLiteralString(LiteralString node) => visitLiteral(node);
  T visitLiteralNumber(LiteralNumber node) => visitLiteral(node);
  T visitLiteralNull(LiteralNull node) => visitLiteral(node);

  T visitArrayInitializer(ArrayInitializer node) => visitExpression(node);
  T visitArrayHole(ArrayHole node) => visitExpression(node);
  T visitObjectInitializer(ObjectInitializer node) => visitExpression(node);
  T visitProperty(Property node) => visitNode(node);
  T visitRegExpLiteral(RegExpLiteral node) => visitExpression(node);
  T visitTemplateString(TemplateString node) => visitExpression(node);
  T visitTaggedTemplate(TaggedTemplate node) => visitExpression(node);

  T visitClassDeclaration(ClassDeclaration node) => visitStatement(node);
  T visitClassExpression(ClassExpression node) => visitExpression(node);
  T visitMethod(Method node) => visitProperty(node);

  T visitModuleItem(ModuleItem node) => visitNode(node);
  T visitImportDeclaration(ImportDeclaration node) => visitModuleItem(node);
  T visitExportDeclaration(ExportDeclaration node) => visitModuleItem(node);
  T visitExportClause(ExportClause node) => visitNode(node);
  T visitNameSpecifier(NameSpecifier node) => visitNode(node);
  T visitModule(Module node) => visitNode(node);

  T visitInterpolatedNode(InterpolatedNode node) => visitNode(node);

  T visitInterpolatedExpression(InterpolatedExpression node) =>
      visitInterpolatedNode(node);
  T visitInterpolatedLiteral(InterpolatedLiteral node) =>
      visitInterpolatedNode(node);
  T visitInterpolatedParameter(InterpolatedParameter node) =>
      visitInterpolatedNode(node);
  T visitInterpolatedSelector(InterpolatedSelector node) =>
      visitInterpolatedNode(node);
  T visitInterpolatedStatement(InterpolatedStatement node) =>
      visitInterpolatedNode(node);
  T visitInterpolatedMethod(InterpolatedMethod node) =>
      visitInterpolatedNode(node);
  T visitInterpolatedIdentifier(InterpolatedIdentifier node) =>
      visitInterpolatedNode(node);

  // Ignore comments by default.
  T visitComment(Comment node) => null;
  T visitCommentExpression(CommentExpression node) => null;

  T visitAwait(Await node) => visitExpression(node);
  T visitDartYield(DartYield node) => visitStatement(node);

  T visitBindingPattern(BindingPattern node) => visitNode(node);
  T visitArrayBindingPattern(ArrayBindingPattern node) =>
      visitBindingPattern(node);
  T visitObjectBindingPattern(ObjectBindingPattern node) =>
      visitBindingPattern(node);
  T visitDestructuredVariable(DestructuredVariable node) => visitNode(node);
  T visitSimpleBindingPattern(SimpleBindingPattern node) => visitNode(node);

  T visitTypeRef(TypeRef node) => visitNode(node);
  T visitQualifiedTypeRef(QualifiedTypeRef node) => visitTypeRef(node);
  T visitGenericTypeRef(GenericTypeRef node) => visitTypeRef(node);
  T visitOptionalTypeRef(OptionalTypeRef node) => visitTypeRef(node);
  T visitRecordTypeRef(RecordTypeRef node) => visitTypeRef(node);
  T visitUnionTypeRef(UnionTypeRef node) => visitTypeRef(node);
  T visitFunctionTypeRef(FunctionTypeRef node) => visitTypeRef(node);
  T visitAnyTypeRef(AnyTypeRef node) => visitTypeRef(node);
  T visitUnknownTypeRef(UnknownTypeRef node) => visitTypeRef(node);
  T visitArrayTypeRef(ArrayTypeRef node) => visitTypeRef(node);
}

abstract class Node {
  /// Sets the source location of this node. For performance reasons, we allow
  /// setting this after construction.
  Object sourceInformation;

  /// Closure annotation of this node.
  ClosureAnnotation closureAnnotation;

  T accept<T>(NodeVisitor<T> visitor);
  void visitChildren(NodeVisitor visitor);

  // Shallow clone of node.  Does not clone positions since the only use of this
  // private method is create a copy with a new position.
  Node _clone();

  // Returns a node equivalent to [this], but with new source position and end
  // source position.
  Node withSourceInformation(sourceInformation) {
    if (sourceInformation == this.sourceInformation) {
      return this;
    }
    Node clone = _clone();
    // TODO(sra): Should existing data be 'sticky' if we try to overwrite with
    // `null`?
    clone.sourceInformation = sourceInformation;
    return clone;
  }

  bool get isCommaOperator => false;

  Statement toStatement() {
    throw UnsupportedError('toStatement');
  }

  Statement toReturn() {
    throw UnsupportedError('toReturn');
  }

  // For debugging
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
  /// Script tag hash-bang, e.g. `#!/usr/bin/env node`
  final String scriptTag;

  /// Top-level statements in the program.
  final List<ModuleItem> body;

  /// The module's own name.
  ///
  /// This is not used in ES6, but is provided to allow module lowering.
  final String name;

  Program(this.body, {this.scriptTag, this.name});

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitProgram(this);
  void visitChildren(NodeVisitor visitor) {
    for (ModuleItem statement in body) statement.accept(visitor);
  }

  Program _clone() => Program(body);
}

abstract class Statement extends ModuleItem {
  static Statement from(List<Statement> statements) {
    // TODO(jmesserly): empty block singleton? Should this use empty statement?
    if (statements.length == 0) return Block([]);
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

  /// Whether this statement would always `return` if used as a funtion body.
  ///
  /// This is only well defined on the outermost block; it cannot be used for a
  /// block inside of a loop (because of `break` and `continue`).
  bool get alwaysReturns => false;

  /// If this statement [shadows] any name from [names], this will wrap it in a
  /// new scoped [Block].
  Statement toScopedBlock(Set<String> names) {
    return shadows(names) ? Block([this], isScope: true) : this;
  }

  Statement toStatement() => this;
  Statement toReturn() => Block([this, Return()]);

  Block toBlock() => Block([this]);
}

class Block extends Statement {
  final List<Statement> statements;

  /// True to preserve this [Block] for scoping reasons.
  final bool isScope;

  Block(this.statements, {this.isScope = false}) {
    assert(statements.every((s) => s is Statement));
  }
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

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitBlock(this);
  void visitChildren(NodeVisitor visitor) {
    for (Statement statement in statements) statement.accept(visitor);
  }

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

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitExpressionStatement(this);
  void visitChildren(NodeVisitor visitor) {
    expression.accept(visitor);
  }

  ExpressionStatement _clone() => ExpressionStatement(expression);
}

class EmptyStatement extends Statement {
  EmptyStatement();

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitEmptyStatement(this);
  void visitChildren(NodeVisitor visitor) {}
  EmptyStatement _clone() => EmptyStatement();
}

class If extends Statement {
  final Expression condition;
  final Statement then;
  final Statement otherwise;

  If(this.condition, this.then, this.otherwise);
  If.noElse(this.condition, this.then) : this.otherwise = null;

  @override
  bool get alwaysReturns =>
      hasElse && then.alwaysReturns && otherwise.alwaysReturns;

  bool get hasElse => otherwise != null;

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitIf(this);

  void visitChildren(NodeVisitor visitor) {
    condition.accept(visitor);
    then.accept(visitor);
    if (otherwise != null) otherwise.accept(visitor);
  }

  If _clone() => If(condition, then, otherwise);
}

abstract class Loop extends Statement {
  final Statement body;
  Loop(this.body);
}

class For extends Loop {
  final Expression init;
  final Expression condition;
  final Expression update;

  For(this.init, this.condition, this.update, Statement body) : super(body);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitFor(this);

  void visitChildren(NodeVisitor visitor) {
    if (init != null) init.accept(visitor);
    if (condition != null) condition.accept(visitor);
    if (update != null) update.accept(visitor);
    body.accept(visitor);
  }

  For _clone() => For(init, condition, update, body);
}

class ForIn extends Loop {
  // Note that [VariableDeclarationList] is a subclass of [Expression].
  // Therefore we can type the leftHandSide as [Expression].
  final Expression leftHandSide;
  final Expression object;

  ForIn(this.leftHandSide, this.object, Statement body) : super(body);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitForIn(this);

  void visitChildren(NodeVisitor visitor) {
    leftHandSide.accept(visitor);
    object.accept(visitor);
    body.accept(visitor);
  }

  ForIn _clone() => ForIn(leftHandSide, object, body);
}

class ForOf extends Loop {
  // Note that [VariableDeclarationList] is a subclass of [Expression].
  // Therefore we can type the leftHandSide as [Expression].
  final Expression leftHandSide;
  final Expression iterable;

  ForOf(this.leftHandSide, this.iterable, Statement body) : super(body);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitForOf(this);

  void visitChildren(NodeVisitor visitor) {
    leftHandSide.accept(visitor);
    iterable.accept(visitor);
    body.accept(visitor);
  }

  ForIn _clone() => ForIn(leftHandSide, iterable, body);
}

class While extends Loop {
  final Expression condition;

  While(this.condition, Statement body) : super(body);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitWhile(this);

  void visitChildren(NodeVisitor visitor) {
    condition.accept(visitor);
    body.accept(visitor);
  }

  While _clone() => While(condition, body);
}

class Do extends Loop {
  final Expression condition;

  Do(Statement body, this.condition) : super(body);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitDo(this);

  void visitChildren(NodeVisitor visitor) {
    body.accept(visitor);
    condition.accept(visitor);
  }

  Do _clone() => Do(body, condition);
}

class Continue extends Statement {
  final String targetLabel; // Can be null.

  Continue(this.targetLabel);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitContinue(this);
  void visitChildren(NodeVisitor visitor) {}

  Continue _clone() => Continue(targetLabel);
}

class Break extends Statement {
  final String targetLabel; // Can be null.

  Break(this.targetLabel);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitBreak(this);
  void visitChildren(NodeVisitor visitor) {}

  Break _clone() => Break(targetLabel);
}

class Return extends Statement {
  final Expression value; // Can be null.

  Return([this.value = null]);

  @override
  bool get alwaysReturns => true;

  Statement toReturn() => this;

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitReturn(this);

  void visitChildren(NodeVisitor visitor) {
    if (value != null) value.accept(visitor);
  }

  Return _clone() => Return(value);

  static bool foundIn(Node node) {
    _returnFinder.found = false;
    node.accept(_returnFinder);
    return _returnFinder.found;
  }
}

final _returnFinder = _ReturnFinder();

class _ReturnFinder extends BaseVisitor {
  bool found = false;
  visitReturn(Return node) {
    found = true;
  }

  visitNode(Node node) {
    if (!found) super.visitNode(node);
  }
}

class Throw extends Statement {
  final Expression expression;

  Throw(this.expression);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitThrow(this);

  void visitChildren(NodeVisitor visitor) {
    expression.accept(visitor);
  }

  Throw _clone() => Throw(expression);
}

class Try extends Statement {
  final Block body;
  final Catch catchPart; // Can be null if [finallyPart] is non-null.
  final Block finallyPart; // Can be null if [catchPart] is non-null.

  Try(this.body, this.catchPart, this.finallyPart) {
    assert(catchPart != null || finallyPart != null);
  }

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitTry(this);

  void visitChildren(NodeVisitor visitor) {
    body.accept(visitor);
    if (catchPart != null) catchPart.accept(visitor);
    if (finallyPart != null) finallyPart.accept(visitor);
  }

  Try _clone() => Try(body, catchPart, finallyPart);
}

class Catch extends Node {
  final Identifier declaration;
  final Block body;

  Catch(this.declaration, this.body);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitCatch(this);

  void visitChildren(NodeVisitor visitor) {
    declaration.accept(visitor);
    body.accept(visitor);
  }

  Catch _clone() => Catch(declaration, body);
}

class Switch extends Statement {
  final Expression key;
  final List<SwitchCase> cases;

  Switch(this.key, this.cases);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitSwitch(this);

  void visitChildren(NodeVisitor visitor) {
    key.accept(visitor);
    for (var clause in cases) clause.accept(visitor);
  }

  Switch _clone() => Switch(key, cases);
}

class SwitchCase extends Node {
  final Expression expression;
  final Block body;

  SwitchCase(this.expression, this.body);
  SwitchCase.defaultCase(this.body) : expression = null;

  bool get isDefault => expression == null;

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitSwitchCase(this);

  void visitChildren(NodeVisitor visitor) {
    expression?.accept(visitor);
    body.accept(visitor);
  }

  SwitchCase _clone() => SwitchCase(expression, body);
}

class FunctionDeclaration extends Statement {
  final Identifier name;
  final Fun function;

  FunctionDeclaration(this.name, this.function);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitFunctionDeclaration(this);

  void visitChildren(NodeVisitor visitor) {
    name.accept(visitor);
    function.accept(visitor);
  }

  FunctionDeclaration _clone() => FunctionDeclaration(name, function);
}

class LabeledStatement extends Statement {
  final String label;
  final Statement body;

  LabeledStatement(this.label, this.body);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLabeledStatement(this);

  void visitChildren(NodeVisitor visitor) {
    body.accept(visitor);
  }

  LabeledStatement _clone() => LabeledStatement(label, body);
}

class LiteralStatement extends Statement {
  final String code;

  LiteralStatement(this.code);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralStatement(this);
  void visitChildren(NodeVisitor visitor) {}

  LiteralStatement _clone() => LiteralStatement(code);
}

// Not a real JavaScript node, but represents the yield statement from a dart
// program translated to JavaScript.
class DartYield extends Statement {
  final Expression expression;

  final bool hasStar;

  DartYield(this.expression, this.hasStar);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitDartYield(this);

  void visitChildren(NodeVisitor visitor) {
    expression.accept(visitor);
  }

  DartYield _clone() => DartYield(expression, hasStar);
}

abstract class Expression extends Node {
  Expression();

  factory Expression.binary(List<Expression> exprs, String op) {
    Expression comma = null;
    for (var node in exprs) {
      comma = (comma == null) ? node : Binary(op, comma, node);
    }
    return comma;
  }

  int get precedenceLevel;

  Statement toStatement() => ExpressionStatement(toVoidExpression());
  Statement toReturn() => Return(this);

  // TODO(jmesserly): make this return a Yield?
  Statement toYieldStatement({bool star = false}) =>
      ExpressionStatement(Yield(this, star: star));

  Expression toVoidExpression() => this;
  Expression toAssignExpression(Expression left, [String op]) =>
      Assignment.compound(left, op, this);

  // TODO(jmesserly): make this work for more cases?
  Statement toVariableDeclaration(VariableBinding name) =>
      VariableDeclarationList('let', [VariableInitialization(name, this)])
          .toStatement();
}

class LiteralExpression extends Expression {
  final String template;
  final List<Expression> inputs;

  LiteralExpression(this.template) : inputs = const [];
  LiteralExpression.withData(this.template, this.inputs);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralExpression(this);

  void visitChildren(NodeVisitor visitor) {
    if (inputs != null) {
      for (Expression expr in inputs) expr.accept(visitor);
    }
  }

  LiteralExpression _clone() => LiteralExpression.withData(template, inputs);

  // Code that uses JS must take care of operator precedences, and
  // put parenthesis if needed.
  int get precedenceLevel => PRIMARY;
}

/**
 * [VariableDeclarationList] is a subclass of [Expression] to simplify the
 * AST.
 */
class VariableDeclarationList extends Expression {
  /**
   * The `var` or `let` or `const` keyword used for this variable declaration
   * list.
   */
  final String keyword;
  final List<VariableInitialization> declarations;

  VariableDeclarationList(this.keyword, this.declarations);

  /// True if this declares any name from [names].
  ///
  /// Analogous to the predicate [Statement.shadows].
  bool shadows(Set<String> names) {
    if (keyword == 'var') return false;
    for (var d in declarations) if (d.declaration.shadows(names)) return true;
    return false;
  }

  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitVariableDeclarationList(this);

  void visitChildren(NodeVisitor visitor) {
    for (VariableInitialization declaration in declarations) {
      declaration.accept(visitor);
    }
  }

  VariableDeclarationList _clone() =>
      VariableDeclarationList(keyword, declarations);

  int get precedenceLevel => EXPRESSION;
}

class Assignment extends Expression {
  final Expression leftHandSide;
  final String op; // Null, if the assignment is not compound.
  final Expression value;

  Assignment(this.leftHandSide, this.value) : op = null;
  Assignment.compound(this.leftHandSide, this.op, this.value);

  int get precedenceLevel => ASSIGNMENT;

  bool get isCompound => op != null;

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitAssignment(this);

  void visitChildren(NodeVisitor visitor) {
    leftHandSide.accept(visitor);
    if (value != null) value.accept(visitor);
  }

  Assignment _clone() => Assignment.compound(leftHandSide, op, value);
}

class VariableInitialization extends Expression {
  final VariableBinding declaration;
  final Expression value; // May be null.

  /// [value] may be null.
  VariableInitialization(this.declaration, this.value);

  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitVariableInitialization(this);

  VariableInitialization _clone() => VariableInitialization(declaration, value);

  int get precedenceLevel => ASSIGNMENT;

  void visitChildren(NodeVisitor visitor) {
    declaration.accept(visitor);
    if (value != null) value.accept(visitor);
  }
}

abstract class VariableBinding extends Expression {
  /// True if this binding declares any name from [names].
  ///
  /// Analogous to the predicate [Statement.shadows].
  bool shadows(Set<String> names);
}

// TODO(jmesserly): destructuring was originally implemented in the context of
// Closure Compiler work. Rethink how this is represented.
class DestructuredVariable extends Expression implements Parameter {
  final Identifier name;

  /// The proprety in an object binding pattern, for example:
  ///
  ///     let key = 'z';
  ///     let {[key]: foo} = {z: 'bar'};
  ///     console.log(foo); // "bar"
  ///
  // TODO(jmesserly): parser does not support this feature.
  final Expression property;

  final BindingPattern structure;
  final Expression defaultValue;
  final TypeRef type;
  DestructuredVariable(
      {this.name,
      this.property,
      this.structure,
      this.defaultValue,
      this.type}) {
    assert(name != null || structure != null);
  }

  bool shadows(Set<String> names) {
    return (name?.shadows(names) ?? false) ||
        (structure?.shadows(names) ?? false);
  }

  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitDestructuredVariable(this);
  void visitChildren(NodeVisitor visitor) {
    name?.accept(visitor);
    structure?.accept(visitor);
    defaultValue?.accept(visitor);
  }

  /// Avoid parenthesis when pretty-printing.
  @override
  int get precedenceLevel => PRIMARY;
  @override
  Node _clone() => DestructuredVariable(
      name: name,
      property: property,
      structure: structure,
      defaultValue: defaultValue);
}

abstract class BindingPattern extends Expression implements VariableBinding {
  final List<DestructuredVariable> variables;
  BindingPattern(this.variables);

  bool shadows(Set<String> names) {
    for (var v in variables) if (v.shadows(names)) return true;
    return false;
  }

  void visitChildren(NodeVisitor visitor) {
    for (DestructuredVariable v in variables) v.accept(visitor);
  }
}

class SimpleBindingPattern extends BindingPattern {
  final Identifier name;
  SimpleBindingPattern(Identifier name)
      : name = name,
        super([DestructuredVariable(name: name)]);

  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitSimpleBindingPattern(this);

  @override
  bool shadows(Set<String> names) => names.contains(name.name);

  /// Avoid parenthesis when pretty-printing.
  @override
  int get precedenceLevel => PRIMARY;
  @override
  Node _clone() => SimpleBindingPattern(name);
}

class ObjectBindingPattern extends BindingPattern {
  ObjectBindingPattern(List<DestructuredVariable> variables) : super(variables);
  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitObjectBindingPattern(this);

  /// Avoid parenthesis when pretty-printing.
  @override
  int get precedenceLevel => PRIMARY;
  @override
  Node _clone() => ObjectBindingPattern(variables);
}

class ArrayBindingPattern extends BindingPattern {
  ArrayBindingPattern(List<DestructuredVariable> variables) : super(variables);
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitArrayBindingPattern(this);

  /// Avoid parenthesis when pretty-printing.
  @override
  int get precedenceLevel => PRIMARY;
  @override
  Node _clone() => ArrayBindingPattern(variables);
}

class Conditional extends Expression {
  final Expression condition;
  final Expression then;
  final Expression otherwise;

  Conditional(this.condition, this.then, this.otherwise);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitConditional(this);

  void visitChildren(NodeVisitor visitor) {
    condition.accept(visitor);
    then.accept(visitor);
    otherwise.accept(visitor);
  }

  Conditional _clone() => Conditional(condition, then, otherwise);

  int get precedenceLevel => ASSIGNMENT;
}

class Call extends Expression {
  Expression target;
  List<Expression> arguments;

  Call(this.target, this.arguments);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitCall(this);

  void visitChildren(NodeVisitor visitor) {
    target.accept(visitor);
    for (Expression arg in arguments) arg.accept(visitor);
  }

  Call _clone() => Call(target, arguments);

  int get precedenceLevel => CALL;
}

class New extends Call {
  New(Expression cls, List<Expression> arguments) : super(cls, arguments);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitNew(this);

  New _clone() => New(target, arguments);

  int get precedenceLevel => ACCESS;
}

class Binary extends Expression {
  final String op;
  final Expression left;
  final Expression right;

  Binary(this.op, this.left, this.right);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitBinary(this);

  Binary _clone() => Binary(op, left, right);

  void visitChildren(NodeVisitor visitor) {
    left.accept(visitor);
    right.accept(visitor);
  }

  bool get isCommaOperator => op == ',';

  Expression toVoidExpression() {
    if (!isCommaOperator) return super.toVoidExpression();
    var l = left.toVoidExpression();
    var r = right.toVoidExpression();
    if (l == left && r == right) return this;
    return Binary(',', l, r);
  }

  Statement toStatement() {
    if (!isCommaOperator) return super.toStatement();
    return Block([left.toStatement(), right.toStatement()]);
  }

  Statement toReturn() {
    if (!isCommaOperator) return super.toReturn();
    return Block([left.toStatement(), right.toReturn()]);
  }

  Statement toYieldStatement({bool star = false}) {
    if (!isCommaOperator) return super.toYieldStatement(star: star);
    return Block([left.toStatement(), right.toYieldStatement(star: star)]);
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

  int get precedenceLevel {
    // TODO(floitsch): switch to constant map.
    switch (op) {
      case "*":
      case "/":
      case "%":
        return MULTIPLICATIVE;
      case "+":
      case "-":
        return ADDITIVE;
      case "<<":
      case ">>":
      case ">>>":
        return SHIFT;
      case "<":
      case ">":
      case "<=":
      case ">=":
      case "instanceof":
      case "in":
        return RELATIONAL;
      case "==":
      case "===":
      case "!=":
      case "!==":
        return EQUALITY;
      case "&":
        return BIT_AND;
      case "^":
        return BIT_XOR;
      case "|":
        return BIT_OR;
      case "&&":
        return LOGICAL_AND;
      case "||":
        return LOGICAL_OR;
      case ',':
        return EXPRESSION;
      default:
        throw "Internal Error: Unhandled binary operator: $op";
    }
  }
}

class Prefix extends Expression {
  final String op;
  final Expression argument;

  Prefix(this.op, this.argument);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitPrefix(this);

  Prefix _clone() => Prefix(op, argument);

  void visitChildren(NodeVisitor visitor) {
    argument.accept(visitor);
  }

  int get precedenceLevel => UNARY;
}

// SpreadElement isn't really a prefix expression, as it can only appear in
// certain places such as ArgumentList and BindingPattern, but we pretend
// it is for simplicity's sake.
class Spread extends Prefix {
  Spread(Expression operand) : super('...', operand);
  int get precedenceLevel => SPREAD;

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitSpread(this);
  Spread _clone() => Spread(argument);
}

class Postfix extends Expression {
  final String op;
  final Expression argument;

  Postfix(this.op, this.argument);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitPostfix(this);

  Postfix _clone() => Postfix(op, argument);

  void visitChildren(NodeVisitor visitor) {
    argument.accept(visitor);
  }

  int get precedenceLevel => UNARY;
}

abstract class Parameter implements Expression, VariableBinding {
  TypeRef get type;
}

class Identifier extends Expression implements Parameter {
  final String name;
  final bool allowRename;
  final TypeRef type;

  Identifier(this.name, {this.allowRename = true, this.type}) {
    if (!_identifierRE.hasMatch(name)) {
      throw ArgumentError.value(name, "name", "not a valid identifier");
    }
  }
  static RegExp _identifierRE = RegExp(r'^[A-Za-z_$][A-Za-z_$0-9]*$');

  bool shadows(Set<String> names) => names.contains(name);

  Identifier _clone() => Identifier(name, allowRename: allowRename);
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitIdentifier(this);
  int get precedenceLevel => PRIMARY;
  void visitChildren(NodeVisitor visitor) {}
}

// This is an expression for convenience in the AST.
class RestParameter extends Expression implements Parameter {
  final Identifier parameter;
  TypeRef get type => null;

  RestParameter(this.parameter);

  bool shadows(Set<String> names) => names.contains(parameter.name);

  RestParameter _clone() => RestParameter(parameter);
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitRestParameter(this);
  void visitChildren(NodeVisitor visitor) {
    parameter.accept(visitor);
  }

  int get precedenceLevel => PRIMARY;
}

class This extends Expression {
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitThis(this);
  This _clone() => This();
  int get precedenceLevel => PRIMARY;
  void visitChildren(NodeVisitor visitor) {}

  static bool foundIn(Node node) {
    _thisFinder.found = false;
    node.accept(_thisFinder);
    return _thisFinder.found;
  }
}

final _thisFinder = _ThisFinder();

class _ThisFinder extends BaseVisitor {
  bool found = false;
  visitThis(This node) {
    found = true;
  }

  visitNode(Node node) {
    if (!found) super.visitNode(node);
  }
}

// `super` is more restricted in the ES6 spec, but for simplicity we accept
// it anywhere that `this` is accepted.
class Super extends Expression {
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitSuper(this);
  Super _clone() => Super();
  int get precedenceLevel => PRIMARY;
  void visitChildren(NodeVisitor visitor) {}
}

class NamedFunction extends Expression {
  final Identifier name;
  final Fun function;
  // A heuristic to force extra parens around this function.  V8 and other
  // engines use this IIFE (immediately invoked function expression) heuristic
  // to eagerly parse a function.
  final bool immediatelyInvoked;

  NamedFunction(this.name, this.function, [this.immediatelyInvoked = false]);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitNamedFunction(this);

  void visitChildren(NodeVisitor visitor) {
    name.accept(visitor);
    function.accept(visitor);
  }

  NamedFunction _clone() => NamedFunction(name, function, immediatelyInvoked);

  int get precedenceLevel =>
      immediatelyInvoked ? EXPRESSION : PRIMARY_LOW_PRECEDENCE;
}

abstract class FunctionExpression extends Expression {
  List<Parameter> get params;

  get body; // Expression or block
  /// Type parameters passed to this generic function, if any. `null` otherwise.
  // TODO(ochafik): Support type bounds.
  List<Identifier> get typeParams;

  /// Return type of this function, if any. `null` otherwise.
  TypeRef get returnType;
}

class Fun extends FunctionExpression {
  final List<Parameter> params;
  final Block body;
  @override
  final List<Identifier> typeParams;
  @override
  final TypeRef returnType;

  /** Whether this is a JS generator (`function*`) that may contain `yield`. */
  final bool isGenerator;

  final AsyncModifier asyncModifier;

  Fun(this.params, this.body,
      {this.isGenerator = false,
      this.asyncModifier = const AsyncModifier.sync(),
      this.typeParams,
      this.returnType});

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitFun(this);

  void visitChildren(NodeVisitor visitor) {
    for (Parameter param in params) param.accept(visitor);
    body.accept(visitor);
  }

  Fun _clone() =>
      Fun(params, body, isGenerator: isGenerator, asyncModifier: asyncModifier);

  int get precedenceLevel => PRIMARY_LOW_PRECEDENCE;
}

class ArrowFun extends FunctionExpression {
  final List<Parameter> params;
  final body; // Expression or Block
  @override
  final List<Identifier> typeParams;
  @override
  final TypeRef returnType;

  ArrowFun(this.params, this.body, {this.typeParams, this.returnType});

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitArrowFun(this);

  void visitChildren(NodeVisitor visitor) {
    for (Parameter param in params) param.accept(visitor);
    body.accept(visitor);
  }

  int get precedenceLevel => PRIMARY_LOW_PRECEDENCE;

  ArrowFun _clone() => ArrowFun(params, body);
}

/**
 * The Dart sync, sync*, async, and async* modifier.
 * See [DartYield].
 *
 * This is not used for JS functions.
 */
class AsyncModifier {
  final bool isAsync;
  final bool isYielding;
  final String description;

  const AsyncModifier.sync()
      : isAsync = false,
        isYielding = false,
        description = "sync";
  const AsyncModifier.async()
      : isAsync = true,
        isYielding = false,
        description = "async";
  const AsyncModifier.asyncStar()
      : isAsync = true,
        isYielding = true,
        description = "async*";
  const AsyncModifier.syncStar()
      : isAsync = false,
        isYielding = true,
        description = "sync*";
  toString() => description;
}

class PropertyAccess extends Expression {
  final Expression receiver;
  final Expression selector;

  PropertyAccess(this.receiver, this.selector);
  PropertyAccess.field(this.receiver, String fieldName)
      : selector = LiteralString('"$fieldName"');
  PropertyAccess.indexed(this.receiver, int index)
      : selector = LiteralNumber('$index');

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitAccess(this);

  void visitChildren(NodeVisitor visitor) {
    receiver.accept(visitor);
    selector.accept(visitor);
  }

  PropertyAccess _clone() => PropertyAccess(receiver, selector);

  int get precedenceLevel => ACCESS;
}

abstract class Literal extends Expression {
  void visitChildren(NodeVisitor visitor) {}

  int get precedenceLevel => PRIMARY;
}

class LiteralBool extends Literal {
  final bool value;

  LiteralBool(this.value);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralBool(this);
  // [visitChildren] inherited from [Literal].
  LiteralBool _clone() => LiteralBool(value);
}

class LiteralNull extends Literal {
  LiteralNull();

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralNull(this);
  LiteralNull _clone() => LiteralNull();
}

class LiteralString extends Literal {
  final String value;

  /**
   * Constructs a LiteralString from a string value.
   *
   * The constructor does not add the required quotes.  If [value] is not
   * surrounded by quotes and property escaped, the resulting object is invalid
   * as a JS value.
   *
   * TODO(sra): Introduce variants for known valid strings that don't allocate a
   * new string just to add quotes.
   */
  LiteralString(this.value);

  /// Gets the value inside the string without the beginning and end quotes.
  String get valueWithoutQuotes => value.substring(1, value.length - 1);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralString(this);
  LiteralString _clone() => LiteralString(value);
}

class LiteralNumber extends Literal {
  final String value; // Must be a valid JavaScript number literal.

  LiteralNumber(this.value);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitLiteralNumber(this);
  LiteralNumber _clone() => LiteralNumber(value);

  /**
   * Use a different precedence level depending on whether the value contains a
   * dot to ensure we generate `(1).toString()` and `1.0.toString()`.
   */
  int get precedenceLevel => value.contains('.') ? PRIMARY : UNARY;
}

class ArrayInitializer extends Expression {
  final List<Expression> elements;
  final bool multiline;

  ArrayInitializer(this.elements, {this.multiline = false});

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitArrayInitializer(this);

  void visitChildren(NodeVisitor visitor) {
    for (Expression element in elements) element.accept(visitor);
  }

  ArrayInitializer _clone() => ArrayInitializer(elements);

  int get precedenceLevel => PRIMARY;
}

/**
 * An empty place in an [ArrayInitializer].
 * For example the list [1, , , 2] would contain two holes.
 */
class ArrayHole extends Expression {
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitArrayHole(this);

  void visitChildren(NodeVisitor visitor) {}

  ArrayHole _clone() => ArrayHole();

  int get precedenceLevel => PRIMARY;
}

class ObjectInitializer extends Expression {
  final List<Property> properties;
  final bool _multiline;

  /**
   * Constructs a new object-initializer containing the given [properties].
   */
  ObjectInitializer(this.properties, {bool multiline = false})
      : _multiline = multiline;

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitObjectInitializer(this);

  void visitChildren(NodeVisitor visitor) {
    for (Property init in properties) init.accept(visitor);
  }

  ObjectInitializer _clone() => ObjectInitializer(properties);

  int get precedenceLevel => PRIMARY;
  /**
   * If set to true, forces a vertical layout when using the [Printer].
   * Otherwise, layout will be vertical if and only if any [properties]
   * are [FunctionExpression]s.
   */
  bool get multiline {
    return _multiline || properties.any((p) => p.value is FunctionExpression);
  }
}

class Property extends Node {
  final Expression name;
  final Expression value;

  Property(this.name, this.value);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitProperty(this);

  void visitChildren(NodeVisitor visitor) {
    name.accept(visitor);
    value.accept(visitor);
  }

  Property _clone() => Property(name, value);
}

// TODO(jmesserly): parser does not support this yet.
class TemplateString extends Expression {
  /**
   * The parts of this template string: a sequence of [String]s and
   * [Expression]s. Strings and expressions will alternate, for example:
   *
   *     `foo${1 + 2} bar ${'hi'}`
   *
   * would be represented by [strings]:
   *
   *     ['foo', ' bar ', '']
   *
   * and [interpolations]:
   *
   *     [new JS.Binary('+', js.number(1), js.number(2)),
   *      new JS.LiteralString("'hi'")]
   *
   * There should be exactly one more string than interpolation expression.
   */
  final List<String> strings;
  final List<Expression> interpolations;

  TemplateString(this.strings, this.interpolations) {
    assert(strings.length == interpolations.length + 1);
  }

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitTemplateString(this);

  void visitChildren(NodeVisitor visitor) {
    for (var element in interpolations) {
      element.accept(visitor);
    }
  }

  TemplateString _clone() => TemplateString(strings, interpolations);

  int get precedenceLevel => PRIMARY;
}

// TODO(jmesserly): parser does not support this yet.
class TaggedTemplate extends Expression {
  final Expression tag;
  final TemplateString template;

  TaggedTemplate(this.tag, this.template);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitTaggedTemplate(this);

  void visitChildren(NodeVisitor visitor) {
    tag.accept(visitor);
    template.accept(visitor);
  }

  TaggedTemplate _clone() => TaggedTemplate(tag, template);

  int get precedenceLevel => CALL;
}

// TODO(jmesserly): parser does not support this yet.
class Yield extends Expression {
  final Expression value; // Can be null.

  /**
   * Whether this yield expression is a `yield*` that iterates each item in
   * [value].
   */
  final bool star;

  Yield(this.value, {this.star = false});

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitYield(this);

  void visitChildren(NodeVisitor visitor) {
    if (value != null) value.accept(visitor);
  }

  Yield _clone() => Yield(value);

  int get precedenceLevel => YIELD;
}

class ClassDeclaration extends Statement {
  final ClassExpression classExpr;

  ClassDeclaration(this.classExpr);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitClassDeclaration(this);
  visitChildren(NodeVisitor visitor) => classExpr.accept(visitor);
  ClassDeclaration _clone() => ClassDeclaration(classExpr);
}

class ClassExpression extends Expression {
  final Identifier name;
  final Expression heritage; // Can be null.
  final List<Method> methods;

  /// Type parameters of this class, if any. `null` otherwise.
  // TODO(ochafik): Support type bounds.
  final List<Identifier> typeParams;

  /// Field declarations of this class (TypeScript / ES6_TYPED).
  final List<VariableDeclarationList> fields;

  ClassExpression(this.name, this.heritage, this.methods,
      {this.typeParams, this.fields});

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitClassExpression(this);

  void visitChildren(NodeVisitor visitor) {
    name.accept(visitor);
    if (heritage != null) heritage.accept(visitor);
    for (Method element in methods) element.accept(visitor);
    if (fields != null) {
      for (var field in fields) {
        field.accept(visitor);
      }
    }
    if (typeParams != null) {
      for (var typeParam in typeParams) {
        typeParam.accept(visitor);
      }
    }
  }

  @override
  ClassDeclaration toStatement() => ClassDeclaration(this);

  ClassExpression _clone() => ClassExpression(name, heritage, methods,
      typeParams: typeParams, fields: fields);

  int get precedenceLevel => PRIMARY_LOW_PRECEDENCE;
}

class Method extends Node implements Property {
  final Expression name;
  final Fun function;
  final bool isGetter;
  final bool isSetter;
  final bool isStatic;

  Method(this.name, this.function,
      {this.isGetter = false, this.isSetter = false, this.isStatic = false}) {
    assert(!isGetter || function.params.length == 0);
    assert(!isSetter || function.params.length == 1);
    assert(!isGetter && !isSetter || !function.isGenerator);
  }

  Fun get value => function;

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitMethod(this);

  void visitChildren(NodeVisitor visitor) {
    name.accept(visitor);
    function.accept(visitor);
  }

  Method _clone() => Method(name, function,
      isGetter: isGetter, isSetter: isSetter, isStatic: isStatic);
}

/// Tag class for all interpolated positions.
abstract class InterpolatedNode implements Node {
  get nameOrPosition;

  bool get isNamed => nameOrPosition is String;
  bool get isPositional => nameOrPosition is int;
}

class InterpolatedExpression extends Expression with InterpolatedNode {
  final nameOrPosition;

  InterpolatedExpression(this.nameOrPosition);

  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitInterpolatedExpression(this);
  void visitChildren(NodeVisitor visitor) {}
  InterpolatedExpression _clone() => InterpolatedExpression(nameOrPosition);

  int get precedenceLevel => PRIMARY;
}

class InterpolatedLiteral extends Literal with InterpolatedNode {
  final nameOrPosition;

  InterpolatedLiteral(this.nameOrPosition);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitInterpolatedLiteral(this);
  void visitChildren(NodeVisitor visitor) {}
  InterpolatedLiteral _clone() => InterpolatedLiteral(nameOrPosition);
}

class InterpolatedParameter extends Expression
    with InterpolatedNode
    implements Identifier {
  final nameOrPosition;
  TypeRef get type => null;

  String get name {
    throw "InterpolatedParameter.name must not be invoked";
  }

  bool shadows(Set<String> names) => false;

  bool get allowRename => false;

  InterpolatedParameter(this.nameOrPosition);

  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitInterpolatedParameter(this);
  void visitChildren(NodeVisitor visitor) {}
  InterpolatedParameter _clone() => InterpolatedParameter(nameOrPosition);

  int get precedenceLevel => PRIMARY;
}

class InterpolatedSelector extends Expression with InterpolatedNode {
  final nameOrPosition;

  InterpolatedSelector(this.nameOrPosition);

  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitInterpolatedSelector(this);
  void visitChildren(NodeVisitor visitor) {}
  InterpolatedSelector _clone() => InterpolatedSelector(nameOrPosition);

  int get precedenceLevel => PRIMARY;
}

class InterpolatedStatement extends Statement with InterpolatedNode {
  final nameOrPosition;

  InterpolatedStatement(this.nameOrPosition);

  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitInterpolatedStatement(this);
  void visitChildren(NodeVisitor visitor) {}
  InterpolatedStatement _clone() => InterpolatedStatement(nameOrPosition);
}

// TODO(jmesserly): generalize this to InterpolatedProperty?
class InterpolatedMethod extends Expression
    with InterpolatedNode
    implements Method {
  final nameOrPosition;

  InterpolatedMethod(this.nameOrPosition);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitInterpolatedMethod(this);
  void visitChildren(NodeVisitor visitor) {}
  InterpolatedMethod _clone() => InterpolatedMethod(nameOrPosition);

  int get precedenceLevel => PRIMARY;
  Expression get name => throw _unsupported;
  Fun get value => throw _unsupported;
  bool get isGetter => throw _unsupported;
  bool get isSetter => throw _unsupported;
  bool get isStatic => throw _unsupported;
  Fun get function => throw _unsupported;
  Error get _unsupported =>
      UnsupportedError('$runtimeType does not support this member.');
}

class InterpolatedIdentifier extends Expression
    with InterpolatedNode
    implements Identifier {
  final nameOrPosition;
  TypeRef get type => null;

  InterpolatedIdentifier(this.nameOrPosition);

  bool shadows(Set<String> names) => false;

  T accept<T>(NodeVisitor<T> visitor) =>
      visitor.visitInterpolatedIdentifier(this);
  void visitChildren(NodeVisitor visitor) {}
  InterpolatedIdentifier _clone() => InterpolatedIdentifier(nameOrPosition);

  int get precedenceLevel => PRIMARY;
  String get name => throw '$runtimeType does not support this member.';
  bool get allowRename => false;
}

/**
 * [RegExpLiteral]s, despite being called "Literal", do not inherit from
 * [Literal]. Indeed, regular expressions in JavaScript have a side-effect and
 * are thus not in the same category as numbers or strings.
 */
class RegExpLiteral extends Expression {
  /** Contains the pattern and the flags.*/
  final String pattern;

  RegExpLiteral(this.pattern);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitRegExpLiteral(this);
  void visitChildren(NodeVisitor visitor) {}
  RegExpLiteral _clone() => RegExpLiteral(pattern);

  int get precedenceLevel => PRIMARY;
}

/**
 * An asynchronous await.
 *
 * Not part of JavaScript. We desugar this expression before outputting.
 * Should only occur in a [Fun] with `asyncModifier` async or asyncStar.
 */
class Await extends Expression {
  /** The awaited expression. */
  final Expression expression;

  Await(this.expression);

  int get precedenceLevel => UNARY;
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitAwait(this);
  void visitChildren(NodeVisitor visitor) => expression.accept(visitor);
  Await _clone() => Await(expression);
}

/**
 * A comment.
 *
 * Extends [Statement] so we can add comments before statements in
 * [Block] and [Program].
 */
class Comment extends Statement {
  final String comment;

  Comment(this.comment);

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitComment(this);
  Comment _clone() => Comment(comment);

  void visitChildren(NodeVisitor visitor) {}
}

/**
 * A comment for expressions.
 *
 * Extends [Expression] so we can add comments before expressions.
 * Has the highest possible precedence, so we don't add parentheses around it.
 */
class CommentExpression extends Expression {
  final String comment;
  final Expression expression;

  CommentExpression(this.comment, this.expression);

  int get precedenceLevel => PRIMARY;
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitCommentExpression(this);
  CommentExpression _clone() => CommentExpression(comment, expression);

  void visitChildren(NodeVisitor visitor) => expression.accept(visitor);
}

class DebuggerStatement extends Statement {
  T accept<T>(NodeVisitor<T> visitor) => visitor.visitDebuggerStatement(this);
  DebuggerStatement _clone() => DebuggerStatement();
  void visitChildren(NodeVisitor visitor) {}
}

/**
 * Represents allowed module items:
 * [Statement], [ImportDeclaration], and [ExportDeclaration].
 */
abstract class ModuleItem extends Node {}

class ImportDeclaration extends ModuleItem {
  final Identifier defaultBinding; // Can be null.

  // Can be null, a single specifier of `* as name`, or a list.
  final List<NameSpecifier> namedImports;

  final LiteralString from;

  ImportDeclaration({this.defaultBinding, this.namedImports, this.from}) {
    assert(from != null);
  }

  /** The `import "name.js"` form of import */
  ImportDeclaration.all(LiteralString module) : this(from: module);

  /** If this import has `* as name` returns the name, otherwise null. */
  Identifier get importStarAs {
    if (namedImports != null &&
        namedImports.length == 1 &&
        namedImports[0].isStar) {
      return namedImports[0].asName;
    }
    return null;
  }

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitImportDeclaration(this);
  void visitChildren(NodeVisitor visitor) {
    if (namedImports != null) {
      for (NameSpecifier name in namedImports) name.accept(visitor);
    }
    from.accept(visitor);
  }

  ImportDeclaration _clone() => ImportDeclaration(
      defaultBinding: defaultBinding, namedImports: namedImports, from: from);
}

class ExportDeclaration extends ModuleItem {
  /**
   * Exports a name from this module.
   *
   * This can be a [ClassDeclaration] or [FunctionDeclaration].
   * If [isDefault] is true, it can also be an [Expression].
   * Otherwise it can be a [VariableDeclarationList] or an [ExportClause].
   */
  final Node exported;

  /** True if this is an `export default`. */
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
  List<Identifier> get exportedNames {
    if (isDefault) return [Identifier('default')];

    var exported = this.exported;
    if (exported is ClassDeclaration) return [exported.classExpr.name];
    if (exported is FunctionDeclaration) return [exported.name];
    if (exported is VariableDeclarationList) {
      return exported.declarations
          .map((i) => i.declaration as Identifier)
          .toList();
    }
    if (exported is ExportClause) {
      if (exported.exportStar) return null;
      return exported.exports.map((e) => e.name).toList();
    }
    throw StateError('invalid export declaration');
  }

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitExportDeclaration(this);
  visitChildren(NodeVisitor visitor) => exported.accept(visitor);
  ExportDeclaration _clone() =>
      ExportDeclaration(exported, isDefault: isDefault);
}

class ExportClause extends Node {
  final List<NameSpecifier> exports;
  final LiteralString from; // Can be null.

  ExportClause(this.exports, {this.from});

  /** The `export * from 'name.js'` form. */
  ExportClause.star(LiteralString from)
      : this([NameSpecifier.star()], from: from);

  /** True if this is an `export *`. */
  bool get exportStar => exports.length == 1 && exports[0].isStar;

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitExportClause(this);
  void visitChildren(NodeVisitor visitor) {
    for (NameSpecifier name in exports) name.accept(visitor);
    if (from != null) from.accept(visitor);
  }

  ExportClause _clone() => ExportClause(exports, from: from);
}

/** An import or export specifier. */
class NameSpecifier extends Node {
  final Identifier name;
  final Identifier asName; // Can be null.

  NameSpecifier(this.name, {this.asName});
  NameSpecifier.star() : this(null);

  /** True if this is a `* as someName` specifier. */
  bool get isStar => name == null;

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitNameSpecifier(this);
  void visitChildren(NodeVisitor visitor) {}
  NameSpecifier _clone() => NameSpecifier(name, asName: asName);
}

// TODO(jmesserly): should this be related to [Program]?
class Module extends Node {
  /// The module's name
  // TODO(jmesserly): this is not declared in ES6, but is known by the loader.
  // We use this because some ES5 desugarings require it.
  final String name;

  final List<ModuleItem> body;
  Module(this.body, {this.name});

  T accept<T>(NodeVisitor<T> visitor) => visitor.visitModule(this);
  void visitChildren(NodeVisitor visitor) {
    for (ModuleItem item in body) item.accept(visitor);
  }

  Module _clone() => Module(body);
}
