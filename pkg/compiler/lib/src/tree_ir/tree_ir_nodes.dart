// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tree_ir_nodes;

import '../constants/expressions.dart';
import '../constants/values.dart' as values;
import '../dart_types.dart' show DartType, InterfaceType, TypeVariableType;
import '../elements/elements.dart';
import '../io/source_information.dart' show SourceInformation;
import '../universe/universe.dart' show Selector;

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
  accept1(ExpressionVisitor1 v, arg);
}

abstract class Statement extends Node {
  Statement get next;
  void set next(Statement s);
  accept(StatementVisitor v);
  accept1(StatementVisitor1 v, arg);
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
 * A local variable in the tree IR.
 *
 * All tree IR variables are mutable, and may in Dart-mode be referenced inside
 * nested functions.
 *
 * To use a variable as an expression, reference it from a [VariableUse], with
 * one [VariableUse] per expression.
 *
 * [Variable]s are reference counted. The node constructors [VariableUse],
 * [Assign], [FunctionDefinition], and [Try] automatically update the reference
 * count for their variables, but when transforming the tree, the transformer
 * is responsible for updating reference counts.
 */
class Variable extends Node {
  /// Function that declares this variable.
  ExecutableElement host;

  /// [Entity] used for synthesizing a name for the variable.
  /// Different variables may have the same entity. May be null.
  Entity element;

  /// Number of places where this variable occurs in a [VariableUse].
  int readCount = 0;

  /// Number of places where this variable occurs as:
  /// - left-hand of an [Assign]
  /// - left-hand of a [FunctionDeclaration]
  /// - parameter in a [FunctionDefinition]
  /// - catch parameter in a [Try]
  int writeCount = 0;

  /// True if a nested function reads or writes this variable.
  ///
  /// Always false in JS-mode because closure conversion eliminated nested
  /// functions.
  bool isCaptured = false;

  Variable(this.host, this.element) {
    assert(host != null);
  }

  String toString() => element == null ? 'Variable' : element.toString();
}

/// Read the value of a variable.
class VariableUse extends Expression {
  Variable variable;

  /// Creates a use of [variable] and updates its `readCount`.
  VariableUse(this.variable) {
    variable.readCount++;
  }

  accept(ExpressionVisitor visitor) => visitor.visitVariableUse(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitVariableUse(this, arg);
  }
}

class Assign extends Expression {
  Variable variable;
  Expression value;

  Assign(this.variable, this.value) {
    variable.writeCount++;
  }

  accept(ExpressionVisitor v) => v.visitAssign(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitAssign(this, arg);

  static ExpressionStatement makeStatement(Variable variable,
                                           Expression value,
                                           [Statement next]) {
    return new ExpressionStatement(new Assign(variable, value), next);
  }
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
  final SourceInformation sourceInformation;

  /// True if the [target] is known not to diverge or read or write any
  /// mutable state.
  ///
  /// This is set for calls to `getInterceptor` and `identical` to indicate
  /// that they can be safely be moved across an impure expression
  /// (assuming the [arguments] are not affected by the impure expression).
  bool isEffectivelyConstant = false;

  InvokeStatic(this.target, this.selector, this.arguments,
               {this.sourceInformation});

  accept(ExpressionVisitor visitor) => visitor.visitInvokeStatic(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitInvokeStatic(this, arg);
  }
}

/**
 * A call to a method, operator, getter, setter or index getter/setter.
 *
 * If [receiver] is `null`, an error is thrown before the arguments are
 * evaluated. This corresponds to the JS evaluation order.
 */
class InvokeMethod extends Expression implements Invoke {
  Expression receiver;
  final Selector selector;
  final List<Expression> arguments;

  /// If true, it is known that the receiver cannot be `null`.
  bool receiverIsNotNull = false;

  InvokeMethod(this.receiver, this.selector, this.arguments) {
    assert(receiver != null);
  }

  accept(ExpressionVisitor visitor) => visitor.visitInvokeMethod(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitInvokeMethod(this, arg);
  }
}

/// Invoke [target] on [receiver], bypassing ordinary dispatch semantics.
///
/// Since the [receiver] is not used for method lookup, it may be `null`
/// without an error being thrown.
class InvokeMethodDirectly extends Expression implements Invoke {
  Expression receiver;
  final Element target;
  final Selector selector;
  final List<Expression> arguments;

  InvokeMethodDirectly(this.receiver, this.target, this.selector,
      this.arguments);

