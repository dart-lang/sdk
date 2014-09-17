// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tree_ir_nodes;

import '../dart2jslib.dart' as dart2js;
import '../elements/elements.dart';
import '../universe/universe.dart';
import '../cps_ir/cps_ir_nodes.dart' as cps_ir;
import '../dart_types.dart' show DartType, GenericType;
import '../universe/universe.dart' show Selector;
import '../cps_ir/const_expression.dart';


// The Tree language is the target of translation out of the CPS-based IR.
//
// The translation from CPS to Dart consists of several stages.  Among the
// stages are translation to direct style, translation out of SSA, eliminating
// unnecessary names, recognizing high-level control constructs.  Combining
// these separate concerns is complicated and the constraints of the CPS-based
// language do not permit a multi-stage translation.
//
// For that reason, CPS is translated to the direct-style language Tree.
// Translation out of SSA, unnaming, and control-flow, as well as 'instruction
// selection' are performed on the Tree language.
//
// In contrast to the CPS-based IR, non-primitive expressions can be named and
// arguments (to calls, primitives, and blocks) can be arbitrary expressions.
//
// Additionally, variables are considered in scope within inner functions;
// closure variables are thus handled directly instead of using ref cells.

/**
 * The base class of all Tree nodes.
 */
abstract class Node {
}

/**
 * The base class of [Expression]s.
 */
abstract class Expression extends Node {
  accept(ExpressionVisitor v);

  /// Temporary variable used by [StatementRewriter].
  /// If set to true, this expression has already had enclosing assignments
  /// propagated into its variables, and should not be processed again.
  /// It is only set for expressions that are known to be in risk of redundant
  /// processing.
  bool processed = false;
}

abstract class Statement extends Node {
  Statement get next;
  void set next(Statement s);
  accept(StatementVisitor v);
}

/**
 * Labels name [LabeledStatement]s.
 */
class Label {
  // A counter used to generate names.  The counter is reset to 0 for each
  // function emitted.
  static int counter = 0;
  static String _newName() => 'L${counter++}';

  String cachedName;

  String get name {
    if (cachedName == null) cachedName = _newName();
    return cachedName;
  }

  /// Number of [Break] or [Continue] statements that target this label.
  /// The [Break] constructor will increment this automatically, but the
  /// counter must be decremented by hand when a [Break] becomes orphaned.
  int useCount = 0;

  /// The [LabeledStatement] or [WhileTrue] binding this label.
  JumpTarget binding;
}

/**
 * Variables are [Expression]s.
 */
class Variable extends Expression {
  /// Function that declares this variable.
  FunctionDefinition host;

  /// [Entity] used for synthesizing a name for the variable.
  /// Different variables may have the same entity. May be null.
  Entity element;

  int readCount = 0;

  /// Number of places where this variable occurs as:
  /// - left-hand of an [Assign]
  /// - left-hand of a [FunctionDeclaration]
  /// - parameter in a [FunctionDefinition]
  int writeCount = 0;

  Variable(this.host, this.element) {
    assert(host != null);
  }

  accept(ExpressionVisitor visitor) => visitor.visitVariable(this);
}

/**
 * Common interface for invocations with arguments.
 */
abstract class Invoke {
  List<Expression> get arguments;
  Selector get selector;
}

/**
 * A call to a static function or getter/setter to a static field.
 *
 * In contrast to the CPS-based IR, the arguments can be arbitrary expressions.
 */
class InvokeStatic extends Expression implements Invoke {
  final Entity target;
  final List<Expression> arguments;
  final Selector selector;

  InvokeStatic(this.target, this.selector, this.arguments);

  accept(ExpressionVisitor visitor) => visitor.visitInvokeStatic(this);
}

/**
 * A call to a method, operator, getter, setter or index getter/setter.
 *
 * In contrast to the CPS-based IR, the receiver and arguments can be
 * arbitrary expressions.
 */
class InvokeMethod extends Expression implements Invoke {
  Expression receiver;
  final Selector selector;
  final List<Expression> arguments;

  InvokeMethod(this.receiver, this.selector, this.arguments) {
    assert(receiver != null);
  }

  accept(ExpressionVisitor visitor) => visitor.visitInvokeMethod(this);
}

class InvokeSuperMethod extends Expression implements Invoke {
  final Selector selector;
  final List<Expression> arguments;

  InvokeSuperMethod(this.selector, this.arguments) ;

