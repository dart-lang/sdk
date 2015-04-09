// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tree_ir_nodes;

import '../constants/expressions.dart';
import '../constants/values.dart' as values;
import '../dart_types.dart' show DartType, GenericType, InterfaceType, TypeVariableType;
import '../elements/elements.dart';
import '../io/source_information.dart' show SourceInformation;
import '../universe/universe.dart';
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
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitInvokeMethod(this, arg);
  }
}

/// Invoke [target] on [receiver], bypassing ordinary dispatch semantics.
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

  Constant(this.expression);

  Constant.primitive(values.PrimitiveConstantValue primitiveValue)
      : expression = new PrimitiveConstantExpression(primitiveValue);

  accept(ExpressionVisitor visitor) => visitor.visitConstant(this);
  accept1(ExpressionVisitor1 visitor, arg) => visitor.visitConstant(this, arg);

  values.ConstantValue get value => expression.value;
}

class This extends Expression {
  accept(ExpressionVisitor visitor) => visitor.visitThis(this);
  accept1(ExpressionVisitor1 visitor, arg) => visitor.visitThis(this, arg);
}

class ReifyTypeVar extends Expression implements DartSpecificNode {
  TypeVariableElement typeVariable;

  ReifyTypeVar(this.typeVariable);

  accept(ExpressionVisitor visitor) => visitor.visitReifyTypeVar(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitReifyTypeVar(this, arg);
  }
}

class LiteralList extends Expression {
  final GenericType type;
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
  final GenericType type;
  final List<LiteralMapEntry> entries;

  LiteralMap(this.type, this.entries);

  accept(ExpressionVisitor visitor) => visitor.visitLiteralMap(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitLiteralMap(this, arg);
  }
}

class TypeOperator extends Expression {
  Expression receiver;
  final DartType type;
  final bool isTypeTest;

  TypeOperator(this.receiver, this.type, {bool this.isTypeTest});

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

class FunctionExpression extends Expression implements DartSpecificNode {
  final FunctionDefinition definition;

  FunctionExpression(this.definition) {
    assert(definition.element.type.returnType.treatAsDynamic);
  }

  accept(ExpressionVisitor visitor) => visitor.visitFunctionExpression(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitFunctionExpression(this, arg);
  }
}

/// Declares a local function.
/// Used for functions that may not occur in expression context due to
/// being recursive or having a return type.
/// The [variable] must not occur as the left-hand side of an [Assign] or
/// any other [FunctionDeclaration].
class FunctionDeclaration extends Statement implements DartSpecificNode {
  Variable variable;
  final FunctionDefinition definition;
  Statement next;

  FunctionDeclaration(this.variable, this.definition, this.next) {
    ++variable.writeCount;
  }