  accept(ExpressionVisitor visitor) => visitor.visitInvokeMethodDirectly(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitInvokeMethodDirectly(this, arg);
  }
}

/**
 * Call to a factory or generative constructor.
 */
class InvokeConstructor extends Expression implements Invoke {
  final DartType type;
  final FunctionElement target;
  final List<Expression> arguments;
  final Selector selector;
  /// TODO(karlklose): get rid of this field.  Instead use the constant's
  /// expression to find the constructor to be called in dart2dart.
  final values.ConstantValue constant;

  InvokeConstructor(this.type, this.target, this.selector, this.arguments,
                    [this.constant]);

  ClassElement get targetClass => target.enclosingElement;

  accept(ExpressionVisitor visitor) {
    return visitor.visitInvokeConstructor(this);
  }

  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitInvokeConstructor(this, arg);
  }
}

/// Calls [toString] on each argument and concatenates the results.
class ConcatenateStrings extends Expression {
  final List<Expression> arguments;

  ConcatenateStrings(this.arguments);

  accept(ExpressionVisitor visitor) => visitor.visitConcatenateStrings(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitConcatenateStrings(this, arg);
  }
}

/**
 * A constant.
 */
class Constant extends Expression {
  final ConstantExpression expression;
  final values.ConstantValue value;

  Constant(this.expression, this.value);

  Constant.bool(values.BoolConstantValue constantValue)
      : expression = new BoolConstantExpression(
          constantValue.primitiveValue),
        value = constantValue;

  accept(ExpressionVisitor visitor) => visitor.visitConstant(this);
  accept1(ExpressionVisitor1 visitor, arg) => visitor.visitConstant(this, arg);
}

class This extends Expression {
  accept(ExpressionVisitor visitor) => visitor.visitThis(this);
  accept1(ExpressionVisitor1 visitor, arg) => visitor.visitThis(this, arg);
}

class LiteralList extends Expression {
  final InterfaceType type;
  final List<Expression> values;

  LiteralList(this.type, this.values);

  accept(ExpressionVisitor visitor) => visitor.visitLiteralList(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitLiteralList(this, arg);
  }
}

class LiteralMapEntry {
  Expression key;
  Expression value;

  LiteralMapEntry(this.key, this.value);
}

class LiteralMap extends Expression {
  final InterfaceType type;
  final List<LiteralMapEntry> entries;

  LiteralMap(this.type, this.entries);

  accept(ExpressionVisitor visitor) => visitor.visitLiteralMap(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitLiteralMap(this, arg);
  }
}

class TypeOperator extends Expression {
  Expression value;
  final DartType type;
  final List<Expression> typeArguments;
  final bool isTypeTest;

  TypeOperator(this.value, this.type, this.typeArguments,
               {bool this.isTypeTest});

  accept(ExpressionVisitor visitor) => visitor.visitTypeOperator(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitTypeOperator(this, arg);
  }

  String get operator => isTypeTest ? 'is' : 'as';
}

/// A conditional expression.
class Conditional extends Expression {
  Expression condition;
  Expression thenExpression;
  Expression elseExpression;

  Conditional(this.condition, this.thenExpression, this.elseExpression);

  accept(ExpressionVisitor visitor) => visitor.visitConditional(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitConditional(this, arg);
  }
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
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitLogicalOperator(this, arg);
  }
}

/// Logical negation.
class Not extends Expression {
  Expression operand;

  Not(this.operand);

  accept(ExpressionVisitor visitor) => visitor.visitNot(this);
  accept1(ExpressionVisitor1 visitor, arg) => visitor.visitNot(this, arg);
}

/// Currently unused.
///
/// See CreateFunction in the cps_ir_nodes.dart.
class FunctionExpression extends Expression {
  final FunctionDefinition definition;

  FunctionExpression(this.definition);

  accept(ExpressionVisitor visitor) => visitor.visitFunctionExpression(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitFunctionExpression(this, arg);
  }
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
  accept1(StatementVisitor1 visitor, arg) {
    return visitor.visitLabeledStatement(this, arg);
  }
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
  accept1(StatementVisitor1 visitor, arg) => visitor.visitWhileTrue(this, arg);
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
  accept1(StatementVisitor1 visitor, arg) {
    return visitor.visitWhileCondition(this, arg);
  }
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
  accept1(StatementVisitor1 visitor, arg) => visitor.visitBreak(this, arg);
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
  accept1(StatementVisitor1 visitor, arg) => visitor.visitContinue(this, arg);
}

