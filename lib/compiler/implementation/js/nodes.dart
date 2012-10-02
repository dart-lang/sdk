// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  T visitVariableReference(VariableReference node) => visitExpression(node);

  T visitLiteralExpression(LiteralExpression node) => visitExpression(node);
  T visitVariableDeclarationList(VariableDeclarationList node)
      => visitExpression(node);
  T visitSequence(Sequence node) => visitExpression(node);
  T visitAssignment(Assignment node) => visitExpression(node);
  T visitVariableInitialization(VariableInitialization node) {
    if (node.value != null) {
      visitAssignment(node);
    } else {
      visitExpression(node);
    }
  }
  T visitConditional(Conditional node) => visitExpression(node);
  T visitNew(New node) => visitExpression(node);
  T visitCall(Call node) => visitExpression(node);
  T visitBinary(Binary node) => visitCall(node);
  T visitPrefix(Prefix node) => visitCall(node);
  T visitPostfix(Postfix node) => visitCall(node);
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
}

abstract class Node {
  var sourcePosition;
  var endSourcePosition;

  abstract accept(NodeVisitor visitor);
  abstract void visitChildren(NodeVisitor visitor);
}

class Program extends Node {
  final List<Statement> body;
  Program(this.body);

  accept(NodeVisitor visitor) => visitor.visitProgram(this);
  void visitChildren(NodeVisitor visitor) {
    for (Statement statement in body) statement.accept(visitor);
  }
}

abstract class Statement extends Node {
}

class Block extends Statement {
  final List<Statement> statements;
  Block(this.statements);
  Block.empty() : this.statements = <Statement>[];

  accept(NodeVisitor visitor) => visitor.visitBlock(this);
  void visitChildren(NodeVisitor visitor) {
    for (Statement statement in statements) statement.accept(visitor);
  }
}

class ExpressionStatement extends Statement {
  final Expression expression;
  ExpressionStatement(this.expression);

  accept(NodeVisitor visitor) => visitor.visitExpressionStatement(this);
  void visitChildren(NodeVisitor visitor) { expression.accept(visitor); }
}

class EmptyStatement extends Statement {
  EmptyStatement();

  accept(NodeVisitor visitor) => visitor.visitEmptyStatement(this);
  void visitChildren(NodeVisitor visitor) {}
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
    if (init !== null) init.accept(visitor);
    if (condition !== null) condition.accept(visitor);
    if (update !== null) update.accept(visitor);
    body.accept(visitor);
  }
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
}

class While extends Loop {
  final Node condition;

  While(this.condition, Statement body) : super(body);

  accept(NodeVisitor visitor) => visitor.visitWhile(this);

  void visitChildren(NodeVisitor visitor) {
    condition.accept(visitor);
    body.accept(visitor);
  }
}

class Do extends Loop {
  final Expression condition;

  Do(Statement body, this.condition) : super(body);

  accept(NodeVisitor visitor) => visitor.visitDo(this);

  void visitChildren(NodeVisitor visitor) {
    body.accept(visitor);
    condition.accept(visitor);
  }
}

class Continue extends Statement {
  final String targetLabel;  // Can be null.

  Continue(this.targetLabel);

  accept(NodeVisitor visitor) => visitor.visitContinue(this);
  void visitChildren(NodeVisitor visitor) {}
}

class Break extends Statement {
  final String targetLabel;  // Can be null.

  Break(this.targetLabel);

  accept(NodeVisitor visitor) => visitor.visitBreak(this);
  void visitChildren(NodeVisitor visitor) {}
}

class Return extends Statement {
  final Expression value;  // Can be null.

  Return([this.value = null]);

  accept(NodeVisitor visitor) => visitor.visitReturn(this);

  void visitChildren(NodeVisitor visitor) {
    if (value != null) value.accept(visitor);
  }
}

class Throw extends Statement {
  final Expression expression;

  Throw(this.expression);

  accept(NodeVisitor visitor) => visitor.visitThrow(this);

  void visitChildren(NodeVisitor visitor) {
    expression.accept(visitor);
  }
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
    if (catchPart !== null) catchPart.accept(visitor);
    if (finallyPart !== null) finallyPart.accept(visitor);
  }
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
}