  accept(ExpressionVisitor visitor) => visitor.visitInvokeSuperMethod(this);
}

/**
 * Call to a factory or generative constructor.
 */
class InvokeConstructor extends Expression implements Invoke {
  final DartType type;
  final FunctionElement target;
  final List<Expression> arguments;
  final Selector selector;
  final dart2js.Constant constant;

  InvokeConstructor(this.type, this.target, this.selector, this.arguments,
      [this.constant]);

  ClassElement get targetClass => target.enclosingElement;

  accept(ExpressionVisitor visitor) => visitor.visitInvokeConstructor(this);
}

/// Calls [toString] on each argument and concatenates the results.
class ConcatenateStrings extends Expression {
  final List<Expression> arguments;
  final dart2js.Constant constant;

  ConcatenateStrings(this.arguments, [this.constant]);

  accept(ExpressionVisitor visitor) => visitor.visitConcatenateStrings(this);
}

/**
 * A constant.
 */
class Constant extends Expression {
  final ConstExp expression;
  final dart2js.Constant value;

  Constant(this.expression, this.value);

  Constant.primitive(dart2js.PrimitiveConstant primitiveValue)
      : expression = new PrimitiveConstExp(primitiveValue),
        value = primitiveValue;

  accept(ExpressionVisitor visitor) => visitor.visitConstant(this);
}

class This extends Expression {
  accept(ExpressionVisitor visitor) => visitor.visitThis(this);
}

class ReifyTypeVar extends Expression {
  TypeVariableElement typeVariable;

  ReifyTypeVar(this.typeVariable);

  accept(ExpressionVisitor visitor) => visitor.visitReifyTypeVar(this);
}

class LiteralList extends Expression {
  final GenericType type;
  final List<Expression> values;

  LiteralList(this.type, this.values);

  accept(ExpressionVisitor visitor) => visitor.visitLiteralList(this);
}

class LiteralMap extends Expression {
  final GenericType type;
  final List<Expression> keys;
  final List<Expression> values;

  LiteralMap(this.type, this.keys, this.values);

  accept(ExpressionVisitor visitor) => visitor.visitLiteralMap(this);
}

class TypeOperator extends Expression {
  Expression receiver;
  final DartType type;
  final String operator;

  TypeOperator(this.receiver, this.type, this.operator) ;

  accept(ExpressionVisitor visitor) => visitor.visitTypeOperator(this);
}

/// A conditional expression.
class Conditional extends Expression {
  Expression condition;
  Expression thenExpression;
  Expression elseExpression;

  Conditional(this.condition, this.thenExpression, this.elseExpression);

  accept(ExpressionVisitor visitor) => visitor.visitConditional(this);
}

/// An && or || expression. The operator is internally represented as a boolean
/// [isAnd] to simplify rewriting of logical operators.
class LogicalOperator extends Expression {
  Expression left;
  bool isAnd;
  Expression right;

  LogicalOperator(this.left, this.right, this.isAnd);
  LogicalOperator.and(this.left, this.right) : isAnd = true;
  LogicalOperator.or(this.left, this.right) : isAnd = false;

  String get operator => isAnd ? '&&' : '||';

  accept(ExpressionVisitor visitor) => visitor.visitLogicalOperator(this);
}

/// Logical negation.
class Not extends Expression {
  Expression operand;

  Not(this.operand);

  accept(ExpressionVisitor visitor) => visitor.visitNot(this);
}

class FunctionExpression extends Expression {
  final FunctionDefinition definition;

  FunctionExpression(this.definition) {
    assert(definition.element.functionSignature.type.returnType.treatAsDynamic);
  }

  accept(ExpressionVisitor visitor) => visitor.visitFunctionExpression(this);
}

/// Declares a local function.
/// Used for functions that may not occur in expression context due to
/// being recursive or having a return type.
/// The [variable] must not occur as the left-hand side of an [Assign] or
/// any other [FunctionDeclaration].
class FunctionDeclaration extends Statement {
  Variable variable;
  final FunctionDefinition definition;
  Statement next;

  FunctionDeclaration(this.variable, this.definition, this.next) {
    ++variable.writeCount;
  }

  accept(StatementVisitor visitor) => visitor.visitFunctionDeclaration(this);
}

/// A [LabeledStatement] or [WhileTrue] or [WhileCondition].
abstract class JumpTarget extends Statement {
  Label get label;
  Statement get body;
}