/**
 * A return exit from the function.
 *
 * In contrast to the CPS-based IR, the return value is an arbitrary
 * expression.
 */
class Return extends Statement {
  /// Should not be null. Use [Constant] with [NullConstantValue] for void
  /// returns.
  /// Even in constructors this holds true. Take special care when translating
  /// back to dart, where `return null;` in a constructor is an error.
  Expression value;

  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  Return(this.value);

  accept(StatementVisitor visitor) => visitor.visitReturn(this);
  accept1(StatementVisitor1 visitor, arg) => visitor.visitReturn(this, arg);
}

/// A throw statement.
///
/// In the Tree IR, throw is a statement (like JavaScript and unlike Dart).
/// It does not have a successor statement.
class Throw extends Statement {
  Expression value;

  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  Throw(this.value);

  accept(StatementVisitor visitor) => visitor.visitThrow(this);
  accept1(StatementVisitor1 visitor, arg) => visitor.visitThrow(this, arg);
}

/// A rethrow of an exception.
///
/// Rethrow can only occur nested inside a catch block.  It implicitly throws
/// the block's caught exception value without changing the caught stack
/// trace.  It does not have a successor statement.
class Rethrow extends Statement {
  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  Rethrow();

  accept(StatementVisitor visitor) => visitor.visitRethrow(this);
  accept1(StatementVisitor1 visitor, arg) => visitor.visitRethrow(this, arg);
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
  accept1(StatementVisitor1 visitor, arg) => visitor.visitIf(this, arg);
}

class ExpressionStatement extends Statement {
  Statement next;
  Expression expression;

  ExpressionStatement(this.expression, this.next);

  accept(StatementVisitor visitor) => visitor.visitExpressionStatement(this);
  accept1(StatementVisitor1 visitor, arg) {
    return visitor.visitExpressionStatement(this, arg);
  }
}

class Try extends Statement {
  Statement tryBody;
  List<Variable> catchParameters;
  Statement catchBody;

  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  Try(this.tryBody, this.catchParameters, this.catchBody) {
    for (Variable variable in catchParameters) {
      variable.writeCount++; // Being a catch parameter counts as a write.
    }
  }

  accept(StatementVisitor visitor) => visitor.visitTry(this);
  accept1(StatementVisitor1 visitor, arg) {
    return visitor.visitTry(this, arg);
  }
}

class FunctionDefinition extends Node {
  final ExecutableElement element;
  final List<Variable> parameters;
  Statement body;

  /// Creates a function definition and updates `writeCount` for [parameters].
  FunctionDefinition(this.element, this.parameters, this.body) {
    for (Variable param in parameters) {
      param.writeCount++; // Being a parameter counts as a write.
    }
  }
}

class CreateBox extends Expression {
  accept(ExpressionVisitor visitor) => visitor.visitCreateBox(this);
  accept1(ExpressionVisitor1 visitor, arg) => visitor.visitCreateBox(this, arg);
}

class CreateInstance extends Expression {
  ClassElement classElement;
  List<Expression> arguments;
  List<Expression> typeInformation;

  CreateInstance(this.classElement, this.arguments, this.typeInformation);

  accept(ExpressionVisitor visitor) => visitor.visitCreateInstance(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitCreateInstance(this, arg);
  }
}

class GetField extends Expression {
  Expression object;
  Element field;

  GetField(this.object, this.field);

  accept(ExpressionVisitor visitor) => visitor.visitGetField(this);
  accept1(ExpressionVisitor1 visitor, arg) => visitor.visitGetField(this, arg);
}

class SetField extends Expression {
  Expression object;
  Element field;
  Expression value;

  SetField(this.object, this.field, this.value);

  accept(ExpressionVisitor visitor) => visitor.visitSetField(this);
  accept1(ExpressionVisitor1 visitor, arg) => visitor.visitSetField(this, arg);
}

/// Read the value of a field, possibly provoking its initializer to evaluate,
/// or tear off a static method.
class GetStatic extends Expression {
  Element element;
  SourceInformation sourceInformation;

  GetStatic(this.element, this.sourceInformation);

  accept(ExpressionVisitor visitor) => visitor.visitGetStatic(this);
  accept1(ExpressionVisitor1 visitor, arg) => visitor.visitGetStatic(this, arg);
}

class SetStatic extends Expression {
  Element element;
  Expression value;
  SourceInformation sourceInformation;

  SetStatic(this.element, this.value, this.sourceInformation);