class Default extends SwitchClause {
  Default(Block body) : super(body);

  accept(NodeVisitor visitor) => visitor.visitDefault(this);

  void visitChildren(NodeVisitor visitor) {
    body.accept(visitor);
  }
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
}

class LabeledStatement extends Statement {
  final String label;
  final Statement body;

  LabeledStatement(this.label, this.body);

  accept(NodeVisitor visitor) => visitor.visitLabeledStatement(this);

  void visitChildren(NodeVisitor visitor) {
    body.accept(visitor);
  }
}

class LiteralStatement extends Statement {
  final String code;

  LiteralStatement(this.code);

  accept(NodeVisitor visitor) => visitor.visitLiteralStatement(this);
  void visitChildren(NodeVisitor visitor) { }
}

abstract class Expression extends Node {
  abstract int get precedenceLevel;
}

class LiteralExpression extends Expression {
  final String template;
  final List<Expression> inputs;

  LiteralExpression(this.template) : inputs = const [];
  LiteralExpression.withData(this.template, this.inputs);

  accept(NodeVisitor visitor) => visitor.visitLiteralExpression(this);

  void visitChildren(NodeVisitor visitor) {
    for (Expression expr in inputs) expr.accept(visitor);
  }

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

  int get precedenceLevel => EXPRESSION;
}

class Sequence extends Expression {
  final List<Expression> expressions;

  Sequence(this.expressions);

  accept(NodeVisitor visitor) => visitor.visitSequence(this);

  void visitChildren(NodeVisitor visitor) {
    for (Expression expr in expressions) expr.accept(visitor);
  }

  int get precedenceLevel => EXPRESSION;
}

class Assignment extends Expression {
  final Expression leftHandSide;
  // Null, if the assignment is not compound.
  final VariableReference compoundTarget;
  final Expression value;  // May be null, for [VariableInitialization]s.

  Assignment(this.leftHandSide, this.value) : compoundTarget = null;
  Assignment.compound(this.leftHandSide, String op, this.value)
      : compoundTarget = new VariableUse(op);

  int get precedenceLevel => ASSIGNMENT;

  bool get isCompound => compoundTarget != null;
  String get op => compoundTarget == null ? null : compoundTarget.name;

  accept(NodeVisitor visitor) => visitor.visitAssignment(this);

  void visitChildren(NodeVisitor visitor) {
    leftHandSide.accept(visitor);
    if (compoundTarget != null) compoundTarget.accept(visitor);
    if (value != null) value.accept(visitor);
  }
}

class VariableInitialization extends Assignment {
  /** [value] may be null. */
  VariableInitialization(VariableDeclaration declaration, Expression value)
      : super(declaration, value);

  VariableDeclaration get declaration => leftHandSide;

  accept(NodeVisitor visitor) => visitor.visitVariableInitialization(this);
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

  int get precedenceLevel => CALL;
}

class New extends Call {
  New(Expression cls, List<Expression> arguments) : super(cls, arguments);

  accept(NodeVisitor visitor) => visitor.visitNew(this);
}

class Binary extends Call {
  Binary(String op, Expression left, Expression right)
      : super(new VariableUse(op), <Expression>[left, right]);

  String get op {
    VariableUse use = target;
    return use.name;
  }

  Expression get left => arguments[0];
  Expression get right => arguments[1];

  accept(NodeVisitor visitor) => visitor.visitBinary(this);

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
      default:
        throw new leg.CompilerCancelledException(
            "Internal Error: Unhandled binary operator: $op");
    }
  }
}

class Prefix extends Call {
  Prefix(String op, Expression arg)
      : super(new VariableUse(op), <Expression>[arg]);

  String get op => (target as VariableUse).name;
  Expression get argument => arguments[0];

  accept(NodeVisitor visitor) => visitor.visitPrefix(this);

  int get precedenceLevel => UNARY;
}

class Postfix extends Call {
  Postfix(String op, Expression arg)
      : super(new VariableUse(op), <Expression>[arg]);

  String get op => (target as VariableUse).name;
  Expression get argument => arguments[0];

