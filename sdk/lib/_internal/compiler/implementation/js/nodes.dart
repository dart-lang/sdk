// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js;

abstract class NodeVisitor<T> {
  T visitProgram(Program node);

  T visitBlock(Block node);
  T visitExpressionStatement(ExpressionStatement node);
  T visitEmptyStatement(EmptyStatement node);
  T visitIf(If node);
  T visitFor(For node);
  T visitForIn(ForIn node);
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

  T visitBlob(Blob node);
  T visitLiteralExpression(LiteralExpression node);
  T visitVariableDeclarationList(VariableDeclarationList node);
  T visitSequence(Sequence node);
  T visitAssignment(Assignment node);
  T visitVariableInitialization(VariableInitialization node);
  T visitConditional(Conditional cond);
  T visitNew(New node);
  T visitCall(Call node);
  T visitBinary(Binary node);
  T visitPrefix(Prefix node);
  T visitPostfix(Postfix node);

  T visitVariableUse(VariableUse node);
  T visitThis(This node);
  T visitVariableDeclaration(VariableDeclaration node);
  T visitParameter(Parameter node);
  T visitAccess(PropertyAccess node);

  T visitNamedFunction(NamedFunction node);
  T visitFun(Fun node);

  T visitLiteralBool(LiteralBool node);
  T visitLiteralString(LiteralString node);
  T visitLiteralNumber(LiteralNumber node);
  T visitLiteralNull(LiteralNull node);

  T visitArrayInitializer(ArrayInitializer node);
  T visitArrayElement(ArrayElement node);
  T visitObjectInitializer(ObjectInitializer node);
  T visitProperty(Property node);
  T visitRegExpLiteral(RegExpLiteral node);

  T visitComment(Comment node);

  T visitInterpolatedExpression(InterpolatedExpression node);
  T visitInterpolatedLiteral(InterpolatedLiteral node);
  T visitInterpolatedParameter(InterpolatedParameter node);
  T visitInterpolatedSelector(InterpolatedSelector node);
  T visitInterpolatedStatement(InterpolatedStatement node);
}

class BaseVisitor<T> implements NodeVisitor<T> {
  T visitNode(Node node) {
    node.visitChildren(this);
    return null;
  }

  T visitProgram(Program node) => visitNode(node);

  T visitStatement(Statement node) => visitNode(node);
  T visitLoop(Loop node) => visitStatement(node);
  T visitJump(Statement node) => visitStatement(node);

  T visitBlock(Block node) => visitStatement(node);
  T visitExpressionStatement(ExpressionStatement node)
      => visitStatement(node);
  T visitEmptyStatement(EmptyStatement node) => visitStatement(node);
  T visitIf(If node) => visitStatement(node);
  T visitFor(For node) => visitLoop(node);
  T visitForIn(ForIn node) => visitLoop(node);
  T visitWhile(While node) => visitLoop(node);
  T visitDo(Do node) => visitLoop(node);
  T visitContinue(Continue node) => visitJump(node);
  T visitBreak(Break node) => visitJump(node);
  T visitReturn(Return node) => visitJump(node);
  T visitThrow(Throw node) => visitJump(node);
  T visitTry(Try node) => visitStatement(node);
  T visitSwitch(Switch node) => visitStatement(node);
  T visitFunctionDeclaration(FunctionDeclaration node)
      => visitStatement(node);
  T visitLabeledStatement(LabeledStatement node) => visitStatement(node);
  T visitLiteralStatement(LiteralStatement node) => visitStatement(node);

  T visitCatch(Catch node) => visitNode(node);
  T visitCase(Case node) => visitNode(node);
  T visitDefault(Default node) => visitNode(node);

  T visitExpression(Expression node) => visitNode(node);
  T visitBlob(Blob node) => visitExpression(node);
  T visitVariableReference(VariableReference node) => visitExpression(node);

  T visitLiteralExpression(LiteralExpression node) => visitExpression(node);
  T visitVariableDeclarationList(VariableDeclarationList node)
      => visitExpression(node);
  T visitSequence(Sequence node) => visitExpression(node);
  T visitAssignment(Assignment node) => visitExpression(node);
  T visitVariableInitialization(VariableInitialization node) {
    if (node.value != null) {
      return visitAssignment(node);
    } else {
      return visitExpression(node);
    }
  }
  T visitConditional(Conditional node) => visitExpression(node);
  T visitNew(New node) => visitExpression(node);
  T visitCall(Call node) => visitExpression(node);
  T visitBinary(Binary node) => visitExpression(node);
  T visitPrefix(Prefix node) => visitExpression(node);
  T visitPostfix(Postfix node) => visitExpression(node);
  T visitAccess(PropertyAccess node) => visitExpression(node);