/**
 * A labeled statement.  Breaks to the label within the labeled statement
 * target the successor statement.
 */
class LabeledStatement extends JumpTarget {
  Statement next;
  final Label label;
  Statement body;

  LabeledStatement(this.label, this.body, this.next) {
    assert(label.binding == null);
    label.binding = this;
  }

  accept(StatementVisitor visitor) => visitor.visitLabeledStatement(this);
}

/// A [WhileTrue] or [WhileCondition] loop.
abstract class Loop extends JumpTarget {
}

/**
 * A labeled while(true) loop.
 */
class WhileTrue extends Loop {
  final Label label;
  Statement body;

  WhileTrue(this.label, this.body) {
    assert(label.binding == null);
    label.binding = this;
  }

  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  accept(StatementVisitor visitor) => visitor.visitWhileTrue(this);
}

/**
 * A while loop with a condition. If the condition is false, control resumes
 * at the [next] statement.
 *
 * It is NOT valid to target this statement with a [Break].
 * The only way to reach [next] is for the condition to evaluate to false.
 *
 * [WhileCondition] statements are introduced in the [LoopRewriter] and is
 * assumed not to occur before then.
 */
class WhileCondition extends Loop {
  final Label label;
  Expression condition;
  Statement body;
  Statement next;

  WhileCondition(this.label, this.condition, this.body,
                 this.next) {
    assert(label.binding == null);
    label.binding = this;
  }

  accept(StatementVisitor visitor) => visitor.visitWhileCondition(this);
}

/// A [Break] or [Continue] statement.
abstract class Jump extends Statement {
  Label get target;
}

/**
 * A break from an enclosing [LabeledStatement].  The break targets the
 * labeled statement's successor statement.
 */
class Break extends Jump {
  final Label target;

  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  Break(this.target) {
    ++target.useCount;
  }

  accept(StatementVisitor visitor) => visitor.visitBreak(this);
}

/**
 * A continue to an enclosing [WhileTrue] or [WhileCondition] loop.
 * The continue targets the loop's body.
 */
class Continue extends Jump {
  final Label target;

  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  Continue(this.target) {
    ++target.useCount;
  }

  accept(StatementVisitor visitor) => visitor.visitContinue(this);
}

/**
 * An assignments of an [Expression] to a [Variable].
 *
 * In contrast to the CPS-based IR, non-primitive expressions can be assigned
 * to variables.
 */
class Assign extends Statement {
  Statement next;
  Variable variable;
  Expression definition;

  /// If true, this declares a new copy of the closure variable.
  /// The consequences are similar to [cps_ir.SetClosureVariable].
  /// All uses of the variable must be nested inside the [next] statement.
  bool isDeclaration;

  Assign(this.variable, this.definition, this.next,
         { this.isDeclaration: false }) {
    variable.writeCount++;
  }

  bool get hasExactlyOneUse => variable.readCount == 1;

  accept(StatementVisitor visitor) => visitor.visitAssign(this);
}

/**
 * A return exit from the function.
 *
 * In contrast to the CPS-based IR, the return value is an arbitrary
 * expression.
 */
class Return extends Statement {
  /// Should not be null. Use [Constant] with [NullConstant] for void returns.
  Expression value;

  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  Return(this.value);

  accept(StatementVisitor visitor) => visitor.visitReturn(this);
}

/**
 * A conditional branch based on the true value of an [Expression].
 */
class If extends Statement {
  Expression condition;
  Statement thenStatement;
  Statement elseStatement;

  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  If(this.condition, this.thenStatement, this.elseStatement);

  accept(StatementVisitor visitor) => visitor.visitIf(this);
}

class ExpressionStatement extends Statement {
  Statement next;
  Expression expression;

  ExpressionStatement(this.expression, this.next);

  accept(StatementVisitor visitor) => visitor.visitExpressionStatement(this);
}

class FunctionDefinition extends Node {
  final FunctionElement element;
  final List<Variable> parameters;
  Statement body;
  final List<ConstDeclaration> localConstants;
  final List<ConstExp> defaultParameterValues;

  FunctionDefinition(this.element, this.parameters, this.body,
      this.localConstants, this.defaultParameterValues);

  /// Returns `true` if this function is abstract.
  ///
  /// If `true` [body] is `null` and [localConstants] is empty.
  bool get isAbstract => body == null;
}