  accept(ExpressionVisitor visitor) => visitor.visitSetStatic(this);
  accept1(ExpressionVisitor1 visitor, arg) => visitor.visitSetStatic(this, arg);
}

class ReifyRuntimeType extends Expression {
  Expression value;

  ReifyRuntimeType(this.value);

  accept(ExpressionVisitor visitor) {
    return visitor.visitReifyRuntimeType(this);
  }

  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitReifyRuntimeType(this, arg);
  }
}

class ReadTypeVariable extends Expression {
  final TypeVariableType variable;
  Expression target;

  ReadTypeVariable(this.variable, this.target);

  accept(ExpressionVisitor visitor) {
    return visitor.visitReadTypeVariable(this);
  }

  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitReadTypeVariable(this, arg);
  }
}

class CreateInvocationMirror extends Expression {
  final Selector selector;
  final List<Expression> arguments;

  CreateInvocationMirror(this.selector, this.arguments);

  accept(ExpressionVisitor visitor) {
    return visitor.visitCreateInvocationMirror(this);
  }

  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitCreateInvocationMirror(this, arg);
  }
}

/// Denotes the internal representation of [dartType], where all type variables
/// are replaced by the values in [arguments].
/// (See documentation on the TypeExpression CPS node for more details.)
class TypeExpression extends Expression {
  final DartType dartType;
  final List<Expression> arguments;

  TypeExpression(this.dartType, this.arguments);

  accept(ExpressionVisitor visitor) {
    return visitor.visitTypeExpression(this);
  }

  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitTypeExpression(this, arg);
  }
}

abstract class ExpressionVisitor<E> {
  E visitExpression(Expression node) => node.accept(this);
  E visitVariableUse(VariableUse node);
  E visitAssign(Assign node);
  E visitInvokeStatic(InvokeStatic node);
  E visitInvokeMethod(InvokeMethod node);
  E visitInvokeMethodDirectly(InvokeMethodDirectly node);
  E visitInvokeConstructor(InvokeConstructor node);
  E visitConcatenateStrings(ConcatenateStrings node);
  E visitConstant(Constant node);
  E visitThis(This node);
  E visitConditional(Conditional node);
  E visitLogicalOperator(LogicalOperator node);
  E visitNot(Not node);
  E visitLiteralList(LiteralList node);
  E visitLiteralMap(LiteralMap node);
  E visitTypeOperator(TypeOperator node);
  E visitFunctionExpression(FunctionExpression node);
  E visitGetField(GetField node);
  E visitSetField(SetField node);
  E visitGetStatic(GetStatic node);
  E visitSetStatic(SetStatic node);
  E visitCreateBox(CreateBox node);
  E visitCreateInstance(CreateInstance node);
  E visitReifyRuntimeType(ReifyRuntimeType node);
  E visitReadTypeVariable(ReadTypeVariable node);
  E visitTypeExpression(TypeExpression node);
  E visitCreateInvocationMirror(CreateInvocationMirror node);
}

abstract class ExpressionVisitor1<E, A> {
  E visitExpression(Expression node, A arg) => node.accept1(this, arg);
  E visitVariableUse(VariableUse node, A arg);
  E visitAssign(Assign node, A arg);
  E visitInvokeStatic(InvokeStatic node, A arg);
  E visitInvokeMethod(InvokeMethod node, A arg);
  E visitInvokeMethodDirectly(InvokeMethodDirectly node, A arg);
  E visitInvokeConstructor(InvokeConstructor node, A arg);
  E visitConcatenateStrings(ConcatenateStrings node, A arg);
  E visitConstant(Constant node, A arg);
  E visitThis(This node, A arg);
  E visitConditional(Conditional node, A arg);
  E visitLogicalOperator(LogicalOperator node, A arg);
  E visitNot(Not node, A arg);
  E visitLiteralList(LiteralList node, A arg);
  E visitLiteralMap(LiteralMap node, A arg);
  E visitTypeOperator(TypeOperator node, A arg);
  E visitFunctionExpression(FunctionExpression node, A arg);
  E visitGetField(GetField node, A arg);
  E visitSetField(SetField node, A arg);
  E visitGetStatic(GetStatic node, A arg);
  E visitSetStatic(SetStatic node, A arg);
  E visitCreateBox(CreateBox node, A arg);
  E visitCreateInstance(CreateInstance node, A arg);
  E visitReifyRuntimeType(ReifyRuntimeType node, A arg);
  E visitReadTypeVariable(ReadTypeVariable node, A arg);
  E visitTypeExpression(TypeExpression node, A arg);
  E visitCreateInvocationMirror(CreateInvocationMirror node, A arg);
}