  T visitVariableUse(VariableUse node) => visitVariableReference(node);
  T visitVariableDeclaration(VariableDeclaration node)
      => visitVariableReference(node);
  T visitParameter(Parameter node) => visitVariableDeclaration(node);
  T visitThis(This node) => visitParameter(node);

  T visitNamedFunction(NamedFunction node) => visitExpression(node);
  T visitFun(Fun node) => visitExpression(node);

  T visitLiteral(Literal node) => visitExpression(node);

  T visitLiteralBool(LiteralBool node) => visitLiteral(node);
  T visitLiteralString(LiteralString node) => visitLiteral(node);
  T visitLiteralNumber(LiteralNumber node) => visitLiteral(node);
  T visitLiteralNull(LiteralNull node) => visitLiteral(node);

  T visitArrayInitializer(ArrayInitializer node) => visitExpression(node);
  T visitArrayElement(ArrayElement node) => visitNode(node);
  T visitObjectInitializer(ObjectInitializer node) => visitExpression(node);
  T visitProperty(Property node) => visitNode(node);
  T visitRegExpLiteral(RegExpLiteral node) => visitExpression(node);

  T visitInterpolatedNode(InterpolatedNode node) => visitNode(node);

  T visitInterpolatedExpression(InterpolatedExpression node)
      => visitInterpolatedNode(node);
  T visitInterpolatedLiteral(InterpolatedLiteral node)
      => visitInterpolatedNode(node);
  T visitInterpolatedParameter(InterpolatedParameter node)
      => visitInterpolatedNode(node);
  T visitInterpolatedSelector(InterpolatedSelector node)
      => visitInterpolatedNode(node);
  T visitInterpolatedStatement(InterpolatedStatement node)
      => visitInterpolatedNode(node);

  // Ignore comments by default.
  T visitComment(Comment node) => null;
}

abstract class Node {
  get sourcePosition => _sourcePosition;
  get endSourcePosition => _endSourcePosition;

  var _sourcePosition;
  var _endSourcePosition;

  accept(NodeVisitor visitor);
  void visitChildren(NodeVisitor visitor);

  // Shallow clone of node.  Does not clone positions since the only use of this
  // private method is create a copy with a new position.
  Node _clone();

  // Returns a node equivalent to [this], but with new source position and end
  // source position.
  Node withPosition(var sourcePosition, var endSourcePosition) {
    if (sourcePosition == _sourcePosition &&
        endSourcePosition == _endSourcePosition) {
      return this;
    }
    Node clone = _clone();
    // TODO(sra): Should existing data be 'sticky' if we try to overwrite with
    // `null`?
    clone._sourcePosition = sourcePosition;
    clone._endSourcePosition = endSourcePosition;
    return clone;
  }

  // Returns a node equivalent to [this], but with new [this.sourcePositions],
  // keeping the existing [endPosition]
  Node withLocation(var sourcePosition) =>
      withPosition(sourcePosition, this.endSourcePosition);

  VariableUse asVariableUse() => null;

  Statement toStatement() {
    throw new UnsupportedError('toStatement');
  }
}

class Program extends Node {
  final List<Statement> body;
  Program(this.body);

  accept(NodeVisitor visitor) => visitor.visitProgram(this);
  void visitChildren(NodeVisitor visitor) {
    for (Statement statement in body) statement.accept(visitor);
  }
  Program _clone() => new Program(body);
}

abstract class Statement extends Node {
  Statement toStatement() => this;

  Statement withPosition(var sourcePosition, var endSourcePosition) =>
      super.withPosition(sourcePosition, endSourcePosition);
}

class Block extends Statement {
  final List<Statement> statements;
  Block(this.statements);
  Block.empty() : this.statements = <Statement>[];

  accept(NodeVisitor visitor) => visitor.visitBlock(this);
  void visitChildren(NodeVisitor visitor) {
    for (Statement statement in statements) statement.accept(visitor);
  }
  Block _clone() => new Block(statements);
}

class ExpressionStatement extends Statement {
  final Expression expression;
  ExpressionStatement(this.expression);