  accept(StatementVisitor visitor) => visitor.visitFunctionDeclaration(this);
  accept1(StatementVisitor1 visitor, arg) {
    return visitor.visitFunctionDeclaration(this, arg);
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
 * An assignments of an [Expression] to a [Variable].
 *
 * In contrast to the CPS-based IR, non-primitive expressions can be assigned
 * to variables.
 */
class Assign extends Statement {
  Statement next;
  Variable variable;
  Expression value;

  /// If true, this assignes to a fresh variable scoped to the [next]
  /// statement.
  ///
  /// Variable declarations themselves are hoisted to function level.
  bool isDeclaration;

  /// Creates an assignment to [variable] and updates its `writeCount`.
  Assign(this.variable, this.value, this.next,
         { this.isDeclaration: false }) {
    variable.writeCount++;
  }

  bool get hasExactlyOneUse => variable.readCount == 1;

  accept(StatementVisitor visitor) => visitor.visitAssign(this);
  accept1(StatementVisitor1 visitor, arg) => visitor.visitAssign(this, arg);
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

abstract class RootNode extends Node {
  ExecutableElement get element;
  List<Variable> get parameters;

  /// True if there is no body for this root node.
  ///
  /// In some parts of the compiler, empty root nodes are used as placeholders
  /// for abstract methods, external constructors, fields without initializers,
  /// etc.
  bool get isEmpty;

  void forEachBody(void action(Statement node));
  void replaceEachBody(Statement transform(Statement node));

  accept(RootVisitor v);
  accept1(RootVisitor1 v, arg);
}

class FieldDefinition extends RootNode implements DartSpecificNode {
  final FieldElement element;
  // The `body` of a field is its initializer.
  Statement body;
  List<Variable> get parameters => const <Variable>[];

  FieldDefinition(this.element, this.body);

  bool get isEmpty => body == null;

  accept(RootVisitor v) => v.visitFieldDefinition(this);
  accept1(RootVisitor1 v, arg) => v.visitFieldDefinition(this, arg);

  void forEachBody(void action(Statement node)) {
    if (isEmpty) return;
    action(body);
  }

  void replaceEachBody(Statement transform(Statement node)) {
    if (isEmpty) return;
    body = transform(body);
  }
}

class FunctionDefinition extends RootNode {
  final FunctionElement element;
  final List<Variable> parameters;
  Statement body;
  final List<ConstDeclaration> localConstants;
  final List<ConstantExpression> defaultParameterValues;

  /// Creates a function definition and updates `writeCount` for [parameters].
  FunctionDefinition(this.element, this.parameters, this.body,
      this.localConstants, this.defaultParameterValues) {
    for (Variable param in parameters) {
      param.writeCount++; // Being a parameter counts as a write.
    }
  }

  bool get isEmpty => body == null;

  accept(RootVisitor v) => v.visitFunctionDefinition(this);
  accept1(RootVisitor1 v, arg) => v.visitFunctionDefinition(this, arg);

  void forEachBody(void action(Statement node)) {
    if (isEmpty) return;
    action(body);
  }

  void replaceEachBody(Statement transform(Statement node)) {
    if (isEmpty) return;
    body = transform(body);
  }
}

abstract class Initializer implements DartSpecificNode {
  accept(InitializerVisitor v);
  accept1(InitializerVisitor1 v, arg);

  void forEachBody(void action(Statement node));
  void replaceEachBody(Statement transform(Statement node));
}

class FieldInitializer extends Initializer {
  final FieldElement element;
  Statement body;
  bool processed = false;

  FieldInitializer(this.element, this.body);

  accept(InitializerVisitor visitor) => visitor.visitFieldInitializer(this);
  accept1(InitializerVisitor1 visitor, arg) {
    return visitor.visitFieldInitializer(this, arg);
  }

  void forEachBody(void action(Statement node)) {
    action(body);
  }

  void replaceEachBody(Statement transform(Statement node)) {
    body = transform(body);
  }
}

class SuperInitializer extends Initializer {
  final ConstructorElement target;
  final Selector selector;
  final List<Statement> arguments;
  bool processed = false;

  SuperInitializer(this.target, this.selector, this.arguments);
  accept(InitializerVisitor visitor) => visitor.visitSuperInitializer(this);
  accept1(InitializerVisitor1 visitor, arg) {
    return visitor.visitSuperInitializer(this, arg);
  }

  void forEachBody(void action(Statement node)) {
    arguments.forEach(action);
  }

  void replaceEachBody(Statement transform(Statement node)) {
    for (int i = 0; i < arguments.length; i++) {
      arguments[i] = transform(arguments[i]);
    }
  }
}

class ConstructorDefinition extends RootNode
                            implements DartSpecificNode {
  final ConstructorElement element;
  final List<Variable> parameters;
  Statement body;
  final List<ConstDeclaration> localConstants;
  final List<ConstantExpression> defaultParameterValues;
  final List<Initializer> initializers;

  ConstructorDefinition(this.element,
                        this.parameters,
                        this.body,
                        this.initializers,
                        this.localConstants,
                        this.defaultParameterValues) {
    for (Variable param in parameters) {
      param.writeCount++; // Being a parameter counts as a write.
    }
  }

  bool get isEmpty => body == null;

  accept(RootVisitor v) => v.visitConstructorDefinition(this);
  accept1(RootVisitor1 v, arg) => v.visitConstructorDefinition(this, arg);

  void forEachBody(void action(Statement node)) {
    if (isEmpty) return;
    for (Initializer init in initializers) {
      init.forEachBody(action);
    }
    action(body);
  }

  void replaceEachBody(Statement transform(Statement node)) {
    if (isEmpty) return;
    for (Initializer init in initializers) {
      init.replaceEachBody(transform);
    }
    body = transform(body);
  }
}

abstract class JsSpecificNode implements Node {}

abstract class DartSpecificNode implements Node {}

class CreateBox extends Expression implements JsSpecificNode {
  accept(ExpressionVisitor visitor) => visitor.visitCreateBox(this);
  accept1(ExpressionVisitor1 visitor, arg) => visitor.visitCreateBox(this, arg);
}

class CreateInstance extends Expression implements JsSpecificNode {
  ClassElement classElement;
  List<Expression> arguments;
  List<Expression> typeInformation;

  CreateInstance(this.classElement, this.arguments, this.typeInformation);

  accept(ExpressionVisitor visitor) => visitor.visitCreateInstance(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitCreateInstance(this, arg);
  }
}

class GetField extends Expression implements JsSpecificNode {
  Expression object;
  Element field;

  GetField(this.object, this.field);

  accept(ExpressionVisitor visitor) => visitor.visitGetField(this);
  accept1(ExpressionVisitor1 visitor, arg) => visitor.visitGetField(this, arg);
}

class SetField extends Statement implements JsSpecificNode {
  Expression object;
  Element field;
  Expression value;
  Statement next;

  SetField(this.object, this.field, this.value, this.next);

  accept(StatementVisitor visitor) => visitor.visitSetField(this);
  accept1(StatementVisitor1 visitor, arg) => visitor.visitSetField(this, arg);
}

class ReifyRuntimeType extends Expression implements JsSpecificNode {
  Expression value;

  ReifyRuntimeType(this.value);

  accept(ExpressionVisitor visitor) {
    return visitor.visitReifyRuntimeType(this);
  }

  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitReifyRuntimeType(this, arg);
  }
}

class ReadTypeVariable extends Expression implements JsSpecificNode {
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
  E visitInvokeStatic(InvokeStatic node);
  E visitInvokeMethod(InvokeMethod node);
  E visitInvokeMethodDirectly(InvokeMethodDirectly node);
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
  E visitGetField(GetField node);
  E visitCreateBox(CreateBox node);
  E visitCreateInstance(CreateInstance node);
  E visitReifyRuntimeType(ReifyRuntimeType node);
  E visitReadTypeVariable(ReadTypeVariable node);
  E visitTypeExpression(TypeExpression node);
}

abstract class ExpressionVisitor1<E, A> {
  E visitExpression(Expression node, A arg) => node.accept1(this, arg);
  E visitVariableUse(VariableUse node, A arg);
  E visitInvokeStatic(InvokeStatic node, A arg);
  E visitInvokeMethod(InvokeMethod node, A arg);
  E visitInvokeMethodDirectly(InvokeMethodDirectly node, A arg);
  E visitInvokeConstructor(InvokeConstructor node, A arg);
  E visitConcatenateStrings(ConcatenateStrings node, A arg);
  E visitConstant(Constant node, A arg);
  E visitThis(This node, A arg);
  E visitReifyTypeVar(ReifyTypeVar node, A arg);
  E visitConditional(Conditional node, A arg);
  E visitLogicalOperator(LogicalOperator node, A arg);
  E visitNot(Not node, A arg);
  E visitLiteralList(LiteralList node, A arg);
  E visitLiteralMap(LiteralMap node, A arg);
  E visitTypeOperator(TypeOperator node, A arg);
  E visitFunctionExpression(FunctionExpression node, A arg);
  E visitGetField(GetField node, A arg);
  E visitCreateBox(CreateBox node, A arg);
  E visitCreateInstance(CreateInstance node, A arg);
  E visitReifyRuntimeType(ReifyRuntimeType node, A arg);
  E visitReadTypeVariable(ReadTypeVariable node, A arg);
  E visitTypeExpression(TypeExpression node, A arg);
}

abstract class StatementVisitor<S> {
  S visitStatement(Statement node) => node.accept(this);
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
  S visitTry(Try node);
  S visitSetField(SetField node);
}

abstract class StatementVisitor1<S, A> {
  S visitStatement(Statement node, A arg) => node.accept1(this, arg);
  S visitLabeledStatement(LabeledStatement node, A arg);
  S visitAssign(Assign node, A arg);
  S visitReturn(Return node, A arg);
  S visitBreak(Break node, A arg);
  S visitContinue(Continue node, A arg);
  S visitIf(If node, A arg);
  S visitWhileTrue(WhileTrue node, A arg);
  S visitWhileCondition(WhileCondition node, A arg);
  S visitFunctionDeclaration(FunctionDeclaration node, A arg);
  S visitExpressionStatement(ExpressionStatement node, A arg);
  S visitTry(Try node, A arg);
  S visitSetField(SetField node, A arg);
}

abstract class RootVisitor<T> {
  T visitRootNode(RootNode node) => node.accept(this);
  T visitFunctionDefinition(FunctionDefinition node);
  T visitConstructorDefinition(ConstructorDefinition node);
  T visitFieldDefinition(FieldDefinition node);
}

abstract class RootVisitor1<T, A> {
  T visitRootNode(RootNode node, A arg) => node.accept1(this, arg);
  T visitFunctionDefinition(FunctionDefinition node, A arg);
  T visitConstructorDefinition(ConstructorDefinition node, A arg);
  T visitFieldDefinition(FieldDefinition node, A arg);
}

abstract class InitializerVisitor<T> {
  T visitInitializer(Initializer node) => node.accept(this);
  T visitFieldInitializer(FieldInitializer node);
  T visitSuperInitializer(SuperInitializer node);
}

abstract class InitializerVisitor1<T, A> {
  T visitInitializer(Initializer node, A arg) => node.accept1(this, arg);
  T visitFieldInitializer(FieldInitializer node, A arg);
  T visitSuperInitializer(SuperInitializer node, A arg);
}

abstract class RecursiveVisitor implements StatementVisitor, ExpressionVisitor {
  visitExpression(Expression e) => e.accept(this);
  visitStatement(Statement s) => s.accept(this);

  visitInnerFunction(FunctionDefinition node);

  visitVariable(Variable node) {}

  visitVariableUse(VariableUse node) {
    visitVariable(node.variable);
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
    node.entries.forEach((LiteralMapEntry entry) {
      visitExpression(entry.key);
      visitExpression(entry.value);
    });
  }

  visitTypeOperator(TypeOperator node) {
    visitExpression(node.receiver);
  }

  visitFunctionExpression(FunctionExpression node) {
    visitInnerFunction(node.definition);
  }

  visitLabeledStatement(LabeledStatement node) {
    visitStatement(node.body);
    visitStatement(node.next);
  }

  visitAssign(Assign node) {
    visitExpression(node.value);
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
    visitInnerFunction(node.definition);
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
    visitStatement(node.next);
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

  visitReifyTypeVar(ReifyTypeVar node) => node;

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
    node.receiver = visitExpression(node.receiver);
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

  visitAssign(Assign node) {
    node.value = visitExpression(node.value);
    node.next = visitStatement(node.next);
    return node;
  }

  visitReturn(Return node) {
    node.value = visitExpression(node.value);
    return node;
  }

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

  visitFunctionDeclaration(FunctionDeclaration node) {
    visitInnerFunction(node.definition);
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
    node.next = visitStatement(node.next);
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
}