abstract class StatementVisitor<S> {
  S visitStatement(Statement node) => node.accept(this);
  S visitLabeledStatement(LabeledStatement node);
  S visitReturn(Return node);
  S visitThrow(Throw node);
  S visitRethrow(Rethrow node);
  S visitBreak(Break node);
  S visitContinue(Continue node);
  S visitIf(If node);
  S visitWhileTrue(WhileTrue node);
  S visitWhileCondition(WhileCondition node);
  S visitExpressionStatement(ExpressionStatement node);
  S visitTry(Try node);
}

abstract class StatementVisitor1<S, A> {
  S visitStatement(Statement node, A arg) => node.accept1(this, arg);
  S visitLabeledStatement(LabeledStatement node, A arg);
  S visitReturn(Return node, A arg);
  S visitThrow(Throw node, A arg);
  S visitRethrow(Rethrow node, A arg);
  S visitBreak(Break node, A arg);
  S visitContinue(Continue node, A arg);
  S visitIf(If node, A arg);
  S visitWhileTrue(WhileTrue node, A arg);
  S visitWhileCondition(WhileCondition node, A arg);
  S visitExpressionStatement(ExpressionStatement node, A arg);
  S visitTry(Try node, A arg);
}

abstract class RecursiveVisitor implements StatementVisitor, ExpressionVisitor {
  visitExpression(Expression e) => e.accept(this);
  visitStatement(Statement s) => s.accept(this);

  visitInnerFunction(FunctionDefinition node);

  visitVariable(Variable variable) {}

  visitVariableUse(VariableUse node) {
    visitVariable(node.variable);
  }

  visitAssign(Assign node) {
    visitVariable(node.variable);
    visitExpression(node.value);
  }

  visitInvokeStatic(InvokeStatic node) {
    node.arguments.forEach(visitExpression);
  }

  visitInvokeMethod(InvokeMethod node) {
    visitExpression(node.receiver);
    node.arguments.forEach(visitExpression);
  }

  visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    visitExpression(node.receiver);
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
    node.entries.forEach((LiteralMapEntry entry) {
      visitExpression(entry.key);
      visitExpression(entry.value);
    });
  }

  visitTypeOperator(TypeOperator node) {
    visitExpression(node.value);
    node.typeArguments.forEach(visitExpression);
  }

  visitFunctionExpression(FunctionExpression node) {
    visitInnerFunction(node.definition);
  }

  visitLabeledStatement(LabeledStatement node) {
    visitStatement(node.body);
    visitStatement(node.next);
  }

  visitReturn(Return node) {
    visitExpression(node.value);
  }

  visitThrow(Throw node) {
    visitExpression(node.value);
  }

  visitRethrow(Rethrow node) {}

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

  visitExpressionStatement(ExpressionStatement node) {
    visitExpression(node.expression);
    visitStatement(node.next);
  }

  visitTry(Try node) {
    visitStatement(node.tryBody);
    visitStatement(node.catchBody);
  }

  visitGetField(GetField node) {
    visitExpression(node.object);
  }

  visitSetField(SetField node) {
    visitExpression(node.object);
    visitExpression(node.value);
  }

  visitGetStatic(GetStatic node) {
  }

  visitSetStatic(SetStatic node) {
    visitExpression(node.value);
  }

  visitCreateBox(CreateBox node) {
  }

  visitCreateInstance(CreateInstance node) {
    node.arguments.forEach(visitExpression);
    node.typeInformation.forEach(visitExpression);
  }

  visitReifyRuntimeType(ReifyRuntimeType node) {
    visitExpression(node.value);
  }

  visitReadTypeVariable(ReadTypeVariable node) {
    visitExpression(node.target);
  }

  visitTypeExpression(TypeExpression node) {
    node.arguments.forEach(visitExpression);
  }

  visitCreateInvocationMirror(CreateInvocationMirror node) {
    node.arguments.forEach(visitExpression);
  }
}

abstract class Transformer implements ExpressionVisitor<Expression>,
                                      StatementVisitor<Statement> {
   Expression visitExpression(Expression e) => e.accept(this);
   Statement visitStatement(Statement s) => s.accept(this);
}

class RecursiveTransformer extends Transformer {
  void visitInnerFunction(FunctionDefinition node) {
    node.body = visitStatement(node.body);
  }