  accept(NodeVisitor visitor) => visitor.visitExpressionStatement(this);
  void visitChildren(NodeVisitor visitor) { expression.accept(visitor); }
  ExpressionStatement _clone() => new ExpressionStatement(expression);
}

class EmptyStatement extends Statement {
  EmptyStatement();

  accept(NodeVisitor visitor) => visitor.visitEmptyStatement(this);
  void visitChildren(NodeVisitor visitor) {}
  EmptyStatement _clone() => new EmptyStatement();
}

class If extends Statement {
  final Expression condition;
  final Node then;
  final Node otherwise;

  If(this.condition, this.then, this.otherwise);
  If.noElse(this.condition, this.then) : this.otherwise = new EmptyStatement();

  bool get hasElse => otherwise is !EmptyStatement;

  accept(NodeVisitor visitor) => visitor.visitIf(this);

  void visitChildren(NodeVisitor visitor) {
    condition.accept(visitor);
    then.accept(visitor);
    otherwise.accept(visitor);
  }

  If _clone() => new If(condition, then, otherwise);
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

  accept(NodeVisitor visitor) => visitor.visitFor(this);

  void visitChildren(NodeVisitor visitor) {
    if (init != null) init.accept(visitor);
    if (condition != null) condition.accept(visitor);
    if (update != null) update.accept(visitor);
    body.accept(visitor);
  }

  For _clone() => new For(init, condition, update, body);
}

class ForIn extends Loop {
  // Note that [VariableDeclarationList] is a subclass of [Expression].
  // Therefore we can type the leftHandSide as [Expression].
  final Expression leftHandSide;
  final Expression object;

  ForIn(this.leftHandSide, this.object, Statement body) : super(body);

  accept(NodeVisitor visitor) => visitor.visitForIn(this);

  void visitChildren(NodeVisitor visitor) {
    leftHandSide.accept(visitor);
    object.accept(visitor);
    body.accept(visitor);
  }

  ForIn _clone() => new ForIn(leftHandSide, object, body);
}

class While extends Loop {
  final Node condition;

  While(this.condition, Statement body) : super(body);

  accept(NodeVisitor visitor) => visitor.visitWhile(this);

  void visitChildren(NodeVisitor visitor) {
    condition.accept(visitor);
    body.accept(visitor);
  }

  While _clone() => new While(condition, body);
}

class Do extends Loop {
  final Expression condition;

  Do(Statement body, this.condition) : super(body);

  accept(NodeVisitor visitor) => visitor.visitDo(this);

  void visitChildren(NodeVisitor visitor) {
    body.accept(visitor);
    condition.accept(visitor);
  }

  Do _clone() => new Do(body, condition);
}

class Continue extends Statement {
  final String targetLabel;  // Can be null.

  Continue(this.targetLabel);

  accept(NodeVisitor visitor) => visitor.visitContinue(this);
  void visitChildren(NodeVisitor visitor) {}

  Continue _clone() => new Continue(targetLabel);
}

class Break extends Statement {
  final String targetLabel;  // Can be null.

  Break(this.targetLabel);

  accept(NodeVisitor visitor) => visitor.visitBreak(this);
  void visitChildren(NodeVisitor visitor) {}

  Break _clone() => new Break(targetLabel);
}

class Return extends Statement {
  final Expression value;  // Can be null.

  Return([this.value = null]);

  accept(NodeVisitor visitor) => visitor.visitReturn(this);

  void visitChildren(NodeVisitor visitor) {
    if (value != null) value.accept(visitor);
  }

  Return _clone() => new Return(value);
}

class Throw extends Statement {
  final Expression expression;

  Throw(this.expression);

  accept(NodeVisitor visitor) => visitor.visitThrow(this);

  void visitChildren(NodeVisitor visitor) {
    expression.accept(visitor);
  }

  Throw _clone() => new Throw(expression);
}

class Try extends Statement {
  final Block body;
  final Catch catchPart;  // Can be null if [finallyPart] is non-null.
  final Block finallyPart;  // Can be null if [catchPart] is non-null.

  Try(this.body, this.catchPart, this.finallyPart) {
    assert(catchPart != null || finallyPart != null);
  }

  accept(NodeVisitor visitor) => visitor.visitTry(this);

  void visitChildren(NodeVisitor visitor) {
    body.accept(visitor);
    if (catchPart != null) catchPart.accept(visitor);
    if (finallyPart != null) finallyPart.accept(visitor);
  }