abstract class ExpressionVisitor<E> {
  E visitExpression(Expression e) => e.accept(this);
  E visitVariable(Variable node);
  E visitInvokeStatic(InvokeStatic node);
  E visitInvokeMethod(InvokeMethod node);
  E visitInvokeSuperMethod(InvokeSuperMethod node);
  E visitInvokeConstructor(InvokeConstructor node);
  E visitConcatenateStrings(ConcatenateStrings node);
  E visitConstant(Constant node);
  E visitThis(This node);
  E visitReifyTypeVar(ReifyTypeVar node);
  E visitConditional(Conditional node);
  E visitLogicalOperator(LogicalOperator node);
  E visitNot(Not node);
  E visitLiteralList(LiteralList node);
  E visitLiteralMap(LiteralMap node);
  E visitTypeOperator(TypeOperator node);
  E visitFunctionExpression(FunctionExpression node);
}

abstract class StatementVisitor<S> {
  S visitStatement(Statement s) => s.accept(this);
  S visitLabeledStatement(LabeledStatement node);
  S visitAssign(Assign node);
  S visitReturn(Return node);
  S visitBreak(Break node);
  S visitContinue(Continue node);
  S visitIf(If node);
  S visitWhileTrue(WhileTrue node);
  S visitWhileCondition(WhileCondition node);
  S visitFunctionDeclaration(FunctionDeclaration node);
  S visitExpressionStatement(ExpressionStatement node);
}

abstract class Visitor<S,E> implements ExpressionVisitor<E>,
                                       StatementVisitor<S> {
   E visitExpression(Expression e) => e.accept(this);
   S visitStatement(Statement s) => s.accept(this);
}

class RecursiveVisitor extends Visitor {
  visitFunctionDefinition(FunctionDefinition node) {
    visitStatement(node.body);
  }

  visitVariable(Variable node) {}

  visitInvokeStatic(InvokeStatic node) {
    node.arguments.forEach(visitExpression);
  }

  visitInvokeMethod(InvokeMethod node) {
    visitExpression(node.receiver);
    node.arguments.forEach(visitExpression);
  }

  visitInvokeSuperMethod(InvokeSuperMethod node) {
    node.arguments.forEach(visitExpression);
  }

  visitInvokeConstructor(InvokeConstructor node) {
    node.arguments.forEach(visitExpression);
  }

  visitConcatenateStrings(ConcatenateStrings node) {
    node.arguments.forEach(visitExpression);
  }

  visitConstant(Constant node) {}

  visitThis(This node) {}

  visitReifyTypeVar(ReifyTypeVar node) {}

  visitConditional(Conditional node) {
    visitExpression(node.condition);
    visitExpression(node.thenExpression);
    visitExpression(node.elseExpression);
  }

  visitLogicalOperator(LogicalOperator node) {
    visitExpression(node.left);
    visitExpression(node.right);
  }

  visitNot(Not node) {
    visitExpression(node.operand);
  }

  visitLiteralList(LiteralList node) {
    node.values.forEach(visitExpression);
  }

  visitLiteralMap(LiteralMap node) {
    for (int i=0; i<node.keys.length; i++) {
      visitExpression(node.keys[i]);
      visitExpression(node.values[i]);
    }
  }

  visitTypeOperator(TypeOperator node) {
    visitExpression(node.receiver);
  }

  visitFunctionExpression(FunctionExpression node) {
    visitFunctionDefinition(node.definition);
  }

  visitLabeledStatement(LabeledStatement node) {
    visitStatement(node.body);
    visitStatement(node.next);
  }

  visitAssign(Assign node) {
    visitExpression(node.definition);
    visitVariable(node.variable);
    visitStatement(node.next);
  }

  visitReturn(Return node) {
    visitExpression(node.value);
  }

  visitBreak(Break node) {}

  visitContinue(Continue node) {}

  visitIf(If node) {
    visitExpression(node.condition);
    visitStatement(node.thenStatement);
    visitStatement(node.elseStatement);
  }

  visitWhileTrue(WhileTrue node) {
    visitStatement(node.body);
  }

  visitWhileCondition(WhileCondition node) {
    visitExpression(node.condition);
    visitStatement(node.body);
    visitStatement(node.next);
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    visitFunctionDefinition(node.definition);
    visitStatement(node.next);
  }

  visitExpressionStatement(ExpressionStatement node) {
    visitExpression(node.expression);
    visitStatement(node.next);
  }
}