  void _replaceExpressions(List<Expression> list) {
    for (int i = 0; i < list.length; i++) {
      list[i] = visitExpression(list[i]);
    }
  }

  visitVariableUse(VariableUse node) => node;

  visitAssign(Assign node) {
    node.value = visitExpression(node.value);
    return node;
  }

  visitInvokeStatic(InvokeStatic node) {
    _replaceExpressions(node.arguments);
    return node;
  }

  visitInvokeMethod(InvokeMethod node) {
    node.receiver = visitExpression(node.receiver);
    _replaceExpressions(node.arguments);
    return node;
  }

  visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    node.receiver = visitExpression(node.receiver);
    _replaceExpressions(node.arguments);
    return node;
  }

  visitInvokeConstructor(InvokeConstructor node) {
    _replaceExpressions(node.arguments);
    return node;
  }

  visitConcatenateStrings(ConcatenateStrings node) {
    _replaceExpressions(node.arguments);
    return node;
  }

  visitConstant(Constant node) => node;

  visitThis(This node) => node;

  visitConditional(Conditional node) {
    node.condition = visitExpression(node.condition);
    node.thenExpression = visitExpression(node.thenExpression);
    node.elseExpression = visitExpression(node.elseExpression);
    return node;
  }

  visitLogicalOperator(LogicalOperator node) {
    node.left = visitExpression(node.left);
    node.right = visitExpression(node.right);
    return node;
  }

  visitNot(Not node) {
    node.operand = visitExpression(node.operand);
    return node;
  }

  visitLiteralList(LiteralList node) {
    _replaceExpressions(node.values);
    return node;
  }

  visitLiteralMap(LiteralMap node) {
    node.entries.forEach((LiteralMapEntry entry) {
      entry.key = visitExpression(entry.key);
      entry.value = visitExpression(entry.value);
    });
    return node;
  }

  visitTypeOperator(TypeOperator node) {
    node.value = visitExpression(node.value);
    _replaceExpressions(node.typeArguments);
    return node;
  }

  visitFunctionExpression(FunctionExpression node) {
    visitInnerFunction(node.definition);
    return node;
  }

  visitLabeledStatement(LabeledStatement node) {
    node.body = visitStatement(node.body);
    node.next = visitStatement(node.next);
    return node;
  }

  visitReturn(Return node) {
    node.value = visitExpression(node.value);
    return node;
  }

  visitThrow(Throw node) {
    node.value = visitExpression(node.value);
    return node;
  }

  visitRethrow(Rethrow node) => node;

  visitBreak(Break node) => node;

  visitContinue(Continue node) => node;

  visitIf(If node) {
    node.condition = visitExpression(node.condition);
    node.thenStatement = visitStatement(node.thenStatement);
    node.elseStatement = visitStatement(node.elseStatement);
    return node;
  }

  visitWhileTrue(WhileTrue node) {
    node.body = visitStatement(node.body);
    return node;
  }

  visitWhileCondition(WhileCondition node) {
    node.condition = visitExpression(node.condition);
    node.body = visitStatement(node.body);
    node.next = visitStatement(node.next);
    return node;
  }

  visitExpressionStatement(ExpressionStatement node) {
    node.expression = visitExpression(node.expression);
    node.next = visitStatement(node.next);
    return node;
  }

  visitTry(Try node) {
    node.tryBody = visitStatement(node.tryBody);
    node.catchBody = visitStatement(node.catchBody);
    return node;
  }

  visitGetField(GetField node) {
    node.object = visitExpression(node.object);
    return node;
  }

  visitSetField(SetField node) {
    node.object = visitExpression(node.object);
    node.value = visitExpression(node.value);
    return node;
  }

  visitGetStatic(GetStatic node) => node;

  visitSetStatic(SetStatic node) {
    node.value = visitExpression(node.value);
    return node;
  }

  visitCreateBox(CreateBox node) => node;

  visitCreateInstance(CreateInstance node) {
    _replaceExpressions(node.arguments);
    return node;
  }

  visitReifyRuntimeType(ReifyRuntimeType node) {
    node.value = visitExpression(node.value);
    return node;
  }

  visitReadTypeVariable(ReadTypeVariable node) {
    node.target = visitExpression(node.target);
    return node;
  }

  visitTypeExpression(TypeExpression node) {
    _replaceExpressions(node.arguments);
    return node;
  }

  visitCreateInvocationMirror(CreateInvocationMirror node) {
    _replaceExpressions(node.arguments);
    return node;
  }
}