  Try _clone() => new Try(body, catchPart, finallyPart);
}

class Catch extends Node {
  final VariableDeclaration declaration;
  final Block body;

  Catch(this.declaration, this.body);

  accept(NodeVisitor visitor) => visitor.visitCatch(this);

  void visitChildren(NodeVisitor visitor) {
    declaration.accept(visitor);
    body.accept(visitor);
  }

  Catch _clone() => new Catch(declaration, body);
}

class Switch extends Statement {
  final Expression key;
  final List<SwitchClause> cases;

  Switch(this.key, this.cases);

  accept(NodeVisitor visitor) => visitor.visitSwitch(this);

  void visitChildren(NodeVisitor visitor) {
    key.accept(visitor);
    for (SwitchClause clause in cases) clause.accept(visitor);
  }

  Switch _clone() => new Switch(key, cases);
}

abstract class SwitchClause extends Node {
  final Block body;

  SwitchClause(this.body);
}

class Case extends SwitchClause {
  final Expression expression;

  Case(this.expression, Block body) : super(body);

  accept(NodeVisitor visitor) => visitor.visitCase(this);

  void visitChildren(NodeVisitor visitor) {
    expression.accept(visitor);
    body.accept(visitor);
  }

  Case _clone() => new Case(expression, body);
}

class Default extends SwitchClause {
  Default(Block body) : super(body);

  accept(NodeVisitor visitor) => visitor.visitDefault(this);

  void visitChildren(NodeVisitor visitor) {
    body.accept(visitor);
  }

  Default _clone() => new Default(body);
}

class FunctionDeclaration extends Statement {
  final VariableDeclaration name;
  final Fun function;

  FunctionDeclaration(this.name, this.function);

  accept(NodeVisitor visitor) => visitor.visitFunctionDeclaration(this);

  void visitChildren(NodeVisitor visitor) {
    name.accept(visitor);
    function.accept(visitor);
  }

  FunctionDeclaration _clone() => new FunctionDeclaration(name, function);
}

class LabeledStatement extends Statement {
  final String label;
  final Statement body;

  LabeledStatement(this.label, this.body);

  accept(NodeVisitor visitor) => visitor.visitLabeledStatement(this);

  void visitChildren(NodeVisitor visitor) {
    body.accept(visitor);
  }

  LabeledStatement _clone() => new LabeledStatement(label, body);
}

class LiteralStatement extends Statement {
  final String code;

  LiteralStatement(this.code);

  accept(NodeVisitor visitor) => visitor.visitLiteralStatement(this);
  void visitChildren(NodeVisitor visitor) { }

  LiteralStatement _clone() => new LiteralStatement(code);
}

abstract class Expression extends Node {
  int get precedenceLevel;

  Statement toStatement() => new ExpressionStatement(this);

  Expression withPosition(var sourcePosition, var endSourcePosition) =>
      super.withPosition(sourcePosition, endSourcePosition);
}

/// Wrap a CodeBuffer as an expression.
class Blob extends Expression {
  // TODO(ahe): This class is an aid to convert everything to ASTs, remove when
  // not needed anymore.

  final leg.CodeBuffer buffer;

  Blob(this.buffer);

  accept(NodeVisitor visitor) => visitor.visitBlob(this);

  void visitChildren(NodeVisitor visitor) {}

  Blob _clone() => new Blob(buffer);

  int get precedenceLevel => PRIMARY;

}

class LiteralExpression extends Expression {
  final String template;
  final List<Expression> inputs;

  LiteralExpression(this.template) : inputs = const [];
  LiteralExpression.withData(this.template, this.inputs);

  accept(NodeVisitor visitor) => visitor.visitLiteralExpression(this);

  void visitChildren(NodeVisitor visitor) {
    if (inputs != null) {
      for (Expression expr in inputs) expr.accept(visitor);
    }
  }

  LiteralExpression _clone() =>
      new LiteralExpression.withData(template, inputs);

  // Code that uses JS must take care of operator precedences, and
  // put parenthesis if needed.
  int get precedenceLevel => PRIMARY;
}

/**
 * [VariableDeclarationList] is a subclass of [Expression] to simplify the
 * AST.
 */
class VariableDeclarationList extends Expression {
  final List<VariableInitialization> declarations;

  VariableDeclarationList(this.declarations);

  accept(NodeVisitor visitor) => visitor.visitVariableDeclarationList(this);