  accept(NodeVisitor visitor) => visitor.visitPostfix(this);

  int get precedenceLevel => UNARY;
}

abstract class VariableReference extends Expression {
  final String name;

  // We treat operators as if they were special functions. They can thus be
  // referenced like other variables.
  VariableReference(this.name);

  abstract accept(NodeVisitor visitor);
  int get precedenceLevel => PRIMARY;
  void visitChildren(NodeVisitor visitor) {}
}

class VariableUse extends VariableReference {
  VariableUse(String name) : super(name);

  accept(NodeVisitor visitor) => visitor.visitVariableUse(this);
}

class VariableDeclaration extends VariableReference {
  VariableDeclaration(String name) : super(name);

  accept(NodeVisitor visitor) => visitor.visitVariableDeclaration(this);
}

class Parameter extends VariableDeclaration {
  Parameter(String id) : super(id);

  accept(NodeVisitor visitor) => visitor.visitParameter(this);
}

class This extends Parameter {
  This() : super("this");

  accept(NodeVisitor visitor) => visitor.visitThis(this);
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

  int get precedenceLevel => CALL;
}

class PropertyAccess extends Expression {
  final Expression receiver;
  final Expression selector;

  PropertyAccess(this.receiver, this.selector);
  PropertyAccess.field(this.receiver, String fieldName)
      : selector = new LiteralString("'$fieldName'");

  accept(NodeVisitor visitor) => visitor.visitAccess(this);

  void visitChildren(NodeVisitor visitor) {
    receiver.accept(visitor);
    selector.accept(visitor);
  }

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
}

class LiteralNull extends Literal {
  LiteralNull();

  accept(NodeVisitor visitor) => visitor.visitLiteralNull(this);
}

class LiteralString extends Literal {
  final String value;

  LiteralString(this.value);

  accept(NodeVisitor visitor) => visitor.visitLiteralString(this);
}

class LiteralNumber extends Literal {
  final String value;

  LiteralNumber(this.value);

  accept(NodeVisitor visitor) => visitor.visitLiteralNumber(this);
}

class ArrayInitializer extends Expression {
  final int length;
  // We represent the array as sparse list of elements. Each element knows its
  // position in the array.
  final List<ArrayElement> elements;

  ArrayInitializer(this.length, this.elements);

  accept(NodeVisitor visitor) => visitor.visitArrayInitializer(this);

  void visitChildren(NodeVisitor visitor) {
    for (ArrayElement element in elements) element.accept(visitor);
  }

  int get precedenceLevel => PRIMARY;
}

/**
 * An expression inside an [ArrayInitialization]. An [ArrayElement] knows
 * its position in the containing [ArrayInitialization].
 */
class ArrayElement extends Node {
  int index;
  Expression value;

  ArrayElement(this.index, this.value);

  accept(NodeVisitor visitor) => visitor.visitArrayElement(this);

  void visitChildren(NodeVisitor visitor) {
    value.accept(visitor);
  }
}

class ObjectInitializer extends Expression {
  List<Property> properties;

  ObjectInitializer(this.properties);

  accept(NodeVisitor visitor) => visitor.visitObjectInitializer(this);

  void visitChildren(NodeVisitor visitor) {
    for (Property init in properties) init.accept(visitor);
  }

  int get precedenceLevel => PRIMARY;
}

class Property extends Node {
  Literal name;
  Expression value;

  Property(this.name, this.value);

  accept(NodeVisitor visitor) => visitor.visitProperty(this);

  void visitChildren(NodeVisitor visitor) {
    name.accept(visitor);
    value.accept(visitor);
  }
}

/**
 * [RegExpLiteral]s, despite being called "Literal", are not inheriting from
 * [Literal]. Indeed, regular expressions in JavaScript have a side-effect and
 * are thus not in the same category as numbers or strings.
 */
class RegExpLiteral extends Expression {
  /** Contains the pattern and the flags.*/
  String pattern;

  RegExpLiteral(this.pattern);

  accept(NodeVisitor visitor) => visitor.visitRegExpLiteral(this);
  void visitChildren(NodeVisitor visitor) {}

  int get precedenceLevel => PRIMARY;
}