  void visitChildren(NodeVisitor visitor) {
    for (VariableInitialization declaration in declarations) {
      declaration.accept(visitor);
    }
  }

  VariableDeclarationList _clone() => new VariableDeclarationList(declarations);

  int get precedenceLevel => EXPRESSION;
}

class Sequence extends Expression {
  final List<Expression> expressions;

  Sequence(this.expressions);

  accept(NodeVisitor visitor) => visitor.visitSequence(this);

  void visitChildren(NodeVisitor visitor) {
    for (Expression expr in expressions) expr.accept(visitor);
  }

  Sequence _clone() => new Sequence(expressions);

  int get precedenceLevel => EXPRESSION;
}

class Assignment extends Expression {
  final Expression leftHandSide;
  final String op;         // Null, if the assignment is not compound.
  final Expression value;  // May be null, for [VariableInitialization]s.

  Assignment(leftHandSide, value)
      : this.compound(leftHandSide, null, value);
  Assignment.compound(this.leftHandSide, this.op, this.value);

  int get precedenceLevel => ASSIGNMENT;

  bool get isCompound => op != null;

  accept(NodeVisitor visitor) => visitor.visitAssignment(this);

  void visitChildren(NodeVisitor visitor) {
    leftHandSide.accept(visitor);
    if (value != null) value.accept(visitor);
  }

  Assignment _clone() =>
      new Assignment.compound(leftHandSide, op, value);
}

class VariableInitialization extends Assignment {
  /** [value] may be null. */
  VariableInitialization(VariableDeclaration declaration, Expression value)
      : super(declaration, value);

  VariableDeclaration get declaration => leftHandSide;

  accept(NodeVisitor visitor) => visitor.visitVariableInitialization(this);

  VariableInitialization _clone() =>
      new VariableInitialization(declaration, value);
}

class Conditional extends Expression {
  final Expression condition;
  final Expression then;
  final Expression otherwise;

  Conditional(this.condition, this.then, this.otherwise);

  accept(NodeVisitor visitor) => visitor.visitConditional(this);

  void visitChildren(NodeVisitor visitor) {
    condition.accept(visitor);
    then.accept(visitor);
    otherwise.accept(visitor);
  }

  Conditional _clone() => new Conditional(condition, then, otherwise);

  int get precedenceLevel => ASSIGNMENT;
}

class Call extends Expression {
  Expression target;
  List<Expression> arguments;

  Call(this.target, this.arguments);

  accept(NodeVisitor visitor) => visitor.visitCall(this);

  void visitChildren(NodeVisitor visitor) {
    target.accept(visitor);
    for (Expression arg in arguments) arg.accept(visitor);
  }

  Call _clone() => new Call(target, arguments);

  int get precedenceLevel => CALL;
}

class New extends Call {
  New(Expression cls, List<Expression> arguments) : super(cls, arguments);

  accept(NodeVisitor visitor) => visitor.visitNew(this);

  New _clone() => new New(target, arguments);
}

class Binary extends Expression {
  final String op;
  final Expression left;
  final Expression right;

  Binary(this.op, this.left, this.right);

  accept(NodeVisitor visitor) => visitor.visitBinary(this);

  Binary _clone() => new Binary(op, left, right);

  void visitChildren(NodeVisitor visitor) {
    left.accept(visitor);
    right.accept(visitor);
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
        throw new leg.CompilerCancelledException(
            "Internal Error: Unhandled binary operator: $op");
    }
  }
}

class Prefix extends Expression {
  final String op;
  final Expression argument;

  Prefix(this.op, this.argument);

  accept(NodeVisitor visitor) => visitor.visitPrefix(this);

  Prefix _clone() => new Prefix(op, argument);

  void visitChildren(NodeVisitor visitor) {
    argument.accept(visitor);
  }

  int get precedenceLevel => UNARY;
}

class Postfix extends Expression {
  final String op;
  final Expression argument;

  Postfix(this.op, this.argument);

  accept(NodeVisitor visitor) => visitor.visitPostfix(this);

  Postfix _clone() => new Postfix(op, argument);

  void visitChildren(NodeVisitor visitor) {
    argument.accept(visitor);
  }


  int get precedenceLevel => UNARY;
}

abstract class VariableReference extends Expression {
  final String name;

  VariableReference(this.name) {
    assert(_identifierRE.hasMatch(name));
  }
  static RegExp _identifierRE = new RegExp(r'^[A-Za-z_$][A-Za-z_$0-9]*$');

  accept(NodeVisitor visitor);
  int get precedenceLevel => PRIMARY;
  void visitChildren(NodeVisitor visitor) {}
}

class VariableUse extends VariableReference {
  VariableUse(String name) : super(name);

  accept(NodeVisitor visitor) => visitor.visitVariableUse(this);
  VariableUse _clone() => new VariableUse(name);

  VariableUse asVariableUse() => this;

  toString() => 'VariableUse($name)';
}

class VariableDeclaration extends VariableReference {
  VariableDeclaration(String name) : super(name);

  accept(NodeVisitor visitor) => visitor.visitVariableDeclaration(this);
  VariableDeclaration _clone() => new VariableDeclaration(name);
}

class Parameter extends VariableDeclaration {
  Parameter(String name) : super(name);

  accept(NodeVisitor visitor) => visitor.visitParameter(this);
  Parameter _clone() => new Parameter(name);
}

class This extends Parameter {
  This() : super("this");

  accept(NodeVisitor visitor) => visitor.visitThis(this);
  This _clone() => new This();
}

class NamedFunction extends Expression {
  final VariableDeclaration name;
  final Fun function;

  NamedFunction(this.name, this.function);

  accept(NodeVisitor visitor) => visitor.visitNamedFunction(this);

  void visitChildren(NodeVisitor visitor) {
    name.accept(visitor);
    function.accept(visitor);
  }
  NamedFunction _clone() => new NamedFunction(name, function);

  int get precedenceLevel => CALL;
}

class Fun extends Expression {
  final List<Parameter> params;
  final Block body;

  Fun(this.params, this.body);

  accept(NodeVisitor visitor) => visitor.visitFun(this);

  void visitChildren(NodeVisitor visitor) {
    for (Parameter param in params) param.accept(visitor);
    body.accept(visitor);
  }

  Fun _clone() => new Fun(params, body);

  int get precedenceLevel => CALL;
}

class PropertyAccess extends Expression {
  final Expression receiver;
  final Expression selector;

  PropertyAccess(this.receiver, this.selector);
  PropertyAccess.field(this.receiver, String fieldName)
      : selector = new LiteralString('"$fieldName"');
  PropertyAccess.indexed(this.receiver, int index)
      : selector = new LiteralNumber('$index');

  accept(NodeVisitor visitor) => visitor.visitAccess(this);

  void visitChildren(NodeVisitor visitor) {
    receiver.accept(visitor);
    selector.accept(visitor);
  }

  PropertyAccess _clone() => new PropertyAccess(receiver, selector);

  int get precedenceLevel => CALL;
}

abstract class Literal extends Expression {
  void visitChildren(NodeVisitor visitor) {}

  int get precedenceLevel => PRIMARY;
}

class LiteralBool extends Literal {
  final bool value;

  LiteralBool(this.value);

  accept(NodeVisitor visitor) => visitor.visitLiteralBool(this);
  // [visitChildren] inherited from [Literal].
  LiteralBool _clone() => new LiteralBool(value);
}

class LiteralNull extends Literal {
  LiteralNull();

  accept(NodeVisitor visitor) => visitor.visitLiteralNull(this);
  LiteralNull _clone() => new LiteralNull();
}

class LiteralString extends Literal {
  final String value;

  /**
   * Constructs a LiteralString from a string value.
   *
   * The constructor does not add the required quotes.  If [value] is
   * not surrounded by quotes, the resulting object is invalid as a JS
   * value.
   */
  LiteralString(this.value);

  accept(NodeVisitor visitor) => visitor.visitLiteralString(this);
  LiteralString _clone() => new LiteralString(value);
}

class LiteralNumber extends Literal {
  final String value;

  LiteralNumber(this.value);

  accept(NodeVisitor visitor) => visitor.visitLiteralNumber(this);
  LiteralNumber _clone() => new LiteralNumber(value);
}

class ArrayInitializer extends Expression {
  final int length;
  // We represent the array as sparse list of elements. Each element knows its
  // position in the array.
  final List<ArrayElement> elements;

  ArrayInitializer(this.length, this.elements);

  factory ArrayInitializer.from(Iterable<Expression> expressions) =>
      new ArrayInitializer(expressions.length, _convert(expressions));

  accept(NodeVisitor visitor) => visitor.visitArrayInitializer(this);

  void visitChildren(NodeVisitor visitor) {
    for (ArrayElement element in elements) element.accept(visitor);
  }

  ArrayInitializer _clone() => new ArrayInitializer(length, elements);

  int get precedenceLevel => PRIMARY;

  static List<ArrayElement> _convert(Iterable<Expression> expressions) {
    int index = 0;
    return expressions.map(
        (expression) => new ArrayElement(index++, expression))
        .toList();
  }
}

/**
 * An expression inside an [ArrayInitializer]. An [ArrayElement] knows
 * its position in the containing [ArrayInitializer].
 */
class ArrayElement extends Node {
  final int index;
  final Expression value;

  ArrayElement(this.index, this.value);

  accept(NodeVisitor visitor) => visitor.visitArrayElement(this);

  void visitChildren(NodeVisitor visitor) {
    value.accept(visitor);
  }

  ArrayElement _clone() => new ArrayElement(index, value);
}

class ObjectInitializer extends Expression {
  final List<Property> properties;
  final bool isOneLiner;

  /**
   * Constructs a new object-initializer containing the given [properties].
   *
   * [isOneLiner] describes the behaviour when pretty-printing (non-minified).
   * If true print all properties on the same line.
   * If false print each property on a seperate line.
   */
  ObjectInitializer(this.properties, {this.isOneLiner: true});

  accept(NodeVisitor visitor) => visitor.visitObjectInitializer(this);

  void visitChildren(NodeVisitor visitor) {
    for (Property init in properties) init.accept(visitor);
  }

  ObjectInitializer _clone() =>
      new ObjectInitializer(properties, isOneLiner: isOneLiner);

  int get precedenceLevel => PRIMARY;
}

class Property extends Node {
  final Literal name;
  final Expression value;

  Property(this.name, this.value);

  accept(NodeVisitor visitor) => visitor.visitProperty(this);

  void visitChildren(NodeVisitor visitor) {
    name.accept(visitor);
    value.accept(visitor);
  }

  Property _clone() => new Property(name, value);
}

/// Tag class for all interpolated positions.
abstract class InterpolatedNode implements Node {
  get name; // 'int' for positional interpolated nodes, 'String' for named.
}

class InterpolatedExpression extends Expression implements InterpolatedNode {
  final name;

  InterpolatedExpression(this.name);

  accept(NodeVisitor visitor) => visitor.visitInterpolatedExpression(this);
  void visitChildren(NodeVisitor visitor) {}
  InterpolatedExpression _clone() => new InterpolatedExpression(name);

  int get precedenceLevel => PRIMARY;
}

class InterpolatedLiteral extends Literal implements InterpolatedNode {
  final name;

  InterpolatedLiteral(this.name);

  accept(NodeVisitor visitor) => visitor.visitInterpolatedLiteral(this);
  void visitChildren(NodeVisitor visitor) {}
  InterpolatedLiteral _clone() => new InterpolatedLiteral(name);
}

class InterpolatedParameter extends Expression
    implements Parameter, InterpolatedNode {
  final name;

  InterpolatedParameter(this.name);

  accept(NodeVisitor visitor) => visitor.visitInterpolatedParameter(this);
  void visitChildren(NodeVisitor visitor) {}
  InterpolatedParameter _clone() => new InterpolatedParameter(name);

  int get precedenceLevel => PRIMARY;
}

class InterpolatedSelector extends Expression implements InterpolatedNode {
  final name;

  InterpolatedSelector(this.name);

  accept(NodeVisitor visitor) => visitor.visitInterpolatedSelector(this);
  void visitChildren(NodeVisitor visitor) {}
  InterpolatedSelector _clone() => new InterpolatedSelector(name);

  int get precedenceLevel => PRIMARY;
}

class InterpolatedStatement extends Statement implements InterpolatedNode {
  final name;

  InterpolatedStatement(this.name);

  accept(NodeVisitor visitor) => visitor.visitInterpolatedStatement(this);
  void visitChildren(NodeVisitor visitor) {}
  InterpolatedStatement _clone() => new InterpolatedStatement(name);
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

  accept(NodeVisitor visitor) => visitor.visitRegExpLiteral(this);
  void visitChildren(NodeVisitor visitor) {}
  RegExpLiteral _clone() => new RegExpLiteral(pattern);

  int get precedenceLevel => PRIMARY;
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

  accept(NodeVisitor visitor) => visitor.visitComment(this);
  Comment _clone() => new Comment(comment);

  void visitChildren(NodeVisitor visitor) {}
}
